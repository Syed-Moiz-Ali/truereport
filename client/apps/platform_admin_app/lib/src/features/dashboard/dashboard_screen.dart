import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_form.dart';
import '../../components/platform_shell.dart';
import '../../components/platform_states.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final overview = ref.watch(overviewProvider);

    return PlatformShell(
      currentRoute: '/dashboard',
      showSearch: false,
      onNavigate: (route) => context.go(route),
      child: PlatformPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlatformPageHeader(
              title: l10n.dashboardTitle,
              subtitle: l10n.dashboardSubtitle,
              actions: [
                PlatformSecondaryButton(
                  label: l10n.refresh,
                  icon: Icons.refresh_rounded,
                  onPressed: () => ref.invalidate(overviewProvider),
                ),
              ],
            ),
            const SizedBox(height: 20),
            overview.when(
              loading: () => PlatformLoadingView(message: l10n.loading),
              error: (error, stackTrace) => PlatformErrorView(
                message: l10n.unhealthy,
                retryLabel: l10n.retry,
                onRetry: () => ref.invalidate(overviewProvider),
              ),
              data: (summary) => _DashboardContent(summary: summary),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.summary});

  final OverviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (summary.isEmpty) {
      return PlatformEmptyView(
        icon: Icons.dashboard_outlined,
        title: l10n.dashEmpty,
        actionLabel: l10n.registerWorkshop,
        onAction: () => context.go('/workshops'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroCard(summary: summary),
        const SizedBox(height: 24),
        PlatformSectionHeader(title: l10n.dashboardKpis),
        const SizedBox(height: 12),
        _KpiGrid(summary: summary),
        if (summary.jobs.byStatus.isNotEmpty ||
            summary.reports.byMonth.isNotEmpty) ...[
          const SizedBox(height: 24),
          _DistributionSection(summary: summary),
        ],
        const SizedBox(height: 24),
        _ActivityAlerts(summary: summary),
        const SizedBox(height: 24),
        const _QuickActions(),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.summary});

  final OverviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stats = <String>[
      '${summary.workshops.total} ${l10n.dashTotalWorkshops}',
      '${summary.workshops.active} ${l10n.dashActiveWorkshops}',
      '${summary.staff.technicians} ${l10n.dashTechnicians}',
    ];
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFF006C49), Color(0xFF0A8A5F)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22006C49),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.dashboard_rounded,
                      size: 24,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.dashboardTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PtTheme.font(
                            24,
                            lineHeight: 30,
                            weight: FontWeight.w800,
                            color: PtTheme.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.dashboardSubtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: PtTheme.font(
                            13,
                            lineHeight: 18,
                            color: PtTheme.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final stat in stats)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: const Color(0xFFFFFFFF)
                              .withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(
                        stat,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PtTheme.font(
                          12,
                          lineHeight: 16,
                          weight: FontWeight.w700,
                          color: PtTheme.white,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
          final cta = PlatformSecondaryButton(
            label: l10n.wsAdd,
            icon: Icons.add_business_rounded,
            onPressed: () => context.go('/workshops/new'),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [heading, const SizedBox(height: 16), cta],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: heading),
              const SizedBox(width: 20),
              cta,
            ],
          );
        },
      ),
    );
  }
}

@immutable
class _KpiData {
  const _KpiData({
    required this.value,
    required this.label,
    required this.icon,
    required this.route,
    required this.accent,
    required this.tint,
  });

