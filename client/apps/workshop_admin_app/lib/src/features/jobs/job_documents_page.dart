import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/documents/document_row.dart';
import 'package:workshop_admin_app/src/features/jobs/documents/documents_states.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_error_copy.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// Generated report documents for the latest report version. Empty before a
/// publish is honest: the copy states documents are generated after publish.
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
    return Scaffold(
      backgroundColor: context.ws.canvas,
      body: SafeArea(
        child: Column(
          children: [
            JobPageTopBar(title: l10n.jobsDocumentsTitle),
            Expanded(
              child: documents.hasError && !documents.hasValue
                  ? SingleChildScrollView(
                      padding: context.ws.pagePaddingOf(context),
                      child: WorkshopErrorState(
                        title: l10n.error,
                        body: jobErrorCopy(l10n, documents.error!),
                        retryLabel: l10n.retryAction,
                        onRetry: () =>
                            ref.invalidate(jobDocumentsProvider(widget.jobId)),
                      ),
                    )
                  : documents.when(
                      loading: () => Padding(
                        padding: context.ws.pagePaddingOf(context),
                        child: const WorkshopSkeleton(card: true, lines: 4),
                      ),
                      error: (error, _) => SingleChildScrollView(
                        padding: context.ws.pagePaddingOf(context),
                        child: WorkshopErrorState(
                          title: l10n.error,
                          body: jobErrorCopy(l10n, error),
                          retryLabel: l10n.retryAction,
                          onRetry: () => ref.invalidate(
                            jobDocumentsProvider(widget.jobId),
                          ),
                        ),
                      ),
                      data: (items) => _content(context, items),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, List<JobDocument> items) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final banner = _error == null
        ? null
        : DocumentsErrorBanner(message: _error!);
    if (items.isEmpty) {
      return WorkshopPageScroll(
        children: [
          if (banner != null) ...[banner, SizedBox(height: spacing.lg)],
          WorkshopCard(
            child: WorkshopEmptyState(
              title: l10n.jobsDocumentsEmpty,
              body: l10n.jobsDocsGeneratedAfterPublish,
              icon: Icons.description_outlined,
            ),
          ),
        ],
      );
    }
    return WorkshopPageScroll(
      children: [
        if (banner != null) ...[banner, SizedBox(height: spacing.lg)],
        WorkshopCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0) const WorkshopDivider(),
                DocumentRow(
                  document: items[index],
                  busy: _busy,
                  onRetry: () => _retry(items[index]),
                  onCopy: () => _copy(items[index].downloadUrl!),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _retry(JobDocument document) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(adminApiProvider)
          .retryJobDocument(widget.jobId, document.documentTypeCode);
      ref.invalidate(jobDocumentsProvider(widget.jobId));
      _toast(l10n.jobsDocumentRetried);
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = jobErrorCopy(l10n, error));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _copy(String url) async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: url));
    _toast(l10n.linkCopied);
  }

  void _toast(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.ws.ink,
      ),
    );
  }
}
