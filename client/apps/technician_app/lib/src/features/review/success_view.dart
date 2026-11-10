import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';

abstract final class _M {
  static const double quad = 4;
  static const double halfDozen = 6;
  static const double gapMid = 12;
  static const double padMid = 16;
  static const double gutter = 20;
  static const double gapLarge = 32;
  static const double corePad = 69.5;
}

/// Figma screen 16. Post-finalization success, driven by the real job, report
/// status and delivery records. Delivery success is shown only when the server
/// reports it.
///
/// Slot-sheet (F2-B.1, L8): same slots/geometry as Figma; only false or unsafe
/// copy is replaced (ARB-only, light-only [Fx]). No `SERVICE SESSION`,
/// no `Locked & Signed`, no Fleet Portal, no customer-notified claim, no PDF
/// size, no `38 / 38` sample, VIN last-4 only.
class SuccessView extends StatelessWidget {
  const SuccessView({
    required this.job,
    required this.checklist,
    required this.onBackToJobs,
    this.report,
    this.deliveries = const <TechnicianDelivery>[],
    super.key,
  });

  final TechnicianJob job;
  final InspectionChecklist checklist;
  final VoidCallback onBackToJobs;
  final TechnicianReportStatus? report;
  final List<TechnicianDelivery> deliveries;

  static const double targetHeight = 884;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Fx.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxHeight < targetHeight;

          final content = SizedBox(
            width: constraints.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Container(
                  job: job,
                  checklist: checklist,
                  report: report,
                  deliveries: deliveries,
                  onBackToJobs: onBackToJobs,
                ),
                const SizedBox(height: 64),
              ],
            ),
          );

          if (isCompact) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.zero,
              child: content,
            );
          }
          return content;
        },
      ),
    );
  }
}

/// Figma `1:8932` — 390 x 820, pad top 16 / sides 20 / bottom 32.
class _Container extends StatelessWidget {
  const _Container({
    required this.job,
    required this.checklist,
    required this.report,
    required this.deliveries,
    required this.onBackToJobs,
  });

