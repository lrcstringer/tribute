import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_entry.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/repositories/circle_repository.dart';
import '../../domain/services/daily_score_service.dart';

class HabitProvider extends ChangeNotifier {
  final HabitRepository _repository;
  final bool Function() _isAuthenticated;
  final CircleRepository _circleRepository;

  HabitProvider(this._repository, this._isAuthenticated, this._circleRepository);

  List<Habit> _habits = [];
  bool _isLoading = false;
  String? _checkInPulseHabitId;
  bool _showingAddHabit = false;
  bool _loadInProgress = false;

  List<Habit> get habits => List.unmodifiable(_habits);
  List<Habit> get sortedHabits =>
      [..._habits]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  bool get isLoading => _isLoading;
  String? get checkInPulseHabitId => _checkInPulseHabitId;
  bool get showingAddHabit => _showingAddHabit;

  Future<void> loadHabits() async {
    // Guard against concurrent loads to avoid double ensureGratitudeHabit inserts.
    if (_loadInProgress) return;
    _loadInProgress = true;
    _isLoading = true;
    notifyListeners();
    _habits = await _repository.loadHabits();
    _isLoading = false;
    await ensureGratitudeHabit();
    notifyListeners();
    _loadInProgress = false;
  }

  Future<void> ensureGratitudeHabit() async {
    final hasGratitude = _habits
        .any((h) => h.isBuiltIn && h.category == HabitCategory.gratitude);
    if (!hasGratitude) {
      final gratitude = Habit.create(
        name: 'Daily Gratitude',
        category: HabitCategory.gratitude,
        trackingType: HabitTrackingType.checkIn,
        purposeStatement:
            'Give thanks in all circumstances; for this is God\u2019s will for you in Christ Jesus.',
        isBuiltIn: true,
        sortOrder: 0,
      );
      await _repository.insertHabit(gratitude);
      _habits = [gratitude, ..._habits];
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
    await _repository.insertHabit(habit);
    _habits = [..._habits, habit];
    notifyListeners();
  }

  Future<void> updateHabit(Habit habit) async {
    await _repository.updateHabit(habit);
    _habits = [
      for (final h in _habits) h.id == habit.id ? habit : h,
    ];
    notifyListeners();
  }

  Future<void> deleteHabit(Habit habit) async {
    if (habit.isBuiltIn) return;
    await _repository.deleteHabit(habit.id);
    _habits = _habits.where((h) => h.id != habit.id).toList();
    notifyListeners();
  }

  Future<void> reorderHabits(List<Habit> reordered) async {
    _habits = reordered;
    await _repository.updateHabitSortOrders(reordered);
    notifyListeners();
  }

  // Check-in methods

  Future<void> checkInHabit(Habit habit,
      {DateTime? date, bool retroactive = false}) async {
    final target = _dayStart(date ?? DateTime.now());
    await _upsertEntry(habit,
        targetDate: target,
        value: habit.dailyTarget,
        isCompleted: true);
    if (!retroactive) unawaited(_syncHeatmapToCircles());
    _checkInPulseHabitId = habit.id;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1200));
    _checkInPulseHabitId = null;
    notifyListeners();
  }

  Future<void> checkInGratitude(Habit habit,
      {String? note, DateTime? date}) async {
    final target = _dayStart(date ?? DateTime.now());
    await _upsertEntry(habit,
        targetDate: target, value: 1, isCompleted: true, gratitudeNote: note);
    unawaited(_syncHeatmapToCircles());
    _checkInPulseHabitId = habit.id;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1200));
    _checkInPulseHabitId = null;
    notifyListeners();
  }

  Future<void> updateTimedEntry(Habit habit, double minutes,
      {DateTime? date}) async {
    final target = _dayStart(date ?? DateTime.now());
    final completed = minutes >= habit.dailyTarget;
    await _upsertEntry(habit,
        targetDate: target, value: minutes, isCompleted: completed);
    if (completed) {
      unawaited(_syncHeatmapToCircles());
      _checkInPulseHabitId = habit.id;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 1200));
      _checkInPulseHabitId = null;
    }
    notifyListeners();
  }

  Future<void> updateCountEntry(Habit habit, double count,
      {DateTime? date}) async {
    final target = _dayStart(date ?? DateTime.now());
    final completed = count >= habit.dailyTarget;
    await _upsertEntry(habit,
        targetDate: target, value: count, isCompleted: completed);
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
    if (!_isAuthenticated()) return;
    try {
      final today = DateTime.now();
      final dayStart = _dayStart(today);
      // Build Sunday-to-today date range for the current week.
      final weekday = dayStart.weekday % 7; // 0 = Sunday
      final sunday = dayStart.subtract(Duration(days: weekday));
      final days = List.generate(
        weekday + 1,
        (i) => sunday.add(Duration(days: i)),
      );
      final weekData = days.map((d) {
        final score = DailyScoreService.instance.dailyScore(_habits, d);
        return {
          'date': d.toIso8601String().substring(0, 10),
          'score': score
        };
      }).toList();

      final circles = await _circleRepository.listCircles();
      for (final circle in circles) {
        await _circleRepository.submitHeatmapData(circle.id, weekData);
      }
    } catch (_) {
      // Fire-and-forget — never surface heatmap sync errors to the user.
    }
  }

  // Private helpers

  Future<void> _upsertEntry(
    Habit habit, {
    required DateTime targetDate,
    required double value,
    required bool isCompleted,
    String? gratitudeNote,
  }) async {
    final existing = habit.entryFor(targetDate);
    final HabitEntry entry;

    if (existing != null) {
      // Preserve the existing gratitude note when no new note is provided.
      entry = existing.copyWith(
        value: value,
        isCompleted: isCompleted,
        gratitudeNote: gratitudeNote ?? existing.gratitudeNote,
      );
    } else {
      entry = HabitEntry.create(
        habitId: habit.id,
        date: targetDate,
        value: value,
        isCompleted: isCompleted,
        gratitudeNote: gratitudeNote,
      );
    }

    await _repository.upsertEntry(entry);

    // Replace the habit in _habits with an updated immutable copy.
    _habits = [
      for (final h in _habits)
        if (h.id == habit.id)
          _withUpdatedEntry(h, entry, previous: existing)
        else
          h,
    ];
  }

  /// Returns a copy of [habit] with [entry] inserted or replaced in its entries list.
  /// Also adjusts [allTimeCompletedCount] and [allTimeTotalValue] by the delta between
  /// [previous] and the new [entry], keeping cached aggregates in sync after in-session check-ins.
  static Habit _withUpdatedEntry(Habit habit, HabitEntry entry, {HabitEntry? previous}) {
    final entries = List<HabitEntry>.from(habit.entries);
    final idx = entries.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      entries[idx] = entry;
    } else {
      entries.add(entry);
    }

    // Update cached aggregate counts if they are present.
    int? newAllTimeCompleted = habit.allTimeCompletedCount;
    double? newAllTimeTotalValue = habit.allTimeTotalValue;

    if (newAllTimeCompleted != null) {
      final wasCompleted = previous?.isCompleted ?? false;
      if (!wasCompleted && entry.isCompleted) {
        newAllTimeCompleted += 1;
      } else if (wasCompleted && !entry.isCompleted) {
        newAllTimeCompleted = (newAllTimeCompleted - 1).clamp(0, newAllTimeCompleted);
      }
    }

    if (newAllTimeTotalValue != null) {
      newAllTimeTotalValue += entry.value - (previous?.value ?? 0.0);
    }

    return habit.copyWith(
      entries: entries,
      allTimeCompletedCount: newAllTimeCompleted,
      allTimeTotalValue: newAllTimeTotalValue,
    );
  }

  static DateTime _dayStart(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
