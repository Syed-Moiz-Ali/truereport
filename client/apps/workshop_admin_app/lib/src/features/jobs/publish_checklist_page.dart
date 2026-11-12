import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/features/jobs/public_link_page.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

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
    return AppScaffold(
      appBar: AppBar(title: Text(l10n.jobsPublishChecklist)),
      body: ListView(
        padding: EdgeInsetsDirectional.all(context.spacing.lg),
        children: [
          SectionHeader(title: l10n.jobsPublishChecklist),
          if (_error != null) ...[
            JobInlineError(message: _error!),
            SizedBox(height: context.spacing.md),
          ],
          checklist.when(
            loading: () => const LoadingSkeleton(lines: 5),
            error: (error, _) => ErrorState(
              title: l10n.error,
              body: l10n.commonLoadFailed,
              retryLabel: l10n.retryAction,
              onRetry: () =>
                  ref.invalidate(publishChecklistProvider(widget.jobId)),
            ),
            data: (value) => _content(context, value),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, PublishChecklist checklist) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        JobPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: context.spacing.sm,
                runSpacing: context.spacing.sm,
                children: [
                  StatusChip(
                    key: const Key('jobs-checklist-ready-chip'),
                    label: checklist.ready
                        ? l10n.jobsChecklistReady
                        : l10n.jobsChecklistNotReady,
                    tone: checklist.ready
                        ? StatusTone.success
                        : StatusTone.danger,
                    icon: checklist.ready
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                  ),
                  StatusChip(
                    label:
                        '${l10n.jobsItemsAssessed}: '
                        '${formatNumber(context, checklist.itemsAssessed)} / '
                        '${formatNumber(context, checklist.itemsTotal)}',
                    tone: StatusTone.info,
                    icon: Icons.checklist_outlined,
                  ),
                  StatusChip(
                    label:
                        '${l10n.jobsScore}: '
                        '${formatScore(context, checklist.score)}',
                    tone: StatusTone.neutral,
                    icon: Icons.speed_outlined,
                  ),
                  StatusChip(
                    label:
                        '${l10n.jobsGrade}: '
                        '${checklist.gradeCode ?? l10n.commonNotAvailable}',
                    tone: StatusTone.success,
                    icon: Icons.grade_outlined,
                  ),
                  StatusChip(
                    label: checklist.consentGranted
                        ? l10n.jobsConsentGranted
                        : l10n.jobsConsentMissing,
                    tone: checklist.consentGranted
                        ? StatusTone.success
                        : StatusTone.danger,
                    icon: Icons.verified_user_outlined,
                  ),
                  StatusChip(
                    label: checklist.signaturePresent
                        ? l10n.jobsSignaturePresent
                        : l10n.jobsSignatureMissing,
                    tone: checklist.signaturePresent
                        ? StatusTone.success
                        : StatusTone.warning,
                    icon: Icons.draw_outlined,
                  ),
                  StatusChip(
                    label: checklist.documentsReady
                        ? l10n.jobsDocumentsReady
                        : l10n.jobsDocumentsNotReady,
                    tone: checklist.documentsReady
                        ? StatusTone.success
                        : StatusTone.warning,
                    icon: Icons.description_outlined,
                  ),
                  StatusChip(
                    label: checklist.safetyCapApplied
                        ? (checklist.safetyCapReason ??
                              l10n.jobsSafetyCapApplied)
                        : l10n.jobsSafetyCapNotApplied,
                    tone: checklist.safetyCapApplied
                        ? StatusTone.warning
                        : StatusTone.neutral,
                    icon: Icons.shield_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: context.spacing.md),
        for (final item in checklist.items)
          Padding(
            padding: EdgeInsetsDirectional.only(bottom: context.spacing.sm),
            child: JobPanel(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusChip(
                    key: Key('jobs-checklist-${item.code}'),
                    label: item.passed
                        ? l10n.jobsChecklistPassed
                        : l10n.jobsChecklistFailed,
                    tone: item.passed ? StatusTone.success : StatusTone.danger,
                    icon: item.passed
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                  ),
                  SizedBox(width: context.spacing.sm),
                  Expanded(
                    child: Text(
                      localizedText(
                        context,
                        en: item.messageEn,
                        ar: item.messageAr,
                      ),
                      style: context.texts.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(height: context.spacing.md),
        JobPanel(
          title: l10n.publish,
          icon: Icons.public_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.pdfDownload,
                      style: context.texts.bodyMedium,
                    ),
                  ),
                  Switch(
                    value: _pdfDownload,
                    onChanged: _busy
                        ? null
                        : (value) => setState(() => _pdfDownload = value),
                  ),
                ],
              ),
              SizedBox(height: context.spacing.sm),
              AppButton(
                key: const Key('jobs-publish-button'),
                label: l10n.jobsPublishNow,
                onPressed: checklist.ready && !_busy ? _publish : null,
                isLoading: _busy,
                icon: Icons.public_outlined,
                expand: true,
              ),
              if (!checklist.ready) ...[
                SizedBox(height: context.spacing.sm),
                Text(
                  l10n.jobsChecklistNotReady,
                  style: context.texts.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
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
      ref.invalidate(cleanJobCountsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.jobsPublished)));
        await Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute<void>(
            builder: (_) => PublicLinkPage(jobId: link.jobId),
          ),
        );
      }
    } on Object {
      if (mounted) {
        setState(() => _error = l10n.jobsPublishFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
