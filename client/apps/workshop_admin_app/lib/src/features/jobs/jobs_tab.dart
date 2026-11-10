import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/labels.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/features/jobs/assign_technician_dialog.dart';
import 'package:workshop_admin_app/src/features/reports/report_page.dart';
import 'package:workshop_admin_app/src/features/jobs/schedule_job_sheet.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:l10n/l10n.dart';

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

class JobsTab extends ConsumerStatefulWidget {
  const JobsTab({super.key});

  @override
  ConsumerState<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends ConsumerState<JobsTab> {
  final _search = TextEditingController();
  String _status = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _key => '${_search.text}\u0001$_status';

  /// Counts key: same search text, unfiltered status.
  String get _countsKey => '${_search.text}\u0001';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final jobs = ref.watch(jobsProvider(_key));
    final counts = ref.watch(jobsProvider(_countsKey)).maybeWhen(
      data: (items) => items,
      orElse: () => null,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: context.spacing.lg,
            end: context.spacing.lg,
            top: context.spacing.lg,
          ),
          child: WorkshopHeader(
            title: l10n.queueTitle,
            search: AppTextField(
              key: const Key('jobs-search'),
              controller: _search,
              label: l10n.jobSearch,
              hint: l10n.jobSearch,
              prefixIcon: const Icon(Icons.search),
              onChanged: (_) => setState(() {}),
            ),
            actions: [
              AppButton(
                label: l10n.newJob,
                onPressed: () => _openCreate(context),
                icon: Icons.add,
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: context.spacing.lg,
            vertical: context.spacing.sm,
          ),
          child: Wrap(
            spacing: context.spacing.sm,
            runSpacing: context.spacing.sm,
            children: [
              _filter(context, '', l10n.filterAll, counts),
              _filter(context, 'IN_PROGRESS', l10n.statusInProgress, counts),
              _filter(
                context,
                'READY_TO_FINALIZE',
                l10n.statusReadyToFinalize,
                counts,
              ),
              _filter(context, 'FINALIZED', l10n.statusFinalized, counts),
            ],
          ),
        ),
        Expanded(
          child: jobs.when(
            loading: () => Padding(
              padding: EdgeInsetsDirectional.all(context.spacing.lg),
              child: const LoadingSkeleton(lines: 4),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: EdgeInsetsDirectional.all(context.spacing.lg),
                child: ErrorState(
                  title: l10n.error,
                  body: l10n.genericError,
                  onRetry: () => ref.invalidate(jobsProvider(_key)),
                  retryLabel: l10n.retryAction,
                ),
              ),
            ),
            data: (items) => items.isEmpty
                ? Padding(
                    padding: EdgeInsetsDirectional.all(context.spacing.lg),
                    child: EmptyState(
                      title: l10n.noResults,
                      body: '',
                      icon: Icons.search_off_outlined,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => ref.invalidate(jobsProvider(_key)),
                    child: ListView.separated(
                      padding: EdgeInsetsDirectional.all(context.spacing.lg),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          SizedBox(height: context.spacing.sm),
                      itemBuilder: (context, index) {
                        final job = items[index];
                        final vehicle =
                            '${job.vehicleMake} ${job.vehicleModel}'
                                .trim();
                        return WorkshopJobCard(
                          key: Key('job-${job.id}'),
                          title: vehicle.isEmpty
                              ? job.customerName
                              : vehicle,
                          reference: job.reference,
                          status: StatusChip(
                            label: jobStatusLabel(l10n, job.status),
                            tone: jobStatusTone(job.status),
                          ),
                          meta: [
                            Text(job.customerName),
                            Text(
                              '${job.templateName} v${job.templateVersionNo ?? '-'}',
                            ),
                            Text(
                              job.assignedTechnicianName ?? l10n.unassigned,
                            ),
                          ],
                          onTap: () => _openDetails(context, job),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _filter(
    BuildContext context,
    String value,
    String label,
    List<WorkshopJob>? all,
  ) {
    final count = all == null
        ? null
        : value.isEmpty
        ? all.length
        : all.where((job) => job.status == value).length;
    return AppSelectableText(
      label: count == null ? label : '$label (${_formatCount(context, count)})',
      selected: _status == value,
      onTap: () => setState(() => _status = value),
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    final created = await ScheduleJobSheet.showScheduleJobSheet(context);
    if (created != null) {
      ref.invalidate(jobsProvider(_key));
    }
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
              Wrap(
                spacing: context.spacing.sm,
                runSpacing: context.spacing.sm,
                children: [
                  AppButton(
                    label: job.assignedTechnicianId == null
                        ? l10n.assign
                        : l10n.reassign,
                    onPressed: () => _assign(context, job),
                    icon: Icons.person_add_alt_1_outlined,
                    variant: AppButtonVariant.tonal,
                  ),
                  AppButton(
                    label: l10n.cancelJob,
                    onPressed: () => _cancel(context, job),
                    icon: Icons.cancel_outlined,
                    variant: AppButtonVariant.text,
                  ),
                ],
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
    ref.invalidate(jobsProvider(_key));
  }

  Future<void> _cancel(BuildContext context, WorkshopJob job) async {
    final l10n = AppLocalizations.of(context);
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelJob),
        content: AppTextField(controller: reason, label: l10n.reason),
        actions: [
          AppButton(
            label: l10n.cancel,
            onPressed: () => Navigator.of(context).pop(false),
            variant: AppButtonVariant.text,
          ),
          AppButton(
            label: l10n.cancelJob,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || reason.text.trim().isEmpty || !context.mounted) {
      reason.dispose();
      return;
    }
    try {
      await ref.read(adminApiProvider).cancelJob(job.id, reason.text.trim());
      ref.invalidate(jobsProvider(_key));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.jobCancelled)));
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
      }
    } finally {
      reason.dispose();
    }
  }
}
