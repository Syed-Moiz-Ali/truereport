import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/report_pdf_saver.dart';
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

class _ReportPageState extends ConsumerState<ReportPage> {
  bool _busy = false;
  String? _publicUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final report = ref.watch(reportProvider(widget.jobId));
    return AppScaffold(
      appBar: AppBar(
        title: Text(l10n.report),
        actions: [
          IconButton(
            tooltip: l10n.cancel,
            onPressed: () => ref.invalidate(reportProvider(widget.jobId)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: report.when(
        loading: () => Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: const LoadingSkeleton(lines: 6),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            child: ErrorState(
              title: l10n.error,
              body: l10n.genericError,
              onRetry: () => ref.invalidate(reportProvider(widget.jobId)),
              retryLabel: l10n.retryAction,
            ),
          ),
        ),
        data: (value) => _body(context, value),
      ),
    );
  }

  Widget _body(BuildContext context, ReportAdmin report) {
    final l10n = AppLocalizations.of(context);
    final ready = report.reportReady;
    return ListView(
      padding: EdgeInsetsDirectional.all(context.spacing.lg),
      children: [
        SectionHeader(
          title: l10n.report,
          subtitle: '${report.reportNumber} - v${report.version}',
        ),
        Card(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(context, l10n.reportStatus, report.generationStatus),
                _row(
                  context,
                  l10n.finalized,
                  _formatInstant(context, report.finalizedAt),
                ),
                _row(context, l10n.consent, report.consentState),
                _row(context, l10n.publicLink, report.linkState),
                _row(
                  context,
                  l10n.pdfDownload,
                  report.pdfDownloadEnabled ? l10n.reportReady : l10n.disabled,
                ),
                if (report.generationError != null)
                  _row(context, l10n.error, report.generationError!),
                SizedBox(height: context.spacing.sm),
                Text(
                  '${l10n.snapshotHash}: ${report.snapshotHash}',
                  style: context.texts.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (report.content != null) ...[
          SizedBox(height: context.spacing.lg),
          SectionHeader(title: l10n.report),
          ..._content(context, report.content!),
        ],
        SizedBox(height: context.spacing.lg),
        if (!ready && report.generationStatus == 'FAILED')
          AppButton(
            label: l10n.retryReport,
            onPressed: _busy ? null : _retry,
            isLoading: _busy,
            icon: Icons.refresh,
            expand: true,
          ),
        if (ready) ...[
          AppButton(
            label: l10n.downloadPdf,
            onPressed: _busy ? null : _downloadPdf,
            isLoading: _busy,
            icon: Icons.download_outlined,
            expand: true,
          ),
          SizedBox(height: context.spacing.sm),
          AppButton(
            label:
                '${l10n.pdfDownload}: ${report.pdfDownloadEnabled ? l10n.reportReady : l10n.disabled}',
            onPressed: _busy
                ? null
                : () => _togglePdf(report.pdfDownloadEnabled),
            icon: report.pdfDownloadEnabled
                ? Icons.toggle_on_outlined
                : Icons.toggle_off_outlined,
            variant: AppButtonVariant.tonal,
            expand: true,
          ),
        ],
        SizedBox(height: context.spacing.lg),
        SectionHeader(title: l10n.publicLink),
        Card(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatusChip(
                  label: report.linkState,
                  tone: report.linkState == 'ACTIVE'
                      ? StatusTone.success
                      : report.linkState == 'REVOKED'
                      ? StatusTone.danger
                      : StatusTone.warning,
                  icon: report.linkState == 'ACTIVE'
                      ? Icons.link
                      : Icons.link_off,
                ),
                SizedBox(height: context.spacing.sm),
                if (report.consentState != 'GRANTED')
                  Text(l10n.consentNotGranted, style: context.texts.bodySmall),
                if (report.linkState == 'PENDING_CONSENT' &&
                    report.consentState == 'GRANTED')
                  AppButton(
                    label: l10n.createLink,
                    onPressed: _busy ? null : _activate,
                    isLoading: _busy,
                    icon: Icons.link,
                    expand: true,
                  ),
                if (_publicUrl != null) ...[
                  SizedBox(height: context.spacing.sm),
                  SelectableText(_publicUrl!),
                  SizedBox(height: context.spacing.sm),
                  AppButton(
                    label: l10n.copyLink,
                    onPressed: _copy,
                    icon: Icons.copy,
                    expand: true,
                  ),
                ],
                if (report.linkState == 'ACTIVE' && _publicUrl == null)
                  Text(
                    '${l10n.linkActive}. ${l10n.copyLink}: ${l10n.reportUnavailable}',
                    style: context.texts.bodySmall,
                  ),
                if (report.linkState != 'REVOKED') ...[
                  SizedBox(height: context.spacing.sm),
                  AppButton(
                    label: l10n.deactivateLink,
                    onPressed: _busy ? null : _revoke,
                    icon: Icons.link_off,
                    variant: AppButtonVariant.text,
                    expand: true,
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: context.spacing.lg),
        _deliverySection(context, ready),
      ],
    );
  }

  Widget _deliverySection(BuildContext context, bool ready) {
    final l10n = AppLocalizations.of(context);
    final deliveries = ref.watch(reportDeliveriesProvider(widget.jobId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.deliveryHistory),
        if (ready)
          AppButton(
            label: l10n.sendReport,
            onPressed: _busy ? null : _send,
            isLoading: _busy,
            icon: Icons.send_outlined,
            expand: true,
          ),
        Padding(
          padding: EdgeInsetsDirectional.only(top: context.spacing.xs),
          child: Text(
            l10n.deliveryConsentHint,
            style: context.texts.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(height: context.spacing.md),
        deliveries.when(
          loading: () => const LoadingSkeleton(lines: 2),
          error: (error, _) =>
              Text(l10n.genericError, style: context.texts.bodySmall),
          data: (items) {
            if (items.isEmpty) {
              return Text(l10n.noDeliveries, style: context.texts.bodySmall);
            }
            return Column(
              children: [
                for (final item in items) ...[
                  _deliveryCard(context, item),
                  SizedBox(height: context.spacing.sm),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _deliveryCard(BuildContext context, ReportDelivery item) {
    final l10n = AppLocalizations.of(context);
    final language = item.language == 'ar' ? l10n.arabic : l10n.english;
    return Card(
      child: Padding(
        padding: EdgeInsetsDirectional.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: context.spacing.xs,
              runSpacing: context.spacing.xs,
              children: [
                StatusChip(
                  label: item.channel,
                  tone: StatusTone.info,
                  icon: switch (item.channel) {
                    'EMAIL' => Icons.mail_outline,
                    'SMS' => Icons.sms_outlined,
                    _ => Icons.chat_outlined,
                  },
                ),
                StatusChip(
                  label: item.status,
                  tone: switch (item.status) {
                    'SENT' || 'DELIVERED' => StatusTone.success,
                    'FAILED' || 'DEAD_LETTER' => StatusTone.danger,
                    _ => StatusTone.warning,
                  },
                ),
              ],
            ),
            SizedBox(height: context.spacing.sm),
            _row(context, l10n.deliveryRecipient, item.recipientMasked),
            _row(context, l10n.deliveryLanguage, language),
            _row(
              context,
              l10n.deliveryAttempts,
              '${item.attempts} / ${item.maxAttempts}',
            ),
            if (item.pdfAttached)
              _row(context, l10n.report, l10n.deliveryPdfAttached),
            if (item.lastErrorMessage != null &&
                item.lastErrorMessage!.isNotEmpty)
              _row(context, l10n.deliveryError, item.lastErrorMessage!),
            if (item.nextAttemptAt.isNotEmpty)
              _row(context, l10n.deliveryNextAttempt, item.nextAttemptAt),
            if (item.retryable) ...[
              SizedBox(height: context.spacing.sm),
              AppButton(
                label: l10n.retryDelivery,
                onPressed: _busy ? null : () => _retryDelivery(item),
                icon: Icons.refresh,
                variant: AppButtonVariant.tonal,
                expand: true,
              ),
            ],
          ],
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

  List<Widget> _content(BuildContext context, Map<String, dynamic> content) {
    final l10n = AppLocalizations.of(context);
    final vehicle = content['vehicle'] as Map<String, dynamic>? ?? {};
    final coverage = content['coverage'] as Map<String, dynamic>? ?? {};
    final keyFindings = content['keyFindings'] as List<dynamic>? ?? [];
    final categories = content['categories'] as List<dynamic>? ?? [];
    return [
      Card(
        child: Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row(
                context,
                l10n.vehicle,
                '${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''}',
              ),
              _row(context, l10n.odometer, '${vehicle['odometer'] ?? ''}'),
              _row(
                context,
                l10n.coverage,
                '${coverage['completed'] ?? 0} / ${coverage['applicable'] ?? 0}',
              ),
            ],
          ),
        ),
      ),
      SizedBox(height: context.spacing.md),
      SectionHeader(title: l10n.keyFindings),
      if (keyFindings.isEmpty)
        Text(l10n.noResults, style: context.texts.bodySmall),
      ...keyFindings.map((dynamic raw) {
        final item = raw as Map<String, dynamic>;
        return Card(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['labelEn'] as String? ?? '',
                  style: context.texts.titleSmall,
                ),
                if ((item['note'] as String? ?? '').isNotEmpty)
                  Text(item['note'] as String, style: context.texts.bodySmall),
              ],
            ),
          ),
        );
      }),
      SizedBox(height: context.spacing.md),
      SectionHeader(title: l10n.findings),
      ...categories.map((dynamic raw) {
        final category = raw as Map<String, dynamic>;
        final items = category['items'] as List<dynamic>? ?? [];
        return Padding(
          padding: EdgeInsetsDirectional.only(bottom: context.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category['labelEn'] as String? ?? '',
                style: context.texts.titleSmall,
              ),
              ...items.map((dynamic rawItem) {
                final item = rawItem as Map<String, dynamic>;
                final severity = item['severityEn'] as String? ?? '';
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item['labelEn'] as String? ?? ''),
                  subtitle: Text(
                    '${item['resultEn'] ?? item['resultCode'] ?? ''}'
                    '${severity.isEmpty ? '' : ' - $severity'}',
                  ),
                );
              }),
            ],
          ),
        );
      }),
    ];
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: context.spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: context.texts.bodySmall)),
          Expanded(child: Text(value, style: context.texts.bodyMedium)),
        ],
      ),
    );
  }

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

  Future<void> _copy() async {
    final l10n = AppLocalizations.of(context);
    final url = _publicUrl;
    if (url == null) {
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
