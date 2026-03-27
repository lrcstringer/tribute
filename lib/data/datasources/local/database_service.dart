import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/habit.dart';
import '../models/habit_entry.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tribute.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE habits (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            trackingType TEXT NOT NULL,
            purposeStatement TEXT NOT NULL DEFAULT '',
            dailyTarget REAL NOT NULL DEFAULT 1,
            targetUnit TEXT NOT NULL DEFAULT '',
            isBuiltIn INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL,
            sortOrder INTEGER NOT NULL DEFAULT 0,
            activeDays TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7',
            trigger TEXT NOT NULL DEFAULT '',
            copingPlan TEXT NOT NULL DEFAULT ''
          )
        ''');

        await db.execute('''
          CREATE TABLE habit_entries (
            id TEXT PRIMARY KEY,
            date TEXT NOT NULL,
            value REAL NOT NULL DEFAULT 0,
            isCompleted INTEGER NOT NULL DEFAULT 0,
            gratitudeNote TEXT,
            habitId TEXT NOT NULL,
            FOREIGN KEY (habitId) REFERENCES habits(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('CREATE INDEX idx_entries_habitId ON habit_entries(habitId)');
        await db.execute('CREATE INDEX idx_entries_date ON habit_entries(date)');
      },
    );
  }

  // Habits

  Future<List<Habit>> loadHabits() async {
    final db = await database;
    final habitRows = await db.query('habits', orderBy: 'sortOrder ASC');
    final entryRows = await db.query('habit_entries');

    final entriesByHabitId = <String, List<HabitEntry>>{};
    for (final row in entryRows) {
      final entry = HabitEntry.fromMap(row);
      entriesByHabitId.putIfAbsent(entry.habitId, () => []).add(entry);
    }

    return habitRows.map((row) {
      final habit = Habit.fromMap(row);
      habit.entries = entriesByHabitId[habit.id] ?? [];
      return habit;
    }).toList();
  }

  Future<void> insertHabit(Habit habit) async {
    final db = await database;
    await db.insert('habits', habit.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateHabit(Habit habit) async {
    final db = await database;
    await db.update('habits', habit.toMap(), where: 'id = ?', whereArgs: [habit.id]);
  }

  Future<void> deleteHabit(String habitId) async {
    final db = await database;
    await db.delete('habits', where: 'id = ?', whereArgs: [habitId]);
    await db.delete('habit_entries', where: 'habitId = ?', whereArgs: [habitId]);
  }

  Future<void> updateHabitSortOrders(List<Habit> habits) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < habits.length; i++) {
      batch.update('habits', {'sortOrder': i}, where: 'id = ?', whereArgs: [habits[i].id]);
    }
    await batch.commit(noResult: true);
  }

  // Entries

  Future<void> upsertEntry(HabitEntry entry) async {
    final db = await database;
    await db.insert('habit_entries', entry.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteEntry(String entryId) async {
    final db = await database;
    await db.delete('habit_entries', where: 'id = ?', whereArgs: [entryId]);
  }
}
