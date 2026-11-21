import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/report_pdf_saver.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';

import 'report_actions.dart';
import 'report_chrome.dart';
import 'report_distribution.dart';
import 'report_language_options.dart';
import 'report_sheet.dart';

class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({required this.jobId, this.preferredLanguage, super.key});

  final String jobId;

  /// The job's preferred language when the caller already has it.
  ///
  /// Falls back to the language captured in the generated report snapshot.
  final String? preferredLanguage;

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
    final t = UiStrings.of(context);
    final report = ref.watch(reportProvider(widget.jobId));
    // Start the capability fetch with the page; `_send` reads its current value
    // and falls back to EMAIL while it is loading or if it failed.
    ref.watch(deliveryChannelsProvider);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final data = report.asData?.value;
    final reference = (data?.reportNumber ?? '').trim().isEmpty
        ? t(WorkshopAdminKeys.report)
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
                error: (error, _) => _error(context, t),
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

  Widget _error(BuildContext context, UiStrings t) {
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
                  title: t(WorkshopAdminKeys.error),
                  body: t(WorkshopAdminKeys.reportUnavailable),
                  retryLabel: t(WorkshopAdminKeys.retryAction),
                  onRetry: () => ref.invalidate(reportProvider(widget.jobId)),
                ),
                SizedBox(height: spacing.md),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ReportActionButton(
                    label: t(WorkshopAdminKeys.commonBack),
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
    final t = UiStrings.of(context);
    final serverChannels = ref.read(deliveryChannelsProvider).asData?.value;
    final channelCodes = <String>[
      for (final option in serverChannels ?? const <DeliveryChannelOption>[])
        if (option.available && option.channel.trim().isNotEmpty)
          option.channel.trim(),
    ];
    if (channelCodes.isEmpty) channelCodes.add('EMAIL');
    var channel = channelCodes.first;
    List<WorkshopLanguage>? registry;
    try {
      registry = await ref.read(workshopLanguagesProvider.future);
    } on Object {
      registry = null;
    }
    if (!mounted) return;
    final report = ref.read(reportProvider(widget.jobId)).asData?.value;
    final manifest = ref
        .read(languageSelectionProvider(adminUiMessageClient))
        .manifest;
    final preferred =
        (widget.preferredLanguage ?? report?.preferredLanguage ?? '').trim();
    final languageOptions = reportLanguageOptions(
      registry,
      preferred: preferred,
      manifest: manifest,
    );
    var language = reportDeliveryLanguage(
      languageOptions,
      preferred: preferred,
    );
    final confirmed = await showAppBottomSheet<bool>(
      context,
      child: StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(title: t(WorkshopAdminKeys.sendReportTitle)),
              Text(
                t(WorkshopAdminKeys.deliveryChannel),
                style: context.texts.bodySmall,
              ),
              for (final code in channelCodes)
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    bottom: context.spacing.xs,
                  ),
                  child: AppSelectableText(
                    key: Key('report-delivery-channel-${code.toLowerCase()}'),
                    label: _channelLabel(t, code),
                    selected: channel == code,
                    onTap: () => setSheetState(() => channel = code),
                  ),
                ),
              SizedBox(height: context.spacing.sm),
              Text(
                t(WorkshopAdminKeys.deliveryLanguage),
                style: context.texts.bodySmall,
              ),
              for (final option in languageOptions)
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    bottom: context.spacing.xs,
                  ),
                  child: AppSelectableText(
                    key: Key('report-delivery-language-${option.code}'),
                    label: option.label,
                    selected: language == option.code,
                    onTap: () => setSheetState(() => language = option.code),
                  ),
                ),
              SizedBox(height: context.spacing.lg),
              AppButton(
                label: t(WorkshopAdminKeys.sendReport),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(WorkshopAdminKeys.deliveryQueued))),
        );
      }
    });
  }

  Future<void> _retryDelivery(ReportDelivery item) async {
    final t = UiStrings.of(context);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(WorkshopAdminKeys.deliveryQueued))),
        );
      }
    });
  }

  String _newDeliveryKey(String prefix) =>
      'admin-$prefix-${DateTime.now().microsecondsSinceEpoch}';

  Future<void> _retry() async {
    final t = UiStrings.of(context);
    await _run(() async {
      await ref.read(adminApiProvider).retryReport(widget.jobId);
      ref.invalidate(reportProvider(widget.jobId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(WorkshopAdminKeys.reportStatus))),
        );
      }
    });
  }

  Future<void> _activate() async {
    final t = UiStrings.of(context);
    await _run(() async {
      final result = await ref
          .read(adminApiProvider)
          .activateReportLink(widget.jobId);
      setState(() => _publicUrl = result.publicUrl);
      ref.invalidate(reportProvider(widget.jobId));
      if (mounted && result.publicUrl != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t(WorkshopAdminKeys.copyLink))));
      }
    });
  }

  Future<void> _revoke() async {
    final t = UiStrings.of(context);
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
              SectionHeader(title: t(WorkshopAdminKeys.deactivateLink)),
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
              AppTextField(
                controller: note,
                label: t(WorkshopAdminKeys.deactivateReason),
              ),
              SizedBox(height: context.spacing.lg),
              AppButton(
                label: t(WorkshopAdminKeys.deactivate),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(WorkshopAdminKeys.linkRevoked))),
        );
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
    final t = UiStrings.of(context);
    await _run(() async {
      final bytes = await ref.read(adminApiProvider).reportPdf(widget.jobId);
      final path = await saveReportPdf(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t(WorkshopAdminKeys.pdfBytesSaved)}: $path'),
          ),
        );
      }
    });
  }

  Future<void> _copy(String? url) async {
    final t = UiStrings.of(context);
    if (url == null || url.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(WorkshopAdminKeys.linkCopied))));
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    final t = UiStrings.of(context);
    setState(() => _busy = true);
    try {
      await action();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(WorkshopAdminKeys.actionFailed))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

String _channelLabel(UiStrings t, String channel) {
  switch (channel.trim().toUpperCase()) {
    case 'WHATSAPP':
      return t(WorkshopAdminKeys.channelWhatsapp);
    case 'SMS':
      return t(WorkshopAdminKeys.channelSms);
    case 'EMAIL':
      return t(WorkshopAdminKeys.channelEmail);
    default:
      return channel.trim().toUpperCase();
  }
}
