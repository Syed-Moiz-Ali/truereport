/// One language bundle as served by `/{client}/bundle?lang=`.
///
/// The payload carries both the per-namespace [catalogs] used by the
/// namespaced (Platform Admin) app and the flat, English-filled [messages] map
/// used by the ARB-backed apps. Parsing is deliberately tolerant: edited
/// catalogs in production must never crash the UI.
class UiMessageBundle {
  const UiMessageBundle({
    required this.language,
    required this.fallbackLanguage,
    required this.versions,
    required this.catalogs,
    this.messages = const <String, String>{},
    this.client = '',
    this.namespaces = const <String>[],
    this.missingKeys = const <String, List<String>>{},
  });

  final String language;
  final String fallbackLanguage;
  final Map<String, int> versions;
  final Map<String, Map<String, String>> catalogs;

  /// Flat key -> value map: `catalogs.common` merged with `catalogs.<client>`.
  final Map<String, String> messages;
  final String client;
  final List<String> namespaces;
  final Map<String, List<String>> missingKeys;

  String? lookup(String namespace, String key) => catalogs[namespace]?[key];

  /// Flattens the catalogs for [language]. `common` is applied first so the
  /// client namespace wins on a key collision.
  Map<String, String> mergedMessages() {
    if (messages.isNotEmpty) return messages;
    final merged = <String, String>{};
    final common = catalogs['common'];
    if (common != null) merged.addAll(common);
    for (final entry in catalogs.entries) {
      if (entry.key == 'common') continue;
      merged.addAll(entry.value);
    }
    return merged;
  }

  factory UiMessageBundle.fromJson(Map<String, dynamic> json) {
    final language = _asNonEmptyString(json['language']) ?? '';
    final fallbackLanguage =
        _asNonEmptyString(json['fallbackLanguage']) ?? 'en';
    final client = _asNonEmptyString(json['client']) ?? '';

    final versions = <String, int>{};
    final rawVersions = json['versions'];
    if (rawVersions is Map) {
      rawVersions.forEach((key, value) {
        if (key is String) versions[key] = _asInt(value);
      });
    }

    final rawNamespaces = json['namespaces'];
    final namespaces = <String>[];
    if (rawNamespaces is List) {
      namespaces.addAll(rawNamespaces.whereType<String>());
    } else if (rawNamespaces is Map) {
      namespaces.addAll(rawNamespaces.keys.whereType<String>());
    }

    final catalogs = <String, Map<String, String>>{};
    final rawCatalogs = json['catalogs'];
    if (rawCatalogs is Map) {
      rawCatalogs.forEach((key, value) {
        if (key is String && value is Map) {
          catalogs[key] = _asStrings(value);
        }
      });
    }

    // Legacy single-catalog shape: `catalog` + `namespaces`.
    final rawCatalog = json['catalog'];
    if (catalogs.isEmpty && rawCatalog is Map) {
      final flat = _asStrings(rawCatalog);
      final legacyNamespaces = namespaces.isEmpty
          ? const <String>['platform_admin']
          : namespaces;
      for (final namespace in legacyNamespaces) {
        catalogs[namespace] = Map<String, String>.from(flat);
      }
      for (final namespace in catalogs.keys) {
        versions[namespace] = _asInt(json['version']);
      }
    }

    final messages = <String, String>{};
    final rawMessages = json['messages'];
    if (rawMessages is Map) {
      messages.addAll(_asStrings(rawMessages));
    }
    if (messages.isEmpty) {
      final common = catalogs['common'];
      if (common != null) messages.addAll(common);
      for (final entry in catalogs.entries) {
        if (entry.key == 'common') continue;
        messages.addAll(entry.value);
      }
    } else {
      // Catalogs are authoritative for keys they define.
      for (final entry in catalogs.entries) {
        messages.addAll(entry.value);
      }
    }

    final missingKeys = <String, List<String>>{};
    final rawMissing = json['missingKeys'];
    if (rawMissing is Map) {
      rawMissing.forEach((key, value) {
        if (key is String && value is List) {
          missingKeys[key] = value.whereType<String>().toList();
        }
      });
    } else if (rawMissing is List) {
      final flat = rawMissing.whereType<String>().toList();
      if (flat.isNotEmpty) missingKeys['platform_admin'] = flat;
    }

    if (language.isEmpty) {
      throw const FormatException('UiMessageBundle is missing "language"');
    }
    if (catalogs.isEmpty && messages.isEmpty) {
      throw FormatException('UiMessageBundle for "$language" has no catalogs');
    }

    return UiMessageBundle(
      language: language,
      fallbackLanguage: fallbackLanguage,
      versions: versions,
      catalogs: catalogs,
      messages: messages,
      client: client,
      namespaces: namespaces,
      missingKeys: missingKeys,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'language': language,
    'fallbackLanguage': fallbackLanguage,
    if (client.isNotEmpty) 'client': client,
    if (namespaces.isNotEmpty) 'namespaces': List<String>.from(namespaces),
    'versions': Map<String, dynamic>.from(versions),
    'catalogs': <String, dynamic>{
      for (final entry in catalogs.entries)
        entry.key: Map<String, dynamic>.from(entry.value),
    },
    'messages': Map<String, dynamic>.from(messages),
    'missingKeys': <String, dynamic>{
      for (final entry in missingKeys.entries)
        entry.key: List<String>.from(entry.value),
    },
  };
}

/// Keeps strings and stringifies scalar values; silently drops anything that
/// cannot be shown as text (nulls, maps, lists).
Map<String, String> _asStrings(Map value) {
  final result = <String, String>{};
  value.forEach((key, item) {
    if (key is! String) return;
    if (item is String) {
      result[key] = item;
    } else if (item is num || item is bool) {
      result[key] = item.toString();
    }
  });
  return result;
}

String? _asNonEmptyString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
