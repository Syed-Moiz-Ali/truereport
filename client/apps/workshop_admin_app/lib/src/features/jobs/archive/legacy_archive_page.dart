import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/jobs_queue_body.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/workshop_digits.dart';

/// Read-only bridge for `inspection_jobs` rows that have not been migrated.
/// Quarantined here: no create, assign, cancel, report, publish or link.
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final jobs = ref.watch(jobsProvider(''));
    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        child: Column(
          children: [
            JobPageTopBar(title: l10n.jobsArchiveTitle),
            Expanded(
              child: WorkshopPageScroll(
                children: [
                  Container(
                    key: const Key('jobs-archive-banner'),
                    padding: EdgeInsetsDirectional.all(spacing.md),
                    decoration: BoxDecoration(
                      color: ws.warningSoft,
                      borderRadius: BorderRadius.circular(ws.cardRadius),
                      border: Border.all(
                        color: ws.warning.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 18, color: ws.warning),
                        SizedBox(width: spacing.sm),
                        Expanded(
                          child: Text(
                            l10n.jobsArchiveBanner,
                            style: ws.body.copyWith(color: ws.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: spacing.lg),
                  WorkshopSearchField(
                    key: const Key('jobs-archive-search'),
                    controller: _search,
                    hint: l10n.jobSearch,
                    semanticLabel: l10n.jobSearch,
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: spacing.lg),
                  _archiveBody(context, jobs, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _archiveBody(
    BuildContext context,
    AsyncValue<List<WorkshopJob>> jobs,
    AppLocalizations l10n,
  ) {
    if (jobs.isLoading && !jobs.hasValue) {
      return const WorkshopSkeleton(card: true, lines: 6);
    }
    if (jobs.hasError && !jobs.hasValue) {
      return WorkshopErrorState(
        title: l10n.error,
        body: loadCopy(l10n, jobs.error!),
        retryLabel: l10n.retryAction,
        onRetry: () => ref.invalidate(jobsProvider('')),
      );
    }
    final query = _search.text.trim().toLowerCase();
    final items = (jobs.value ?? const <WorkshopJob>[])
        .where((job) {
          if (query.isEmpty) {
            return true;
          }
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
    if (items.isEmpty) {
      return WorkshopCard(
        child: WorkshopEmptyState(
          title: l10n.jobsArchiveEmpty,
          icon: Icons.inventory_2_outlined,
        ),
      );
    }
    return WorkshopCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 680;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (columns) ...[const _ArchiveHeader(), const WorkshopDivider()],
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0) const WorkshopDivider(),
                _ArchiveRow(
                  key: Key('legacy-job-${items[index].id}'),
                  job: items[index],
                  columns: columns,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Column labels for the read-only archive (brief §9 order).
class _ArchiveHeader extends StatelessWidget {
  const _ArchiveHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    Widget cell(int flex, String label, {bool last = false}) => Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsetsDirectional.only(end: last ? 0 : spacing.md),
        child: Text(label, style: ws.eyebrow.copyWith(color: ws.muted)),
      ),
    );
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ws.cardPadding,
        vertical: spacing.sm,
      ),
      child: Row(
        children: [
          cell(2, l10n.jobsReference),
          cell(3, l10n.jobsVehicle),
          cell(2, l10n.jobsListColumnCustomer),
          cell(2, l10n.status),
          cell(2, l10n.jobsListColumnScheduled, last: true),
        ],
      ),
    );
  }
}

class _ArchiveRow extends StatelessWidget {
  const _ArchiveRow({required this.job, required this.columns, super.key});

  final WorkshopJob job;
  final bool columns;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);
    final schedule = pinDigits(formatInstant(context, job.scheduledAt));
    final scheduleText = schedule.isEmpty ? l10n.commonNotAvailable : schedule;
    final vehicle = '${job.vehicleMake} ${job.vehicleModel}'.trim();
    final plate = job.vehiclePlate?.trim() ?? '';
    Widget cell(int flex, Widget child, {bool last = false}) => Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsetsDirectional.only(end: last ? 0 : spacing.md),
        child: child,
      ),
    );
    if (!columns) {
      return Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: ws.cardPadding,
          vertical: spacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.reference,
                    maxLines: 1,
                    softWrap: false,
                    textDirection: TextDirection.ltr,
                    style: ws.bodyStrong.copyWith(color: ws.ink),
                  ),
                ),
                SizedBox(width: spacing.sm),
                JobStatusBadge(status: job.status),
              ],
            ),
            SizedBox(height: spacing.xxs),
            Text(
              vehicle.isEmpty ? job.customerName : vehicle,
              maxLines: 2,
              style: ws.body.copyWith(color: ws.ink),
            ),
            if (plate.isNotEmpty)
              Text(
                plate,
                maxLines: 1,
                textDirection: TextDirection.ltr,
                style: ws.meta.copyWith(color: ws.muted),
              ),
            SizedBox(height: spacing.xs),
            Text(
              job.customerName,
              maxLines: 2,
              style: ws.meta.copyWith(color: ws.muted),
            ),
            SizedBox(height: spacing.xxs),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  scheduleText,
                  maxLines: 1,
                  textDirection: TextDirection.ltr,
                  style: ws.meta.copyWith(color: ws.muted),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ws.cardPadding,
        vertical: spacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cell(
            2,
            Text(
              job.reference,
              maxLines: 2,
              softWrap: false,
              textDirection: TextDirection.ltr,
              style: ws.body.copyWith(color: ws.ink),
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
                  style: ws.bodyStrong.copyWith(color: ws.ink),
                ),
                if (plate.isNotEmpty) ...[
                  SizedBox(height: spacing.xxs),
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
              style: ws.body.copyWith(color: ws.ink),
            ),
          ),
          cell(
            2,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: JobStatusBadge(status: job.status),
            ),
          ),
          cell(
            2,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  scheduleText,
                  maxLines: 2,
                  textDirection: TextDirection.ltr,
                  style: ws.meta.copyWith(color: ws.muted),
                ),
              ),
            ),
            last: true,
          ),
        ],
      ),
    );
  }
}
