import 'package:flutter/foundation.dart';

String _s(dynamic value) => value == null ? '' : value.toString();
int _i(dynamic value) => value is num ? value.toInt() : 0;

@immutable
class PlatformCatalogueValue {
  const PlatformCatalogueValue({
    required this.id,
    required this.code,
    required this.status,
    required this.sortOrder,
    required this.labelEn,
    required this.labelAr,
  });

  final String id;
  final String code;
  final String status;
  final int sortOrder;
  final String labelEn;
  final String labelAr;

  factory PlatformCatalogueValue.fromJson(Map<String, dynamic> json) =>
      PlatformCatalogueValue(
        id: _s(json['id']),
        code: _s(json['code']),
        status: _s(json['status']),
        sortOrder: _i(json['sortOrder']),
        labelEn: _s(json['labelEn']),
        labelAr: _s(json['labelAr']),
      );
}

@immutable
class PlatformCatalogueEntry {
  const PlatformCatalogueEntry({
    required this.id,
    required this.code,
    required this.status,
    required this.sortOrder,
    required this.labelEn,
    required this.labelAr,
    required this.values,
  });

  final String id;
  final String code;
  final String status;
  final int sortOrder;
  final String labelEn;
  final String labelAr;
  final List<PlatformCatalogueValue> values;

  factory PlatformCatalogueEntry.fromJson(Map<String, dynamic> json) =>
      PlatformCatalogueEntry(
        id: _s(json['id']),
        code: _s(json['code']),
        status: _s(json['status']),
        sortOrder: _i(json['sortOrder']),
        labelEn: _s(json['labelEn']),
        labelAr: _s(json['labelAr']),
        values: (json['values'] as List<dynamic>? ?? const [])
            .map(
              (item) =>
                  PlatformCatalogueValue.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
      );
}

@immutable
class AuditEventPage {
  const AuditEventPage({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
  });

  final List<PlatformAuditEvent> items;
  final int total;
  final int page;
  final int size;

  factory AuditEventPage.fromJson(Map<String, dynamic> json) => AuditEventPage(
    items: (json['items'] as List<dynamic>? ?? const [])
        .map(
          (item) => PlatformAuditEvent.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false),
    total: _i(json['total']),
    page: _i(json['page']),
    size: _i(json['size']) == 0 ? 25 : _i(json['size']),
  );
}

@immutable
class PlatformAuditEvent {
  const PlatformAuditEvent({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.actorRole,
    required this.occurredAt,
    required this.reasonCode,
    required this.metadataJson,
  });

  final String id;
  final String action;
  final String entityType;
  final String entityId;
  final String actorRole;
  final String occurredAt;
  final String reasonCode;
  final String metadataJson;

  factory PlatformAuditEvent.fromJson(Map<String, dynamic> json) =>
      PlatformAuditEvent(
        id: _s(json['id']),
        action: _s(json['action']),
        entityType: _s(json['entityType']),
        entityId: _s(json['entityId']),
        actorRole: _s(json['actorRole']),
        occurredAt: _s(json['occurredAt']),
        reasonCode: _s(json['reasonCode']),
        metadataJson: _s(json['metadataJson']),
      );
}
