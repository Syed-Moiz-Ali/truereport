class UiMessageBundle {
  const UiMessageBundle({
    required this.language,
    required this.fallbackLanguage,
    required this.versions,
    required this.catalogs,
    this.missingKeys = const <String, List<String>>{},
  });

  final String language;
  final String fallbackLanguage;
  final Map<String, int> versions;
  final Map<String, Map<String, String>> catalogs;
  final Map<String, List<String>> missingKeys;

  String? lookup(String namespace, String key) => catalogs[namespace]?[key];

  factory UiMessageBundle.fromJson(Map<String, dynamic> json) {
    final rawLanguage = json['language'];
    final rawFallback = json['fallbackLanguage'];
    final language = rawLanguage is String && rawLanguage.isNotEmpty
        ? rawLanguage
        : '';
    final fallbackLanguage = rawFallback is String && rawFallback.isNotEmpty
        ? rawFallback
        : 'en';
    final versions = <String, int>{};
    final catalogs = <String, Map<String, String>>{};
    final missingKeys = <String, List<String>>{};
    final rawVersions = json['versions'];
    if (rawVersions is Map) {
      rawVersions.forEach((key, value) {
        if (key is String) versions[key] = _asInt(value);
      });
    }
    final rawCatalogs = json['catalogs'];
    if (rawCatalogs is Map) {
      rawCatalogs.forEach((key, value) {
        if (key is String && value is Map) {
          catalogs[key] = _asStrings(value);
        }
      });
    }
    final rawVersion = json['version'];
    final rawNamespaces = json['namespaces'];
    final rawCatalog = json['catalog'];
    if (catalogs.isEmpty && rawCatalog is Map) {
      final flat = _asStrings(rawCatalog);
      final namespaces = rawNamespaces is List
          ? rawNamespaces.whereType<String>().toList()
          : <String>['platform_admin'];
      for (final namespace in namespaces) {
        catalogs[namespace] = Map<String, String>.from(flat);
      }
      for (final namespace in catalogs.keys) {
        versions[namespace] = _asInt(rawVersion);
      }
    }
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
    if (catalogs.isEmpty) {
      throw FormatException('UiMessageBundle for "$language" has no catalogs');
    }
    return UiMessageBundle(
      language: language,
      fallbackLanguage: fallbackLanguage,
      versions: versions,
      catalogs: catalogs,
      missingKeys: missingKeys,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'language': language,
    'fallbackLanguage': fallbackLanguage,
    'versions': Map<String, dynamic>.from(versions),
    'catalogs': <String, dynamic>{
      for (final entry in catalogs.entries)
        entry.key: Map<String, dynamic>.from(entry.value),
    },
    'missingKeys': <String, dynamic>{
      for (final entry in missingKeys.entries)
        entry.key: List<String>.from(entry.value),
    },
  };
}

Map<String, String> _asStrings(Map value) {
  final result = <String, String>{};
  value.forEach((key, item) {
    if (key is String && item is String) result[key] = item;
  });
  return result;
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
