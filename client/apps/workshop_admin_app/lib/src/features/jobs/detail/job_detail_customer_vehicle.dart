import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Customer and vehicle facts. Identifiers that users read verbatim (phone,
/// plate, VIN, odometer) stay LTR in Arabic.
class JobDetailCustomerVehicle extends StatelessWidget {
  const JobDetailCustomerVehicle({required this.job, super.key});

  final CleanJob job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final odometer = job.odometerValue == null
        ? l10n.commonNotAvailable
        : '${formatNumber(context, job.odometerValue!)} '
                  '${job.odometerUnit ?? ''}'
              .trim();
    final preferred = (job.preferredLanguage ?? '').toLowerCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopSectionHeader(title: l10n.jobDetailCustomerVehicle),
        SizedBox(height: spacing.sm),
        WorkshopCard(
          child: JobFactGrid(
            // Ten facts in one column pushed Inspection under the sticky bar at
            // 1024 (Gate 6 F11). Two columns fit from 360 px up.
            minColumns: 2,
            facts: [
              JobFact(label: l10n.customerName, value: job.customerName),
              JobFact(
                label: l10n.customerPhone,
                value: job.customerPhone ?? l10n.commonNotAvailable,
                valueDirection: TextDirection.ltr,
              ),
              JobFact(
                label: l10n.customerEmail,
                value: job.customerEmail ?? l10n.commonNotAvailable,
                valueDirection: TextDirection.ltr,
              ),
              JobFact(
                label: l10n.vehicleYear,
                value: job.vehicleYear?.toString() ?? l10n.commonNotAvailable,
                valueDirection: TextDirection.ltr,
              ),
              JobFact(
                label: l10n.vehiclePlate,
                value: job.vehiclePlate ?? l10n.commonNotAvailable,
                valueDirection: TextDirection.ltr,
              ),
              JobFact(
                label: l10n.vehicleVin,
                value: job.vehicleVin ?? l10n.commonNotAvailable,
                valueDirection: TextDirection.ltr,
              ),
              JobFact(
                label: l10n.jobsFieldOdometer,
                value: odometer,
                valueDirection: TextDirection.ltr,
              ),
              JobFact(
                label: l10n.jobsFieldTransmission,
                value: job.transmission ?? l10n.commonNotAvailable,
              ),
              JobFact(
                label: l10n.jobsFieldFuelType,
                value: job.fuelType ?? l10n.commonNotAvailable,
              ),
              if (preferred == 'ar' || preferred == 'en')
                JobFact(
                  label: l10n.jobsFieldPreferredLanguage,
                  value: preferred == 'ar'
                      ? l10n.languageArabic
                      : l10n.languageEnglish,
                ),
              if (job.cancelReason != null)
                JobFact(label: l10n.jobsCancelReason, value: job.cancelReason!),
            ],
          ),
        ),
      ],
    );
  }
}
