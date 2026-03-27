import 'habit_entry.dart';

enum HabitTrackingType {
  timed,
  count,
  checkIn,
  abstain;

  String get rawValue => name;

  static HabitTrackingType fromString(String value) {
    return HabitTrackingType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HabitTrackingType.checkIn,
    );
  }
}

enum HabitCategory {
  exercise('Exercise & Movement'),
  scripture('Scripture & Prayer'),
  rest('Rest & Sleep'),
  fasting('Fasting'),
  study('Study & Learning'),
  service('Service & Generosity'),
  connection('Connection'),
  health('Health & Nourishment'),
  abstain('Breaking a Bad Habit'),
  custom('Custom'),
  gratitude('Gratitude');

  const HabitCategory(this.label);
  final String label;

  String get rawValue => label;

  static HabitCategory fromString(String value) {
    return HabitCategory.values.firstWhere(
      (e) => e.label == value,
      orElse: () => HabitCategory.gratitude,
    );
  }

  String get iconName {
    switch (this) {
      case exercise: return 'figure.run';
      case scripture: return 'book.fill';
      case rest: return 'moon.fill';
      case fasting: return 'leaf.fill';
      case study: return 'graduationcap.fill';
      case service: return 'heart.fill';
      case connection: return 'person.2.fill';
      case health: return 'drop.fill';
      case abstain: return 'shield.fill';
      case custom: return 'sparkles';
      case gratitude: return 'hands.sparkles.fill';
    }
  }

  String get defaultPurpose {
    switch (this) {
      case exercise: return 'My body is a gift. Moving it honours the One who made it.';
      case scripture: return "I'm someone who puts God's Word first.";
      case rest: return "Rest isn't laziness. God commands it because He designed me to need it.";
      case fasting: return 'Fasting draws me closer to God and teaches me discipline.';
      case study: return 'Growing my mind is an act of stewardship.';
      case service: return 'Serving others is serving God.';
      case connection: return 'I was made for community.';
      case health: return "My body is God's temple. Nourishing it is an act of worship.";
      case abstain: return 'God made me for freedom.';
      case custom: return 'Whatever you do, do it all for the glory of God.';
      case gratitude: return 'Every good gift comes from above.';
    }
  }

  HabitTrackingType get suggestedTrackingType {
    switch (this) {
      case exercise:
      case scripture:
      case rest:
      case study:
        return HabitTrackingType.timed;
      case fasting:
      case connection:
      case gratitude:
      case custom:
        return HabitTrackingType.checkIn;
      case service:
      case health:
        return HabitTrackingType.count;
      case abstain:
        return HabitTrackingType.abstain;
    }
  }
}

