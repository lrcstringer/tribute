import 'package:uuid/uuid.dart';

// Sentinel for copyWith — distinguishes "not provided" from explicit null.
const _keep = Object();

class HabitEntry {
  final String id;
  final DateTime date;
  final double value;
  final bool isCompleted;
  final String? gratitudeNote;
  final String habitId;

  const HabitEntry({
    required this.id,
    required this.date,
    this.value = 0,
    this.isCompleted = false,
    this.gratitudeNote,
    required this.habitId,
  });

  factory HabitEntry.create({
    required String habitId,
    required DateTime date,
    double value = 0,
    bool isCompleted = false,
    String? gratitudeNote,
  }) {
    final dayStart = DateTime(date.year, date.month, date.day);
    return HabitEntry(
      id: const Uuid().v4(),
      date: dayStart,
      value: value,
      isCompleted: isCompleted,
      gratitudeNote: gratitudeNote,
      habitId: habitId,
    );
  }

  HabitEntry copyWith({
    DateTime? date,
    double? value,
    bool? isCompleted,
    // Use _keep sentinel so callers can pass null to explicitly clear the note.
    Object? gratitudeNote = _keep,
  }) =>
      HabitEntry(
        id: id,
        date: date ?? this.date,
        value: value ?? this.value,
        isCompleted: isCompleted ?? this.isCompleted,
        gratitudeNote: identical(gratitudeNote, _keep)
            ? this.gratitudeNote
            : (gratitudeNote as String?),
        habitId: habitId,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'value': value,
        'isCompleted': isCompleted ? 1 : 0,
        'gratitudeNote': gratitudeNote,
        'habitId': habitId,
      };

  factory HabitEntry.fromMap(Map<String, dynamic> map) => HabitEntry(
        id: map['id'] as String? ?? (throw StateError('HabitEntry.fromMap: row missing id — data may be corrupted: $map')),
        date: DateTime.tryParse((map['date'] as String?) ?? '') ?? DateTime(2000, 1, 1),
        value: (map['value'] as num?)?.toDouble() ?? 0,
        isCompleted: ((map['isCompleted'] as num?)?.toInt() ?? 0) == 1,
        gratitudeNote: map['gratitudeNote'] as String?,
        habitId: map['habitId'] as String? ?? '',
      );
}
