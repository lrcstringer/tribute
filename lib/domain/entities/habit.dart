import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'habit_entry.dart';
import 'fruit.dart';

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
      case exercise:
        return 'figure.run';
      case scripture:
        return 'book.fill';
      case rest:
        return 'moon.fill';
      case fasting:
        return 'leaf.fill';
      case study:
        return 'graduationcap.fill';
      case service:
        return 'heart.fill';
      case connection:
        return 'person.2.fill';
      case health:
        return 'drop.fill';
      case abstain:
        return 'shield.fill';
      case custom:
        return 'sparkles';
      case gratitude:
        return 'hands.sparkles.fill';
    }
  }

  String get defaultPurpose {
    switch (this) {
      case exercise:
        return 'My body is a gift. Moving it honours the One who made it.';
      case scripture:
        return "I'm someone who puts God's Word first.";
      case rest:
        return "Rest isn't laziness. God commands it because He designed me to need it.";
      case fasting:
        return 'Fasting draws me closer to God and teaches me discipline.';
      case study:
        return 'Growing my mind is an act of stewardship.';
      case service:
        return 'Serving others is serving God.';
      case connection:
        return 'I was made for community.';
      case health:
        return "My body is God's temple. Nourishing it is an act of worship.";
      case abstain:
        return 'God made me for freedom.';
      case custom:
        return 'Whatever you do, do it all for the glory of God.';
      case gratitude:
        return 'Every good gift comes from above.';
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
  final String name;
  final HabitCategory category;
  final HabitTrackingType trackingType;
  final String purposeStatement;
  final double dailyTarget;
  final String targetUnit;
  final bool isBuiltIn;
  final bool isArchived;
  final DateTime createdAt;
  final int sortOrder;
  // Comma-separated weekday numbers using Swift convention (1=Sun..7=Sat).
  final String activeDays;
  final String trigger;
  final String copingPlan;
  final List<HabitEntry> entries;
  // Lifetime aggregates populated by DatabaseService to avoid loading all historical rows.
  // When non-null, totalCompletedDays() and totalValue() use these instead of entries.
  final int? allTimeCompletedCount;
  final double? allTimeTotalValue;
  // Fruit of the Spirit tagging
  final List<FruitType> fruitTags;
  final String? fruitPurposeStatement;
  final String sourceType; // 'user_created' | 'micro_action_library'
  final String? sourceActionId;
  // Two-level category hierarchy (new system)
  final String? categoryId;
  final String? subcategoryId;
  final String? categoryName;
  final String? subcategoryName;
  // Personal notes (stored as flutter_quill Delta JSON; empty string = no notes)
  final String notes;
  // Optional reference URL the user can attach to this habit (empty string = none)
  final String referenceUrl;

  const Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.trackingType,
    this.purposeStatement = '',
    this.dailyTarget = 1,
    this.targetUnit = '',
    this.isBuiltIn = false,
    this.isArchived = false,
    required this.createdAt,
    this.sortOrder = 0,
    this.activeDays = '1,2,3,4,5,6,7',
    this.trigger = '',
    this.copingPlan = '',
    this.entries = const [],
    this.allTimeCompletedCount,
    this.allTimeTotalValue,
    this.fruitTags = const [],
    this.fruitPurposeStatement,
    this.sourceType = 'user_created',
    this.sourceActionId,
    this.categoryId,
    this.subcategoryId,
    this.categoryName,
    this.subcategoryName,
    this.notes = '',
    this.referenceUrl = '',
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
    List<FruitType> fruitTags = const [],
    String? fruitPurposeStatement,
    String sourceType = 'user_created',
    String? sourceActionId,
    String notes = '',
    String referenceUrl = '',
  }) {
    final purpose =
        purposeStatement.isEmpty ? category.defaultPurpose : purposeStatement;
    final days = (activeDays.toList()..sort()).join(',');
    return Habit(
      id: const Uuid().v4(),
      name: name,
      category: category,
      trackingType: trackingType,
      purposeStatement: purpose,
      dailyTarget: dailyTarget,
      targetUnit: targetUnit,
      isBuiltIn: isBuiltIn,
      createdAt: DateTime.now(),
      sortOrder: sortOrder,
      activeDays: days,
      trigger: trigger,
      copingPlan: copingPlan,
      entries: const [],
      fruitTags: fruitTags,
      fruitPurposeStatement: fruitPurposeStatement,
      sourceType: sourceType,
      sourceActionId: sourceActionId,
      notes: notes,
      referenceUrl: referenceUrl,
    );
  }

  Habit copyWith({
    String? name,
    HabitCategory? category,
    HabitTrackingType? trackingType,
    String? purposeStatement,
    double? dailyTarget,
    String? targetUnit,
    bool? isBuiltIn,
    bool? isArchived,
    DateTime? createdAt,
    int? sortOrder,
    String? activeDays,
    String? trigger,
    String? copingPlan,
    List<HabitEntry>? entries,
    int? allTimeCompletedCount,
    double? allTimeTotalValue,
    List<FruitType>? fruitTags,
    String? fruitPurposeStatement,
    String? sourceType,
    String? sourceActionId,
    String? categoryId,
    String? subcategoryId,
    String? categoryName,
    String? subcategoryName,
    String? notes,
    String? referenceUrl,
  }) =>
      Habit(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        trackingType: trackingType ?? this.trackingType,
        purposeStatement: purposeStatement ?? this.purposeStatement,
        dailyTarget: dailyTarget ?? this.dailyTarget,
        targetUnit: targetUnit ?? this.targetUnit,
        isBuiltIn: isBuiltIn ?? this.isBuiltIn,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt ?? this.createdAt,
        sortOrder: sortOrder ?? this.sortOrder,
        activeDays: activeDays ?? this.activeDays,
        trigger: trigger ?? this.trigger,
        copingPlan: copingPlan ?? this.copingPlan,
        entries: entries ?? this.entries,
        allTimeCompletedCount: allTimeCompletedCount ?? this.allTimeCompletedCount,
        allTimeTotalValue: allTimeTotalValue ?? this.allTimeTotalValue,
        fruitTags: fruitTags ?? this.fruitTags,
        fruitPurposeStatement: fruitPurposeStatement ?? this.fruitPurposeStatement,
        sourceType: sourceType ?? this.sourceType,
        sourceActionId: sourceActionId ?? this.sourceActionId,
        categoryId: categoryId ?? this.categoryId,
        subcategoryId: subcategoryId ?? this.subcategoryId,
        categoryName: categoryName ?? this.categoryName,
        subcategoryName: subcategoryName ?? this.subcategoryName,
        notes: notes ?? this.notes,
        referenceUrl: referenceUrl ?? this.referenceUrl,
      );

  Set<int> get activeDaySet {
    if (activeDays.isEmpty) return {1, 2, 3, 4, 5, 6, 7};
    final parsed = activeDays
        .split(',')
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .where((d) => d >= 1 && d <= 7)
        .toSet();
    // Fallback to all days if activeDays contains only invalid/corrupt data.
    return parsed.isEmpty ? {1, 2, 3, 4, 5, 6, 7} : parsed;
  }

  bool get isActiveToday => isActive(DateTime.now());

  bool isActive(DateTime date) {
    // Flutter weekday: Mon=1..Sun=7. Swift weekday: Sun=1..Sat=7.
    final flutterWeekday = date.weekday; // 1=Mon..7=Sun
    final swiftWeekday = flutterWeekday % 7 + 1; // 1=Sun..7=Sat
    return activeDaySet.contains(swiftWeekday);
  }

  HabitEntry? entryFor(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    return entries.where((e) => _isSameDay(e.date, dayStart)).firstOrNull;
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

  int totalCompletedDays() =>
      allTimeCompletedCount ?? entries.where((e) => e.isCompleted).length;

  double totalValue() =>
      allTimeTotalValue ?? entries.fold(0.0, (acc, e) => acc + e.value);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime _currentWeekStart() {
    final now = DateTime.now();
    // Week starts on Sunday (weekday 7 in Flutter)
    final daysFromSunday = now.weekday % 7; // Mon=1..Sun=7 → Sun=0..Sat=6
    return DateTime(now.year, now.month, now.day - daysFromSunday);
  }

  // ── Firestore ─────────────────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'name': name,
        'category': category.rawValue,
        'trackingType': trackingType.rawValue,
        'purposeStatement': purposeStatement,
        'dailyTarget': dailyTarget,
        'targetUnit': targetUnit,
        'isBuiltIn': isBuiltIn,
        'isArchived': isArchived,
        'createdAt': Timestamp.fromDate(createdAt),
        'sortOrder': sortOrder,
        'activeDays': activeDays,
        'trigger': trigger,
        'copingPlan': copingPlan,
        'allTimeCompletedCount': allTimeCompletedCount ?? 0,
        'allTimeTotalValue': allTimeTotalValue ?? 0.0,
        'fruitTags': fruitTags.map((f) => f.name).toList(),
        'fruitPurposeStatement': fruitPurposeStatement,
        'sourceType': sourceType,
        'sourceActionId': sourceActionId,
        'categoryId': categoryId,
        'subcategoryId': subcategoryId,
        'categoryName': categoryName,
        'subcategoryName': subcategoryName,
        'notes': notes,
        'referenceUrl': referenceUrl,
      };

  factory Habit.fromFirestore(
    Map<String, dynamic> data, {
    List<HabitEntry> entries = const [],
  }) {
    DateTime createdAt;
    final raw = data['createdAt'];
    if (raw is Timestamp) {
      createdAt = raw.toDate();
    } else if (raw is String) {
      createdAt = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }
    return Habit(
      id: data['id'] as String? ?? const Uuid().v4(),
      name: data['name'] as String? ?? '',
      category: HabitCategory.fromString(data['category'] as String? ?? ''),
      trackingType: HabitTrackingType.fromString(data['trackingType'] as String? ?? ''),
      purposeStatement: data['purposeStatement'] as String? ?? '',
      dailyTarget: (data['dailyTarget'] as num?)?.toDouble() ?? 1,
      targetUnit: data['targetUnit'] as String? ?? '',
      isBuiltIn: (data['isBuiltIn'] as bool?) ?? false,
      isArchived: (data['isArchived'] as bool?) ?? false,
      createdAt: createdAt,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      activeDays: data['activeDays'] as String? ?? '1,2,3,4,5,6,7',
      trigger: data['trigger'] as String? ?? '',
      copingPlan: data['copingPlan'] as String? ?? '',
      entries: entries,
      allTimeCompletedCount: (data['allTimeCompletedCount'] as num?)?.toInt(),
      allTimeTotalValue: (data['allTimeTotalValue'] as num?)?.toDouble(),
      fruitTags: ((data['fruitTags'] as List<dynamic>?) ?? [])
          .map((e) => FruitType.fromString(e as String))
          .toList(),
      fruitPurposeStatement: data['fruitPurposeStatement'] as String?,
      sourceType: data['sourceType'] as String? ?? 'user_created',
      sourceActionId: data['sourceActionId'] as String?,
      categoryId: data['categoryId'] as String?,
      subcategoryId: data['subcategoryId'] as String?,
      categoryName: data['categoryName'] as String?,
      subcategoryName: data['subcategoryName'] as String?,
      notes: data['notes'] as String? ?? '',
      referenceUrl: data['referenceUrl'] as String? ?? '',
    );
  }
}
