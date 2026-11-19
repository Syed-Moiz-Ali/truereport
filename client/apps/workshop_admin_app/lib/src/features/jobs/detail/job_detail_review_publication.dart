import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// Review and publication state, including the consent gate.
///
/// There is no publish button here: the checklist is the only client publish
/// path (M6). An approved job without consent states why publishing is blocked
/// and promises nothing.
class JobDetailReviewPublication extends ConsumerWidget {
  const JobDetailReviewPublication({required this.job, super.key});

  final CleanJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final review = ref.watch(jobReviewProvider(job.id));
    final reviewLabel = reviewStatusLabel(l10n, job.reviewStatus);
    final blocked = job.status == 'APPROVED' && !job.consentGranted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopSectionHeader(title: l10n.jobDetailReviewPublication),
        SizedBox(height: spacing.sm),
        WorkshopCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              JobFactGrid(
                facts: [
                  JobFact(
                    label: l10n.jobsReviewStatus,
                    value: reviewLabel ?? l10n.commonNotAvailable,
                  ),
                  JobFact(
                    label: l10n.jobsPublicationStatus,
                    value: publicationStatusLabel(l10n, job.publicationStatus),
                  ),
                  JobFact(
                    label: l10n.consent,
                    value: job.consentGranted
                        ? l10n.jobsConsentGranted
                        : l10n.jobsConsentMissing,
                  ),
                ],
              ),
              if (blocked) ...[
                SizedBox(height: spacing.md),
                WorkshopStatusBadge(
                  label: l10n.jobsPublicationBlocked,
                  tone: WorkshopStatusTone.warning,
                ),
                SizedBox(height: spacing.sm),
                WorkshopInlineNote(text: l10n.jobsPublicationBlockedBody),
              ],
              SizedBox(height: spacing.lg),
              review.when(
                loading: () => const WorkshopSkeleton(lines: 2),
                error: (error, _) =>
                    WorkshopInlineNote(text: l10n.commonLoadFailed),
                data: (value) => JobFactGrid(
                  facts: [
                    JobFact(
                      label: l10n.jobsItemsAssessed,
                      value:
                          '${formatNumber(context, value.itemsAssessed)} / '
                          '${formatNumber(context, value.itemsTotal)}',
                    ),
                    JobFact(
                      label: l10n.jobsScorePreview,
                      value: formatScore(context, value.scorePreview),
                    ),
                    JobFact(
                      label: l10n.jobsGradePreview,
                      value: value.gradePreview ?? l10n.commonNotAvailable,
                    ),
                    if (value.safetyCapPreview != null)
                      JobFact(
                        label: l10n.jobsSafetyCapPreview,
                        value: value.safetyCapPreview!,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
