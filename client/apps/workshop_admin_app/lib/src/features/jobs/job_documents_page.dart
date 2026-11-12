import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

class DocumentsPage extends ConsumerStatefulWidget {
  const DocumentsPage({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends ConsumerState<DocumentsPage> {
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final documents = ref.watch(jobDocumentsProvider(widget.jobId));
    return AppScaffold(
      appBar: AppBar(title: Text(l10n.jobsDocumentsTitle)),
      body: ListView(
        padding: EdgeInsetsDirectional.all(context.spacing.lg),
        children: [
          SectionHeader(title: l10n.jobsDocumentsTitle),
          if (_error != null) ...[
            JobInlineError(message: _error!),
            SizedBox(height: context.spacing.md),
          ],
          documents.when(
            loading: () => const LoadingSkeleton(lines: 4),
            error: (error, _) => ErrorState(
              title: l10n.error,
              body: l10n.commonLoadFailed,
              retryLabel: l10n.retryAction,
              onRetry: () => ref.invalidate(jobDocumentsProvider(widget.jobId)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return EmptyState(
                  title: l10n.jobsDocumentsEmpty,
                  body: '',
                  icon: Icons.description_outlined,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final document in items)
                    _document(context, document),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _document(BuildContext context, JobDocument document) {
    final l10n = AppLocalizations.of(context);
    final failed = document.status == 'FAILED';
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: context.spacing.sm),
      child: JobPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: context.spacing.sm,
              runSpacing: context.spacing.sm,
              children: [
                StatusChip(
                  label:
                      '${localizedText(context, en: document.nameEn, ar: document.nameAr)}'
                      ' (${document.language})',
                  tone: StatusTone.info,
                  icon: Icons.description_outlined,
                ),
                StatusChip(
                  label: document.status,
                  tone: failed ? StatusTone.danger : StatusTone.success,
                  icon: failed
                      ? Icons.error_outline
                      : Icons.check_circle_outline,
                ),
              ],
            ),
            SizedBox(height: context.spacing.sm),
            JobKeyValue(
              label: l10n.jobsDocumentType,
              value: document.documentTypeCode,
            ),
            JobKeyValue(
              label: l10n.jobsDocumentLanguage,
              value: document.language,
            ),
            JobKeyValue(
              label: l10n.jobsDocumentSize,
              value: formatBytes(context, document.bytes),
            ),
            if (document.generatedAt != null)
              JobKeyValue(
                label: l10n.jobsDocumentGeneratedAt,
                value: formatInstant(context, document.generatedAt),
              ),
            if (document.error != null)
              JobKeyValue(
                label: l10n.jobsDocumentError,
                value: document.error!,
              ),
            SizedBox(height: context.spacing.sm),
            Wrap(
              spacing: context.spacing.sm,
              runSpacing: context.spacing.sm,
              children: [
                if (failed)
                  AppButton(
                    key: Key('jobs-retry-document-${document.id}'),
                    label: l10n.jobsRetryDocument,
                    onPressed: _busy
                        ? null
                        : () => _retry(document.documentTypeCode),
                    icon: Icons.refresh,
                    variant: AppButtonVariant.tonal,
                  ),
                if (document.downloadUrl != null)
                  AppButton(
                    label: l10n.commonDownload,
                    onPressed: () => _copyDownload(document.downloadUrl!),
                    icon: Icons.download_outlined,
                    variant: AppButtonVariant.text,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _retry(String type) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(adminApiProvider)
          .retryJobDocument(widget.jobId, type);
      ref.invalidate(jobDocumentsProvider(widget.jobId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.jobsDocumentRetried)));
      }
    } on Object {
      if (mounted) {
        setState(() => _error = l10n.commonActionFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _copyDownload(String url) async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.linkCopied)));
    }
  }
}
