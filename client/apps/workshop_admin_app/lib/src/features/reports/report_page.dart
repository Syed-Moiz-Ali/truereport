import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/report_pdf_saver.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:l10n/l10n.dart';

class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

/// Parses a raw ISO `scheduledAt`/`finalizedAt` string and returns the
/// Asia/Dubai (UTC+4) wall-clock instant for display.
///
/// Strings carrying no UTC offset are treated as UTC (matching the
/// technician app's `scheduledTimeUtc4` instant interpretation in
/// `assigned_jobs_view.dart`, which displays `toUtc() + 4h`). Returns null
/// when the string is empty or unparseable.
DateTime? _dubaiWallTime(String raw) {
  if (raw.trim().isEmpty) {
    return null;
  }
  final parsed = DateTime.tryParse(raw.trim());
  if (parsed == null) {
    return null;
  }
  final hasOffset = RegExp(r'([Zz]|[+-]\d{2}:?\d{2})$').hasMatch(raw.trim());
  final utc = hasOffset
      ? parsed.toUtc()
      : DateTime.utc(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
          parsed.microsecond,
        );
  return utc.add(const Duration(hours: 4));
}

/// Locale-aware date+time for a raw ISO instant (`DateFormat.yMd + add_Hm`
/// under the active locale). Falls back to the raw string when unparseable
/// so no information is silently dropped.
String _formatInstant(BuildContext context, String raw) {
  final wall = _dubaiWallTime(raw);
  if (wall == null) {
    return raw;
  }
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMd(locale).add_Hm().format(wall);
}

/// Date-only form for the compact page subtitle; the hero summary keeps the
/// full instant so the same string is never repeated verbatim.
String _formatDate(BuildContext context, String raw) {
  final wall = _dubaiWallTime(raw);
  if (wall == null) {
    return raw;
  }
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMd(locale).format(wall);
}

/// Reads a dynamic content field as display text without inventing data.
String _text(dynamic value) => value == null ? '' : '$value'.trim();

/// Picks the Arabic value when the page is Arabic and one is present,
/// otherwise the English value. Report snapshots carry both locales.
String _localized(Map<String, dynamic> item, String prefix, bool isArabic) {
  final english = _text(item['${prefix}En']);
  final arabic = _text(item['${prefix}Ar']);
  if (isArabic && arabic.isNotEmpty) {
    return arabic;
  }
  return english;
}

String _consentLabel(AppLocalizations l10n, String state) => switch (state) {
  'GRANTED' => l10n.consentGranted,
  'REFUSED' => l10n.consentRefused,
  'WITHDRAWN' => l10n.consentWithdrawn,
  _ => state,
};

String _linkLabel(AppLocalizations l10n, String state) => switch (state) {
  'ACTIVE' => l10n.linkActive,
  'REVOKED' => l10n.linkRevoked,
  'PENDING_CONSENT' => l10n.linkPendingConsent,
  _ => state,
};

WorkshopStatusTone _generationTone(String status) => switch (status) {
  'READY' => WorkshopStatusTone.success,
  'FAILED' => WorkshopStatusTone.danger,
  _ => WorkshopStatusTone.warning,
};

String _generationLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'READY' => l10n.reportReady,
      'FAILED' => l10n.reportFailed,
      'PENDING' || 'GENERATING' => l10n.generating,
      _ => status,
    };

WorkshopStatusTone _linkTone(String state) => switch (state) {
  'ACTIVE' => WorkshopStatusTone.success,
  'REVOKED' => WorkshopStatusTone.danger,
  'PENDING_CONSENT' => WorkshopStatusTone.warning,
  _ => WorkshopStatusTone.neutral,
};

WorkshopStatusTone _severityTone(String raw) {
  final normalized = raw.toUpperCase();
  if (normalized == 'MAJOR' ||
      normalized == 'CRITICAL' ||
      normalized == 'HIGH') {
    return WorkshopStatusTone.danger;
  }
  if (normalized == 'MODERATE' || normalized == 'MEDIUM') {
    return WorkshopStatusTone.warning;
  }
  return WorkshopStatusTone.neutral;
}

WorkshopStatusTone _deliveryTone(String status) {
  if (status == 'SENT' || status == 'DELIVERED') {
    return WorkshopStatusTone.success;
  }
  if (status == 'FAILED' || status == 'DEAD_LETTER') {
    return WorkshopStatusTone.danger;
  }
  return WorkshopStatusTone.warning;
}

