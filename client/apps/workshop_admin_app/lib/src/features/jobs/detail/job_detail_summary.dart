import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_technician.dart';
import 'package:workshop_admin_app/src/workshop_digits.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Identity band: what the job is, whose car it is, and its lifecycle state.
/// Replaces the old header + status row + summary card stack.
class JobDetailSummary extends ConsumerWidget {
  const JobDetailSummary({required this.job, super.key});

  final CleanJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final staff = ref.watch(staffProvider).value;
    final vehicle = [
      job.vehicleMake,
      job.vehicleModel,
    ].where((part) => part.trim().isNotEmpty).join(' ');
    final template = localizedText(
      context,
      en: job.templateNameEn,
      ar: job.templateNameAr,
    );
    // Data values stay Latin and left-to-right in every locale: `DateFormat`
    // for `ar` otherwise emits Arabic-Indic digits and bidi controls, which
    // made the scheduled date read `٩:٠٠ ٢٠٢٦/١١/٥` (Gate 6 F1).
    final schedule = pinDigits(formatInstant(context, job.scheduledAt));
    return WorkshopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            vehicle.isEmpty ? job.customerName : vehicle,
            maxLines: 2,
            style: ws.pageTitle.copyWith(color: ws.ink),
          ),
          SizedBox(height: spacing.xs),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              job.reference,
              textDirection: TextDirection.ltr,
              style: ws.body.copyWith(color: ws.muted),
            ),
          ),
          SizedBox(height: spacing.sm),
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.xs,
            children: [
              JobStatusBadge(status: job.status),
              if (job.reviewStatus.isNotEmpty && job.reviewStatus != job.status)
                JobReviewStatusBadge(status: job.reviewStatus),
              // Publication is only a second chip when it adds information.
              if (!(job.status == 'PUBLISHED' &&
                  job.publicationStatus == 'PUBLISHED'))
                JobPublicationBadge(status: job.publicationStatus),
            ],
          ),
          SizedBox(height: spacing.lg),
          JobFactGrid(
            minColumns: 2,
            facts: [
              JobFact(
                label: t(WorkshopAdminKeys.scheduledAt),
                value: schedule.isEmpty
                    ? t(WorkshopAdminKeys.commonNotAvailable)
                    : schedule,
                valueDirection: TextDirection.ltr,
              ),
              JobFact(
                label: t(WorkshopAdminKeys.jobsAssignedTechnician),
                value: jobTechnicianName(t, job, staff),
              ),
              JobFact(
                label: t(WorkshopAdminKeys.template),
                value: template.isEmpty
                    ? t(WorkshopAdminKeys.commonNotAvailable)
                    : job.templateVersionNo == null
                    ? template
                    : '$template v${job.templateVersionNo}',
              ),
              JobFact(
                label: t(WorkshopAdminKeys.jobsScore),
                value: formatScore(context, job.score),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
