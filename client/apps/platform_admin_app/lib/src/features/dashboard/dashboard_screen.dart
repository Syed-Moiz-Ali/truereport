import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_shell.dart';
import '../../platform_catalogue_models.dart';
import '../../platform_config_models.dart';
import '../../platform_dashboard_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import 'dashboard_feed.dart';
import 'platform_charts.dart';
import 'trellis/trellis_actions.dart';
import 'trellis/trellis_activity.dart';
import 'trellis/trellis_attention_sheet.dart';
import 'trellis/trellis_header.dart';
import 'trellis/trellis_modules.dart';
import 'trellis/trellis_ribbon.dart';
import 'trellis/trellis_ui.dart';

/// Platform Admin dashboard — the command centre.
///
/// Live KPIs and attention come from `/platform/overview`; job flow, workshop
/// leaders, status mix, languages, configuration and delivery come from
/// `/platform/dashboard`, all sharing one 7/14/30-day range.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _days = 14;
  PlatformDashboard? _lastDashboard;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final overview = ref.watch(overviewProvider);
    final dashboard = ref.watch(platformDashboardProvider(_days));
    final latest = dashboard.value;
    if (latest != null) {
      _lastDashboard = latest;
    }

    void refresh() {
      ref.invalidate(overviewProvider);
      ref.invalidate(auditEventsProvider);
      ref.invalidate(platformDashboardProvider(_days));
    }

    return PlatformShell(
      currentRoute: '/dashboard',
      showSearch: false,
      onNavigate: (route) => context.go(route),
      child: overview.when(
        loading: () => const TrellisSkeleton(),
        error: (_, _) => TrellisError(strings: strings, onRetry: refresh),
        data: (summary) {
          if (summary.isEmpty) {
            return TrellisEmpty(
              title: strings.tKey(PlatformAdminKeys.emptyWorkshopsTitle),
              body: strings.tKey(PlatformAdminKeys.emptyWorkshopsBody),
              actionLabel: strings.tKey(PlatformAdminKeys.pageWorkshopsAdd),
              onAction: () => context.go('/workshops/new'),
            );
          }
          return _DashboardContent(
            strings: strings,
            summary: summary,
            dashboard: _lastDashboard,
            dashboardError: dashboard.hasError,
            refreshing: dashboard.isLoading && _lastDashboard != null,
            days: _days,
            onDaysChanged: (days) => setState(() => _days = days),
            onRefresh: refresh,
            onRetryDashboard: () =>
                ref.invalidate(platformDashboardProvider(_days)),
          );
        },
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({
    required this.strings,
    required this.summary,
    required this.dashboard,
    required this.dashboardError,
    required this.refreshing,
    required this.days,
    required this.onDaysChanged,
    required this.onRefresh,
    required this.onRetryDashboard,
  });

  final UiMessageStrings strings;
  final OverviewSummary summary;
  final PlatformDashboard? dashboard;
  final bool dashboardError;
  final bool refreshing;
  final int days;
  final ValueChanged<int> onDaysChanged;
  final VoidCallback onRefresh;
  final VoidCallback onRetryDashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events =
        ref.watch(auditEventsProvider).asData?.value ??
        const <PlatformAuditEvent>[];
    final localeName = Localizations.localeOf(context).toString();

    final attention = buildDashboardAttention(
      summary: summary,
      strings: strings,
    );
    final activity = buildDashboardActivity(
      summary: summary,
      auditEvents: events,
      localeName: localeName,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        final data = dashboard;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 24, wide ? 28 : 16, 44),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TrellisHeader(
                    strings: strings,
                    onRefresh: onRefresh,
                    width: constraints.maxWidth,
                  ),
                  const SizedBox(height: 16),
                  TrellisRibbon(
                    strings: strings,
                    entries: attention,
                    onDetails: () => showTrellisAttentionSheet(
                      context: context,
                      strings: strings,
                      entries: attention,
                      onOpen: (route) => context.go(route),
                      onHealth: () => context.go('/checklist/health'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (data != null)
                    PlatformKpiStrip(data: data, strings: strings)
                  else
                    TrellisBento(strings: strings, cards: summary.metricCards),
                  const SizedBox(height: 16),
                  if (dashboardError && data == null)
                    _DashboardError(strings: strings, onRetry: onRetryDashboard)
                  else if (data != null) ...[
                    if (wide) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 8,
                            child: PlatformFlowCard(
                              data: data,
                              days: days,
                              onDaysChanged: onDaysChanged,
                              refreshing: refreshing,
                              strings: strings,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 4,
                            child: PlatformReportsCard(
                              reports: data.reports,
                              strings: strings,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: PlatformWorkshopLeadersCard(
                              workshops: data.workshops,
                              strings: strings,
                              onOpenWorkshops: () => context.go('/workshops'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 6,
                            child: PlatformStatusDonutCard(
                              jobs: data.jobs,
                              strings: strings,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      PlatformLanguagesConfigCard(
                        config: data.config,
                        strings: strings,
                      ),
                    ] else ...[
                      PlatformFlowCard(
                        data: data,
                        days: days,
                        onDaysChanged: onDaysChanged,
                        refreshing: refreshing,
                        strings: strings,
                      ),
                      const SizedBox(height: 16),
                      PlatformReportsCard(
                        reports: data.reports,
                        strings: strings,
                      ),
                      const SizedBox(height: 16),
                      PlatformWorkshopLeadersCard(
                        workshops: data.workshops,
                        strings: strings,
                        onOpenWorkshops: () => context.go('/workshops'),
                      ),
                      const SizedBox(height: 16),
                      PlatformStatusDonutCard(
                        jobs: data.jobs,
                        strings: strings,
                      ),
                      const SizedBox(height: 16),
                      PlatformLanguagesConfigCard(
                        config: data.config,
                        strings: strings,
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),
                  TrellisActions(
                    strings: strings,
                    onOpen: (route) => context.go(route),
                  ),
                  const SizedBox(height: 24),
                  TrellisActivity(
                    strings: strings,
                    entries: activity,
                    onViewAll: () => context.go('/audit-log'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.strings, required this.onRetry});

  final UiMessageStrings strings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return TrellisSurface(
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: PtTheme.rose,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              strings.tKey(PlatformAdminKeys.dashboardInsightsError),
              style: Trellis.text(12.5, color: PtTheme.rose),
            ),
          ),
          const SizedBox(width: 10),
          TrellisButton(
            label: strings.tKey(PlatformAdminKeys.dashboardInsightsRetry),
            onPressed: onRetry,
            variant: TrellisButtonVariant.secondary,
            compact: true,
          ),
        ],
      ),
    );
  }
}
