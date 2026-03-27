/// Circle domain entities — pure Dart, no JSON or platform imports.
/// All JSON parsing lives in the data layer (CircleRepositoryImpl).
library;

class Circle {
  final String id;
  final String name;
  final String description;
  final int memberCount;
  final String role;
  final String inviteCode;

  const Circle({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.role,
    required this.inviteCode,
  });
}

class CircleMember {
  final String userId;
  final String role;
  final String joinedAt;

  const CircleMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
  });
}

class CircleDetails {
  final String id;
  final String name;
  final String description;
  final int memberCount;
  final String inviteCode;
  final String createdAt;
  final List<CircleMember> members;

  const CircleDetails({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.inviteCode,
    required this.createdAt,
    required this.members,
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
