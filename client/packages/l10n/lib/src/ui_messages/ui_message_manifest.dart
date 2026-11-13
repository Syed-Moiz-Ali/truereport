class UiMessageLanguage {
  const UiMessageLanguage({
    required this.code,
    required this.direction,
    this.version = 0,
    this.versions = const <String, int>{},
    this.nativeName = '',
    this.nameEn = '',
  });

  final String code;
  final String direction;
  final int version;
  final Map<String, int> versions;
  final String nativeName;
  final String nameEn;

  bool get isRtl => direction.toLowerCase() == 'rtl';

  bool get hasVersions => versions.isNotEmpty;

  String get displayName {
    if (nativeName.isNotEmpty) return nativeName;
    if (nameEn.isNotEmpty) return nameEn;
    return code;
  }

  factory UiMessageLanguage.fromJson(Map<String, dynamic> json) {
    final rawCode = json['code'];
    final rawDirection = json['direction'];
    final rawNativeName = json['nativeName'];
    final rawNameEn = json['nameEn'];
    return UiMessageLanguage(
      code: rawCode is String ? rawCode : '',
      direction: rawDirection is String && rawDirection.isNotEmpty
          ? rawDirection
          : 'ltr',
      version: _asInt(json['version']),
      versions: _asVersionMap(json['versions']),
      nativeName: rawNativeName is String ? rawNativeName : '',
      nameEn: rawNameEn is String ? rawNameEn : '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'direction': direction,
    'version': version,
    'versions': Map<String, dynamic>.from(versions),
    'nativeName': nativeName,
    'nameEn': nameEn,
  };
}

class UiMessageManifest {
  const UiMessageManifest({
    required this.defaultLanguage,
    required this.namespaceVersions,
    required this.languages,
  });

  final String defaultLanguage;
  final Map<String, int> namespaceVersions;
  final List<UiMessageLanguage> languages;

  List<String> get codes => languages.map((item) => item.code).toList();

  UiMessageLanguage? languageFor(String code) {
    for (final language in languages) {
      if (language.code == code) return language;
    }
    return null;
  }

  Map<String, int> expectedVersions(String code) {
    final language = languageFor(code);
    if (language != null && language.hasVersions) {
      return Map<String, int>.from(language.versions);
    }
    return const <String, int>{};
  }

  factory UiMessageManifest.fromJson(Map<String, dynamic> json) {
    final rawDefault = json['defaultLanguage'];
    final defaultLanguage = rawDefault is String && rawDefault.isNotEmpty
        ? rawDefault
        : 'en';
    final namespaceVersions = _namespaceVersions(json);
    final languages = _languages(json, namespaceVersions);
    return UiMessageManifest(
      defaultLanguage: defaultLanguage,
      namespaceVersions: namespaceVersions,
      languages: languages,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'defaultLanguage': defaultLanguage,
    'namespaces': Map<String, dynamic>.from(namespaceVersions),
    'languages': languages.map((item) => item.toJson()).toList(),
  };
}

Map<String, int> _namespaceVersions(Map<String, dynamic> json) {
  final result = <String, int>{};
  final raw = json['namespaces'];
  if (raw is Map) {
    raw.forEach((key, value) {
      if (key is String) result[key] = _asInt(value);
    });
  } else if (raw is List) {
    for (final entry in raw) {
      if (entry is String) result[entry] = 0;
    }
  }
  if (result.isEmpty) {
    result['platform_admin'] = 0;
    result['common'] = 0;
  }
  return result;
}

List<UiMessageLanguage> _languages(
  Map<String, dynamic> json,
  Map<String, int> namespaceVersions,
) {
  final raw = json['languages'];
  if (raw is! List) return const [];
  final catalogVersion = _asInt(json['catalogVersion']);
  return raw.whereType<Map>().map((entry) {
    final map = Map<String, dynamic>.from(entry);
    if (!map.containsKey('version') && catalogVersion > 0) {
      map['version'] = catalogVersion;
    }
    if (!map.containsKey('direction')) map['direction'] = 'ltr';
    return UiMessageLanguage.fromJson(map);
  }).toList();
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

Map<String, int> _asVersionMap(Object? value) {
  final result = <String, int>{};
  if (value is Map) {
    value.forEach((key, item) {
      if (key is String) result[key] = _asInt(item);
    });
  }
  return result;
}
