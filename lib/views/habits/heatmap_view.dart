import 'package:flutter/material.dart';
import '../../models/habit.dart';
import '../../services/daily_score_service.dart';
import '../../theme/app_theme.dart';

class HeatmapView extends StatelessWidget {
  final Habit habit;
  final int weekCount;

  const HeatmapView({super.key, required this.habit, required this.weekCount});

  static final _scoreService = DailyScoreService.instance;

  List<List<_HeatmapDay>> _buildWeeks() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    // Find Sunday of current week
    int weekday = today.weekday; // Mon=1..Sun=7
    final daysSinceSunday = weekday % 7; // Sun=0, Mon=1, ..., Sat=6
    final currentWeekStart = todayStart.subtract(Duration(days: daysSinceSunday));

    final result = <List<_HeatmapDay>>[];
    for (int w = -(weekCount - 1); w <= 0; w++) {
      final weekStart = currentWeekStart.add(Duration(days: w * 7));
      final week = <_HeatmapDay>[];
      for (int d = 0; d < 7; d++) {
        final date = weekStart.add(Duration(days: d));
        final isFuture = date.isAfter(todayStart);
        final score = isFuture ? 0.0 : _scoreService.habitScore(habit, date);
        final tier = isFuture ? DayTier.nothing : _scoreService.tierForScore(score < 0 ? 0 : score);
        week.add(_HeatmapDay(date: date, isFuture: isFuture, tier: tier));
      }
      result.add(week);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final weeks = _buildWeeks();
    final tileSpacing = weekCount > 4 ? 2.0 : 3.0;
    final cornerRadius = weekCount > 12 ? 2.0 : 3.0;
    final isAbstain = habit.habitTrackingType == HabitTrackingType.abstain;
    final accentColor = isAbstain ? TributeColor.sage : TributeColor.golden;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (weekCount > 1) ...[
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((label) => Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
        ],
        Column(
          children: weeks.map((week) => Padding(
            padding: EdgeInsets.only(bottom: tileSpacing),
            child: Row(
              children: week.map((day) => Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: tileSpacing / 2),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: _tileFill(day, accentColor),
                        borderRadius: BorderRadius.circular(cornerRadius),
                        border: day.tier == DayTier.partial && !day.isFuture
                            ? Border.all(color: accentColor.withValues(alpha: 0.5), width: 1)
                            : null,
                        boxShadow: day.tier == DayTier.full && !day.isFuture
                            ? [BoxShadow(color: accentColor.withValues(alpha: 0.35), blurRadius: 3)]
                            : null,
                      ),
                    ),
                  ),
                ),
              )).toList(),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Color _tileFill(_HeatmapDay day, Color accent) {
    if (day.isFuture) return Colors.white.withValues(alpha: 0.02);
    switch (day.tier) {
      case DayTier.nothing:
        return TributeColor.surfaceOverlay;
      case DayTier.partial:
        return accent.withValues(alpha: 0.12);
      case DayTier.substantial:
        return accent.withValues(alpha: 0.55);
      case DayTier.full:
        return accent.withValues(alpha: 0.8);
    }
  }
}

class _HeatmapDay {
  final DateTime date;
  final bool isFuture;
  final DayTier tier;
  const _HeatmapDay({required this.date, required this.isFuture, required this.tier});
}