class _ReportPageState extends ConsumerState<ReportPage> {
  bool _busy = false;
  String? _publicUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final report = ref.watch(reportProvider(widget.jobId));
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: context.ws.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReportTopBar(
            isRtl: isRtl,
            onBack: () => Navigator.of(context).maybePop(),
            onRefresh: () => ref.invalidate(reportProvider(widget.jobId)),
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
    return WorkshopPageScroll(
      children: [
        const WorkshopSkeleton(lines: 3),
        SizedBox(height: spacing.xl),
        const WorkshopSkeleton(lines: 4, card: true),
        SizedBox(height: spacing.lg),
        const WorkshopSkeleton(lines: 5, card: true),
        SizedBox(height: spacing.xxl),
      ],
    );
  }

  Widget _error(BuildContext context, AppLocalizations l10n) {
    final spacing = context.spacing;
    return WorkshopPageScroll(
      children: [
        Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
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
                  child: WorkshopButton(
                    label: l10n.commonBack,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_forward
                        : Icons.arrow_back,
                    variant: WorkshopButtonVariant.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: spacing.xxl),
      ],
    );
  }

  Widget _body(BuildContext context, ReportAdmin report) {
    final spacing = context.spacing;
    final ready = report.reportReady;
    return WorkshopPageScroll(
      key: const Key('report-scroll'),
      children: [
        _ReportHeader(
          report: report,
          showPrimary: ready,
          isLoading: _busy,
          onDownload: _busy ? null : _downloadPdf,
        ),
        SizedBox(height: spacing.xl),
        _SummaryCard(report: report),
        if (ready && report.content != null) ...[
          SizedBox(height: spacing.xl),
          ..._preview(context, report),
        ],
        if (ready) ...[
          SizedBox(height: spacing.xl),
          _linkSection(context, report, url: _publicUrl ?? report.publicUrl),
          SizedBox(height: spacing.xl),
          _deliverySection(context, ready),
        ] else ...[
          SizedBox(height: spacing.xl),
          _notReadySection(context, report),
        ],
        SizedBox(height: spacing.xxl),
      ],
    );
  }

  List<Widget> _preview(BuildContext context, ReportAdmin report) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final isArabic = context.isArabic;
    final content = report.content!;
    final vehicle = content['vehicle'] as Map<String, dynamic>? ?? const {};
    final keyFindings =
        content['keyFindings'] as List<dynamic>? ?? const <dynamic>[];
    final categories =
        content['categories'] as List<dynamic>? ?? const <dynamic>[];

    final vehicleItems = <_LabeledValue>[
      if (_text(vehicle['make']).isNotEmpty)
        _LabeledValue(l10n.vehicleMake, _text(vehicle['make'])),
      if (_text(vehicle['model']).isNotEmpty)
        _LabeledValue(l10n.vehicleModel, _text(vehicle['model'])),
      if (_text(vehicle['odometer']).isNotEmpty)
        _LabeledValue(
          l10n.odometer,
          _text(vehicle['odometer']),
          valueDirection: TextDirection.ltr,
        ),
      if (_text(vehicle['plate']).isNotEmpty)
        _LabeledValue(
          l10n.vehiclePlate,
          _text(vehicle['plate']),
          valueDirection: TextDirection.ltr,
        ),
    ];