  final String value;
  final String label;
  final IconData icon;
  final String route;
  final Color accent;
  final Color tint;
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.summary});

  final OverviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cards = <_KpiData>[
      _KpiData(
        value: '${summary.workshops.total}',
        label: l10n.dashTotalWorkshops,
        icon: Icons.store_rounded,
        route: '/workshops',
        accent: PtTheme.deepGreen,
        tint: PtTheme.emerald,
      ),
      _KpiData(
        value: '${summary.workshops.active}',
        label: l10n.dashActiveWorkshops,
        icon: Icons.storefront_rounded,
        route: '/workshops',
        accent: PtTheme.deepGreen,
        tint: PtTheme.emerald,
      ),
      _KpiData(
        value: '${summary.staff.technicians}',
        label: l10n.dashTechnicians,
        icon: Icons.engineering_rounded,
        route: '/workshops',
        accent: const Color(0xFF1D4ED8),
        tint: const Color(0xFF3B82F6),
      ),
      _KpiData(
        value: '${summary.jobs.active}',
        label: l10n.dashActiveJobs,
        icon: Icons.assignment_rounded,
        route: '/audit-log',
        accent: const Color(0xFF7C3AED),
        tint: const Color(0xFF8B5CF6),
      ),
      _KpiData(
        value: '${summary.jobs.pendingReview}',
        label: l10n.dashPendingReviews,
        icon: Icons.rate_review_rounded,
        route: '/audit-log',
        accent: PtTheme.amber,
        tint: PtTheme.gold,
      ),
      _KpiData(
        value: '${summary.reports.published}',
        label: l10n.dashPublishedReports,
        icon: Icons.description_rounded,
        route: '/audit-log',
        accent: const Color(0xFF0E7490),
        tint: const Color(0xFF06B6D4),
      ),
      _KpiData(
        value: '${summary.checklist.issues}',
        label: l10n.dashChecklistHealth,
        icon: Icons.health_and_safety_rounded,
        route: '/checklist/health',
        accent: summary.checklist.healthy ? PtTheme.deepGreen : PtTheme.rose,
        tint: summary.checklist.healthy ? PtTheme.emerald : PtTheme.rose,
      ),
      _KpiData(
        value: '${summary.languages.live}/${summary.languages.translating}',
        label: l10n.dashLanguagesLive,
        icon: Icons.translate_rounded,
        route: '/settings/languages',
        accent: const Color(0xFF4338CA),
        tint: const Color(0xFF6366F1),
      ),
    ];
    return LayoutBuilder(
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
            for (final card in cards)
              SizedBox(
                width: cardWidth,
                child: _KpiCard(data: card),
              ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});

  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: data.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.go(data.route),
          child: PlatformSectionCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: data.tint.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: data.tint.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Icon(data.icon, size: 22, color: data.accent),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: 10),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: PtTheme.muted.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PtTheme.font(
                    28,
                    lineHeight: 34,
                    weight: FontWeight.w800,
                    color: PtTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PtTheme.font(
                    12,
                    lineHeight: 16,
                    weight: FontWeight.w600,
                    color: PtTheme.muted,
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

class _DistributionSection extends StatelessWidget {
  const _DistributionSection({required this.summary});

  final OverviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final jobsCard = summary.jobs.byStatus.isEmpty
        ? null
        : _BarsCard(
            title: l10n.dashJobsByStatus,
            entries: summary.jobs.byStatus,
          );
    final reportsCard = summary.reports.byMonth.isEmpty
        ? null
        : _BarsCard(
            title: l10n.dashReportsByMonth,
            entries: summary.reports.byMonth,
          );
    return LayoutBuilder(
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
    );
  }
}

class _BarsCard extends StatelessWidget {
  const _BarsCard({required this.title, required this.entries});

  final String title;
  final Map<String, int> entries;

  @override
  Widget build(BuildContext context) {
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

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.fraction,
  });

  final String label;
  final int value;
  final double fraction;

  @override
  Widget build(BuildContext context) {
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

class _ActivityAlerts extends StatelessWidget {
  const _ActivityAlerts({required this.summary});

  final OverviewSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _RecentActivity(entries: summary.recentActivity),
              ),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _AlertsSection(summary: summary)),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RecentActivity(entries: summary.recentActivity),
            const SizedBox(height: 24),
            _AlertsSection(summary: summary),
          ],
        );
      },
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.entries});

  final List<OverviewActivityEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlatformSectionHeader(
          title: l10n.dashRecentActivity,
          action: const _ViewAll(route: '/audit-log'),
        ),
        const SizedBox(height: 12),
        if (entries.isNotEmpty)
          PlatformSectionCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in entries.take(8))
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
              for (final event in items.take(8))
                _ActivityRow(
                  title: event.action,
                  meta: _RecentActivity._joinMeta([
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

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.title, required this.meta});

  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: PtTheme.canvas,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: PtTheme.border),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 17,
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

@immutable
class _AlertItem {
  const _AlertItem({
    required this.title,
    required this.body,
    required this.route,
    required this.severity,
  });

  final String title;
  final String body;
  final String route;
  final String severity;
}

class _AlertsSection extends ConsumerWidget {
  const _AlertsSection({required this.summary});

