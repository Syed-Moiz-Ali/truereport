import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/approve/approve_actions.dart';
import 'package:workshop_admin_app/src/features/jobs/approve/approve_score.dart';
import 'package:workshop_admin_app/src/features/jobs/approve/approve_states.dart';
import 'package:workshop_admin_app/src/features/jobs/approve/approve_summary.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Approve screen body: 7/5 two columns on desktop, one stack below 1000.
class ApproveBody extends StatelessWidget {
  const ApproveBody({
    required this.job,
    required this.error,
    required this.errorIsConflict,
    required this.busy,
    required this.reason,
    required this.safetyCapReason,
    required this.onApprove,
    required this.onReject,
    required this.onOpenChecklist,
    required this.onReload,
    super.key,
  });

  final CleanJob job;
  final String? error;
  final bool errorIsConflict;
  final bool busy;
  final TextEditingController reason;
  final TextEditingController safetyCapReason;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onOpenChecklist;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final payload = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (error != null) ...[
          ApproveNotice(
            message: error!,
            onReload: errorIsConflict ? onReload : null,
          ),
          SizedBox(height: spacing.md),
        ],
        if (job.version == null) ...[
          ApproveNotice(
            message: l10n.jobsNoVersion,
            tone: ApproveNoticeTone.warning,
            onReload: onReload,
          ),
          SizedBox(height: spacing.md),
        ],
        if (job.status != 'PENDING_REVIEW') ...[
          ApproveNotice(
            message: l10n.jobsNotEditable,
            tone: ApproveNoticeTone.warning,
          ),
          SizedBox(height: spacing.md),
        ],
        ApproveActions(
          reason: reason,
          safetyCapReason: safetyCapReason,
          canAct: job.version != null && job.status == 'PENDING_REVIEW',
          busy: busy,
          onApprove: onApprove,
          onReject: onReject,
          onOpenChecklist: onOpenChecklist,
        ),
      ],
    );
    final facts = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ApproveSummary(job: job),
        SizedBox(height: spacing.lg),
        ApproveScore(jobId: job.id),
      ],
    );
    return WorkshopPageScroll(
      children: [
        Text(
          l10n.jobsApproveSubtitle,
          style: ws.body.copyWith(color: ws.muted),
        ),
        SizedBox(height: spacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 1000) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  facts,
                  SizedBox(height: spacing.lg),
                  payload,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: facts),
                SizedBox(width: spacing.xl),
                Expanded(flex: 5, child: payload),
              ],
            );
          },
        ),
      ],
    );
  }
}