class Habit {
  final String id;
  String name;
  String category;
  String trackingType;
  String purposeStatement;
  double dailyTarget;
  String targetUnit;
  bool isBuiltIn;
  DateTime createdAt;
  int sortOrder;
  String activeDays; // comma-separated weekday numbers (1=Sun..7=Sat)
  String trigger;
  String copingPlan;
  List<HabitEntry> entries;

  Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.trackingType,
    this.purposeStatement = '',
    this.dailyTarget = 1,
    this.targetUnit = '',
    this.isBuiltIn = false,
    required this.createdAt,
    this.sortOrder = 0,
    this.activeDays = '1,2,3,4,5,6,7',
    this.trigger = '',
    this.copingPlan = '',
    this.entries = const [],
  });

  factory Habit.create({
    required String name,
    required HabitCategory category,
    required HabitTrackingType trackingType,
    String purposeStatement = '',
    double dailyTarget = 1,
    String targetUnit = '',
    bool isBuiltIn = false,
    int sortOrder = 0,
    Set<int> activeDays = const {1, 2, 3, 4, 5, 6, 7},
    String trigger = '',
    String copingPlan = '',
  }) {
    final purpose = purposeStatement.isEmpty ? category.defaultPurpose : purposeStatement;
    final days = (activeDays.toList()..sort()).join(',');
    return Habit(
      id: _generateId(),
      name: name,
      category: category.rawValue,
      trackingType: trackingType.rawValue,
      purposeStatement: purpose,
      dailyTarget: dailyTarget,
      targetUnit: targetUnit,
      isBuiltIn: isBuiltIn,
      createdAt: DateTime.now(),
      sortOrder: sortOrder,
      activeDays: days,
      trigger: trigger,
      copingPlan: copingPlan,
      entries: [],
    );
  }

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (1000 + (DateTime.now().microsecond % 9000)).toString();
  }

  HabitCategory get habitCategory => HabitCategory.fromString(category);
  HabitTrackingType get habitTrackingType => HabitTrackingType.fromString(trackingType);

  Set<int> get activeDaySet {
    if (activeDays.isEmpty) return {1, 2, 3, 4, 5, 6, 7};
    return activeDays.split(',').map((s) => int.tryParse(s.trim()) ?? 0).toSet();
  }

  set activeDaySet(Set<int> days) {
    activeDays = (days.toList()..sort()).join(',');
  }

  bool get isActiveToday => isActive(DateTime.now());

  bool isActive(DateTime date) {
    // Flutter weekday: Mon=1..Sun=7. Swift weekday: Sun=1..Sat=7.
    // Convert: Flutter Sun=7 → Swift Sun=1, Flutter Mon=1 → Swift Mon=2, etc.
    final flutterWeekday = date.weekday; // 1=Mon..7=Sun
    final swiftWeekday = flutterWeekday % 7 + 1; // 1=Sun..7=Sat
    return activeDaySet.contains(swiftWeekday);
  }

  HabitEntry? entryFor(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    try {
      return entries.firstWhere((e) => _isSameDay(e.date, dayStart));
    } catch (_) {
      return null;
    }
  }

  HabitEntry? get todayEntry => entryFor(DateTime.now());

  bool isCompleted(DateTime date) => entryFor(date)?.isCompleted ?? false;
  bool get isCompletedToday => isCompleted(DateTime.now());

  List<HabitEntry> entriesForCurrentWeek() {
    final weekStart = _currentWeekStart();
    return entries.where((e) => !e.date.isBefore(weekStart)).toList();
  }

  int completedDaysThisWeek() =>
      entriesForCurrentWeek().where((e) => e.isCompleted).length;

  int totalCompletedDays() => entries.where((e) => e.isCompleted).length;

  double totalValue() => entries.fold(0.0, (sum, e) => sum + e.value);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime _currentWeekStart() {
    final now = DateTime.now();
    // Week starts on Sunday (weekday 7 in Flutter)
    final daysFromSunday = now.weekday % 7; // Mon=1..Sun=7 → Sun=0..Sat=6
    return DateTime(now.year, now.month, now.day - daysFromSunday);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'trackingType': trackingType,
    'purposeStatement': purposeStatement,
    'dailyTarget': dailyTarget,
    'targetUnit': targetUnit,
    'isBuiltIn': isBuiltIn ? 1 : 0,
    'createdAt': createdAt.toIso8601String(),
    'sortOrder': sortOrder,
    'activeDays': activeDays,
    'trigger': trigger,
    'copingPlan': copingPlan,
  };

  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
    id: map['id'] as String,
    name: map['name'] as String,
    category: map['category'] as String,
    trackingType: map['trackingType'] as String,
    purposeStatement: map['purposeStatement'] as String? ?? '',
    dailyTarget: (map['dailyTarget'] as num).toDouble(),
    targetUnit: map['targetUnit'] as String? ?? '',
    isBuiltIn: (map['isBuiltIn'] as int) == 1,
    createdAt: DateTime.parse(map['createdAt'] as String),
    sortOrder: map['sortOrder'] as int? ?? 0,
    activeDays: map['activeDays'] as String? ?? '1,2,3,4,5,6,7',
    trigger: map['trigger'] as String? ?? '',
    copingPlan: map['copingPlan'] as String? ?? '',
    entries: [],
  );
}
