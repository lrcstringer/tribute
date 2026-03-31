import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/scripture.dart';
import '../../providers/habit_provider.dart';
import '../../providers/store_provider.dart';
import '../../../domain/services/milestone_service.dart';
import '../../theme/app_theme.dart';
import '../circles/sos_view.dart';
import '../shared/fruit_tag_row.dart';
import '../shared/golden_pulse_view.dart';
import '../shared/milestone_celebration_view.dart';
import '../shared/mywalk_paywall_view.dart';
import 'habit_detail_view.dart';

class HabitCheckInCardView extends StatefulWidget {
  final Habit habit;
  final DateTime targetDate;
  final bool isRetroactive;

  const HabitCheckInCardView({
    super.key,
    required this.habit,
    required this.targetDate,
    this.isRetroactive = false,
  });

  @override
  State<HabitCheckInCardView> createState() => _HabitCheckInCardViewState();
}

class _HabitCheckInCardViewState extends State<HabitCheckInCardView> {
  static const _milestoneService = MilestoneService.instance;

  bool _showPulse = false;
  bool _isCompleted = false;
  double _timedMinutes = 0;
  double _countValue = 0;
  Scripture? _completionVerse;
  Milestone? _celebrationMilestone;

  // Write-serialization token: incremented on every timed/count update so
  // only the most-recent async write commits its post-await setState.
  int _writeToken = 0;

  Habit get _habit => widget.habit;
  DateTime get _targetDate => widget.targetDate;

  @override
  void initState() {
    super.initState();
    _refreshState();
  }

  @override
  void didUpdateWidget(HabitCheckInCardView old) {
    super.didUpdateWidget(old);
    if (old.targetDate != widget.targetDate) {
      _refreshState();
    }
  }

  void _refreshState() {
    final entry = _habit.entryFor(_targetDate);
    _isCompleted = entry?.isCompleted ?? false;
    _timedMinutes = entry?.value ?? 0;
    _countValue = entry?.value ?? 0;
    if (_isCompleted) {
      // isPremium read deferred to build time to avoid context-in-initState issues
      _completionVerse = ScriptureLibrary.completionVerse(_habit.category, _targetDate, isPremium: false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isCompleted) {
      final isPremium = context.read<StoreProvider>().isPremium;
      _completionVerse = ScriptureLibrary.completionVerse(_habit.category, _targetDate, isPremium: isPremium);
    }
  }

  Future<void> _checkIn() async {
    final provider = context.read<HabitProvider>();
    final storeProvider = context.read<StoreProvider>();
    final previousTotal = _habit.totalCompletedDays().toDouble();
    setState(() {
      _showPulse = true;
      _isCompleted = true;
    });
    await provider.checkInHabit(_habit, date: _targetDate, retroactive: widget.isRetroactive);
    if (!mounted) return;
    final isPremium = storeProvider.isPremium;
    setState(() {
      _completionVerse = ScriptureLibrary.completionVerse(_habit.category, _targetDate, isPremium: isPremium);
    });
    if (!widget.isRetroactive) {
      final newTotal = previousTotal + 1;
      final milestone = _milestoneService.checkForNewMilestone(
        _habit,
        previousValue: previousTotal,
        newValue: newTotal,
      );
      if (milestone != null) {
        await Future.delayed(const Duration(milliseconds: 1800));
        if (mounted) setState(() { _showPulse = false; _celebrationMilestone = milestone; });
        return;
      }
    }
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _showPulse = false);
  }

  Future<void> _updateTimed(double delta) async {
    final provider = context.read<HabitProvider>();
    final newVal = (_timedMinutes + delta).clamp(0, 999).toDouble();
    // Optimistic UI update is always immediate and correct.
    setState(() => _timedMinutes = newVal);
    // Stamp a token before the await so rapid taps only commit the last write.
    final token = ++_writeToken;
    await provider.updateTimedEntry(_habit, newVal, date: _targetDate);
    if (!mounted || token != _writeToken) return;
    setState(() => _isCompleted =
        _habit.entryFor(_targetDate)?.isCompleted ?? newVal >= _habit.dailyTarget);
  }

