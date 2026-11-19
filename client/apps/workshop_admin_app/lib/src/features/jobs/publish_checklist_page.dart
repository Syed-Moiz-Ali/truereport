import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';
import 'package:workshop_admin_app/src/features/jobs/public_link_page.dart';
import 'package:workshop_admin_app/src/features/jobs/publish/checklist_items.dart';
import 'package:workshop_admin_app/src/features/jobs/publish/checklist_summary.dart';
import 'package:workshop_admin_app/src/features/jobs/publish/publish_panel.dart';
import 'package:workshop_admin_app/src/features/jobs/publish/publish_states.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_error_copy.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// The only client publish gate (M6). Publish requires the server checklist to
/// be ready AND consent to be granted; a `422 CONSENT_REQUIRED` is mapped to
/// the same honest copy instead of a generic failure.
class PublishChecklistPage extends ConsumerStatefulWidget {
  const PublishChecklistPage({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<PublishChecklistPage> createState() =>
      _PublishChecklistPageState();
}

class _PublishChecklistPageState extends ConsumerState<PublishChecklistPage> {
  bool _busy = false;
  bool _pdfDownload = true;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final checklist = ref.watch(publishChecklistProvider(widget.jobId));
    return Scaffold(
      backgroundColor: context.ws.canvas,
      body: SafeArea(
        child: Column(
          children: [
            JobPageTopBar(title: l10n.jobsPublishChecklist),
            Expanded(
              child: checklist.hasError && !checklist.hasValue
                  ? SingleChildScrollView(
                      padding: context.ws.pagePaddingOf(context),
                      child: WorkshopErrorState(
                        title: l10n.error,
                        body: jobErrorCopy(l10n, checklist.error!),
                        retryLabel: l10n.retryAction,
                        onRetry: () => ref.invalidate(
                          publishChecklistProvider(widget.jobId),
                        ),
                      ),
                    )
                  : checklist.when(
                      loading: () => Padding(
                        padding: context.ws.pagePaddingOf(context),
                        child: const WorkshopSkeleton(card: true, lines: 5),
                      ),
                      error: (error, _) => SingleChildScrollView(
                        padding: context.ws.pagePaddingOf(context),
                        child: WorkshopErrorState(
                          title: l10n.error,
                          body: jobErrorCopy(l10n, error),
                          retryLabel: l10n.retryAction,
                          onRetry: () => ref.invalidate(
                            publishChecklistProvider(widget.jobId),
                          ),
                        ),
                      ),
                      data: (value) => _content(context, value),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, PublishChecklist checklist) {
    final spacing = context.spacing;
    final canPublish = checklist.ready && checklist.consentGranted;
    final panel = PublishPanel(
      checklist: checklist,
      busy: _busy,
      pdfDownload: _pdfDownload,
      onPdfDownloadChanged: (value) => setState(() => _pdfDownload = value),
      onPublish: canPublish && !_busy ? _publish : null,
    );
    return WorkshopPageScroll(
      children: [
        if (_error != null) ...[
          PublishErrorBanner(message: _error!),
          SizedBox(height: spacing.lg),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 1000) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChecklistSummary(checklist: checklist),
                  SizedBox(height: spacing.lg),
                  ChecklistItems(items: checklist.items),
                  SizedBox(height: spacing.lg),
                  panel,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: ChecklistItems(items: checklist.items),
                ),
                SizedBox(width: spacing.xl),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChecklistSummary(checklist: checklist),
                      SizedBox(height: spacing.lg),
                      panel,
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _publish() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final link = await ref
          .read(adminApiProvider)
          .publishJob(widget.jobId, pdfDownloadEnabled: _pdfDownload);
      ref.invalidate(publishChecklistProvider(widget.jobId));
      ref.invalidate(publicLinkProvider(widget.jobId));
      ref.invalidate(cleanJobProvider(widget.jobId));
      ref.invalidate(cleanJobsProvider);
      ref.invalidate(cleanJobCountsProvider);
      if (!mounted) {
        return;
      }
      _toast(l10n.jobsPublished);
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => PublicLinkPage(jobId: link.jobId),
        ),
      );
    } on Object catch (error) {
      ref.invalidate(publishChecklistProvider(widget.jobId));
      if (mounted) {
        setState(() => _error = jobErrorCopy(l10n, error));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.ws.ink,
      ),
    );
  }
}
