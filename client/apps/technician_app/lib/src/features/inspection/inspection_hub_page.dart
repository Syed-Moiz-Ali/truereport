import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/features/inspection/inspection_hub_view.dart';
import 'package:technician_app/src/features/profile/profile_sheet.dart';
import 'package:technician_app/src/technician_providers.dart';

class InspectionHubPage extends ConsumerWidget {
  const InspectionHubPage({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final job = ref.watch(technicianJobProvider(jobId));
    final checklist = ref.watch(inspectionChecklistProvider(jobId));
    final online = ref.watch(connectivityProvider).value ?? true;
    final pending = ref.watch(pendingSyncCountProvider).value ?? 0;

    final combined = job.asData?.value;
    final checklistValue = checklist.asData?.value;
    final error = job.error ?? checklist.error;
    if (error != null && combined == null && checklistValue == null) {
      return AppScaffold(
        appBar: TechnicianAppBar(
          title: l10n.technicianInspectionHub,
          showBack: true,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.gutter),
            child: ErrorState(
              title: l10n.error,
              body: l10n.genericError,
              onRetry: () {
                ref.invalidate(technicianJobProvider(jobId));
                ref.invalidate(inspectionChecklistProvider(jobId));
              },
              retryLabel: l10n.retryAction,
            ),
          ),
        ),
      );
    }
    if (combined == null || checklistValue == null) {
      return AppScaffold(
        appBar: TechnicianAppBar(
          title: l10n.technicianInspectionHub,
          showBack: true,
        ),
        body: Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.gutter),
          child: const LoadingSkeleton(lines: 6),
        ),
      );
    }

    return InspectionHubView(
      job: combined,
      checklist: checklistValue,
      pendingSyncCount: pending,
      online: online,
      onOpenModule: (_) => context.push('/jobs/$jobId/checklist'),
      onContinue: () => context.push('/jobs/$jobId/checklist'),
      onVehicle: () => context.push('/jobs/$jobId'),
      onSync: () async {
        await context.push('/sync');
        ref.invalidate(pendingSyncCountProvider);
      },
      onProfile: () => showTechnicianProfile(context, ref),
    );
  }
}
