import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/report_pdf_saver.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import 'report_actions.dart';
import 'report_chrome.dart';
import 'report_distribution.dart';
import 'report_sheet.dart';

class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  bool _busy = false;
  String? _publicUrl;

  static const double _canvasMax = 1176;
  static const double _errorMax = 560;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final report = ref.watch(reportProvider(widget.jobId));
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final data = report.asData?.value;
    final reference = (data?.reportNumber ?? '').trim().isEmpty
        ? l10n.report
        : data!.reportNumber;

    return Scaffold(
      backgroundColor: context.ws.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReportTopBar(
            reference: reference,
            isRtl: isRtl,
            reportReady: data?.reportReady ?? false,
            isBusy: _busy,
            onBack: () => Navigator.of(context).maybePop(),
            onRefresh: () => ref.invalidate(reportProvider(widget.jobId)),
            onDownload: _busy ? null : _downloadPdf,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: report.when(
                loading: () => _loading(context),
                error: (error, _) => _error(context, l10n),
                data: (value) => _body(context, value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loading(BuildContext context) {
    final spacing = context.spacing;
    return _scroll(
      context,
      child: Padding(
        padding: EdgeInsetsDirectional.only(bottom: spacing.xxl),
        child: const ReportCanvas(
          sheet: ReportSheetSkeleton(),
          stub: ReportStubSkeleton(),
        ),
      ),
    );
  }

  Widget _error(BuildContext context, AppLocalizations l10n) {
    final spacing = context.spacing;
    return _scroll(
      context,
      child: Padding(
        padding: EdgeInsetsDirectional.only(bottom: spacing.xxl),
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _errorMax),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                WorkshopErrorState(
                  title: l10n.error,
                  body: l10n.reportUnavailable,
                  retryLabel: l10n.retryAction,
                  onRetry: () => ref.invalidate(reportProvider(widget.jobId)),
                ),
                SizedBox(height: spacing.md),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ReportActionButton(
                    label: l10n.commonBack,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_forward
                        : Icons.arrow_back,
                    variant: ReportActionVariant.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ReportAdmin report) {
    final spacing = context.spacing;
    final ready = report.reportReady;
    final canPop = Navigator.of(context).canPop();
    final deliveries = ref.watch(reportDeliveriesProvider(widget.jobId));

    return _scroll(
      context,
      scrollKey: const Key('report-scroll'),
      child: Padding(
        padding: EdgeInsetsDirectional.only(bottom: spacing.xxl),
        child: ReportCanvas(
          sheet: ReportSheet(
            report: report,
            canPop: canPop,
            isBusy: _busy,
            onRetry: _retry,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          stub: ready
              ? ReportDistribution(
                  report: report,
                  deliveries: deliveries,
                  publicUrl: _publicUrl ?? report.publicUrl,
                  isBusy: _busy,
                  onCopy: () => _copy(_publicUrl ?? report.publicUrl),
                  onCreateLink: _activate,
                  onRevoke: _revoke,
                  onSend: _send,
                  onRetryDelivery: _retryDelivery,
                  onTogglePdf: () => _togglePdf(report.pdfDownloadEnabled),
                )
              : null,
        ),
      ),
    );
  }

  Widget _scroll(
    BuildContext context, {
    required Widget child,
    Key? scrollKey,
  }) {
    return SingleChildScrollView(
      key: scrollKey,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: context.ws.pagePaddingOf(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _canvasMax),
          child: child,
        ),
      ),
    );
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    var channel = 'WHATSAPP';
    var language = 'en';
    final confirmed = await showAppBottomSheet<bool>(
      context,
      child: StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(title: l10n.sendReportTitle),
              Text(l10n.deliveryChannel, style: context.texts.bodySmall),
              for (final option in [
                ('WHATSAPP', l10n.channelWhatsapp),
                ('SMS', l10n.channelSms),
                ('EMAIL', l10n.channelEmail),
              ])
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    bottom: context.spacing.xs,
                  ),
                  child: AppSelectableText(
                    label: option.$2,
                    selected: channel == option.$1,
                    onTap: () => setSheetState(() => channel = option.$1),
                  ),
                ),
              SizedBox(height: context.spacing.sm),
              Text(l10n.deliveryLanguage, style: context.texts.bodySmall),
              for (final option in [('en', l10n.english), ('ar', l10n.arabic)])
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    bottom: context.spacing.xs,
                  ),
                  child: AppSelectableText(
                    label: option.$2,
                    selected: language == option.$1,
                    onTap: () => setSheetState(() => language = option.$1),
                  ),
                ),
              SizedBox(height: context.spacing.lg),
              AppButton(
                label: l10n.sendReport,
                onPressed: () => Navigator.of(context).pop(true),
                icon: Icons.send_outlined,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await _run(() async {
      await ref
          .read(adminApiProvider)
          .sendDelivery(
            widget.jobId,
            channel: channel,
            language: language,
            idempotencyKey: _newDeliveryKey('send'),
          );
      ref.invalidate(reportDeliveriesProvider(widget.jobId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.deliveryQueued)));
      }
    });
  }

  Future<void> _retryDelivery(ReportDelivery item) async {
    final l10n = AppLocalizations.of(context);
    await _run(() async {
      await ref
          .read(adminApiProvider)
          .retryDelivery(
            widget.jobId,
            item.id,
            idempotencyKey: _newDeliveryKey('retry-${item.id}'),
          );
      ref.invalidate(reportDeliveriesProvider(widget.jobId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.deliveryQueued)));
      }
    });
  }

  String _newDeliveryKey(String prefix) =>
      'admin-$prefix-${DateTime.now().microsecondsSinceEpoch}';

  Future<void> _retry() async {
    final l10n = AppLocalizations.of(context);
    await _run(() async {
      await ref.read(adminApiProvider).retryReport(widget.jobId);
      ref.invalidate(reportProvider(widget.jobId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.reportStatus)));
      }
    });
  }

  Future<void> _activate() async {
    final l10n = AppLocalizations.of(context);
    await _run(() async {
      final result = await ref
          .read(adminApiProvider)
          .activateReportLink(widget.jobId);
      setState(() => _publicUrl = result.publicUrl);
      ref.invalidate(reportProvider(widget.jobId));
      if (mounted && result.publicUrl != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.copyLink)));
      }
    });
  }

  Future<void> _revoke() async {
    final l10n = AppLocalizations.of(context);
    var reason = 'PRIVACY';
    final note = TextEditingController();
    final confirmed = await showAppBottomSheet<bool>(
      context,
      child: StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(title: l10n.deactivateLink),
              for (final code in const [
                'PRIVACY',
                'SECURITY',
                'LEGAL',
                'CUSTOMER_REQUEST',
                'OTHER',
              ])
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    bottom: context.spacing.xs,
                  ),
                  child: AppSelectableText(
                    label: code,
                    selected: reason == code,
                    onTap: () => setState(() => reason = code),
                  ),
                ),
              AppTextField(controller: note, label: l10n.deactivateReason),
              SizedBox(height: context.spacing.lg),
              AppButton(
                label: l10n.deactivate,
                onPressed: () => Navigator.of(context).pop(true),
                icon: Icons.link_off,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
    final noteText = note.text.trim();
    note.dispose();
    if (confirmed != true || !mounted) {
      return;
    }
    await _run(() async {
      await ref
          .read(adminApiProvider)
          .revokeReportLink(widget.jobId, reason, noteText);
      ref.invalidate(reportProvider(widget.jobId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.linkRevoked)));
      }
    });
  }

  Future<void> _togglePdf(bool enabled) async {
    await _run(() async {
      await ref.read(adminApiProvider).setPdfDownload(widget.jobId, !enabled);
      ref.invalidate(reportProvider(widget.jobId));
    });
  }

  Future<void> _downloadPdf() async {
    final l10n = AppLocalizations.of(context);
    await _run(() async {
      final bytes = await ref.read(adminApiProvider).reportPdf(widget.jobId);
      final path = await saveReportPdf(bytes);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.pdfBytesSaved}: $path')));
      }
    });
  }

  Future<void> _copy(String? url) async {
    final l10n = AppLocalizations.of(context);
    if (url == null || url.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.linkCopied)));
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await action();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
