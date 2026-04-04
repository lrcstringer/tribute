import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/beatitude.dart';
import '../../../domain/entities/habit.dart';
import '../../providers/habit_provider.dart';
import '../../theme/app_theme.dart';

const _kAccent = Color(0xFF9B8BB4);

class BeatitudePracticeDetailSheet extends StatefulWidget {
  final BeatitudePractice practice;
  final BeatitudeModel beatitude;

  const BeatitudePracticeDetailSheet({
    super.key,
    required this.practice,
    required this.beatitude,
  });

  static Future<void> show(
    BuildContext context,
    BeatitudePractice practice,
    BeatitudeModel beatitude,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: MyWalkColor.charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BeatitudePracticeDetailSheet(
        practice: practice,
        beatitude: beatitude,
      ),
    );
  }

  @override
  State<BeatitudePracticeDetailSheet> createState() =>
      _BeatitudePracticeDetailSheetState();
}

class _BeatitudePracticeDetailSheetState
    extends State<BeatitudePracticeDetailSheet> {
  bool _adding = false;

  BeatitudePractice get _practice => widget.practice;
  BeatitudeModel get _beatitude => widget.beatitude;

  /// Derives a concise habit name from the full practice text.
  /// Splits on " — " (em dash) and takes the first part; caps at 60 chars.
  String get _habitName {
    const sep = ' \u2014 ';
    final idx = _practice.text.indexOf(sep);
    if (idx > 0 && idx <= 60) return _practice.text.substring(0, idx);
    return _practice.text.length > 60
        ? '${_practice.text.substring(0, 57)}...'
        : _practice.text;
  }

  /// Maps the practice's habit category label to new-system category IDs.
  ({
    HabitCategory legacyCat,
    String? catId,
    String? subId,
    String? catName,
    String? subName,
  })
  get _categoryMapping => switch (_practice.habit) {
    'Prayer' => (
        legacyCat: HabitCategory.scripture,
        catId: 'the_beatitudes',
        subId: 'prayer',
        catName: 'The Beatitudes',
        subName: 'Prayer',
      ),
    "God's Word" => (
        legacyCat: HabitCategory.scripture,
        catId: 'the_beatitudes',
        subId: 'gods_word',
        catName: 'The Beatitudes',
        subName: "God's Word",
      ),
    'Fasting' => (
        legacyCat: HabitCategory.fasting,
        catId: 'the_beatitudes',
        subId: 'fasting',
        catName: 'The Beatitudes',
        subName: 'Fasting',
      ),
    'Evangelism' => (
        legacyCat: HabitCategory.custom,
        catId: 'the_beatitudes',
        subId: 'evangelism',
        catName: 'The Beatitudes',
        subName: 'Evangelism',
      ),
    'Service & Generosity' => (
        legacyCat: HabitCategory.service,
        catId: 'the_beatitudes',
        subId: 'service_and_generosity',
        catName: 'The Beatitudes',
        subName: 'Service & Generosity',
      ),
    'Connection & Community' => (
        legacyCat: HabitCategory.connection,
        catId: 'the_beatitudes',
        subId: 'connection_and_community',
        catName: 'The Beatitudes',
        subName: 'Connection & Community',
      ),
    'Breaking Habits' => (
        legacyCat: HabitCategory.abstain,
        catId: 'the_beatitudes',
        subId: 'breaking_habits',
        catName: 'The Beatitudes',
        subName: 'Breaking Habits',
      ),
    'Reading & Learning' => (
        legacyCat: HabitCategory.study,
        catId: 'the_beatitudes',
        subId: 'reading_and_learning',
        catName: 'The Beatitudes',
        subName: 'Reading & Learning',
      ),
    _ => (
        legacyCat: HabitCategory.custom,
        catId: 'the_beatitudes',
        subId: null,
        catName: 'The Beatitudes',
        subName: null,
      ),
  };

  Future<void> _addHabit() async {
    if (_adding) return;
    setState(() => _adding = true);

    try {
      final cat = _categoryMapping;
      await context.read<HabitProvider>().addHabit(
            name: _habitName,
            category: cat.legacyCat,
            trackingType: HabitTrackingType.checkIn,
            purpose: _practice.text,
            dailyTarget: 1.0,
            targetUnit: '',
            sourceType: 'beatitude_practice',
            categoryId: cat.catId,
            subcategoryId: cat.subId,
            categoryName: cat.catName,
            subcategoryName: cat.subName,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Practice added to Today.'),
            backgroundColor: MyWalkColor.cardBackground,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Badges row
            Row(
              children: [
                // Beatitude badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.self_improvement, size: 12, color: _kAccent),
                      const SizedBox(width: 5),
                      Text(
                        _beatitude.title,
                        style: TextStyle(
                          fontSize: 12,
                          color: _kAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Habit category badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: MyWalkColor.surfaceOverlay,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _practice.habit,
                    style: TextStyle(
                      fontSize: 11,
                      color: MyWalkColor.softGold.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Practice text
            Text(
              _practice.text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: MyWalkColor.warmWhite,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Beatitude context callout
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              decoration: BoxDecoration(
                color: _kAccent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(color: _kAccent.withValues(alpha: 0.5), width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\u201c${_beatitude.yourWhy}\u201d',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: MyWalkColor.warmWhite.withValues(alpha: 0.75),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\u2014 ${_beatitude.title}',
                    style: TextStyle(
                      fontSize: 11,
                      color: _kAccent.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Add CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _adding ? null : _addHabit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyWalkColor.golden,
                  foregroundColor: MyWalkColor.charcoal,
                  disabledBackgroundColor: MyWalkColor.golden.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _adding
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(MyWalkColor.charcoal),
                        ),
                      )
                    : const Text(
                        'Add this habit',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Not for me',
                  style: TextStyle(
                    color: MyWalkColor.softGold.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
