import '../models/habit.dart';

enum DayTier { nothing, partial, substantial, full }

class DailyScoreService {
  static const DailyScoreService instance = DailyScoreService._();
  const DailyScoreService._();

  double habitScore(Habit habit, DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    if (!habit.isActive(dayStart)) return -1;

    final entry = habit.entryFor(dayStart);
    if (entry == null) return 0;

    switch (habit.habitTrackingType) {
      case HabitTrackingType.timed:
      case HabitTrackingType.count:
        if (habit.dailyTarget <= 0) return entry.isCompleted ? 1.0 : 0.0;
        return (entry.value / habit.dailyTarget).clamp(0.0, 1.0);
      case HabitTrackingType.checkIn:
      case HabitTrackingType.abstain:
        return entry.isCompleted ? 1.0 : 0.0;
    }
  }

  double dailyScore(List<Habit> habits, DateTime date) {
    final scores = habits
        .map((h) => habitScore(h, date))
        .where((s) => s >= 0)
        .toList();
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  DayTier tierForScore(double score) {
    if (score <= 0) return DayTier.nothing;
    if (score < 0.5) return DayTier.partial;
    if (score < 0.95) return DayTier.substantial;
    return DayTier.full;
  }

  DayTier tierForHabits(List<Habit> habits, DateTime date) {
    return tierForScore(dailyScore(habits, date));
  }
}
