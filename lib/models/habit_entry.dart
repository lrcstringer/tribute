class HabitEntry {
  final String id;
  DateTime date;
  double value;
  bool isCompleted;
  String? gratitudeNote;
  String habitId;

  HabitEntry({
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
      id: _generateId(),
      date: dayStart,
      value: value,
      isCompleted: isCompleted,
      gratitudeNote: gratitudeNote,
      habitId: habitId,
    );
  }

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (1000 + (DateTime.now().microsecond % 9000)).toString();
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'value': value,
    'isCompleted': isCompleted ? 1 : 0,
    'gratitudeNote': gratitudeNote,
    'habitId': habitId,
  };

  factory HabitEntry.fromMap(Map<String, dynamic> map) => HabitEntry(
    id: map['id'] as String,
    date: DateTime.parse(map['date'] as String),
    value: (map['value'] as num).toDouble(),
    isCompleted: (map['isCompleted'] as int) == 1,
    gratitudeNote: map['gratitudeNote'] as String?,
    habitId: map['habitId'] as String,
  );
}
