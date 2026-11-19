import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/approve_job_page.dart';
import 'package:workshop_admin_app/src/features/jobs/archive/archive_route.dart';
import 'package:workshop_admin_app/src/features/jobs/assign/assign_sheet.dart';
import 'package:workshop_admin_app/src/features/jobs/job_creation_wizard_page.dart';
import 'package:workshop_admin_app/src/features/jobs/job_detail_page.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/features/jobs/public_link_page.dart';
import 'package:workshop_admin_app/src/features/jobs/publish_checklist_page.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_actions.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_error_copy.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// Navigation and mutations for the queue. Keeping them out of the page keeps
/// the composition within the region budget.
class JobsQueueActions {
  const JobsQueueActions({
    required this.context,
    required this.ref,
    required this.onRefresh,
    required this.onConflict,
  });

  final BuildContext context;
  final WidgetRef ref;
  final VoidCallback onRefresh;
  final ValueChanged<String> onConflict;

  Future<void> open(Widget page) async {
    await Navigator.of(context)
        .push<void>(MaterialPageRoute<void>(builder: (_) => page));
    if (context.mounted) {
      onRefresh();
    }
  }

  void openDetail(CleanJob job) => open(JobDetailPage(jobId: job.id));

  Future<void> openArchivePage() async {
    await openArchive(context);
    if (context.mounted) {
      onRefresh();
    }
  }

  Future<void> openCreate() async {
    final created = await Navigator.of(context).push<CleanJob>(
      MaterialPageRoute<CleanJob>(
        builder: (_) => const JobCreationWizardPage(),
      ),
    );
    if (created == null || !context.mounted) {
      return;
    }
    ref.invalidate(cleanJobsProvider);
    ref.invalidate(cleanJobCountsProvider);
    AppSnackBar.show(
      context,
      message: AppLocalizations.of(context).jobsCreated,
      icon: Icons.add,
    );
  }

  Future<void> assign(CleanJob job) async {
    final l10n = AppLocalizations.of(context);
    if (job.version == null) {
      AppSnackBar.show(context, message: l10n.jobsNoVersion);
      return;
    }
    final assigned = await showAssignSheet(context, job: job);
    if (!context.mounted || assigned != true) {
      return;
    }
    _invalidate(job);
    AppSnackBar.show(
      context,
      message: l10n.jobAssigned,
      icon: Icons.person_add_alt_1_outlined,
    );
  }

  Future<void> cancel(CleanJob job) async {
    final l10n = AppLocalizations.of(context);
    if (job.version == null) {
      AppSnackBar.show(context, message: l10n.jobsNoVersion);
      return;
    }
    final reason = await showJobReasonSheet(
      context,
      title: l10n.cancelJob,
      label: l10n.jobsCancelReason,
      confirmLabel: l10n.cancelJob,
    );
    if (reason == null || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(adminApiProvider)
          .cancelCleanJob(job.id, reason, version: job.version);
      if (!context.mounted) {
        return;
      }
      _invalidate(job);
      AppSnackBar.show(
        context,
        message: l10n.jobCancelled,
        icon: Icons.cancel_outlined,
      );
    } on Object catch (error) {
      if (context.mounted) {
        onConflict(jobErrorCopy(l10n, error));
      }
    }
  }

  void onAction(CleanJob job, JobPrimaryAction action) {
    switch (action) {
      case JobPrimaryAction.assign:
        assign(job);
      case JobPrimaryAction.reviewApprove:
        open(ApproveIssuePage(jobId: job.id));
      case JobPrimaryAction.publishChecklist:
        open(PublishChecklistPage(jobId: job.id));
      case JobPrimaryAction.publicLink:
        open(PublicLinkPage(jobId: job.id));
      case JobPrimaryAction.openJob:
        open(JobDetailPage(jobId: job.id));
      case JobPrimaryAction.none:
        break;
    }
  }

  void _invalidate(CleanJob job) {
    ref.invalidate(cleanJobsProvider);
    ref.invalidate(cleanJobCountsProvider);
    ref.invalidate(cleanJobProvider(job.id));
  }
}
