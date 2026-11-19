import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// Live review preview plus the findings a decision needs: label, stable code
/// and a mapped result. Evidence counts, issue values and `completedAt` are
/// deliberately absent (CR-7 / CR-8).
class ApproveScore extends ConsumerWidget {
  const ApproveScore({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final review = ref.watch(jobReviewProvider(jobId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopSectionHeader(title: l10n.jobsReviewTitle),
        SizedBox(height: spacing.sm),
        review.when(
          loading: () => const WorkshopSkeleton(card: true, lines: 3),
          error: (error, _) => WorkshopErrorState(
            title: l10n.error,
            body: l10n.commonLoadFailed,
            retryLabel: l10n.retryAction,
            onRetry: () => ref.invalidate(jobReviewProvider(jobId)),
          ),
          data: (value) => _ScoreCard(review: value),
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.review});

  final JobReview review;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    return WorkshopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.sm,
            children: [
              WorkshopStatusBadge(
                label:
                    '${l10n.jobsItemsAssessed}: '
                    '${formatNumber(context, review.itemsAssessed)} / '
                    '${formatNumber(context, review.itemsTotal)}',
                tone: WorkshopStatusTone.accent,
                icon: Icons.checklist_outlined,
              ),
              WorkshopStatusBadge(
                label:
                    '${l10n.jobsScorePreview}: '
                    '${formatScore(context, review.scorePreview)}',
                tone: WorkshopStatusTone.neutral,
                icon: Icons.speed_outlined,
              ),
              WorkshopStatusBadge(
                label:
                    '${l10n.jobsGradePreview}: '
                    '${review.gradePreview ?? l10n.commonNotAvailable}',
                tone: WorkshopStatusTone.success,
                icon: Icons.grade_outlined,
              ),
              if (review.safetyCapPreview != null)
                WorkshopStatusBadge(
                  label:
                      '${l10n.jobsSafetyCapPreview}: '
                      '${review.safetyCapPreview}',
                  tone: WorkshopStatusTone.warning,
                  icon: Icons.shield_outlined,
                ),
            ],
          ),
          SizedBox(height: spacing.md),
          const WorkshopDivider(),
          if (review.findings.isEmpty)
            Padding(
              padding: EdgeInsetsDirectional.only(top: spacing.md),
              child: Text(
                l10n.jobsNoFindings,
                style: ws.meta.copyWith(color: ws.muted),
              ),
            )
          else
            for (var index = 0; index < review.findings.length; index++) ...[
              if (index > 0) const WorkshopDivider(),
              _FindingRow(finding: review.findings[index]),
            ],
        ],
      ),
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
          WorkshopStatusBadge(label: label, tone: tone),
        ],
      ),
    );
  }
}
