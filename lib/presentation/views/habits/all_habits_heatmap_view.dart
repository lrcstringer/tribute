import 'package:flutter/material.dart';
import '../../models/habit.dart';
import '../../services/daily_score_service.dart';
import '../../theme/app_theme.dart';

class AllHabitsHeatmapView extends StatelessWidget {
  final List<Habit> habits;
  final int weekCount;

  const AllHabitsHeatmapView({super.key, required this.habits, required this.weekCount});

  static final _scoreService = DailyScoreService.instance;

  List<List<_AggDay>> _buildWeeks() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final daysSinceSunday = today.weekday % 7;
    final currentWeekStart = todayStart.subtract(Duration(days: daysSinceSunday));

    final result = <List<_AggDay>>[];
    for (int w = -(weekCount - 1); w <= 0; w++) {
      final weekStart = currentWeekStart.add(Duration(days: w * 7));
      final week = <_AggDay>[];
      for (int d = 0; d < 7; d++) {
        final date = weekStart.add(Duration(days: d));
        final isFuture = date.isAfter(todayStart);
        final score = isFuture ? 0.0 : _scoreService.dailyScore(habits, date);
        final tier = isFuture ? DayTier.nothing : _scoreService.tierForScore(score);
        week.add(_AggDay(date: date, isFuture: isFuture, tier: tier));
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: _tileFill(day),
                        borderRadius: BorderRadius.circular(cornerRadius),
                        border: day.tier == DayTier.partial && !day.isFuture
                            ? Border.all(
                                color: TributeColor.golden.withValues(alpha: 0.5),
                                width: 1)
                            : null,
                        boxShadow: day.tier == DayTier.full && !day.isFuture
                            ? [
                                BoxShadow(
                                  color: TributeColor.golden.withValues(alpha: 0.7),
                                  blurRadius: 5,
                                ),
                                BoxShadow(
                                  color: TributeColor.golden.withValues(alpha: 0.3),
                                  blurRadius: 2,
                                ),
                              ]
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

  Color _tileFill(_AggDay day) {
    if (day.isFuture) return Colors.white.withValues(alpha: 0.02);
    switch (day.tier) {
      case DayTier.nothing:
        return TributeColor.surfaceOverlay;
      case DayTier.partial:
        return TributeColor.golden.withValues(alpha: 0.12);
      case DayTier.substantial:
        return TributeColor.golden.withValues(alpha: 0.55);
      case DayTier.full:
        return TributeColor.golden.withValues(alpha: 0.95);
    }
  }
}

class _AggDay {
  final DateTime date;
  final bool isFuture;
  final DayTier tier;
  const _AggDay({required this.date, required this.isFuture, required this.tier});
}
