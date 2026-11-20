import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../platform_catalogue_models.dart';
import '../../platform_config_models.dart';

enum DashboardSeverity { critical, warning, info }

@immutable
class DashboardAttention {
  const DashboardAttention({
    required this.title,
    required this.meta,
    required this.severity,
    required this.route,
    required this.icon,
  });

  final String title;
  final String meta;
  final DashboardSeverity severity;
  final String route;
  final IconData icon;
}

@immutable
class DashboardActivity {
  const DashboardActivity({
    required this.title,
    required this.meta,
    required this.when,
  });

  final String title;
  final String meta;
  final String when;
}

/// Turns API codes such as `MASTER_ITEM_PUBLISHED` into readable copy.
/// These are data values, not UI strings.
String humanizeCode(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final words = trimmed
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .toLowerCase()
      .split(' ')
      .where((word) => word.isNotEmpty);
  if (words.isEmpty) return '';
  final list = words.toList(growable: false);
  final first = list.first;
  return [
    '${first[0].toUpperCase()}${first.substring(1)}',
    ...list.skip(1),
  ].join(' ');
}

String languageDisplayName(PlatformLanguage language) {
  final name = language.nativeName.isNotEmpty
      ? language.nativeName
      : language.code.toUpperCase();
  if (name.isEmpty) return language.code.toUpperCase();
  return '$name (${language.code})';
}

String languageStatusLabel(UiMessageStrings strings, String status) {
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

UiMessageKey? _alertKey(String key) {
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

String _alertCopy(
  UiMessageStrings strings,
  String raw,
  String key,
  Map<String, dynamic> args,
) {
  if (key.isEmpty) return raw;
  final resolved = _alertKey(key);
  if (resolved == null) return raw;
  return args.isEmpty
      ? strings.tKey(resolved)
      : strings.tArgsKey(resolved, args);
}

/// Same rules as the previous dashboard: governance first, then unapproved
/// work, then setup. Only rows backed by real data are produced.
List<DashboardAttention> buildDashboardAttention({
  required OverviewSummary summary,
  required UiMessageStrings strings,
  required ConfigHealth? health,
  required List<PlatformLanguage> languages,
}) {
  final entries = <DashboardAttention>[];

  if (health != null && !health.healthy) {
    final failing = health.checks.where((check) => !check.ok).toList();
    if (failing.isNotEmpty) {
      final count = failing.length;
      entries.add(
        DashboardAttention(
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
          severity: DashboardSeverity.critical,
          route: '/checklist/health',
          icon: Icons.report_gmailerrorred_outlined,
        ),
      );
    }
  }

  if (summary.jobs.pendingReview > 0) {
    entries.add(
      DashboardAttention(
        title: strings.tArgsKey(
          PlatformAdminKeys.dashboardNeedsAttentionPendingReviews,
          {'count': '${summary.jobs.pendingReview}'},
        ),
        meta: strings.tKey(PlatformAdminKeys.sectionDashboardAlerts),
        severity: DashboardSeverity.warning,
        route: '/audit-log',
        icon: Icons.rate_review_outlined,
      ),
    );
  }

  for (final language in languages.where((item) => item.isInSetup).take(2)) {
    entries.add(
      DashboardAttention(
        title: strings.tArgsKey(
          PlatformAdminKeys.dashboardNeedsAttentionLanguageInSetup,
          {
            'language': languageDisplayName(language),
            'status': languageStatusLabel(strings, language.status),
          },
        ),
        meta: strings.tKey(PlatformAdminKeys.pageLanguagesTitle),
        severity: DashboardSeverity.info,
        route: '/settings/languages/${language.code}?tab=overview',
        icon: Icons.translate_rounded,
      ),
    );
  }

  for (final alert in summary.alerts.take(3)) {
    entries.add(
      DashboardAttention(
        title: _alertCopy(strings, alert.title, alert.titleKey, alert.args),
        meta: _alertCopy(strings, alert.body, alert.bodyKey, alert.args),
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

List<DashboardActivity> buildDashboardActivity({
  required OverviewSummary summary,
  required List<PlatformAuditEvent> auditEvents,
  required String localeName,
}) {
  final entries = <DashboardActivity>[];

  for (final item in summary.recentActivity.take(6)) {
    entries.add(
      DashboardActivity(
        title: humanizeCode(item.action),
        meta: _activityMeta([
          humanizeCode(item.entityType),
          item.entityId,
          item.actor,
        ]),
        when: humanizeTimestamp(item.occurredAt, localeName),
      ),
    );
  }

  if (entries.isEmpty) {
    for (final event in auditEvents.take(6)) {
      entries.add(
        DashboardActivity(
          title: humanizeCode(event.action),
          meta: _activityMeta([
            humanizeCode(event.entityType),
            event.entityId,
            humanizeCode(event.actorRole),
          ]),
          when: humanizeTimestamp(event.occurredAt, localeName),
        ),
      );
    }
  }

  return entries;
}

String _activityMeta(List<String> parts) =>
    parts.where((part) => part.trim().isNotEmpty).join(' · ');

/// Locale-aware absolute timestamp. No invented relative words.
String humanizeTimestamp(String raw, String localeName) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final local = parsed.toLocal();
  final locale = localeName.trim().isEmpty ? 'en' : localeName.trim();
  try {
    return DateFormat.yMMMd(locale).add_jm().format(local);
  } catch (_) {
    try {
      return DateFormat.yMMMd().add_jm().format(local);
    } catch (_) {
      return raw;
    }
  }
}
