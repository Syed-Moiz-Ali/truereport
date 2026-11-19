import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/approve/approve_decision.dart';
import 'package:workshop_admin_app/src/features/jobs/approve/approve_score.dart';
import 'package:workshop_admin_app/src/features/jobs/approve/approve_states.dart';
import 'package:workshop_admin_app/src/features/jobs/approve/approve_summary.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_chrome.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_pills.dart';
import 'package:workshop_admin_app/src/features/jobs/publish_checklist_page.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_error_copy.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// Review and decide. Approve/reject exist only here; each call sends the
/// job's version and maps guard failures to distinct copy (F15).
///
/// The page is the dispatch document: a bar with the reference and status, the
/// customer identity, the lifecycle rail, one pill per allowed outcome, then
/// the facts and the decision note in a 5/4 grid. The calls, the version guard,
/// the reason validation and the conflict copy are untouched.
class ApproveIssuePage extends ConsumerStatefulWidget {
  const ApproveIssuePage({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<ApproveIssuePage> createState() => _ApproveIssuePageState();
}

class _ApproveIssuePageState extends ConsumerState<ApproveIssuePage> {
  final _reason = TextEditingController();
  final _safetyCapReason = TextEditingController();
  final _decisionKey = GlobalKey();
  bool _busy = false;
  bool _busyIsReject = false;
  bool _reasonMissing = false;
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
    final ws = context.ws;
    final width = MediaQuery.sizeOf(context).width;
    final jobAsync = ref.watch(cleanJobProvider(widget.jobId));
    final job = jobAsync.value;

    final Widget body;
    if (jobAsync.hasError && !jobAsync.hasValue) {
      body = SingleChildScrollView(
        padding: ws.pagePadding(width),
        child: ApproveLoadError(
          message: jobErrorCopy(l10n, jobAsync.error!),
          onRetry: _reload,
        ),
      );
    } else {
      body = jobAsync.when(
        loading: () => Padding(
          padding: ws.pagePadding(width),
          child: const WorkshopSkeleton(card: true, lines: 6),
        ),
        error: (error, _) => SingleChildScrollView(
          padding: ws.pagePadding(width),
          child: ApproveLoadError(
            message: jobErrorCopy(l10n, error),
            onRetry: _reload,
          ),
        ),
        data: (value) => _content(context, value),
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
              reference: job?.reference ?? l10n.jobsApproveTitle,
              status: job?.status,
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, CleanJob job) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final width = MediaQuery.sizeOf(context).width;
    final canAct = job.version != null && job.status == 'PENDING_REVIEW';
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
                eyebrow: l10n.jobsApproveTitle,
                title: job.customerName,
                meta: _meta(context, job),
              ),
              SizedBox(height: spacing.lg),
              JobStageRail(status: job.status),
              if (_hasNotices(job)) ...[
                SizedBox(height: spacing.md),
                _notices(context, job),
              ],
              SizedBox(height: spacing.md),
              _actionPills(context, job, canAct: canAct),
              SizedBox(height: spacing.lg),
              JobSplitColumns(
                leading: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ApproveSummary(job: job),
                    SizedBox(height: spacing.lg),
                    ApproveScore(jobId: job.id),
                  ],
                ),
                trailing: ApproveDecision(
                  key: _decisionKey,
                  reason: _reason,
                  safetyCapReason: _safetyCapReason,
                  reasonMissing: _reasonMissing,
                  onReasonChanged: (_) {
                    if (_reasonMissing) {
                      setState(() => _reasonMissing = false);
                    }
                  },
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
    final l10n = AppLocalizations.of(context);
    final vehicle = [
      job.vehicleMake,
      job.vehicleModel,
      if (job.vehicleYear != null) '${job.vehicleYear}',
    ].join(' ').trim();
    return [
      if (vehicle.isNotEmpty) vehicle,
      if ((job.vehiclePlate ?? '').isNotEmpty) job.vehiclePlate!,
      job.assignedTechnicianName ?? l10n.unassigned,
    ];
  }

  bool _hasNotices(CleanJob job) =>
      _error != null || job.version == null || job.status != 'PENDING_REVIEW';

  Widget _notices(BuildContext context, CleanJob job) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final notices = <Widget>[
      if (_error != null)
        ApproveNotice(
          message: _error!,
          onReload: _errorIsConflict ? _reload : null,
        ),
      if (job.version == null)
        ApproveNotice(
          message: l10n.jobsNoVersion,
          tone: ApproveNoticeTone.warning,
          onReload: _reload,
        ),
      if (job.status != 'PENDING_REVIEW')
        ApproveNotice(
          message: l10n.jobsNotEditable,
          tone: ApproveNoticeTone.warning,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < notices.length; index++) ...[
          if (index > 0) SizedBox(height: spacing.sm),
          notices[index],
        ],
      ],
    );
  }

  Widget _actionPills(
    BuildContext context,
    CleanJob job, {
    required bool canAct,
  }) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: context.spacing.sm,
      runSpacing: context.spacing.sm,
      children: [
        JobPillButton(
          key: const Key('jobs-approve-button'),
          label: l10n.jobsApprove,
          icon: Icons.verified_outlined,
          loading: _busy && !_busyIsReject,
          onPressed: canAct && !_busy ? () => _approve(job) : null,
        ),
        JobPillButton(
          key: const Key('jobs-reject-button'),
          label: l10n.jobsReject,
          icon: Icons.block_outlined,
          variant: JobPillVariant.danger,
          loading: _busy && _busyIsReject,
          onPressed: canAct && !_busy ? () => _reject(job) : null,
        ),
        JobPillButton(
          key: const Key('jobs-checklist-link'),
          label: l10n.jobsOpenPublishChecklist,
          icon: Icons.playlist_add_check_outlined,
          variant: JobPillVariant.outline,
          onPressed: _busy ? null : () => _openChecklist(context),
        ),
      ],
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
      _busyIsReject = false;
      _error = null;
      _errorIsConflict = false;
      _reasonMissing = false;
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
        _reasonMissing = true;
        _error = null;
        _errorIsConflict = false;
      });
      _revealDecision();
      return;
    }
    if (job.version == null) {
      setState(() => _error = l10n.jobsNoVersion);
      return;
    }
    setState(() {
      _busy = true;
      _busyIsReject = true;
      _reasonMissing = false;
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

  /// On a stacked layout the decision note sits below the facts, so a reject
  /// that needs a note brings the note into view instead of failing off-screen.
  void _revealDecision() {
    if (MediaQuery.sizeOf(context).width >= 900) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _decisionKey.currentContext;
      if (target == null) {
        return;
      }
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _reload() {
    setState(() {
      _error = null;
      _errorIsConflict = false;
      _reasonMissing = false;
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
