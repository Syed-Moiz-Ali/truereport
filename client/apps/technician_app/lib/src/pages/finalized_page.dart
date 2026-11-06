import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/screens/f2b/success_view.dart';
import 'package:technician_app/src/technician_providers.dart';

class FinalizedPage extends ConsumerWidget {
  const FinalizedPage({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final checklist = ref.watch(inspectionChecklistProvider(jobId));
    final report = ref.watch(technicianReportProvider(jobId));
    final deliveries = ref.watch(technicianDeliveriesProvider(jobId));
    final job = ref.watch(technicianJobProvider(jobId));

    final checklistValue = checklist.value;
    final jobValue = job.value;
    if (checklistValue == null || jobValue == null) {
      return AppScaffold(
        appBar: AppBar(title: Text(l10n.finalizedReadOnly)),
        body: Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: const LoadingSkeleton(lines: 7),
        ),
      );
    }

    return SuccessView(
      job: jobValue,
      checklist: checklistValue,
      report: report.value,
      deliveries: deliveries.value ?? const [],
      onBackToJobs: () => context.go('/jobs'),
    );
  }
}
