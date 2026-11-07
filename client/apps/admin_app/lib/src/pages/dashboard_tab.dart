import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/job_counts.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/pages/assign_technician_dialog.dart';
import 'package:admin_app/src/pages/jobs_tab.dart';
import 'package:admin_app/src/pages/report_page.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:l10n/l10n.dart';

/// Screen 1 — Workshop dashboard (Overview tab).
///
/// O4-compliant: stat cards render counts from the P6 counts endpoint only,
/// and the recent list renders jobs from the existing `GET jobs` endpoint.
/// Client-side search filters the recent list; nothing is invented.
///
/// Omitted per the slot sheet: floor-status pill, live-numbers eyebrow,
/// work-period toggle, send-to-floor action, per-station headline counts,
/// correctness %, per-item counts, rows beyond plain status chips,
/// gauge ring/cards, floor map. Mobile/tablet arrange the same widgets
/// in a stacked column (derived layouts, labelled here only — no claim).
class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

/// Parses a raw ISO `scheduledAt`/`finalizedAt` string and returns the
/// Asia/Dubai (UTC+4) wall-clock instant for display.
///
/// Strings carrying no UTC offset are treated as UTC (matching the
/// technician app's `scheduledTimeUtc4` instant interpretation in
/// `assigned_jobs_view.dart`, which displays `toUtc() + 4h`). Returns null
/// when the string is empty or unparseable.
DateTime? _dubaiWallTime(String raw) {
  if (raw.trim().isEmpty) {
    return null;
  }
  final parsed = DateTime.tryParse(raw.trim());
  if (parsed == null) {
    return null;
  }
  final hasOffset = RegExp(r'([Zz]|[+-]\d{2}:?\d{2})$').hasMatch(raw.trim());
  final utc = hasOffset
      ? parsed.toUtc()
      : DateTime.utc(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
          parsed.microsecond,
        );
  return utc.add(const Duration(hours: 4));
}

/// Locale-aware date+time for a raw ISO instant (`DateFormat.yMd + add_Hm`
/// under the active locale). Falls back to the raw string when unparseable
/// so no information is silently dropped.
String _formatInstant(BuildContext context, String raw) {
  final wall = _dubaiWallTime(raw);
  if (wall == null) {
    return raw;
  }
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMd(locale).add_Hm().format(wall);
}

