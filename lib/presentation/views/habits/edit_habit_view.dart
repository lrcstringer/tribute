import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_category_model.dart';
import '../../../domain/entities/fruit.dart';
import '../../../domain/services/fruit_service.dart';
import '../../utils/category_icons.dart';
import '../../providers/habit_provider.dart';
import '../../providers/habit_category_provider.dart';
import '../../providers/fruit_portfolio_provider.dart';
import '../../providers/store_provider.dart';
import '../../theme/app_theme.dart';
import '../shared/fruit_tag_chip.dart';
import '../shared/mywalk_paywall_view.dart';

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
  late final TextEditingController _fruitPurposeController;
  late double _dailyTarget;
  late String _targetUnit;
  late Set<int> _activeDays;
  late List<FruitType> _fruitTags;
  String? _categoryId;
  String? _subcategoryId;
  String? _categoryName;
  String? _subcategoryName;

  static const _copingSuggestions = ['Pray first', 'Call a friend', 'Go for a walk', 'Read my verse', 'Journal it out'];

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _nameController = TextEditingController(text: h.name);
    _purposeController = TextEditingController(text: h.purposeStatement);
    _triggerController = TextEditingController(text: h.trigger);
    _copingController = TextEditingController(text: h.copingPlan);
    _fruitPurposeController = TextEditingController(text: h.fruitPurposeStatement ?? '');
    _dailyTarget = h.dailyTarget;
    _targetUnit = h.targetUnit;
    _activeDays = h.activeDaySet;
    _fruitTags = List.from(h.fruitTags);
    _categoryId = h.categoryId;
    _subcategoryId = h.subcategoryId;
    _categoryName = h.categoryName;
    _subcategoryName = h.subcategoryName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purposeController.dispose();
    _triggerController.dispose();
    _copingController.dispose();
    _fruitPurposeController.dispose();
    super.dispose();
  }

  bool get _nameEmpty => _nameController.text.trim().isEmpty;

  void _save() {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) return;
    final isPremium = context.read<StoreProvider>().isPremium;
    final fruitPurpose = _fruitPurposeController.text.trim();
    final updated = widget.habit.copyWith(
      name: !widget.habit.isBuiltIn ? trimmed : null,
      purposeStatement: isPremium ? _purposeController.text : null,
      dailyTarget: _dailyTarget,
      targetUnit: _targetUnit,
      activeDays: (_activeDays.toList()..sort()).join(','),
      trigger: _triggerController.text,
      copingPlan: _copingController.text,
      fruitTags: _fruitTags,
      fruitPurposeStatement: fruitPurpose.isEmpty ? null : fruitPurpose,
      categoryId: _categoryId,
      subcategoryId: _subcategoryId,
      categoryName: _categoryName,
      subcategoryName: _subcategoryName,
    );
    context.read<HabitProvider>().updateHabit(updated);
    // Update portfolio habit counts for changed tags.
    context.read<FruitPortfolioProvider>().onHabitTagsChanged(
      widget.habit.fruitTags,
      _fruitTags,
    );
    Navigator.pop(context);
  }

  IconData _categoryIcon() {
    switch (widget.habit.category) {
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
    switch (widget.habit.category) {
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
    final isAbstain = widget.habit.trackingType == HabitTrackingType.abstain;

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
        title: const Text('Edit Habit',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite)),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: MyWalkColor.softGold)),
        ),
        leadingWidth: 80,
        actions: [
          TextButton(
            onPressed: _nameEmpty ? null : _save,
            child: Text('Save',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _nameEmpty ? Colors.white.withValues(alpha: 0.3) : MyWalkColor.golden,
                )),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _headerSection(),
          if (_categoryId != null) ...[
            const SizedBox(height: 16),
            _categoryChipsRow(),
          ],
          const SizedBox(height: 20),
          _nameSection(),
          const SizedBox(height: 20),
          _purposeSection(isPremium),
          const SizedBox(height: 20),
          _fruitSection(),
          if (widget.habit.trackingType == HabitTrackingType.timed) ...[
            const SizedBox(height: 20),
            _timedTargetSection(),
          ],
          if (widget.habit.trackingType == HabitTrackingType.count) ...[
            const SizedBox(height: 20),
            _countTargetSection(),
          ],
          const SizedBox(height: 20),
          _dayOfWeekSection(isAbstain),
          const SizedBox(height: 20),
          if (isAbstain) _copingSection() else _triggerSection(),
          if (!widget.habit.isBuiltIn) ...[
            const SizedBox(height: 40),
            Row(children: [
              Expanded(child: _archiveButton()),
              const SizedBox(width: 12),
              Expanded(child: _deleteSection()),
            ]),
          ],
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _fruitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SPIRITUAL GROWTH',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: MyWalkColor.softGold.withValues(alpha: 0.5),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'What fruit is this habit cultivating?',
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FruitType.values.map((fruit) {
            return FruitTagChip(
              fruit: fruit,
              isSelected: _fruitTags.contains(fruit),
              onTap: () => setState(() {
                if (_fruitTags.contains(fruit)) {
                  _fruitTags = _fruitTags.where((f) => f != fruit).toList();
                } else {
                  _fruitTags = [..._fruitTags, fruit];
                  if (_fruitPurposeController.text.isEmpty) {
                    _fruitPurposeController.text = FruitPurposeStatements.defaultFor(
                      widget.habit.category,
                      fruit,
                    );
                  }
                }
              }),
            );
          }).toList(),
        ),
        if (_fruitTags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Spiritual purpose (optional)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                color: MyWalkColor.softGold.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _fruitPurposeController,
            maxLines: 3,
            maxLength: 200,
            style: const TextStyle(fontSize: 14, color: MyWalkColor.warmWhite),
            decoration: InputDecoration(
              hintText: 'Why does this habit matter to you spiritually?',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: MyWalkColor.cardBackground,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(12),
              counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 10),
            ),
          ),
        ],
      ],
    );
  }

  Widget _archiveButton() {
    return GestureDetector(
      onTap: _confirmArchive,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: MyWalkColor.softGold.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MyWalkColor.softGold.withValues(alpha: 0.25), width: 0.5),
        ),
        child: const Center(
          child: Text(
            'Archive',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: MyWalkColor.softGold),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmArchive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MyWalkColor.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Archive habit?',
          style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: Text(
          '"${widget.habit.name}" will be hidden from your active habits. '
          'Your history and progress are preserved — you can restore it any time from Settings.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: MyWalkColor.softGold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archive', style: TextStyle(color: MyWalkColor.softGold, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<HabitProvider>().archiveHabit(widget.habit);
      if (mounted) {
        Navigator.pop(context); // dismiss EditHabitView
        Navigator.pop(context); // dismiss HabitDetailView
      }
    }
  }

  Widget _deleteSection() {
    return GestureDetector(
      onTap: _confirmDelete,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: MyWalkColor.warmCoral.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MyWalkColor.warmCoral.withValues(alpha: 0.25), width: 0.5),
        ),
        child: const Center(
          child: Text(
            'Delete Habit',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: MyWalkColor.warmCoral),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final checkIns = widget.habit.totalCompletedDays();
    final habitName = widget.habit.name;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MyWalkColor.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete habit?',
          style: TextStyle(color: MyWalkColor.warmWhite, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: Text(
          checkIns == 0
              ? '"$habitName" has no check-ins. Deleting it is permanent and cannot be undone.'
              : '"$habitName" has $checkIns ${checkIns == 1 ? 'check-in' : 'check-ins'}. Deleting it will permanently remove all your data for this habit and cannot be undone.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: MyWalkColor.softGold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: MyWalkColor.warmCoral, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<HabitProvider>().deleteHabit(widget.habit);
      if (mounted) {
        Navigator.pop(context); // dismiss EditHabitView
        Navigator.pop(context); // dismiss HabitDetailView
      }
    }
  }

  Widget _headerSection() {
    final isAbstain = widget.habit.trackingType == HabitTrackingType.abstain;
    return Row(children: [
      Icon(_categoryIcon(), size: 18,
          color: isAbstain ? MyWalkColor.warmCoral : MyWalkColor.golden),
      const SizedBox(width: 10),
      Text(widget.habit.category.rawValue,
          style: TextStyle(
            fontSize: 15,
            color: MyWalkColor.softGold.withValues(alpha: 0.7),
          )),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _trackingLabel(widget.habit.trackingType),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: MyWalkColor.softGold.withValues(alpha: 0.5)),
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
              color: MyWalkColor.softGold.withValues(alpha: 0.6))),
      const SizedBox(height: 8),
      if (widget.habit.isBuiltIn)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MyWalkColor.cardBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(_nameController.text,
              style: TextStyle(fontSize: 16, color: MyWalkColor.warmWhite.withValues(alpha: 0.6))),
        )
      else
        TextField(
          controller: _nameController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 16, color: MyWalkColor.warmWhite),
          decoration: InputDecoration(
            hintText: 'Habit name',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: MyWalkColor.cardBackground,
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
                color: MyWalkColor.softGold.withValues(alpha: 0.6))),
        if (!isPremium) ...[
          const Spacer(),
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: MyWalkColor.charcoal,
              builder: (_) => const MyWalkPaywallView(
                contextTitle: 'Custom purpose statements',
                contextMessage: "Write your own \u2018why\u2019 for each habit. Make it personal and God-centred.",
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: MyWalkColor.golden.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.workspace_premium_rounded, size: 8, color: MyWalkColor.golden),
                const SizedBox(width: 3),
                const Text('Customise',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: MyWalkColor.golden)),
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
          style: const TextStyle(fontSize: 15, color: MyWalkColor.warmWhite),
          decoration: InputDecoration(
            hintText: 'Why does this matter to you and to God?',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: MyWalkColor.cardBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(12),
          ),
        )
      else
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MyWalkColor.cardBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(_purposeController.text,
              style: TextStyle(fontSize: 15, color: MyWalkColor.softGold.withValues(alpha: 0.7))),
        ),
    ]);
  }

  Widget _timedTargetSection() {
    const minuteOptions = [15.0, 30.0, 45.0, 60.0];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Daily Goal (minutes)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: MyWalkColor.softGold.withValues(alpha: 0.6))),
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
                    color: selected ? MyWalkColor.golden : MyWalkColor.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text('${mins.toInt()}',
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500,
                          color: selected ? MyWalkColor.charcoal : MyWalkColor.softGold,
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
              color: MyWalkColor.softGold.withValues(alpha: 0.6))),
      const SizedBox(height: 8),
      Row(children: [
        Text('${_dailyTarget.toInt()}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: MyWalkColor.golden)),
        const SizedBox(width: 12),
        Column(children: [
          GestureDetector(
            onTap: () => setState(() => _dailyTarget = (_dailyTarget + 1).clamp(1, 100)),
            child: const Icon(Icons.keyboard_arrow_up, color: MyWalkColor.golden),
          ),
          GestureDetector(
            onTap: () => setState(() => _dailyTarget = (_dailyTarget - 1).clamp(1, 100)),
            child: const Icon(Icons.keyboard_arrow_down, color: MyWalkColor.golden),
          ),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: TextEditingController(text: _targetUnit),
            onChanged: (v) => _targetUnit = v,
            style: const TextStyle(fontSize: 15, color: MyWalkColor.warmWhite),
            decoration: InputDecoration(
              hintText: 'Unit',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
              filled: true,
              fillColor: MyWalkColor.cardBackground,
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
              color: MyWalkColor.softGold.withValues(alpha: 0.6))),
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
                color: selected ? MyWalkColor.golden : MyWalkColor.cardBackground,
                border: Border.all(color: selected ? MyWalkColor.golden : MyWalkColor.cardBorder, width: 0.5),
              ),
              child: Center(
                child: Text(dayLabels[i],
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: selected ? MyWalkColor.charcoal : Colors.white.withValues(alpha: 0.4),
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
              color: MyWalkColor.softGold.withValues(alpha: 0.6))),
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
                    color: selected ? MyWalkColor.golden : MyWalkColor.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(chip,
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        color: selected ? MyWalkColor.charcoal : MyWalkColor.softGold,
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
        style: const TextStyle(fontSize: 15, color: MyWalkColor.warmWhite),
        decoration: InputDecoration(
          hintText: 'Or type your own trigger\u2026',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          filled: true,
          fillColor: MyWalkColor.cardBackground,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    ]);
  }

  Widget _categoryChipsRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_categoryName != null)
          _editChip(
            label: _categoryName!,
            onTap: () => _openSubcategoryPicker(startOnCategories: true),
          ),
        if (_subcategoryName != null && _subcategoryName!.isNotEmpty)
          _editChip(
            label: _subcategoryName!,
            onTap: () => _openSubcategoryPicker(startOnCategories: false),
          ),
      ],
    );
  }

  Widget _editChip({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MyWalkColor.golden.withValues(alpha: 0.5), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: MyWalkColor.golden.withValues(alpha: 0.9)),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit_outlined, size: 11, color: MyWalkColor.golden.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  Future<void> _openSubcategoryPicker({required bool startOnCategories}) async {
    final catProvider = context.read<HabitCategoryProvider>();
    final result = await showModalBottomSheet<
        ({String categoryId, String subcategoryId, String categoryName, String subcategoryName})>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SubcategoryPickerSheet(
        initialCategoryId: startOnCategories ? null : _categoryId,
        catProvider: catProvider,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _categoryId = result.categoryId;
        _subcategoryId = result.subcategoryId;
        _categoryName = result.categoryName;
        _subcategoryName = result.subcategoryName;
      });
    }
  }

  Widget _copingSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('When I feel tempted, I will\u2026',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: MyWalkColor.softGold.withValues(alpha: 0.6))),
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
                    color: selected ? MyWalkColor.warmCoral : MyWalkColor.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(s,
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        color: selected ? MyWalkColor.charcoal : MyWalkColor.softGold,
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
        style: const TextStyle(fontSize: 15, color: MyWalkColor.warmWhite),
        decoration: InputDecoration(
          hintText: 'Or write your own plan\u2026',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          filled: true,
          fillColor: MyWalkColor.cardBackground,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    ]);
  }
}

