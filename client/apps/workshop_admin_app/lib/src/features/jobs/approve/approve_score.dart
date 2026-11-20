import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/reference_status.dart';
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
    final t = UiStrings.of(context);
    final spacing = context.spacing;
    final review = ref.watch(jobReviewProvider(jobId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopSectionHeader(title: t(WorkshopAdminKeys.jobsReviewTitle)),
        SizedBox(height: spacing.sm),
        review.when(
          loading: () => const WorkshopSkeleton(card: true, lines: 3),
          error: (error, _) => WorkshopErrorState(
            title: t(WorkshopAdminKeys.error),
            body: t(WorkshopAdminKeys.commonLoadFailed),
            retryLabel: t(WorkshopAdminKeys.retryAction),
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
    final t = UiStrings.of(context);
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
                    '${t(WorkshopAdminKeys.jobsItemsAssessed)}: '
                    '${formatNumber(context, review.itemsAssessed)} / '
                    '${formatNumber(context, review.itemsTotal)}',
                tone: WorkshopStatusTone.accent,
                icon: Icons.checklist_outlined,
              ),
              WorkshopStatusBadge(
                label:
                    '${t(WorkshopAdminKeys.jobsScorePreview)}: '
                    '${formatScore(context, review.scorePreview)}',
                tone: WorkshopStatusTone.neutral,
                icon: Icons.speed_outlined,
              ),
              WorkshopStatusBadge(
                label:
                    '${t(WorkshopAdminKeys.jobsGradePreview)}: '
                    '${review.gradePreview ?? t(WorkshopAdminKeys.commonNotAvailable)}',
                tone: WorkshopStatusTone.success,
                icon: Icons.grade_outlined,
              ),
              if (review.safetyCapPreview != null)
                WorkshopStatusBadge(
                  label:
                      '${t(WorkshopAdminKeys.jobsSafetyCapPreview)}: '
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
                t(WorkshopAdminKeys.jobsNoFindings),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final badge = WorkshopStatusBadge(label: label, tone: tone);
          final detail = Column(
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
          );
          // Below ~440 px the badge and the label cannot share a line without
          // squeezing the finding name, so the badge moves above it.
          if (constraints.maxWidth < 440) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                badge,
                SizedBox(height: spacing.xs),
                detail,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: detail),
              SizedBox(width: spacing.sm),
              badge,
            ],
          );
        },
      ),
    );
  }
}
