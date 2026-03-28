import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/circle.dart';
import '../../domain/repositories/circle_repository.dart';

class FirestoreCircleRepository implements CircleRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseFunctions _fn;

  FirestoreCircleRepository()
      : _db = FirebaseFirestore.instance,
        _auth = FirebaseAuth.instance,
        _fn = FirebaseFunctions.instanceFor(region: 'us-central1');

  String get _uid => _auth.currentUser!.uid;

  // ── Collection references ────────────────────────────────────────────────

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

  // ── Read operations (direct Firestore) ───────────────────────────────────

  @override
  Future<List<Circle>> listCircles() async {
    final memberSnaps = await _db
        .collectionGroup('members')
        .where('userId', isEqualTo: _uid)
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
          .data() as Map<String, dynamic>;
      return Circle(
        id: s.id,
        name: data['name'] as String? ?? '',
        description: data['description'] as String? ?? '',
        memberCount: data['memberCount'] as int? ?? 0,
        role: membership['role'] as String? ?? 'member',
        inviteCode: data['inviteCode'] as String? ?? '',
      );
    }).toList();
  }

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
      members: membersSnap.docs.map((m) {
        final md = m.data() as Map<String, dynamic>;
        return CircleMember(
          userId: md['userId'] as String? ?? '',
          role: md['role'] as String? ?? 'member',
          joinedAt: _tsToIso(md['joinedAt']),
        );
      }).toList(),
    );
  }

  @override
  Future<GratitudeWall> getGratitudeWall(String circleId,
      {int weeksBack = 0}) async {
    final cutoff =
        DateTime.now().subtract(Duration(days: (weeksBack + 1) * 7));
    final snap = await _gratitudes(circleId)
        .where('sharedAt',
            isGreaterThan: Timestamp.fromDate(cutoff))
        .orderBy('sharedAt', descending: true)
        .get();
    final posts = snap.docs
        .map((d) => d.data() as Map<String, dynamic>)
        .where((d) => d['deleted'] != true)
        .map((d) => GratitudePost(
              id: d['id'] as String? ?? '',
              gratitudeText: d['gratitudeText'] as String? ?? '',
              isAnonymous: d['isAnonymous'] as bool? ?? false,
              displayName: d['displayName'] as String?,
              sharedAt: _tsToIso(d['sharedAt']),
              isMine: d['userId'] == _uid,
            ))
        .toList();
    return GratitudeWall(
        circleId: circleId, weeksBack: weeksBack, gratitudes: posts);
  }

  @override
  Future<int> getGratitudeNewCount(String circleId) async {
    final seenSnap = await _seenDoc(circleId).get();
    final lastSeenAt = seenSnap.exists
        ? ((seenSnap.data() as Map<String, dynamic>?)?['lastSeenAt'] as Timestamp?)
        : null;

    Query query = _gratitudes(circleId);
    if (lastSeenAt != null) {
      query = query.where('sharedAt', isGreaterThan: lastSeenAt);
    }
    final snap = await query.get();
    return snap.docs
        .where(
            (d) => (d.data() as Map<String, dynamic>)['deleted'] != true)
        .length;
  }

  @override
  Future<int> getGratitudeWeekCount(String circleId) async {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final snap = await _gratitudes(circleId)
        .where('sharedAt',
            isGreaterThan: Timestamp.fromDate(weekAgo))
        .get();
    return snap.docs
        .where(
            (d) => (d.data() as Map<String, dynamic>)['deleted'] != true)
        .length;
  }

  @override
  Future<CircleHeatmap> getCircleHeatmap(String circleId,
      {int weekCount = 1}) async {
    final snap = await _heatmapEntries(circleId).get();
    final totalMembers = snap.size == 0 ? 1 : snap.size;
    final cutoff =
        DateTime.now().subtract(Duration(days: weekCount * 7));
    final cutoffStr = _dateStr(cutoff);

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
      _milestones(circleId)
          .orderBy('achievedAt', descending: false)
          .get(),
    ]);
    final totalsSnap = results[0] as DocumentSnapshot;
    final milestonesSnap = results[1] as QuerySnapshot;
    final totals = totalsSnap.exists
        ? totalsSnap.data()! as Map<String, dynamic>
        : <String, dynamic>{};
    return CollectiveMilestones(
      circleId: circleId,
      totalGivingDays: (totals['totalGivingDays'] as int?) ?? 0,
      totalHours:
          ((totals['totalHours'] as num?) ?? 0).toDouble(),
      totalGratitudeDays:
          (totals['totalGratitudeDays'] as int?) ?? 0,
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
        ? (circleSnap.data()! as Map<String, dynamic>)['memberCount']
                as int? ??
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
        isMine: data['senderId'] == _uid,
      );
    }).toList();
  }

  @override
  Future<String> generateShareLink(String circleId) async {
    final snap = await _circles.doc(circleId).get();
    final inviteCode = snap.exists
        ? (snap.data()! as Map<String, dynamic>)['inviteCode']
                as String? ??
            ''
        : '';
    return 'https://tribute.app/join?code=$inviteCode';
  }

  @override
  Future<void> markGratitudesSeen(String circleId) async {
    await _seenDoc(circleId)
        .set({'lastSeenAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> setSOSContacts(
      String circleId, List<String> contactUserIds) async {
    await _sosContactsDoc(circleId)
        .set({'contactUserIds': contactUserIds});
  }

  // ── Write operations (Firebase Callable Functions) ────────────────────────

  @override
  Future<Circle> createCircle(String name,
      {String description = ''}) async {
    final result = await _fn
        .httpsCallable('circleCreate')
        .call<Map<Object?, Object?>>({'name': name, 'description': description});
    final data = Map<String, dynamic>.from(result.data);
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
    final result = await _fn
        .httpsCallable('circleJoin')
        .call<Map<Object?, Object?>>({'inviteCode': inviteCode});
    final data = Map<String, dynamic>.from(result.data);
    return JoinCircleResult(
      id: data['id'] as String,
      name: data['name'] as String,
      alreadyMember: data['alreadyMember'] as bool? ?? false,
    );
  }

  @override
  Future<void> leaveCircle(String circleId) async {
    await _fn
        .httpsCallable('circleLeave')
        .call({'circleId': circleId});
  }

  @override
  Future<void> sendSOS(
      String circleId, String message, List<String> recipientIds) async {
    await _fn.httpsCallable('circleSendSOS').call({
      'circleId': circleId,
      'message': message,
      'recipientIds': recipientIds,
    });
  }

  @override
  Future<void> shareGratitude({
    required List<String> circleIds,
    required String gratitudeText,
    required bool isAnonymous,
    String? displayName,
  }) async {
    await _fn.httpsCallable('circleShareGratitude').call({
      'circleIds': circleIds,
      'gratitudeText': gratitudeText,
      'isAnonymous': isAnonymous,
      'displayName': displayName,
    });
  }

  @override
  Future<void> deleteGratitude(
      String circleId, String gratitudeId) async {
    await _fn.httpsCallable('circleDeleteGratitude').call({
      'circleId': circleId,
      'gratitudeId': gratitudeId,
    });
  }

  @override
  Future<void> submitHeatmapData(
      String circleId, List<Map<String, dynamic>> weekData) async {
    await _fn.httpsCallable('circleSubmitHeatmapData').call({
      'circleId': circleId,
      'weekData': weekData,
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _tsToIso(dynamic ts) {
    if (ts is Timestamp) return ts.toDate().toIso8601String();
    return DateTime.now().toIso8601String();
  }

  static String _dateStr(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
