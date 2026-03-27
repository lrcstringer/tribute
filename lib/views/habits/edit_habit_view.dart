import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../providers/store_provider.dart';
import '../../theme/app_theme.dart';
import '../shared/tribute_paywall_view.dart';

class EditHabitView extends StatefulWidget {
  final Habit habit;
  final ScrollController? scrollController;
  const EditHabitView({super.key, required this.habit, this.scrollController});

  @override
  State<EditHabitView> createState() => _EditHabitViewState();
}

class _EditHabitViewState extends State<EditHabitView> {
  late final TextEditingController _nameController;
  late final TextEditingController _purposeController;
  late final TextEditingController _triggerController;
  late final TextEditingController _copingController;
  late double _dailyTarget;
  late String _targetUnit;
  late Set<int> _activeDays;

  static const _copingSuggestions = ['Pray first', 'Call a friend', 'Go for a walk', 'Read my verse', 'Journal it out'];

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _nameController = TextEditingController(text: h.name);
    _purposeController = TextEditingController(text: h.purposeStatement);
    _triggerController = TextEditingController(text: h.trigger);
    _copingController = TextEditingController(text: h.copingPlan);
    _dailyTarget = h.dailyTarget;
    _targetUnit = h.targetUnit;
    _activeDays = h.activeDaySet;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purposeController.dispose();
    _triggerController.dispose();
    _copingController.dispose();
    super.dispose();
  }

  bool get _nameEmpty => _nameController.text.trim().isEmpty;

  void _save() {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) return;
    final isPremium = context.read<StoreProvider>().isPremium;
    if (!widget.habit.isBuiltIn) widget.habit.name = trimmed;
    if (isPremium) widget.habit.purposeStatement = _purposeController.text;
    widget.habit.dailyTarget = _dailyTarget;
    widget.habit.targetUnit = _targetUnit;
    widget.habit.activeDaySet = _activeDays;
    widget.habit.trigger = _triggerController.text;
    widget.habit.copingPlan = _copingController.text;
    context.read<HabitProvider>().updateHabit(widget.habit);
    Navigator.pop(context);
  }

  IconData _categoryIcon() {
    switch (widget.habit.habitCategory) {
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

  List<String> _triggerChips() {
    switch (widget.habit.habitCategory) {
      case HabitCategory.exercise: return ['After my morning coffee', 'Before work', 'During lunch break', 'After dinner'];
      case HabitCategory.scripture: return ['First thing in the morning', 'Before bed', 'During lunch', 'After prayer'];
      case HabitCategory.rest: return ['At 10pm', 'After dinner', 'When I feel tired'];
      case HabitCategory.fasting: return ['After morning prayer', 'On Wednesdays', 'Weekly'];
      case HabitCategory.study: return ['After dinner', 'Morning routine', 'Lunch break'];
      case HabitCategory.service: return ['After church', 'On weekends', 'When I see a need'];
      case HabitCategory.connection: return ['Sunday afternoon', 'After dinner', 'During commute'];
      default: return ['In the morning', 'After lunch', 'Before bed'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<StoreProvider>().isPremium;
    final isAbstain = widget.habit.habitTrackingType == HabitTrackingType.abstain;

    return Scaffold(
      backgroundColor: TributeColor.charcoal,
      appBar: AppBar(
        backgroundColor: TributeColor.charcoal,
        foregroundColor: TributeColor.warmWhite,
        title: const Text('Edit Habit',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: TributeColor.warmWhite)),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: TributeColor.softGold)),
        ),
        leadingWidth: 80,
        actions: [
          TextButton(
            onPressed: _nameEmpty ? null : _save,
            child: Text('Save',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _nameEmpty ? Colors.white.withValues(alpha: 0.3) : TributeColor.golden,
                )),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _headerSection(),
          const SizedBox(height: 20),
          _nameSection(),
          const SizedBox(height: 20),
          _purposeSection(isPremium),
          if (widget.habit.habitTrackingType == HabitTrackingType.timed) ...[
            const SizedBox(height: 20),
            _timedTargetSection(),
          ],
          if (widget.habit.habitTrackingType == HabitTrackingType.count) ...[
            const SizedBox(height: 20),
            _countTargetSection(),
          ],
          const SizedBox(height: 20),
          _dayOfWeekSection(isAbstain),
          const SizedBox(height: 20),
          if (isAbstain) _copingSection() else _triggerSection(),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _headerSection() {
    final isAbstain = widget.habit.habitTrackingType == HabitTrackingType.abstain;
    return Row(children: [
      Icon(_categoryIcon(), size: 18,
          color: isAbstain ? TributeColor.warmCoral : TributeColor.golden),
      const SizedBox(width: 10),
      Text(widget.habit.habitCategory.rawValue,
          style: TextStyle(
            fontSize: 15,
            color: TributeColor.softGold.withValues(alpha: 0.7),
          )),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: TributeColor.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _trackingLabel(widget.habit.habitTrackingType),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: TributeColor.softGold.withValues(alpha: 0.5)),
        ),
      ),
    ]);
  }

  String _trackingLabel(HabitTrackingType type) {
    switch (type) {
      case HabitTrackingType.timed: return 'Timed';
      case HabitTrackingType.count: return 'Count';
      case HabitTrackingType.abstain: return 'Abstain';
      case HabitTrackingType.checkIn: return 'Check-in';
    }
  }

  Widget _nameSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Habit Name',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: TributeColor.softGold.withValues(alpha: 0.6))),
      const SizedBox(height: 8),
      if (widget.habit.isBuiltIn)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TributeColor.cardBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(_nameController.text,
              style: TextStyle(fontSize: 16, color: TributeColor.warmWhite.withValues(alpha: 0.6))),
        )
      else
        TextField(
          controller: _nameController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 16, color: TributeColor.warmWhite),
          decoration: InputDecoration(
            hintText: 'Habit name',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: TributeColor.cardBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
    ]);
  }

  Widget _purposeSection(bool isPremium) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Your Why',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                color: TributeColor.softGold.withValues(alpha: 0.6))),
        if (!isPremium) ...[
          const Spacer(),
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: TributeColor.charcoal,
              builder: (_) => const TributePaywallView(
                contextTitle: 'Custom purpose statements',
                contextMessage: "Write your own \u2018why\u2019 for each habit. Make it personal and God-centred.",
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: TributeColor.golden.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.workspace_premium_rounded, size: 8, color: TributeColor.golden),
                const SizedBox(width: 3),
                const Text('Customise',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: TributeColor.golden)),
              ]),
            ),
          ),
        ],
      ]),
      const SizedBox(height: 8),
      if (isPremium)
        TextField(
          controller: _purposeController,
          maxLines: 4,
          style: const TextStyle(fontSize: 15, color: TributeColor.warmWhite),
          decoration: InputDecoration(
            hintText: 'Why does this matter to you and to God?',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: TributeColor.cardBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(12),
          ),
        )
      else
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TributeColor.cardBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(_purposeController.text,
              style: TextStyle(fontSize: 15, color: TributeColor.softGold.withValues(alpha: 0.7))),
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
              padding: EdgeInsets.only(right: mins != minuteOptions.last ? 12 : 0),
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
            controller: TextEditingController(text: _targetUnit),
            onChanged: (v) => _targetUnit = v,
            style: const TextStyle(fontSize: 15, color: TributeColor.warmWhite),
            decoration: InputDecoration(
              hintText: 'Unit',
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

  Widget _dayOfWeekSection(bool isAbstain) {
    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final label = isAbstain ? 'Track days' : 'Active days';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
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
              width: 38, height: 38,
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
    final chips = _triggerChips();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('When will you do this?',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: TributeColor.softGold.withValues(alpha: 0.6))),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    ]);
  }
}
