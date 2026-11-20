import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_fact.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_fact_grid.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// One document row inside the shared surface. Status is localized, a null
/// size reads `—` (G-J23), and the action is a truthful "Copy link" because
/// no client content endpoint exists (G-J6 / F16).
class DocumentRow extends StatelessWidget {
  const DocumentRow({
    required this.document,
    required this.busy,
    required this.onRetry,
    required this.onCopy,
    super.key,
  });

  final JobDocument document;
  final bool busy;
  final VoidCallback onRetry;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final failed = document.status == 'FAILED';
    final name = localizedText(
      context,
      en: document.nameEn,
      ar: document.nameAr,
    );
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name.isEmpty ? l10n.commonNotAvailable : name,
                  style: ws.cardTitle.copyWith(color: ws.ink),
                ),
              ),
              SizedBox(width: spacing.sm),
              WorkshopStatusBadge(
                key: Key('jobs-document-status-${document.id}'),
                label: jobDocumentStatusLabel(l10n, document.status),
                tone: jobDocumentStatusTone(document.status),
                icon: jobDocumentStatusIcon(document.status),
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
          JobFactGrid(
            facts: [
              JobFact(
                label: l10n.jobsDocumentLanguage,
                value: _languageLabel(l10n, document.language),
                valueDirection: TextDirection.ltr,
              ),
              JobFact(
                label: l10n.jobsDocumentSize,
                value: document.bytes == null
                    ? '—'
                    : formatBytes(context, document.bytes!),
              ),
            ],
          ),
          if (document.error != null) ...[
            SizedBox(height: spacing.sm),
            Text(
              '${l10n.jobsDocumentError}: ${document.error}',
              style: ws.body.copyWith(color: ws.danger),
            ),
          ],
          SizedBox(height: spacing.sm),
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.sm,
            children: [
              if (failed)
                WorkshopButton(
                  key: Key('jobs-retry-document-${document.id}'),
                  label: l10n.jobsRetryDocument,
                  icon: Icons.refresh,
                  variant: WorkshopButtonVariant.secondary,
                  onPressed: busy ? null : onRetry,
                ),
              if (document.downloadUrl != null)
                WorkshopButton(
                  key: Key('jobs-copy-document-${document.id}'),
                  label: l10n.copyLink,
                  icon: Icons.link,
                  variant: WorkshopButtonVariant.ghost,
                  onPressed: busy ? null : onCopy,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Localized document status. An unknown value reads "Not available", never
/// the raw enum (inventory §6.1 rule 1).
String jobDocumentStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'READY' => l10n.reportReady,
      'FAILED' => l10n.reportFailed,
      'GENERATING' => l10n.generating,
      'PENDING' => l10n.technicianQueued,
      _ => l10n.commonNotAvailable,
    };

WorkshopStatusTone jobDocumentStatusTone(String status) => switch (status) {
  'READY' => WorkshopStatusTone.success,
  'FAILED' => WorkshopStatusTone.danger,
  'GENERATING' => WorkshopStatusTone.warning,
  _ => WorkshopStatusTone.neutral,
};

IconData jobDocumentStatusIcon(String status) => switch (status) {
  'READY' => Icons.check_circle_outline,
  'FAILED' => Icons.error_outline,
  'GENERATING' => Icons.hourglass_top_outlined,
  _ => Icons.schedule_outlined,
};

String _languageLabel(AppLocalizations l10n, String language) =>
    switch (language) {
      'en' => l10n.languageEnglish,
      _ => l10n.commonNotAvailable,
    };
