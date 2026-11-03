import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/pages/job_form_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

String jobStatusLabel(AppLocalizations l10n, String status) => switch (status) {
  'DRAFT' => l10n.draft,
  'SCHEDULED' => l10n.statusScheduled,
  'ASSIGNED' => l10n.statusAssigned,
  'IN_PROGRESS' => l10n.statusInProgress,
  'READY_TO_FINALIZE' => l10n.statusReadyToFinalize,
  'FINALIZED' => l10n.statusFinalized,
  'CANCELLED' => l10n.statusCancelled,
  _ => status,
};

StatusTone jobStatusTone(String status) => switch (status) {
  'FINALIZED' => StatusTone.success,
  'CANCELLED' => StatusTone.danger,
  'ASSIGNED' || 'IN_PROGRESS' || 'READY_TO_FINALIZE' => StatusTone.info,
  'SCHEDULED' => StatusTone.warning,
  _ => StatusTone.neutral,
};

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final jobs = ref.watch(jobsProvider(_key));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            context.spacing.lg,
            context.spacing.lg,
            context.spacing.lg,
            context.spacing.sm,
          ),
          child: SectionHeader(
            title: l10n.jobsTab,
            action: AppButton(
              label: l10n.newJob,
              onPressed: () => _openCreate(context),
              icon: Icons.add,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: context.spacing.lg,
          ),
          child: AppTextField(
            key: const Key('jobs-search'),
            controller: _search,
            label: l10n.jobSearch,
            hint: l10n.jobSearch,
            onChanged: (_) => setState(() {}),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: context.spacing.lg,
            vertical: context.spacing.sm,
          ),
          child: Row(
            children: [
              _filter('', l10n.filterAll),
              SizedBox(width: context.spacing.sm),
              _filter('DRAFT', l10n.draft),
              SizedBox(width: context.spacing.sm),
              _filter('SCHEDULED', l10n.statusScheduled),
              SizedBox(width: context.spacing.sm),
              _filter('ASSIGNED', l10n.statusAssigned),
              SizedBox(width: context.spacing.sm),
              _filter('IN_PROGRESS', l10n.statusInProgress),
              SizedBox(width: context.spacing.sm),
              _filter('READY_TO_FINALIZE', l10n.statusReadyToFinalize),
              SizedBox(width: context.spacing.sm),
              _filter('FINALIZED', l10n.statusFinalized),
              SizedBox(width: context.spacing.sm),
              _filter('CANCELLED', l10n.statusCancelled),
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
                  retryLabel: l10n.search,
                ),
              ),
            ),
            data: (items) => items.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsetsDirectional.all(context.spacing.lg),
                      child: EmptyState(
                        title: l10n.noResults,
                        body: l10n.newJob,
                        action: AppButton(
                          label: l10n.newJob,
                          onPressed: () => _openCreate(context),
                          variant: AppButtonVariant.tonal,
                        ),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => ref.invalidate(jobsProvider(_key)),
                    child: ListView.separated(
                      padding: EdgeInsetsDirectional.all(context.spacing.lg),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          SizedBox(height: context.spacing.sm),
                      itemBuilder: (context, index) => Card(
                        child: AppListTile(
                          key: Key('job-${items[index].id}'),
                          leading: const Icon(Icons.work_outline),
                          title:
                              '${items[index].reference} · ${items[index].customerName}',
                          subtitle:
                              '${items[index].vehicleMake} ${items[index].vehicleModel} · ${items[index].templateName} v${items[index].templateVersionNo ?? '-'}',
                          trailing: StatusChip(
                            label: jobStatusLabel(l10n, items[index].status),
                            tone: jobStatusTone(items[index].status),
                          ),
                          onTap: () => _openDetails(context, items[index]),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _filter(String value, String label) {
    return AppSelectableText(
      label: label,
      selected: _status == value,
      onTap: () => setState(() => _status = value),
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const JobFormPage()));
    ref.invalidate(jobsProvider(_key));
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
              subtitle: jobStatusLabel(l10n, job.status),
            ),
            AppListTile(
              leading: const Icon(Icons.person_outline),
              title: job.customerName,
              subtitle: job.customerPhone ?? job.customerEmail ?? '',
            ),
            AppListTile(
              leading: const Icon(Icons.directions_car_outlined),
              title: '${job.vehicleMake} ${job.vehicleModel}',
              subtitle: [job.vehiclePlate, job.vehicleVin]
                  .whereType<String>()
                  .where((value) => value.isNotEmpty)
                  .join(' · '),
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
                subtitle: job.scheduledAt,
              ),
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
    final l10n = AppLocalizations.of(context);
    final selected = await showAppBottomSheet<String>(
      context,
      child: Consumer(
        builder: (context, ref, _) {
          final staff = ref.watch(staffProvider);
          return staff.when(
            loading: () => const LoadingSkeleton(lines: 3),
            error: (error, _) =>
                ErrorState(title: l10n.error, body: l10n.genericError),
            data: (members) {
              final technicians = members
                  .where(
                    (member) =>
                        member.role == 'TECHNICIAN' &&
                        member.status == 'ACTIVE',
                  )
                  .toList();
              if (technicians.isEmpty) {
                return EmptyState(
                  title: l10n.noTechnicians,
                  body: l10n.staffReadOnlyBody,
                  icon: Icons.groups_outlined,
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(title: l10n.assign),
                  ...technicians.map(
                    (member) => AppListTile(
                      title: member.displayName,
                      subtitle: member.emailMasked,
                      onTap: () => Navigator.of(context).pop(member.userId),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
    if (selected == null || !context.mounted) {
      return;
    }
    try {
      await ref.read(adminApiProvider).assignJob(job.id, selected, null);
      ref.invalidate(jobsProvider(_key));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.jobAssigned)));
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
      }
    }
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
