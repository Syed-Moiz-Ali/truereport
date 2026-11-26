import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/reference_ui.dart';
import 'package:technician_app/src/technician_providers.dart';

import 'fieldwork/completed_ui.dart';
import 'fieldwork/review_ui.dart';

/// The handover: what was completed, and what happens to it next.
///
/// This is the last thing the technician sees before walking away from the
/// vehicle, so it confirms the submission, states the next step, and gives one
/// way out. Score and grade appear only when the server has them.
class TechnicianCompletedPage extends ConsumerWidget {
  const TechnicianCompletedPage({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final job = ref.watch(technicianJobSummaryProvider(jobId)).asData?.value;
    final summary = ref.watch(technicianSummaryProvider(jobId)).asData?.value;

    final reference = (job?.reference ?? '').trim();
    final vehicle = job == null
        ? ''
        : [
            job.vehicleMake,
            job.vehicleModel,
            if (job.vehicleYear != null) '${job.vehicleYear}',
          ].where((value) => value.isNotEmpty).join(' ');
    final plate = (job?.vehiclePlate ?? '').trim();
    // The chip reports the job's real status, not a constant. The fallback only
    // covers the frame before the summary lands, so the chip keeps its shape.
    final status = (job?.status ?? '').trim();
    final statusCode = status.isEmpty ? 'PENDING_REVIEW' : status;
    final rows = <ReviewReceiptRow>[
      if (reference.isNotEmpty)
        ReviewReceiptRow(
          label: t(TechnicianKeys.jobReferenceLabel),
          value: reference,
        ),
      if (vehicle.isNotEmpty)
        ReviewReceiptRow(
          label: t(TechnicianKeys.technicianVehicle),
          value: vehicle,
        ),
      if (plate.isNotEmpty)
        ReviewReceiptRow(
          label: t(TechnicianKeys.technicianPlate),
          value: plate,
        ),
      if (summary != null && summary.itemsTotal > 0)
        ReviewReceiptRow(
          label: t(TechnicianKeys.technicianItems),
          value: t(TechnicianKeys.technicianItemsAssessed, {
            'done': summary.itemsAssessed,
            'total': summary.itemsTotal,
          }),
        ),
      if (summary?.score != null)
        ReviewReceiptRow(
          label: t(TechnicianKeys.technicianDraftScore),
          value: '${summary!.score}',
        ),
      if (summary?.gradeCode != null)
        ReviewReceiptRow(
          label: t(TechnicianKeys.technicianGradeLabel),
          value: summary!.gradeCode!,
        ),
    ];

    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: CompletedView(
        title: t(TechnicianKeys.technicianInspectionComplete),
        body: t(TechnicianKeys.technicianCompletedPendingReview),
        statusLabel: jobStatusLabel(ref, statusCode),
        statusTone: jobStatusTone(ref, statusCode),
        receiptRows: rows,
        primaryLabel: t(TechnicianKeys.technicianBackToJobs),
        onPrimary: () => context.go('/jobs'),
      ),
    );
  }
}
