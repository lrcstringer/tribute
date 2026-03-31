import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/circle.dart';
import '../../domain/repositories/circle_repository.dart';
import '../../domain/services/week_id_service.dart';

class FirestoreCircleRepository implements CircleRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseFunctions _fn;

  FirestoreCircleRepository()
      : _db = FirebaseFirestore.instance,
        _auth = FirebaseAuth.instance,
        _fn = FirebaseFunctions.instanceFor(region: 'us-central1');

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not authenticated');
    return user.uid;
  }

  // ── Collection / document references ─────────────────────────────────────

  CollectionReference get _circles => _db.collection('circles');

  CollectionReference _members(String circleId) =>
      _circles.doc(circleId).collection('members');

  CollectionReference _gratitudes(String circleId) =>
      _circles.doc(circleId).collection('gratitudes');

  CollectionReference _heatmapEntries(String circleId) =>
      _circles.doc(circleId).collection('heatmapEntries');

  CollectionReference _milestones(String circleId) =>
      _circles.doc(circleId).collection('milestones');

  CollectionReference _sosRequests(String circleId) =>
      _circles.doc(circleId).collection('sosRequests');

  DocumentReference _meta(String circleId) =>
      _circles.doc(circleId).collection('meta').doc('totals');

  DocumentReference _seenDoc(String circleId) =>
      _circles.doc(circleId).collection('userSeenGratitude').doc(_uid);

  DocumentReference _sosContactsDoc(String circleId) =>
      _circles.doc(circleId).collection('sosContacts').doc(_uid);

  // Feature sub-collections
  CollectionReference _prayerRequests(String circleId) =>
      _circles.doc(circleId).collection('prayer_requests');

  CollectionReference _scriptureFocus(String circleId) =>
      _circles.doc(circleId).collection('scripture_focus');

  CollectionReference _reflections(String circleId, String weekId) =>
      _scriptureFocus(circleId).doc(weekId).collection('reflections');

  CollectionReference _circleHabits(String circleId) =>
      _circles.doc(circleId).collection('circle_habits');

  CollectionReference _habitCompletions(String circleId, String habitId) =>
      _circleHabits(circleId).doc(habitId).collection('completions');

  CollectionReference _habitDailySummary(String circleId, String habitId) =>
      _circleHabits(circleId).doc(habitId).collection('daily_summary');

  CollectionReference _milestoneShares(String circleId) =>
      _circles.doc(circleId).collection('milestone_shares');

  CollectionReference _circleHabitMilestones(String circleId) =>
      _circles.doc(circleId).collection('circle_habit_milestones');

  CollectionReference _weeklyPulse(String circleId) =>
      _circles.doc(circleId).collection('weekly_pulse');

  CollectionReference _pulseResponses(String circleId, String weekId) =>
      _weeklyPulse(circleId).doc(weekId).collection('responses');

  CollectionReference _events(String circleId) =>
      _circles.doc(circleId).collection('events');

  // ── Callable helper ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> data) async {
    final result = await _fn
        .httpsCallable(name)
        .call<Map<Object?, Object?>>(data);
    return Map<String, dynamic>.from(result.data);
  }

  // ── Existing: listCircles ─────────────────────────────────────────────────

  @override
  Future<List<Circle>> listCircles() async {
    final uid = _uid;
    final memberSnaps = await _db
        .collectionGroup('members')
        .where('userId', isEqualTo: uid)
        .get();
    if (memberSnaps.docs.isEmpty) return [];

    final circleIds =
        memberSnaps.docs.map((d) => d.reference.parent.parent!.id).toList();
    final circleSnaps =
        await Future.wait(circleIds.map((id) => _circles.doc(id).get()));

    return circleSnaps.where((s) => s.exists).map((s) {
      final data = s.data()! as Map<String, dynamic>;
      final membership = memberSnaps.docs
          .firstWhere((m) => m.reference.parent.parent!.id == s.id)
          .data();
      return Circle(
        id: s.id,
        name: data['name'] as String? ?? '',
        description: data['description'] as String? ?? '',
        memberCount: data['memberCount'] as int? ?? 0,
        role: membership['role'] as String? ?? 'member',
        inviteCode: data['inviteCode'] as String? ?? '',
        settings: CircleSettings.fromMap(
            (data['settings'] as Map<String, dynamic>?) ?? {}),
      );
    }).toList();
  }

  // ── Existing: getCircleDetail ─────────────────────────────────────────────

  @override
  Future<CircleDetails> getCircleDetail(String circleId) async {
    final results = await Future.wait([
      _circles.doc(circleId).get(),
      _members(circleId).get(),
    ]);
    final snap = results[0] as DocumentSnapshot;
    final membersSnap = results[1] as QuerySnapshot;
    if (!snap.exists) throw Exception('Circle not found');
    final data = snap.data()! as Map<String, dynamic>;
    return CircleDetails(
      id: snap.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      memberCount: data['memberCount'] as int? ?? 0,
      inviteCode: data['inviteCode'] as String? ?? '',
      createdAt: _tsToIso(data['createdAt']),
      settings: CircleSettings.fromMap(
          (data['settings'] as Map<String, dynamic>?) ?? {}),
      members: membersSnap.docs.map((m) {
        final md = m.data() as Map<String, dynamic>;
        return CircleMember(
          userId: md['userId'] as String? ?? '',
          role: md['role'] as String? ?? 'member',
          joinedAt: _tsToIso(md['joinedAt']),
          displayName: md['displayName'] as String? ?? 'Circle Member',
        );
      }).toList(),
    );
  }

  // ── Existing: getGratitudeWall ────────────────────────────────────────────

  @override
  Future<GratitudeWall> getGratitudeWall(String circleId,
      {int weeksBack = 0}) async {
    final uid = _uid;
    final now = DateTime.now();
    final lowerBound = now.subtract(Duration(days: (weeksBack + 1) * 7));
    final upperBound = now.subtract(Duration(days: weeksBack * 7));
    final Query<Object?> query = _gratitudes(circleId)
        .where('sharedAt', isGreaterThan: Timestamp.fromDate(lowerBound))
        .where('sharedAt', isLessThanOrEqualTo: Timestamp.fromDate(upperBound))
        .orderBy('sharedAt', descending: true);
    final snap = await query.get();
    final posts = snap.docs
        .map((d) => d.data() as Map<String, dynamic>)
        .where((d) => d['deleted'] != true)
        .map((d) => GratitudePost(
              id: d['id'] as String? ?? '',
              gratitudeText: d['gratitudeText'] as String? ?? '',
              isAnonymous: d['isAnonymous'] as bool? ?? false,
              displayName: d['displayName'] as String?,
              sharedAt: _tsToIso(d['sharedAt']),
              isMine: d['userId'] == uid,
            ))
        .toList();
    return GratitudeWall(
        circleId: circleId, weeksBack: weeksBack, gratitudes: posts);
  }

  @override
  Future<int> getGratitudeNewCount(String circleId) async {
    final seenSnap = await _seenDoc(circleId).get();
    final lastSeenAt = seenSnap.exists
        ? ((seenSnap.data() as Map<String, dynamic>?)?['lastSeenAt']
            as Timestamp?)
        : null;

    Query query = _gratitudes(circleId);
    if (lastSeenAt != null) {
      query = query.where('sharedAt', isGreaterThan: lastSeenAt);
    }
    final snap = await query.get();
    return snap.docs
        .where((d) =>
            (d.data() as Map<String, dynamic>)['deleted'] != true)
        .length;
  }

  @override
  Future<int> getGratitudeWeekCount(String circleId) async {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final snap = await _gratitudes(circleId)
        .where('sharedAt', isGreaterThan: Timestamp.fromDate(weekAgo))
        .get();
    return snap.docs
        .where((d) =>
            (d.data() as Map<String, dynamic>)['deleted'] != true)
        .length;
  }

  @override
  Future<CircleHeatmap> getCircleHeatmap(String circleId,
      {int weekCount = 1}) async {
    final snap = await _heatmapEntries(circleId).get();
    final totalMembers = snap.size == 0 ? 1 : snap.size;
    final cutoff = DateTime.now().subtract(Duration(days: weekCount * 7));
    final cutoffStr = WeekIdService.dateStr(cutoff);

    final strongCount = <String, int>{};
    final seenCount = <String, int>{};

    for (final doc in snap.docs) {
      final entry = doc.data() as Map<String, dynamic>;
      final weekData =
          (entry['weekData'] as List<dynamic>?) ?? <dynamic>[];
      for (final day in weekData) {
        final d = day as Map<String, dynamic>;
        final date = d['date'] as String? ?? '';
        if (date.compareTo(cutoffStr) < 0) continue;
        seenCount[date] = (seenCount[date] ?? 0) + 1;
        final score = (d['score'] as num?)?.toDouble() ?? 0.0;
        if (score >= 0.5) {
          strongCount[date] = (strongCount[date] ?? 0) + 1;
        }
      }
    }

    final days = seenCount.keys.toList()..sort();
    return CircleHeatmap(
      circleId: circleId,
      weekCount: weekCount,
      days: days
          .map((date) => HeatmapDay(
                date: date,
                intensity: (strongCount[date] ?? 0) / totalMembers,
              ))
          .toList(),
    );
  }

  @override
  Future<CollectiveMilestones> getCircleMilestones(String circleId) async {
    final results = await Future.wait([
      _meta(circleId).get(),
      _milestones(circleId).orderBy('achievedAt', descending: false).get(),
    ]);
    final totalsSnap = results[0] as DocumentSnapshot;
    final milestonesSnap = results[1] as QuerySnapshot;
    final totals = totalsSnap.exists
        ? totalsSnap.data()! as Map<String, dynamic>
        : <String, dynamic>{};
    return CollectiveMilestones(
      circleId: circleId,
      totalGivingDays: (totals['totalGivingDays'] as int?) ?? 0,
      totalHours: ((totals['totalHours'] as num?) ?? 0).toDouble(),
      totalGratitudeDays: (totals['totalGratitudeDays'] as int?) ?? 0,
      milestones: milestonesSnap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return CollectiveMilestone(
          id: data['id'] as String? ?? d.id,
          title: data['title'] as String? ?? '',
          message: data['message'] as String? ?? '',
          achievedAt: _tsToIso(data['achievedAt']),
        );
      }).toList(),
    );
  }

  @override
  Future<CircleWeeklySummary> getSundaySummary(String circleId) async {
    final results = await Future.wait([
      _circles.doc(circleId).get(),
      _heatmapEntries(circleId).get(),
    ]);
    final circleSnap = results[0] as DocumentSnapshot;
    final entrySnaps = results[1] as QuerySnapshot;

    final totalMembers = circleSnap.exists
        ? (circleSnap.data()! as Map<String, dynamic>)['memberCount'] as int? ??
            0
        : 0;

    var activeCount = 0;
    var totalScore = 0.0;
    for (final doc in entrySnaps.docs) {
      final entry = doc.data() as Map<String, dynamic>;
      final weekData =
          (entry['weekData'] as List<dynamic>?) ?? <dynamic>[];
      if (weekData.isNotEmpty) {
        activeCount++;
        final avg = weekData.fold<double>(
              0,
              (acc, d) =>
                  acc +
                  ((d as Map<String, dynamic>)['score'] as num? ?? 0)
                      .toDouble(),
            ) /
            weekData.length;
        totalScore += avg;
      }
    }

    return CircleWeeklySummary(
      circleId: circleId,
      weekOf: DateTime.now().toIso8601String(),
      totalMembers: totalMembers,
      activeMembers: activeCount,
      averageScore: activeCount > 0 ? totalScore / activeCount : 0,
      topMembers: [],
    );
  }

  @override
  Future<List<SOSMessage>> getRecentSOS(
      {String? circleId, int limit = 20}) async {
    final uid = _uid;
    if (circleId == null) return [];
    final snap = await _sosRequests(circleId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return SOSMessage(
        id: data['id'] as String? ?? d.id,
        senderId: data['senderId'] as String? ?? '',
        circleId: data['circleId'] as String? ?? '',
        message: data['message'] as String? ?? '',
        createdAt: _tsToIso(data['createdAt']),
        isMine: data['senderId'] == uid,
      );
    }).toList();
  }

  @override
  Future<String> generateShareLink(String circleId) async {
    final snap = await _circles.doc(circleId).get();
    final inviteCode = snap.exists
        ? (snap.data()! as Map<String, dynamic>)['inviteCode'] as String? ?? ''
        : '';
    return 'https://mywalk.faith/join?code=$inviteCode';
  }

  @override
  Future<void> markGratitudesSeen(String circleId) async {
    await _seenDoc(circleId)
        .set({'lastSeenAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> setSOSContacts(
      String circleId, List<String> contactUserIds) async {
    await _sosContactsDoc(circleId).set({'contactUserIds': contactUserIds});
  }

  // ── Write operations (Callable Functions) ─────────────────────────────────

  @override
  Future<Circle> createCircle(String name,
      {String description = ''}) async {
    final data =
        await _call('circleCreate', {'name': name, 'description': description});
    return Circle(
      id: data['id'] as String,
      name: data['name'] as String,
      description: description,
      memberCount: 1,
      role: 'admin',
      inviteCode: data['inviteCode'] as String,
    );
  }

  @override
  Future<JoinCircleResult> joinCircle(String inviteCode) async {
    final data =
        await _call('circleJoin', {'inviteCode': inviteCode});
    return JoinCircleResult(
      id: data['id'] as String,
      name: data['name'] as String,
      alreadyMember: data['alreadyMember'] as bool? ?? false,
    );
  }

  @override
  Future<void> leaveCircle(String circleId) async {
    await _call('circleLeave', {'circleId': circleId});
  }

  @override
  Future<void> sendSOS(
      String circleId, String message, List<String> recipientIds) async {
    await _call('circleSendSOS',
        {'circleId': circleId, 'message': message, 'recipientIds': recipientIds});
  }

  @override
  Future<void> shareGratitude({
    required List<String> circleIds,
    required String gratitudeText,
    required bool isAnonymous,
    String? displayName,
  }) async {
    await _call('circleShareGratitude', {
      'circleIds': circleIds,
      'gratitudeText': gratitudeText,
      'isAnonymous': isAnonymous,
      'displayName': displayName,
    });
  }

  @override
  Future<void> deleteGratitude(String circleId, String gratitudeId) async {
    await _call('circleDeleteGratitude',
        {'circleId': circleId, 'gratitudeId': gratitudeId});
  }

  @override
  Future<void> submitHeatmapData(
      String circleId, List<Map<String, dynamic>> weekData) async {
    await _call('circleSubmitHeatmapData',
        {'circleId': circleId, 'weekData': weekData});
  }

  // ── Circle Settings ───────────────────────────────────────────────────────

  @override
  Future<void> updateCircleSettings(
      String circleId, CircleSettings settings) async {
    await _call('circleUpdateSettings',
        {'circleId': circleId, 'settings': settings.toMap()});
  }

  @override
  Future<void> updateMemberRole(
      String circleId, String targetUserId, String role) async {
    await _call('circleUpdateMemberRole',
        {'circleId': circleId, 'targetUserId': targetUserId, 'role': role});
  }

  // ── Feature 1: Prayer List ────────────────────────────────────────────────

  @override
  Future<List<PrayerRequest>> getPrayerRequests(String circleId) async {
    final uid = _uid;
    final snap = await _prayerRequests(circleId)
        .where('status', whereIn: ['ACTIVE', 'ANSWERED'])
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return _parsePrayerRequest(d.id, data, uid);
    }).toList();
  }

  @override
  Future<void> createPrayerRequest({
    required String circleId,
    required String requestText,
    required PrayerDuration duration,
    bool anonymous = false,
  }) async {
    await _call('prayerRequestCreate', {
      'circleId': circleId,
      'requestText': requestText,
      'duration': _prayerDurationToString(duration),
      'anonymous': anonymous,
    });
  }

  @override
  Future<void> prayForRequest(String circleId, String requestId) async {
    await _call('prayerPrayFor',
        {'circleId': circleId, 'requestId': requestId});
  }

  @override
  Future<void> markPrayerAnswered(String circleId, String requestId,
      {String? answeredNote}) async {
    await _call('prayerRequestMarkAnswered', {
      'circleId': circleId,
      'requestId': requestId,
      'answeredNote': answeredNote,
    });
  }

  // ── Feature 2: Scripture Focus ────────────────────────────────────────────

  @override
  Future<ScriptureFocus?> getCurrentScriptureFocus(String circleId) async {
    final weekId = WeekIdService.currentWeekId();
    final snap = await _scriptureFocus(circleId).doc(weekId).get();
    if (!snap.exists) return null;
    final data = snap.data() as Map<String, dynamic>;
    return _parseScriptureFocus(snap.id, data);
  }

  @override
  Future<List<ScriptureReflection>> getReflections(
      String circleId, String weekId) async {
    final snap = await _reflections(circleId, weekId)
        .orderBy('createdAt', descending: false)
        .get();
    return snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return ScriptureReflection(
        id: d.id,
        authorId: data['authorId'] as String? ?? '',
        authorDisplayName: data['authorDisplayName'] as String? ?? '',
        reflectionText: data['reflectionText'] as String? ?? '',
        createdAt: _tsToIso(data['createdAt']),
      );
    }).toList();
  }

  @override
  Future<void> setScriptureFocus({
    required String circleId,
    required String reference,
    required String translation,
    required String passageText,
    String? reflectionPrompt,
  }) async {
    await _call('circleSetScriptureFocus', {
      'circleId': circleId,
      'reference': reference,
      'translation': translation,
      'passageText': passageText,
      'reflectionPrompt': reflectionPrompt,
    });
  }

  @override
  Future<void> submitReflection({
    required String circleId,
    required String weekId,
    required String text,
  }) async {
    await _call('circleSubmitReflection', {
      'circleId': circleId,
      'weekId': weekId,
      'text': text,
    });
  }

  @override
  Future<String> fetchBiblePassage(
      String reference, String translation) async {
    final data = await _call('circleFetchBiblePassage',
        {'reference': reference, 'translation': translation});
    return data['text'] as String? ?? '';
  }

  // ── Feature 3: Circle Habits ──────────────────────────────────────────────

  @override
  Future<List<CircleHabit>> getCircleHabits(String circleId) async {
    final snap = await _circleHabits(circleId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: false)
        .get();
    return snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return _parseCircleHabit(d.id, data);
    }).toList();
  }

  @override
  Future<CircleHabitDailySummary?> getCircleHabitDailySummary(
    String circleId,
    String habitId,
    String date,
  ) async {
    final snap =
        await _habitDailySummary(circleId, habitId).doc(date).get();
    if (!snap.exists) return null;
    final data = snap.data() as Map<String, dynamic>;
    return CircleHabitDailySummary(
      id: snap.id,
      habitId: data['habitId'] as String? ?? habitId,
      totalMembers: data['totalMembers'] as int? ?? 0,
      completedCount: data['completedCount'] as int? ?? 0,
      completedUserIds: List<String>.from(
          (data['completedUserIds'] as List<dynamic>?) ?? []),
    );
  }

  @override
  Future<void> createCircleHabit({
    required String circleId,
    required String name,
    required CircleHabitTrackingType trackingType,
    int? targetValue,
    required CircleHabitFrequency frequency,
    List<int>? specificDays,
    String? anchorVerse,
    String? purposeStatement,
    String? description,
  }) async {
    await _call('circleCreateHabit', {
      'circleId': circleId,
      'name': name,
      'trackingType': _circleHabitTrackingTypeToString(trackingType),
      'targetValue': targetValue,
      'frequency': _circleHabitFrequencyToString(frequency),
      'specificDays': specificDays,
      'anchorVerse': anchorVerse,
      'purposeStatement': purposeStatement,
      'description': description,
    });
  }

  @override
  Future<void> completeCircleHabit({
    required String circleId,
    required String habitId,
    required int value,
    required String date,
  }) async {
    final uid = _uid;
    // Write directly to Firestore; server-side trigger handles aggregation.
    final completionId = '${date}_$uid';
    await _habitCompletions(circleId, habitId).doc(completionId).set({
      'id': completionId,
      'habitId': habitId,
      'userId': uid,
      'date': date,
      'value': value,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deactivateCircleHabit(String circleId, String habitId) async {
    await _call('circleDeactivateHabit',
        {'circleId': circleId, 'habitId': habitId});
  }

  // ── Feature 4: Encouragements ─────────────────────────────────────────────

  @override
  Future<List<Encouragement>> getReceivedEncouragements(
      String circleId) async {
    final data = await _call('circleGetEncouragements',
        {'circleId': circleId, 'type': 'received'});
    final list = (data['encouragements'] as List<dynamic>?) ?? [];
    return list
        .map((e) => _parseEncouragement(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Encouragement>> getSentEncouragements(String circleId) async {
    final data = await _call('circleGetEncouragements',
        {'circleId': circleId, 'type': 'sent'});
    final list = (data['encouragements'] as List<dynamic>?) ?? [];
    return list
        .map((e) => _parseEncouragement(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> sendEncouragement({
    required String circleId,
    required String recipientId,
    required EncouragementMessageType messageType,
    String? presetKey,
    String? customText,
    required bool isAnonymous,
  }) async {
    await _call('circleSendEncouragement', {
      'circleId': circleId,
      'recipientId': recipientId,
      'messageType':
          messageType == EncouragementMessageType.preset ? 'PRESET' : 'CUSTOM',
      'presetKey': presetKey,
      'customText': customText,
      'isAnonymous': isAnonymous,
    });
  }

  @override
  Future<void> markEncouragementRead(
      String circleId, String encouragementId) async {
    await _call('circleMarkEncouragementRead',
        {'circleId': circleId, 'encouragementId': encouragementId});
  }

  // ── Feature 5: Milestone Shares ───────────────────────────────────────────

  @override
  Future<List<MilestoneShare>> getMilestoneShares(String circleId) async {
    final uid = _uid;
    final snap = await _milestoneShares(circleId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();
    return snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return _parseMilestoneShare(d.id, data, uid);
    }).toList();
  }

  @override
  Future<void> shareMilestone({
    required List<String> circleIds,
    required MilestoneShareType milestoneType,
    required int milestoneValue,
    required String habitName,
    required String userDisplayName,
  }) async {
    await _call('circleShareMilestone', {
      'circleIds': circleIds,
      'milestoneType': _milestoneShareTypeToString(milestoneType),
      'milestoneValue': milestoneValue,
      'habitName': habitName,
      'userDisplayName': userDisplayName,
    });
  }

  @override
  Future<void> celebrateMilestone(String circleId, String shareId) async {
    await _call('circleCelebrateMilestone',
        {'circleId': circleId, 'shareId': shareId});
  }

  // ── Circle Habit Milestones ───────────────────────────────────────────────

  @override
  Future<List<CircleHabitMilestone>> getCircleHabitMilestones(
      String circleId) async {
    final snap = await _circleHabitMilestones(circleId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return CircleHabitMilestone(
        id: data['id'] as String? ?? d.id,
        circleId: data['circleId'] as String? ?? circleId,
        habitId: data['habitId'] as String? ?? '',
        habitName: data['habitName'] as String? ?? '',
        milestoneValue: (data['milestoneValue'] as int?) ?? 0,
        createdAt: _tsToIso(data['createdAt']),
      );
    }).toList();
  }

  // ── Feature 6: Weekly Pulse ───────────────────────────────────────────────

  @override
  Future<WeeklyPulse?> getCurrentWeeklyPulse(String circleId) async {
    final weekId = WeekIdService.currentWeekId();
    final snap = await _weeklyPulse(circleId).doc(weekId).get();
    if (!snap.exists) return null;
    final data = snap.data() as Map<String, dynamic>;
    return _parseWeeklyPulse(snap.id, data);
  }

  @override
  Future<PulseResponse?> getMyPulseResponse(
      String circleId, String weekId) async {
    final uid = _uid;
    final snap = await _pulseResponses(circleId, weekId).doc(uid).get();
    if (!snap.exists) return null;
    final data = snap.data() as Map<String, dynamic>;
    return _parsePulseResponse(snap.id, data);
  }

  @override
  Future<void> submitPulseResponse({
    required String circleId,
    required PulseStatus status,
    String? note,
    required bool isAnonymous,
  }) async {
    await _call('circleSubmitPulseResponse', {
      'circleId': circleId,
      'status': _pulseStatusToString(status),
      'note': note,
      'isAnonymous': isAnonymous,
    });
  }

  // ── Feature 7: Events ─────────────────────────────────────────────────────

  @override
  Future<List<CircleEvent>> getUpcomingEvents(String circleId) async {
    final now = DateTime.now();
    final snap = await _events(circleId)
        .where('eventDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('eventDate', descending: false)
        .limit(2)
        .get();
    return snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return _parseCircleEvent(d.id, data);
    }).toList();
  }

  @override
  Future<void> createEvent({
    required String circleId,
    required String title,
    required DateTime eventDate,
    String? description,
    String? location,
    String? meetingLink,
  }) async {
    await _call('circleCreateEvent', {
      'circleId': circleId,
      'title': title,
      'eventDate': eventDate.toIso8601String(),
      'description': description,
      'location': location,
      'meetingLink': meetingLink,
    });
  }

  @override
  Future<void> deleteEvent(String circleId, String eventId) async {
    await _call('circleDeleteEvent',
        {'circleId': circleId, 'eventId': eventId});
  }

  // ── Parse helpers ─────────────────────────────────────────────────────────

  static PrayerRequest _parsePrayerRequest(
      String id, Map<String, dynamic> d, String uid) {
    return PrayerRequest(
      id: id,
      circleId: d['circleId'] as String? ?? '',
      authorId: d['authorId'] as String? ?? '',
      authorDisplayName: d['authorDisplayName'] as String? ?? '',
      requestText: d['requestText'] as String? ?? '',
      duration: _parsePrayerDuration(d['duration'] as String?),
      status: _parsePrayerStatus(d['status'] as String?),
      answeredNote: d['answeredNote'] as String?,
      prayerCount: d['prayerCount'] as int? ?? 0,
      prayedByUserIds:
          List<String>.from((d['prayedByUserIds'] as List<dynamic>?) ?? []),
      createdAt: _tsToIso(d['createdAt']),
      answeredAt: d['answeredAt'] != null ? _tsToIso(d['answeredAt']) : null,
      expiresAt: d['expiresAt'] != null ? _tsToIso(d['expiresAt']) : null,
    );
  }

  static ScriptureFocus _parseScriptureFocus(
      String id, Map<String, dynamic> d) {
    return ScriptureFocus(
      id: id,
      circleId: d['circleId'] as String? ?? '',
      setById: d['setById'] as String? ?? '',
      setByDisplayName: d['setByDisplayName'] as String? ?? '',
      reference: d['reference'] as String? ?? '',
      text: d['text'] as String? ?? '',
      translation: d['translation'] as String? ?? '',
      reflectionPrompt: d['reflectionPrompt'] as String?,
      weekStartDate: _tsToIso(d['weekStartDate']),
      createdAt: _tsToIso(d['createdAt']),
    );
  }

  static CircleHabit _parseCircleHabit(
      String id, Map<String, dynamic> d) {
    return CircleHabit(
      id: id,
      circleId: d['circleId'] as String? ?? '',
      createdById: d['createdById'] as String? ?? '',
      name: d['name'] as String? ?? '',
      description: d['description'] as String?,
      trackingType: _parseCircleHabitTrackingType(d['trackingType'] as String?),
      targetValue: d['targetValue'] as int?,
      frequency: _parseCircleHabitFrequency(d['frequency'] as String?),
      specificDays: (d['specificDays'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      anchorVerse: d['anchorVerse'] as String?,
      purposeStatement: d['purposeStatement'] as String?,
      isActive: d['isActive'] as bool? ?? false,
      createdAt: _tsToIso(d['createdAt']),
      startsAt: _tsToIso(d['startsAt']),
      endsAt: d['endsAt'] != null ? _tsToIso(d['endsAt']) : null,
    );
  }

  static Encouragement _parseEncouragement(Map<String, dynamic> d) {
    return Encouragement(
      id: d['id'] as String? ?? '',
      circleId: d['circleId'] as String? ?? '',
      senderId: d['senderId'] as String?,
      senderDisplayName: d['senderDisplayName'] as String?,
      recipientId: d['recipientId'] as String? ?? '',
      messageType: (d['messageType'] as String?) == 'PRESET'
          ? EncouragementMessageType.preset
          : EncouragementMessageType.custom,
      presetKey: d['presetKey'] as String?,
      customText: d['customText'] as String?,
      isAnonymous: d['isAnonymous'] as bool? ?? false,
      isRead: d['isRead'] as bool? ?? false,
      createdAt: d['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  static MilestoneShare _parseMilestoneShare(
      String id, Map<String, dynamic> d, String uid) {
    return MilestoneShare(
      id: id,
      circleId: d['circleId'] as String? ?? '',
      userId: d['userId'] as String? ?? '',
      userDisplayName: d['userDisplayName'] as String? ?? '',
      milestoneType: _parseMilestoneShareType(d['milestoneType'] as String?),
      milestoneValue: d['milestoneValue'] as int? ?? 0,
      habitName: d['habitName'] as String? ?? '',
      celebrationCount: d['celebrationCount'] as int? ?? 0,
      celebratedByUserIds:
          List<String>.from((d['celebratedByUserIds'] as List<dynamic>?) ?? []),
      createdAt: _tsToIso(d['createdAt']),
    );
  }

  static WeeklyPulse _parseWeeklyPulse(String id, Map<String, dynamic> d) {
    final summaryRaw =
        (d['pulseSummary'] as Map<String, dynamic>?) ?? {};
    final summary = <PulseStatus, int>{};
    for (final status in PulseStatus.values) {
      final key = _pulseStatusToString(status);
      summary[status] = summaryRaw[key] as int? ?? 0;
    }
    return WeeklyPulse(
      id: id,
      circleId: d['circleId'] as String? ?? '',
      weekStartDate: _tsToIso(d['weekStartDate']),
      responseCount: d['responseCount'] as int? ?? 0,
      pulseSummary: summary,
      needsPrayerCount: d['needsPrayerCount'] as int? ?? 0,
    );
  }

  static PulseResponse _parsePulseResponse(
      String id, Map<String, dynamic> d) {
    return PulseResponse(
      id: id,
      userId: d['userId'] as String?,
      userDisplayName: d['userDisplayName'] as String?,
      status: _parsePulseStatus(d['status'] as String?),
      note: d['note'] as String?,
      isAnonymous: d['isAnonymous'] as bool? ?? false,
      createdAt: _tsToIso(d['createdAt']),
    );
  }

  static CircleEvent _parseCircleEvent(String id, Map<String, dynamic> d) {
    return CircleEvent(
      id: id,
      circleId: d['circleId'] as String? ?? '',
      createdById: d['createdById'] as String? ?? '',
      title: d['title'] as String? ?? '',
      description: d['description'] as String?,
      eventDate: _tsToIso(d['eventDate']),
      location: d['location'] as String?,
      meetingLink: d['meetingLink'] as String?,
      reminderSent: d['reminderSent'] as bool? ?? false,
      createdAt: _tsToIso(d['createdAt']),
    );
  }

  // ── Enum converters ───────────────────────────────────────────────────────

  static String _prayerDurationToString(PrayerDuration d) {
    switch (d) {
      case PrayerDuration.thisWeek:
        return 'THIS_WEEK';
      case PrayerDuration.ongoing:
        return 'ONGOING';
      case PrayerDuration.untilRemoved:
        return 'UNTIL_REMOVED';
    }
  }

  static PrayerDuration _parsePrayerDuration(String? s) {
    switch (s) {
      case 'THIS_WEEK':
        return PrayerDuration.thisWeek;
      case 'UNTIL_REMOVED':
        return PrayerDuration.untilRemoved;
      default:
        return PrayerDuration.ongoing;
    }
  }

  static PrayerRequestStatus _parsePrayerStatus(String? s) {
    switch (s) {
      case 'ANSWERED':
        return PrayerRequestStatus.answered;
      case 'EXPIRED':
        return PrayerRequestStatus.expired;
      default:
        return PrayerRequestStatus.active;
    }
  }

  static CircleHabitTrackingType _parseCircleHabitTrackingType(String? s) {
    switch (s) {
      case 'TIMED':
        return CircleHabitTrackingType.timed;
      case 'COUNT':
        return CircleHabitTrackingType.count;
      default:
        return CircleHabitTrackingType.checkIn;
    }
  }

  static String _circleHabitTrackingTypeToString(
      CircleHabitTrackingType t) {
    switch (t) {
      case CircleHabitTrackingType.timed:
        return 'TIMED';
      case CircleHabitTrackingType.count:
        return 'COUNT';
      case CircleHabitTrackingType.checkIn:
        return 'CHECK_IN';
    }
  }

  static CircleHabitFrequency _parseCircleHabitFrequency(String? s) {
    switch (s) {
      case 'WEEKLY':
        return CircleHabitFrequency.weekly;
      case 'SPECIFIC_DAYS':
        return CircleHabitFrequency.specificDays;
      default:
        return CircleHabitFrequency.daily;
    }
  }

  static String _circleHabitFrequencyToString(CircleHabitFrequency f) {
    switch (f) {
      case CircleHabitFrequency.weekly:
        return 'WEEKLY';
      case CircleHabitFrequency.specificDays:
        return 'SPECIFIC_DAYS';
      case CircleHabitFrequency.daily:
        return 'DAILY';
    }
  }

  static MilestoneShareType _parseMilestoneShareType(String? s) {
    switch (s) {
      case 'TIME':
        return MilestoneShareType.time;
      case 'COUNT':
        return MilestoneShareType.count;
      case 'CONSECUTIVE':
        return MilestoneShareType.consecutive;
      default:
        return MilestoneShareType.days;
    }
  }

  static String _milestoneShareTypeToString(MilestoneShareType t) {
    switch (t) {
      case MilestoneShareType.time:
        return 'TIME';
      case MilestoneShareType.count:
        return 'COUNT';
      case MilestoneShareType.consecutive:
        return 'CONSECUTIVE';
      case MilestoneShareType.days:
        return 'DAYS';
    }
  }

  static String _pulseStatusToString(PulseStatus s) {
    switch (s) {
      case PulseStatus.encouraged:
        return 'ENCOURAGED';
      case PulseStatus.steady:
        return 'STEADY';
      case PulseStatus.struggling:
        return 'STRUGGLING';
      case PulseStatus.needsPrayer:
        return 'NEEDS_PRAYER';
    }
  }

  static PulseStatus _parsePulseStatus(String? s) {
    switch (s) {
      case 'STEADY':
        return PulseStatus.steady;
      case 'STRUGGLING':
        return PulseStatus.struggling;
      case 'NEEDS_PRAYER':
        return PulseStatus.needsPrayer;
      default:
        return PulseStatus.encouraged;
    }
  }

  // ── Timestamp helper ──────────────────────────────────────────────────────

  static String _tsToIso(dynamic ts) {
    if (ts is Timestamp) return ts.toDate().toIso8601String();
    return DateTime.now().toIso8601String();
  }
}
