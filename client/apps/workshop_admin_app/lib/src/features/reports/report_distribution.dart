import 'package:workshop_admin_app/src/features/templates/template_pills.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/workshop_clock.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/reference_status.dart';

import 'report_actions.dart';
import 'report_copy.dart';
import 'report_pills.dart';

/// Distribution stub: link state, delivery history and the single primary
/// "Send report" action. Beside the sheet on desktop, under it on phones.
class ReportDistribution extends StatelessWidget {
  const ReportDistribution({
    required this.report,
    required this.deliveries,
    required this.publicUrl,
    required this.isBusy,
    required this.onCopy,
    required this.onCreateLink,
    required this.onRevoke,
    required this.onSend,
    required this.onRetryDelivery,
    required this.onTogglePdf,
    super.key,
  });

  final ReportAdmin report;
  final AsyncValue<List<ReportDelivery>> deliveries;
  final String? publicUrl;
  final bool isBusy;
  final VoidCallback onCopy;
  final VoidCallback onCreateLink;
  final VoidCallback onRevoke;
  final VoidCallback onSend;
  final void Function(ReportDelivery item) onRetryDelivery;
  final VoidCallback onTogglePdf;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final copy = context.reportCopy;
    final t = UiStrings.of(context);
    final items = deliveries.asData?.value ?? const <ReportDelivery>[];
    final delivered = items
        .where((item) => item.status == 'SENT' || item.status == 'DELIVERED')
        .length;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(ws.cardLargeRadius),
        border: Border.all(color: ws.border),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(spacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: ReportEyebrow(label: copy.distribution)),
                if (items.isNotEmpty)
                  Text(
                    '$delivered/${items.length}',
                    style: ws.meta.copyWith(
                      color: ws.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            if (items.isNotEmpty) ...[
              SizedBox(height: spacing.xxs),
              Text(copy.delivered, style: ws.meta.copyWith(color: ws.muted)),
            ],
            SizedBox(height: spacing.md),
            const WorkshopDivider(),
            SizedBox(height: spacing.md),
            _LinkBlock(
              report: report,
              publicUrl: publicUrl,
              isBusy: isBusy,
              onCopy: onCopy,
              onCreateLink: onCreateLink,
              onRevoke: onRevoke,
              onTogglePdf: onTogglePdf,
            ),
            SizedBox(height: spacing.md),
            const WorkshopDivider(),
            SizedBox(height: spacing.md),
            WorkshopInlineNote(
              text: t(WorkshopAdminKeys.deliveryConsentHint),
              icon: Icons.info_outline,
            ),
            SizedBox(height: spacing.md),
            deliveries.when(
              loading: () => const WorkshopSkeleton(lines: 3),
              error: (error, _) => WorkshopInlineNote(
                text: t(WorkshopAdminKeys.genericError),
                icon: Icons.error_outline,
              ),
              data: (list) {
                if (list.isEmpty) {
                  return WorkshopInlineNote(
                    text: t(WorkshopAdminKeys.noDeliveries),
                    icon: Icons.history,
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < list.length; index++) ...[
                      if (index > 0) ...[
                        SizedBox(height: spacing.md),
                        const WorkshopDivider(),
                        SizedBox(height: spacing.md),
                      ],
                      _DeliveryBlock(
                        item: list[index],
                        isBusy: isBusy,
                        onRetry: () => onRetryDelivery(list[index]),
                      ),
                    ],
                  ],
                );
              },
            ),
            SizedBox(height: spacing.lg),
            ReportActionButton(
              label: t(WorkshopAdminKeys.sendReport),
              onPressed: isBusy ? null : onSend,
              loading: isBusy,
              icon: Icons.send_outlined,
              expand: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkBlock extends ConsumerWidget {
  const _LinkBlock({
    required this.report,
    required this.publicUrl,
    required this.isBusy,
    required this.onCopy,
    required this.onCreateLink,
    required this.onRevoke,
    required this.onTogglePdf,
  });

  final ReportAdmin report;
  final String? publicUrl;
  final bool isBusy;
  final VoidCallback onCopy;
  final VoidCallback onCreateLink;
  final VoidCallback onRevoke;
  final VoidCallback onTogglePdf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = context.ws;
    final spacing = context.spacing;
    final copy = context.reportCopy;
    final t = UiStrings.of(context);
    final publicationStatuses = ref
        .watch(statusesProvider('publication'))
        .value;
    final consentStatuses = ref.watch(statusesProvider('consent')).value;
    final url = publicUrl?.trim() ?? '';
    final showUrl = url.isNotEmpty;
    final hasConsent = report.consentState == 'GRANTED';
    final canCreate = report.linkState == 'PENDING_CONSENT' && hasConsent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ReportStatusPill(
              label: referenceStatusText(publicationStatuses, report.linkState),
              tone: referenceStatusTone(publicationStatuses, report.linkState),
              icon: linkIcon(report.linkState),
            ),
            ReportStatusPill(
              label: referenceStatusText(
                consentStatuses,
                consentStatusCode(hasConsent),
              ),
              tone: referenceStatusTone(
                consentStatuses,
                consentStatusCode(hasConsent),
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.md),
        Text(
          showUrl ? _shortUrl(url) : copy.noLinkYet,
          textDirection: TextDirection.ltr,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          style: ws.meta.copyWith(
            color: showUrl ? ws.ink : ws.muted,
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: spacing.md),
        Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.sm,
          children: [
            if (canCreate)
              ReportActionButton(
                label: t(WorkshopAdminKeys.createLink),
                onPressed: isBusy ? null : onCreateLink,
                icon: Icons.link,
                variant: ReportActionVariant.secondary,
              ),
            if (showUrl)
              ReportActionButton(
                label: t(WorkshopAdminKeys.copyLink),
                onPressed: isBusy ? null : onCopy,
                icon: Icons.copy,
                variant: ReportActionVariant.secondary,
              ),
            if (report.linkState != 'REVOKED')
              ReportActionButton(
                label: t(WorkshopAdminKeys.deactivateLink),
                onPressed: isBusy ? null : onRevoke,
                icon: Icons.link_off,
                variant: ReportActionVariant.danger,
              ),
          ],
        ),
        SizedBox(height: spacing.md),
        _PdfToggle(
          label:
              '${t(WorkshopAdminKeys.pdfDownload)} · ${report.pdfDownloadEnabled ? copy.inUse : copy.notInUse}',
          selected: report.pdfDownloadEnabled,
          onTap: isBusy ? null : onTogglePdf,
        ),
      ],
    );
  }

  String _shortUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return url;
    }
    final host = uri.host;
    final path = uri.path;
    if (host.isEmpty) {
      return path.isEmpty ? url : path;
    }
    return path.isEmpty ? host : '$host$path';
  }
}

