import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/habit.dart';
import '../../models/scripture.dart';
import '../../providers/store_provider.dart';
import '../../theme/app_theme.dart';

class HabitSetupScreen extends StatefulWidget {
  final HabitCategory category;
  final void Function(
    String name,
    String purpose,
    HabitTrackingType trackingType,
    double dailyTarget,
    String targetUnit,
    String trigger,
    String copingPlan,
    Set<int> activeDays,
  ) onComplete;

  const HabitSetupScreen({super.key, required this.category, required this.onComplete});

  @override
  State<HabitSetupScreen> createState() => _HabitSetupScreenState();
}

class _HabitSetupScreenState extends State<HabitSetupScreen> {
  final _nameController = TextEditingController();
  final _purposeController = TextEditingController();
  final _triggerController = TextEditingController();
  final _copingController = TextEditingController();
  HabitTrackingType _trackingType = HabitTrackingType.checkIn;
  double _dailyTarget = 1;
  String _targetUnit = '';
  final Set<int> _activeDays = {1, 2, 3, 4, 5, 6, 7};

  @override
  void initState() {
    super.initState();
    _nameController.text = _defaultName(widget.category);
    _purposeController.text = widget.category.defaultPurpose;
    _trackingType = widget.category.suggestedTrackingType;
    _dailyTarget = _defaultTarget(widget.category);
    _targetUnit = _defaultUnit(widget.category);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purposeController.dispose();
    _triggerController.dispose();
    _copingController.dispose();
    super.dispose();
  }

  String _defaultName(HabitCategory category) {
    switch (category) {
      case HabitCategory.exercise: return 'Exercise';
      case HabitCategory.scripture: return 'Bible Reading';
      case HabitCategory.rest: return 'Sleep';
      case HabitCategory.fasting: return 'Fasting';
      case HabitCategory.study: return 'Study';
      case HabitCategory.service: return 'Serve Someone';
      case HabitCategory.connection: return 'Call a Friend';
      case HabitCategory.health: return 'Drink Water';
      default: return '';
    }
  }

  double _defaultTarget(HabitCategory category) {
    switch (category) {
      case HabitCategory.exercise: return 30;
      case HabitCategory.scripture: return 15;
      case HabitCategory.study: return 30;
      case HabitCategory.health: return 8;
      default: return 1;
    }
  }

  String _defaultUnit(HabitCategory category) {
    switch (category) {
      case HabitCategory.exercise:
      case HabitCategory.scripture:
      case HabitCategory.study: return 'minutes';
      case HabitCategory.service: return 'acts';
      case HabitCategory.health: return 'glasses';
      default: return '';
    }
  }

  List<String> _triggerChips(HabitCategory category) {
    switch (category) {
      case HabitCategory.exercise: return ['After my morning coffee', 'Before work', 'During lunch break', 'After dinner'];
      case HabitCategory.scripture: return ['First thing in the morning', 'Before bed', 'During lunch', 'After prayer'];
      case HabitCategory.rest: return ['At 10pm', 'After dinner', 'When I feel tired'];
      case HabitCategory.fasting: return ['After morning prayer', 'On Wednesdays', 'Weekly'];
      case HabitCategory.study: return ['After dinner', 'Morning routine', 'Lunch break'];
      case HabitCategory.service: return ['After church', 'On weekends', 'When I see a need'];
      case HabitCategory.connection: return ['Sunday afternoon', 'After dinner', 'During commute'];
      case HabitCategory.health: return ['With every meal', 'First thing in the morning', 'After exercise', 'Before bed'];
      default: return ['In the morning', 'After lunch', 'Before bed'];
    }
  }

  static const _copingSuggestions = ['Pray first', 'Call a friend', 'Go for a walk', 'Read my verse', 'Journal it out'];

  IconData _categoryIcon() {
    switch (widget.category) {
      case HabitCategory.exercise: return Icons.fitness_center;
      case HabitCategory.scripture: return Icons.menu_book;
      case HabitCategory.rest: return Icons.bedtime;
      case HabitCategory.fasting: return Icons.no_food;
      case HabitCategory.study: return Icons.school;
      case HabitCategory.service: return Icons.volunteer_activism;
      case HabitCategory.connection: return Icons.people;
      case HabitCategory.health: return Icons.favorite;
      case HabitCategory.abstain: return Icons.shield_rounded;
      default: return Icons.auto_awesome;
    }
  }

