import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Checklist facts. `documentsReady` is never rendered: it is a server
/// constant and documents only exist after publish (G-J5 / CR-6). The note
/// states the real order of events instead.
class ChecklistSummary extends StatelessWidget {
  const ChecklistSummary({required this.checklist, super.key});

  final PublishChecklist checklist;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopSectionHeader(title: l10n.jobsSummary),
        SizedBox(height: spacing.sm),
        WorkshopCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: spacing.sm,
                runSpacing: spacing.sm,
                children: [
                  WorkshopStatusBadge(
                    key: const Key('jobs-checklist-ready-chip'),
                    label: checklist.ready
                        ? l10n.jobsChecklistReady
                        : l10n.jobsChecklistNotReady,
                    tone: checklist.ready
                        ? WorkshopStatusTone.success
                        : WorkshopStatusTone.danger,
                    icon: checklist.ready
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                  ),
                  WorkshopStatusBadge(
                    label:
                        '${l10n.jobsItemsAssessed}: '
                        '${formatNumber(context, checklist.itemsAssessed)} / '
                        '${formatNumber(context, checklist.itemsTotal)}',
                    tone: WorkshopStatusTone.accent,
                    icon: Icons.checklist_outlined,
                  ),
                  WorkshopStatusBadge(
                    label:
                        '${l10n.jobsScore}: '
                        '${formatScore(context, checklist.score)}',
                    tone: WorkshopStatusTone.neutral,
                    icon: Icons.speed_outlined,
                  ),
                  WorkshopStatusBadge(
                    label:
                        '${l10n.jobsGrade}: '
                        '${checklist.gradeCode ?? l10n.commonNotAvailable}',
                    tone: WorkshopStatusTone.success,
                    icon: Icons.grade_outlined,
                  ),
                  WorkshopStatusBadge(
                    label: checklist.consentGranted
                        ? l10n.jobsConsentGranted
                        : l10n.jobsConsentMissing,
                    tone: checklist.consentGranted
                        ? WorkshopStatusTone.success
                        : WorkshopStatusTone.danger,
                    icon: Icons.verified_user_outlined,
                  ),
                  WorkshopStatusBadge(
                    label: checklist.signaturePresent
                        ? l10n.jobsSignaturePresent
                        : l10n.jobsSignatureMissing,
                    tone: checklist.signaturePresent
                        ? WorkshopStatusTone.success
                        : WorkshopStatusTone.warning,
                    icon: Icons.draw_outlined,
                  ),
                  WorkshopStatusBadge(
                    label: checklist.safetyCapApplied
                        ? (checklist.safetyCapReason ??
                              l10n.jobsSafetyCapApplied)
                        : l10n.jobsSafetyCapNotApplied,
                    tone: checklist.safetyCapApplied
                        ? WorkshopStatusTone.warning
                        : WorkshopStatusTone.neutral,
                    icon: Icons.shield_outlined,
                  ),
                ],
              ),
              SizedBox(height: spacing.md),
              WorkshopInlineNote(
                key: const Key('jobs-checklist-docs-note'),
                text: l10n.jobsDocsGeneratedAfterPublish,
                icon: Icons.description_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
