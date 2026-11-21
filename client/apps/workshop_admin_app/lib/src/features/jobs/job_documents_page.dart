import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_pills.dart';
import 'package:workshop_admin_app/src/features/jobs/documents/document_row.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_error_copy.dart';
import 'package:workshop_admin_app/src/features/reports/report_language_options.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// Generated report documents for the latest report version.
///
/// Same provider, same retry and copy calls as before; the page now uses the
/// Dispatch chrome (bar, identity-free header, one surface) and pill actions.
/// Empty stays honest: documents only exist after a publish.
class DocumentsPage extends ConsumerStatefulWidget {
  const DocumentsPage({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends ConsumerState<DocumentsPage> {
  bool _busy = false;
  String? _error;

  String get _reference =>
      ref.watch(cleanJobProvider(widget.jobId)).value?.reference ?? '';

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    final width = MediaQuery.sizeOf(context).width;
    final documents = ref.watch(jobDocumentsProvider(widget.jobId));
    final languages = ref.watch(workshopLanguagesProvider).asData?.value;

    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: ws.topBarHeight,
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: ws.pageGutter(width),
              ),
              decoration: BoxDecoration(
                color: ws.surface,
                border: BorderDirectional(bottom: BorderSide(color: ws.border)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
                  child: Row(
                    children: [
                      WorkshopIconButton(
                        icon: Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_forward
                            : Icons.arrow_back,
                        semanticLabel: t(WorkshopAdminKeys.commonBack),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t(WorkshopAdminKeys.jobsDocumentsTitle),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ws.bodyStrong.copyWith(color: ws.ink),
                        ),
                      ),
                      if (_reference.isNotEmpty)
                        Text(
                          _reference,
                          style: ws.meta.copyWith(
                            color: ws.muted,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: documents.hasError && !documents.hasValue
                  ? _errorState(context, jobErrorCopy(t, documents.error!))
                  : documents.when(
                      loading: () => SingleChildScrollView(
                        padding: ws.pagePadding(width),
                        child: const WorkshopSkeleton(card: true, lines: 4),
                      ),
                      error: (error, _) =>
                          _errorState(context, jobErrorCopy(t, error)),
                      data: (items) => _content(context, items, languages),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context, String message) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    return SingleChildScrollView(
      padding: ws.pagePadding(MediaQuery.sizeOf(context).width),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: WorkshopErrorState(
            title: t(WorkshopAdminKeys.error),
            body: message,
            retryLabel: t(WorkshopAdminKeys.retryAction),
            onRetry: () => ref.invalidate(jobDocumentsProvider(widget.jobId)),
          ),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    List<JobDocument> items,
    List<WorkshopLanguage>? languages,
  ) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    final width = MediaQuery.sizeOf(context).width;
    return SingleChildScrollView(
      padding: ws.pagePadding(width),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                t(WorkshopAdminKeys.jobsDocumentsTitle),
                style: ws.pageTitle.copyWith(
                  fontSize: width < 520 ? 26 : 30,
                  letterSpacing: -0.6,
                  color: ws.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _error ?? t(WorkshopAdminKeys.jobsDocsGeneratedAfterPublish),
                style: ws.meta.copyWith(
                  color: _error == null ? ws.muted : ws.danger,
                ),
              ),
              const SizedBox(height: 18),
              if (items.isEmpty)
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 40, 24, 40),
                  decoration: BoxDecoration(
                    color: ws.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: ws.border),
                  ),
                  child: Column(
                    children: [
                      const JobGlyph(size: 52),
                      const SizedBox(height: 16),
                      Text(
                        t(WorkshopAdminKeys.jobsDocumentsEmpty),
                        textAlign: TextAlign.center,
                        style: ws.sectionTitle.copyWith(color: ws.ink),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t(WorkshopAdminKeys.jobsDocsGeneratedAfterPublish),
                        textAlign: TextAlign.center,
                        style: ws.body.copyWith(color: ws.muted),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: ws.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: ws.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < items.length; index++) ...[
                        if (index > 0) Container(height: 1, color: ws.border),
                        DocumentRow(
                          document: items[index],
                          languageLabel:
                              resolvedLanguageLabel(
                                languages,
                                items[index].language,
                              ) ??
                              t(WorkshopAdminKeys.commonNotAvailable),
                          busy: _busy,
                          onRetry: () => _retry(items[index]),
                          onCopy: () => _copy(items[index].downloadUrl!),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _retry(JobDocument document) async {
    final t = UiStrings.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(adminApiProvider)
          .retryJobDocument(widget.jobId, document.documentTypeCode);
      ref.invalidate(jobDocumentsProvider(widget.jobId));
      _toast(t(WorkshopAdminKeys.jobsDocumentRetried));
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = jobErrorCopy(t, error));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _copy(String url) async {
    final t = UiStrings.of(context);
    await Clipboard.setData(ClipboardData(text: url));
    _toast(t(WorkshopAdminKeys.linkCopied));
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
