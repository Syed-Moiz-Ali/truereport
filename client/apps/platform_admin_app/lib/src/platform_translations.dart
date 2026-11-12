import 'package:api_client/api_client.dart';
import 'package:auth/auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'platform_config_models.dart';

String _str(dynamic value) => value == null ? '' : value.toString();

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _dbl(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map<String, dynamic> ? value : <String, dynamic>{};

List<dynamic> _list(dynamic value) =>
    value is List<dynamic> ? value : const <dynamic>[];

/// Per-entity/per-field translation status (lowercase wire values).
///
/// Language activation requires every required field to be `approved`.
/// `translating` is work-in-progress; queue summary cards fold it into the
/// Draft count (see translation_queue_screen.dart).
abstract final class TranslationStatus {
  static const String missing = 'missing';
  static const String draft = 'draft';
  static const String translating = 'translating';
  static const String reviewed = 'reviewed';
  static const String approved = 'approved';

  /// Normalizes backend status values (any casing) to the lowercase wire
  /// values above; unknown values fall back to [missing].
  static String normalize(dynamic value) {
    switch (_str(value).toLowerCase()) {
      case draft:
        return draft;
      case translating:
        return translating;
      case reviewed:
        return reviewed;
      case approved:
        return approved;
      case missing:
      default:
        return missing;
    }
  }
}

/// Language lifecycle: DRAFT → TRANSLATING → REVIEW → LIVE → RETIRED.
///
/// Only `LIVE` languages are exposed to Workshop/Technician/public;
/// everything else is Platform Admin only.
abstract final class LanguageStatus {
  static const String draft = 'DRAFT';
  static const String translating = 'TRANSLATING';
  static const String review = 'REVIEW';
  static const String live = 'LIVE';
  static const String retired = 'RETIRED';

  /// Normalizes backend status values; unknown values fall back to [draft].
  static String normalize(dynamic value) {
    switch (_str(value).toUpperCase()) {
      case translating:
        return translating;
      case review:
        return review;
      case live:
        return live;
      case retired:
        return retired;
      case draft:
      default:
        return draft;
    }
  }
}

/// Entity types covered by the translation backlog.
abstract final class TranslationEntityType {
  static const String category = 'CATEGORY';
  static const String item = 'ITEM';
  static const String optionSet = 'OPTION_SET';
  static const String optionValue = 'OPTION_VALUE';
  static const String template = 'TEMPLATE';
  static const String documentType = 'DOCUMENT_TYPE';
  static const String issueField = 'ISSUE_FIELD';
}

@immutable
class TranslationItem {
  const TranslationItem({
    required this.entityType,
    required this.entityId,
    required this.entityCode,
    required this.field,
    required this.defaultText,
    required this.text,
    required this.status,
  });

  final String entityType;
  final String entityId;
  final String entityCode;
  final String field;
  final String defaultText;
  final String? text;
  final String status;

  /// Stable selection key for bulk actions (`entityType|entityId|field`).
  String get key => '$entityType|$entityId|$field';

  bool get isApproved => status == TranslationStatus.approved;

  bool get isMissing =>
      status == TranslationStatus.missing ||
      (text == null || text!.trim().isEmpty);

  TranslationItem copyWith({
    String? entityType,
    String? entityId,
    String? entityCode,
    String? field,
    String? defaultText,
    String? text,
    String? status,
  }) {
    return TranslationItem(
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      entityCode: entityCode ?? this.entityCode,
      field: field ?? this.field,
      defaultText: defaultText ?? this.defaultText,
      text: text ?? this.text,
      status: status ?? this.status,
    );
  }

  factory TranslationItem.fromJson(Map<String, dynamic> json) =>
      TranslationItem(
        entityType: _str(json['entityType']),
        entityId: _str(json['entityId']),
        entityCode: _str(json['entityCode']),
        field: _str(json['field']),
        defaultText: _str(json['defaultText']),
        text: json['text'] == null ? null : _str(json['text']),
        status: TranslationStatus.normalize(json['status']),
      );

  Map<String, dynamic> toJson() => {
    'entityType': entityType,
    'entityId': entityId,
    'entityCode': entityCode,
    'field': field,
    'defaultText': defaultText,
    'text': text,
    'status': status,
  };
}

@immutable
class TranslationBacklogGroup {
  const TranslationBacklogGroup({
    required this.entityType,
    required this.total,
    required this.approved,
    required this.items,
  });

  final String entityType;
  final int total;
  final int approved;
  final List<TranslationItem> items;

  factory TranslationBacklogGroup.fromJson(Map<String, dynamic> json) {
    final items = _list(json['items'])
        .map((e) => TranslationItem.fromJson(_map(e)))
        .toList(growable: false);
    return TranslationBacklogGroup(
      entityType: _str(json['entityType']),
      total: json['total'] == null ? items.length : _int(json['total']),
      approved: json['approved'] == null
          ? items.where((e) => e.status == TranslationStatus.approved).length
          : _int(json['approved']),
      items: items,
    );
  }
}

@immutable
class TranslationBacklog {
  const TranslationBacklog({
    required this.languageCode,
    required this.languageStatus,
    required this.totalRequired,
    required this.approvedCount,
    required this.coveragePercent,
    required this.groups,
  });

  final String languageCode;
  final String languageStatus;
  final int totalRequired;
  final int approvedCount;
  final double coveragePercent;
  final List<TranslationBacklogGroup> groups;

  /// All items across every group, in group order.
  List<TranslationItem> get allItems =>
      groups.expand((group) => group.items).toList(growable: false);

  /// True when every required translation is approved (publish gate).
  bool get isComplete => totalRequired > 0 && approvedCount >= totalRequired;

  factory TranslationBacklog.fromJson(Map<String, dynamic> json) {
    // Backend contract nests identity as `language: {code, status}`; accept
    // the flat shape too so fakes and future payloads keep working.
    final language = json['language'];
    final code = language is Map<String, dynamic>
        ? _str(language['code'])
        : _str(json['languageCode']);
    final status = language is Map<String, dynamic>
        ? _str(language['status'])
        : _str(json['languageStatus']);
    final groups = _list(json['groups'])
        .map((e) => TranslationBacklogGroup.fromJson(_map(e)))
        .toList(growable: false);
    final total = json['totalRequired'] == null
        ? groups.fold<int>(0, (sum, group) => sum + group.total)
        : _int(json['totalRequired']);
    final approved = json['approvedCount'] == null
        ? groups.fold<int>(0, (sum, group) => sum + group.approved)
        : _int(json['approvedCount']);
    final percent = json['coveragePercent'] == null
        ? (total == 0 ? 0.0 : approved / total * 100)
        : _dbl(json['coveragePercent']);
    return TranslationBacklog(
      languageCode: code,
      languageStatus: LanguageStatus.normalize(status),
      totalRequired: total,
      approvedCount: approved,
      coveragePercent: percent,
      groups: groups,
    );
  }
}

@immutable
class EntityCoverage {
  const EntityCoverage({required this.total, required this.approved});

  final int total;
  final int approved;

  factory EntityCoverage.fromJson(Map<String, dynamic> json) => EntityCoverage(
    total: _int(json['total']),
    approved: _int(json['approved']),
  );
}

@immutable
class TranslationCoverage {
  const TranslationCoverage({
    required this.language,
    required this.totalRequired,
    required this.approvedCount,
    required this.coveragePercent,
    required this.byEntity,
  });

  final String language;
  final int totalRequired;
  final int approvedCount;
  final double coveragePercent;
  final Map<String, EntityCoverage> byEntity;

  factory TranslationCoverage.fromJson(Map<String, dynamic> json) =>
      TranslationCoverage(
        language: _str(json['language']),
        totalRequired: _int(json['totalRequired']),
        approvedCount: _int(json['approvedCount']),
        coveragePercent: _dbl(json['coveragePercent']),
        byEntity: (_map(json['byEntity'])).map(
          (key, value) => MapEntry(key, EntityCoverage.fromJson(_map(value))),
        ),
      );
}

/// Typed client for the Platform Admin translation queue endpoints.
///
/// Subclassable (non-final) with this exact constructor so widget tests can
/// override [translationApiProvider] with an in-memory fake.
class TranslationApi {
  TranslationApi(this._api, this._endpoints);

  final ApiClient _api;
  final ApiEndpoints _endpoints;

  Future<TranslationBacklog> fetchBacklog(String code) async {
    final data = await _api.getDynamic(
      _endpoints.platformLanguageBacklog(code),
    );
    return TranslationBacklog.fromJson(_map(data));
  }

  Future<TranslationCoverage> fetchCoverage(String code) async {
    final data = await _api.getDynamic(
      _endpoints.platformLanguageCoverageFor(code),
    );
    return TranslationCoverage.fromJson(_map(data));
  }

  Future<TranslationItem> upsertTranslation({
    required String entityType,
    required String entityId,
    required String field,
    required String language,
    required String text,
    String? status,
  }) async {
    final data = await _api.putDynamic(
      _endpoints.platformTranslations,
      body: {
        'entityType': entityType,
        'entityId': entityId,
        'field': field,
        'language': language,
        'text': text,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return TranslationItem.fromJson(_map(data));
  }

  Future<PlatformLanguage> publishLanguage(String code) async {
    final data = await _api.postDynamic(
      _endpoints.platformLanguagePublish(code),
    );
    return PlatformLanguage.fromJson(_map(data));
  }

  Future<PlatformLanguage> setLanguageStatus(String code, String status) async {
    final data = await _api.putDynamic(
      _endpoints.platformLanguageStatus(code),
      body: {'status': status},
    );
    return PlatformLanguage.fromJson(_map(data));
  }
}

final translationApiProvider = Provider<TranslationApi>(
  (ref) => TranslationApi(
    ref.watch(apiClientProvider),
    ref.watch(apiEndpointsProvider),
  ),
);

final languageBacklogProvider = FutureProvider.autoDispose
    .family<TranslationBacklog, String>(
      (ref, code) => ref.watch(translationApiProvider).fetchBacklog(code),
    );

final languageCoverageProvider = FutureProvider.autoDispose
    .family<TranslationCoverage, String>(
      (ref, code) => ref.watch(translationApiProvider).fetchCoverage(code),
    );
