import 'package:shared_preferences/shared_preferences.dart';

/// Small string store used by the reference cache.
///
/// Default is in-memory; apps that must work offline (technician) override it
/// with [SharedPreferencesReferenceStore].
abstract interface class ReferenceStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

class InMemoryReferenceStore implements ReferenceStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }
}

class SharedPreferencesReferenceStore implements ReferenceStore {
  SharedPreferencesReferenceStore({Future<SharedPreferences>? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _preferences;

  String _key(String key) => 'reference_data.$key';

  @override
  Future<String?> read(String key) async {
    final prefs = await _preferences;
    return prefs.getString(_key(key));
  }

  @override
  Future<void> write(String key, String value) async {
    final prefs = await _preferences;
    await prefs.setString(_key(key), value);
  }

  @override
  Future<void> remove(String key) async {
    final prefs = await _preferences;
    await prefs.remove(_key(key));
  }
}
