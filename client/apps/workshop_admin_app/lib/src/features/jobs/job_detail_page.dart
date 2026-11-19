import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/assign/assign_sheet.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_action_bar.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_body.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_states.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_top_bar.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_actions.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_error_copy.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_reason_sheet.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// Clean job detail: state + mutations only. Every visible block lives in a
/// region file under `features/jobs/detail/`.
class JobDetailPage extends ConsumerStatefulWidget {
  const JobDetailPage({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends ConsumerState<JobDetailPage> {
  bool _busy = false;
  String? _banner;

  String get _jobId => widget.jobId;

  void _refresh() {
    setState(() => _banner = null);
    ref.invalidate(cleanJobProvider(_jobId));
    ref.invalidate(jobReviewProvider(_jobId));
    ref.invalidate(jobAssignmentsProvider(_jobId));
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final jobAsync = ref.watch(cleanJobProvider(_jobId));
    final job = jobAsync.value;
    final actions = job == null
        ? null
        : jobActionsFor(status: job.status, consentGranted: job.consentGranted);
    final mutationsEnabled =
        job != null && job.version != null && _banner == null;
    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            JobDetailTopBar(
              job: job,
              canAssign: (actions?.canAssign ?? false) && mutationsEnabled,
              canCancel: (actions?.canCancel ?? false) && mutationsEnabled,
              busy: _busy,
              onRefresh: _refresh,
              onAssign: _assign,
              onCancel: _cancel,
            ),
            Expanded(
              child: jobAsync.hasError && !jobAsync.hasValue
                  ? JobDetailLoadError(
                      error: jobAsync.error!,
                      onRetry: () => ref.invalidate(cleanJobProvider(_jobId)),
                    )
                  : jobAsync.when(
                      loading: () => const JobDetailLoading(),
                      error: (error, _) => JobDetailLoadError(
                        error: error,
                        onRetry: () => ref.invalidate(cleanJobProvider(_jobId)),
                      ),
                      data: (value) =>
                          JobDetailBody(job: value, banner: _banner),
                    ),
            ),
            if (job != null && actions != null)
              JobDetailActionBar(
                job: job,
                actions: actions,
                busy: _busy,
                mutationsEnabled: mutationsEnabled,
                onAssign: _assign,
                onCancel: _cancel,
                onRefresh: _refresh,
                onOpen: _open,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context)
        .push<void>(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) {
      _refresh();
    }
  }

  Future<void> _assign() async {
    final job = ref.read(cleanJobProvider(_jobId)).value;
    if (job == null) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    if (job.version == null) {
      setState(() => _banner = l10n.jobsNoVersion);
      return;
    }
    final assigned = await showAssignSheet(context, job: job);
    if (!mounted || assigned != true) {
      return;
    }
    _refresh();
    AppSnackBar.show(
      context,
      message: l10n.jobAssigned,
      icon: Icons.person_add,
    );
  }

  Future<void> _cancel() async {
    final l10n = AppLocalizations.of(context);
    final job = ref.read(cleanJobProvider(_jobId)).value;
    if (job == null) {
      return;
    }
    if (job.version == null) {
      setState(() => _banner = l10n.jobsNoVersion);
      return;
    }
    final reason = await showJobReasonSheet(
      context,
      title: l10n.cancelJob,
      label: l10n.jobsCancelReason,
      confirmLabel: l10n.cancelJob,
    );
    if (reason == null || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(adminApiProvider)
          .cancelCleanJob(job.id, reason, version: job.version);
      ref.invalidate(cleanJobProvider(job.id));
      ref.invalidate(cleanJobCountsProvider);
      if (mounted) {
        _refresh();
        AppSnackBar.show(
          context,
          message: l10n.jobCancelled,
          icon: Icons.cancel_outlined,
        );
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _banner = jobErrorCopy(l10n, error));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
