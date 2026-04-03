import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/services/daily_score_service.dart';
import '../../../domain/services/milestone_service.dart';
import '../../../domain/services/week_cycle_manager.dart';
import '../../providers/habit_provider.dart';
import '../../providers/store_provider.dart';
import '../../theme/app_theme.dart';
import '../habits/all_habits_heatmap_view.dart';
import '../shared/mywalk_paywall_view.dart';

class ProgressView extends StatelessWidget {
  final WeekCycleManager weekCycleManager;

  const ProgressView({super.key, required this.weekCycleManager});

  static const _scoreService = DailyScoreService.instance;
  static const _milestoneService = MilestoneService.instance;
  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitProvider>().sortedHabits;
    final isPremium = context.watch<StoreProvider>().isPremium;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final weekDates = weekCycleManager.currentWeekDates;
    final daysElapsed = weekDates.where((d) => !d.isAfter(todayStart)).toList();

    // ── Week stats ────────────────────────────────────────────────────────────
    final overallScore = daysElapsed.isEmpty
        ? 0.0
        : daysElapsed
                .map((d) => _scoreService.dailyScore(habits.toList(), d))
                .reduce((a, b) => a + b) /
            daysElapsed.length;
    final tier = _scoreService.tierForScore(overallScore);
    final totalCompleted = habits.fold<int>(
        0, (sum, h) => sum + weekCycleManager.completedDaysThisWeek(h));
    final totalPossible = daysElapsed.fold<int>(
        0, (sum, d) => sum + habits.where((h) => h.isActive(d)).length);

    final milestoneCallouts = habits
        .map((h) {
          final p = weekCycleManager.microMilestonePreview(h);
          return p != null ? (h, p) : null;
        })
        .whereType<(Habit, String)>()
        .toList();

