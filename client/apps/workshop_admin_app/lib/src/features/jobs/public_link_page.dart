import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_chrome.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_pills.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/features/jobs/publish_checklist_page.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/reference_status.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// The public share surface, in the dispatch document language.
///
/// Everything below the chrome is the same contract as before: the public-link
/// provider, the QR provider, the same copy/share/rotate/unpublish/revoke calls
/// with the same guards, the same token display and the same snackbars. The
/// layout is a status line, one pill per allowed action, then the link details
/// and the QR in a 5/4 split from 900 px (stacked below it).
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
    final t = UiStrings.of(context);
    final ws = context.ws;
    final width = MediaQuery.sizeOf(context).width;
    final link = ref.watch(publicLinkProvider(widget.jobId));
    final publicationStatuses = ref
        .watch(statusesProvider('publication'))
        .value;
    final qr = ref.watch(jobQrProvider(widget.jobId));
    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            JobTitleBar(
              title: t(WorkshopAdminKeys.jobsPublicLinkTitle),
              trailing: link.value == null
                  ? null
                  : _StatePill(
                      label: referenceStatusText(
                        publicationStatuses,
                        link.value!.status,
                      ),
                      tone: _pillTone(
                        referenceStatusTone(
                          publicationStatuses,
                          link.value!.status,
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: ws.pagePadding(width),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        if (_error != null) ...[
                          JobInlineError(message: _error!),
                          const SizedBox(height: 14),
                        ],
                        link.when(
                          loading: () =>
                              const WorkshopSkeleton(card: true, lines: 4),
                          error: (error, _) => WorkshopErrorState(
                            title: t(WorkshopAdminKeys.error),
                            body: t(WorkshopAdminKeys.commonLoadFailed),
                            retryLabel: t(WorkshopAdminKeys.retryAction),
                            onRetry: () => ref.invalidate(
                              publicLinkProvider(widget.jobId),
                            ),
                          ),
                          data: (value) => _content(context, value, qr),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    PublicLink link,
    AsyncValue<List<int>> qr,
  ) {
    final active = link.status == 'ACTIVE';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _actions(context, link, active),
        const SizedBox(height: 20),
        JobSplitColumns(
          leading: _linkSurface(context, link),
          trailing: _qrSurface(context, qr),
        ),
      ],
    );
  }

  Widget _actions(BuildContext context, PublicLink link, bool active) {
    final t = UiStrings.of(context);
    final url = link.publicUrl;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        JobPillButton(
          label: t(WorkshopAdminKeys.copyLink),
          icon: Icons.copy,
          variant: active ? JobPillVariant.filled : JobPillVariant.outline,
          onPressed: _busy || url == null ? null : () => _copy(url),
        ),
        JobPillButton(
          key: const Key('jobs-share-button'),
          label: t(WorkshopAdminKeys.jobsShare),
          icon: Icons.share_outlined,
          variant: JobPillVariant.outline,
          onPressed: _busy || url == null ? null : () => _share(url),
        ),
        if (!active)
          JobPillButton(
            key: const Key('jobs-publish-checklist-button'),
            label: t(WorkshopAdminKeys.jobsOpenPublishChecklist),
            icon: Icons.playlist_add_check_outlined,
            onPressed: _busy ? null : _openChecklist,
          ),
        if (active)
          JobPillButton(
            label: t(WorkshopAdminKeys.jobsRotateToken),
            icon: Icons.autorenew,
            variant: JobPillVariant.outline,
            onPressed: _busy ? null : _rotate,
          ),
        if (active)
          JobPillButton(
            key: const Key('jobs-unpublish-button'),
            label: t(WorkshopAdminKeys.jobsUnpublish),
            icon: Icons.visibility_off_outlined,
            variant: JobPillVariant.ghost,
            onPressed: _busy ? null : _unpublish,
          ),
        if (link.status != 'REVOKED')
          JobPillButton(
            key: const Key('jobs-revoke-button'),
            label: t(WorkshopAdminKeys.jobsRevoke),
            icon: Icons.link_off,
            variant: JobPillVariant.danger,
            onPressed: _busy ? null : _revoke,
          ),
      ],
    );
  }

  /// The link itself is the focal point: one surface, label above, the URL in
  /// wrapping tabular-free text, then the facts a support call needs.
  Widget _linkSurface(BuildContext context, PublicLink link) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    final url = link.publicUrl;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ws.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.link, size: 16, color: ws.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t(WorkshopAdminKeys.jobsPublicUrl).toUpperCase(),
                  style: ws.eyebrow.copyWith(color: ws.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            url ?? t(WorkshopAdminKeys.commonNotAvailable),
            textDirection: TextDirection.ltr,
            style: ws.bodyStrong.copyWith(
              fontSize: 16,
              height: 1.5,
              color: url == null ? ws.muted : ws.ink,
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: ws.border),
          const SizedBox(height: 12),
          _Fact(
            label: t(WorkshopAdminKeys.jobsPublicToken),
            value: link.token ?? t(WorkshopAdminKeys.commonNotAvailable),
            valueDirection: TextDirection.ltr,
            selectable: true,
          ),
          _Fact(
            label: t(WorkshopAdminKeys.pdfDownload),
            value: link.pdfDownloadEnabled
                ? t(WorkshopAdminKeys.commonYes)
                : t(WorkshopAdminKeys.commonNo),
          ),
          if (link.activatedAt != null)
            _Fact(
              label: t(WorkshopAdminKeys.jobsActivatedAt),
              value: formatInstant(context, link.activatedAt),
            ),
          if (link.revokedAt != null)
            _Fact(
              label: t(WorkshopAdminKeys.jobsRevokedAt),
              value: formatInstant(context, link.revokedAt),
            ),
          if (link.revocationReason != null)
            _Fact(
              label: t(WorkshopAdminKeys.jobsRevocationReason),
              value: link.revocationReason!,
            ),
        ],
      ),
    );
  }

  Widget _qrSurface(BuildContext context, AsyncValue<List<int>> qr) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ws.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t(WorkshopAdminKeys.jobsQrTitle).toUpperCase(),
            style: ws.eyebrow.copyWith(color: ws.muted),
          ),
          const SizedBox(height: 14),
          qr.when(
            loading: () => _qrFrame(context, const WorkshopSkeleton(lines: 3)),
            error: (error, _) => _qrPlaceholder(context),
            data: (bytes) {
              if (bytes.isEmpty) {
                return _qrPlaceholder(context);
              }
              return _qrFrame(
                context,
                Image.memory(
                  Uint8List.fromList(bytes),
                  fit: BoxFit.contain,
                  semanticLabel: t(WorkshopAdminKeys.jobsQrTitle),
                  errorBuilder: (context, error, stackTrace) =>
                      _qrPlaceholder(context),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// A fixed square plate so the QR region is composed even before the image
  /// resolves, instead of a small icon floating in an empty card.
  Widget _qrFrame(BuildContext context, Widget child) {
    final ws = context.ws;
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: AspectRatio(
          aspectRatio: 1,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ws.canvas,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ws.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _qrPlaceholder(BuildContext context) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    return _qrFrame(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_2_outlined, size: 44, color: ws.muted),
          const SizedBox(height: 10),
          Text(
            t(WorkshopAdminKeys.jobsQrUnavailable),
            textAlign: TextAlign.center,
            style: ws.meta.copyWith(color: ws.muted),
          ),
        ],
      ),
    );
  }

  Future<void> _copy(String url) async {
    final t = UiStrings.of(context);
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(WorkshopAdminKeys.linkCopied))));
    }
  }

  Future<void> _share(String url) async {
    final t = UiStrings.of(context);
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(WorkshopAdminKeys.linkCopied))));
    }
  }

  /// Publication has one gate: the checklist (M6). A non-active link routes
  /// there; this page never publishes on its own.
  void _openChecklist() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublishChecklistPage(jobId: widget.jobId),
      ),
    );
  }

  Future<void> _rotate() async {
    final t = UiStrings.of(context);
    await _run(() async {
      await ref.read(adminApiProvider).rotateJobToken(widget.jobId);
      ref.invalidate(publicLinkProvider(widget.jobId));
      ref.invalidate(jobQrProvider(widget.jobId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(WorkshopAdminKeys.jobsTokenRotated))),
        );
      }
    });
  }

  Future<void> _unpublish() async {
    final t = UiStrings.of(context);
    final reason = await showJobReasonSheet(
      context,
      title: t(WorkshopAdminKeys.jobsUnpublish),
      label: t(WorkshopAdminKeys.jobsUnpublishReason),
      confirmLabel: t(WorkshopAdminKeys.jobsUnpublish),
    );
    if (reason == null || !mounted) {
      return;
    }
    await _run(() async {
      await ref.read(adminApiProvider).unpublishJob(widget.jobId, reason);
      ref.invalidate(publicLinkProvider(widget.jobId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(WorkshopAdminKeys.jobsLinkUnpublished))),
        );
      }
    });
  }

  Future<void> _revoke() async {
    final t = UiStrings.of(context);
    final reason = await showJobReasonSheet(
      context,
      title: t(WorkshopAdminKeys.jobsRevoke),
      label: t(WorkshopAdminKeys.jobsRevokeReason),
      confirmLabel: t(WorkshopAdminKeys.jobsRevoke),
    );
    if (reason == null || !mounted) {
      return;
    }
    await _run(() async {
      await ref.read(adminApiProvider).revokeJob(widget.jobId, reason);
      ref.invalidate(publicLinkProvider(widget.jobId));
      ref.invalidate(jobQrProvider(widget.jobId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(WorkshopAdminKeys.linkRevoked))),
        );
      }
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    final t = UiStrings.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on Object {
      if (mounted) {
        setState(() => _error = t(WorkshopAdminKeys.commonActionFailed));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

enum _PillTone { success, warning, danger, neutral }

_PillTone _pillTone(WorkshopStatusTone tone) => switch (tone) {
  WorkshopStatusTone.success => _PillTone.success,
  WorkshopStatusTone.danger => _PillTone.danger,
  WorkshopStatusTone.accent || WorkshopStatusTone.warning => _PillTone.warning,
  WorkshopStatusTone.neutral => _PillTone.neutral,
};

/// State pill in the module's full-radius badge geometry. Colour is paired
/// with the label, never used alone.
class _StatePill extends StatelessWidget {
  const _StatePill({required this.label, required this.tone});

  final String label;
  final _PillTone tone;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final (Color bg, Color fg) = switch (tone) {
      _PillTone.success => (ws.successSoft, ws.success),
      _PillTone.warning => (ws.warningSoft, ws.warning),
      _PillTone.danger => (ws.dangerSoft, ws.danger),
      _PillTone.neutral => (ws.canvas, ws.muted),
    };
    return Semantics(
      label: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(context.radii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: ws.eyebrow.copyWith(color: fg, fontSize: 10.5)),
          ],
        ),
      ),
    );
  }
}

/// Label above value. Values that are identifiers are pinned LTR and can be
/// selected; nothing that identifies the link is ellipsized.
class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.value,
    this.valueDirection,
    this.selectable = false,
  });

  final String label;
  final String value;
  final TextDirection? valueDirection;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final style = ws.body.copyWith(color: ws.ink);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: ws.eyebrow.copyWith(color: ws.muted)),
          const SizedBox(height: 3),
          if (selectable)
            SelectableText(value, textDirection: valueDirection, style: style)
          else
            Text(value, textDirection: valueDirection, style: style),
        ],
      ),
    );
  }
}
