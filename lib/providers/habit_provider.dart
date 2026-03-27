import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/habit.dart';
import '../models/habit_entry.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/daily_score_service.dart';
import '../services/database_service.dart';

class HabitProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<Habit> _habits = [];
  bool _isLoading = false;
  String? _checkInPulseHabitId;
  bool _showingAddHabit = false;

  List<Habit> get habits => List.unmodifiable(_habits);
  List<Habit> get sortedHabits => [..._habits]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  bool get isLoading => _isLoading;
  String? get checkInPulseHabitId => _checkInPulseHabitId;
  bool get showingAddHabit => _showingAddHabit;

  Future<void> loadHabits() async {
    _isLoading = true;
    notifyListeners();
    _habits = await _db.loadHabits();
    _isLoading = false;
    await ensureGratitudeHabit();
    notifyListeners();
  }

  Future<void> ensureGratitudeHabit() async {
    final hasGratitude = _habits.any((h) => h.isBuiltIn && h.habitCategory == HabitCategory.gratitude);
    if (!hasGratitude) {
      final gratitude = Habit.create(
        name: 'Daily Gratitude',
        category: HabitCategory.gratitude,
        trackingType: HabitTrackingType.checkIn,
        purposeStatement: 'Give thanks in all circumstances; for this is God\u2019s will for you in Christ Jesus.',
        isBuiltIn: true,
        sortOrder: 0,
      );
      await _db.insertHabit(gratitude);
      _habits.insert(0, gratitude);
      notifyListeners();
    }
  }

  Future<void> addHabit({
    required String name,
    required HabitCategory category,
    required HabitTrackingType trackingType,
    required String purpose,
    required double dailyTarget,
    required String targetUnit,
    Set<int> activeDays = const {1, 2, 3, 4, 5, 6, 7},
    String trigger = '',
    String copingPlan = '',
  }) async {
    final habit = Habit.create(
      name: name,
      category: category,
      trackingType: trackingType,
      purposeStatement: purpose,
      dailyTarget: dailyTarget,
      targetUnit: targetUnit,
      sortOrder: _habits.length,
      activeDays: activeDays,
      trigger: trigger,
      copingPlan: copingPlan,
    );
    await _db.insertHabit(habit);
    _habits.add(habit);
    notifyListeners();
  }

  Future<void> updateHabit(Habit habit) async {
    await _db.updateHabit(habit);
    final idx = _habits.indexWhere((h) => h.id == habit.id);
    if (idx >= 0) _habits[idx] = habit;
    notifyListeners();
  }

  Future<void> deleteHabit(Habit habit) async {
    if (habit.isBuiltIn) return;
    await _db.deleteHabit(habit.id);
    _habits.removeWhere((h) => h.id == habit.id);
    notifyListeners();
  }

  Future<void> reorderHabits(List<Habit> reordered) async {
    _habits = reordered;
    await _db.updateHabitSortOrders(reordered);
    notifyListeners();
  }

  // Check-in methods

  Future<void> checkInHabit(Habit habit, {DateTime? date, bool retroactive = false}) async {
    final target = _dayStart(date ?? DateTime.now());
    await _upsertEntry(habit, targetDate: target, value: habit.dailyTarget, isCompleted: true);
    if (!retroactive) unawaited(_syncHeatmapToCircles());
    _checkInPulseHabitId = habit.id;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1200));
    _checkInPulseHabitId = null;
    notifyListeners();
  }

  Future<void> checkInGratitude(Habit habit, {String? note, DateTime? date}) async {
    final target = _dayStart(date ?? DateTime.now());
    await _upsertEntry(habit, targetDate: target, value: 1, isCompleted: true, gratitudeNote: note);
    unawaited(_syncHeatmapToCircles());
    _checkInPulseHabitId = habit.id;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1200));
    _checkInPulseHabitId = null;
    notifyListeners();
  }

  Future<void> updateTimedEntry(Habit habit, double minutes, {DateTime? date}) async {
    final target = _dayStart(date ?? DateTime.now());
    final completed = minutes >= habit.dailyTarget;
    await _upsertEntry(habit, targetDate: target, value: minutes, isCompleted: completed);
    if (completed) {
      unawaited(_syncHeatmapToCircles());
      _checkInPulseHabitId = habit.id;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 1200));
      _checkInPulseHabitId = null;
    }
    notifyListeners();
  }

  Future<void> updateCountEntry(Habit habit, double count, {DateTime? date}) async {
    final target = _dayStart(date ?? DateTime.now());
    final completed = count >= habit.dailyTarget;
    await _upsertEntry(habit, targetDate: target, value: count, isCompleted: completed);
    if (completed) {
      unawaited(_syncHeatmapToCircles());
      _checkInPulseHabitId = habit.id;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 1200));
      _checkInPulseHabitId = null;
    }
    notifyListeners();
  }

  void setShowingAddHabit(bool value) {
    _showingAddHabit = value;
    notifyListeners();
  }

  // Heatmap sync

  Future<void> _syncHeatmapToCircles() async {
    if (!AuthService.shared.isAuthenticated) return;
    try {
      final today = DateTime.now();
      final dayStart = _dayStart(today);
      // Build Sunday-to-today date range for the current week
      final weekday = dayStart.weekday % 7; // 0 = Sunday
      final sunday = dayStart.subtract(Duration(days: weekday));
      final days = List.generate(
        weekday + 1,
        (i) => sunday.add(Duration(days: i)),
      );
      final weekData = days.map((d) {
        final score = DailyScoreService.instance.dailyScore(_habits, d);
        return {'date': d.toIso8601String().substring(0, 10), 'score': score};
      }).toList();

      final circles = await APIService.shared.listCircles();
      for (final circle in circles) {
        await APIService.shared.submitHeatmapData(circle.id, weekData);
      }
    } catch (_) {
      // Fire-and-forget — never surface heatmap sync errors to the user
    }
  }

  // Private helpers

  Future<void> _upsertEntry(Habit habit, {required DateTime targetDate, required double value, required bool isCompleted, String? gratitudeNote}) async {
    final existing = habit.entryFor(targetDate);
    if (existing != null) {
      existing.value = value;
      existing.isCompleted = isCompleted;
      if (gratitudeNote != null) existing.gratitudeNote = gratitudeNote;
      await _db.upsertEntry(existing);
    } else {
      final entry = HabitEntry.create(
        habitId: habit.id,
        date: targetDate,
        value: value,
        isCompleted: isCompleted,
        gratitudeNote: gratitudeNote,
      );
      await _db.upsertEntry(entry);
      final idx = _habits.indexWhere((h) => h.id == habit.id);
      if (idx >= 0) _habits[idx].entries.add(entry);
    }
  }

  static DateTime _dayStart(DateTime date) => DateTime(date.year, date.month, date.day);
}
