import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/fruit.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/services/fruit_service.dart';
import '../../providers/fruit_portfolio_provider.dart';
import '../../providers/habit_provider.dart';
import '../../theme/app_theme.dart';
import '../shared/fruit_tag_chip.dart';

class FruitTaggingScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const FruitTaggingScreen({super.key, required this.onNext, required this.onSkip});

  @override
  State<FruitTaggingScreen> createState() => _FruitTaggingScreenState();
}

class _FruitTaggingScreenState extends State<FruitTaggingScreen> {
  // habitId → selected fruit tags
  late Map<String, List<FruitType>> _tagsByHabit;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final habits = context.read<HabitProvider>().habits;
    // Pre-populate with suggestions based on category
    _tagsByHabit = {
      for (final h in habits)
        h.id: List<FruitType>.from(
          h.fruitTags.isNotEmpty
              ? h.fruitTags
              : FruitSuggestionService.suggest(h.category),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitProvider>().habits;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Connect your habits to the fruit.',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: MyWalkColor.warmWhite,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'See which fruits your habits are cultivating. You can always change this later.',
            style: TextStyle(
              fontSize: 14,
              color: MyWalkColor.warmWhite.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: ListView.separated(
              itemCount: habits.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _habitCard(habits[i]),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: MyWalkColor.golden,
                foregroundColor: MyWalkColor.charcoal,
                disabledBackgroundColor: MyWalkColor.golden.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: MyWalkColor.charcoal),
                    )
                  : const Text('Continue',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: widget.onSkip,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "I'll do this later",
                  style: TextStyle(
                    fontSize: 13,
                    color: MyWalkColor.softGold.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _habitCard(Habit habit) {
    final selected = _tagsByHabit[habit.id] ?? [];
    final suggested = FruitSuggestionService.suggest(habit.category);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            habit.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: MyWalkColor.warmWhite,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: FruitType.values.map((fruit) {
              final isSelected = selected.contains(fruit);
              final isSuggested = !isSelected && suggested.contains(fruit);
              return FruitTagChip(
                fruit: fruit,
                isSelected: isSelected,
                isSuggested: isSuggested,
                onTap: () => _toggleTag(habit.id, fruit),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _toggleTag(String habitId, FruitType fruit) {
    setState(() {
      final current = List<FruitType>.from(_tagsByHabit[habitId] ?? []);
      if (current.contains(fruit)) {
        current.remove(fruit);
      } else {
        current.add(fruit);
      }
      _tagsByHabit[habitId] = current;
    });
  }

  Future<void> _onContinue() async {
    setState(() => _isSaving = true);
    try {
      final habitProvider = context.read<HabitProvider>();
      final portfolioProvider = context.read<FruitPortfolioProvider>();

      for (final habit in habitProvider.habits) {
        final newTags = _tagsByHabit[habit.id] ?? [];
        final oldTags = habit.fruitTags;
        // Only update if tags actually changed
        if (_tagsChanged(oldTags, newTags)) {
          await habitProvider.updateHabit(
            habit.copyWith(fruitTags: newTags),
          );
          await portfolioProvider.onHabitTagsChanged(oldTags, newTags);
        }
      }
      if (mounted) widget.onNext();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't save fruit tags. You can add them later in habit settings."),
            duration: Duration(seconds: 3),
          ),
        );
        widget.onNext();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _tagsChanged(List<FruitType> a, List<FruitType> b) {
    if (a.length != b.length) return true;
    final setA = a.toSet();
    final setB = b.toSet();
    return setA.difference(setB).isNotEmpty || setB.difference(setA).isNotEmpty;
  }
}
