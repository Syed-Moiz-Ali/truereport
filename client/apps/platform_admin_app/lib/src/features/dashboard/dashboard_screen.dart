import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_form.dart';
import '../../components/platform_shell.dart';
import '../../components/platform_states.dart';
import '../languages/language_workspace_screen.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

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

String _languageStatusLabel(UiMessageStrings strings, String status) {
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

String _formatLanguageDisplayName(PlatformLanguage lang) {
  if (lang.code.toLowerCase() == 'zh-hans') {
    return '中文 (ZH-HANS)';
  }
  final name = lang.nativeName.isNotEmpty ? lang.nativeName : lang.displayName;
  return name.isNotEmpty
      ? '$name (${lang.code.toUpperCase()})'
      : lang.code.toUpperCase();
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final overview = ref.watch(overviewProvider);

    return PlatformShell(
      currentRoute: '/dashboard',
      showSearch: false,
      onNavigate: (route) => context.go(route),
      child: PlatformPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Page Header (compact, with refresh and operational summary)
            PlatformPageHeader(
              title: strings.tKey(PlatformAdminKeys.pageDashboardTitle),
              subtitle: strings.tKey(PlatformAdminKeys.pageDashboardSubtitle),
              actions: [
                PlatformSecondaryButton(
                  key: const Key('btn-dashboard-refresh'),
                  label: strings.tKey(CommonKeys.buttonRefresh),
                  icon: Icons.refresh_rounded,
                  onPressed: () {
                    ref.invalidate(overviewProvider);
                    ref.invalidate(configHealthProvider);
                    ref.invalidate(platformLanguagesProvider);
                    ref.invalidate(auditEventsProvider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            overview.when(
              loading: () => PlatformLoadingView(
                message: strings.tKey(CommonKeys.stateLoading),
              ),
              error: (error, stackTrace) => PlatformErrorView(
                message: strings.tKey(CommonKeys.statusUnhealthy),
                retryLabel: strings.tKey(CommonKeys.buttonRetry),
                onRetry: () {
                  ref.invalidate(overviewProvider);
                  ref.invalidate(configHealthProvider);
                  ref.invalidate(platformLanguagesProvider);
                  ref.invalidate(auditEventsProvider);
                },
              ),
              data: (summary) => _DashboardContent(summary: summary),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.summary});

  final OverviewSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    if (summary.isEmpty) {
      return PlatformEmptyView(
        icon: Icons.dashboard_outlined,
        title: strings.tKey(PlatformAdminKeys.emptyDashboardTitle),
        actionLabel: strings.tKey(PlatformAdminKeys.pageWorkshopsRegister),
        onAction: () => context.go('/workshops'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 2. Operational Status / Welcome Strip
        _OperationalStatusStrip(summary: summary),
        const SizedBox(height: 20),

        // 3. Primary KPI Grid & Secondary Metrics
        _KpiSection(summary: summary),
        const SizedBox(height: 24),

        // 4. Needs Attention Section
        _NeedsAttentionSection(summary: summary),
        const SizedBox(height: 24),

        // 5. Language Setup Action Center
        const _LanguageSetupActionCenter(),
        const SizedBox(height: 24),

        // 6. Operations Snapshot
        if (summary.jobs.byStatus.isNotEmpty ||
            summary.reports.byMonth.isNotEmpty) ...[
          _OperationsSnapshotSection(summary: summary),
          const SizedBox(height: 24),
        ],

        // 7. Recent Activity
        _RecentActivitySection(summary: summary),
        const SizedBox(height: 24),

        // 8. Quick Actions
        const _QuickActionsSection(),
      ],
    );
  }
}

// =============================================================================
// 2. Operational Status / Welcome Strip
// =============================================================================

class _OperationalStatusStrip extends ConsumerWidget {
  const _OperationalStatusStrip({required this.summary});

  final OverviewSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final health = ref.watch(configHealthProvider).asData?.value;
    final languages = ref.watch(platformLanguagesProvider).asData?.value ?? [];

    final hasChecklistIssue = health != null && !health.healthy;
    final incompleteLangs = languages.where((l) => l.isInSetup).length;
    final alertCount = summary.alerts.length;
    final pendingReviews = summary.jobs.pendingReview;

    final totalAttentionItems = (hasChecklistIssue ? 1 : 0) +
        incompleteLangs +
        alertCount +
        (pendingReviews > 0 ? 1 : 0);

    final isHealthy = totalAttentionItems == 0;

    final bgColor = isHealthy ? PtTheme.canvas : const Color(0xFFFFFBEB);
    final borderColor = isHealthy
        ? PtTheme.border
        : PtTheme.amber.withValues(alpha: 0.35);
    final indicatorColor = isHealthy ? PtTheme.emerald : PtTheme.amber;
    final title = strings.tKey(
      isHealthy
          ? PlatformAdminKeys.dashboardStatusHealthy
          : PlatformAdminKeys.dashboardStatusAttention,
    );
    final subtitle = isHealthy
        ? strings.tKey(PlatformAdminKeys.dashboardStatusHealthySubtitle)
        : strings.tArgsKey(
            PlatformAdminKeys.dashboardStatusAttentionSubtitle,
            {'count': '$totalAttentionItems'},
          );

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 640;
          final statusInfo = Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: PtTheme.font(
                        15,
                        lineHeight: 20,
                        weight: FontWeight.w700,
                        color: PtTheme.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: PtTheme.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );

          final cta = PlatformSecondaryButton(
            key: const Key('btn-status-strip-action'),
            label: isHealthy
                ? strings.tKey(PlatformAdminKeys.pageHealthTitle)
                : strings.tKey(PlatformAdminKeys.buttonHealthReview),
            icon: isHealthy
                ? Icons.health_and_safety_outlined
                : Icons.warning_amber_rounded,
            onPressed: () => context.go('/checklist/health'),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                statusInfo,
                const SizedBox(height: 12),
                cta,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: statusInfo),
              const SizedBox(width: 16),
              cta,
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// 3. Primary KPI Grid & Secondary Compact Metric Strip
// =============================================================================

@immutable
class _KpiMetric {
  const _KpiMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.route,
    required this.accent,
  });

  final String value;
  final String label;
  final IconData icon;
  final String route;
  final Color accent;
}

class _KpiSection extends ConsumerWidget {
  const _KpiSection({required this.summary});

  final OverviewSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);

    final primaryCards = [
      _KpiMetric(
        value: '${summary.workshops.active}',
        label: strings.tKey(PlatformAdminKeys.kpiWorkshopsActive),
        icon: Icons.storefront_rounded,
        route: '/workshops',
        accent: PtTheme.deepGreen,
      ),
      _KpiMetric(
        value: strings.tArgsKey(PlatformAdminKeys.dashboardKpiJobsActiveCount, {
          'count': '${summary.jobs.active}',
        }),
        label: strings.tKey(PlatformAdminKeys.kpiJobsActive),
        icon: Icons.assignment_rounded,
        route: '/audit-log',
        accent: const Color(0xFF1D4ED8),
      ),
      _KpiMetric(
        value: strings.tArgsKey(PlatformAdminKeys.dashboardKpiReviewsPendingCount, {
          'count': '${summary.jobs.pendingReview}',
        }),
        label: strings.tKey(PlatformAdminKeys.kpiReviewsPending),
        icon: Icons.rate_review_rounded,
        route: '/audit-log',
        accent: PtTheme.amber,
      ),
      _KpiMetric(
        value: strings.tArgsKey(PlatformAdminKeys.dashboardKpiReportsPublishedCount, {
          'count': '${summary.reports.published}',
        }),
        label: strings.tKey(PlatformAdminKeys.kpiReportsPublished),
        icon: Icons.description_rounded,
        route: '/reports/document-types',
        accent: const Color(0xFF0E7490),
      ),
    ];

    final secondaryPills = [
      _KpiMetric(
        value: '${summary.workshops.total}',
        label: strings.tKey(PlatformAdminKeys.kpiWorkshopsTotal),
        icon: Icons.business_rounded,
        route: '/workshops',
        accent: PtTheme.deepGreen,
      ),
      _KpiMetric(
        value: '${summary.staff.technicians}',
        label: strings.tKey(PlatformAdminKeys.kpiTechnicians),
        icon: Icons.engineering_rounded,
        route: '/workshops',
        accent: const Color(0xFF1D4ED8),
      ),
      _KpiMetric(
        value: summary.checklist.healthy
            ? strings.tKey(CommonKeys.statusHealthy)
            : strings.tArgsKey(
                PlatformAdminKeys.dashboardKpiChecklistIssuesCount,
                {'count': '${summary.checklist.issues}'},
              ),
        label: strings.tKey(PlatformAdminKeys.kpiChecklistHealth),
        icon: Icons.health_and_safety_rounded,
        route: '/checklist/health',
        accent: summary.checklist.healthy ? PtTheme.deepGreen : PtTheme.rose,
      ),
      _KpiMetric(
        value: summary.languages.translating > 0
            ? strings.tArgsKey(
                PlatformAdminKeys.dashboardKpiLanguagesLiveWithSetup,
                {
                  'liveCount': '${summary.languages.live}',
                  'setupCount': '${summary.languages.translating}',
                },
              )
            : strings.tArgsKey(
                PlatformAdminKeys.dashboardKpiLanguagesLiveCount,
                {'count': '${summary.languages.live}'},
              ),
        label: strings.tKey(PlatformAdminKeys.kpiLanguagesLive),
        icon: Icons.translate_rounded,
        route: '/settings/languages',
        accent: const Color(0xFF4338CA),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlatformSectionHeader(
          title: strings.tKey(PlatformAdminKeys.sectionDashboardKpis),
        ),
        const SizedBox(height: 12),
        // Primary 4 Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final columns = maxWidth >= 1000
                ? 4
                : maxWidth >= 600
                    ? 2
                    : 1;
            const spacing = 12.0;
            final cardWidth = (maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final item in primaryCards)
                  SizedBox(
                    width: cardWidth,
                    child: _PrimaryKpiCard(metric: item),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        // Secondary Compact Metrics Strip
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final columns = maxWidth >= 1000
                ? 4
                : maxWidth >= 600
                    ? 2
                    : 1;
            const spacing = 12.0;
            final pillWidth = (maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final item in secondaryPills)
                  SizedBox(
                    width: pillWidth,
                    child: _SecondaryMetricPill(metric: item),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PrimaryKpiCard extends StatelessWidget {
  const _PrimaryKpiCard({required this.metric});

  final _KpiMetric metric;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: metric.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go(metric.route),
          child: PlatformSectionCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: metric.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(metric.icon, size: 20, color: metric.accent),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: PtTheme.muted.withValues(alpha: 0.7),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  metric.value,
                  style: PtTheme.font(
                    26,
                    lineHeight: 32,
                    weight: FontWeight.w800,
                    color: PtTheme.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  metric.label,
                  style: PtTheme.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryMetricPill extends StatelessWidget {
  const _SecondaryMetricPill({required this.metric});

  final _KpiMetric metric;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: metric.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go(metric.route),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: PtTheme.canvas,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: PtTheme.border),
            ),
            child: Row(
              children: [
                Icon(metric.icon, size: 16, color: metric.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    metric.label,
                    style: PtTheme.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    metric.value,
                    style: PtTheme.font(
                      13,
                      lineHeight: 18,
                      weight: FontWeight.w700,
                      color: PtTheme.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 4. Needs Attention Section
// =============================================================================

@immutable
class _AttentionItem {
  const _AttentionItem({
    required this.title,
    required this.description,
    required this.route,
    required this.priority,
    required this.severity,
  });

  final String title;
  final String description;
  final String route;
  final int priority; // 1 = highest
  final String severity;
}

class _NeedsAttentionSection extends ConsumerWidget {
  const _NeedsAttentionSection({required this.summary});

  final OverviewSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final items = <_AttentionItem>[];

    // 1. Config health issues (Highest priority)
    final health = ref.watch(configHealthProvider).asData?.value;
    if (health != null && !health.healthy) {
      final failing = health.checks.where((c) => !c.ok).toList();
      final summaryText = failing.length == 1
          ? strings.tKey(PlatformAdminKeys.dashboardHealthSummarySingle)
          : strings.tArgsKey(
              PlatformAdminKeys.dashboardHealthSummaryMultiple,
              {'count': '${failing.length}'},
            );
      items.add(
        _AttentionItem(
          title: strings.tArgsKey(
            PlatformAdminKeys.dashboardNeedsAttentionChecklistIssues,
            {'count': '${failing.length}'},
          ),
          description: summaryText,
          route: '/checklist/health',
          priority: 1,
          severity: 'ERROR',
        ),
      );
    }

    // 2. Pending reviews
    if (summary.jobs.pendingReview > 0) {
      items.add(
        _AttentionItem(
          title: strings.tArgsKey(
            PlatformAdminKeys.dashboardNeedsAttentionPendingReviews,
            {'count': '${summary.jobs.pendingReview}'},
          ),
          description: strings.tKey(PlatformAdminKeys.kpiReviewsPending),
          route: '/audit-log',
          priority: 2,
          severity: 'WARNING',
        ),
      );
    }

    // 3. Languages in setup
    final languages = ref.watch(platformLanguagesProvider).asData?.value ?? [];
    for (final lang in languages) {
      if (lang.isInSetup) {
        final langName = _formatLanguageDisplayName(lang);
        final localizedStatus = _languageStatusLabel(strings, lang.status);
        items.add(
          _AttentionItem(
            title: strings.tArgsKey(
              PlatformAdminKeys.dashboardNeedsAttentionLanguageInSetup,
              {'language': langName, 'status': localizedStatus},
            ),
            description: strings.tKey(PlatformAdminKeys.sidebarLanguagesContinueSetup),
            route: '/settings/languages/${lang.code}?tab=overview',
            priority: 3,
            severity: 'WARNING',
          ),
        );
      }
    }

    // 4. Overview alerts
    for (final alert in summary.alerts) {
      String alertTitle = alert.title;
      String alertBody = alert.body;
      if (alert.titleKey.isNotEmpty) {
        final resolvedKey = _resolveAlertKey(alert.titleKey);
        if (resolvedKey != null) {
          alertTitle = alert.args.isNotEmpty
              ? strings.tArgsKey(resolvedKey, alert.args)
              : strings.tKey(resolvedKey);
        }
      }
      if (alert.bodyKey.isNotEmpty) {
        final resolvedKey = _resolveAlertKey(alert.bodyKey);
        if (resolvedKey != null) {
          alertBody = alert.args.isNotEmpty
              ? strings.tArgsKey(resolvedKey, alert.args)
              : strings.tKey(resolvedKey);
        }
      }

      items.add(
        _AttentionItem(
          title: alertTitle,
          description: alertBody,
          route: alert.route,
          priority: 4,
          severity: alert.severity,
        ),
      );
    }

    // Sort by priority (ascending)
    items.sort((a, b) => a.priority.compareTo(b.priority));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlatformSectionHeader(
          title: strings.tKey(PlatformAdminKeys.dashboardNeedsAttentionTitle),
          action: items.isNotEmpty
              ? TextButton(
                  key: const Key('btn-attention-view-all'),
                  onPressed: () => context.go(items.first.route),
                  child: Text(
                    strings.tKey(PlatformAdminKeys.buttonViewAll),
                    style: PtTheme.font(
                      13,
                      lineHeight: 18,
                      weight: FontWeight.w700,
                      color: PtTheme.deepGreen,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          PlatformSectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: PtTheme.emerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: PtTheme.deepGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    strings.tKey(PlatformAdminKeys.dashboardNeedsAttentionEmpty),
                    style: PtTheme.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )
        else
          PlatformSectionCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in items.take(4))
                  _AttentionRow(item: item),
              ],
            ),
          ),
      ],
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.item});

  final _AttentionItem item;

  @override
  Widget build(BuildContext context) {
    final isError = item.severity.toUpperCase() == 'ERROR';
    final color = isError ? PtTheme.rose : PtTheme.amber;
    final icon = isError ? Icons.error_outline_rounded : Icons.warning_amber_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: item.route.isNotEmpty ? () => context.go(item.route) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: PtTheme.font(
                          13,
                          lineHeight: 18,
                          weight: FontWeight.w700,
                          color: PtTheme.ink,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          style: PtTheme.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (item.route.isNotEmpty)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8, top: 4),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: PtTheme.muted.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 5. Language Setup Action Center
// =============================================================================

class _LanguageSetupActionCenter extends ConsumerWidget {
  const _LanguageSetupActionCenter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final languagesAsync = ref.watch(platformLanguagesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlatformSectionHeader(
          title: strings.tKey(PlatformAdminKeys.dashboardActionCenterTitle),
          action: TextButton(
            key: const Key('btn-action-center-view-all'),
            onPressed: () => context.go('/settings/languages'),
            child: Text(
              strings.tKey(PlatformAdminKeys.sidebarLanguagesViewAll),
              style: PtTheme.font(
                13,
                lineHeight: 18,
                weight: FontWeight.w700,
                color: PtTheme.deepGreen,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        languagesAsync.when(
          data: (languages) {
            final candidates = languages.where((l) => l.isInSetup).toList();
            if (candidates.isEmpty) {
              return PlatformSectionCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: PtTheme.emerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                        color: PtTheme.deepGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        strings.tKey(PlatformAdminKeys.dashboardActionCenterAllLive),
                        style: PtTheme.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }

            return _PrioritizedLanguageCards(candidates: candidates);
          },
          loading: () => const PlatformLoadingView(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _PrioritizedLanguageCards extends ConsumerWidget {
  const _PrioritizedLanguageCards({required this.candidates});

  final List<PlatformLanguage> candidates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Score each candidate by urgency
    final scored = <MapEntry<PlatformLanguage, int>>[];

    for (final lang in candidates) {
      final readiness = ref.watch(readinessProvider(lang.code)).asData?.value;
      final genData = ref.watch(contentGenerationProvider(lang.code)).asData?.value;
      final isGenerating = genData?.isRunning ?? false;

      int score = 6;
      if (readiness != null) {
        if (readiness.status == 'REVIEW' && readiness.blockers.isEmpty) {
          score = 1;
        } else if (readiness.readinessPercent == 100 && readiness.status != 'LIVE') {
          score = 2;
        } else if (lang.status == 'TRANSLATING' || isGenerating) {
          score = 3;
        } else if (lang.status == 'DRAFT' && readiness.uiMessagesPath.isNotEmpty && readiness.readinessPercent < 100) {
          score = 4;
        } else if (lang.status == 'DRAFT' && readiness.uiMessagesPath.isEmpty) {
          score = 5;
        } else {
          score = 6;
        }
      } else {
        if (lang.status == 'REVIEW') {
          score = 1;
        } else if (lang.status == 'TRANSLATING' || isGenerating) {
          score = 3;
        } else if (lang.status == 'DRAFT') {
          score = 5;
        }
      }
      scored.add(MapEntry(lang, score));
    }

    scored.sort((a, b) => a.value.compareTo(b.value));

    final topLanguages = scored.take(3).map((e) => e.key).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth >= 960
            ? topLanguages.length.clamp(1, 3)
            : maxWidth >= 600
                ? 2
                : 1;
        const spacing = 12.0;
        final cardWidth = (maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final lang in topLanguages)
              SizedBox(
                width: cardWidth,
                child: _ActionCenterLanguageCard(language: lang),
              ),
          ],
        );
      },
    );
  }
}

class _ActionCenterLanguageCard extends ConsumerWidget {
  const _ActionCenterLanguageCard({required this.language});

  final PlatformLanguage language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final readinessAsync = ref.watch(readinessProvider(language.code));
    final genAsync = ref.watch(contentGenerationProvider(language.code));

    final genData = genAsync.asData?.value;
    final isGenerating = genData?.isRunning ?? false;
    final genProgress = ((genData?.progress ?? 0) * 100).round();

    final readiness = readinessAsync.asData?.value;

    String targetTab = LanguageWorkspaceTab.overview;
    UiMessageKey actionKey = PlatformAdminKeys.sidebarLanguagesActionView;

    if (readiness != null) {
      if (isGenerating) {
        targetTab = LanguageWorkspaceTab.overview;
      } else if (readiness.blockers.isNotEmpty) {
        final firstBlocker = readiness.blockers.first;
        targetTab = firstBlocker.tab;
        if (firstBlocker.tab == LanguageWorkspaceTab.uiText) {
          actionKey = PlatformAdminKeys.sidebarLanguagesActionGenerate;
        } else if (firstBlocker.tab == LanguageWorkspaceTab.publish) {
          actionKey = PlatformAdminKeys.sidebarLanguagesActionPublish;
        } else {
          actionKey = readiness.status == 'REVIEW'
              ? PlatformAdminKeys.sidebarLanguagesActionReview
              : PlatformAdminKeys.sidebarLanguagesActionGenerate;
        }
      } else if (readiness.status == 'DRAFT') {
        if (readiness.uiMessagesPath.isEmpty) {
          targetTab = LanguageWorkspaceTab.uiText;
          actionKey = PlatformAdminKeys.sidebarLanguagesActionGenerate;
        } else if (readiness.readinessPercent < 100) {
          targetTab = LanguageWorkspaceTab.categories;
          actionKey = PlatformAdminKeys.sidebarLanguagesActionGenerateMissing;
        } else {
          targetTab = LanguageWorkspaceTab.publish;
          actionKey = PlatformAdminKeys.sidebarLanguagesActionPublish;
        }
      } else if (readiness.status == 'TRANSLATING') {
        targetTab = LanguageWorkspaceTab.categories;
        actionKey = PlatformAdminKeys.sidebarLanguagesActionContinueGeneration;
      } else if (readiness.status == 'REVIEW') {
        targetTab = LanguageWorkspaceTab.overview;
        actionKey = PlatformAdminKeys.sidebarLanguagesActionReview;
      } else if (readiness.readinessPercent == 100) {
        targetTab = LanguageWorkspaceTab.publish;
        actionKey = PlatformAdminKeys.sidebarLanguagesActionPublish;
      }
    } else {
      if (language.status == 'REVIEW') {
        actionKey = PlatformAdminKeys.sidebarLanguagesActionReview;
      } else if (language.status == 'TRANSLATING' || isGenerating) {
        actionKey = PlatformAdminKeys.sidebarLanguagesActionContinueGeneration;
      } else if (language.status == 'DRAFT') {
        actionKey = PlatformAdminKeys.sidebarLanguagesActionGenerate;
      }
    }

    final targetRoute = '/settings/languages/${language.code}?tab=$targetTab';
    final langName = _formatLanguageDisplayName(language);

    return PlatformSectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isGenerating ? PtTheme.deepGreen : PtTheme.amber,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  langName,
                  style: PtTheme.font(
                    14,
                    lineHeight: 18,
                    weight: FontWeight.w700,
                    color: PtTheme.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PlatformStatusChip(status: language.status),
            ],
          ),
          const SizedBox(height: 12),
          if (isGenerating)
            Text(
              strings.tArgsKey(
                PlatformAdminKeys.sidebarLanguagesGenerating,
                {'percent': '$genProgress'},
              ),
              style: PtTheme.font(
                12,
                lineHeight: 16,
                weight: FontWeight.w600,
                color: PtTheme.deepGreen,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else if (readiness != null)
            Text(
              strings.tArgsKey(
                PlatformAdminKeys.sidebarLanguagesProgress,
                {
                  'translated': '${readiness.readinessPercent}',
                  'total': '100',
                  'percent': '${readiness.readinessPercent}',
                },
              ),
              style: PtTheme.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else
            Text(
              _languageStatusLabel(strings, language.status),
              style: PtTheme.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 14),
          PlatformPrimaryButton(
            key: Key('btn-action-center-${language.code}'),
            label: strings.tKey(actionKey),
            icon: Icons.arrow_forward_rounded,
            onPressed: isGenerating ? null : () => context.go(targetRoute),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 6. Operations Snapshot (Jobs by status & Reports by month)
// =============================================================================

class _OperationsSnapshotSection extends ConsumerWidget {
  const _OperationsSnapshotSection({required this.summary});

  final OverviewSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final jobsCard = summary.jobs.byStatus.isEmpty
        ? null
        : _BarsCard(
            title: strings.tKey(PlatformAdminKeys.chartJobsByStatus),
            entries: summary.jobs.byStatus,
          );
    final reportsCard = summary.reports.byMonth.isEmpty
        ? null
        : _BarsCard(
            title: strings.tKey(PlatformAdminKeys.chartReportsByMonth),
            entries: summary.reports.byMonth,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlatformSectionHeader(
          title: strings.tKey(PlatformAdminKeys.dashboardSnapshotTitle),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 900 &&
                jobsCard != null &&
                reportsCard != null) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: jobsCard),
                  const SizedBox(width: 16),
                  Expanded(child: reportsCard),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ?jobsCard,
                if (jobsCard != null && reportsCard != null)
                  const SizedBox(height: 16),
                ?reportsCard,
              ],
            );
          },
        ),
      ],
    );
  }
}

class _BarsCard extends ConsumerWidget {
  const _BarsCard({required this.title, required this.entries});

  final String title;
  final Map<String, int> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final values = entries.values.toList(growable: false);
    final maxValue = values.fold<int>(
      1,
      (max, value) => value > max ? value : max,
    );
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlatformSectionHeader(title: title),
          const SizedBox(height: 14),
          for (final entry in entries.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BarRow(
                label: entry.key,
                value: entry.value,
                fraction: maxValue <= 0
                    ? 0
                    : (entry.value / maxValue).clamp(0.0, 1.0),
              ),
            ),
        ],
      ),
    );
  }
}

class _BarRow extends ConsumerWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.fraction,
  });

  final String label;
  final int value;
  final double fraction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label.isEmpty ? '—' : label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PtTheme.caption,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: PtTheme.canvas,
              borderRadius: BorderRadius.circular(9999),
            ),
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: fraction,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: PtTheme.deepGreen,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 28),
          child: Text(
            '$value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: PtTheme.font(
              12,
              lineHeight: 16,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 7. Recent Activity Section
// =============================================================================

class _RecentActivitySection extends ConsumerWidget {
  const _RecentActivitySection({required this.summary});

  final OverviewSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final entries = summary.recentActivity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlatformSectionHeader(
          title: strings.tKey(PlatformAdminKeys.sectionDashboardRecentActivity),
          action: TextButton(
            key: const Key('btn-activity-view-audit-log'),
            onPressed: () => context.go('/audit-log'),
            child: Text(
              strings.tKey(PlatformAdminKeys.buttonViewAll),
              style: PtTheme.font(
                13,
                lineHeight: 18,
                weight: FontWeight.w700,
                color: PtTheme.deepGreen,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (entries.isNotEmpty)
          PlatformSectionCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in entries.take(6))
                  _ActivityRow(
                    title: entry.action,
                    meta: _joinMeta([
                      entry.entityType.isEmpty
                          ? ''
                          : '${entry.entityType}/${entry.entityId}',
                      entry.actor,
                      entry.occurredAt,
                    ]),
                  ),
              ],
            ),
          )
        else
          const _ActivityFallback(),
      ],
    );
  }

  static String _joinMeta(List<String> parts) =>
      parts.where((part) => part.trim().isNotEmpty).join(' • ');
}

class _ActivityFallback extends ConsumerWidget {
  const _ActivityFallback();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(auditEventsProvider);
    return events.when(
      loading: () => const PlatformLoadingView(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return PlatformSectionCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final event in items.take(6))
                _ActivityRow(
                  title: event.action,
                  meta: _RecentActivitySection._joinMeta([
                    event.entityType.isEmpty
                        ? ''
                        : '${event.entityType}/${event.entityId}',
                    event.actorRole,
                    event.occurredAt,
                  ]),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivityRow extends ConsumerWidget {
  const _ActivityRow({required this.title, required this.meta});

  final String title;
  final String meta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: PtTheme.canvas,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: PtTheme.border),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 16,
              color: PtTheme.deepGreen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.isEmpty ? '—' : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PtTheme.font(
                    13,
                    lineHeight: 18,
                    weight: FontWeight.w700,
                    color: PtTheme.ink,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PtTheme.caption,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 8. Quick Actions Section
// =============================================================================

@immutable
class _DashboardQuickAction {
  const _DashboardQuickAction({
    required this.label,
    required this.description,
    required this.icon,
    required this.route,
    required this.accent,
  });

  final String label;
  final String description;
  final IconData icon;
  final String route;
  final Color accent;
}

class _QuickActionsSection extends ConsumerWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final actions = <_DashboardQuickAction>[
      _DashboardQuickAction(
        label: strings.tKey(PlatformAdminKeys.dashboardQuickActionsAddWorkshop),
        description: strings.tKey(PlatformAdminKeys.dashboardQuickActionsAddWorkshopDesc),
        icon: Icons.add_business_rounded,
        route: '/workshops/new',
        accent: PtTheme.deepGreen,
      ),
      _DashboardQuickAction(
        label: strings.tKey(PlatformAdminKeys.dashboardQuickActionsAddChecklistItem),
        description: strings.tKey(PlatformAdminKeys.dashboardQuickActionsAddChecklistItemDesc),
        icon: Icons.post_add_rounded,
        route: '/checklist/items/new',
        accent: const Color(0xFF1D4ED8),
      ),
      _DashboardQuickAction(
        label: strings.tKey(PlatformAdminKeys.dashboardQuickActionsCreateTemplate),
        description: strings.tKey(PlatformAdminKeys.dashboardQuickActionsCreateTemplateDesc),
        icon: Icons.playlist_add_rounded,
        route: '/checklist/templates/new',
        accent: const Color(0xFF7C3AED),
      ),
      _DashboardQuickAction(
        label: strings.tKey(PlatformAdminKeys.dashboardQuickActionsAddLanguage),
        description: strings.tKey(PlatformAdminKeys.dashboardQuickActionsAddLanguageDesc),
        icon: Icons.translate_rounded,
        route: '/settings/languages',
        accent: PtTheme.amber,
      ),
      _DashboardQuickAction(
        label: strings.tKey(PlatformAdminKeys.dashboardQuickActionsViewHealth),
        description: strings.tKey(PlatformAdminKeys.dashboardQuickActionsViewHealthDesc),
        icon: Icons.health_and_safety_rounded,
        route: '/checklist/health',
        accent: PtTheme.emerald,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlatformSectionHeader(
          title: strings.tKey(PlatformAdminKeys.dashboardQuickActionsTitle),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final columns = maxWidth >= 1100
                ? 3
                : maxWidth >= 640
                    ? 2
                    : 1;
            const spacing = 12.0;
            final tileWidth =
                (maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final action in actions)
                  SizedBox(
                    width: tileWidth,
                    child: _QuickActionCard(action: action),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _DashboardQuickAction action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: action.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go(action.route),
          child: PlatformSectionCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: action.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(action.icon, size: 20, color: action.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        action.label,
                        style: PtTheme.font(
                          14,
                          lineHeight: 18,
                          weight: FontWeight.w700,
                          color: PtTheme.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        action.description,
                        style: PtTheme.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: PtTheme.muted.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
