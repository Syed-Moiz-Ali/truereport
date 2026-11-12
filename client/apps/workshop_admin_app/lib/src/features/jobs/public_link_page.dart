import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

class PublicLinkPage extends ConsumerStatefulWidget {
  const PublicLinkPage({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<PublicLinkPage> createState() => _PublicLinkPageState();
}

class _PublicLinkPageState extends ConsumerState<PublicLinkPage> {
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final link = ref.watch(publicLinkProvider(widget.jobId));
    final qr = ref.watch(jobQrProvider(widget.jobId));
    return AppScaffold(
      appBar: AppBar(title: Text(l10n.jobsPublicLinkTitle)),
      body: ListView(
        padding: EdgeInsetsDirectional.all(context.spacing.lg),
        children: [
          SectionHeader(title: l10n.jobsPublicLinkTitle),
          if (_error != null) ...[
            JobInlineError(message: _error!),
            SizedBox(height: context.spacing.md),
          ],
          link.when(
            loading: () => const LoadingSkeleton(lines: 4),
            error: (error, _) => ErrorState(
              title: l10n.error,
              body: l10n.commonLoadFailed,
              retryLabel: l10n.retryAction,
              onRetry: () => ref.invalidate(publicLinkProvider(widget.jobId)),
            ),
            data: (value) => _content(context, value, qr),
          ),
        ],
      ),
    );
  }

  Widget _content(
    BuildContext context,
    PublicLink link,
    AsyncValue<List<int>> qr,
  ) {
    final l10n = AppLocalizations.of(context);
    final active = link.status == 'ACTIVE';
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
                    label: link.status,
                    tone: active
                        ? StatusTone.success
                        : link.status == 'REVOKED'
                        ? StatusTone.danger
                        : StatusTone.warning,
                    icon: active ? Icons.link : Icons.link_off,
                  ),
                  StatusChip(
                    label: link.pdfDownloadEnabled
                        ? l10n.pdfDownload
                        : l10n.commonNotAvailable,
                    tone: link.pdfDownloadEnabled
                        ? StatusTone.success
                        : StatusTone.neutral,
                    icon: Icons.picture_as_pdf_outlined,
                  ),
                ],
              ),
              SizedBox(height: context.spacing.md),
              JobKeyValue(
                label: l10n.jobsPublicUrl,
                value: link.publicUrl ?? l10n.commonNotAvailable,
                valueDirection: TextDirection.ltr,
              ),
              JobKeyValue(
                label: l10n.jobsPublicToken,
                value: link.token ?? l10n.commonNotAvailable,
                valueDirection: TextDirection.ltr,
              ),
              if (link.activatedAt != null)
                JobKeyValue(
                  label: l10n.jobsActivatedAt,
                  value: formatInstant(context, link.activatedAt),
                ),
              if (link.revokedAt != null)
                JobKeyValue(
                  label: l10n.jobsRevokedAt,
                  value: formatInstant(context, link.revokedAt),
                ),
              if (link.revocationReason != null)
                JobKeyValue(
                  label: l10n.jobsRevocationReason,
                  value: link.revocationReason!,
                ),
              if (link.publicUrl != null) ...[
                SizedBox(height: context.spacing.sm),
                SelectableText(
                  link.publicUrl!,
                  textDirection: TextDirection.ltr,
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: context.spacing.md),
        Wrap(
          spacing: context.spacing.sm,
          runSpacing: context.spacing.sm,
          children: [
            AppButton(
              label: l10n.copyLink,
              onPressed: _busy || link.publicUrl == null
                  ? null
                  : () => _copy(link.publicUrl!),
              icon: Icons.copy,
              variant: AppButtonVariant.tonal,
            ),
            AppButton(
              key: const Key('jobs-share-button'),
              label: l10n.jobsShare,
              onPressed: _busy || link.publicUrl == null
                  ? null
                  : () => _share(link.publicUrl!),
              icon: Icons.share_outlined,
              variant: AppButtonVariant.tonal,
            ),
            if (!active)
              AppButton(
                key: const Key('jobs-publish-link-button'),
                label: l10n.jobsPublishNow,
                onPressed: _busy ? null : _publish,
                icon: Icons.public_outlined,
                variant: AppButtonVariant.tonal,
              ),
            if (active)
              AppButton(
                label: l10n.jobsRotateToken,
                onPressed: _busy ? null : _rotate,
                icon: Icons.autorenew,
                variant: AppButtonVariant.tonal,
              ),
            if (active)
              AppButton(
                key: const Key('jobs-unpublish-button'),
                label: l10n.jobsUnpublish,
                onPressed: _busy ? null : _unpublish,
                icon: Icons.visibility_off_outlined,
                variant: AppButtonVariant.text,
              ),
            if (link.status != 'REVOKED')
              AppButton(
                key: const Key('jobs-revoke-button'),
                label: l10n.jobsRevoke,
                onPressed: _busy ? null : _revoke,
                icon: Icons.link_off,
                variant: AppButtonVariant.text,
              ),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        SectionHeader(title: l10n.jobsQrTitle),
        JobPanel(
          child: qr.when(
            loading: () => const LoadingSkeleton(lines: 3),
            error: (error, _) => _qrPlaceholder(context),
            data: (bytes) {
              if (bytes.isEmpty) {
                return _qrPlaceholder(context);
              }
              return Align(
                alignment: Alignment.center,
                child: FractionallySizedBox(
                  widthFactor: 0.7,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.memory(
                      Uint8List.fromList(bytes),
                      fit: BoxFit.contain,
                      semanticLabel: l10n.jobsQrTitle,
                      errorBuilder: (context, error, stackTrace) =>
                          _qrPlaceholder(context),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _qrPlaceholder(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.all(context.spacing.lg),
      child: Column(
        children: [
          Icon(
            Icons.qr_code_2_outlined,
            size: context.sizing.emptyArt,
            color: context.colors.onSurfaceVariant,
          ),
          SizedBox(height: context.spacing.sm),
          Text(
            l10n.jobsQrUnavailable,
            style: context.texts.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copy(String url) async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.linkCopied)));
    }
  }

  Future<void> _share(String url) async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.linkCopied)));
    }
  }

  Future<void> _publish() async {
    await _run(() async {
      await ref
          .read(adminApiProvider)
          .publishJob(widget.jobId, pdfDownloadEnabled: true);
      ref.invalidate(publicLinkProvider(widget.jobId));
      ref.invalidate(cleanJobProvider(widget.jobId));
      ref.invalidate(cleanJobCountsProvider);
    });
  }

  Future<void> _rotate() async {
    final l10n = AppLocalizations.of(context);
    await _run(() async {
      await ref.read(adminApiProvider).rotateJobToken(widget.jobId);
      ref.invalidate(publicLinkProvider(widget.jobId));
      ref.invalidate(jobQrProvider(widget.jobId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.jobsTokenRotated)));
      }
    });
  }

  Future<void> _unpublish() async {
    final l10n = AppLocalizations.of(context);
    final reason = await showJobReasonSheet(
      context,
      title: l10n.jobsUnpublish,
      label: l10n.jobsUnpublishReason,
      confirmLabel: l10n.jobsUnpublish,
    );
    if (reason == null || !mounted) {
      return;
    }
    await _run(() async {
      await ref.read(adminApiProvider).unpublishJob(widget.jobId, reason);
      ref.invalidate(publicLinkProvider(widget.jobId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.jobsLinkUnpublished)));
      }
    });
  }

  Future<void> _revoke() async {
    final l10n = AppLocalizations.of(context);
    final reason = await showJobReasonSheet(
      context,
      title: l10n.jobsRevoke,
      label: l10n.jobsRevokeReason,
      confirmLabel: l10n.jobsRevoke,
    );
    if (reason == null || !mounted) {
      return;
    }
    await _run(() async {
      await ref.read(adminApiProvider).revokeJob(widget.jobId, reason);
      ref.invalidate(publicLinkProvider(widget.jobId));
      ref.invalidate(jobQrProvider(widget.jobId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.linkRevoked)));
      }
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
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
}
