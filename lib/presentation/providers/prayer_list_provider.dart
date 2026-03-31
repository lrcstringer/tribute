import 'package:flutter/foundation.dart';
import '../../domain/entities/circle.dart';
import '../../domain/repositories/circle_repository.dart';

class PrayerListProvider extends ChangeNotifier {
  final CircleRepository _repo;

  PrayerListProvider(this._repo);

  final Map<String, List<PrayerRequest>> _activeByCircle = {};
  final Map<String, List<PrayerRequest>> _answeredByCircle = {};
  final Map<String, bool> _loadingByCircle = {};
  String? error;

  List<PrayerRequest> activeFor(String circleId) =>
      _activeByCircle[circleId] ?? [];

  List<PrayerRequest> answeredFor(String circleId) =>
      _answeredByCircle[circleId] ?? [];

  bool isLoading(String circleId) => _loadingByCircle[circleId] ?? false;

  Future<void> load(String circleId) async {
    // Guard: don't start a second concurrent load for the same circle.
    if (_loadingByCircle[circleId] == true) return;
    _loadingByCircle[circleId] = true;
    error = null;
    notifyListeners();

    try {
      final all = await _repo.getPrayerRequests(circleId);
      _activeByCircle[circleId] = all
          .where((r) => r.status == PrayerRequestStatus.active)
          .toList();
      _answeredByCircle[circleId] = all
          .where((r) => r.status == PrayerRequestStatus.answered)
          .toList();
    } catch (e) {
      error = e.toString();
    } finally {
      _loadingByCircle[circleId] = false;
      notifyListeners();
    }
  }

  Future<void> createRequest({
    required String circleId,
    required String text,
    required PrayerDuration duration,
    bool anonymous = false,
  }) async {
    await _repo.createPrayerRequest(
      circleId: circleId,
      requestText: text,
      duration: duration,
      anonymous: anonymous,
    );
    // Reload to reflect server-calculated expiresAt.
    await load(circleId);
  }

  Future<void> prayFor(String circleId, String requestId, String uid) async {
    // Optimistic update: increment count + add uid locally before server confirms.
    _updateRequest(circleId, requestId, (r) {
      if (r.hasPrayed(uid)) return r;
      final newIds = [...r.prayedByUserIds, uid];
      return PrayerRequest(
        id: r.id,
        circleId: r.circleId,
        authorId: r.authorId,
        authorDisplayName: r.authorDisplayName,
        requestText: r.requestText,
        duration: r.duration,
        status: r.status,
        answeredNote: r.answeredNote,
        prayerCount: r.prayerCount + 1,
        prayedByUserIds: newIds,
        createdAt: r.createdAt,
        answeredAt: r.answeredAt,
        expiresAt: r.expiresAt,
      );
    });
    notifyListeners();

    try {
      await _repo.prayForRequest(circleId, requestId);
    } catch (_) {
      // Roll back on failure by reloading from source.
      await load(circleId);
    }
  }

  Future<void> markAnswered(String circleId, String requestId,
      {String? answeredNote}) async {
    await _repo.markPrayerAnswered(circleId, requestId,
        answeredNote: answeredNote);
    await load(circleId);
  }

  void _updateRequest(String circleId, String requestId,
      PrayerRequest Function(PrayerRequest) updater) {
    final active = _activeByCircle[circleId];
    if (active == null) return;
    final idx = active.indexWhere((r) => r.id == requestId);
    if (idx < 0) return;
    final updated = [...active];
    updated[idx] = updater(active[idx]);
    _activeByCircle[circleId] = updated;
  }
}
