import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/job_counts.dart';
import 'package:workshop_admin_app/src/labels.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/features/jobs/assign_technician_dialog.dart';
import 'package:workshop_admin_app/src/features/reports/report_page.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:l10n/l10n.dart';

/// Screen 1 — Workshop dashboard (Overview tab).
///
/// Stat cards render counts from the counts endpoint only,
/// and the recent list renders jobs from the existing `GET jobs` endpoint.
/// Client-side search filters the recent list; nothing is invented.
class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

/// Parses a raw ISO `scheduledAt`/`finalizedAt` string and returns the
/// Asia/Dubai (UTC+4) wall-clock instant for display.
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
/// under the active locale). Falls back to the raw string when unparseable.
String _formatInstant(BuildContext context, String raw) {
  final wall = _dubaiWallTime(raw);
  if (wall == null) {
    return raw;
  }
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMd(locale).add_Hm().format(wall);
}

/// Locale-aware count (`NumberFormat.decimalPattern` under the active locale).
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

    if (counts.hasError) {
      return Center(
        child: ErrorState(
          title: l10n.error,
          body: l10n.actionFailed,
          retryLabel: l10n.retryAction,
          onRetry: () => ref.invalidate(jobCountsProvider),
        ),
      );
    }

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
                user: displayName.isNotEmpty
                    ? WorkshopUserChip(
                        initials: _initials(displayName),
                        displayName: displayName,
                        workshopName: workshopName,
                      )
                    : null,
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: context.spacing.lg,
            ),
            sliver: SliverToBoxAdapter(
              child: counts.when(
                loading: () => const LoadingSkeleton(lines: 3),
                error: (error, _) => const SizedBox.shrink(),
                data: (data) => _StatGrid(counts: data),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(
              context.spacing.lg,
              context.spacing.lg,
              context.spacing.lg,
              context.spacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: SectionHeader(title: l10n.dashboardRecentJobs),
            ),
          ),
          SliverPadding(
            padding: EdgeInsetsDirectional.only(
              start: context.spacing.lg,
              end: context.spacing.lg,
              bottom: context.spacing.lg,
            ),
            sliver: jobs.when(
              loading: () => const SliverToBoxAdapter(
                child: LoadingSkeleton(lines: 4),
              ),
              error: (error, _) => SliverToBoxAdapter(
                child: ErrorState(
                  title: l10n.error,
                  body: l10n.genericError,
                  retryLabel: l10n.retryAction,
                  onRetry: () => ref.invalidate(jobsProvider('')),
                ),
              ),
              data: (items) {
                final query = _search.text.trim().toLowerCase();
                final filtered = items.where((job) {
                  if (query.isEmpty) {
                    return true;
                  }
                  final plate = job.vehiclePlate?.toLowerCase() ?? '';
                  final vin = job.vehicleVin?.toLowerCase() ?? '';
                  final customer = job.customerName.toLowerCase();
                  final ref = job.reference.toLowerCase();
                  final vehicle =
                      '${job.vehicleMake} ${job.vehicleModel}'.toLowerCase();
                  return ref.contains(query) ||
                      customer.contains(query) ||
                      plate.contains(query) ||
                      vin.contains(query) ||
                      vehicle.contains(query);
                }).toList(growable: false);
                if (filtered.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsetsDirectional.all(context.spacing.lg),
                      child: EmptyState(
                        title: l10n.noResults,
                        body: '',
                        icon: Icons.search_off_outlined,
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final job = filtered[index];
                      final vehicle =
                          '${job.vehicleMake} ${job.vehicleModel}'.trim();
                      final plateOrVin = [job.vehiclePlate, job.vehicleVin]
                          .whereType<String>()
                          .where((s) => s.isNotEmpty)
                          .join(' · ');
                      return Padding(
                        padding: EdgeInsetsDirectional.only(
                          bottom: context.spacing.sm,
                        ),
                        child: AppCard(
                          key: Key('dashboard-job-${job.id}'),
                          onTap: () => _openDetails(context, job),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vehicle.isEmpty
                                              ? job.customerName
                                              : vehicle,
                                          style: context.texts.titleMedium,
                                        ),
                                        SizedBox(height: context.spacing.xs),
                                        Text(
                                          job.reference,
                                          style: context.texts.labelSmall
                                              ?.copyWith(
                                                color: context.colors.primary,
                                              ),
                                          textDirection: TextDirection.ltr,
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusChip(
                                    label: jobStatusLabel(l10n, job.status),
                                    tone: jobStatusTone(job.status),
                                  ),
                                ],
                              ),
                              SizedBox(height: context.spacing.sm),
                              Wrap(
                                spacing: context.spacing.md,
                                runSpacing: context.spacing.xs,
                                children: [
                                  if (vehicle.isNotEmpty)
                                    Text(
                                      job.customerName,
                                      style: context.texts.bodySmall,
                                    ),
                                  if (plateOrVin.isNotEmpty)
                                    Text(
                                      plateOrVin,
                                      style: context.texts.bodySmall,
                                      textDirection: TextDirection.ltr,
                                    ),
                                  Text(
                                    job.templateName,
                                    style: context.texts.bodySmall,
                                  ),
                                  if (job.scheduledAt.isNotEmpty)
                                    Text(
                                      '${l10n.scheduledAt}: ${_formatInstant(context, job.scheduledAt)}',
                                      style: context.texts.bodySmall,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
              title: '${job.vehicleMake} ${job.vehicleModel}'.trim(),
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