  @override
  Widget build(BuildContext context) {
    final verse = ScriptureLibrary.anchorVerse(widget.category);
    final isAbstain = widget.category == HabitCategory.abstain;
    final nameEmpty = _nameController.text.trim().isEmpty;

    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(_categoryIcon(), size: 20,
                  color: isAbstain ? TributeColor.warmCoral : TributeColor.golden),
              const SizedBox(width: 10),
              Text(widget.category.rawValue,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: TributeColor.softGold)),
            ]),
            const SizedBox(height: 24),
            if (isAbstain) _abstainNameSection() else _nameSection(),
            const SizedBox(height: 24),
            _purposeSection(),
            const SizedBox(height: 24),
            _verseSection(verse),
            if (!isAbstain) ...[
              const SizedBox(height: 24),
              _trackingSection(),
              const SizedBox(height: 24),
              if (_trackingType == HabitTrackingType.timed) _timedTargetSection(),
              if (_trackingType == HabitTrackingType.count) _countTargetSection(),
            ],
            const SizedBox(height: 24),
            _dayOfWeekSection(),
            const SizedBox(height: 24),
            if (isAbstain) _copingSection() else _triggerSection(),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Opacity(
          opacity: nameEmpty ? 0.5 : 1.0,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: nameEmpty ? null : _submit,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Set this habit',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: TributeColor.golden,
                foregroundColor: TributeColor.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  void _submit() {
    widget.onComplete(
      _nameController.text.trim(),
      _purposeController.text,
      _trackingType,
      _dailyTarget,
      _targetUnit,
      _triggerController.text,
      _copingController.text,
      _activeDays,
    );
  }

  Widget _nameSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Habit Name',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: TributeColor.softGold.withValues(alpha: 0.6))),
      const SizedBox(height: 8),
      TextField(
        controller: _nameController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 16, color: TributeColor.warmWhite),
        decoration: InputDecoration(
          hintText: 'e.g. Morning run',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          filled: true,
          fillColor: TributeColor.cardBackground,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    ]);
  }

  Widget _abstainNameSection() {
    const presets = ['No alcohol', 'No porn', 'No doom-scrolling', 'No junk food', 'No smoking'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('What are you letting go of?',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: TributeColor.softGold.withValues(alpha: 0.6))),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: presets.map((preset) {
          final selected = _nameController.text == preset;
          return GestureDetector(
            onTap: () => setState(() => _nameController.text = preset),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? TributeColor.warmCoral : TributeColor.cardBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(preset,
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: selected ? TributeColor.charcoal : TributeColor.softGold,
                  )),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _nameController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 15, color: TributeColor.warmWhite),
        decoration: InputDecoration(
          hintText: 'Or type your own...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          filled: true,
          fillColor: TributeColor.cardBackground,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    ]);
  }

  Widget _purposeSection() {
    final isPremium = context.read<StoreProvider>().isPremium;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Your Why',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                color: TributeColor.softGold.withValues(alpha: 0.6))),
        if (!isPremium) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: TributeColor.golden.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('PRO',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: TributeColor.golden)),
          ),
        ],
      ]),
      const SizedBox(height: 4),
      Text(isPremium ? 'Why does this matter to you and to God?' : 'Upgrade to write a custom purpose statement.',
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
      const SizedBox(height: 8),
      TextField(
        controller: _purposeController,
        maxLines: 4,
        readOnly: !isPremium,
        style: TextStyle(fontSize: 15, color: isPremium ? TributeColor.warmWhite : TributeColor.warmWhite.withValues(alpha: 0.5)),
        decoration: InputDecoration(
          hintText: 'Your purpose for this habit...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          filled: true,
          fillColor: isPremium ? TributeColor.cardBackground : TributeColor.cardBackground.withValues(alpha: 0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    ]);
  }

  Widget _verseSection(Scripture verse) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Your Anchor Verse',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: TributeColor.softGold.withValues(alpha: 0.6))),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TributeColor.golden.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TributeColor.golden.withValues(alpha: 0.12), width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('\u201C${verse.text}\u201D',
              style: TextStyle(
                fontSize: 14, fontStyle: FontStyle.italic, height: 1.6,
                color: TributeColor.softGold.withValues(alpha: 0.7),
              )),
          const SizedBox(height: 6),
          Text('- ${verse.reference}',
              style: TextStyle(fontSize: 12, color: TributeColor.golden.withValues(alpha: 0.5))),
        ]),
      ),
    ]);
  }

  Widget _trackingSection() {
    const types = [HabitTrackingType.checkIn, HabitTrackingType.timed, HabitTrackingType.count];
    final labels = {
      HabitTrackingType.checkIn: 'Yes/No',
      HabitTrackingType.timed: 'Timed',
      HabitTrackingType.count: 'Count',
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('How do you want to track this?',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: TributeColor.softGold.withValues(alpha: 0.6))),
      const SizedBox(height: 8),
      Row(
        children: types.map((type) {
          final selected = _trackingType == type;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: type != types.last ? 8 : 0),
              child: GestureDetector(
                onTap: () => setState(() {
                  _trackingType = type;
                  if (type == HabitTrackingType.timed) {
                    _dailyTarget = 30; _targetUnit = 'minutes';
                  } else if (type == HabitTrackingType.count) {
                    _dailyTarget = 8; _targetUnit = '';
                  } else {
                    _dailyTarget = 1; _targetUnit = '';
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? TributeColor.golden : TributeColor.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(labels[type]!,
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500,
                          color: selected ? TributeColor.charcoal : TributeColor.softGold,
                        )),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _timedTargetSection() {
    const minuteOptions = [15.0, 30.0, 45.0, 60.0];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Daily Goal (minutes)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: TributeColor.softGold.withValues(alpha: 0.6))),
      const SizedBox(height: 8),
      Row(
        children: minuteOptions.map((mins) {
          final selected = _dailyTarget == mins;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: mins != minuteOptions.last ? 10 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _dailyTarget = mins),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? TributeColor.golden : TributeColor.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text('${mins.toInt()}',
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500,
                          color: selected ? TributeColor.charcoal : TributeColor.softGold,
                        )),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _countTargetSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Daily Goal',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: TributeColor.softGold.withValues(alpha: 0.6))),
      const SizedBox(height: 8),
      Row(children: [
        Text('${_dailyTarget.toInt()}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: TributeColor.golden)),
        const SizedBox(width: 12),
        Column(children: [
          GestureDetector(
            onTap: () => setState(() => _dailyTarget = (_dailyTarget + 1).clamp(1, 100)),
            child: const Icon(Icons.keyboard_arrow_up, color: TributeColor.golden),
          ),
          GestureDetector(
            onTap: () => setState(() => _dailyTarget = (_dailyTarget - 1).clamp(1, 100)),
            child: const Icon(Icons.keyboard_arrow_down, color: TributeColor.golden),
          ),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: TextEditingController(text: _targetUnit)
              ..selection = TextSelection.collapsed(offset: _targetUnit.length),
            onChanged: (v) => _targetUnit = v,
            style: const TextStyle(fontSize: 15, color: TributeColor.warmWhite),
            decoration: InputDecoration(
              hintText: 'Unit (e.g. glasses)',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
              filled: true,
              fillColor: TributeColor.cardBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
        ),
      ]),
    ]);
  }

  Widget _dayOfWeekSection() {
    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Active days',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: TributeColor.softGold.withValues(alpha: 0.6))),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final day = i + 1;
          final selected = _activeDays.contains(day);
          return GestureDetector(
            onTap: () => setState(() {
              if (selected) {
                _activeDays.remove(day);
              } else {
                _activeDays.add(day);
              }
            }),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? TributeColor.golden : TributeColor.cardBackground,
                border: Border.all(color: selected ? TributeColor.golden : TributeColor.cardBorder, width: 0.5),
              ),
              child: Center(
                child: Text(dayLabels[i],
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: selected ? TributeColor.charcoal : Colors.white.withValues(alpha: 0.4),
                    )),
              ),
            ),
          );
        }),
      ),
    ]);
  }

  Widget _triggerSection() {
    final chips = _triggerChips(widget.category);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('When will you do this?',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: TributeColor.softGold.withValues(alpha: 0.6))),
      const SizedBox(height: 4),
      Text('Anchor it to something you already do.',
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips.map((chip) {
            final selected = _triggerController.text == chip;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _triggerController.text = chip),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? TributeColor.golden : TributeColor.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(chip,
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        color: selected ? TributeColor.charcoal : TributeColor.softGold,
                      )),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _triggerController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 15, color: TributeColor.warmWhite),
        decoration: InputDecoration(
          hintText: 'Or type your own trigger\u2026',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          filled: true,
          fillColor: TributeColor.cardBackground,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    ]);
  }

  Widget _copingSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('When I feel tempted, I will\u2026',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: TributeColor.softGold.withValues(alpha: 0.6))),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _copingSuggestions.map((s) {
            final selected = _copingController.text == s;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _copingController.text = s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? TributeColor.warmCoral : TributeColor.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(s,
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        color: selected ? TributeColor.charcoal : TributeColor.softGold,
                      )),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _copingController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 15, color: TributeColor.warmWhite),
        decoration: InputDecoration(
          hintText: 'Or write your own plan\u2026',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          filled: true,
          fillColor: TributeColor.cardBackground,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    ]);
  }
}
