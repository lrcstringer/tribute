/// Circle domain entities — pure Dart, no JSON or platform imports.
/// All JSON parsing lives in the data layer (FirestoreCircleRepository).
library;

// ── Settings ──────────────────────────────────────────────────────────────────

class CircleSettings {
  final String scriptureFocusPermission; // 'admin' | 'any_member'
  final String eventPermission;          // 'admin' | 'any_member'
  final String pulseVisibility;          // 'aggregate' | 'named'
  final bool encouragementPromptsEnabled;
  final String circleHabitGridVisibility; // 'checkmarks' | 'names'

  const CircleSettings({
    this.scriptureFocusPermission = 'admin',
    this.eventPermission = 'admin',
    this.pulseVisibility = 'aggregate',
    this.encouragementPromptsEnabled = true,
    this.circleHabitGridVisibility = 'checkmarks',
  });

  factory CircleSettings.fromMap(Map<String, dynamic> m) => CircleSettings(
        scriptureFocusPermission:
            m['scriptureFocusPermission'] as String? ?? 'admin',
        eventPermission: m['eventPermission'] as String? ?? 'admin',
        pulseVisibility: m['pulseVisibility'] as String? ?? 'aggregate',
        encouragementPromptsEnabled:
            m['encouragementPromptsEnabled'] as bool? ?? true,
        circleHabitGridVisibility:
            m['circleHabitGridVisibility'] as String? ?? 'checkmarks',
      );

  Map<String, dynamic> toMap() => {
        'scriptureFocusPermission': scriptureFocusPermission,
        'eventPermission': eventPermission,
        'pulseVisibility': pulseVisibility,
        'encouragementPromptsEnabled': encouragementPromptsEnabled,
        'circleHabitGridVisibility': circleHabitGridVisibility,
      };
}

// ── Core circle types ─────────────────────────────────────────────────────────

class Circle {
  final String id;
  final String name;
  final String description;
  final int memberCount;
  final String role;
  final String inviteCode;
  final CircleSettings settings;

  const Circle({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.role,
    required this.inviteCode,
    this.settings = const CircleSettings(),
  });

  bool get isAdmin => role == 'admin';
}

class CircleMember {
  final String userId;
  final String role;
  final String joinedAt;
  final String displayName;

  const CircleMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.displayName = 'Circle Member',
  });

  bool get isAdmin => role == 'admin';
}

class CircleDetails {
  final String id;
  final String name;
  final String description;
  final int memberCount;
  final String inviteCode;
  final String createdAt;
  final List<CircleMember> members;
  final CircleSettings settings;

  const CircleDetails({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.inviteCode,
    required this.createdAt,
    required this.members,
    this.settings = const CircleSettings(),
  });
}

class JoinCircleResult {
  final String id;
  final String name;
  final bool alreadyMember;

  const JoinCircleResult({
    required this.id,
    required this.name,
    required this.alreadyMember,
  });
}

class SOSMessage {
  final String id;
  final String senderId;
  final String circleId;
  final String message;
  final String createdAt;
  final bool isMine;

  const SOSMessage({
    required this.id,
    required this.senderId,
    required this.circleId,
    required this.message,
    required this.createdAt,
    required this.isMine,
  });
}

class GratitudePost {
  final String id;
  final String gratitudeText;
  final bool isAnonymous;
  final String? displayName;
  final String sharedAt;
  final bool isMine;

  const GratitudePost({
    required this.id,
    required this.gratitudeText,
    required this.isAnonymous,
    this.displayName,
    required this.sharedAt,
    required this.isMine,
  });
}

class GratitudeWall {
  final String circleId;
  final int weeksBack;
  final List<GratitudePost> gratitudes;

  const GratitudeWall({
    required this.circleId,
    required this.weeksBack,
    required this.gratitudes,
  });
}

class CircleWeeklyTopMember {
  final String userId;
  final int streak;

  const CircleWeeklyTopMember({required this.userId, required this.streak});
}

class CircleWeeklySummary {
  final String circleId;
  final String weekOf;
  final int totalMembers;
  final int activeMembers;
  final double averageScore;
  final List<CircleWeeklyTopMember> topMembers;

  const CircleWeeklySummary({
    required this.circleId,
    required this.weekOf,
    required this.totalMembers,
    required this.activeMembers,
    required this.averageScore,
    required this.topMembers,
  });
}

class HeatmapDay {
  final String date;
  final double intensity;

  const HeatmapDay({required this.date, required this.intensity});
}

class CircleHeatmap {
  final String circleId;
  final int weekCount;
  final List<HeatmapDay> days;

  const CircleHeatmap({
    required this.circleId,
    required this.weekCount,
    required this.days,
  });
}

class CollectiveMilestone {
  final String id;
  final String title;
  final String message;
  final String achievedAt;

  const CollectiveMilestone({
    required this.id,
    required this.title,
    required this.message,
    required this.achievedAt,
  });
}

