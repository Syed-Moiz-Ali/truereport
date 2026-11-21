import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/features/jobs/job_documents_page.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/reference_status.dart';
import 'package:workshop_admin_app/src/features/reports/report_page.dart';
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
    final t = UiStrings.of(context);
    final spacing = context.spacing;
    final review = ref.watch(jobReviewProvider(job.id));
    final reviewStatuses = ref.watch(statusesProvider('review')).value;
    final publicationStatuses = ref
        .watch(statusesProvider('publication'))
        .value;
    final consentStatuses = ref.watch(statusesProvider('consent')).value;
    final consentCode = consentStatusCode(job.consentGranted);
    final reviewLabel = referenceStatusText(reviewStatuses, job.reviewStatus);
    final blocked = job.status == 'APPROVED' && !job.consentGranted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopSectionHeader(
          title: t(WorkshopAdminKeys.jobDetailReviewPublication),
        ),
        SizedBox(height: spacing.sm),
        WorkshopCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              JobFactGrid(
                facts: [
                  JobFact(
                    label: t(WorkshopAdminKeys.jobsReviewStatus),
                    value: job.reviewStatus.isEmpty
                        ? t(WorkshopAdminKeys.commonNotAvailable)
                        : reviewLabel,
                  ),
                  JobFact(
                    label: t(WorkshopAdminKeys.jobsPublicationStatus),
                    value: referenceStatusText(
                      publicationStatuses,
                      job.publicationStatus,
                    ),
                  ),
                  JobFact(
                    label: t(WorkshopAdminKeys.consent),
                    value: referenceStatusText(consentStatuses, consentCode),
                  ),
                ],
              ),
              if (blocked) ...[
                SizedBox(height: spacing.md),
                WorkshopStatusBadge(
                  label: t(WorkshopAdminKeys.jobsPublicationBlocked),
                  tone: WorkshopStatusTone.warning,
                ),
                SizedBox(height: spacing.sm),
                WorkshopInlineNote(
                  text: t(WorkshopAdminKeys.jobsPublicationBlockedBody),
                ),
              ],
              SizedBox(height: spacing.lg),
              review.when(
                loading: () => const WorkshopSkeleton(lines: 2),
                error: (error, _) => WorkshopInlineNote(
                  text: t(WorkshopAdminKeys.commonLoadFailed),
                ),
                data: (value) => JobFactGrid(
                  facts: [
                    JobFact(
                      label: t(WorkshopAdminKeys.jobsItemsAssessed),
                      value:
                          '${formatNumber(context, value.itemsAssessed)} / '
                          '${formatNumber(context, value.itemsTotal)}',
                    ),
                    JobFact(
                      label: t(WorkshopAdminKeys.jobsScorePreview),
                      value: formatScore(context, value.scorePreview),
                    ),
                    JobFact(
                      label: t(WorkshopAdminKeys.jobsGradePreview),
                      value:
                          value.gradePreview ??
                          t(WorkshopAdminKeys.commonNotAvailable),
                    ),
                    if (value.safetyCapPreview != null)
                      JobFact(
                        label: t(WorkshopAdminKeys.jobsSafetyCapPreview),
                        value: value.safetyCapPreview!,
                      ),
                  ],
                ),
              ),
              SizedBox(height: spacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 480;
                  final actionWidth = wide
                      ? (constraints.maxWidth - spacing.md) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: spacing.md,
                    runSpacing: spacing.sm,
                    children: [
                      SizedBox(
                        width: actionWidth,
                        child: AppButton(
                          key: const Key('job-detail-report-action'),
                          label: t(WorkshopAdminKeys.report),
                          icon: Icons.receipt_long_outlined,
                          variant: AppButtonVariant.tonal,
                          expand: true,
                          onPressed: () => _openReport(context),
                        ),
                      ),
                      SizedBox(
                        width: actionWidth,
                        child: AppButton(
                          key: const Key('job-detail-documents-action'),
                          label: t(WorkshopAdminKeys.jobsDocumentsTitle),
                          icon: Icons.folder_open_outlined,
                          variant: AppButtonVariant.tonal,
                          expand: true,
                          onPressed: () => _openDocuments(context),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The report is a full screen with its own top bar and back action.
  void _openReport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ReportPage(jobId: job.id, preferredLanguage: job.preferredLanguage),
      ),
    );
  }

  /// Generated documents are a full screen with Dispatch chrome.
  void _openDocuments(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => DocumentsPage(jobId: job.id)),
    );
  }
}
