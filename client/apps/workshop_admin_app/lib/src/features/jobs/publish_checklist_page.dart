import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_chrome.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_pills.dart';
import 'package:workshop_admin_app/src/features/jobs/public_link_page.dart';
import 'package:workshop_admin_app/src/features/jobs/publish/checklist_items.dart';
import 'package:workshop_admin_app/src/features/jobs/publish/checklist_summary.dart';
import 'package:workshop_admin_app/src/features/jobs/publish/publish_gate.dart';
import 'package:workshop_admin_app/src/features/jobs/publish/publish_states.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_action_set.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_error_copy.dart';
import 'package:workshop_admin_app/src/shared/translation_issue_dialog.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// The only client publish gate (M6). Publish requires the server checklist to
/// be ready AND consent to be granted; a `422 CONSENT_REQUIRED` is mapped to
/// the same honest copy instead of a generic failure.
///
/// Layout is the dispatch document: bar, identity, lifecycle rail, the publish
/// pill, then the checklist items and the readiness summary in a 5/4 grid. The
/// gate, the call and every invalidation are the ones this page already had.
class PublishChecklistPage extends ConsumerStatefulWidget {
  const PublishChecklistPage({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<PublishChecklistPage> createState() =>
      _PublishChecklistPageState();
}

class _PublishChecklistPageState extends ConsumerState<PublishChecklistPage> {
  bool _busy = false;
  bool _consentBusy = false;
  bool _pdfDownload = true;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    final width = MediaQuery.sizeOf(context).width;
    final checklist = ref.watch(publishChecklistProvider(widget.jobId));
    final job = ref.watch(cleanJobProvider(widget.jobId)).value;

    final Widget body;
    if (checklist.hasError && !checklist.hasValue) {
      body = _loadError(context, jobErrorCopy(t, checklist.error!));
    } else {
      body = checklist.when(
        loading: () => Padding(
          padding: ws.pagePadding(width),
          child: const WorkshopSkeleton(card: true, lines: 5),
        ),
        error: (error, _) => _loadError(context, jobErrorCopy(t, error)),
        data: (value) => _content(context, value, job),
      );
    }

    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            JobPageBar(
              reference:
                  job?.reference ?? t(WorkshopAdminKeys.jobsPublishChecklist),
              status: job?.status,
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _loadError(BuildContext context, String message) {
    return SingleChildScrollView(
      padding: context.ws.pagePaddingOf(context),
      child: WorkshopErrorState(
        title: UiStrings.of(context)(WorkshopAdminKeys.error),
        body: message,
        retryLabel: UiStrings.of(context)(WorkshopAdminKeys.retryAction),
        onRetry: () => ref.invalidate(publishChecklistProvider(widget.jobId)),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    PublishChecklist checklist,
    CleanJob? job,
  ) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final width = MediaQuery.sizeOf(context).width;
    final actions = effectivePublishActions(job, checklist);
    final publish = jobActionFor(actions, const <String>[
      'publishChecklist',
      'publish',
      'publishJob',
    ]);
    final canPublish =
        publish != null &&
        checklist.ready &&
        (!publish.requiresConsent || checklist.consentGranted);
    return SingleChildScrollView(
      padding: ws.pagePadding(width),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: spacing.md),
              JobIdentityBlock(
                eyebrow: t(WorkshopAdminKeys.jobsPublishChecklist),
                title:
                    job?.customerName ??
                    t(WorkshopAdminKeys.jobsPublishChecklist),
                meta: job == null ? const <String>[] : _meta(context, job),
              ),
              SizedBox(height: spacing.lg),
              if (job != null) ...[
                JobStageRail(status: job.status),
                SizedBox(height: spacing.md),
              ],
              if (_error != null) ...[
                PublishErrorBanner(message: _error!),
                SizedBox(height: spacing.md),
              ],
              Wrap(
                spacing: spacing.sm,
                runSpacing: spacing.sm,
                children: [
                  // Consent is surfaced before the action that requires it.
                  if (!checklist.consentGranted && job != null)
                    JobPillButton(
                      key: const Key('jobs-publish-consent'),
                      label: t(WorkshopAdminKeys.jobsConsentGrant),
                      icon: Icons.verified_user_outlined,
                      variant: JobPillVariant.outline,
                      loading: _consentBusy,
                      onPressed: _consentBusy || _busy
                          ? null
                          : () => _grantConsent(job),
                    ),
                  if (publish != null)
                    JobPillButton(
                      key: const Key('jobs-publish-button'),
                      label: jobActionLabel(publish),
                      icon: Icons.public_outlined,
                      loading: _busy,
                      onPressed: canPublish && !_busy ? _publish : null,
                    ),
                ],
              ),
              if (!canPublish) ...[
                SizedBox(height: spacing.md),
                PublishGate(checklist: checklist),
              ],
              SizedBox(height: spacing.lg),
              JobSplitColumns(
                leading: ChecklistItems(items: checklist.items),
                trailing: ChecklistSummary(
                  checklist: checklist,
                  pdfDownload: _pdfDownload,
                  onPdfDownloadChanged: (value) =>
                      setState(() => _pdfDownload = value),
                  busy: _busy,
                ),
              ),
              SizedBox(height: spacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _meta(BuildContext context, CleanJob job) {
    final t = UiStrings.of(context);
    final vehicle = [
      job.vehicleMake,
      job.vehicleModel,
      if (job.vehicleYear != null) '${job.vehicleYear}',
    ].join(' ').trim();
    return [
      if (vehicle.isNotEmpty) vehicle,
      if ((job.vehiclePlate ?? '').isNotEmpty) job.vehiclePlate!,
      job.assignedTechnicianName ?? t(WorkshopAdminKeys.unassigned),
    ];
  }

  Future<void> _grantConsent(CleanJob job) async {
    final t = UiStrings.of(context);
    if (job.version == null) {
      setState(() => _error = t(WorkshopAdminKeys.jobsNoVersion));
      return;
    }
    setState(() {
      _consentBusy = true;
      _error = null;
    });
    try {
      await ref
          .read(adminApiProvider)
          .updateJobConsent(job.id, consentGranted: true, version: job.version);
      ref.invalidate(publishChecklistProvider(widget.jobId));
      ref.invalidate(cleanJobProvider(widget.jobId));
    } on Object catch (error) {
      ref.invalidate(publishChecklistProvider(widget.jobId));
      ref.invalidate(cleanJobProvider(widget.jobId));
      if (mounted) {
        setState(() => _error = jobErrorCopy(t, error));
      }
    } finally {
      if (mounted) {
        setState(() => _consentBusy = false);
      }
    }
  }

  Future<void> _publish() async {
    final t = UiStrings.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final link = await ref
          .read(adminApiProvider)
          .publishJob(widget.jobId, pdfDownloadEnabled: _pdfDownload);
      ref.invalidate(publishChecklistProvider(widget.jobId));
      ref.invalidate(publicLinkProvider(widget.jobId));
      ref.invalidate(cleanJobProvider(widget.jobId));
      ref.invalidate(cleanJobsProvider);
      ref.invalidate(cleanJobCountsProvider);
      if (!mounted) {
        return;
      }
      _toast(t(WorkshopAdminKeys.jobsPublished));
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => PublicLinkPage(jobId: link.jobId),
        ),
      );
    } on Object catch (error) {
      ref.invalidate(publishChecklistProvider(widget.jobId));
      if (!mounted) return;
      if (error is AppFailure && error.code == 'TRANSLATION_REVIEW_REQUIRED') {
        await showTranslationIssuesDialog(context, error);
        return;
      }
      setState(() => _error = jobErrorCopy(t, error));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.ws.ink,
      ),
    );
  }
}
