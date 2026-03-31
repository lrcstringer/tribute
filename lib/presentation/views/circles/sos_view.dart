import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/scripture.dart';
import '../../../data/datasources/remote/auth_service.dart';
import '../../../domain/repositories/circle_repository.dart';
import '../../../domain/services/milestone_service.dart';
import '../../theme/app_theme.dart';
import 'sos_circle_picker_view.dart';

class SOSView extends StatefulWidget {
  final Habit habit;
  const SOSView({super.key, required this.habit});

  @override
  State<SOSView> createState() => _SOSViewState();
}

class _SOSViewState extends State<SOSView> with SingleTickerProviderStateMixin {
  static const _milestoneService = MilestoneService.instance;

  bool _microActionCompleted = false;
  bool _showPrayerCircleMessage = false;
  bool _circleLoadFailed = false;
  bool _isLoadingCircles = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.0, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<String> get _microActions {
    switch (widget.habit.category) {
      case HabitCategory.exercise:
        return ['Just do the first 5 minutes.', 'Do 10 pushups to reset your headspace.', 'Step outside and walk for 2 minutes.'];
      case HabitCategory.scripture:
        return ['Open to any page. Read one verse.', 'Pray for 60 seconds. Just talk to Him.', 'Write down one thing God has done for you.'];
      case HabitCategory.rest:
        return ['Put your phone down for 5 minutes.', 'Close your eyes and breathe for 60 seconds.', "Tell God what's keeping you up."];
      case HabitCategory.abstain:
        return ['Pray for 60 seconds. Tell God what you\'re feeling.', 'Do 10 pushups to reset your headspace.', 'Text someone you trust right now.', 'Step outside. Change your environment.'];
      case HabitCategory.fasting:
        return ['Drink a glass of water slowly.', 'Pray for 60 seconds. Offer the hunger to God.', 'Read one verse about God\'s provision.'];
      case HabitCategory.study:
        return ['Just open the book. Read one page.', 'Set a 5-minute timer. That\'s all.', 'Write down why you started this.'];
      case HabitCategory.service:
        return ['Send one encouraging text to someone.', 'Pray for someone specific right now.', 'Do one small act of kindness today.'];
      case HabitCategory.connection:
        return ['Reach out to one person right now.', 'Pray for someone you haven\'t talked to.', 'Send a simple \'thinking of you\' message.'];
      case HabitCategory.health:
        return ['Drink a glass of water right now.', 'Fill your bottle and take three sips.', 'Set a timer for your next glass.'];
      case HabitCategory.custom:
        return ['Just start. Do the smallest version of this.', 'Pray for 60 seconds. Ask God for strength.', 'Remember why you committed to this.'];
      case HabitCategory.gratitude:
        return ['Thank God for one thing right now.'];
    }
  }

  String get _selectedMicroAction {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return _microActions[dayOfYear % _microActions.length];
  }

