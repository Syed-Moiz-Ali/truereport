import 'package:flutter/foundation.dart';

/// Canonical content entity types exposed by the manual translation units
/// endpoint. The backend owns the same codes; the order here is the order the
/// picker and grouped list use.
abstract final class ManualTranslationEntityType {
  static const String category = 'CATEGORY';
  static const String item = 'ITEM';
  static const String optionSet = 'OPTION_SET';
  static const String optionValue = 'OPTION_VALUE';
  static const String template = 'TEMPLATE';
  static const String documentType = 'DOCUMENT_TYPE';
  static const String issueField = 'ISSUE_FIELD';

  static const List<String> all = <String>[
    category,
    item,
    optionSet,
    optionValue,
    template,
    documentType,
    issueField,
  ];
}

/// `filter` values accepted by `GET /platform/i18n/content/units`.
abstract final class ManualTranslationFilter {
  static const String all = 'all';
  static const String missing = 'missing';
}

/// One canonical field for one language. `text`, `status` and `origin` are
/// null/absent when the language has no translation for the field.
@immutable
class ManualTranslationUnit {
  const ManualTranslationUnit({
    required this.entityType,
    required this.entityId,
    required this.field,
    required this.sourceText,
    this.text,
    this.status,
    this.origin,
    this.safetyCritical = false,
  });

  final String entityType;
  final String entityId;
  final String field;

  /// Plain English source text; never used as the translation.
  final String sourceText;

  /// Authored/reviewed translation for the requested language.
  final String? text;

  /// `DRAFT`, `PENDING_REVIEW`, `REVIEWED` or `STALE` when translated.
  final String? status;

  /// `AUTHORED`, `REVIEWED` or `MACHINE`. Manual saves are never `MACHINE`.
  final String? origin;

  final bool safetyCritical;

  /// Stable row identity across pages.
  String get key => '$entityType/$entityId/$field';

  String get trimmedText => (text ?? '').trim();

  bool get hasTranslation => trimmedText.isNotEmpty;

  bool get isMissing => !hasTranslation;

  bool get hasStatus => (status ?? '').trim().isNotEmpty;

  /// Keeps the request identity when the write response omits it.
  ManualTranslationUnit withIdentity(ManualTranslationUnit fallback) {
    return ManualTranslationUnit(
      entityType: entityType.isEmpty ? fallback.entityType : entityType,
      entityId: entityId.isEmpty ? fallback.entityId : entityId,
      field: field.isEmpty ? fallback.field : field,
      sourceText: sourceText.isEmpty ? fallback.sourceText : sourceText,
      text: text ?? fallback.text,
      status: status ?? fallback.status,
      origin: origin ?? fallback.origin,
      safetyCritical: safetyCritical || fallback.safetyCritical,
    );
  }

  ManualTranslationUnit copyWith({
    String? text,
    String? status,
    String? origin,
  }) {
    return ManualTranslationUnit(
      entityType: entityType,
      entityId: entityId,
      field: field,
      sourceText: sourceText,
      text: text ?? this.text,
      status: status ?? this.status,
      origin: origin ?? this.origin,
      safetyCritical: safetyCritical,
    );
  }

  factory ManualTranslationUnit.fromJson(Map<String, dynamic> json) {
    return ManualTranslationUnit(
      entityType: _text(json['entityType']),
      entityId: _text(json['entityId']),
      field: _text(json['field']),
      sourceText: _text(json['sourceText']),
      // The list endpoint calls it `text`; the write endpoint returns `body`.
      text: _textOrNull(json['text']) ?? _textOrNull(json['body']),
      status: _textOrNull(json['status']),
      origin: _textOrNull(json['origin']),
      safetyCritical: _flag(json['safetyCritical']),
    );
  }
}

/// One page of manual translation units plus the server total.
@immutable
class ManualTranslationPage {
  const ManualTranslationPage({
    required this.lang,
    required this.total,
    required this.page,
    required this.size,
    required this.items,
  });

  final String lang;
  final int total;
  final int page;
  final int size;
  final List<ManualTranslationUnit> items;

  factory ManualTranslationPage.fromJson(Map<String, dynamic> json) {
    return ManualTranslationPage(
      lang: _text(json['lang']),
      total: _int(json['total']),
      page: _int(json['page']),
      size: _int(json['size']),
      items: _list(json['items'])
          .whereType<Map>()
          .map(
            (item) => ManualTranslationUnit.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(growable: false),
    );
  }
}

/// Header counts for one language, from the server totals (never the page).
@immutable
class ManualTranslationSummary {
  const ManualTranslationSummary({required this.total, required this.missing});

  /// Every canonical field for the language.
  final int total;

  /// Canonical fields with no translation yet.
  final int missing;

  /// Fields that already carry a translation.
  int get translated => missing > total ? 0 : total - missing;

  factory ManualTranslationSummary.fromPages({
    required ManualTranslationPage all,
    required ManualTranslationPage missing,
  }) {
    return ManualTranslationSummary(total: all.total, missing: missing.total);
  }
}

/// Immutable request key for the row page (so Riverpod does not refetch when
/// the widget rebuilds with the same filters).
@immutable
class ManualTranslationQuery {
  const ManualTranslationQuery({
    required this.lang,
    this.entityType,
    this.filter = ManualTranslationFilter.all,
    this.search = '',
    this.page = 0,
    this.size = 50,
  });

  final String lang;
  final String? entityType;
  final String filter;
  final String search;
  final int page;
  final int size;

  @override
  bool operator ==(Object other) =>
      other is ManualTranslationQuery &&
      other.lang == lang &&
      other.entityType == entityType &&
      other.filter == filter &&
      other.search == search &&
      other.page == page &&
      other.size == size;

  @override
  int get hashCode => Object.hash(lang, entityType, filter, search, page, size);
}

String _text(Object? value) => value == null ? '' : '$value';

String? _textOrNull(Object? value) {
  if (value == null) return null;
  final text = '$value'.trim();
  return text.isEmpty ? null : text;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

bool _flag(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}

List<dynamic> _list(Object? value) =>
    value is List<dynamic> ? value : const <dynamic>[];
