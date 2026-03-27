import '../entities/habit.dart';
import '../repositories/user_preferences_repository.dart';

class WeekCycleManager {
  final UserPreferencesRepository _prefs;

  WeekCycleManager(this._prefs);

  // Week starts Sunday. Flutter weekday: Mon=1..Sun=7.
  // We convert to Swift convention (Sun=1..Sat=7) in Habit.isActive().

  DateTime get currentWeekStart {
    final now = DateTime.now();
    final daysFromSunday = now.weekday % 7; // Mon=1→1, Sun=7→0
    final start = DateTime(now.year, now.month, now.day - daysFromSunday);
    return start;
  }

  DateTime get previousWeekStart {
    return currentWeekStart.subtract(const Duration(days: 7));
  }

  List<DateTime> weekDates(DateTime weekStart) {
    return List.generate(7, (i) => weekStart.add(Duration(days: i)));
  }

  List<DateTime> get currentWeekDates => weekDates(currentWeekStart);
  List<DateTime> get previousWeekDates => weekDates(previousWeekStart);

  bool get isSunday => DateTime.now().weekday == DateTime.sunday;

  int get dayOfWeekIndex {
    final weekday = DateTime.now().weekday; // Mon=1..Sun=7
    return weekday % 7; // Sun=0..Sat=6
  }

  // Persistence helpers (async)

