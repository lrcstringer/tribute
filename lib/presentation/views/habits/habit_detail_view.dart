import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/scripture.dart';
import '../../providers/store_provider.dart';
import '../../../domain/services/milestone_service.dart';
import '../../theme/app_theme.dart';
import '../shared/tribute_paywall_view.dart';
import 'edit_habit_view.dart';
import 'heatmap_view.dart';

class HabitDetailView extends StatefulWidget {
  final Habit habit;
  final ScrollController? scrollController;

  const HabitDetailView({super.key, required this.habit, this.scrollController});

  @override
  State<HabitDetailView> createState() => _HabitDetailViewState();
}

class _HabitDetailViewState extends State<HabitDetailView> {
  static const _milestoneService = MilestoneService.instance;

  Habit get _habit => widget.habit;

  Color _accentColor() =>
      _habit.trackingType == HabitTrackingType.abstain
          ? TributeColor.sage
          : TributeColor.golden;

  List<DateTime> _currentWeekDates() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final daysSinceSunday = today.weekday % 7;
    final weekStart = todayStart.subtract(Duration(days: daysSinceSunday));
    return List.generate(7, (i) => weekStart.add(Duration(days: i)));
  }

  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<StoreProvider>().isPremium;
    final accent = _accentColor();
    final lifetimeStat = _milestoneService.lifetimeStat(_habit);
    final milestones = _milestoneService.milestones(_habit);
    final habitAge = _milestoneService.habitAge(_habit);
    final verse = ScriptureLibrary.completionVerse(_habit.category, DateTime.now(), isPremium: isPremium);

    return Scaffold(
      backgroundColor: TributeColor.charcoal,
      appBar: AppBar(
        backgroundColor: TributeColor.charcoal,
        title: Text(
          _habit.name,
          style: const TextStyle(color: TributeColor.warmWhite, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: TributeColor.warmWhite),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: TributeColor.softGold.withValues(alpha: 0.8)),
            onPressed: () => _showEdit(context),
          ),
        ],
      ),
      body: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          _lifetimeStatSection(lifetimeStat, accent),
          const SizedBox(height: 20),
          _weekBreakdownSection(),
          const SizedBox(height: 20),
          _heatmapSection(isPremium, accent),
          const SizedBox(height: 20),
          _milestoneSection(milestones, accent),
          const SizedBox(height: 20),
          if (_habit.trigger.isNotEmpty || _habit.copingPlan.isNotEmpty) ...[
            _anchoringSection(),
            const SizedBox(height: 20),
          ],
          _purposeSection(),
          const SizedBox(height: 20),
          _verseSection(verse),
          const SizedBox(height: 20),
          _habitInfoSection(habitAge),
        ],
      ),
    );
  }

  Widget _lifetimeStatSection(LifetimeStat stat, Color accent) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [accent.withValues(alpha: 0.25), accent.withValues(alpha: 0.04)],
            ),
          ),
          child: Icon(_habitIcon(), color: accent, size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          stat.primaryValue,
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w800,
            color: accent,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          stat.description,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: TributeColor.softGold),
        ),
        if (stat.detail != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_habit.trackingType == HabitTrackingType.abstain)
                Icon(Icons.shield_outlined, size: 13, color: TributeColor.sage.withValues(alpha: 0.6)),
              if (_habit.trackingType == HabitTrackingType.abstain)
                const SizedBox(width: 4),
              Text(
                stat.detail!,
                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.45)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _weekBreakdownSection() {
    final dates = _currentWeekDates();
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: TributeDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This Week',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: TributeColor.softGold)),
          const SizedBox(height: 12),
          Row(
            children: dates.asMap().entries.map((e) {
              final date = e.value;
              final isToday = date.year == todayStart.year &&
                  date.month == todayStart.month &&
                  date.day == todayStart.day;
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      _dayLabels[e.key],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        color: isToday ? TributeColor.golden : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _weekDayVisual(date),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _weekDayVisual(DateTime date) {
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final isFuture = date.isAfter(todayStart);
    final isActive = _habit.isActive(date);
    final entry = _habit.entryFor(date);

    switch (_habit.trackingType) {
      case HabitTrackingType.timed:
        return _timedDayBar(entry, isFuture, isActive);
      case HabitTrackingType.count:
        return _countDayVisual(entry, isFuture, isActive);
      case HabitTrackingType.checkIn:
        return _checkInDayCircle(entry, isFuture, isActive);
      case HabitTrackingType.abstain:
        return _abstainDayShield(entry, isFuture, isActive);
    }
  }

  Widget _timedDayBar(dynamic entry, bool isFuture, bool isActive) {
    final value = entry?.value ?? 0.0;
    final target = _habit.dailyTarget;
    final ratio = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    final completed = entry?.isCompleted ?? false;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 16,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            if (!isFuture && isActive)
              Container(
                width: 16,
                height: (40 * ratio).clamp(2.0, 40.0).toDouble(),
                decoration: BoxDecoration(
                  color: completed ? TributeColor.golden : TributeColor.mutedSage,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          (!isFuture && isActive && value > 0) ? '${value.toInt()}' : ' ',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: completed ? TributeColor.golden : Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _countDayVisual(dynamic entry, bool isFuture, bool isActive) {
    final value = entry?.value ?? 0.0;
    final completed = entry?.isCompleted ?? false;

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (!isFuture && isActive && value > 0)
                ? (completed
                    ? TributeColor.golden.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.04))
                : Colors.white.withValues(alpha: isFuture || !isActive ? 0.02 : 0.04),
          ),
          child: (!isFuture && isActive && value > 0)
              ? Center(
                  child: Text(
                    '${value.toInt()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: completed
                          ? TributeColor.golden
                          : TributeColor.softGold.withValues(alpha: 0.6),
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 4),
        const Text(' ', style: TextStyle(fontSize: 9)),
      ],
    );
  }

  Widget _checkInDayCircle(dynamic entry, bool isFuture, bool isActive) {
    final completed = entry?.isCompleted ?? false;

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed
                ? TributeColor.golden
                : Colors.white.withValues(alpha: isFuture || !isActive ? 0.02 : 0.04),
          ),
          child: completed
              ? const Icon(Icons.check, size: 14, color: TributeColor.charcoal)
              : null,
        ),
        const SizedBox(height: 4),
        const Text(' ', style: TextStyle(fontSize: 9)),
      ],
    );
  }

  Widget _abstainDayShield(dynamic entry, bool isFuture, bool isActive) {
    final confirmed = entry?.isCompleted ?? false;

    return Column(
      children: [
        Icon(
          confirmed ? Icons.shield_rounded : Icons.shield_outlined,
          size: 24,
          color: confirmed
              ? TributeColor.sage
              : Colors.white.withValues(alpha: isFuture || !isActive ? 0.08 : 0.2),
        ),
        const SizedBox(height: 4),
        const Text(' ', style: TextStyle(fontSize: 9)),
      ],
    );
  }

  Widget _heatmapSection(bool isPremium, Color accent) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: TributeDecorations.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Activity',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: TributeColor.softGold)),
                  const Spacer(),
                  Text(isPremium ? 'Last 12 weeks' : 'Current week',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
                ],
              ),
              const SizedBox(height: 12),
              HeatmapView(habit: _habit, weekCount: isPremium ? 12 : 1),
            ],
          ),
        ),
        if (isPremium) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: TributeDecorations.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Year in Tribute',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: TributeColor.golden)),
                    const Spacer(),
                    Text('52 weeks',
                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
                  ],
                ),
                const SizedBox(height: 12),
                HeatmapView(habit: _habit, weekCount: 52),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _showPaywall(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: TributeDecorations.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Year in Tribute',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TributeColor.softGold)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: TributeColor.golden.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.workspace_premium, size: 10, color: TributeColor.golden),
                            const SizedBox(width: 3),
                            Text('PRO',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: TributeColor.golden)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRect(
                    child: SizedBox(
                      height: 180,
                      child: ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: IgnorePointer(child: HeatmapView(habit: _habit, weekCount: 52)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.lock_outline, size: 13, color: TributeColor.golden),
                      const SizedBox(width: 6),
                      Text('Unlock with Tribute Pro',
                          style: TextStyle(
                              fontSize: 12, color: TributeColor.softGold)),
                      const Spacer(),
                      Icon(Icons.chevron_right,
                          size: 13, color: Colors.white.withValues(alpha: 0.3)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _milestoneSection(List<Milestone> milestones, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: TributeDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Milestones',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: TributeColor.softGold)),
          const SizedBox(height: 14),
          ...milestones.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: m.isReached
                        ? accent.withValues(alpha: 0.2)
                        : TributeColor.surfaceOverlay,
                  ),
                  child: Icon(
                    m.isReached ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 16,
                    color: m.isReached ? accent : Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: m.isReached
                              ? TributeColor.warmWhite
                              : Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      if (m.progressHint != null && !m.isReached)
                        Text(
                          m.progressHint!,
                          style: TextStyle(
                              fontSize: 11, color: accent.withValues(alpha: 0.6)),
                        )
                      else if (!m.isReached)
                        Text('Keep going',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.2))),
                    ],
                  ),
                ),
                if (m.isReached)
                  Icon(Icons.check_circle_rounded,
                      size: 18, color: accent.withValues(alpha: 0.6)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _anchoringSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: TributeDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_habit.trigger.isNotEmpty) ...[
            Row(children: [
              Icon(Icons.access_time,
                  size: 13, color: TributeColor.golden.withValues(alpha: 0.7)),
              const SizedBox(width: 5),
              Text('Trigger',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: TributeColor.golden.withValues(alpha: 0.7))),
            ]),
            const SizedBox(height: 4),
            Text(_habit.trigger,
                style: const TextStyle(fontSize: 14, color: TributeColor.warmWhite)),
          ],
          if (_habit.trigger.isNotEmpty && _habit.copingPlan.isNotEmpty)
            const SizedBox(height: 10),
          if (_habit.copingPlan.isNotEmpty) ...[
            Row(children: [
              Icon(Icons.shield_outlined,
                  size: 13, color: TributeColor.warmCoral.withValues(alpha: 0.7)),
              const SizedBox(width: 5),
              Text('Coping Plan',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: TributeColor.warmCoral.withValues(alpha: 0.7))),
            ]),
            const SizedBox(height: 4),
            Text(_habit.copingPlan,
                style: const TextStyle(fontSize: 14, color: TributeColor.warmWhite)),
          ],
        ],
      ),
    );
  }

  Widget _purposeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: TributeDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Why',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: TributeColor.softGold)),
          const SizedBox(height: 8),
          Text(
            _habit.purposeStatement,
            style: TextStyle(
                fontSize: 15, color: TributeColor.warmWhite, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _verseSection(Scripture verse) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            '\u201C${verse.text}\u201D',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: TributeColor.softGold.withValues(alpha: 0.6),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            verse.reference,
            style: TextStyle(fontSize: 11, color: TributeColor.golden.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _habitInfoSection(int habitAge) {
    final activedays = _habit.activeDaySet.toList()..sort();
    const dayNames = {1: 'Sun', 2: 'Mon', 3: 'Tue', 4: 'Wed', 5: 'Thu', 6: 'Fri', 7: 'Sat'};
    final activeDaysSummary = activedays.map((d) => dayNames[d] ?? '').where((s) => s.isNotEmpty).join(', ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: TributeDecorations.card,
      child: Column(
        children: [
          _infoRow('Tracking type', _habit.trackingType.name[0].toUpperCase() + _habit.trackingType.name.substring(1)),
          const SizedBox(height: 8),
          _infoRow('Started', '$habitAge days ago'),
          const SizedBox(height: 8),
          _infoRow('Total entries', '${_habit.entries.where((e) => e.isCompleted).length}'),
          if (_habit.activeDaySet.length < 7) ...[
            const SizedBox(height: 8),
            _infoRow('Active days', activeDaysSummary),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: TributeColor.softGold)),
      ],
    );
  }

  IconData _habitIcon() {
    if (_habit.trackingType == HabitTrackingType.abstain) return Icons.shield_rounded;
    switch (_habit.category) {
      case HabitCategory.gratitude: return Icons.auto_awesome;
      case HabitCategory.scripture: return Icons.menu_book;
      case HabitCategory.exercise: return Icons.fitness_center;
      case HabitCategory.rest: return Icons.bedtime;
      case HabitCategory.fasting: return Icons.no_food;
      case HabitCategory.study: return Icons.school;
      case HabitCategory.service: return Icons.volunteer_activism;
      case HabitCategory.connection: return Icons.people;
      case HabitCategory.health: return Icons.favorite;
      case HabitCategory.abstain: return Icons.shield_rounded;
      case HabitCategory.custom: return Icons.star;
    }
  }

  void _showPaywall(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: TributeColor.charcoal,
      builder: (_) => const TributePaywallView(),
    );
  }

  void _showEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: TributeColor.charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        expand: false,
        builder: (ctx, sc) => EditHabitView(habit: _habit, scrollController: sc),
      ),
    );
  }
}