    return [
      if (vehicleItems.isNotEmpty) ...[
        WorkshopSectionHeader(title: l10n.vehicle),
        SizedBox(height: spacing.sm),
        WorkshopCard(
          padding: context.ws.cardPaddingFor(MediaQuery.sizeOf(context).width),
          child: _ValueGrid(items: vehicleItems),
        ),
        SizedBox(height: spacing.xl),
      ],
      WorkshopSectionHeader(title: l10n.keyFindings),
      SizedBox(height: spacing.sm),
      if (keyFindings.isEmpty)
        WorkshopInlineNote(text: l10n.noResults, icon: Icons.search_off)
      else
        _KeyFindingsCard(items: keyFindings, isArabic: isArabic),
      SizedBox(height: spacing.xl),
      WorkshopSectionHeader(title: l10n.findings),
      SizedBox(height: spacing.sm),
      if (categories.isEmpty)
        WorkshopInlineNote(text: l10n.noResults, icon: Icons.search_off)
      else
        _FindingsCard(categories: categories, isArabic: isArabic),
    ];
  }

  Widget _notReadySection(BuildContext context, ReportAdmin report) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final canPop = Navigator.of(context).canPop();
    final failed = report.generationStatus == 'FAILED';

    if (!failed) {
      return WorkshopCard(
        child: WorkshopEmptyState(
          title: l10n.reportNotReadyTitle,
          body: l10n.reportNotReadyBody,
          icon: Icons.description_outlined,
          action: canPop
              ? WorkshopButton(
                  label: l10n.reportBackToJob,
                  onPressed: () => Navigator.of(context).maybePop(),
                  expand: true,
                )
              : null,
        ),
      );
    }

    final errorText = report.generationError?.trim() ?? '';
    return WorkshopCard(
      child: WorkshopEmptyState(
        title: l10n.reportFailed,
        body: errorText.isEmpty ? null : errorText,
        icon: Icons.error_outline,
        action: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            WorkshopButton(
              label: l10n.retryReport,
              onPressed: _busy ? null : _retry,
              isLoading: _busy,
              icon: Icons.refresh,
              expand: true,
            ),
            if (canPop) ...[
              SizedBox(height: spacing.sm),
              WorkshopButton(
                label: l10n.reportBackToJob,
                onPressed: () => Navigator.of(context).maybePop(),
                variant: WorkshopButtonVariant.secondary,
                expand: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _linkSection(
    BuildContext context,
    ReportAdmin report, {
    required String? url,
  }) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final linkTone = _linkTone(report.linkState);
    final hasConsent = report.consentState == 'GRANTED';
    final displayUrl = url?.trim() ?? '';
    final showUrl = displayUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkshopSectionHeader(title: l10n.publicLink),
        SizedBox(height: spacing.sm),
        WorkshopCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.all(ws.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _SafeBadge(
                        label: _linkLabel(l10n, report.linkState),
                        tone: linkTone,
                        icon: switch (report.linkState) {
                          'ACTIVE' => Icons.link,
                          'REVOKED' => Icons.link_off,
                          _ => Icons.schedule,
                        },
                      ),
                    ),
                    SizedBox(height: spacing.md),
                    WorkshopInlineNote(
                      icon: hasConsent
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      text: hasConsent
                          ? l10n.consentGranted
                          : l10n.consentNotGranted,
                    ),
                    if (showUrl) ...[
                      SizedBox(height: spacing.md),
                      SelectableText(
                        displayUrl,
                        style: ws.body.copyWith(color: ws.ink),
                      ),
                    ],
                    SizedBox(height: spacing.md),
                    Wrap(
                      spacing: spacing.sm,
                      runSpacing: spacing.sm,
                      children: [
                        if (report.linkState == 'PENDING_CONSENT' && hasConsent)
                          WorkshopButton(
                            label: l10n.createLink,
                            onPressed: _busy ? null : _activate,
                            isLoading: _busy,
                            icon: Icons.link,
                          ),
                        if (showUrl)
                          WorkshopButton(
                            label: l10n.copyLink,
                            onPressed: () => _copy(displayUrl),
                            icon: Icons.copy,
                            variant: WorkshopButtonVariant.secondary,
                          ),
                        if (report.linkState != 'REVOKED')
                          WorkshopButton(
                            label: l10n.deactivateLink,
                            onPressed: _busy ? null : _revoke,
                            icon: Icons.link_off,
                            variant: WorkshopButtonVariant.danger,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const WorkshopDivider(),
              Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: ws.cardPadding,
                  vertical: spacing.md,
                ),
                child: MergeSemantics(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l10n.pdfDownload, style: ws.bodyStrong),
                            SizedBox(height: spacing.xxs),
                            Text(
                              report.pdfDownloadEnabled
                                  ? l10n.reportReady
                                  : l10n.disabled,
                              style: ws.meta.copyWith(color: ws.muted),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: spacing.md),
                      Switch(
                        value: report.pdfDownloadEnabled,
                        onChanged: _busy
                            ? null
                            : (_) => _togglePdf(report.pdfDownloadEnabled),
                        activeThumbColor: ws.accent,
                        activeTrackColor: ws.accentSoft,
                        inactiveThumbColor: ws.muted,
                        inactiveTrackColor: ws.canvas,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _deliverySection(BuildContext context, bool ready) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final deliveries = ref.watch(reportDeliveriesProvider(widget.jobId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkshopSectionHeader(title: l10n.deliveryHistory),
        SizedBox(height: spacing.sm),
        if (ready) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: WorkshopButton(
              label: l10n.sendReport,
              onPressed: _busy ? null : _send,
              isLoading: _busy,
              icon: Icons.send_outlined,
              variant: WorkshopButtonVariant.secondary,
            ),
          ),
          SizedBox(height: spacing.sm),
        ],
        Text(
          l10n.deliveryConsentHint,
          style: ws.meta.copyWith(color: ws.muted),
        ),
        SizedBox(height: spacing.md),
        WorkshopCard(
          padding: EdgeInsets.zero,
          child: deliveries.when(
            loading: () => Padding(
              padding: EdgeInsetsDirectional.all(ws.cardPadding),
              child: const WorkshopSkeleton(lines: 3),
            ),
            error: (error, _) => Padding(
              padding: EdgeInsetsDirectional.all(ws.cardPadding),
              child: WorkshopInlineNote(
                text: l10n.genericError,
                icon: Icons.error_outline,
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Padding(
                  padding: EdgeInsetsDirectional.all(ws.cardPadding),
                  child: WorkshopInlineNote(
                    text: l10n.noDeliveries,
                    icon: Icons.history,
                  ),
                );
              }
              return Column(
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    if (index > 0) const WorkshopDivider(),
                    _DeliveryRow(
                      item: items[index],
                      busy: _busy,
                      onRetry: () => _retryDelivery(items[index]),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
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

// ---------------------------------------------------------------------------
// Page chrome
// ---------------------------------------------------------------------------

/// 60 px pushed-page bar: back, page title and refresh. The page lives outside
/// the workshop shell, so it carries its own chrome and keeps it visible while
/// the body loads, errors or shows an empty state.
class _ReportTopBar extends StatelessWidget {
  const _ReportTopBar({
    required this.isRtl,
    required this.onBack,
    required this.onRefresh,
  });

  final bool isRtl;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);
    final gutter = ws.pageGutter(MediaQuery.sizeOf(context).width);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ws.surface,
        border: Border(bottom: BorderSide(color: ws.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: ws.topBarHeight,
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: gutter),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
                child: Row(
                  children: [
                    WorkshopIconButton(
                      icon: isRtl ? Icons.arrow_forward : Icons.arrow_back,
                      semanticLabel: l10n.commonBack,
                      onPressed: onBack,
                    ),
                    SizedBox(width: spacing.sm),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          l10n.report,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ws.sectionTitle,
                        ),
                      ),
                    ),
                    SizedBox(width: spacing.sm),
                    WorkshopIconButton(
                      icon: Icons.refresh,
                      semanticLabel: l10n.refresh,
                      onPressed: onRefresh,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Report heading: `TR-0001 - v1`, the finalized instant + generation status
/// badge, and the single primary action for the current state.
class _ReportHeader extends StatelessWidget {
  const _ReportHeader({
    required this.report,
    required this.showPrimary,
    required this.isLoading,
    required this.onDownload,
  });

  final ReportAdmin report;
  final bool showPrimary;
  final bool isLoading;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);
    final title = '${report.reportNumber} - v${report.version}';
    final finalized = _formatDate(context, report.finalizedAt);

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(header: true, child: Text(title, style: ws.pageTitle)),
        SizedBox(height: spacing.xs),
        Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (finalized.trim().isNotEmpty)
              Text(
                '${l10n.finalized}: $finalized',
                style: ws.meta.copyWith(color: ws.muted),
              ),
            _SafeBadge(
              label: _generationLabel(l10n, report.generationStatus),
              tone: _generationTone(report.generationStatus),
            ),
          ],
        ),
      ],
    );

    Widget action({required bool expand}) => WorkshopButton(
      label: l10n.downloadPdf,
      onPressed: onDownload,
      isLoading: isLoading,
      icon: Icons.download_outlined,
      expand: expand,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 680) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              heading,
              if (showPrimary) ...[
                SizedBox(height: spacing.lg),
                action(expand: true),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: heading),
            if (showPrimary) ...[
              SizedBox(width: spacing.lg),
              action(expand: false),
            ],
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Summary and preview
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report});

  final ReportAdmin report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final coverage = report.content?['coverage'];
    final coverageMap = coverage is Map<String, dynamic> ? coverage : null;
    final completed = coverageMap?['completed'];
    final applicable = coverageMap?['applicable'];

    final items = <_LabeledValue>[
      _LabeledValue(
        l10n.reportStatus,
        _generationLabel(l10n, report.generationStatus),
      ),
      if (report.finalizedAt.trim().isNotEmpty)
        _LabeledValue(
          l10n.finalized,
          _formatInstant(context, report.finalizedAt),
          valueDirection: TextDirection.ltr,
        ),
      if (completed != null && applicable != null)
        _LabeledValue(l10n.coverage, '$completed / $applicable'),
      _LabeledValue(l10n.consent, _consentLabel(l10n, report.consentState)),
      _LabeledValue(l10n.publicLink, _linkLabel(l10n, report.linkState)),
      _LabeledValue(
        l10n.pdfDownload,
        report.pdfDownloadEnabled ? l10n.reportReady : l10n.disabled,
      ),
    ];

    return WorkshopCard(
      padding: context.ws.cardPaddingFor(MediaQuery.sizeOf(context).width),
      child: _ValueGrid(items: items),
    );
  }
}

/// Responsive 2-4 column grid of compact label-above-value cells. The label
/// and value wrap instead of overflowing, so it survives phone + 2x text.
class _ValueGrid extends StatelessWidget {
  const _ValueGrid({required this.items});

  final List<_LabeledValue> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final spacing = context.spacing;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final columns = available >= 900
            ? 4
            : available >= 620
            ? 3
            : 2;
        final count = items.length < columns ? items.length : columns;
        final gap = spacing.lg;
        final cellWidth = (available - gap * (count - 1)) / count;
        return Wrap(
          spacing: gap,
          runSpacing: spacing.xl,
          children: [
            for (final item in items)
              SizedBox(
                width: cellWidth > 0 ? cellWidth : available,
                child: _ValueCell(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({required this.item});

  final _LabeledValue item;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Semantics(
      container: true,
      label: '${item.label}: ${item.value}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.label,
            textAlign: TextAlign.start,
            style: ws.meta.copyWith(color: ws.muted),
          ),
          SizedBox(height: spacing.xxs),
          Text(
            item.value,
            textDirection: item.valueDirection,
            textAlign: TextAlign.start,
            style: ws.bodyStrong.copyWith(color: ws.ink),
          ),
        ],
      ),
    );
  }
}

class _KeyFindingsCard extends StatelessWidget {
  const _KeyFindingsCard({required this.items, required this.isArabic});

  final List<dynamic> items;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return WorkshopCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) const WorkshopDivider(),
            _KeyFindingRow(
              item: items[index] as Map<String, dynamic>,
              isArabic: isArabic,
              labelStyle: ws.bodyStrong,
              noteStyle: ws.meta.copyWith(color: ws.muted),
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: ws.cardPadding,
                vertical: spacing.md,
              ),
              gap: spacing.xxs,
            ),
          ],
        ],
      ),
    );
  }
}

