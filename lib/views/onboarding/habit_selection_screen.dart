import 'package:flutter/material.dart';
import '../../models/habit.dart';
import '../../theme/app_theme.dart';

class HabitSelectionScreen extends StatelessWidget {
  final void Function(HabitCategory) onSelect;
  const HabitSelectionScreen({super.key, required this.onSelect});

  static const _gridCategories = [
    HabitCategory.exercise,
    HabitCategory.scripture,
    HabitCategory.rest,
    HabitCategory.fasting,
    HabitCategory.study,
    HabitCategory.service,
    HabitCategory.connection,
    HabitCategory.health,
  ];

  IconData _icon(HabitCategory category) {
    switch (category) {
      case HabitCategory.exercise: return Icons.fitness_center;
      case HabitCategory.scripture: return Icons.menu_book;
      case HabitCategory.rest: return Icons.bedtime;
      case HabitCategory.fasting: return Icons.no_food;
      case HabitCategory.study: return Icons.school;
      case HabitCategory.service: return Icons.volunteer_activism;
      case HabitCategory.connection: return Icons.people;
      case HabitCategory.health: return Icons.favorite;
      default: return Icons.auto_awesome;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Now pick your\nown habit.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: TributeColor.warmWhite, height: 1.3),
            ),
            const SizedBox(height: 10),
            Text(
              'Gratitude is set. What else do you want to give to God this season?',
              style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 6),
            Text(
              'Pick 1 to start. You can add more later.',
              style: TextStyle(fontSize: 12, color: TributeColor.softGold.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: _gridCategories.map((category) {
                return GestureDetector(
                  onTap: () => onSelect(category),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                    decoration: BoxDecoration(
                      color: TributeColor.cardBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: TributeColor.cardBorder, width: 0.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_icon(category), size: 26, color: TributeColor.golden),
                        const SizedBox(height: 10),
                        Text(
                          category.rawValue,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500, color: TributeColor.warmWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.defaultPurpose,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.4)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            _specialRow(
              icon: Icons.shield_rounded,
              iconColor: TributeColor.warmCoral,
              borderColor: TributeColor.warmCoral.withValues(alpha: 0.2),
              title: 'I\u2019m letting go of something',
              subtitle: 'Break a bad habit with God\u2019s help',
              onTap: () => onSelect(HabitCategory.abstain),
            ),
            const SizedBox(height: 12),
            _specialRow(
              icon: Icons.auto_awesome,
              iconColor: TributeColor.golden,
              borderColor: TributeColor.golden.withValues(alpha: 0.15),
              title: 'Something else entirely',
              subtitle: 'Create a fully custom habit',
              onTap: () => onSelect(HabitCategory.custom),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _specialRow({
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TributeColor.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: TributeColor.warmWhite)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
            ]),
          ),
          Icon(Icons.chevron_right, size: 14, color: Colors.white.withValues(alpha: 0.4)),
        ]),
      ),
    );
  }
}
