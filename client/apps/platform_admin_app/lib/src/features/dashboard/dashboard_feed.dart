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
    this.actionLabel = '',
  });

  final String title;
  final String meta;
  final DashboardSeverity severity;
  final String route;
  final IconData icon;

  /// Served action label for this alert; empty when the server supplied none.
  final String actionLabel;

  bool get canOpen => route.trim().isNotEmpty;
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

/// Resolves a served platform key with its string args.
///
/// Missing keys resolve to an empty string so the caller can omit the row
/// rather than render a qualified key.
String _servedCopy(
  UiMessageStrings strings,
  String key,
  Map<String, String> args,
) {
  if (key.isEmpty) return '';
  final template = strings.resolveFlatKey(key);
  if (template == null || template.trim().isEmpty) return '';
  var value = template;
  for (final entry in args.entries) {
    value = value.replaceAll('{${entry.key}}', entry.value);
  }
  return value;
}

DashboardSeverity _alertSeverity(String raw) {
  return switch (raw.toLowerCase()) {
    'danger' || 'critical' || 'error' => DashboardSeverity.critical,
    'info' => DashboardSeverity.info,
    _ => DashboardSeverity.warning,
  };
}

IconData _alertIcon(DashboardSeverity severity) {
  return switch (severity) {
    DashboardSeverity.critical => Icons.error_outline_rounded,
    DashboardSeverity.warning => Icons.warning_amber_rounded,
    DashboardSeverity.info => Icons.info_outline_rounded,
  };
}

/// Attention rows the backend has already evaluated.
///
/// Pending reviews are the one client-side operational row that the overview
/// still owns; everything else comes from `localizedAlerts` so the dashboard
/// never re-derives a health/language verdict locally.
List<DashboardAttention> buildDashboardAttention({
  required OverviewSummary summary,
  required UiMessageStrings strings,
}) {
  final entries = <DashboardAttention>[];

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

  for (final alert in summary.localizedAlerts) {
    final severity = _alertSeverity(alert.severity);
    final title = _servedCopy(strings, alert.titleKey, alert.args);
    if (title.isEmpty) continue;
    entries.add(
      DashboardAttention(
        title: title,
        meta: _servedCopy(strings, alert.bodyKey, alert.args),
        severity: severity,
        route: alert.actionRoute,
        icon: _alertIcon(severity),
        actionLabel: _servedCopy(strings, alert.actionLabelKey, const {}),
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
