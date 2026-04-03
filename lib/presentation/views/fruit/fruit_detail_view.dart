import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/fruit.dart';
import '../../../domain/entities/habit.dart' show Habit;
import '../../providers/fruit_portfolio_provider.dart';
import '../../providers/habit_provider.dart';
import '../../theme/app_theme.dart';
import 'fruit_library_view.dart';
import '../journal/journal_entry_composer.dart';

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

            // Key verse — tappable
            GestureDetector(
              onTap: () => _showSupportingVerses(context),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                decoration: BoxDecoration(
                  color: fruit.color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(color: fruit.color.withValues(alpha: 0.5), width: 3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fruit.keyVerse.text,
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: MyWalkColor.softGold.withValues(alpha: 0.85),
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\u2014 ${fruit.keyVerse.reference}',
                            style: TextStyle(
                              fontSize: 11,
                              color: MyWalkColor.softGold.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.menu_book_outlined, size: 11, color: fruit.color.withValues(alpha: 0.6)),
                              const SizedBox(width: 4),
                              Text(
                                'More scriptures',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: fruit.color.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.chevron_right, size: 13, color: fruit.color.withValues(alpha: 0.5)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stats row
            if (entry != null) _statsRow(entry),
            const SizedBox(height: 28),

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

            // Linked practices chips
            if (taggedHabits.isNotEmpty) ...[
              const SizedBox(height: 12),
              _LinkedPracticesChips(habits: taggedHabits, fruit: fruit),
            ],

            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => JournalEntryComposer(
                    fruitTag: fruit,
                    sourceType: 'fruit',
                  ),
                ),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: fruit.color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: fruit.color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_note, size: 16, color: fruit.color.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Text(
                      'Add a journal entry',
                      style: TextStyle(
                        fontSize: 14,
                        color: fruit.color.withValues(alpha: 0.7),
                      ),
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

  void _showSupportingVerses(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyWalkColor.charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(fruit.icon, size: 18, color: fruit.color),
                  const SizedBox(width: 8),
                  Text(
                    '${fruit.label} — Scripture',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: fruit.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                itemCount: fruit.supportingVerses.length,
                separatorBuilder: (_, _) => Divider(
                  color: Colors.white.withValues(alpha: 0.07),
                  height: 28,
                ),
                itemBuilder: (_, i) {
                  final verse = fruit.supportingVerses[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verse.text,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: MyWalkColor.warmWhite.withValues(alpha: 0.85),
                          height: 1.65,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '\u2014 ${verse.reference}',
                        style: TextStyle(
                          fontSize: 12,
                          color: fruit.color.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  );
                },
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

}

// ── Linked Practices Chips ────────────────────────────────────────────────────

class _LinkedPracticesChips extends StatelessWidget {
  final List<Habit> habits;
  final FruitType fruit;

  const _LinkedPracticesChips({required this.habits, required this.fruit});

  @override
  Widget build(BuildContext context) {
    const maxVisible = 3;
    final visible = habits.take(maxVisible).toList();
    final overflow = habits.length - maxVisible;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...visible.map((h) => _chip(h.name)),
        if (overflow > 0)
          _chip('+$overflow more', dim: true),
      ],
    );
  }

  Widget _chip(String label, {bool dim = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fruit.color.withValues(alpha: dim ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fruit.color.withValues(alpha: dim ? 0.2 : 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: fruit.color.withValues(alpha: dim ? 0.4 : 0.8),
        ),
      ),
    );
  }
}
