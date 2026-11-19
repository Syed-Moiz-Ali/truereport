import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_chrome.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_pills.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/workshop_digits.dart';

/// Read-only bridge for `inspection_jobs` rows that have not been migrated.
/// Quarantined here: no create, assign, cancel, report, publish or link.
///
/// The archive uses the jobs list language: a 60 px bar with the count, the
/// legacy notice, one search field and one surface of hairline rows. Filtering
/// stays local, the provider and its retry are unchanged, and every row remains
/// inert.
class LegacyArchivePage extends ConsumerStatefulWidget {
  const LegacyArchivePage({super.key});

  @override
  ConsumerState<LegacyArchivePage> createState() => _LegacyArchivePageState();
}

class _LegacyArchivePageState extends ConsumerState<LegacyArchivePage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<WorkshopJob> _visible(List<WorkshopJob> jobs) {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) {
      return jobs;
    }
    return jobs
        .where((job) {
          return [
            job.reference,
            job.customerName,
            job.vehicleMake,
            job.vehicleModel,
            job.vehiclePlate ?? '',
            job.assignedTechnicianName ?? '',
          ].any((field) => field.toLowerCase().contains(query));
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final width = MediaQuery.sizeOf(context).width;
    final jobs = ref.watch(jobsProvider(''));
    final items = jobs.hasValue ? _visible(jobs.value!) : const <WorkshopJob>[];
    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            JobTitleBar(
              title: l10n.jobsArchiveTitle,
              trailing: jobs.hasValue ? _CountPill(count: items.length) : null,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: ws.pagePadding(width),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        _Banner(),
                        const SizedBox(height: 16),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: WorkshopSearchField(
                              key: const Key('jobs-archive-search'),
                              controller: _search,
                              hint: l10n.jobSearch,
                              semanticLabel: l10n.jobSearch,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _body(context, jobs, items, l10n),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AsyncValue<List<WorkshopJob>> jobs,
    List<WorkshopJob> items,
    AppLocalizations l10n,
  ) {
    if (jobs.isLoading && !jobs.hasValue) {
      return const WorkshopSkeleton(card: true, lines: 6);
    }
    if (jobs.hasError && !jobs.hasValue) {
      return WorkshopErrorState(
        title: l10n.error,
        body: _loadCopy(l10n, jobs.error!),
        retryLabel: l10n.retryAction,
        onRetry: () => ref.invalidate(jobsProvider('')),
      );
    }
    if (items.isEmpty) {
      return _ArchiveEmpty(
        title: l10n.jobsArchiveEmpty,
        filtered: _search.text.trim().isNotEmpty,
        noResults: l10n.noResults,
      );
    }
    return _ArchiveSurface(items: items);
  }
}

/// Distinct list errors: 403 is a permission state, 404 is a gone record.
String _loadCopy(AppLocalizations l10n, Object error) {
  if (error is AppFailure) {
    if (error.statusCode == 403 || error.code == 'FORBIDDEN') {
      return l10n.jobsForbidden;
    }
    if (error.statusCode == 404 || error.code == 'JOB_NOT_FOUND') {
      return l10n.jobsNotFound;
    }
  }
  return l10n.commonLoadFailed;
}

/// Neutral count pill in the same full-radius geometry as the lifecycle pills.
class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final label = formatNumber(context, count);
    return Semantics(
      label: '${AppLocalizations.of(context).jobsTab} $label',
      child: Container(
        height: 24,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: ws.canvas,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ws.border),
        ),
        child: Center(
          child: Text(
            label,
            style: ws.eyebrow.copyWith(
              color: ws.ink,
              fontSize: 11,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    return Container(
      key: const Key('jobs-archive-banner'),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: ws.warningSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ws.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 17, color: ws.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.jobsArchiveBanner,
              style: ws.meta.copyWith(color: ws.ink, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// One surface: hairline column band at >= 680 px, stacked rows below it.
class _ArchiveSurface extends StatelessWidget {
  const _ArchiveSurface({required this.items});

  final List<WorkshopJob> items;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Container(
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ws.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 680;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (wide) ...[
                const _ArchiveHeader(),
                Container(height: 1, color: ws.border),
              ],
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0) Container(height: 1, color: ws.border),
                _ArchiveRow(
                  key: Key('legacy-job-${items[index].id}'),
                  job: items[index],
                  wide: wide,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Column labels in the archive's fixed brief §9 order.
class _ArchiveHeader extends StatelessWidget {
  const _ArchiveHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    Widget cell(int flex, String label) => Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 12),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ws.eyebrow.copyWith(color: ws.muted),
        ),
      ),
    );
    return Container(
      color: ws.canvas,
      padding: const EdgeInsetsDirectional.fromSTEB(18, 9, 18, 9),
      child: Row(
        children: [
          cell(2, l10n.jobsReference),
          cell(3, l10n.jobsVehicle),
          cell(2, l10n.jobsListColumnCustomer),
          cell(2, l10n.status),
          cell(2, l10n.jobsListColumnScheduled),
        ],
      ),
    );
  }
}

class _ArchiveRow extends StatelessWidget {
  const _ArchiveRow({required this.job, required this.wide, super.key});

  final WorkshopJob job;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    final vehicle = '${job.vehicleMake} ${job.vehicleModel}'.trim();
    final plate = job.vehiclePlate?.trim() ?? '';
    final schedule = pinDigits(formatInstant(context, job.scheduledAt));
    final scheduleText = schedule.isEmpty ? l10n.commonNotAvailable : schedule;

    if (!wide) {
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const JobGlyph(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    job.reference,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: ws.meta.copyWith(
                      color: ws.ink,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                JobStatusPill(status: job.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              vehicle.isEmpty ? job.customerName : vehicle,
              maxLines: 2,
              style: ws.body.copyWith(
                color: ws.ink,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (plate.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                plate,
                maxLines: 1,
                textDirection: TextDirection.ltr,
                style: ws.meta.copyWith(color: ws.ink),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              job.customerName,
              maxLines: 2,
              style: ws.meta.copyWith(color: ws.muted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule_outlined, size: 14, color: ws.muted),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    scheduleText,
                    textDirection: TextDirection.ltr,
                    style: ws.meta.copyWith(color: ws.muted),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget cell(int flex, Widget child) => Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 12),
        child: child,
      ),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 13, 18, 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cell(
            2,
            Text(
              job.reference,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              style: ws.meta.copyWith(
                color: ws.ink,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          cell(
            3,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vehicle.isEmpty ? job.customerName : vehicle,
                  maxLines: 2,
                  style: ws.body.copyWith(
                    color: ws.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (plate.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    plate,
                    maxLines: 1,
                    textDirection: TextDirection.ltr,
                    style: ws.meta.copyWith(color: ws.muted),
                  ),
                ],
              ],
            ),
          ),
          cell(
            2,
            Text(
              job.customerName,
              maxLines: 2,
              style: ws.meta.copyWith(color: ws.ink),
            ),
          ),
          cell(
            2,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: JobStatusPill(status: job.status),
            ),
          ),
          cell(
            2,
            Text(
              scheduleText,
              textDirection: TextDirection.ltr,
              style: ws.meta.copyWith(color: ws.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveEmpty extends StatelessWidget {
  const _ArchiveEmpty({
    required this.title,
    required this.filtered,
    required this.noResults,
  });

  final String title;
  final bool filtered;
  final String noResults;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 40, 24, 40),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ws.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: ws.canvas, shape: BoxShape.circle),
            child: Icon(Icons.inventory_2_outlined, size: 24, color: ws.muted),
          ),
          const SizedBox(height: 14),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: ws.bodyStrong.copyWith(color: ws.ink),
            ),
          ),
          if (filtered) ...[
            const SizedBox(height: 4),
            Text(
              noResults,
              textAlign: TextAlign.center,
              style: ws.meta.copyWith(color: ws.muted),
            ),
          ],
        ],
      ),
    );
  }
}