class _KeyFindingRow extends StatelessWidget {
  const _KeyFindingRow({
    required this.item,
    required this.isArabic,
    required this.labelStyle,
    required this.noteStyle,
    required this.padding,
    required this.gap,
  });

  final Map<String, dynamic> item;
  final bool isArabic;
  final TextStyle labelStyle;
  final TextStyle noteStyle;
  final EdgeInsetsDirectional padding;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final label = _localized(item, 'label', isArabic);
    final note = _text(item['note']);
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, textAlign: TextAlign.start, style: labelStyle),
          if (note.isNotEmpty) ...[
            SizedBox(height: gap),
            Builder(
              builder: (context) {
                final noteIsArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(note);
                return Text(
                  note,
                  textDirection: noteIsArabic ? null : TextDirection.ltr,
                  textAlign: noteIsArabic
                      ? TextAlign.start
                      : (isArabic ? TextAlign.right : TextAlign.start),
                  style: noteStyle,
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _FindingsCard extends StatelessWidget {
  const _FindingsCard({required this.categories, required this.isArabic});

  final List<dynamic> categories;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final rows = <Widget>[];
    for (var index = 0; index < categories.length; index++) {
      final category = categories[index] as Map<String, dynamic>;
      final items = category['items'] as List<dynamic>? ?? const <dynamic>[];
      if (rows.isNotEmpty) {
        rows.add(const WorkshopDivider());
      }
      rows.add(
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: ws.cardPadding,
            end: ws.cardPadding,
            top: spacing.md,
            bottom: spacing.sm,
          ),
          child: Text(
            _localized(category, 'label', isArabic),
            textAlign: TextAlign.start,
            style: ws.cardTitle,
          ),
        ),
      );
      for (var itemIndex = 0; itemIndex < items.length; itemIndex++) {
        if (itemIndex > 0) {
          rows.add(const WorkshopDivider());
        }
        rows.add(
          _FindingRow(
            item: items[itemIndex] as Map<String, dynamic>,
            isArabic: isArabic,
          ),
        );
      }
    }
    return WorkshopCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }
}

class _FindingRow extends StatelessWidget {
  const _FindingRow({required this.item, required this.isArabic});

  final Map<String, dynamic> item;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final label = _localized(item, 'label', isArabic);
    final localizedResult = _localized(item, 'result', isArabic);
    final result = localizedResult.isEmpty
        ? _text(item['resultCode'])
        : localizedResult;
    final localizedSeverity = _localized(item, 'severity', isArabic);
    final severity = localizedSeverity.isEmpty
        ? _text(item['severityEn'])
        : localizedSeverity;

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ws.cardPadding,
        vertical: spacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, textAlign: TextAlign.start, style: ws.bodyStrong),
          SizedBox(height: spacing.xxs),
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (result.isNotEmpty)
                Text(
                  result,
                  textAlign: TextAlign.start,
                  style: ws.meta.copyWith(color: ws.muted),
                ),
              if (severity.isNotEmpty)
                _SafeBadge(
                  label: severity,
                  tone: _severityTone(_text(item['severityEn'])),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliveryRow extends StatelessWidget {
  const _DeliveryRow({
    required this.item,
    required this.busy,
    required this.onRetry,
  });

  final ReportDelivery item;
  final bool busy;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final language = item.language == 'ar' ? l10n.arabic : l10n.english;
    final lastError = item.lastErrorMessage?.trim() ?? '';

    return Padding(
      padding: EdgeInsetsDirectional.all(ws.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: spacing.xs,
            runSpacing: spacing.xs,
            children: [
              _SafeBadge(
                label: item.channel,
                tone: WorkshopStatusTone.neutral,
                icon: switch (item.channel) {
                  'EMAIL' => Icons.mail_outline,
                  'SMS' => Icons.sms_outlined,
                  _ => Icons.chat_outlined,
                },
              ),
              _SafeBadge(label: item.status, tone: _deliveryTone(item.status)),
            ],
          ),
          SizedBox(height: spacing.sm),
          _InfoLine(label: l10n.deliveryRecipient, value: item.recipientMasked),
          _InfoLine(label: l10n.deliveryLanguage, value: language),
          _InfoLine(
            label: l10n.deliveryAttempts,
            value: '${item.attempts} / ${item.maxAttempts}',
          ),
          if (item.pdfAttached)
            _InfoLine(label: l10n.report, value: l10n.deliveryPdfAttached),
          if (lastError.isNotEmpty)
            _InfoLine(label: l10n.deliveryError, value: lastError),
          if (item.nextAttemptAt.isNotEmpty)
            _InfoLine(
              label: l10n.deliveryNextAttempt,
              value: _formatInstant(context, item.nextAttemptAt),
            ),
          if (item.retryable) ...[
            SizedBox(height: spacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: WorkshopButton(
                label: l10n.retryDelivery,
                onPressed: busy ? null : onRetry,
                icon: Icons.refresh,
                variant: WorkshopButtonVariant.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: ws.meta.copyWith(color: ws.muted)),
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            flex: 3,
            child: Text(value, style: ws.body.copyWith(color: ws.ink)),
          ),
        ],
      ),
    );
  }
}

/// Status pill that scales down instead of overflowing when a long localized
/// label meets a large text scale inside a narrow card.
class _SafeBadge extends StatelessWidget {
  const _SafeBadge({required this.label, required this.tone, this.icon});

  final String label;
  final WorkshopStatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: WorkshopStatusBadge(label: label, tone: tone, icon: icon),
    );
  }
}

class _LabeledValue {
  const _LabeledValue(this.label, this.value, {this.valueDirection});

  final String label;
  final String value;
  final TextDirection? valueDirection;
}
