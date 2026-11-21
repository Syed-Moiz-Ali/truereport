import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/reference_status.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_fact.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_fact_grid.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// One document row inside the shared surface. Status is localized, a null
/// size reads `—` (G-J23), and the action is a truthful "Copy link" because
/// no client content endpoint exists (G-J6 / F16).
class DocumentRow extends ConsumerWidget {
  const DocumentRow({
    required this.document,
    required this.languageLabel,
    required this.busy,
    required this.onRetry,
    required this.onCopy,
    super.key,
  });

  final JobDocument document;

  /// Registry-resolved label for [document]'s language, supplied by the page.
  final String languageLabel;

  final bool busy;
  final VoidCallback onRetry;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final statuses = ref.watch(statusesProvider('document')).value;
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
                  name.isEmpty ? t(WorkshopAdminKeys.commonNotAvailable) : name,
                  style: ws.cardTitle.copyWith(color: ws.ink),
                ),
              ),
              SizedBox(width: spacing.sm),
              WorkshopStatusBadge(
                key: Key('jobs-document-status-${document.id}'),
                label: referenceStatusText(statuses, document.status),
                tone: referenceStatusTone(statuses, document.status),
                icon: jobDocumentStatusIcon(document.status),
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
          JobFactGrid(
            facts: [
              JobFact(
                label: t(WorkshopAdminKeys.jobsDocumentLanguage),
                value: languageLabel,
                valueDirection: TextDirection.ltr,
              ),
              JobFact(
                label: t(WorkshopAdminKeys.jobsDocumentSize),
                value: document.bytes == null
                    ? '—'
                    : formatBytes(context, document.bytes!),
              ),
            ],
          ),
          if (document.error != null) ...[
            SizedBox(height: spacing.sm),
            Text(
              '${t(WorkshopAdminKeys.jobsDocumentError)}: ${document.error}',
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
                  label: t(WorkshopAdminKeys.jobsRetryDocument),
                  icon: Icons.refresh,
                  variant: WorkshopButtonVariant.secondary,
                  onPressed: busy ? null : onRetry,
                ),
              if (document.downloadUrl != null)
                WorkshopButton(
                  key: Key('jobs-copy-document-${document.id}'),
                  label: t(WorkshopAdminKeys.copyLink),
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

IconData jobDocumentStatusIcon(String status) => switch (status) {
  'READY' => Icons.check_circle_outline,
  'FAILED' => Icons.error_outline,
  'GENERATING' => Icons.hourglass_top_outlined,
  _ => Icons.schedule_outlined,
};
