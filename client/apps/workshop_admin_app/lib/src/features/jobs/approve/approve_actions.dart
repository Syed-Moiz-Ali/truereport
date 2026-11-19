import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// The only approve/reject affordances in the module. Both are disabled when
/// the job is not `PENDING_REVIEW`, when its version is missing, or while a
/// mutation is in flight; the checklist link stays available.
class ApproveActions extends StatelessWidget {
  const ApproveActions({
    required this.reason,
    required this.safetyCapReason,
    required this.canAct,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onOpenChecklist,
    super.key,
  });

  final TextEditingController reason;
  final TextEditingController safetyCapReason;
  final bool canAct;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onOpenChecklist;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    return WorkshopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          WorkshopTextField(
            key: const Key('jobs-approve-reason'),
            controller: reason,
            label: l10n.jobsApproveReasonOptional,
          ),
          SizedBox(height: spacing.md),
          WorkshopTextField(
            key: const Key('jobs-safety-cap-reason'),
            controller: safetyCapReason,
            label: l10n.jobsSafetyCapReason,
          ),
          SizedBox(height: spacing.lg),
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              WorkshopButton(
                key: const Key('jobs-approve-button'),
                label: l10n.jobsApprove,
                icon: Icons.verified_outlined,
                isLoading: busy,
                onPressed: canAct && !busy ? onApprove : null,
              ),
              WorkshopButton(
                key: const Key('jobs-reject-button'),
                label: l10n.jobsReject,
                icon: Icons.block_outlined,
                variant: WorkshopButtonVariant.danger,
                onPressed: canAct && !busy ? onReject : null,
              ),
              WorkshopButton(
                key: const Key('jobs-checklist-link'),
                label: l10n.jobsOpenPublishChecklist,
                icon: Icons.playlist_add_check_outlined,
                variant: WorkshopButtonVariant.secondary,
                onPressed: busy ? null : onOpenChecklist,
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
          Text(l10n.jobsRejectHint, style: ws.meta.copyWith(color: ws.muted)),
        ],
      ),
    );
  }
}
