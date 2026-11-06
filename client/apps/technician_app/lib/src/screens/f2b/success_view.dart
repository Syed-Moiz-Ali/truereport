import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/screens/f2b/f2b_kit.dart';

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

  static bool _isKnownChannel(String channel) {
    final normalized = channel.toUpperCase();
    return normalized == 'WHATSAPP' ||
        normalized == 'SMS' ||
        normalized == 'EMAIL';
  }

  String _channelLabel(AppLocalizations l10n, String channel) {
    switch (channel.toUpperCase()) {
      case 'WHATSAPP':
        return l10n.channelWhatsapp;
      case 'SMS':
        return l10n.channelSms;
      case 'EMAIL':
        return l10n.channelEmail;
      default:
        return '';
    }
  }

  String _deliveryLabel(AppLocalizations l10n, String status) {
    switch (status.toUpperCase()) {
      case 'SENT':
      case 'DELIVERED':
        return l10n.deliverySent;
      case 'FAILED':
      case 'DEAD_LETTER':
        return l10n.reportFailed;
      default:
        return l10n.deliveryQueued;
    }
  }

  String _reportState(AppLocalizations l10n, TechnicianReportStatus report) {
    switch (report.generationStatus.toUpperCase()) {
      case 'READY':
        return l10n.reportReady;
      case 'FAILED':
        return l10n.reportFailed;
      default:
        return l10n.generating;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final finalized = job.status == 'FINALIZED';
    final vin = job.vehicleVin ?? '';
    final vinEnding = vin.length >= 4 ? vin.substring(vin.length - 4) : vin;
    // ARB-only channels: unknown channels (incl. any future "Fleet Portal")
    // are never rendered, so no fleet surface can appear.
    final shownDeliveries = deliveries
        .where((d) => _isKnownChannel(d.channel))
        .take(2)
        .toList(growable: false);
    final reportLine = report == null
        ? l10n.reportUnavailable
        : '${l10n.reportStatus}: ${_reportState(l10n, report!)}';
    final heading = finalized ? l10n.finalizedSuccessfully : l10n.statusInProgress;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: Fx.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.fromSTEB(_M.gutter, _M.padMid, _M.gutter, 0),
                child: Column(
                  children: [
                    Semantics(
                      label: '${job.reference} ${finalized ? l10n.finalized : l10n.statusInProgress}',
                      child: Row(
                        children: [
                          ExcludeSemantics(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Fx.emerald,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: _M.gapSmall),
                          Expanded(
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                job.reference.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Fx.text(
                                  11,
                                  14,
                                  FontWeight.w600,
                                  1.1,
                                  color: Fx.muted,
                                ),
                              ),
                            ),
                          ),
                          F2bStatusPill(
                            label: finalized
                                ? l10n.finalized
                                : l10n.statusInProgress,
                            background: Fx.container,
                            foreground: Fx.muted,
                            style: Fx.caption.copyWith(color: Fx.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 70),
                    // Decorative success medallion (Figma 144px double circle).
                    ExcludeSemantics(
                      child: Container(
                        width: 144,
                        height: 144,
                        decoration: const BoxDecoration(
                          color: Fx.white,
                          shape: BoxShape.circle,
                          // Light-only Fx shadows (badge: Figma offsets
                          // 0,4 + 0,20; Fx.navShadow uses 0,4 + 0,18).
                          boxShadow: Fx.navShadow,
                        ),
                        child: Center(
                          child: Container(
                            width: 112,
                            height: 112,
                            decoration: const BoxDecoration(
                              color: Fx.container,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: FxIcon(
                                id: '1_8995',
                                size: 54.25,
                                color: Fx.emerald,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: _M.gapLarge),
                    Semantics(
                      header: true,
                      liveRegion: true,
                      label: '$heading. $reportLine',
                      child: Column(
                        children: [
                          Text(
                            heading,
                            textAlign: TextAlign.center,
                            style: Fx.display26.copyWith(color: Fx.inkStrong),
                          ),
                          const SizedBox(height: _M.gapSmall),
                          Text(
                            reportLine,
                            textAlign: TextAlign.center,
                            style: Fx.body14.copyWith(color: Fx.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: _M.gapLarge),
                    FxCard(
                      radius: 32,
                      padding: const EdgeInsets.all(_M.gutter),
                      child: shownDeliveries.isEmpty
                          ? Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Fx.container,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: FxIcon(
                                      id: '1_8953',
                                      size: 16.67,
                                      color: Fx.muted,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: _M.gapMid),
                                Expanded(
                                  child: Text(
                                    l10n.noDeliveries,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Fx.title16.copyWith(
                                      color: Fx.inkStrong,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                for (
                                  var index = 0;
                                  index < shownDeliveries.length;
                                  index++
                                ) ...[
                                  if (index > 0)
                                    Container(
                                      height: 1,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      color: Fx.divider,
                                    ),
                                  _DeliveryRow(
                                    channelLabel: _channelLabel(
                                      l10n,
                                      shownDeliveries[index].channel,
                                    ),
                                    statusLabel: _deliveryLabel(
                                      l10n,
                                      shownDeliveries[index].status,
                                    ),
                                    status: shownDeliveries[index].status,
                                    iconId: shownDeliveries[index].channel
                                                .toUpperCase() ==
                                            'EMAIL'
                                        ? '1_8965'
                                        : '1_8953',
                                  ),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: _M.padMid),
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Fx.container,
                        borderRadius: BorderRadius.circular(_M.radiusLarge),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: F2bKeyValue(
                                label: l10n.technicianVinChassis,
                                value: vinEnding.isEmpty
                                    ? l10n.technicianNotProvided
                                    : '·$vinEnding',
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: Fx.surfaceHighest,
                          ),
                          const SizedBox(width: _M.padMid),
                          Expanded(
                            child: F2bKeyValue(
                              label: l10n.completedItems,
                              value:
                                  '${checklist.completed} / ${checklist.total}',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: Fx.surfaceHighest,
                          ),
                          const SizedBox(width: _M.padMid),
                          Expanded(
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: F2bKeyValue(
                                label: l10n.report,
                                value: report == null
                                    ? l10n.technicianNotProvided
                                    : 'v${report!.version}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(_M.gutter, _M.padMid, _M.gutter, _M.gutter),
              child: F2bFocusFrame(
                child: FxButton(
                  label: l10n.technicianJobsTitle,
                  onPressed: onBackToJobs,
                  // Mirror the Figma arrow in RTL; icon itself stays Fx.
                  icon: rtl
                      ? const Directionality(
                          textDirection: TextDirection.ltr,
                          child: _MirroredArrow(),
                        )
                      : const FxIcon(
                          id: '1_9005',
                          size: 13.33,
                          color: Fx.white,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MirroredArrow extends StatelessWidget {
  const _MirroredArrow();

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: true,
      child: const FxIcon(id: '1_9005', size: 13.33, color: Fx.white),
    );
  }
}

class _DeliveryRow extends StatelessWidget {
  const _DeliveryRow({
    required this.channelLabel,
    required this.statusLabel,
    required this.status,
    required this.iconId,
  });

  final String channelLabel;
  final String statusLabel;
  final String status;
  final String iconId;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final success = normalized == 'SENT' || normalized == 'DELIVERED';
    final failed = normalized == 'FAILED' || normalized == 'DEAD_LETTER';
    return Semantics(
      label: '$channelLabel. $statusLabel',
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Fx.container,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: FxIcon(id: iconId, size: 16.67, color: Fx.muted),
            ),
          ),
          const SizedBox(width: _M.gapMid),
          Expanded(
            child: Text(
              channelLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Fx.title16.copyWith(color: Fx.inkStrong),
            ),
          ),
          F2bStatusPill(
            label: statusLabel,
            background: Fx.container,
            foreground: failed ? Fx.dangerRed : Fx.inkStrong,
            dot: success ? Fx.emerald : null,
            style: Fx.text(
              12,
              16,
              FontWeight.w600,
              0.24,
              color: failed ? Fx.dangerRed : Fx.inkStrong,
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma-exact spacing/radii for this screen (F2-A `_M` pattern).
abstract final class _M {
  static const double gapSmall = 8;
  static const double gapMid = 12;
  static const double padMid = 16;
  static const double gutter = 20;
  static const double gapLarge = 32;
  static const double radiusLarge = 48;
}