// ── SubcategoryPickerSheet ────────────────────────────────────────────────────

typedef _CategoryResult = ({
  String categoryId,
  String subcategoryId,
  String categoryName,
  String subcategoryName
});

class SubcategoryPickerSheet extends StatefulWidget {
  final String? initialCategoryId;
  final HabitCategoryProvider catProvider;

  const SubcategoryPickerSheet({
    super.key,
    required this.initialCategoryId,
    required this.catProvider,
  });

  @override
  State<SubcategoryPickerSheet> createState() => _SubcategoryPickerSheetState();
}

class _SubcategoryPickerSheetState extends State<SubcategoryPickerSheet> {
  HabitCategoryModel? _selectedCategory;
  // 1 = category grid, 2 = subcategory grid
  late int _step;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryId != null) {
      final cat = widget.catProvider.categoryById(widget.initialCategoryId!);
      if (cat != null) {
        _selectedCategory = cat;
        _step = 2;
      } else {
        _step = 1;
      }
    } else {
      _step = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, sc) => Column(
        children: [
          _sheetHandle(),
          _sheetAppBar(),
          Expanded(
            child: SingleChildScrollView(
              controller: sc,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              child: _step == 1 ? _categoryGrid() : _subcategoryGrid(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _sheetAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          if (_step == 2)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18, color: MyWalkColor.warmWhite),
              onPressed: () => setState(() => _step = 1),
            )
          else
            IconButton(
              icon: const Icon(Icons.close, color: MyWalkColor.warmWhite),
              onPressed: () => Navigator.pop(context),
            ),
          Expanded(
            child: Text(
              _step == 1 ? 'Choose a Category' : (_selectedCategory?.name ?? ''),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: MyWalkColor.warmWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryGrid() {
    final categories = widget.catProvider.categories;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: categories.map((cat) => GestureDetector(
        onTap: () {
          if (cat.isCustom) {
            Navigator.pop<_CategoryResult>(context, (
              categoryId: cat.id,
              subcategoryId: 'custom',
              categoryName: cat.name,
              subcategoryName: '',
            ));
          } else {
            setState(() {
              _selectedCategory = cat;
              _step = 2;
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: MyWalkColor.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconForKey(cat.iconKey), size: 24, color: MyWalkColor.golden),
              const SizedBox(height: 8),
              Text(
                cat.name,
                textAlign: TextAlign.center,
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: MyWalkColor.warmWhite,
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _subcategoryGrid() {
    final cat = _selectedCategory!;
    final subcategories = widget.catProvider.subcategoriesFor(cat.id);

    return Column(
      children: subcategories.map((sub) {
        return GestureDetector(
          onTap: () => Navigator.pop<_CategoryResult>(context, (
            categoryId: cat.id,
            subcategoryId: sub.id,
            categoryName: cat.name,
            subcategoryName: sub.isCustom ? '' : sub.name,
          )),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MyWalkColor.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(iconForKey(sub.iconKey), size: 20, color: MyWalkColor.golden),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        sub.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: MyWalkColor.warmWhite,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 12, color: Colors.white.withValues(alpha: 0.3)),
                  ],
                ),
                if (sub.yourWhy.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    sub.yourWhy,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withValues(alpha: 0.5),
                      height: 1.4,
                    ),
                  ),
                ],
                if (sub.keyVerseRef != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.format_quote,
                          size: 12, color: MyWalkColor.golden.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Text(
                        sub.keyVerseRef!,
                        style: TextStyle(
                          fontSize: 11,
                          color: MyWalkColor.golden.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