  Future<void> _updateCount(double delta) async {
    final provider = context.read<HabitProvider>();
    final newVal = (_countValue + delta).clamp(0, 9999).toDouble();
    setState(() => _countValue = newVal);
    final token = ++_writeToken;
    await provider.updateCountEntry(_habit, newVal, date: _targetDate);
    if (!mounted || token != _writeToken) return;
    setState(() => _isCompleted =
        _habit.entryFor(_targetDate)?.isCompleted ?? newVal >= _habit.dailyTarget);
  }

  @override
  Widget build(BuildContext context) {
    final isPulse = context.select<HabitProvider, bool>(
      (p) => p.checkInPulseHabitId == _habit.id,
    );
    final isAbstain = _habit.trackingType == HabitTrackingType.abstain;
    final accentColor = isAbstain ? MyWalkColor.sage : MyWalkColor.golden;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showDetail(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: MyWalkDecorations.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(accentColor),
                const SizedBox(height: 12),
                _trackingUI(accentColor),
                if (_isCompleted && _completionVerse != null) ...[
                  const SizedBox(height: 12),
                  _verseSection(),
                ],
                if (isAbstain && !widget.isRetroactive) ...[
                  const SizedBox(height: 10),
                  _sosLink(),
                ],
              ],
            ),
          ),
        ),
        if (_showPulse || isPulse)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: GoldenPulseView(onComplete: () {
                  if (mounted) setState(() => _showPulse = false);
                }),
              ),
            ),
          ),
        if (_celebrationMilestone != null)
          Positioned.fill(
            child: MilestoneCelebrationView(
              milestone: _celebrationMilestone!,
              trackingType: _habit.trackingType,
              onDismiss: () => setState(() => _celebrationMilestone = null),
            ),
          ),
      ],
    );
  }

  Widget _header(Color accentColor) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                accentColor.withValues(alpha: _isCompleted ? 0.3 : 0.12),
                accentColor.withValues(alpha: _isCompleted ? 0.1 : 0.03),
              ],
            ),
          ),
          child: Icon(
            _habitIcon(),
            color: accentColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _habit.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: MyWalkColor.warmWhite,
                ),
              ),
              if (_isCompleted)
                Text(
                  _completedSubtitle(),
                  style: TextStyle(
                    fontSize: 11,
                    color: MyWalkColor.sage,
                  ),
                )
              else
                Text(
                  _habit.purposeStatement,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: MyWalkColor.softGold.withValues(alpha: 0.6),
                  ),
                ),
              if (_habit.fruitTags.isNotEmpty) ...[
                const SizedBox(height: 4),
                FruitTagRow(
                  fruitTags: _habit.fruitTags,
                  purposeStatement: _habit.fruitPurposeStatement,
                ),
              ],
            ],
          ),
        ),
        if (_isCompleted)
          Icon(Icons.check_circle_rounded, color: accentColor, size: 24)
        else
          Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.2), size: 16),
      ],
    );
  }

  Widget _trackingUI(Color accentColor) {
    switch (_habit.trackingType) {
      case HabitTrackingType.checkIn:
        return _checkInButton(accentColor);
      case HabitTrackingType.abstain:
        return _abstainButton();
      case HabitTrackingType.timed:
        return _timedUI(accentColor);
      case HabitTrackingType.count:
        return _countUI(accentColor);
    }
  }

  Widget _checkInButton(Color accentColor) {
    if (_isCompleted) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _checkIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: MyWalkColor.charcoal,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Check In', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _sosLink() {
    return GestureDetector(
      onTap: () => _launchSOS(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.shield_rounded, size: 13, color: MyWalkColor.warmCoral.withValues(alpha: 0.65)),
          const SizedBox(width: 5),
          Text('SOS — Need help right now?',
              style: TextStyle(fontSize: 12, color: MyWalkColor.warmCoral.withValues(alpha: 0.65))),
        ]),
      ),
    );
  }

  void _launchSOS(BuildContext context) {
    final isPremium = context.read<StoreProvider>().isPremium;
    if (!isPremium) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: MyWalkColor.charcoal,
        builder: (_) => const MyWalkPaywallView(
          contextTitle: 'SOS Support',
          contextMessage: 'Tough moment? The SOS feature can help — it\'ll remind you why you started and connect you with your circle.',
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SOSView(habit: _habit),
      ),
    );
  }

  String _dayName(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  Widget _abstainButton() {
    if (_isCompleted) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _checkIn,
        icon: const Icon(Icons.shield_rounded, size: 16),
        label: Text(widget.isRetroactive
            ? 'Were you strong on ${_dayName(widget.targetDate)}?'
            : 'Stayed strong today?'),
        style: ElevatedButton.styleFrom(
          backgroundColor: MyWalkColor.sage,
          foregroundColor: MyWalkColor.charcoal,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _timedUI(Color accentColor) {
    final target = _habit.dailyTarget;
    final ratio = target > 0 ? (_timedMinutes / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: ratio,
                strokeWidth: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(accentColor),
              ),
            ),
            Text(
              '${_timedMinutes.toInt()}m',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _timedButton('-5', () => _updateTimed(-5)),
            const SizedBox(width: 8),
            _timedButton('+5', () => _updateTimed(5)),
            const SizedBox(width: 8),
            _timedButton('+15', () => _updateTimed(15)),
            const SizedBox(width: 8),
            _timedButton('+30', () => _updateTimed(30)),
          ],
        ),
        if (target > 0) ...[
          const SizedBox(height: 6),
          Text(
            'Goal: ${target.toInt()} min',
            style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.3)),
          ),
        ],
      ],
    );
  }

  Widget _timedButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: MyWalkColor.surfaceOverlay,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MyWalkColor.softGold),
        ),
      ),
    );
  }

  Widget _countUI(Color accentColor) {
    final target = _habit.dailyTarget;
    final unit = _habit.targetUnit.isEmpty ? '' : ' ${_habit.targetUnit}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _countButton(Icons.remove, () => _updateCount(-1)),
        const SizedBox(width: 16),
        Column(
          children: [
            Text(
              '${_countValue.toInt()}$unit',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _isCompleted ? accentColor : MyWalkColor.warmWhite,
              ),
            ),
            if (target > 0)
              Text(
                'of ${target.toInt()}$unit',
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.3)),
              ),
          ],
        ),
        const SizedBox(width: 16),
        _countButton(Icons.add, () => _updateCount(1)),
      ],
    );
  }

  Widget _countButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: MyWalkColor.surfaceOverlay,
        ),
        child: Icon(icon, size: 18, color: MyWalkColor.softGold),
      ),
    );
  }

  Widget _verseSection() {
    final verse = _completionVerse!;
    return Column(
      children: [
        Text(
          '\u201C${verse.text}\u201D',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: MyWalkColor.softGold.withValues(alpha: 0.55),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          verse.reference,
          style: TextStyle(fontSize: 10, color: MyWalkColor.golden.withValues(alpha: 0.4)),
        ),
      ],
    );
  }

  String _completedSubtitle() {
    switch (_habit.trackingType) {
      case HabitTrackingType.timed:
        return '${_timedMinutes.toInt()} min given';
      case HabitTrackingType.count:
        final unit = _habit.targetUnit.isEmpty ? '' : ' ${_habit.targetUnit}';
        return '${_countValue.toInt()}$unit completed';
      case HabitTrackingType.checkIn:
        return '${_habit.totalCompletedDays()} days total';
      case HabitTrackingType.abstain:
        return 'Clean day \u2713';
    }
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

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, sc) => HabitDetailView(habit: _habit, scrollController: sc),
      ),
    );
  }
}
