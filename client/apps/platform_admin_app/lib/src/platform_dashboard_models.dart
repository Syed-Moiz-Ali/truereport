import 'package:flutter/foundation.dart';

int _count(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? ''}') ?? 0;
}

String _text(dynamic value, [String fallback = '']) =>
    value == null ? fallback : value.toString();

Map<String, int> _countMap(dynamic value) {
  if (value is! Map) return const <String, int>{};
  return <String, int>{
    for (final entry in value.entries) _text(entry.key): _count(entry.value),
  };
}

List<Map<String, dynamic>> _rows(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value.whereType<Map<String, dynamic>>().toList(growable: false);
}

@immutable
class PlatformFlowDay {
  const PlatformFlowDay({
    required this.date,
    required this.created,
    required this.published,
  });

  final String date;
  final int created;
  final int published;

  DateTime? get day => DateTime.tryParse(date);

  factory PlatformFlowDay.fromJson(Map<String, dynamic> json) =>
      PlatformFlowDay(
        date: _text(json['date']),
        created: _count(json['created']),
        published: _count(json['published']),
      );
}

@immutable
class PlatformWorkshopLeader {
  const PlatformWorkshopLeader({
    required this.id,
    required this.name,
    required this.jobs,
  });

  final String id;
  final String name;
  final int jobs;

  factory PlatformWorkshopLeader.fromJson(Map<String, dynamic> json) =>
      PlatformWorkshopLeader(
        id: _text(json['id']),
        name: _text(json['name']),
        jobs: _count(json['jobs']),
      );
}

@immutable
class PlatformDashboardWorkshops {
  const PlatformDashboardWorkshops({
    required this.total,
    required this.active,
    required this.disabled,
    required this.createdInRange,
    required this.top,
  });

  final int total;
  final int active;
  final int disabled;
  final int createdInRange;
  final List<PlatformWorkshopLeader> top;

  factory PlatformDashboardWorkshops.fromJson(Map<String, dynamic> json) =>
      PlatformDashboardWorkshops(
        total: _count(json['total']),
        active: _count(json['active']),
        disabled: _count(json['disabled']),
        createdInRange: _count(json['createdInRange']),
        top: _rows(json['top'])
            .map(PlatformWorkshopLeader.fromJson)
            .toList(growable: false),
      );
}

@immutable
class PlatformDashboardStaff {
  const PlatformDashboardStaff({
    required this.admins,
    required this.technicians,
    required this.createdInRange,
  });

  final int admins;
  final int technicians;
  final int createdInRange;

  factory PlatformDashboardStaff.fromJson(Map<String, dynamic> json) =>
      PlatformDashboardStaff(
        admins: _count(json['admins']),
        technicians: _count(json['technicians']),
        createdInRange: _count(json['createdInRange']),
      );
}

@immutable
class PlatformDashboardJobs {
  const PlatformDashboardJobs({
    required this.total,
    required this.active,
    required this.pendingReview,
    required this.published,
    required this.publishedInRange,
    required this.byStatus,
  });

  final int total;
  final int active;
  final int pendingReview;
  final int published;
  final int publishedInRange;
  final Map<String, int> byStatus;

  factory PlatformDashboardJobs.fromJson(Map<String, dynamic> json) =>
      PlatformDashboardJobs(
        total: _count(json['total']),
        active: _count(json['active']),
        pendingReview: _count(json['pendingReview']),
        published: _count(json['published']),
        publishedInRange: _count(json['publishedInRange']),
        byStatus: _countMap(json['byStatus']),
      );
}

@immutable
class PlatformDashboardConfig {
  const PlatformDashboardConfig({
    required this.templates,
    required this.templateVersions,
    required this.categories,
    required this.items,
    required this.languagesLive,
    required this.languagesTranslating,
    required this.languagesReview,
    required this.languagesDraft,
  });

  final int templates;
  final int templateVersions;
  final int categories;
  final int items;
  final int languagesLive;
  final int languagesTranslating;
  final int languagesReview;
  final int languagesDraft;

