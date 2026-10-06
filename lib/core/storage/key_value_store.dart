import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive key-value persistence (preferences, flags, small caches).
///
/// Reads are synchronous (values are cached in memory at startup) so UI state
/// like theme can be restored before the first frame. Never store tokens or
/// personal data here; use [SecureStore].
abstract interface class KeyValueStore {
  String? getString(String key);
  bool? getBool(String key);
  int? getInt(String key);
  Future<void> setString(String key, String value);
  Future<void> setBool(String key, bool value);
  Future<void> setInt(String key, int value);
  Future<void> remove(String key);
}

class SharedPreferencesStore implements KeyValueStore {
  SharedPreferencesStore(this._prefs);

  static Future<SharedPreferencesStore> create() async =>
      SharedPreferencesStore(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  bool? getBool(String key) => _prefs.getBool(key);

  @override
  int? getInt(String key) => _prefs.getInt(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  @override
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// Volatile implementation for tests and previews.
class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore([Map<String, Object>? initial])
    : _values = {...?initial};

  final Map<String, Object> _values;

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  bool? getBool(String key) => _values[key] as bool?;

  @override
  int? getInt(String key) => _values[key] as int?;

  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;

  @override
  Future<void> setBool(String key, bool value) async => _values[key] = value;

  @override
  Future<void> setInt(String key, int value) async => _values[key] = value;

  @override
  Future<void> remove(String key) async => _values.remove(key);
}
