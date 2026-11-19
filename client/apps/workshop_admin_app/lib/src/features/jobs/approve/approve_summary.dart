import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_fact.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_fact_grid.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_status_badge.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// The real job facts a reviewer needs before approving, and nothing else.
/// Score/grade/safety come from the job; the live review preview lives below.
class ApproveSummary extends StatelessWidget {
  const ApproveSummary({required this.job, super.key});

  final CleanJob job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
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
        WorkshopSectionHeader(title: l10n.jobsSummary),
        SizedBox(height: spacing.sm),
        WorkshopCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      job.reference,
                      textDirection: TextDirection.ltr,
                      style: ws.cardTitle.copyWith(color: ws.ink),
                    ),
                  ),
                  SizedBox(width: spacing.sm),
                  JobStatusBadge(status: job.status),
                ],
              ),
              SizedBox(height: spacing.lg),
              JobFactGrid(
                facts: [
                  JobFact(label: l10n.customerName, value: job.customerName),
                  JobFact(
                    label: l10n.vehicle,
                    value: '${job.vehicleMake} ${job.vehicleModel}'.trim(),
                  ),
                  JobFact(
                    label: l10n.jobsAssignedTechnician,
                    value: job.assignedTechnicianName ?? l10n.unassigned,
                  ),
                  JobFact(
                    label: l10n.jobsTemplate,
                    value: job.templateVersionNo == null
                        ? template
                        : '$template · v${formatNumber(context, job.templateVersionNo!)}',
                  ),
                  JobFact(
                    label: l10n.jobsScore,
                    value: formatScore(context, job.score),
                  ),
                  JobFact(
                    label: l10n.jobsGrade,
                    value: job.gradeCode ?? l10n.commonNotAvailable,
                  ),
                  JobFact(
                    label: l10n.safetyCap,
                    value: job.safetyCapApplied
                        ? (job.safetyCapReason ?? l10n.jobsSafetyCapApplied)
                        : l10n.jobsSafetyCapNotApplied,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
