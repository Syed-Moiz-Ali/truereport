import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'ui_message_catalog.dart';
import 'ui_message_manifest.dart';

abstract class UiMessageStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

class InMemoryUiMessageStore implements UiMessageStore {
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

class SharedPreferencesUiMessageStore implements UiMessageStore {
  const SharedPreferencesUiMessageStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<String?> read(String key) async => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
}

Future<UiMessageStore> createUiMessageStore() async {
  final prefs = await SharedPreferences.getInstance();
  return SharedPreferencesUiMessageStore(prefs);
}

class UiMessageCache {
  UiMessageCache(this._store);

  static const String manifestKey = 'ui_messages_manifest';

  static String bundleKey(String language) => 'ui_messages_$language';

  static String catalogKey(String language) =>
      'ui_messages_${language}_catalog';

  static String versionsKey(String language) =>
      'ui_messages_${language}_versions';

  final UiMessageStore _store;
  final Map<String, Map<String, Map<String, String>>> _catalogs =
      <String, Map<String, Map<String, String>>>{};
  final Map<String, Map<String, int>> _versions = <String, Map<String, int>>{};
  final Map<String, Map<String, List<String>>> _missingKeys =
      <String, Map<String, List<String>>>{};
  UiMessageManifest? _manifest;

  UiMessageManifest? get manifest => _manifest;

  List<String> get cachedLanguages => _catalogs.keys.toList();

  bool get isEmpty => _catalogs.isEmpty;

  bool hasCatalog(String language) => _catalogs.containsKey(language);

  String? lookup(String language, String namespace, String key) =>
      _catalogs[language]?[namespace]?[key];

  Map<String, Map<String, String>> snapshot(String language) {
    final namespaces = _catalogs[language];
    if (namespaces == null) return const {};
    return <String, Map<String, String>>{
      for (final entry in namespaces.entries)
        entry.key: Map<String, String>.from(entry.value),
    };
  }

  bool isFresh(String language, Map<String, int> expected) {
    final cached = _versions[language];
    if (cached == null || !_catalogs.containsKey(language)) return false;
    for (final entry in expected.entries) {
      if (cached[entry.key] != entry.value) return false;
    }
    return true;
  }

  Future<void> restore() async {
    final rawManifest = await _store.read(manifestKey);
    final manifest = _decodeManifest(rawManifest);
    if (manifest != null) {
      _manifest = manifest;
    }
    final languages = _manifest?.codes ?? const <String>[];
    for (final language in languages) {
      await _restoreLanguage(language);
    }
  }

  Future<bool> _restoreLanguage(String language) async {
    final raw = await _store.read(bundleKey(language));
    final decoded = _decodeAtomic(language, raw);
    if (decoded != null) {
      _applyDecoded(language, decoded);
      return true;
    }
    final migrated = await _restoreLegacy(language);
    if (migrated) return true;
    if (!_catalogs.containsKey(language)) {
      _catalogs.remove(language);
      _versions.remove(language);
      _missingKeys.remove(language);
    }
    return false;
  }

  Future<bool> _restoreLegacy(String language) async {
    final results = await Future.wait(<Future<String?>>[
      _store.read(catalogKey(language)),
      _store.read(versionsKey(language)),
    ]);
    if (results[0] == null || results[1] == null) return false;
    final atomic = _decodeAtomic(
      language,
      jsonEncode(<String, dynamic>{
        'language': language,
        'versions': _decodeJsonMap(results[1]),
        'catalog': _decodeJsonMap(results[0]),
        'missingKeys': <String, dynamic>{},
      }),
    );
    if (atomic == null) return false;
    _applyDecoded(language, atomic);
    await _store.write(bundleKey(language), jsonEncode(atomic.toJson()));
    return true;
  }

  void _applyDecoded(String language, UiMessageBundle bundle) {
    _catalogs[language] = <String, Map<String, String>>{
      for (final entry in bundle.catalogs.entries)
        entry.key: Map<String, String>.from(entry.value),
    };
    _versions[language] = Map<String, int>.from(bundle.versions);
    _missingKeys[language] = <String, List<String>>{
      for (final entry in bundle.missingKeys.entries)
        entry.key: List<String>.from(entry.value),
    };
  }

  Future<void> saveManifest(UiMessageManifest manifest) async {
    _manifest = manifest;
    await _store.write(manifestKey, jsonEncode(manifest.toJson()));
  }

  Future<void> storeBundle(UiMessageBundle bundle) async {
    final payload = <String, dynamic>{
      'language': bundle.language,
      'versions': Map<String, dynamic>.from(bundle.versions),
      'catalog': <String, dynamic>{
        for (final entry in bundle.catalogs.entries)
          entry.key: Map<String, dynamic>.from(entry.value),
      },
      'missingKeys': <String, dynamic>{
        for (final entry in bundle.missingKeys.entries)
          entry.key: List<String>.from(entry.value),
      },
    };
    await _store.write(bundleKey(bundle.language), jsonEncode(payload));
    _applyDecoded(bundle.language, bundle);
  }

  Future<void> evictLanguage(String language) async {
    _catalogs.remove(language);
    _versions.remove(language);
    _missingKeys.remove(language);
    await _store.remove(bundleKey(language));
    await _store.remove(catalogKey(language));
    await _store.remove(versionsKey(language));
  }

  UiMessageManifest? _decodeManifest(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return UiMessageManifest.fromJson(Map<String, dynamic>.from(decoded));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  UiMessageBundle? _decodeAtomic(String language, String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      if (map['language'] != language) return null;
      if (map['versions'] is! Map) return null;
      final catalog = map['catalog'] ?? map['catalogs'];
      if (catalog is! Map) return null;
      if (map['missingKeys'] is! Map) return null;
      if (!_isIntMap(map['versions'] as Map)) return null;
      if (!_isCatalogMap(catalog)) return null;
      if (!_isMissingKeysMap(map['missingKeys'] as Map)) return null;
      final candidate = UiMessageBundle.fromJson(<String, dynamic>{
        'language': map['language'],
        'fallbackLanguage': map['fallbackLanguage'] ?? 'en',
        'versions': Map<String, dynamic>.from(map['versions'] as Map),
        'catalogs': Map<String, dynamic>.from(catalog),
        'missingKeys': Map<String, dynamic>.from(map['missingKeys'] as Map),
      });
      final catalogKeys = candidate.catalogs.keys.toSet();
      final versionKeys = candidate.versions.keys.toSet();
      if (catalogKeys.isEmpty) return null;
      if (versionKeys.length != catalogKeys.length) return null;
      if (!versionKeys.containsAll(catalogKeys)) return null;
      return candidate;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _decodeJsonMap(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }
}

bool _isIntMap(Map value) {
  for (final entry in value.entries) {
    if (entry.key is! String || entry.value is! int) return false;
  }
  return true;
}

bool _isCatalogMap(Map value) {
  for (final entry in value.entries) {
    if (entry.key is! String || entry.value is! Map) return false;
    for (final item in (entry.value as Map).entries) {
      if (item.key is! String || item.value is! String) return false;
    }
  }
  return true;
}

bool _isMissingKeysMap(Map value) {
  for (final entry in value.entries) {
    if (entry.key is! String || entry.value is! List) return false;
    for (final item in (entry.value as List)) {
      if (item is! String) return false;
    }
  }
  return true;
}
