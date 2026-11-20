import 'dart:convert';

/// One taxonomy record served by `/api/v1/reference/*`.
///
/// [labelKey] is a backend UI-message key. This package never resolves or
/// stores English; the app resolves it through the shared l10n bundle.
class ReferenceRecord {
  const ReferenceRecord({
    required this.code,
    required this.labelKey,
    this.tone = 'neutral',
    this.icon = '',
    this.order = 0,
    this.selectable = true,
    this.visibleFor = const <String>[],
    this.allowedNext = const <String>[],
    this.version = 0,
    this.status,
  });

  final String code;
  final String labelKey;
  final String tone;
  final String icon;
  final int order;
  final bool selectable;
  final List<String> visibleFor;
  final List<String> allowedNext;
  final int version;

  /// Lifecycle state (`DRAFT` / `PUBLISHED`) when the server sends it.
  ///
  /// Older reads omit it; callers must keep the published-vs-draft fallback.
  final String? status;

  factory ReferenceRecord.fromJson(Map<String, dynamic> json) {
    return ReferenceRecord(
      code: _string(json['code']),
      labelKey: _string(json['labelKey']),
      tone: _stringOr(json['tone'], 'neutral'),
      icon: _string(json['icon']),
      order: _int(json['order']),
      selectable: _bool(json['selectable'], fallback: true),
      visibleFor: _stringList(json['visibleFor']),
      allowedNext: _stringList(json['allowedNext']),
      version: _int(json['version']),
      status: _stringOrNull(json['status']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'labelKey': labelKey,
    'tone': tone,
    'icon': icon,
    'order': order,
    'selectable': selectable,
    'visibleFor': visibleFor,
    'allowedNext': allowedNext,
    'version': version,
    'status': ?status,
  };
}

/// One dropdown option served by `/api/v1/reference/dropdowns/*`.
class ReferenceValue {
  const ReferenceValue({
    required this.code,
    required this.labelKey,
    this.order = 0,
    this.selectable = true,
    this.parentCode,
    this.version = 0,
  });

  final String code;
  final String labelKey;
  final int order;
  final bool selectable;
  final String? parentCode;
  final int version;

  factory ReferenceValue.fromJson(Map<String, dynamic> json) {
    return ReferenceValue(
      code: _string(json['code']),
      labelKey: _string(json['labelKey']),
      order: _int(json['order']),
      selectable: _bool(json['selectable'], fallback: true),
      parentCode: _stringOrNull(json['parentCode']),
      version: _int(json['version']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'labelKey': labelKey,
    'order': order,
    'selectable': selectable,
    'parentCode': parentCode,
    'version': version,
  };
}

/// Allowed-next transitions for one entity.
class StatusTransitions {
  const StatusTransitions({
    required this.entity,
    this.current = '',
    this.allowedNext = const <String>[],
    this.records = const <ReferenceRecord>[],
  });

  final String entity;
  final String current;
  final List<String> allowedNext;

  /// Full records when the backend sends them; otherwise empty (the caller can
  /// resolve codes through `statusesProvider`).
  final List<ReferenceRecord> records;

  factory StatusTransitions.fromJson(Object? data, {required String entity}) {
    if (data is List) {
      final records = parseRecords(data);
      return StatusTransitions(
        entity: entity,
        allowedNext: records
            .map((record) => record.code)
            .toList(growable: false),
        records: records,
      );
    }
    final json = asMap(data);
    final current = _string(json['current']);
    final codes = <String>[];
    final records = <ReferenceRecord>[];
    final rawNext = json['allowedNext'];
    if (rawNext is List) {
      for (final item in rawNext) {
        if (item is String) {
          codes.add(item);
        } else if (item is Map) {
          final record = ReferenceRecord.fromJson(asMap(item));
          records.add(record);
          codes.add(record.code);
        }
      }
    }
    final extra = json['records'];
    if (extra is List) {
      for (final record in parseRecords(extra)) {
        if (!records.any((item) => item.code == record.code)) {
          records.add(record);
        }
      }
    }
    return StatusTransitions(
      entity: _stringOr(json['entity'], entity),
      current: current,
      allowedNext: codes,
      records: records,
    );
  }
}

/// Tolerant record list: accepts a bare list or a wrapper object.
List<ReferenceRecord> parseRecords(Object? data) {
  final list = _listPayload(data);
  final records = <ReferenceRecord>[];
  for (final item in list) {
    if (item is Map) {
      final record = ReferenceRecord.fromJson(asMap(item));
      if (record.code.isNotEmpty) records.add(record);
    }
  }
  records.sort((a, b) {
    final byOrder = a.order.compareTo(b.order);
    return byOrder != 0 ? byOrder : a.code.compareTo(b.code);
  });
  return records;
}

/// Codes that are drafts.
///
/// New servers send `status` on every read, so it wins when present. Older
/// servers omit it: the platform read then returns PUBLISHED+DRAFT while the
/// client read returns PUBLISHED only, and the difference is the draft set.
Set<String> draftCodes(
  List<ReferenceRecord> withDrafts,
  List<ReferenceRecord> published,
) {
  final live = <String>{for (final record in published) record.code};
  return <String>{
    for (final record in withDrafts)
      if (record.status != null && record.status!.isNotEmpty
          ? record.status!.toUpperCase() == 'DRAFT'
          : !live.contains(record.code))
        record.code,
  };
}

/// Tolerant dropdown list: accepts a bare list or a wrapper object.
List<ReferenceValue> parseValues(Object? data) {
  final list = _listPayload(data);
  final values = <ReferenceValue>[];
  for (final item in list) {
    if (item is Map) {
      final value = ReferenceValue.fromJson(asMap(item));
      if (value.code.isNotEmpty) values.add(value);
    }
  }
  values.sort((a, b) {
    final byOrder = a.order.compareTo(b.order);
    return byOrder != 0 ? byOrder : a.code.compareTo(b.code);
  });
  return values;
}

List<dynamic> _listPayload(Object? data) {
  if (data is List) return data;
  if (data is Map) {
    for (final key in const <String>['items', 'records', 'values', 'data']) {
      final value = data[key];
      if (value is List) return value;
    }
  }
  return const <dynamic>[];
}

Map<String, dynamic> asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

String _string(Object? value) => value is String ? value : '';

String _stringOr(Object? value, String fallback) =>
    value is String && value.isNotEmpty ? value : fallback;

String? _stringOrNull(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

List<String> _stringList(Object? value) => value is List
    ? value.whereType<String>().toList(growable: false)
    : const <String>[];

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

bool _bool(Object? value, {required bool fallback}) =>
    value is bool ? value : fallback;

/// Encodes a raw payload for the persistent cache.
String encodeCacheEntry(String? etag, Object? data) =>
    jsonEncode(<String, dynamic>{'etag': etag, 'data': data});

/// Decodes a persistent cache entry. Returns null when the payload is invalid.
({String? etag, Object? data})? decodeCacheEntry(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map || !decoded.containsKey('data')) return null;
    return (etag: decoded['etag'] as String?, data: decoded['data']);
  } catch (_) {
    return null;
  }
}

/// One edge in the transition table.
class ReferenceTransition {
  const ReferenceTransition({
    required this.fromCode,
    required this.toCode,
    required this.role,
    this.guard = const <String, Object?>{},
    this.version = 0,
  });

  final String fromCode;
  final String toCode;
  final String role;
  final Map<String, Object?> guard;
  final int version;

  factory ReferenceTransition.fromJson(Map<String, dynamic> json) {
    return ReferenceTransition(
      fromCode: _string(json['fromCode']),
      toCode: _string(json['toCode']),
      role: _string(json['role']),
      guard: json['guard'] is Map
          ? Map<String, Object?>.from(json['guard'] as Map)
          : const <String, Object?>{},
      version: _int(json['version']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'fromCode': fromCode,
    'toCode': toCode,
    'role': role,
    'guard': guard,
  };
}

/// In-use counts returned by `/{domain}/{key}/impact`.
class ReferenceImpact {
  const ReferenceImpact({
    this.items = 0,
    this.jobs = 0,
    this.templates = 0,
    this.documents = 0,
  });

  final int items;
  final int jobs;
  final int templates;
  final int documents;

  bool get isEmpty =>
      items == 0 && jobs == 0 && templates == 0 && documents == 0;

  factory ReferenceImpact.fromJson(Map<String, dynamic> json) =>
      ReferenceImpact(
        items: _int(json['items']),
        jobs: _int(json['jobs']),
        templates: _int(json['templates']),
        documents: _int(json['documents']),
      );
}

/// Body for creating/updating a reference record.
class ReferenceWrite {
  const ReferenceWrite({
    required this.code,
    required this.labelKey,
    this.tone = 'neutral',
    this.icon = 'circle',
    this.order = 0,
    this.selectable = true,
    this.visibleFor = const <String>['workshop_admin', 'technician'],
    this.allowedNext = const <String>[],
  });

  final String code;
  final String labelKey;
  final String tone;
  final String icon;
  final int order;
  final bool selectable;
  final List<String> visibleFor;
  final List<String> allowedNext;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'labelKey': labelKey,
    'tone': tone,
    'icon': icon,
    'order': order,
    'selectable': selectable,
    'visibleFor': visibleFor,
    'allowedNext': allowedNext,
  };
}

/// Parses transition rules from `/reference/transitions/{entity}`.
List<ReferenceTransition> parseTransitions(Object? data) {
  final list = _listPayload(data);
  final result = <ReferenceTransition>[];
  for (final item in list) {
    if (item is Map) {
      final transition = ReferenceTransition.fromJson(asMap(item));
      if (transition.fromCode.isNotEmpty && transition.toCode.isNotEmpty) {
        result.add(transition);
      }
    }
  }
  return result;
}