/// Locale-aware count (`NumberFormat.decimalPattern` under the active
/// locale; verified: EN unchanged, and 'ar' also renders Latin digits in
/// intl 0.20.3 — no digit conversion is invented here).
String _formatCount(BuildContext context, int value) {
  final locale = Localizations.localeOf(context).toString();
  return NumberFormat.decimalPattern(locale).format(value);
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(jobCountsProvider);
    ref.invalidate(jobsProvider(''));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final counts = ref.watch(jobCountsProvider);
    final jobs = ref.watch(jobsProvider(''));
    final authState = ref.watch(authControllerProvider);
    final session = authState.value;
    final displayName = session?.user.displayName.trim() ?? '';
    final workshopName = session != null && session.memberships.isNotEmpty
        ? session.memberships.first.workshopName
        : null;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(
              context.spacing.lg,
              context.spacing.lg,
              context.spacing.lg,
              context.spacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: WorkshopHeader(
                semanticLabel: l10n.dashboardTab,
                title: l10n.dashboardTab,
                search: AppTextField(
                  key: const Key('dashboard-search'),
                  controller: _search,
                  label: l10n.jobSearch,
                  hint: l10n.jobSearch,
                  onChanged: (_) => setState(() {}),
                ),
                // Signed-in account only: display name + workshop name.
                // No sample names, no role claim.
                user: displayName.isEmpty
                    ? null
                    : WorkshopUserChip(
                        initials: _initials(displayName),
                        displayName: displayName,
                        workshopName: workshopName,
                      ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: context.spacing.lg,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                l10n.dashboardSubtitle,
                style: context.texts.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          counts.when(
            loading: () => SliverPadding(
              padding: EdgeInsetsDirectional.all(context.spacing.lg),
              sliver: const SliverToBoxAdapter(
                child: LoadingSkeleton(lines: 5),
              ),
            ),
            error: (error, _) => SliverPadding(
              padding: EdgeInsetsDirectional.all(context.spacing.lg),
              sliver: SliverToBoxAdapter(
                child: ErrorState(
                  title: l10n.error,
                  body: l10n.genericError,
                  onRetry: () => ref.invalidate(jobCountsProvider),
                  retryLabel: l10n.retryAction,
                ),
              ),
            ),
            data: (value) => SliverPadding(
              padding: EdgeInsetsDirectional.all(context.spacing.lg),
              sliver: SliverToBoxAdapter(child: _StatGrid(counts: value)),
            ),
          ),
          SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(
              context.spacing.lg,
              context.spacing.sm,
              context.spacing.lg,
              context.spacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: SectionHeader(title: l10n.dashboardRecentJobs),
            ),
          ),
          jobs.when(
            loading: () => SliverPadding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: context.spacing.lg,
              ),
              sliver: const SliverToBoxAdapter(
                child: LoadingSkeleton(lines: 4),
              ),
            ),
            // Offline and server failures surface here with a retry,
            // the same pattern used by the jobs list.
            error: (error, _) => SliverPadding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: context.spacing.lg,
              ),
              sliver: SliverToBoxAdapter(
                child: ErrorState(
                  title: l10n.error,
                  body: l10n.genericError,
                  onRetry: () => ref.invalidate(jobsProvider('')),
                  retryLabel: l10n.retryAction,
                ),
              ),
            ),
            data: (items) {
              final filtered = _filter(items, _search.text);
              if (filtered.isEmpty) {
                return SliverPadding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: context.spacing.lg,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: EmptyState(
                      title: l10n.noResults,
                      body: l10n.dashboardSubtitle,
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: EdgeInsetsDirectional.only(
                  start: context.spacing.lg,
                  end: context.spacing.lg,
                  bottom: context.spacing.lg,
                ),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      SizedBox(height: context.spacing.sm),
                  itemBuilder: (context, index) {
                    final job = filtered[index];
                    final vehicle = '${job.vehicleMake} ${job.vehicleModel}'
                        .trim();
                    final reference = vehicle.isEmpty ? job.scope : vehicle;
                    return WorkshopJobCard(
                      key: Key('dashboard-job-${job.id}'),
                      title: '${job.reference} · ${job.customerName}',
                      reference: reference,
                      status: StatusChip(
                        label: jobStatusLabel(l10n, job.status),
                        tone: jobStatusTone(job.status),
                      ),
                      meta: [
                        Text(job.templateName),
                        if (job.scheduledAt.isNotEmpty)
                          Text(
                            '${l10n.scheduledAt}: '
                            '${_formatInstant(context, job.scheduledAt)}',
                          ),
                      ],
                      assignee: Text(
                        '${l10n.jobAssignedTo}: '
                        '${job.assignedTechnicianName ?? l10n.unassigned}',
                      ),
                      onTap: () => _openDetails(context, job),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<WorkshopJob> _filter(List<WorkshopJob> items, String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return items;
    }
    return items
        .where((job) {
          return <String?>[
            job.reference,
            job.customerName,
            job.vehicleMake,
            job.vehicleModel,
            job.vehicleVin,
            job.vehiclePlate,
            job.templateName,
            job.assignedTechnicianName,
          ].whereType<String>().any(
            (field) => field.toLowerCase().contains(query),
          );
        })
        .toList(growable: false);
  }

  Future<void> _openDetails(BuildContext context, WorkshopJob job) async {
    final l10n = AppLocalizations.of(context);
    await showAppBottomSheet<void>(
      context,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: job.reference,
              titleDirection: TextDirection.ltr,
              subtitle: jobStatusLabel(l10n, job.status),
            ),
            AppListTile(
              leading: const Icon(Icons.person_outline),
              title: job.customerName,
              subtitle: job.customerPhone ?? job.customerEmail ?? '',
              subtitleDirection: TextDirection.ltr,
            ),
            AppListTile(
              leading: const Icon(Icons.directions_car_outlined),
              title: '${job.vehicleMake} ${job.vehicleModel}',
              subtitle: [job.vehiclePlate, job.vehicleVin]
                  .whereType<String>()
                  .where((value) => value.isNotEmpty)
                  .join(' · '),
              subtitleDirection: TextDirection.ltr,
            ),
            AppListTile(
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: job.templateName,
              subtitle: '${l10n.scope}: ${job.scope}',
            ),
            if (job.scheduledAt.isNotEmpty)
              AppListTile(
                leading: const Icon(Icons.schedule),
                title: l10n.scheduledAt,
                subtitle: _formatInstant(context, job.scheduledAt),
              ),
            if (job.status == 'FINALIZED') ...[
              SizedBox(height: context.spacing.md),
              AppButton(
                label: l10n.report,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReportPage(jobId: job.id),
                  ),
                ),
                icon: Icons.description_outlined,
                variant: AppButtonVariant.tonal,
                expand: true,
              ),
            ],
            if (job.status != 'FINALIZED' && job.status != 'CANCELLED') ...[
              SizedBox(height: context.spacing.md),
              AppButton(
                label: job.assignedTechnicianId == null
                    ? l10n.assign
                    : l10n.reassign,
                onPressed: () => _assign(context, job),
                icon: Icons.person_add_alt_1_outlined,
                variant: AppButtonVariant.tonal,
                expand: true,
              ),
            ],
            SizedBox(height: context.spacing.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _assign(BuildContext context, WorkshopJob job) async {
    final selected = await WorkshopAssignDialog.show(context, job);
    if (selected == null || !context.mounted) {
      return;
    }
    ref.invalidate(jobsProvider(''));
    ref.invalidate(jobCountsProvider);
  }
}

String _initials(String displayName) {
  final parts = displayName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return '';
  }
  if (parts.length == 1) {
    return parts.first.characters.first.toUpperCase();
  }
  return (parts.first.characters.first + parts[1].characters.first)
      .toUpperCase();
}

/// Stat cards from counts only — never invented.
///
/// Wide (drawn) layouts show five cards in a row; narrow (derived) layouts
/// wrap into fewer columns and stack on phones (O3/P7: derived, no claim).
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.counts});

  final JobCounts counts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cards = <Widget>[
      WorkshopStatCard(
        key: const Key('dashboard-stat-active'),
        value: _formatCount(context, counts.active),
        caption: l10n.dashboardStatActive,
        icon: Icons.work_outline,
      ),
      WorkshopStatCard(
        key: const Key('dashboard-stat-new-scheduled'),
        value: _formatCount(context, counts.newScheduled),
        caption: l10n.dashboardStatNewScheduled,
        icon: Icons.schedule_outlined,
      ),
      WorkshopStatCard(
        key: const Key('dashboard-stat-in-progress'),
        value: _formatCount(context, counts.inProgress),
        caption: l10n.statusInProgress,
        icon: Icons.play_circle_outline,
      ),
      WorkshopStatCard(
        key: const Key('dashboard-stat-ready'),
        value: _formatCount(context, counts.readyToFinalize),
        caption: l10n.statusReadyToFinalize,
        icon: Icons.task_alt_outlined,
      ),
      WorkshopStatCard(
        key: const Key('dashboard-stat-finalized-today'),
        value: _formatCount(context, counts.finalizedToday),
        caption: l10n.dashboardStatFinalizedToday,
        icon: Icons.check_circle_outline,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth >= 1080
            ? 5
            : maxWidth >= 720
            ? 3
            : maxWidth >= 480
            ? 2
            : 1;
        final gap = context.spacing.md;
        final width = (maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}
