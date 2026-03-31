import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/fruit.dart';
import '../../../domain/services/fruit_service.dart';
import '../../providers/habit_provider.dart';
import '../../providers/fruit_portfolio_provider.dart';
import '../../providers/store_provider.dart';
import '../../theme/app_theme.dart';
import '../shared/day_of_week_picker.dart';
import '../shared/fruit_tag_chip.dart';
import '../shared/mywalk_paywall_view.dart';

class AddHabitView extends StatefulWidget {
  final ScrollController? scrollController;

  const AddHabitView({super.key, this.scrollController});

  @override
  State<AddHabitView> createState() => _AddHabitViewState();
}

class _AddHabitViewState extends State<AddHabitView> {
  HabitCategory? _selectedCategory;
  String _habitName = '';
  String _purposeStatement = '';
  HabitTrackingType _trackingType = HabitTrackingType.checkIn;
  double _dailyTarget = 1;
  String _targetUnit = '';
  Set<int> _activeDays = {1, 2, 3, 4, 5, 6, 7};
  String _trigger = '';
  String _copingPlan = '';
  int _step = 1;
  List<FruitType> _selectedFruits = [];
  String _fruitPurposeStatement = '';
  List<FruitType> _suggestedFruits = [];

  static const _selectableCategories = [
    HabitCategory.exercise,
    HabitCategory.scripture,
    HabitCategory.rest,
    HabitCategory.fasting,
    HabitCategory.study,
    HabitCategory.service,
    HabitCategory.connection,
    HabitCategory.health,
  ];

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<StoreProvider>().isPremium;

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        title: Text(
          _step == 1 ? 'Choose a Habit' : 'Set It Up',
          style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        leading: _step == 2
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: MyWalkColor.warmWhite, size: 18),
                onPressed: () => setState(() => _step = 1),
              )
            : IconButton(
                icon: const Icon(Icons.close, color: MyWalkColor.warmWhite),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          if (_step == 1)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: MyWalkColor.softGold.withValues(alpha: 0.8))),
            ),
        ],
      ),
      body: SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: _step == 1 ? _categorySelection() : _habitDetails(isPremium),
      ),
    );
  }

  Widget _categorySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What do you want to give to God this season?',
          style: TextStyle(fontSize: 18, color: MyWalkColor.warmWhite, height: 1.4),
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: _selectableCategories.map((category) {
            return GestureDetector(
              onTap: () => _selectCategory(category),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: MyWalkColor.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_categoryIcon(category), color: MyWalkColor.golden, size: 24),
                    const SizedBox(height: 8),
                    Text(
                      _categoryLabel(category),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: MyWalkColor.warmWhite),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _specialCategoryTile(
          icon: Icons.shield_rounded,
          iconColor: MyWalkColor.warmCoral,
          title: "I'm letting go of something",
          subtitle: "Break a bad habit with God's help",
          borderColor: MyWalkColor.warmCoral.withValues(alpha: 0.2),
          onTap: () => _selectCategory(HabitCategory.abstain),
        ),
        const SizedBox(height: 12),
        _specialCategoryTile(
          icon: Icons.auto_awesome,
          iconColor: MyWalkColor.golden,
          title: 'Something else entirely',
          subtitle: 'Create a fully custom habit',
          borderColor: MyWalkColor.golden.withValues(alpha: 0.15),
          onTap: () => _selectCategory(HabitCategory.custom),
        ),
      ],
    );
  }

  Widget _specialCategoryTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: MyWalkColor.warmWhite)),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: Colors.white.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _habitDetails(bool isPremium) {
    final isAbstain = _selectedCategory == HabitCategory.abstain;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedCategory != null) ...[
          Row(
            children: [
              Icon(_categoryIcon(_selectedCategory!), size: 18, color: MyWalkColor.golden),
              const SizedBox(width: 8),
              Text(
                _categoryLabel(_selectedCategory!),
                style: TextStyle(fontSize: 14, color: MyWalkColor.softGold.withValues(alpha: 0.7)),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // Name
        _label('Habit Name'),
        const SizedBox(height: 8),
        _textField(
          hint: 'e.g. Morning run',
          value: _habitName,
          onChanged: (v) => setState(() => _habitName = v),
        ),
        const SizedBox(height: 20),

        // Purpose
        Row(
          children: [
            _label('Your Why', inline: true),
            if (!isPremium) ...[
              const Spacer(),
              GestureDetector(
                onTap: () => _showPaywall(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: MyWalkColor.golden.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.workspace_premium, size: 10, color: MyWalkColor.golden),
                      const SizedBox(width: 3),
                      Text('Customise',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: MyWalkColor.golden)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (isPremium)
          _textField(
            hint: 'Why does this matter to you and to God?',
            value: _purposeStatement,
            onChanged: (v) => setState(() => _purposeStatement = v),
            maxLines: 3,
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MyWalkColor.surfaceOverlay,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _purposeStatement,
              style: TextStyle(fontSize: 14, color: MyWalkColor.softGold.withValues(alpha: 0.7)),
            ),
          ),
        const SizedBox(height: 20),

        // Fruit tags
        _fruitTagSection(),
        const SizedBox(height: 20),

        // Tracking type (not for abstain)
        if (!isAbstain) ...[
          _label('Tracking Type'),
          const SizedBox(height: 8),
          Row(
            children: [HabitTrackingType.checkIn, HabitTrackingType.timed, HabitTrackingType.count].map((type) {
              final selected = _trackingType == type;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _setTrackingType(type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? MyWalkColor.golden : MyWalkColor.surfaceOverlay,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _trackingTypeLabel(type),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: selected ? MyWalkColor.charcoal : MyWalkColor.softGold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // Timed goal
        if (_trackingType == HabitTrackingType.timed) ...[
          _label('Daily Goal (minutes)'),
          const SizedBox(height: 8),
          Row(
            children: [15.0, 30.0, 45.0, 60.0].map((mins) {
              final selected = _dailyTarget == mins;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _dailyTarget = mins),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? MyWalkColor.golden : MyWalkColor.surfaceOverlay,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${mins.toInt()}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: selected ? MyWalkColor.charcoal : MyWalkColor.softGold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // Count goal
        if (_trackingType == HabitTrackingType.count) ...[
          _label('Daily Goal'),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: MyWalkColor.surfaceOverlay,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _dailyTarget > 1 ? () => setState(() => _dailyTarget--) : null,
                      icon: const Icon(Icons.remove, size: 18, color: MyWalkColor.softGold),
                    ),
                    Text(
                      '${_dailyTarget.toInt()}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: MyWalkColor.golden),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _dailyTarget++),
                      icon: const Icon(Icons.add, size: 18, color: MyWalkColor.softGold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _textField(
                  hint: 'Unit (e.g. glasses)',
                  value: _targetUnit,
                  onChanged: (v) => setState(() => _targetUnit = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // Abstain presets
        if (isAbstain) ...[
          _label("What are you letting go of?"),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['No alcohol', 'No porn', 'No doom-scrolling', 'No junk food', 'No smoking'].map((preset) {
              final selected = _habitName == preset;
              return GestureDetector(
                onTap: () => setState(() => _habitName = preset),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? MyWalkColor.warmCoral : MyWalkColor.surfaceOverlay,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    preset,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: selected ? MyWalkColor.charcoal : MyWalkColor.softGold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // Day of week picker
        DayOfWeekPicker(
          selected: _activeDays,
          onChanged: (days) => setState(() => _activeDays = days),
          isAbstain: isAbstain,
        ),
        const SizedBox(height: 20),

        // Anchoring section
        _anchoringSection(isAbstain),
        const SizedBox(height: 28),

        // Save button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _habitName.trim().isEmpty ? null : _saveHabit,
            style: ElevatedButton.styleFrom(
              backgroundColor: MyWalkColor.golden,
              foregroundColor: MyWalkColor.charcoal,
              disabledBackgroundColor: MyWalkColor.golden.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Set this habit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _anchoringSection(bool isAbstain) {
    if (isAbstain) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('When I feel tempted, I will\u2026'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Pray first', 'Call a friend', 'Go for a walk', 'Read my verse', 'Journal it out']
                  .map((s) => _chipButton(s, _copingPlan == s, MyWalkColor.warmCoral,
                      () => setState(() => _copingPlan = s)))
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
          _textField(
            hint: 'Or write your own plan\u2026',
            value: _copingPlan,
            onChanged: (v) => setState(() => _copingPlan = v),
          ),
        ],
      );
    }

    final chips = _triggerChips(_selectedCategory ?? HabitCategory.custom);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('When will you do this?'),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: chips
                .map((s) => _chipButton(s, _trigger == s, MyWalkColor.golden,
                    () => setState(() => _trigger = s)))
                .toList(),
          ),
        ),
        const SizedBox(height: 10),
        _textField(
          hint: 'Or type your own trigger\u2026',
          value: _trigger,
          onChanged: (v) => setState(() => _trigger = v),
        ),
      ],
    );
  }

  Widget _chipButton(String label, bool selected, Color activeColor, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? activeColor : MyWalkColor.surfaceOverlay,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? MyWalkColor.charcoal : MyWalkColor.softGold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _fruitTagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('What fruit is this cultivating?'),
        const SizedBox(height: 4),
        Text(
          'Connect this habit to your spiritual growth. (Optional)',
          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FruitType.values.map((fruit) {
            return FruitTagChip(
              fruit: fruit,
              isSelected: _selectedFruits.contains(fruit),
              isSuggested: !_selectedFruits.contains(fruit) && _suggestedFruits.contains(fruit),
              onTap: () {
                setState(() {
                  if (_selectedFruits.contains(fruit)) {
                    _selectedFruits = _selectedFruits.where((f) => f != fruit).toList();
                  } else {
                    _selectedFruits = [..._selectedFruits, fruit];
                  }
                  // Auto-populate fruit purpose statement with default when first fruit selected.
                  if (_selectedFruits.isNotEmpty && _fruitPurposeStatement.isEmpty) {
                    _fruitPurposeStatement = FruitPurposeStatements.defaultFor(
                      _selectedCategory ?? HabitCategory.custom,
                      _selectedFruits.first,
                    );
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_selectedFruits.isNotEmpty) ...[
          const SizedBox(height: 12),
          _label('Spiritual purpose (optional)'),
          const SizedBox(height: 6),
          _textField(
            hint: 'Why does this habit matter to you spiritually?',
            value: _fruitPurposeStatement,
            onChanged: (v) => setState(() => _fruitPurposeStatement = v),
            maxLines: 2,
          ),
        ],
        if (_selectedFruits.isEmpty) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _suggestedFruits = []),
            child: Text(
              "I'll decide later",
              style: TextStyle(
                fontSize: 11,
                color: MyWalkColor.softGold.withValues(alpha: 0.45),
                decoration: TextDecoration.underline,
                decorationColor: MyWalkColor.softGold.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _label(String text, {bool inline = false}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: MyWalkColor.softGold.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _textField({
    required String hint,
    required String value,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    return TextField(
      controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
      onChanged: onChanged,
      maxLines: maxLines,
      style: const TextStyle(color: MyWalkColor.warmWhite, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
        filled: true,
        fillColor: MyWalkColor.surfaceOverlay,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  void _selectCategory(HabitCategory category) {
    setState(() {
      _selectedCategory = category;
      _trackingType = category.suggestedTrackingType;
      _habitName = _defaultName(category);
      _purposeStatement = category.defaultPurpose;
      _targetUnit = _defaultUnit(category);
      _dailyTarget = _defaultTarget(category);
      _suggestedFruits = FruitSuggestionService.suggest(category);
      _selectedFruits = [];
      _fruitPurposeStatement = '';
      _step = 2;
    });
  }

  void _setTrackingType(HabitTrackingType type) {
    setState(() {
      _trackingType = type;
      if (type == HabitTrackingType.timed) {
        _dailyTarget = 30;
        _targetUnit = 'minutes';
      } else if (type == HabitTrackingType.count) {
        _dailyTarget = 8;
        _targetUnit = '';
      } else {
        _dailyTarget = 1;
        _targetUnit = '';
      }
    });
  }

  void _saveHabit() {
    final category = _selectedCategory;
    if (category == null) return;
    final trimmed = _habitName.trim();
    if (trimmed.isEmpty) return;
    final isPremium = context.read<StoreProvider>().isPremium;
    final purpose = isPremium ? _purposeStatement : category.defaultPurpose;
    context.read<HabitProvider>().addHabit(
      name: trimmed,
      category: category,
      trackingType: _trackingType,
      purpose: purpose,
      dailyTarget: _dailyTarget,
      targetUnit: _targetUnit,
      activeDays: _activeDays,
      trigger: _trigger,
      copingPlan: _copingPlan,
      fruitTags: _selectedFruits,
      fruitPurposeStatement: _fruitPurposeStatement.trim().isEmpty
          ? null
          : _fruitPurposeStatement.trim(),
    );
    if (_selectedFruits.isNotEmpty) {
      context.read<FruitPortfolioProvider>().onHabitTagsChanged([], _selectedFruits);
    }
    Navigator.pop(context);
  }

  void _showPaywall(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      builder: (_) => const MyWalkPaywallView(),
    );
  }

  String _trackingTypeLabel(HabitTrackingType type) {
    switch (type) {
      case HabitTrackingType.checkIn: return 'Yes/No';
      case HabitTrackingType.timed: return 'Timed';
      case HabitTrackingType.count: return 'Count';
      case HabitTrackingType.abstain: return 'Abstain';
    }
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

  IconData _categoryIcon(HabitCategory category) {
    switch (category) {
      case HabitCategory.exercise: return Icons.fitness_center;
      case HabitCategory.scripture: return Icons.menu_book;
      case HabitCategory.rest: return Icons.bedtime;
      case HabitCategory.fasting: return Icons.no_food;
      case HabitCategory.study: return Icons.school;
      case HabitCategory.service: return Icons.volunteer_activism;
      case HabitCategory.connection: return Icons.people;
      case HabitCategory.health: return Icons.favorite;
      case HabitCategory.abstain: return Icons.shield_rounded;
      case HabitCategory.custom: return Icons.auto_awesome;
      case HabitCategory.gratitude: return Icons.auto_awesome;
    }
  }

  String _categoryLabel(HabitCategory category) {
    switch (category) {
      case HabitCategory.exercise: return 'Exercise';
      case HabitCategory.scripture: return 'Scripture';
      case HabitCategory.rest: return 'Rest';
      case HabitCategory.fasting: return 'Fasting';
      case HabitCategory.study: return 'Study';
      case HabitCategory.service: return 'Service';
      case HabitCategory.connection: return 'Connection';
      case HabitCategory.health: return 'Health';
      case HabitCategory.abstain: return 'Abstain';
      case HabitCategory.custom: return 'Custom';
      case HabitCategory.gratitude: return 'Gratitude';
    }
  }
}