class CollectiveMilestones {
  final String circleId;
  final int totalGivingDays;
  final double totalHours;
  final int totalGratitudeDays;
  final List<CollectiveMilestone> milestones;

  const CollectiveMilestones({
    required this.circleId,
    required this.totalGivingDays,
    required this.totalHours,
    required this.totalGratitudeDays,
    required this.milestones,
  });
}

// ── Feature 1: Prayer List ─────────────────────────────────────────────────────

enum PrayerDuration { thisWeek, ongoing, untilRemoved }
enum PrayerRequestStatus { active, answered, expired }

class PrayerRequest {
  final String id;
  final String circleId;
  final String authorId;
  final String authorDisplayName;
  final String requestText;
  final PrayerDuration duration;
  final PrayerRequestStatus status;
  final String? answeredNote;
  final int prayerCount;
  final List<String> prayedByUserIds;
  final String createdAt;
  final String? answeredAt;
  final String? expiresAt;

  const PrayerRequest({
    required this.id,
    required this.circleId,
    required this.authorId,
    required this.authorDisplayName,
    required this.requestText,
    required this.duration,
    required this.status,
    this.answeredNote,
    required this.prayerCount,
    required this.prayedByUserIds,
    required this.createdAt,
    this.answeredAt,
    this.expiresAt,
  });

  bool hasPrayed(String uid) => prayedByUserIds.contains(uid);
  bool isAuthor(String uid) => authorId == uid;
}

// ── Feature 2: Scripture Focus ────────────────────────────────────────────────

class ScriptureFocus {
  final String id; // YYYY-WW
  final String circleId;
  final String setById;
  final String setByDisplayName;
  final String reference;
  final String text;
  final String translation;
  final String? reflectionPrompt;
  final String weekStartDate;
  final String createdAt;
  final List<ScriptureReflection> reflections;

  const ScriptureFocus({
    required this.id,
    required this.circleId,
    required this.setById,
    required this.setByDisplayName,
    required this.reference,
    required this.text,
    required this.translation,
    this.reflectionPrompt,
    required this.weekStartDate,
    required this.createdAt,
    this.reflections = const [],
  });

  bool canEdit(String uid, CircleSettings settings) =>
      uid == setById ||
      settings.scriptureFocusPermission == 'any_member';
}

class ScriptureReflection {
  final String id;
  final String authorId;
  final String authorDisplayName;
  final String reflectionText;
  final String createdAt;

  const ScriptureReflection({
    required this.id,
    required this.authorId,
    required this.authorDisplayName,
    required this.reflectionText,
    required this.createdAt,
  });

  bool isAuthor(String uid) => authorId == uid;
}

// ── Feature 3: Circle Habits ──────────────────────────────────────────────────

enum CircleHabitFrequency { daily, weekly, specificDays }
enum CircleHabitTrackingType { checkIn, timed, count }

class CircleHabit {
  final String id;
  final String circleId;
  final String createdById;
  final String name;
  final String? description;
  final CircleHabitTrackingType trackingType;
  final int? targetValue;
  final CircleHabitFrequency frequency;
  final List<int>? specificDays; // 0=Sun … 6=Sat
  final String? anchorVerse;
  final String? purposeStatement;
  final bool isActive;
  final String createdAt;
  final String startsAt;
  final String? endsAt;

  const CircleHabit({
    required this.id,
    required this.circleId,
    required this.createdById,
    required this.name,
    this.description,
    required this.trackingType,
    this.targetValue,
    required this.frequency,
    this.specificDays,
    this.anchorVerse,
    this.purposeStatement,
    required this.isActive,
    required this.createdAt,
    required this.startsAt,
    this.endsAt,
  });

  /// Returns true if this habit is scheduled for the given weekday (0=Sun … 6=Sat).
  bool isScheduledFor(int weekday) {
    switch (frequency) {
      case CircleHabitFrequency.daily:
        return true;
      case CircleHabitFrequency.weekly:
        return weekday == 0; // Sunday
      case CircleHabitFrequency.specificDays:
        return specificDays?.contains(weekday) ?? false;
    }
  }
}

class CircleHabitDailySummary {
  final String id; // YYYY-MM-DD
  final String habitId;
  final int totalMembers;
  final int completedCount;
  final List<String> completedUserIds;

  const CircleHabitDailySummary({
    required this.id,
    required this.habitId,
    required this.totalMembers,
    required this.completedCount,
    required this.completedUserIds,
  });

  double get completionRate =>
      totalMembers == 0 ? 0.0 : completedCount / totalMembers;

  bool hasCompleted(String uid) => completedUserIds.contains(uid);
}

// ── Feature 4: Encouragements ─────────────────────────────────────────────────

enum EncouragementMessageType { preset, custom }

class Encouragement {
  final String id;
  final String circleId;
  final String? senderId; // null when anonymous (masked server-side)
  final String? senderDisplayName; // null when anonymous
  final String recipientId;
  final EncouragementMessageType messageType;
  final String? presetKey;
  final String? customText;
  final bool isAnonymous;
  final bool isRead;
  final String createdAt;