    // ── Journey stats ─────────────────────────────────────────────────────────
    final totalGivingDays = _totalGivingDays(habits.toList());
    final totalCheckIns = habits.fold<int>(
        0, (s, h) => s + h.entries.where((e) => e.isCompleted).length);
    final gratitudeDays = habits
            .where((h) => h.isBuiltIn && h.category == HabitCategory.gratitude)
            .firstOrNull
            ?.totalCompletedDays() ??
        0;
    final milestoneCount = habits
        .expand((h) => _milestoneService.milestones(h).where((m) => m.isReached))
        .length;

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: MyWalkColor.charcoal,
              title: const Text('Progress',
                  style: TextStyle(
                      color: MyWalkColor.warmWhite,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              floating: true,
              snap: true,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Journey hero ────────────────────────────────────────────
                  _heroStat(totalGivingDays),
                  const SizedBox(height: 16),

                  // ── Journey stat cards ──────────────────────────────────────
                  _statCardsRow(gratitudeDays, totalCheckIns, milestoneCount),
                  const SizedBox(height: 24),

                  // ── Week summary ────────────────────────────────────────────
                  _weekHeader(tier, totalCompleted, totalPossible),
                  if (milestoneCallouts.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _milestoneCallouts(milestoneCallouts),
                  ],
                  const SizedBox(height: 24),

                  // ── Week grid ───────────────────────────────────────────────
                  _weekGrid(habits.toList(), weekDates, todayStart),
                  const SizedBox(height: 24),

                  // ── Heatmap ─────────────────────────────────────────────────
                  _heatmapSection(habits.toList(), isPremium, context),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Journey hero ────────────────────────────────────────────────────────────

  int _totalGivingDays(List<Habit> habits) {
    final seen = <String>{};
    for (final h in habits) {
      for (final e in h.entries.where((e) => e.isCompleted)) {
        seen.add('${e.date.year}-${e.date.month}-${e.date.day}');
      }
    }
    return seen.length;
  }

  Widget _heroStat(int days) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              MyWalkColor.golden.withValues(alpha: 0.25),
              MyWalkColor.golden.withValues(alpha: 0.04),
            ]),
          ),
          child: const Icon(Icons.local_fire_department, size: 32, color: MyWalkColor.golden),
        ),
        const SizedBox(height: 12),
        Text('$days',
            style: const TextStyle(
                fontSize: 56, fontWeight: FontWeight.w800, color: MyWalkColor.golden, height: 1.0)),
        const SizedBox(height: 6),
        Text(days == 1 ? 'day of giving' : 'days of giving',
            style: const TextStyle(fontSize: 16, color: MyWalkColor.softGold)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _statCardsRow(int gratitudeDays, int checkIns, int milestones) {
    return Row(children: [
      Expanded(child: _statCard(Icons.auto_awesome, '$gratitudeDays', 'gratitude days', MyWalkColor.golden)),
      const SizedBox(width: 12),
      Expanded(child: _statCard(Icons.check_circle_rounded, '$checkIns', 'total check-ins', MyWalkColor.sage)),
      const SizedBox(width: 12),
      Expanded(child: _statCard(Icons.star_rounded, '$milestones', 'milestones', MyWalkColor.golden)),
    ]);
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
      ),
      child: Column(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: MyWalkColor.warmWhite)),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.45))),
      ]),
    );
  }

  // ── Week summary ─────────────────────────────────────────────────────────────

  Widget _weekHeader(DayTier tier, int completed, int possible) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('This Week',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.4),
              letterSpacing: 1.2)),
      const SizedBox(height: 14),
      Row(children: [
        SizedBox(width: 52, height: 52, child: _tierIndicator(tier)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_tierLabel(tier),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: MyWalkColor.warmWhite)),
            Text(weekCycleManager.graceMessage(completed, possible),
                style: const TextStyle(fontSize: 12, color: MyWalkColor.sage)),
          ]),
        ),
      ]),
    ]);
  }

  Widget _tierIndicator(DayTier tier) {
    switch (tier) {
      case DayTier.nothing:
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
          ),
        );
      case DayTier.partial:
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: MyWalkColor.golden.withValues(alpha: 0.6), width: 2),
          ),
          child: Center(child: Icon(Icons.check, size: 16, color: MyWalkColor.golden.withValues(alpha: 0.7))),
        );
      case DayTier.substantial:
        return Container(
          decoration: const BoxDecoration(shape: BoxShape.circle, color: MyWalkColor.golden),
          child: const Center(child: Icon(Icons.check, size: 18, color: MyWalkColor.charcoal)),
        );
      case DayTier.full:
        return Stack(alignment: Alignment.center, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: MyWalkColor.golden.withValues(alpha: 0.45), width: 1.5),
            ),
          ),
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MyWalkColor.golden,
              boxShadow: [
                BoxShadow(color: MyWalkColor.golden.withValues(alpha: 0.7), blurRadius: 14),
                BoxShadow(color: MyWalkColor.golden.withValues(alpha: 0.35), blurRadius: 5),
              ],
            ),
            child: const Center(child: Icon(Icons.check, size: 18, color: MyWalkColor.charcoal)),
          ),
        ]);
    }
  }

  String _tierLabel(DayTier tier) {
    switch (tier) {
      case DayTier.nothing: return 'Just getting started';
      case DayTier.partial: return 'Something given';
      case DayTier.substantial: return 'Strong week';
      case DayTier.full: return 'Beautiful week';
    }
  }

  Widget _milestoneCallouts(List<(Habit, String)> previews) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MyWalkColor.golden.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MyWalkColor.golden.withValues(alpha: 0.12), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: previews.map((item) {
          final (habit, preview) = item;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.auto_awesome, size: 11, color: MyWalkColor.golden),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(habit.name,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite)),
                  Text(preview,
                      style: TextStyle(
                          fontSize: 11, color: MyWalkColor.softGold.withValues(alpha: 0.7))),
                ]),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }

  // ── Week per-habit dot grid ──────────────────────────────────────────────────

  Widget _weekGrid(List<Habit> habits, List<DateTime> weekDates, DateTime todayStart) {
    if (habits.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MyWalkDecorations.card,
      child: Column(
        children: habits.map((h) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Icon(_habitIcon(h), size: 14, color: h.trackingType == HabitTrackingType.abstain
                  ? MyWalkColor.sage : MyWalkColor.golden),
              const SizedBox(width: 8),
              Expanded(
                child: Text(h.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500, color: MyWalkColor.warmWhite),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Row(
                children: weekDates.asMap().entries.map((e) {
                  final date = e.value;
                  final isFuture = date.isAfter(todayStart);
                  final isToday = date.year == todayStart.year &&
                      date.month == todayStart.month &&
                      date.day == todayStart.day;
                  final isActive = h.isActive(date);
                  final score = isActive ? _scoreService.habitScore(h, date) : -1.0;
                  final tileTier = _scoreService.tierForScore(score.clamp(0.0, 1.0));
                  final accent = h.trackingType == HabitTrackingType.abstain
                      ? MyWalkColor.sage : MyWalkColor.golden;

                  return Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: Column(children: [
                      Text(_dayLabels[e.key],
                          style: TextStyle(
                              fontSize: 9,
                              color: isToday ? MyWalkColor.softGold : Colors.white.withValues(alpha: 0.3))),
                      const SizedBox(height: 4),
                      _dot(isActive, isFuture, isToday, tileTier, accent),
                    ]),
                  );
                }).toList(),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _dot(bool isActive, bool isFuture, bool isToday, DayTier tier, Color accent) {
    const size = 20.0;
    if (!isActive) {
      return SizedBox(width: size, height: size,
          child: Center(child: Text('–', style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.12)))));
    }
    if (isFuture) {
      return Container(width: size, height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.03)));
    }
    switch (tier) {
      case DayTier.nothing:
        return Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isToday ? MyWalkColor.golden.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
              width: isToday ? 1.5 : 1,
            ),
          ),
        );
      case DayTier.partial:
        return Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.6), width: 1.5),
          ),
          child: Center(child: Icon(Icons.check, size: 10, color: accent.withValues(alpha: 0.7))),
        );
      case DayTier.substantial:
        return Container(
          width: size, height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
          child: const Center(child: Icon(Icons.check, size: 11, color: MyWalkColor.charcoal)),
        );
      case DayTier.full:
        return Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent,
            boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.6), blurRadius: 6)],
          ),
          child: const Center(child: Icon(Icons.check, size: 11, color: MyWalkColor.charcoal)),
        );
    }
  }

  // ── Heatmap ──────────────────────────────────────────────────────────────────

  Widget _heatmapSection(List<Habit> habits, bool isPremium, BuildContext context) {
    if (isPremium) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: MyWalkDecorations.card,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Year in MyWalk',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: MyWalkColor.golden)),
            const Spacer(),
            Text('52 weeks',
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
          ]),
          const SizedBox(height: 12),
          AllHabitsHeatmapView(habits: habits, weekCount: 52),
          const SizedBox(height: 12),
          _heatmapLegend(),
        ]),
      );
    }

    return Column(children: [
      GestureDetector(
        onTap: () => _openPaywall(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: MyWalkDecorations.card,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Year in MyWalk',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: MyWalkColor.softGold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MyWalkColor.golden.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.workspace_premium, size: 10, color: MyWalkColor.golden),
                  const SizedBox(width: 3),
                  const Text('PRO',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: MyWalkColor.golden)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            ClipRect(
              child: SizedBox(
                height: 140,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: IgnorePointer(child: AllHabitsHeatmapView(habits: habits, weekCount: 52)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.lock_outline, size: 13, color: MyWalkColor.golden),
              const SizedBox(width: 6),
              const Text('Unlock with MyWalk Pro',
                  style: TextStyle(fontSize: 12, color: MyWalkColor.softGold)),
              const Spacer(),
              Icon(Icons.chevron_right, size: 13, color: Colors.white.withValues(alpha: 0.3)),
            ]),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: MyWalkDecorations.card,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Recent Activity',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: MyWalkColor.softGold)),
            const Spacer(),
            Text('4 weeks',
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
          ]),
          const SizedBox(height: 12),
          AllHabitsHeatmapView(habits: habits, weekCount: 4),
          const SizedBox(height: 12),
          _heatmapLegend(),
        ]),
      ),
    ]);
  }

  Widget _heatmapLegend() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _legendItem(MyWalkColor.surfaceOverlay, 'None'),
      const SizedBox(width: 16),
      _legendItem(MyWalkColor.golden.withValues(alpha: 0.12), 'Some', hasBorder: true),
      const SizedBox(width: 16),
      _legendItem(MyWalkColor.golden.withValues(alpha: 0.55), 'Strong'),
      const SizedBox(width: 16),
      _legendItem(MyWalkColor.golden.withValues(alpha: 0.8), 'Full'),
    ]);
  }

  Widget _legendItem(Color color, String label, {bool hasBorder = false}) {
    return Row(children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
          border: hasBorder
              ? Border.all(color: MyWalkColor.golden.withValues(alpha: 0.5), width: 0.5)
              : null,
        ),
      ),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.4))),
    ]);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  IconData _habitIcon(Habit habit) {
    if (habit.trackingType == HabitTrackingType.abstain) return Icons.shield_rounded;
    switch (habit.category) {
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

  void _openPaywall(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => const MyWalkPaywallView(),
    );
  }
}
