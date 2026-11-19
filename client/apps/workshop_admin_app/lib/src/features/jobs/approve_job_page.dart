import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/approve/approve_body.dart';
import 'package:workshop_admin_app/src/features/jobs/approve/approve_states.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';
import 'package:workshop_admin_app/src/features/jobs/publish_checklist_page.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_error_copy.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// Review and decide. Approve/reject exist only here; each call sends the
/// job's version and maps guard failures to distinct copy (F15).
class ApproveIssuePage extends ConsumerStatefulWidget {
  const ApproveIssuePage({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<ApproveIssuePage> createState() => _ApproveIssuePageState();
}

class _ApproveIssuePageState extends ConsumerState<ApproveIssuePage> {
  final _reason = TextEditingController();
  final _safetyCapReason = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _errorIsConflict = false;

  @override
  void dispose() {
    _reason.dispose();
    _safetyCapReason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final job = ref.watch(cleanJobProvider(widget.jobId));
    return Scaffold(
      backgroundColor: context.ws.canvas,
      body: SafeArea(
        child: Column(
          children: [
            JobPageTopBar(title: l10n.jobsApproveTitle),
            Expanded(
              child: job.hasError && !job.hasValue
                  ? SingleChildScrollView(
                      padding: context.ws.pagePaddingOf(context),
                      child: ApproveLoadError(
                        message: jobErrorCopy(l10n, job.error!),
                        onRetry: () =>
                            ref.invalidate(cleanJobProvider(widget.jobId)),
                      ),
                    )
                  : job.when(
                      loading: () => Padding(
                        padding: context.ws.pagePaddingOf(context),
                        child: const WorkshopSkeleton(card: true, lines: 4),
                      ),
                      error: (error, _) => SingleChildScrollView(
                        padding: context.ws.pagePaddingOf(context),
                        child: ApproveLoadError(
                          message: jobErrorCopy(l10n, error),
                          onRetry: () =>
                              ref.invalidate(cleanJobProvider(widget.jobId)),
                        ),
                      ),
                      data: (value) => ApproveBody(
                        job: value,
                        error: _error,
                        errorIsConflict: _errorIsConflict,
                        busy: _busy,
                        reason: _reason,
                        safetyCapReason: _safetyCapReason,
                        onApprove: () => _approve(value),
                        onReject: () => _reject(value),
                        onOpenChecklist: () => _openChecklist(context),
                        onReload: _reload,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChecklist(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PublishChecklistPage(jobId: widget.jobId),
      ),
    );
  }

  Future<void> _approve(CleanJob job) async {
    final l10n = AppLocalizations.of(context);
    if (job.version == null) {
      setState(() => _error = l10n.jobsNoVersion);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _errorIsConflict = false;
    });
    try {
      await ref
          .read(adminApiProvider)
          .approveJob(
            widget.jobId,
            reason: _nullIfEmpty(_reason.text),
            safetyCapReason: _nullIfEmpty(_safetyCapReason.text),
            version: job.version,
          );
      _invalidate();
      _toast(l10n.jobsApproved);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = jobErrorCopy(l10n, error);
          _errorIsConflict = _isConflict(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _reject(CleanJob job) async {
    final l10n = AppLocalizations.of(context);
    if (_reason.text.trim().isEmpty) {
      setState(() {
        _error = l10n.commonReasonRequired;
        _errorIsConflict = false;
      });
      return;
    }
    if (job.version == null) {
      setState(() => _error = l10n.jobsNoVersion);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _errorIsConflict = false;
    });
    try {
      await ref
          .read(adminApiProvider)
          .rejectJob(widget.jobId, _reason.text.trim(), version: job.version);
      _invalidate();
      _toast(l10n.jobsRejected);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = jobErrorCopy(l10n, error);
          _errorIsConflict = _isConflict(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _reload() {
    setState(() {
      _error = null;
      _errorIsConflict = false;
    });
    ref.invalidate(cleanJobProvider(widget.jobId));
    ref.invalidate(jobReviewProvider(widget.jobId));
    ref.invalidate(publishChecklistProvider(widget.jobId));
  }

  void _invalidate() {
    ref.invalidate(cleanJobProvider(widget.jobId));
    ref.invalidate(jobReviewProvider(widget.jobId));
    ref.invalidate(publishChecklistProvider(widget.jobId));
    ref.invalidate(cleanJobsProvider);
    ref.invalidate(cleanJobCountsProvider);
  }

  void _toast(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.ws.ink,
      ),
    );
  }

  bool _isConflict(Object error) {
    final code = error is AppFailure ? error.code : error.toString();
    return code.contains('JOB_VERSION_CONFLICT') ||
        code.contains('VERSION_CONFLICT');
  }

  String? _nullIfEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
