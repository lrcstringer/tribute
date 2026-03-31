import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/fruit.dart';
import '../../../domain/entities/habit.dart';
import '../../providers/fruit_portfolio_provider.dart';
import '../../providers/habit_provider.dart';
import '../../theme/app_theme.dart';
import 'fruit_library_view.dart';

class FruitDetailView extends StatelessWidget {
  final FruitType fruit;

  const FruitDetailView({super.key, required this.fruit});

  @override
  Widget build(BuildContext context) {
    final portfolio = context.watch<FruitPortfolioProvider>().portfolio;
    final habits = context.watch<HabitProvider>().habits;
    final entry = portfolio?.entryFor(fruit);
    final taggedHabits = habits.where((h) => h.fruitTags.contains(fruit)).toList();

    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
        title: Text(fruit.label,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero icon + name
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fruit.color.withValues(alpha: 0.15),
                    border: Border.all(color: fruit.color.withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: Icon(fruit.icon, size: 26, color: fruit.color),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fruit.label,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: MyWalkColor.warmWhite)),
                    Text(
                      fruit.greekWord,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: MyWalkColor.golden.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Definition
            Text(
              fruit.shortDescription,
              style: TextStyle(
                fontSize: 15,
                color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Galatians verse callout
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              decoration: BoxDecoration(
                color: fruit.color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(color: fruit.color.withValues(alpha: 0.5), width: 3),
                ),
              ),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: MyWalkColor.softGold.withValues(alpha: 0.75),
                    height: 1.6,
                  ),
                  children: [
                    const TextSpan(
                        text: 'But the fruit of the Spirit is love, joy, peace, patience, kindness, goodness, faithfulness, gentleness and self-control.'),
                    TextSpan(
                      text: '  — Galatians 5:22-23',
                      style: TextStyle(
                          fontSize: 11, color: MyWalkColor.softGold.withValues(alpha: 0.45)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stats row
            if (entry != null) _statsRow(entry),
            const SizedBox(height: 28),

            // Tagged habits
            Text(
              'YOUR HABITS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: MyWalkColor.softGold.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 10),
            if (taggedHabits.isEmpty)
              _emptyHabits(context)
            else
              ...taggedHabits.map((h) => _habitRow(h)),
            const SizedBox(height: 24),

            // CTA
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FruitLibraryView(initialFruit: fruit)),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: fruit.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: fruit.color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 16, color: fruit.color),
                    const SizedBox(width: 8),
                    Text(
                      'Add a ${fruit.label} practice',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500, color: fruit.color),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsRow(FruitPortfolioEntry entry) {
    return Row(
      children: [
        _stat('${entry.habitCount}', 'habits'),
        _statDivider(),
        _stat('${entry.weeklyCompletions}', 'this week'),
        _statDivider(),
        _stat('${entry.currentStreak}', 'wk streak'),
        _statDivider(),
        _stat('${entry.totalCompletions}', 'all-time'),
      ],
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: MyWalkColor.golden)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 10, color: MyWalkColor.softGold.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 28,
        color: Colors.white.withValues(alpha: 0.08),
      );

  Widget _habitRow(Habit habit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(habit.name,
                  style: const TextStyle(fontSize: 14, color: MyWalkColor.warmWhite)),
            ),
            Text(
              _trackingLabel(habit.trackingType),
              style: TextStyle(fontSize: 11, color: MyWalkColor.softGold.withValues(alpha: 0.4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyHabits(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyWalkColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'No habits tagged with ${fruit.label} yet.',
        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4)),
      ),
    );
  }

  String _trackingLabel(HabitTrackingType type) {
    switch (type) {
      case HabitTrackingType.checkIn: return 'Check-in';
      case HabitTrackingType.timed: return 'Timed';
      case HabitTrackingType.count: return 'Count';
      case HabitTrackingType.abstain: return 'Abstain';
    }
  }
}
