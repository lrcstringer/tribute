import '../entities/habit.dart';
import '../entities/habit_entry.dart';

/// Abstract repository interface for habit persistence.
/// The domain layer depends on this contract; data layer implements it.
abstract class HabitRepository {
  Future<List<Habit>> loadHabits();
  Future<void> insertHabit(Habit habit);
  Future<void> updateHabit(Habit habit);
  Future<void> deleteHabit(String habitId);
  Future<void> upsertEntry(HabitEntry entry);
  Future<void> updateHabitSortOrders(List<Habit> habits);
}
