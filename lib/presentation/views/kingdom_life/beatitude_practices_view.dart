import 'package:flutter/material.dart';
import '../../../domain/entities/beatitude.dart';
import '../../theme/app_theme.dart';
import 'beatitude_practice_detail_sheet.dart';
import '../habits/add_habit_view.dart';

const _kAccent = Color(0xFF9B8BB4);

class BeatitudePracticesView extends StatelessWidget {
  final BeatitudeModel beatitude;

  const BeatitudePracticesView({super.key, required this.beatitude});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyWalkColor.charcoal,
      appBar: AppBar(
        backgroundColor: MyWalkColor.charcoal,
        foregroundColor: MyWalkColor.warmWhite,
        title: const Text(
          'Add a Practice',
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w600, color: MyWalkColor.warmWhite),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Beatitude context chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.self_improvement, size: 12, color: _kAccent.withValues(alpha: 0.8)),
                      const SizedBox(width: 5),
                      Text(
                        beatitude.title,
                        style: TextStyle(
                          fontSize: 12,
                          color: _kAccent.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Small daily practices shaped by this beatitude.',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: MyWalkColor.softGold.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              itemCount: beatitude.practices.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == beatitude.practices.length) {
                  return _CustomPracticeCard(beatitude: beatitude);
                }
                return _PracticeCard(
                  practice: beatitude.practices[i],
                  beatitude: beatitude,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomPracticeCard extends StatelessWidget {
  final BeatitudeModel beatitude;

  const _CustomPracticeCard({required this.beatitude});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
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
          minChildSize: 0.6,
          expand: false,
          builder: (_, sc) => AddHabitView(
            scrollController: sc,
            prefilledCategoryId: 'the_beatitudes',
            prefilledCategoryName: 'The Beatitudes',
            prefilledSubcategoryName: beatitude.title,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MyWalkColor.golden.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MyWalkColor.golden.withValues(alpha: 0.1),
              ),
              child: Icon(Icons.add_circle_outline, size: 18, color: MyWalkColor.golden),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create My Own Practice',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: MyWalkColor.warmWhite,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Name it, set a goal, and make it yours.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 12, color: Colors.white.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  final BeatitudePractice practice;
  final BeatitudeModel beatitude;

  const _PracticeCard({required this.practice, required this.beatitude});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => BeatitudePracticeDetailSheet.show(context, practice, beatitude),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MyWalkColor.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MyWalkColor.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category icon circle
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kAccent.withValues(alpha: 0.12),
              ),
              child: Icon(Icons.self_improvement, size: 16, color: _kAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    practice.text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: MyWalkColor.warmWhite,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: MyWalkColor.surfaceOverlay,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      practice.habit,
                      style: TextStyle(
                        fontSize: 10,
                        color: MyWalkColor.softGold.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.add_circle_outline,
                size: 20, color: MyWalkColor.golden.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}