  final OverviewSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items = <_AlertItem>[
      for (final alert in summary.alerts)
        _AlertItem(
          title: alert.title,
          body: alert.body,
          route: alert.route,
          severity: alert.severity,
        ),
    ];
    final health = ref.watch(configHealthProvider);
    health.whenData((data) {
      if (!data.healthy) {
        final codes = data.checks
            .where((check) => !check.ok)
            .map((check) => check.code)
            .where((code) => code.isNotEmpty)
            .take(3)
            .join(', ');
        items.add(
          _AlertItem(
            title: l10n.unhealthy,
            body: codes,
            route: '/checklist/health',
            severity: 'ERROR',
          ),
        );
      }
    });
    final languages = ref.watch(platformLanguagesProvider);
    languages.whenData((list) {
      for (final language in list) {
        if (language.status == 'LIVE') continue;
        final display = language.nativeName.isNotEmpty
            ? language.nativeName
            : language.code;
        items.add(
          _AlertItem(
            title: l10n.dashTranslationIncomplete(display),
            body: language.status,
            route: '/settings/languages',
            severity: 'WARNING',
          ),
        );
      }
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlatformSectionHeader(title: l10n.dashAlerts),
        const SizedBox(height: 12),
        if (items.isEmpty)
          PlatformSectionCard(
            child: Text(
              l10n.dashNoAlerts,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: PtTheme.bodyMuted,
            ),
          )
        else
          PlatformSectionCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [for (final item in items) _AlertRow(item: item)],
            ),
          ),
      ],
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.item});

  final _AlertItem item;

  @override
  Widget build(BuildContext context) {
    final normalized = item.severity.toUpperCase();
    final color = normalized == 'ERROR' || normalized == 'CRITICAL'
        ? PtTheme.rose
        : normalized == 'WARNING'
        ? PtTheme.amber
        : PtTheme.deepGreen;
    final icon = normalized == 'ERROR' || normalized == 'CRITICAL'
        ? Icons.error_outline_rounded
        : normalized == 'WARNING'
        ? Icons.warning_amber_rounded
        : Icons.info_outline_rounded;
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title.isEmpty ? '—' : item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PtTheme.font(
                    13,
                    lineHeight: 18,
                    weight: FontWeight.w700,
                    color: PtTheme.ink,
                  ),
                ),
                if (item.body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: PtTheme.caption,
                  ),
                ],
              ],
            ),
          ),
          if (item.route.isNotEmpty)
            const Padding(
              padding: EdgeInsetsDirectional.only(start: 8, top: 6),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: PtTheme.muted,
              ),
            ),
        ],
      ),
    );
    if (item.route.isEmpty) return content;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Semantics(
        button: true,
        label: item.title,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => context.go(item.route),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actions = <_QuickAction>[
      _QuickAction(
        label: l10n.registerWorkshop,
        icon: Icons.business_rounded,
        route: '/workshops',
        accent: PtTheme.deepGreen,
        tint: PtTheme.emerald,
      ),
      _QuickAction(
        label: l10n.addItem,
        icon: Icons.add_rounded,
        route: '/checklist/items',
        accent: const Color(0xFF1D4ED8),
        tint: const Color(0xFF3B82F6),
      ),
      _QuickAction(
        label: l10n.createTemplate,
        icon: Icons.description_rounded,
        route: '/checklist/templates',
        accent: const Color(0xFF7C3AED),
        tint: const Color(0xFF8B5CF6),
      ),
      _QuickAction(
        label: l10n.addLanguage,
        icon: Icons.translate_rounded,
        route: '/settings/languages',
        accent: PtTheme.gold,
        tint: PtTheme.amber,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlatformSectionHeader(title: l10n.dashQuickActions),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1000
                ? 4
                : constraints.maxWidth >= 600
                ? 2
                : 1;
            const spacing = 12.0;
            final tileWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final action in actions)
                  SizedBox(
                    width: tileWidth,
                    child: _QuickActionTile(action: action),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: action.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.go(action.route),
          child: PlatformSectionCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: action.tint.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: action.tint.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Icon(action.icon, size: 22, color: action.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    action.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: PtTheme.font(
                      14,
                      lineHeight: 20,
                      weight: FontWeight.w700,
                      color: PtTheme.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: PtTheme.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.route,
    required this.accent,
    required this.tint,
  });

  final String label;
  final IconData icon;
  final String route;
  final Color accent;
  final Color tint;
}

class _ViewAll extends StatelessWidget {
  const _ViewAll({required this.route});

  final String route;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextButton(
      onPressed: () => context.go(route),
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: Text(
        l10n.dashViewAll,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: PtTheme.font(
          13,
          lineHeight: 18,
          weight: FontWeight.w700,
          color: PtTheme.deepGreen,
        ),
      ),
    );
  }
}
