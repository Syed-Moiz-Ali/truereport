import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Checklist facts and the one option the publish call takes.
///
/// `documentsReady` is never rendered: it is a server constant and documents
/// only exist after publish (G-J5 / CR-6). The note states the real order of
/// events instead. The PDF toggle belongs here because it is part of what gets
/// published, not a separate decision.
class ChecklistSummary extends StatelessWidget {
  const ChecklistSummary({
    required this.checklist,
    required this.pdfDownload,
    required this.onPdfDownloadChanged,
    required this.busy,
    super.key,
  });

  final PublishChecklist checklist;
  final bool pdfDownload;
  final ValueChanged<bool> onPdfDownloadChanged;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
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
              SizedBox(height: spacing.md),
              const WorkshopDivider(),
              SizedBox(height: spacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.pdfDownload,
                      style: ws.bodyStrong.copyWith(color: ws.ink),
                    ),
                  ),
                  PublishOptionToggle(
                    value: pdfDownload,
                    onChanged: busy ? null : onPdfDownloadChanged,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A 44 px tappable, pill-styled toggle in the module's control language.
///
/// The earlier Material `Switch` had different geometry from every other
/// control on the page; this is a full-radius pill whose fill, icon and word
/// all carry the state, so it reads as on/off without relying on colour alone.
class PublishOptionToggle extends StatelessWidget {
  const PublishOptionToggle({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final enabled = onChanged != null;
    final duration = context.motionDuration(const Duration(milliseconds: 140));
    final fg = value ? ws.accent : ws.muted;
    return Semantics(
      button: true,
      enabled: enabled,
      toggled: value,
      label: l10n.pdfDownload,
      child: InkWell(
        onTap: enabled ? () => onChanged!(!value) : null,
        borderRadius: BorderRadius.circular(17),
        child: SizedBox(
          height: ws.touchTarget,
          child: Center(
            child: AnimatedContainer(
              duration: duration,
              curve: context.motion.enterCurve,
              height: 34,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: value ? ws.accentSoft : ws.surface,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: value ? ws.accent : ws.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    value ? Icons.check_circle : Icons.remove_circle_outline,
                    size: 15,
                    color: fg,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    value ? l10n.commonYes : l10n.commonNo,
                    style: ws.meta.copyWith(
                      color: fg,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
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