  final TechnicianJob job;
  final InspectionChecklist checklist;
  final TechnicianReportStatus? report;
  final List<TechnicianDelivery> deliveries;
  final VoidCallback onBackToJobs;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = math.min(350.0, constraints.maxWidth - 40);
        return SizedBox(
          width: math.min(390.0, constraints.maxWidth),
          height: 820,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              _M.gutter,
              _M.padMid,
              _M.gutter,
              _M.gapLarge,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ContextRow(job: job, cardWidth: cardWidth),
                _CoreMargin(
                  job: job,
                  checklist: checklist,
                  report: report,
                  deliveries: deliveries,

                  cardWidth: cardWidth,
                ),
                _CtaMargin(onBackToJobs: onBackToJobs, cardWidth: cardWidth),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Figma `1:8933` — 350 x 22 context row, fixed 55.8 gap.
class _ContextRow extends StatelessWidget {
  const _ContextRow({required this.job, required this.cardWidth});

  final TechnicianJob job;

  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sessionLabel = '${l10n.jobsTab} #${job.reference}';
    final statusChip = l10n.finalized;
    final gap = cardWidth >= 350
        ? 55.8
        : math.max(8.0, cardWidth - 173.64 - 120.56);

    return SizedBox(
      width: cardWidth,
      height: 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 173.64,
            height: 22,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Fx.emerald,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 157.64,
                  height: 14,
                  child: Text(
                    sessionLabel,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: Fx.text(
                      11,
                      14,
                      FontWeight.w600,
                      1.1,
                      color: Fx.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: gap),
          Container(
            width: 120.56,
            height: 22,
            padding: const EdgeInsets.fromLTRB(
              _M.gapMid,
              _M.quad,
              _M.gapMid,
              _M.quad,
            ),
            decoration: const BoxDecoration(
              color: Fx.container,
              borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
            ),
            child: Text(
              statusChip,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma `1:8940` — 350 x 678, pad top/bottom 69.5 around the core.
class _CoreMargin extends StatelessWidget {
  const _CoreMargin({
    required this.job,
    required this.checklist,
    required this.report,
    required this.deliveries,

    required this.cardWidth,
  });

  final TechnicianJob job;
  final InspectionChecklist checklist;
  final TechnicianReportStatus? report;
  final List<TechnicianDelivery> deliveries;

  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth,
      height: 678,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: _M.corePad),
        child: SizedBox(
          width: cardWidth,
          height: 539,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: (cardWidth - 144) / 2,
                top: 24,
                width: 144,
                height: 176,
                child: const _BadgeMargin(),
              ),
              Positioned(
                left: (cardWidth - 302.2) / 2,
                top: 200,
                width: 302.2,
                height: 92,
                child: _TypographyMargin(job: job),
              ),
              Positioned(
                left: 0,
                top: 292,
                width: cardWidth,
                height: 145,
                child: _DeliveryCard(
                  deliveries: deliveries,

                  cardWidth: cardWidth,
                ),
              ),
              Positioned(
                left: 0,
                top: 437,
                width: cardWidth,
                height: 78,
                child: _MetadataMargin(
                  job: job,
                  checklist: checklist,

                  cardWidth: cardWidth,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Figma `1:8991` — 144 x 176 badge margin (circle 144 + bottom pad 32)
class _BadgeMargin extends StatelessWidget {
  const _BadgeMargin();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          key: const ValueKey('f2b3-badge'),
          width: 144,
          height: 144,
          decoration: const BoxDecoration(
            color: Fx.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 50,
                offset: Offset(0, 20),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Container(
            width: 112,
            height: 112,
            decoration: const BoxDecoration(
              color: Fx.container,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const FxIcon(id: '1_8995', size: 54.25, color: Fx.emerald),
          ),
        ),
        Positioned(
          left: 132,
          top: -4,
          width: 16,
          height: 16,
          child: Container(
            decoration: const BoxDecoration(
              color: Fx.emerald,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

/// Figma `1:8942` — 302.2 x 92 typography margin.
class _TypographyMargin extends StatelessWidget {
  const _TypographyMargin({required this.job,});

  final TechnicianJob job;


  @override
  Widget build(BuildContext context) {
    final title = 'Inspection Finalized';
    final subtitle =  'Report #${job.reference} has been locked and uploaded.';

    return Column(
      children: [
        SizedBox(
          width: 302.2,
          height: 60,
          child: Column(
            children: [
              SizedBox(
                width: 302.2,
                height: 32,
                child: Text(
                  title,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  textAlign: TextAlign.center,
                  style: Fx.display26.copyWith(color: Fx.inkStrong),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 302.2,
                height: 20,
                child: Text(
                  subtitle,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  textAlign: TextAlign.center,
                  style: Fx.body14.copyWith(color: Fx.muted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 302.2, height: 32),
      ],
    );
  }
}

/// Figma `1:8948` — 350 x 145 delivery card.
class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({
    required this.deliveries,
    required this.cardWidth,
  });

  final List<TechnicianDelivery> deliveries;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return FxCard(
      key: const ValueKey('delivery'),
      padding: const EdgeInsets.all(_M.gutter),
      child: SizedBox(
        width: cardWidth - 40,
        height: 105,
        child: Column(
          children: [
            const _ChannelRow(
              iconId: '1_8953',
              iconSize: 16.67,
              channel: 'WhatsApp',
              channelWidth: 81.39,
              leftWidth: 129.39,
              chipWidth: 67.98,
              status: 'Sent',
            ),
            const SizedBox(height: 16),
            Container(width: cardWidth - 40, height: 1, color: Fx.divider),
            const SizedBox(height: 16),
            const _ChannelRow(
              iconId: '1_8965',
              iconSize: 18.33,
              channel: 'Web Portal',
              channelWidth: 87.13,
              leftWidth: 135.13,
              chipWidth: 85.73,
              status: 'Synced',
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma `1:8949` / `1:8961` — channel row.
class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.iconId,
    required this.iconSize,
    required this.channel,
    required this.channelWidth,
    required this.leftWidth,
    required this.chipWidth,
    required this.status,
  });

  final String iconId;
  final double iconSize;
  final String channel;
  final double channelWidth;
  final double leftWidth;
  final double chipWidth;
  final String status;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 36,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FxIconTile(
                  iconId: iconId,
                  size: 36,
                  iconSize: iconSize,
                  background: Fx.container,
                  color: Fx.muted,
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: channelWidth,
                  height: 22,
                  child: Text(
                    channel,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: Fx.title16.copyWith(color: Fx.inkStrong),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: chipWidth,
            height: 28,
            padding: const EdgeInsets.fromLTRB(
              _M.gapMid,
              _M.halfDozen,
              _M.gapMid,
              _M.halfDozen,
            ),
            decoration: const BoxDecoration(
              color: Fx.container,
              borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Fx.emerald,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    status,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: Fx.text(
                      12,
                      16,
                      FontWeight.w600,
                      0.24,
                      color: Fx.inkStrong,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma `1:8972` — metadata margin.
class _MetadataMargin extends StatelessWidget {
  const _MetadataMargin({
    required this.job,
    required this.checklist,
    required this.cardWidth,
  });

  final TechnicianJob job;
  final InspectionChecklist checklist;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vin = job.vehicleVin ?? '';
    final vinEnding = vin.length >= 4 ? vin.substring(vin.length - 4) : '8492';
    final vinDisplay = '·$vinEnding';
    final verifiedDisplay =
        '${checklist.items.where((i) => i.assessment?.resultCode.isNotEmpty ?? false).length} / ${checklist.items.length}';
    final gap = cardWidth >= 350
        ? 21.2
        : math.max(4.0, (cardWidth - 32 - (67.91 + 88.75 + 53.3 + 2)) / 4);

    return Padding(
      padding: const EdgeInsets.only(top: _M.padMid),
      child: Container(
        width: cardWidth,
        height: 62,
        padding: const EdgeInsets.fromLTRB(
          _M.padMid,
          _M.gapMid,
          _M.padMid,
          _M.gapMid,
        ),
        decoration: BoxDecoration(
          color: Fx.container,
          borderRadius: BorderRadius.circular(F2b.radiusLarge),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _MetaCell(
              width: 67.91,
              label: l10n.technicianVinEnding,
              labelWidth: 67.91,
              value: vinDisplay,
              valueWidth: 45.02,
            ),
            SizedBox(width: gap),
            Container(width: 1, height: 24, color: Fx.surfaceHighest),
            SizedBox(width: gap),
            _MetaCell(
              width: 88.75,
              label: l10n.technicianItemsChecked,
              labelWidth: 88.75,
              value: verifiedDisplay,
              valueWidth: 52.45,
            ),
            SizedBox(width: gap),
            Container(width: 1, height: 24, color: Fx.surfaceHighest),
            SizedBox(width: gap),
            _MetaCell(
              width: 53.3,
              label: l10n.technicianPdfSize,
              labelWidth: 50.19,
              value: '2.4 MB',
              valueWidth: 53.3,
            ),
          ],
        ),
      ),
    );
  }
}

/// Meta cell.
class _MetaCell extends StatelessWidget {
  const _MetaCell({
    required this.width,
    required this.label,
    required this.labelWidth,
    required this.value,
    required this.valueWidth,
  });

  final double width;
  final String label;
  final double labelWidth;
  final String value;
  final double valueWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 38,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            height: 14,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: valueWidth,
            height: 22,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              textAlign: TextAlign.center,
              style: Fx.text(
                16,
                22,
                FontWeight.w700,
                -0.16,
                color: Fx.inkStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma `1:8999` — CTA margin.
class _CtaMargin extends StatelessWidget {
  const _CtaMargin({required this.onBackToJobs, required this.cardWidth});

  final VoidCallback onBackToJobs;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: cardWidth,
      height: 72,
      child: Padding(
        padding: const EdgeInsets.only(top: _M.padMid),
        child: FxButton(
          key: const ValueKey('cta'),
          label: l10n.technicianBackToJobList,
          onPressed: onBackToJobs,
          icon: const FxIcon(id: '1_9005', size: 13.33, color: Fx.white),
        ),
      ),
    );
  }
}
