import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_entry.dart';
import '../../domain/repositories/habit_repository.dart';
import '../datasources/local/database_service.dart';

/// Concrete implementation of [HabitRepository] backed by SQLite via [DatabaseService].
class HabitRepositoryImpl implements HabitRepository {
  final DatabaseService _db;

  const HabitRepositoryImpl(this._db);

  @override
  Future<List<Habit>> loadHabits() => _db.loadHabits();

  @override
  Future<void> insertHabit(Habit habit) => _db.insertHabit(habit);

  @override
  Future<void> updateHabit(Habit habit) => _db.updateHabit(habit);

  @override
  Future<void> deleteHabit(String habitId) => _db.deleteHabit(habitId);

  @override
  Future<void> upsertEntry(HabitEntry entry) => _db.upsertEntry(entry);

  @override
  Future<void> updateHabitSortOrders(List<Habit> habits) =>
      _db.updateHabitSortOrders(habits);
}
