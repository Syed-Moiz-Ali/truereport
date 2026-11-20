import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_fact.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_fact_grid.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// The real job facts a reviewer needs before approving, and nothing else.
/// Score/grade/safety come from the job; the live review preview lives below.
/// The reference and the lifecycle pill live in the page bar, not here.
class ApproveSummary extends StatelessWidget {
  const ApproveSummary({required this.job, super.key});

  final CleanJob job;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final spacing = context.spacing;
    final template = localizedText(
      context,
      en: job.templateNameEn,
      ar: job.templateNameAr,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopSectionHeader(title: t(WorkshopAdminKeys.jobsSummary)),
        SizedBox(height: spacing.sm),
        WorkshopCard(
          child: JobFactGrid(
            minColumns: 2,
            facts: [
              JobFact(
                label: t(WorkshopAdminKeys.jobsAssignedTechnician),
                value:
                    job.assignedTechnicianName ??
                    t(WorkshopAdminKeys.unassigned),
              ),
              JobFact(
                label: t(WorkshopAdminKeys.jobsTemplate),
                value: job.templateVersionNo == null
                    ? template
                    : '$template\u00A0·\u00A0v${formatNumber(context, job.templateVersionNo!)}',
              ),
              JobFact(
                label: t(WorkshopAdminKeys.jobsScore),
                value: formatScore(context, job.score),
              ),
              JobFact(
                label: t(WorkshopAdminKeys.jobsGrade),
                value: job.gradeCode ?? t(WorkshopAdminKeys.commonNotAvailable),
              ),
              JobFact(
                label: t(WorkshopAdminKeys.safetyCap),
                value: job.safetyCapApplied
                    ? (job.safetyCapReason ??
                          t(WorkshopAdminKeys.jobsSafetyCapApplied))
                    : t(WorkshopAdminKeys.jobsSafetyCapNotApplied),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