  factory PlatformDashboardConfig.fromJson(Map<String, dynamic> json) =>
      PlatformDashboardConfig(
        templates: _count(json['templates']),
        templateVersions: _count(json['templateVersions']),
        categories: _count(json['categories']),
        items: _count(json['items']),
        languagesLive: _count(json['languagesLive']),
        languagesTranslating: _count(json['languagesTranslating']),
        languagesReview: _count(json['languagesReview']),
        languagesDraft: _count(json['languagesDraft']),
      );
}

@immutable
class PlatformDashboardReports {
  const PlatformDashboardReports({
    required this.versions,
    required this.published,
    required this.documents,
    required this.readyDocuments,
    required this.failedDocuments,
    required this.exportBytes,
    required this.activeLinks,
    required this.revokedLinks,
  });

  final int versions;
  final int published;
  final int documents;
  final int readyDocuments;
  final int failedDocuments;
  final int exportBytes;
  final int activeLinks;
  final int revokedLinks;

  factory PlatformDashboardReports.fromJson(Map<String, dynamic> json) =>
      PlatformDashboardReports(
        versions: _count(json['versions']),
        published: _count(json['published']),
        documents: _count(json['documents']),
        readyDocuments: _count(json['readyDocuments']),
        failedDocuments: _count(json['failedDocuments']),
        exportBytes: _count(json['exportBytes']),
        activeLinks: _count(json['activeLinks']),
        revokedLinks: _count(json['revokedLinks']),
      );
}

@immutable
class PlatformDashboardActivity {
  const PlatformDashboardActivity({
    required this.at,
    required this.actor,
    required this.action,
    required this.entityType,
    required this.entityId,
  });

  final String? at;
  final String? actor;
  final String action;
  final String entityType;
  final String entityId;

  DateTime? get occurredAt => at == null ? null : DateTime.tryParse(at!);

  factory PlatformDashboardActivity.fromJson(Map<String, dynamic> json) =>
      PlatformDashboardActivity(
        at: json['at']?.toString(),
        actor: json['actor']?.toString(),
        action: _text(json['action']),
        entityType: _text(json['entityType']),
        entityId: _text(json['entityId']),
      );
}

@immutable
class PlatformDashboard {
  const PlatformDashboard({
    required this.days,
    required this.generatedAt,
    required this.today,
    required this.trend,
    required this.workshops,
    required this.staff,
    required this.jobs,
    required this.config,
    required this.reports,
    required this.activity,
  });

  final int days;
  final String generatedAt;
  final PlatformFlowDay today;
  final List<PlatformFlowDay> trend;
  final PlatformDashboardWorkshops workshops;
  final PlatformDashboardStaff staff;
  final PlatformDashboardJobs jobs;
  final PlatformDashboardConfig config;
  final PlatformDashboardReports reports;
  final List<PlatformDashboardActivity> activity;

  factory PlatformDashboard.fromJson(Map<String, dynamic> json) =>
      PlatformDashboard(
        days: _count(json['days']),
        generatedAt: _text(json['generatedAt']),
        today: PlatformFlowDay.fromJson(
          (json['today'] as Map<String, dynamic>?) ?? const {},
        ),
        trend: _rows(json['trend'])
            .map(PlatformFlowDay.fromJson)
            .toList(growable: false),
        workshops: PlatformDashboardWorkshops.fromJson(
          (json['workshops'] as Map<String, dynamic>?) ?? const {},
        ),
        staff: PlatformDashboardStaff.fromJson(
          (json['staff'] as Map<String, dynamic>?) ?? const {},
        ),
        jobs: PlatformDashboardJobs.fromJson(
          (json['jobs'] as Map<String, dynamic>?) ?? const {},
        ),
        config: PlatformDashboardConfig.fromJson(
          (json['config'] as Map<String, dynamic>?) ?? const {},
        ),
        reports: PlatformDashboardReports.fromJson(
          (json['reports'] as Map<String, dynamic>?) ?? const {},
        ),
        activity: _rows(json['activity'])
            .map(PlatformDashboardActivity.fromJson)
            .toList(growable: false),
      );
}
