import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

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
    final t = UiStrings.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopSectionHeader(title: t(WorkshopAdminKeys.reviewAndFinalize)),
        SizedBox(height: spacing.sm),
        WorkshopCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              WorkshopTextField(
                key: const Key('jobs-approve-reason'),
                controller: reason,
                label: t(WorkshopAdminKeys.jobsApproveReasonOptional),
                onChanged: onReasonChanged,
              ),
              if (reasonMissing) ...[
                SizedBox(height: spacing.xs),
                Text(
                  t(WorkshopAdminKeys.commonReasonRequired),
                  style: ws.meta.copyWith(color: ws.danger),
                ),
              ],
              SizedBox(height: spacing.md),
              WorkshopTextField(
                key: const Key('jobs-safety-cap-reason'),
                controller: safetyCapReason,
                label: t(WorkshopAdminKeys.jobsSafetyCapReason),
              ),
              SizedBox(height: spacing.md),
              Text(
                t(WorkshopAdminKeys.jobsRejectHint),
                style: ws.meta.copyWith(color: ws.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
