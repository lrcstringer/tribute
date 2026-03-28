/// Domain-layer interface for key-value user preferences.
/// Keeps domain services (WeekCycleManager, EngagementService) free of
/// SharedPreferences / platform infrastructure.
abstract class UserPreferencesRepository {
  /// Hydrates the local cache from the remote store for the current user.
  /// Must be called after sign-in and on app startup when a session exists.
  /// Implementations that are already in-sync (e.g. local-only) may no-op.
  Future<void> init();

  Future<int?> getInt(String key);
  Future<bool?> getBool(String key);
  Future<void> setInt(String key, int value);
  Future<void> setBool(String key, bool value);
  Future<void> remove(String key);
}