  const Encouragement({
    required this.id,
    required this.circleId,
    this.senderId,
    this.senderDisplayName,
    required this.recipientId,
    required this.messageType,
    this.presetKey,
    this.customText,
    required this.isAnonymous,
    required this.isRead,
    required this.createdAt,
  });

  String get displayMessage {
    if (messageType == EncouragementMessageType.preset &&
        presetKey != null &&
        _presets.containsKey(presetKey)) {
      return _presets[presetKey]!;
    }
    return customText ?? '';
  }

  static const Map<String, String> _presets = {
    'PRAYING': 'Praying for you today.',
    'KEEP_GOING': "Keep going \u2014 you're doing great.",
    'GOD_SEES': 'God sees your faithfulness.',
    'PROUD': 'Proud of you.',
    'NOT_ALONE': "You're not walking alone.",
    'STRENGTH': 'Praying God gives you strength today.',
    'THINKING': "Just wanted you to know I'm thinking of you.",
    'GRATEFUL': 'Grateful to be in community with you.',
  };

  static List<MapEntry<String, String>> get presetEntries =>
      _presets.entries.toList();
}

// ── Feature 5: Milestone Shares ───────────────────────────────────────────────

enum MilestoneShareType { time, count, days, consecutive }

class MilestoneShare {
  final String id;
  final String circleId;
  final String userId;
  final String userDisplayName;
  final MilestoneShareType milestoneType;
  final int milestoneValue;
  final String habitName;
  final int celebrationCount;
  final List<String> celebratedByUserIds;
  final String createdAt;

  const MilestoneShare({
    required this.id,
    required this.circleId,
    required this.userId,
    required this.userDisplayName,
    required this.milestoneType,
    required this.milestoneValue,
    required this.habitName,
    required this.celebrationCount,
    required this.celebratedByUserIds,
    required this.createdAt,
  });

  bool hasCelebrated(String uid) => celebratedByUserIds.contains(uid);
  bool isAuthor(String uid) => userId == uid;

  String get displayLabel {
    switch (milestoneType) {
      case MilestoneShareType.time:
        return '$milestoneValue ${milestoneValue == 1 ? 'hour' : 'hours'} of $habitName';
      case MilestoneShareType.count:
        return '$milestoneValue completions of $habitName';
      case MilestoneShareType.days:
        return '$milestoneValue days of $habitName';
      case MilestoneShareType.consecutive:
        return '$milestoneValue consecutive days of $habitName';
    }
  }
}

// ── Feature 6: Weekly Pulse ───────────────────────────────────────────────────

enum PulseStatus { encouraged, steady, struggling, needsPrayer }

class WeeklyPulse {
  final String id; // YYYY-WW
  final String circleId;
  final String weekStartDate;
  final int responseCount;
  final Map<PulseStatus, int> pulseSummary;
  final int needsPrayerCount;
  final List<PulseResponse> responses;

  const WeeklyPulse({
    required this.id,
    required this.circleId,
    required this.weekStartDate,
    required this.responseCount,
    required this.pulseSummary,
    required this.needsPrayerCount,
    this.responses = const [],
  });

  int countFor(PulseStatus status) => pulseSummary[status] ?? 0;
}

class PulseResponse {
  final String id; // userId
  final String? userId; // null when anonymous (masked server-side)
  final String? userDisplayName;
  final PulseStatus status;
  final String? note;
  final bool isAnonymous;
  final String createdAt;

  const PulseResponse({
    required this.id,
    this.userId,
    this.userDisplayName,
    required this.status,
    this.note,
    required this.isAnonymous,
    required this.createdAt,
  });
}

// ── Circle Habit Milestones (auto-generated) ──────────────────────────────────

class CircleHabitMilestone {
  final String id;         // '{habitId}_completions_{value}'
  final String circleId;
  final String habitId;
  final String habitName;
  final int milestoneValue; // e.g. 100
  final String createdAt;

  const CircleHabitMilestone({
    required this.id,
    required this.circleId,
    required this.habitId,
    required this.habitName,
    required this.milestoneValue,
    required this.createdAt,
  });

  String get displayLabel =>
      'Your circle hit $milestoneValue completions of $habitName!';
}

// ── Feature 7: Events ─────────────────────────────────────────────────────────

class CircleEvent {
  final String id;
  final String circleId;
  final String createdById;
  final String title;
  final String? description;
  final String eventDate; // ISO string
  final String? location;
  final String? meetingLink;
  final bool reminderSent;
  final String createdAt;

  const CircleEvent({
    required this.id,
    required this.circleId,
    required this.createdById,
    required this.title,
    this.description,
    required this.eventDate,
    this.location,
    this.meetingLink,
    required this.reminderSent,
    required this.createdAt,
  });

  bool isAuthor(String uid) => createdById == uid;

  DateTime get eventDateTime => DateTime.parse(eventDate);

  bool get isUpcoming => eventDateTime.isAfter(DateTime.now());
}