/// Template pill chip inside a 44 px hit area: the chip primitive is 32 high,
/// so the wrapper adds the missing touch-target height without changing the
/// pill's visual size.
class _PdfToggle extends StatelessWidget {
  const _PdfToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    void activate() => onTap?.call();
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: activate,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            vertical: context.spacing.micro,
            horizontal: context.spacing.xxs,
          ),
          child: TemplatePillChip(
            label: label,
            selected: selected,
            onTap: activate,
          ),
        ),
      ),
    );
  }
}

class _DeliveryBlock extends ConsumerWidget {
  const _DeliveryBlock({
    required this.item,
    required this.isBusy,
    required this.onRetry,
  });

  final ReportDelivery item;
  final bool isBusy;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = context.ws;
    final spacing = context.spacing;
    final t = UiStrings.of(context);
    final deliveryStatuses = ref.watch(statusesProvider('delivery')).value;
    final language = item.language == 'ar'
        ? t(WorkshopAdminKeys.arabic)
        : t(WorkshopAdminKeys.english);
    final lastError = item.lastErrorMessage?.trim() ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackStatus = constraints.maxWidth < 300;
        final status = ReportStatusPill(
          label: referenceStatusText(deliveryStatuses, item.status),
          tone: referenceStatusTone(deliveryStatuses, item.status),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ws.canvas,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    channelIcon(item.channel),
                    size: 15,
                    color: ws.muted,
                  ),
                ),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Text(
                    item.recipientMasked.isEmpty ? '—' : item.recipientMasked,
                    textDirection: TextDirection.ltr,
                    style: ws.bodyStrong.copyWith(color: ws.ink),
                  ),
                ),
                if (!stackStatus) ...[SizedBox(width: spacing.sm), status],
              ],
            ),
            SizedBox(height: spacing.xs),
            Wrap(
              spacing: spacing.md,
              runSpacing: spacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (stackStatus) status,
                Text(language, style: ws.meta.copyWith(color: ws.muted)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${t(WorkshopAdminKeys.deliveryAttempts)} ',
                      style: ws.meta.copyWith(color: ws.muted),
                    ),
                    Text(
                      '${item.attempts} / ${item.maxAttempts}',
                      textDirection: TextDirection.ltr,
                      style: ws.meta.copyWith(color: ws.muted),
                    ),
                  ],
                ),
                if (item.pdfAttached)
                  Text(
                    t(WorkshopAdminKeys.deliveryPdfAttached),
                    style: ws.meta.copyWith(color: ws.muted),
                  ),
              ],
            ),
            if (lastError.isNotEmpty) ...[
              SizedBox(height: spacing.xs),
              Wrap(
                spacing: spacing.xs,
                runSpacing: spacing.xxs,
                children: [
                  Text(
                    '${t(WorkshopAdminKeys.deliveryError)}:',
                    style: ws.meta.copyWith(color: ws.danger),
                  ),
                  Text(
                    lastError,
                    textDirection: TextDirection.ltr,
                    style: ws.meta.copyWith(color: ws.danger),
                  ),
                ],
              ),
            ],
            if (item.nextAttemptAt.isNotEmpty) ...[
              SizedBox(height: spacing.xs),
              Wrap(
                spacing: spacing.xs,
                runSpacing: spacing.xxs,
                children: [
                  Text(
                    '${t(WorkshopAdminKeys.deliveryNextAttempt)}:',
                    style: ws.meta.copyWith(color: ws.muted),
                  ),
                  Text(
                    '\u202A'
                    '${WorkshopClock.formatInstant(context, item.nextAttemptAt, fallback: item.nextAttemptAt)}'
                    '\u202C',
                    textDirection: TextDirection.ltr,
                    style: ws.meta.copyWith(color: ws.muted),
                  ),
                ],
              ),
            ],
            if (item.retryable) ...[
              SizedBox(height: spacing.sm),
              ReportActionButton(
                label: t(WorkshopAdminKeys.retryDelivery),
                onPressed: isBusy ? null : onRetry,
                icon: Icons.refresh,
                variant: ReportActionVariant.secondary,
                expand: true,
              ),
            ],
          ],
        );
      },
    );
  }
}
