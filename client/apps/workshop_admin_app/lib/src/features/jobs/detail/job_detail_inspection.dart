import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
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
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final review = ref.watch(jobReviewProvider(job.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopSectionHeader(title: l10n.jobDetailInspection),
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
              SizedBox(height: spacing.lg),
              review.when(
                loading: () => const WorkshopSkeleton(lines: 3),
                error: (error, _) =>
                    WorkshopInlineNote(text: l10n.commonLoadFailed),
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
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    if (review.findings.isEmpty) {
      return Text(
        l10n.jobsNoFindings,
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

class _FindingRow extends StatelessWidget {
  const _FindingRow({required this.finding});

  final ReviewFinding finding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final (
      String label,
      WorkshopStatusTone tone,
    ) = switch (finding.resultCode) {
      'NO_ISSUE_OBSERVED' => (l10n.noIssueObserved, WorkshopStatusTone.success),
      'DEFECT_FOUND' => (l10n.defectFound, WorkshopStatusTone.danger),
      'ATTENTION_RECOMMENDED' => (
        l10n.attentionRecommended,
        WorkshopStatusTone.warning,
      ),
      _ => (l10n.commonNotAvailable, WorkshopStatusTone.neutral),
    };
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
