import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/repositories/user_preferences_repository.dart';

class SharedPreferencesRepository implements UserPreferencesRepository {
  // Cache the instance to avoid the overhead of resolving the singleton on every call.
  late final Future<SharedPreferences> _instance = SharedPreferences.getInstance();

  @override
  Future<int?> getInt(String key) async => (await _instance).getInt(key);

  @override
  Future<bool?> getBool(String key) async => (await _instance).getBool(key);

  @override
  Future<void> setInt(String key, int value) async =>
      (await _instance).setInt(key, value);

  @override
  Future<void> setBool(String key, bool value) async =>
      (await _instance).setBool(key, value);

  @override
  Future<void> remove(String key) async => (await _instance).remove(key);
}
