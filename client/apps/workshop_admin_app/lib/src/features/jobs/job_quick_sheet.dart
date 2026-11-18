import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/assign_technician_dialog.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';
import 'package:workshop_admin_app/src/features/reports/report_page.dart';
import 'package:workshop_admin_app/src/models.dart';

/// White bottom sheet with the job at a glance and one primary action.
///
/// Used by the dashboard and the queue. Reassign/Assign opens the existing
/// [WorkshopAssignDialog]; Report opens the published report. Cancel keeps the
/// existing reason-required API flow. Both successful mutations invalidate
/// `jobsProvider('')` and `jobCountsProvider`.
Future<void> showJobQuickSheet(BuildContext context, WorkshopJob job) {
  final ws = context.ws;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: ws.surface,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadiusDirectional.vertical(
        top: Radius.circular(ws.cardLargeRadius),
      ),
    ),
    builder: (_) => _JobQuickSheet(job: job),
  );
}

class _JobQuickSheet extends ConsumerStatefulWidget {
  const _JobQuickSheet({required this.job});

  final WorkshopJob job;

  @override
  ConsumerState<_JobQuickSheet> createState() => _JobQuickSheetState();
}

class _JobQuickSheetState extends ConsumerState<_JobQuickSheet> {
  bool _busy = false;

  WorkshopJob get job => widget.job;

  bool get _isClosed =>
      job.status == 'FINALIZED' ||
      job.status == 'PUBLISHED' ||
      job.status == 'CANCELLED';

  bool get _showsReport =>
      job.status == 'FINALIZED' || job.status == 'PUBLISHED';

  bool get _canAssign =>
      job.status != 'FINALIZED' &&
      job.status != 'PUBLISHED' &&
      job.status != 'CANCELLED';

  bool get _canCancel =>
      job.status != 'FINALIZED' &&
      job.status != 'PUBLISHED' &&
      job.status != 'CANCELLED';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final phone = (job.customerPhone ?? '').trim();
    final email = (job.customerEmail ?? '').trim();
    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.fromSTEB(
        spacing.xl,
        spacing.md,
        spacing.xl,
        spacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        jobVehicleTitle(job),
                        maxLines: 2,
                        style: ws.sectionTitle.copyWith(color: ws.ink),
                      ),
                    ),
                    SizedBox(height: spacing.xs),
                    Wrap(
                      spacing: spacing.sm,
                      runSpacing: spacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          job.reference,
                          textDirection: TextDirection.ltr,
                          style: ws.meta.copyWith(color: ws.muted),
                        ),
                        JobStatusBadge(status: job.status),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing.sm),
              WorkshopIconButton(
                icon: Icons.close,
                semanticLabel: l10n.close,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          SizedBox(height: spacing.lg),
          JobFact(label: l10n.customerName, value: job.customerName),
          if (phone.isNotEmpty) ...[
            SizedBox(height: spacing.md),
            JobFact(
              label: l10n.customerPhone,
              value: phone,
              valueDirection: TextDirection.ltr,
            ),
          ],
          if (email.isNotEmpty) ...[
            SizedBox(height: spacing.md),
            JobFact(
              label: l10n.customerEmail,
              value: email,
              valueDirection: TextDirection.ltr,
            ),
          ],
          SizedBox(height: spacing.md),
          JobFact(
            label: l10n.scheduledAt,
            value: jobScheduleLabel(context, job),
          ),
          SizedBox(height: spacing.md),
          JobFact(
            label: l10n.jobsAssignedTechnician,
            value: job.assignedTechnicianName ?? l10n.unassigned,
          ),
          SizedBox(height: spacing.md),
          JobFact(label: l10n.template, value: jobTemplateLabel(context, job)),
          SizedBox(height: spacing.xl),
          if (_showsReport || _canAssign)
            WorkshopButton(
              label: _showsReport ? l10n.report : _assignLabel(l10n),
              icon: _showsReport
                  ? Icons.description_outlined
                  : Icons.person_add_alt_1_outlined,
              onPressed: _busy ? null : _primaryAction,
              isLoading: _busy,
              expand: true,
            ),
          if (_canCancel) ...[
            SizedBox(height: spacing.xl),
            const WorkshopDivider(),
            SizedBox(height: spacing.xl),
            WorkshopButton(
              label: l10n.cancelJob,
              icon: Icons.cancel_outlined,
              variant: WorkshopButtonVariant.danger,
              onPressed: _busy ? null : _cancel,
              isLoading: _busy,
              expand: true,
            ),
          ],
        ],
      ),
    );
  }

  String _assignLabel(AppLocalizations l10n) =>
      job.assignedTechnicianId == null ? l10n.assign : l10n.reassign;

  Future<void> _primaryAction() async {
    if (_showsReport) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => ReportPage(jobId: job.id)),
      );
      return;
    }
    if (_isClosed) {
      return;
    }
    final selected = await WorkshopAssignDialog.show(context, job);
    ref.invalidate(jobsProvider(''));
    ref.invalidate(jobCountsProvider);
    if (!mounted || selected == null) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _cancel() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final reason = TextEditingController();
    try {
      final confirmed = await WorkshopDialog.show<bool>(
        context,
        title: l10n.cancelJob,
        closeSemanticLabel: l10n.close,
        content: WorkshopTextField(
          controller: reason,
          label: l10n.reason,
          autofocus: true,
        ),
        actions: [
          WorkshopButton(
            label: l10n.cancel,
            variant: WorkshopButtonVariant.secondary,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          WorkshopButton(
            label: l10n.cancelJob,
            variant: WorkshopButtonVariant.danger,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
      final text = reason.text.trim();
      if (confirmed != true || text.isEmpty || !mounted) {
        return;
      }
      setState(() => _busy = true);
      await ref.read(adminApiProvider).cancelJob(job.id, text);
      ref.invalidate(jobsProvider(''));
      ref.invalidate(jobCountsProvider);
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.jobCancelled)));
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
      reason.dispose();
    }
  }
}
