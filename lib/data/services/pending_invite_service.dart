import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and delivers pending Prayer Circle invite codes across the
/// app lifecycle — including codes received during onboarding (before the
/// main content view is mounted).
///
/// Flow:
///   1. `root_view.dart` calls `save(code)` when a deep link is received.
///   2. `content_view.dart` calls `consume()` on mount (handles codes saved
///      while the user was in onboarding / app was cold-started).
///   3. While the app is running, `content_view.dart` listens to [stream]
///      and shows the invitation dialog immediately on any new code.
class PendingInviteService {
  static const _key = 'pending_invite_code';

  final SharedPreferences _prefs;
  final _controller = StreamController<String>.broadcast();

  PendingInviteService(this._prefs);

  /// Emits invite codes as they arrive while the app is foregrounded.
  Stream<String> get stream => _controller.stream;

  /// Saves [code] to persistent storage AND emits on [stream] so any active
  /// listener can react immediately.
  void save(String code) {
    _prefs.setString(_key, code);
    _controller.add(code);
  }

  /// Returns and clears any invite code saved during a prior session or
  /// cold-start onboarding. Returns `null` if nothing is waiting.
  String? consume() {
    final code = _prefs.getString(_key);
    if (code != null) _prefs.remove(_key);
    return code;
  }

  void dispose() => _controller.close();
}
