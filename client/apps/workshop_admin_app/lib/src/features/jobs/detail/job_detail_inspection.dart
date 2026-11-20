import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/reference_status.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// Inspection facts and findings.
///
/// Findings show labels, stable codes and a mapped result label only. Evidence
/// counts, issue values and `completedAt` are deliberately absent (CR-7/CR-8).
class JobDetailInspection extends ConsumerWidget {
  const JobDetailInspection({required this.job, super.key});

  final CleanJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final spacing = context.spacing;
    final review = ref.watch(jobReviewProvider(job.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopSectionHeader(title: t(WorkshopAdminKeys.jobDetailInspection)),
        SizedBox(height: spacing.sm),
        WorkshopCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              JobFactGrid(
                minColumns: 2,
                facts: [
                  JobFact(
                    label: t(WorkshopAdminKeys.jobsGrade),
                    value:
                        job.gradeCode ??
                        t(WorkshopAdminKeys.commonNotAvailable),
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
              SizedBox(height: spacing.lg),
              review.when(
                loading: () => const WorkshopSkeleton(lines: 3),
                error: (error, _) => WorkshopInlineNote(
                  text: t(WorkshopAdminKeys.commonLoadFailed),
                ),
                data: (value) => _Findings(review: value),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Findings extends StatelessWidget {
  const _Findings({required this.review});

  final JobReview review;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    if (review.findings.isEmpty) {
      return Text(
        t(WorkshopAdminKeys.jobsNoFindings),
        style: ws.meta.copyWith(color: ws.muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < review.findings.length; index++) ...[
          if (index > 0) const WorkshopDivider(),
          _FindingRow(finding: review.findings[index]),
        ],
      ],
    );
  }
}

class _FindingRow extends ConsumerWidget {
  const _FindingRow({required this.finding});

  final ReviewFinding finding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = context.ws;
    final spacing = context.spacing;
    final results = ref.watch(enumsProvider('result')).value;
    final label = referenceStatusText(results, finding.resultCode ?? '');
    final tone = referenceStatusTone(results, finding.resultCode ?? '');
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: spacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localizedText(
                    context,
                    en: finding.labelEn,
                    ar: finding.labelAr,
                  ),
                  maxLines: 2,
                  style: ws.bodyStrong.copyWith(color: ws.ink),
                ),
                SizedBox(height: spacing.xxs),
                Text(
                  finding.stableCode,
                  textDirection: TextDirection.ltr,
                  style: ws.meta.copyWith(color: ws.muted),
                ),
              ],
            ),
          ),
          SizedBox(width: spacing.sm),
          Flexible(
            flex: 2,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: WorkshopStatusBadge(label: label, tone: tone),
            ),
          ),
        ],
      ),
    );
  }
}
