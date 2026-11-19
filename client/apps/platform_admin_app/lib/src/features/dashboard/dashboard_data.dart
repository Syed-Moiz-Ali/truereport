import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../platform_catalogue_models.dart';
import '../../platform_config_models.dart';
import 'dashboard_palette.dart';

/// Severity shown on the attention ledger and governance rail.
enum DashboardSeverity { critical, warning, info }

@immutable
class DashboardAttentionEntry {
  const DashboardAttentionEntry({
    required this.title,
    required this.severity,
    required this.route,
    required this.icon,
    this.meta = '',
    this.count,
  });

  final String title;
  final String meta;
  final int? count;
  final DashboardSeverity severity;
  final String route;
  final IconData icon;
}

@immutable
class DashboardActivityEntry {
  const DashboardActivityEntry({
    required this.title,
    required this.meta,
    required this.when,
  });

  final String title;
  final String meta;
  final String when;
}

@immutable
class DashboardRailSegment {
  const DashboardRailSegment({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

String dashboardLanguageStatusLabel(UiMessageStrings strings, String status) {
  switch (status.toUpperCase()) {
    case 'DRAFT':
      return strings.tKey(PlatformAdminKeys.statusLanguageDraft);
    case 'TRANSLATING':
      return strings.tKey(PlatformAdminKeys.statusLanguageTranslating);
    case 'REVIEW':
      return strings.tKey(PlatformAdminKeys.statusLanguageReview);
    case 'LIVE':
      return strings.tKey(PlatformAdminKeys.statusLanguageLive);
    case 'RETIRED':
      return strings.tKey(PlatformAdminKeys.statusLanguageRetired);
    default:
      return status;
  }
}

String dashboardLanguageDisplayName(PlatformLanguage language) {
  if (language.code.toLowerCase() == 'zh-hans') {
    return '中文 (ZH-HANS)';
  }
  final name = language.nativeName.isNotEmpty
      ? language.nativeName
      : language.code.toUpperCase();
  return name.isEmpty
      ? language.code.toUpperCase()
      : '$name (${language.code})';
}

UiMessageKey? _resolveAlertKey(String key) {
  switch (key) {
    case 'dashboard.alert.checklist.title':
      return PlatformAdminKeys.dashboardAlertChecklistTitle;
    case 'dashboard.alert.checklist.body':
      return PlatformAdminKeys.dashboardAlertChecklistBody;
    case 'dashboard.alert.languages.title':
      return PlatformAdminKeys.dashboardAlertLanguagesTitle;
    case 'dashboard.alert.languages.body':
      return PlatformAdminKeys.dashboardAlertLanguagesBody;
    case 'dashboard.alert.reportsFailed.title':
      return PlatformAdminKeys.dashboardAlertReportsFailedTitle;
    case 'dashboard.alert.reportsFailed.body':
      return PlatformAdminKeys.dashboardAlertReportsFailedBody;
    case 'dashboard.alert.reportsUnpublished.title':
      return PlatformAdminKeys.dashboardAlertReportsUnpublishedTitle;
    case 'dashboard.alert.reportsUnpublished.body':
      return PlatformAdminKeys.dashboardAlertReportsUnpublishedBody;
    default:
      return null;
  }
}

String _localizedAlert(
  UiMessageStrings strings,
  String raw,
  String key,
  Map<String, dynamic> args,
) {
  if (key.isEmpty) return raw;
  final resolved = _resolveAlertKey(key);
  if (resolved == null) return raw;
  return args.isEmpty
      ? strings.tKey(resolved)
      : strings.tArgsKey(resolved, args);
}

/// Turns an API code such as `MASTER_ITEM_PUBLISHED` into readable copy.
///
/// These values are data, not UI strings: no translation keys exist for them.
String humanizeCode(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final words = trimmed
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .toLowerCase()
      .split(' ')
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) return '';
  final first = words.first;
  return [
    '${first[0].toUpperCase()}${first.substring(1)}',
    ...words.skip(1),
  ].join(' ');
}

/// Order matters: governance risk first, then unapproved work, then setup.
List<DashboardAttentionEntry> buildAttentionEntries({
  required OverviewSummary summary,
  required UiMessageStrings strings,
  required ConfigHealth? health,
  required List<PlatformLanguage> languages,
}) {
  final entries = <DashboardAttentionEntry>[];

  if (health != null && !health.healthy) {
    final failing = health.checks.where((check) => !check.ok).toList();
    if (failing.isNotEmpty) {
      final count = failing.length;
      entries.add(
        DashboardAttentionEntry(
          title: strings.tArgsKey(
            PlatformAdminKeys.dashboardNeedsAttentionChecklistIssues,
            {'count': '$count'},
          ),
          meta: count == 1
              ? strings.tKey(PlatformAdminKeys.dashboardHealthSummarySingle)
              : strings.tArgsKey(
                  PlatformAdminKeys.dashboardHealthSummaryMultiple,
                  {'count': '$count'},
                ),
          count: count,
          severity: DashboardSeverity.critical,
          route: '/checklist/health',
          icon: Icons.report_gmailerrorred_outlined,
        ),
      );
    }
  }

  if (summary.jobs.pendingReview > 0) {
    entries.add(
      DashboardAttentionEntry(
        title: strings.tArgsKey(
          PlatformAdminKeys.dashboardNeedsAttentionPendingReviews,
          {'count': '${summary.jobs.pendingReview}'},
        ),
        count: summary.jobs.pendingReview,
        severity: DashboardSeverity.warning,
        route: '/audit-log',
        icon: Icons.rate_review_outlined,
      ),
    );
  }

  for (final language in languages.where((item) => item.isInSetup).take(2)) {
    entries.add(
      DashboardAttentionEntry(
        title: strings.tArgsKey(
          PlatformAdminKeys.dashboardNeedsAttentionLanguageInSetup,
          {
            'language': dashboardLanguageDisplayName(language),
            'status': dashboardLanguageStatusLabel(strings, language.status),
          },
        ),
        meta: strings.tKey(PlatformAdminKeys.sidebarLanguagesContinueSetup),
        count: 1,
        severity: DashboardSeverity.warning,
        route: '/settings/languages/${language.code}?tab=overview',
        icon: Icons.translate_rounded,
      ),
    );
  }

  for (final alert in summary.alerts.take(3)) {
    entries.add(
      DashboardAttentionEntry(
        title: _localizedAlert(
          strings,
          alert.title,
          alert.titleKey,
          alert.args,
        ),
        meta: _localizedAlert(strings, alert.body, alert.bodyKey, alert.args),
        count: int.tryParse('${alert.args['count']}'),
        severity: alert.severity.toUpperCase() == 'ERROR'
            ? DashboardSeverity.critical
            : DashboardSeverity.warning,
        route: alert.route,
        icon: alert.severity.toUpperCase() == 'ERROR'
            ? Icons.error_outline_rounded
            : Icons.warning_amber_rounded,
      ),
    );
  }

  return entries.take(5).toList(growable: false);
}

List<DashboardRailSegment> buildJobRail(OverviewSummary summary) {
  final segments = <DashboardRailSegment>[];
  var index = 0;
  for (final entry in summary.jobs.byStatus.entries) {
    if (entry.value <= 0) continue;
    final label = humanizeCode(entry.key);
    if (label.isEmpty) continue;
    final color = switch (index) {
      0 => const Color(0xFF5FD3A9),
      1 => const Color(0xFF9BE3C6),
      2 => const Color(0xFFF0B26A),
      _ => const Color(0xFFC9C6D4),
    };
    segments.add(
      DashboardRailSegment(label: label, count: entry.value, color: color),
    );
    index++;
  }
  return segments;
}

List<DashboardActivityEntry> buildActivityEntries({
  required OverviewSummary summary,
  required List<PlatformAuditEvent> auditEvents,
  required String localeName,
  DateTime? now,
}) {
  final entries = <DashboardActivityEntry>[];

  for (final item in summary.recentActivity.take(6)) {
    entries.add(
      DashboardActivityEntry(
        title: humanizeCode(item.action),
        meta: _activityMeta([
          humanizeCode(item.entityType),
          item.entityId,
          item.actor,
        ]),
        when: humanizeTimestamp(item.occurredAt, localeName, now: now),
      ),
    );
  }

  if (entries.isEmpty) {
    for (final event in auditEvents.take(6)) {
      entries.add(
        DashboardActivityEntry(
          title: humanizeCode(event.action),
          meta: _activityMeta([
            humanizeCode(event.entityType),
            event.entityId,
            humanizeCode(event.actorRole),
          ]),
          when: humanizeTimestamp(event.occurredAt, localeName, now: now),
        ),
      );
    }
  }

  return entries;
}

String _activityMeta(List<String> parts) =>
    parts.where((part) => part.trim().isNotEmpty).join(' · ');

/// `2026-11-19T10:04:00Z` → `Nov 19, 2026, 10:04 AM` in the active locale.
///
/// Today/yesterday words are deliberately avoided: no localized keys exist for
/// them, and an invented English phrase inside an Arabic UI is worse than a
/// localized absolute timestamp.
String humanizeTimestamp(String raw, String localeName, {DateTime? now}) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final local = parsed.toLocal();
  try {
    return DateFormat.yMMMd(localeName).add_jm().format(local);
  } catch (_) {
    try {
      return DateFormat.yMMMd().add_jm().format(local);
    } catch (_) {
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');
      return '${local.day}/${local.month}/${local.year} $hour:$minute';
    }
  }
}

/// Humanized stat values keep tabular figures at the widget layer; this only
/// guards against a missing locale.
const kDashboardMaxWidth = 1280.0;

/// Kept here so the palette and the copy live next to the data they describe.
Color severityColor(DashboardSeverity severity, DashboardPalette palette) {
  return switch (severity) {
    DashboardSeverity.critical => palette.bad,
    DashboardSeverity.warning => palette.warn,
    DashboardSeverity.info => palette.info,
  };
}

Color severitySoftColor(DashboardSeverity severity, DashboardPalette palette) {
  return switch (severity) {
    DashboardSeverity.critical => palette.badSoft,
    DashboardSeverity.warning => palette.warnSoft,
    DashboardSeverity.info => palette.infoSoft,
  };
}
