import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// The note a reviewer leaves with their decision.
///
/// The same two fields serve both outcomes — `approveJob` sends them as the
/// approval note and `rejectJob` sends the first as the rejection reason — so
/// this region owns exactly the controllers the page already had and nothing
/// about the call. A reject with no note marks the first field invalid here,
/// next to the field, instead of failing somewhere else on the page.
class ApproveDecision extends StatelessWidget {
  const ApproveDecision({
    required this.reason,
    required this.safetyCapReason,
    required this.reasonMissing,
    required this.onReasonChanged,
    super.key,
  });

  final TextEditingController reason;
  final TextEditingController safetyCapReason;
  final bool reasonMissing;
  final ValueChanged<String> onReasonChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopSectionHeader(title: l10n.reviewAndFinalize),
        SizedBox(height: spacing.sm),
        WorkshopCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              WorkshopTextField(
                key: const Key('jobs-approve-reason'),
                controller: reason,
                label: l10n.jobsApproveReasonOptional,
                onChanged: onReasonChanged,
              ),
              if (reasonMissing) ...[
                SizedBox(height: spacing.xs),
                Text(
                  l10n.commonReasonRequired,
                  style: ws.meta.copyWith(color: ws.danger),
                ),
              ],
              SizedBox(height: spacing.md),
              WorkshopTextField(
                key: const Key('jobs-safety-cap-reason'),
                controller: safetyCapReason,
                label: l10n.jobsSafetyCapReason,
              ),
              SizedBox(height: spacing.md),
              Text(
                l10n.jobsRejectHint,
                style: ws.meta.copyWith(color: ws.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
