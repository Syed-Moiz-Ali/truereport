import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/features/reports/report_language_options.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Customer and vehicle facts. Identifiers that users read verbatim (phone,
/// plate, VIN, odometer) stay LTR in Arabic.
class JobDetailCustomerVehicle extends ConsumerWidget {
  const JobDetailCustomerVehicle({required this.job, super.key});

  final CleanJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final spacing = context.spacing;
    final odometer = job.odometerValue == null
        ? t(WorkshopAdminKeys.commonNotAvailable)
        : '${formatNumber(context, job.odometerValue!)} '
                  '${job.odometerUnit ?? ''}'
              .trim();
    final languages = ref.watch(workshopLanguagesProvider).asData?.value;
    final preferredLabel = resolvedLanguageLabel(
      languages,
      job.preferredLanguage ?? '',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopSectionHeader(
          title: t(WorkshopAdminKeys.jobDetailCustomerVehicle),
        ),
        SizedBox(height: spacing.sm),
        WorkshopCard(
          child: JobFactGrid(
            // Ten facts in one column pushed Inspection under the sticky bar at
            // 1024 (Gate 6 F11). Two columns fit from 360 px up.
            minColumns: 2,
            facts: [
              JobFact(
                label: t(WorkshopAdminKeys.customerName),
                value: job.customerName,
              ),
              JobFact(
                label: t(WorkshopAdminKeys.customerPhone),
                value:
                    job.customerPhone ??
                    t(WorkshopAdminKeys.commonNotAvailable),
                valueDirection: TextDirection.ltr,
              ),
              JobFact(
                label: t(WorkshopAdminKeys.customerEmail),
                value:
                    job.customerEmail ??
                    t(WorkshopAdminKeys.commonNotAvailable),
                valueDirection: TextDirection.ltr,
              ),
              JobFact(
                label: t(WorkshopAdminKeys.vehicleYear),
                value:
                    job.vehicleYear?.toString() ??
                    t(WorkshopAdminKeys.commonNotAvailable),
                valueDirection: TextDirection.ltr,
              ),
              JobFact(
                label: t(WorkshopAdminKeys.vehiclePlate),
                value:
                    job.vehiclePlate ?? t(WorkshopAdminKeys.commonNotAvailable),
                valueDirection: TextDirection.ltr,
              ),
              JobFact(
                label: t(WorkshopAdminKeys.vehicleVin),
                value:
                    job.vehicleVin ?? t(WorkshopAdminKeys.commonNotAvailable),
                valueDirection: TextDirection.ltr,
              ),
              JobFact(
                label: t(WorkshopAdminKeys.jobsFieldOdometer),
                value: odometer,
                valueDirection: TextDirection.ltr,
              ),
              JobFact(
                label: t(WorkshopAdminKeys.jobsFieldTransmission),
                value:
                    job.transmission ?? t(WorkshopAdminKeys.commonNotAvailable),
              ),
              JobFact(
                label: t(WorkshopAdminKeys.jobsFieldFuelType),
                value: job.fuelType ?? t(WorkshopAdminKeys.commonNotAvailable),
              ),
              if (preferredLabel != null)
                JobFact(
                  label: t(WorkshopAdminKeys.jobsFieldPreferredLanguage),
                  value: preferredLabel,
                ),
              if (job.cancelReason != null)
                JobFact(
                  label: t(WorkshopAdminKeys.jobsCancelReason),
                  value: job.cancelReason!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
