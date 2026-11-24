import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/reference_ui.dart';
import 'package:technician_app/src/technician_providers.dart';

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
    final colors = context.colors;
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
    final rows = <(String, String)>[
      if (reference.isNotEmpty)
        (t(TechnicianKeys.jobReferenceLabel), reference),
      if (vehicle.isNotEmpty) (t(TechnicianKeys.technicianVehicle), vehicle),
      if (plate.isNotEmpty) (t(TechnicianKeys.technicianPlate), plate),
      if (summary != null && summary.itemsTotal > 0)
        (
          t(TechnicianKeys.technicianItems),
          t(TechnicianKeys.technicianItemsAssessed, {
            'done': summary.itemsAssessed,
            'total': summary.itemsTotal,
          }),
        ),
      if (summary?.score != null)
        (t(TechnicianKeys.technicianDraftScore), '${summary!.score}'),
      if (summary?.gradeCode != null)
        (t(TechnicianKeys.technicianGradeLabel), summary!.gradeCode!),
    ];

    return AppScaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SuccessMark(),
                  const SizedBox(height: 24),
                  Text(
                    t(TechnicianKeys.technicianInspectionComplete),
                    textAlign: TextAlign.center,
                    style: context.texts.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(TechnicianKeys.technicianCompletedPendingReview),
                    textAlign: TextAlign.center,
                    style: context.texts.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: StatusChip(
                      label: jobStatusLabel(ref, 'PENDING_REVIEW'),
                      tone: jobStatusTone(ref, 'PENDING_REVIEW'),
                    ),
                  ),
                  if (rows.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    _Receipt(rows: rows),
                  ],
                  const SizedBox(height: 28),
                  _PrimaryAction(
                    label: t(TechnicianKeys.technicianBackToJobs),
                    onPressed: () => context.go('/jobs'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A calm success mark: one ring, one tick, one short settle.
class _SuccessMark extends StatelessWidget {
  const _SuccessMark();

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.success;
    final duration = context.motionDuration(const Duration(milliseconds: 320));
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.92, end: 1),
        duration: duration,
        curve: Curves.easeOutBack,
        builder: (context, value, child) =>
            Transform.scale(scale: value, child: child),
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: pair.background,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: pair.foreground.withValues(alpha: 0.16),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(Icons.check_rounded, size: 46, color: pair.foreground),
        ),
      ),
    );
  }
}

/// What was submitted, on one sheet.
class _Receipt extends StatelessWidget {
  const _Receipt({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 6, 18, 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0) Divider(height: 1, color: colors.outlineVariant),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 108,
                    child: Text(
                      rows[index].$1.toUpperCase(),
                      style: context.texts.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rows[index].$2,
                      style: context.texts.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        height: 48,
        child: Material(
          color: context.brand.ink,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: context.texts.labelLarge?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