  Future<DateTime?> get weekDedicatedDate async {
    final ms = await _prefs.getInt('tribute_week_dedicated_date');
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  Future<void> setWeekDedicatedDate(DateTime? date) async {
    if (date == null) {
      await _prefs.remove('tribute_week_dedicated_date');
    } else {
      await _prefs.setInt('tribute_week_dedicated_date', date.millisecondsSinceEpoch);
    }
  }

  Future<DateTime?> get lastLookBackWeekStart async {
    final ms = await _prefs.getInt('tribute_last_lookback_week');
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  Future<void> setLastLookBackWeekStart(DateTime? date) async {
    if (date == null) {
      await _prefs.remove('tribute_last_lookback_week');
    } else {
      await _prefs.setInt('tribute_last_lookback_week', date.millisecondsSinceEpoch);
    }
  }

  Future<bool> get isCurrentWeekDedicated async {
    final dedicated = await weekDedicatedDate;
    if (dedicated == null) return false;
    // Compare by week-start date rather than (_weekOf, year) to avoid the
    // year-boundary bug where a week spanning Dec 28–Jan 3 has two different
    // `year` values depending on which day the dedication was saved.
    return _weekStartOf(dedicated) == currentWeekStart;
  }

  Future<bool> get needsDedication async => !(await isCurrentWeekDedicated);

  Future<bool> get needsLookBack async {
    final lastLookBack = await lastLookBackWeekStart;
    if (lastLookBack == null) {
      final onboardingMs = await _prefs.getInt('tribute_onboarding_date');
      if (onboardingMs == null) return false;
      final onboarding = DateTime.fromMillisecondsSinceEpoch(onboardingMs);
      final onboardingWeekStart = _weekStartOf(onboarding);
      return currentWeekStart.isAfter(onboardingWeekStart);
    }
    return currentWeekStart.isAfter(lastLookBack);
  }

  Future<void> dedicateCurrentWeek() => setWeekDedicatedDate(DateTime.now());

  Future<void> completeLookBack() => setLastLookBackWeekStart(currentWeekStart);

  // Scoring helpers

  int completedDays(Habit habit, List<DateTime> dates) {
    return dates.where((date) {
      final entry = habit.entryFor(date);
      return entry?.isCompleted == true;
    }).length;
  }

  int completedDaysThisWeek(Habit habit) {
    final datesUpToToday = currentWeekDates.where((d) => !d.isAfter(DateTime.now())).toList();
    return completedDays(habit, datesUpToToday);
  }

  int activeDaysThisWeek(Habit habit) {
    final datesUpToToday = currentWeekDates.where((d) => !d.isAfter(DateTime.now())).toList();
    return datesUpToToday.where((d) => habit.isActive(d)).length;
  }

  String weekProjectionSummary(Habit habit) {
    final activeDaysInWeek = currentWeekDates.where((d) => habit.isActive(d)).length;
    switch (habit.trackingType) {
      case HabitTrackingType.timed:
        final totalMinutes = habit.dailyTarget * activeDaysInWeek;
        if (totalMinutes >= 60) {
          return '${(totalMinutes / 60).toStringAsFixed(1)} hours this week';
        }
        return '${totalMinutes.toInt()} minutes this week';
      case HabitTrackingType.count:
        final total = (habit.dailyTarget * activeDaysInWeek).toInt();
        final unit = habit.targetUnit.isEmpty ? 'total' : habit.targetUnit;
        return '$total $unit this week';
      case HabitTrackingType.checkIn:
        return '$activeDaysInWeek days this week';
      case HabitTrackingType.abstain:
        return '7 days of freedom';
    }
  }

  String graceMessage(int completed, int total) {
    if (total == 0) return 'A new week begins. God is with you.';
    final ratio = completed / total;
    if (ratio >= 1.0) return 'Every single one. What a week of giving.';
    if (ratio >= 0.85) return 'Almost perfect — and God sees every one.';
    if (ratio >= 0.7) return 'A beautiful week. God was with you every single day — including the ones you rested.';
    if (ratio >= 0.5) return "You showed up more than half the time. That's not small — that's faithfulness.";
    if (ratio >= 0.3) return "Some weeks are harder than others. God sees your heart, not your score.";
    return "Even one day of showing up matters. His mercies are new every morning.";
  }

  int consecutiveCleanDays(Habit habit) {
    if (habit.trackingType != HabitTrackingType.abstain) return 0;
    var count = 0;
    var checkDate = DateTime.now();
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    while (true) {
      final entry = habit.entryFor(checkDate);
      if (entry?.isCompleted == true) {
        count++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return count;
  }

  String? microMilestonePreview(Habit habit) {
    // Guard against zero dailyTarget to prevent division by zero in projection calculations.
    if (habit.dailyTarget <= 0) return null;

    final activeDaysRemaining = currentWeekDates.where((d) => d.isAfter(DateTime.now()) && habit.isActive(d)).length;

    switch (habit.trackingType) {
      case HabitTrackingType.timed:
        final totalMinutes = habit.totalValue();
        final projected = totalMinutes + (habit.dailyTarget * (activeDaysRemaining + 1));
        final milestones = [1.0, 5, 10, 25, 50, 100, 250, 500, 1000];
        final currentHours = totalMinutes / 60;
        for (final m in milestones) {
          if (currentHours < m && projected / 60 >= m) {
            final minutesNeeded = (m * 60) - totalMinutes;
            final daysNeeded = (minutesNeeded / habit.dailyTarget).ceil();
            final targetDate = DateTime.now().add(Duration(days: daysNeeded));
            return 'By ${_dayName(targetDate)} you\'ll cross ${m.toInt()} total hours.';
          }
        }
        return null;

      case HabitTrackingType.count:
        final total = habit.totalValue();
        final projected = total + (habit.dailyTarget * (activeDaysRemaining + 1));
        final milestones = [50.0, 100, 250, 500, 1000, 2500, 5000];
        for (final m in milestones) {
          if (total < m && projected >= m) {
            final needed = m - total;
            final daysNeeded = (needed / habit.dailyTarget).ceil();
            final targetDate = DateTime.now().add(Duration(days: daysNeeded));
            final unit = habit.targetUnit.isEmpty ? 'completed' : habit.targetUnit;
            return 'You\'ll pass ${m.toInt()} total $unit by ${_dayName(targetDate)}.';
          }
        }
        return null;

      case HabitTrackingType.checkIn:
        final totalDays = habit.totalCompletedDays().toDouble();
        final projected = totalDays + activeDaysRemaining + 1;
        final milestones = [7.0, 14, 21, 30, 50, 100, 200, 365];
        for (final m in milestones) {
          if (totalDays < m && projected >= m) {
            final needed = (m - totalDays).toInt();
            final targetDate = DateTime.now().add(Duration(days: needed));
            return 'Day ${m.toInt()} lands on ${_dayName(targetDate)}.';
          }
        }
        return null;

      case HabitTrackingType.abstain:
        final consecutive = consecutiveCleanDays(habit);
        final projected = consecutive + activeDaysRemaining + 1;
        final milestones = [7, 14, 21, 30, 60, 90, 180, 365];
        for (final m in milestones) {
          if (consecutive < m && projected >= m) {
            final needed = m - consecutive;
            final targetDate = DateTime.now().add(Duration(days: needed));
            return 'By ${_dayName(targetDate)}, you\'ll have $m consecutive clean days.';
          }
        }
        return null;
    }
  }

  String? proximityMessage(Habit habit) {
    switch (habit.trackingType) {
      case HabitTrackingType.timed:
        final totalMinutes = habit.totalValue();
        final currentHours = totalMinutes / 60;
        final milestones = [1.0, 5, 10, 25, 50, 100, 250, 500, 1000];
        for (final m in milestones) {
          if (currentHours < m) {
            final minutesLeft = (m * 60) - totalMinutes;
            if (minutesLeft <= habit.dailyTarget * 2) {
              return 'Just ${minutesLeft.toInt()} more minutes to hit ${m.toInt()} total hours of ${habit.name.toLowerCase()}.';
            }
            return null;
          }
        }
        return null;

      case HabitTrackingType.count:
        final total = habit.totalValue();
        final milestones = [50.0, 100, 250, 500, 1000, 2500, 5000];
        for (final m in milestones) {
          if (total < m) {
            final left = m - total;
            if (left <= habit.dailyTarget * 2) {
              final unit = habit.targetUnit.isEmpty ? 'completed' : habit.targetUnit;
              return 'Just ${left.toInt()} more $unit to reach ${m.toInt()} total.';
            }
            return null;
          }
        }
        return null;

      case HabitTrackingType.checkIn:
        final totalDays = habit.totalCompletedDays().toDouble();
        final milestones = [7.0, 14, 21, 30, 50, 100, 200, 365];
        for (final m in milestones) {
          if (totalDays < m) {
            final left = (m - totalDays).toInt();
            if (left <= 3) {
              return left == 1
                  ? 'One more day to hit ${m.toInt()} days of ${habit.name.toLowerCase()}.'
                  : '$left more days to hit ${m.toInt()} days of ${habit.name.toLowerCase()}.';
            }
            return null;
          }
        }
        return null;

      case HabitTrackingType.abstain:
        final consecutive = consecutiveCleanDays(habit);
        final milestones = [7, 14, 21, 30, 60, 90, 180, 365];
        for (final m in milestones) {
          if (consecutive < m) {
            final left = m - consecutive;
            if (left <= 3) {
              return left == 1
                  ? 'One more day to $m consecutive clean days.'
                  : '$left more days to $m consecutive clean days.';
            }
            return null;
          }
        }
        return null;
    }
  }

  static DateTime _weekStartOf(DateTime date) {
    final daysFromSunday = date.weekday % 7;
    return DateTime(date.year, date.month, date.day - daysFromSunday);
  }

  static const _dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  static String _dayName(DateTime date) => _dayNames[date.weekday % 7];
}