  String get _milestoneShieldMessage {
    final habit = widget.habit;
    switch (habit.trackingType) {
      case HabitTrackingType.abstain:
        final consecutive = _milestoneService.consecutiveCleanDays(habit);
        final total = habit.totalCompletedDays();
        final next = _nextTarget(consecutive, [7, 14, 30, 60, 90, 180, 365]);
        var msg = '';
        if (consecutive > 0) {
          msg = 'You\'ve been going strong for $consecutive day${consecutive == 1 ? '' : 's'}.';
          if (next != null) {
            final rem = next - consecutive;
            msg += ' You\'re just $rem day${rem == 1 ? '' : 's'} from $next days. That\'s worth protecting.';
          }
        }
        if (total > 0 && total != consecutive) {
          msg += '\n\nEven if today is hard, those $total total clean days still stand. They\'re not going anywhere.';
        } else if (consecutive > 0) {
          msg += '\n\nBut even if today is hard, those $consecutive days still stand. They\'re not going anywhere.';
        }
        return msg.isEmpty ? 'Every moment of strength matters. God sees you in this.' : msg;

      case HabitTrackingType.timed:
        final totalMinutes = habit.totalValue();
        final hours = totalMinutes ~/ 60;
        final mins = totalMinutes.toInt() % 60;
        final timeStr = hours > 0
            ? '$hours hour${hours == 1 ? '' : 's'} and $mins minute${mins == 1 ? '' : 's'}'
            : '$mins minute${mins == 1 ? '' : 's'}';
        if (totalMinutes > 0) {
          return 'You\'ve given $timeStr to God through ${habit.name.toLowerCase()}. That\'s real. That\'s yours. Keep going.';
        }
        return 'Every minute you give matters. Start with just one.';

      case HabitTrackingType.count:
        final total = habit.totalValue().toInt();
        final unit = habit.targetUnit.isEmpty ? 'times' : habit.targetUnit;
        if (total > 0) return 'You\'ve reached $total $unit. Every single one counted. Keep building.';
        return 'Every one counts. Start with just one.';

      case HabitTrackingType.checkIn:
        final days = habit.totalCompletedDays();
        if (days > 0) {
          final next = _nextTarget(days, [7, 30, 100, 365]);
          var msg = '$days day${days == 1 ? '' : 's'} of showing up. That\'s faithfulness.';
          if (next != null) {
            final rem = next - days;
            msg += ' You\'re $rem day${rem == 1 ? '' : 's'} from $next. Worth protecting.';
          }
          return msg;
        }
        return 'Showing up matters. Even today.';
    }
  }

  int? _nextTarget(int current, List<int> thresholds) =>
      thresholds.where((t) => t > current).firstOrNull;

  Future<void> _loadCirclesAndShow() async {
    setState(() { _isLoadingCircles = true; _circleLoadFailed = false; });
    try {
      final circles = await context.read<CircleRepository>().listCircles();
      if (!mounted) return;
      if (circles.isEmpty) {
        setState(() => _showPrayerCircleMessage = true);
      } else {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: MyWalkColor.charcoal,
          builder: (_) => SOSCirclePickerView(circles: circles),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _circleLoadFailed = true);
    }
    if (mounted) setState(() => _isLoadingCircles = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(children: [
          _shieldHeader(),
          const SizedBox(height: 28),
          _refocusSection(),
          if (widget.habit.copingPlan.isNotEmpty) ...[
            const SizedBox(height: 20),
            _copingPlanSection(),
          ],
          const SizedBox(height: 20),
          _bridgeSection(),
          const SizedBox(height: 20),
          _milestoneShieldSection(),
          const SizedBox(height: 20),
          _prayerCircleSection(),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _shieldHeader() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Column(children: [
        const SizedBox(height: 16),
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              MyWalkColor.sage.withValues(alpha: 0.15 + _pulseAnim.value * 0.15),
              MyWalkColor.sage.withValues(alpha: 0.02 + _pulseAnim.value * 0.06),
            ]),
          ),
          child: const Icon(Icons.shield_rounded, size: 40, color: MyWalkColor.sage),
        ),
        const SizedBox(height: 14),
        const Text('You reached out. That takes courage.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite)),
        const SizedBox(height: 6),
        Text('Let\u2019s take this one moment at a time.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.6))),
      ]),
    );
  }

  Widget _refocusSection() {
    final verse = ScriptureLibrary.anchorVerse(widget.habit.category);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MyWalkColor.golden.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.favorite_rounded, size: 13, color: MyWalkColor.golden),
          const SizedBox(width: 6),
          const Text('Your Why',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MyWalkColor.golden)),
        ]),
        const SizedBox(height: 12),
        Text(widget.habit.purposeStatement,
            style: const TextStyle(fontSize: 15, height: 1.6, color: MyWalkColor.warmWhite)),
        const SizedBox(height: 12),
        Text('\u201C${verse.text}\u201D',
            style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic,
                color: MyWalkColor.softGold.withValues(alpha: 0.7), height: 1.5)),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(verse.reference,
              style: TextStyle(fontSize: 11, color: MyWalkColor.golden.withValues(alpha: 0.5))),
        ),
      ]),
    );
  }

  Widget _copingPlanSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyWalkColor.warmCoral.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MyWalkColor.warmCoral.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.shield_outlined, size: 13, color: MyWalkColor.warmCoral),
          const SizedBox(width: 6),
          const Text('Your Plan for Moments Like This',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MyWalkColor.warmCoral)),
        ]),
        const SizedBox(height: 12),
        Text(widget.habit.copingPlan,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, height: 1.5, color: MyWalkColor.warmWhite)),
        const SizedBox(height: 8),
        Text('You wrote this when you were strong. Trust that version of yourself.',
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
      ]),
    );
  }

  Widget _bridgeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyWalkColor.sage.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MyWalkColor.sage.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.directions_walk_rounded, size: 13, color: MyWalkColor.sage),
          const SizedBox(width: 6),
          const Text('A Small Step Right Now',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MyWalkColor.sage)),
        ]),
        const SizedBox(height: 12),
        Text(_selectedMicroAction,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, height: 1.5, color: MyWalkColor.warmWhite)),
        const SizedBox(height: 12),
        if (_microActionCompleted)
          Row(children: [
            const Icon(Icons.check_circle_rounded, size: 18, color: MyWalkColor.sage),
            const SizedBox(width: 8),
            const Text('You did it. That moment of strength matters.',
                style: TextStyle(fontSize: 14, color: MyWalkColor.sage)),
          ])
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _microActionCompleted = true),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
              label: const Text('Did it', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyWalkColor.sage,
                foregroundColor: MyWalkColor.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _milestoneShieldSection() {
    final stat = _milestoneService.lifetimeStat(widget.habit);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [MyWalkColor.golden.withValues(alpha: 0.06), MyWalkColor.golden.withValues(alpha: 0.02)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MyWalkColor.golden.withValues(alpha: 0.12), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.shield_rounded, size: 13, color: MyWalkColor.golden),
          const SizedBox(width: 6),
          const Text('What You\'re Protecting',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MyWalkColor.golden)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Text(stat.primaryValue,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: MyWalkColor.golden)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(stat.description, style: const TextStyle(fontSize: 14, color: MyWalkColor.softGold)),
            if (stat.detail != null)
              Text(stat.detail!, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
          ])),
        ]),
        const SizedBox(height: 10),
        Text(_milestoneShieldMessage,
            style: TextStyle(fontSize: 14, height: 1.6, color: Colors.white.withValues(alpha: 0.85))),
      ]),
    );
  }

  Widget _prayerCircleSection() {
    final auth = context.watch<AuthService>();
    return Column(children: [
      if (auth.isAuthenticated)
        Column(children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoadingCircles ? null : _loadCirclesAndShow,
              icon: _isLoadingCircles
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: MyWalkColor.warmCoral))
                  : const Icon(Icons.bolt_rounded, size: 16, color: MyWalkColor.warmCoral),
              label: const Text('Send SOS prayer request',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: MyWalkColor.warmCoral)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: MyWalkColor.warmCoral.withValues(alpha: 0.3), width: 0.5),
                backgroundColor: MyWalkColor.warmCoral.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_circleLoadFailed) ...[
            const SizedBox(height: 10),
            Text(
              "Couldn't connect. Check your connection and try again.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ] else if (_showPrayerCircleMessage) ...[
            const SizedBox(height: 10),
            Text(
              'Join or create a Prayer Circle first to send SOS requests.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ])
      else ...[
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _showPrayerCircleMessage = true),
            icon: const Icon(Icons.group_rounded, size: 16, color: MyWalkColor.softGold),
            label: const Text('Send a prayer request',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: MyWalkColor.softGold)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: MyWalkColor.cardBorder, width: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (_showPrayerCircleMessage) ...[
          const SizedBox(height: 10),
          Text(
            'Sign in and join a Prayer Circle to send SOS prayer requests to your community.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
          ),
        ],
      ],
    ]);
  }
}
