import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/screens/f2b/f2b_kit.dart';

/// Figma screen 16. Post-finalization success, driven by the real job, report
/// status and delivery records. Delivery success is shown only when the server
/// reports it.
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final finalized = job.status == 'FINALIZED';
    final vin = job.vehicleVin ?? '';
    final vinEnding = vin.length >= 4 ? vin.substring(vin.length - 4) : vin;
    final shownDeliveries = deliveries.take(2).toList(growable: false);

    return Scaffold(
      backgroundColor: Fx.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 0),
                child: Column(
                  children: [
                    Row(
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
                        Expanded(
                          child: Text(
                            job.reference.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            textDirection: TextDirection.ltr,
                            style: Fx.text(
                              11,
                              14,
                              FontWeight.w600,
                              1.1,
                              color: Fx.muted,
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
                    const SizedBox(height: 70),
                    Container(
                      width: 144,
                      height: 144,
                      decoration: const BoxDecoration(
                        color: Fx.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 50,
                            offset: Offset(0, 20),
                          ),
                        ],
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
                    const SizedBox(height: 32),
                    Text(
                      finalized
                          ? l10n.finalizedSuccessfully
                          : l10n.statusInProgress,
                      textAlign: TextAlign.center,
                      style: Fx.display26.copyWith(color: Fx.inkStrong),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report == null
                          ? l10n.reportUnavailable
                          : '${l10n.reportStatus}: '
                                '${report!.generationStatus}',
                      textAlign: TextAlign.center,
                      style: Fx.body14.copyWith(color: Fx.muted),
                    ),
                    const SizedBox(height: 32),
                    FxCard(
                      radius: 32,
                      padding: const EdgeInsets.all(20),
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.noDeliveries,
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
                                    delivery: shownDeliveries[index],
                                  ),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Fx.container,
                        borderRadius: BorderRadius.circular(48),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: F2bKeyValue(
                              label: l10n.technicianVinChassis,
                              value: vinEnding.isEmpty
                                  ? l10n.technicianNotProvided
                                  : '·$vinEnding',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: Fx.surfaceHighest,
                          ),
                          const SizedBox(width: 16),
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: F2bKeyValue(
                              label: l10n.report,
                              value: report == null
                                  ? l10n.technicianNotProvided
                                  : 'v${report!.version}',
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
              padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 20),
              child: FxButton(
                label: l10n.technicianJobsTitle,
                onPressed: onBackToJobs,
                icon: const FxIcon(id: '1_9005', size: 13.33, color: Fx.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryRow extends StatelessWidget {
  const _DeliveryRow({required this.delivery});

  final TechnicianDelivery delivery;

  @override
  Widget build(BuildContext context) {
    final success = delivery.status == 'SENT' || delivery.status == 'DELIVERED';
    final failed =
        delivery.status == 'FAILED' || delivery.status == 'DEAD_LETTER';
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Fx.container,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: FxIcon(id: '1_8953', size: 16.67, color: Fx.muted),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            delivery.channel,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: Fx.title16.copyWith(color: Fx.inkStrong),
          ),
        ),
        F2bStatusPill(
          label: delivery.status,
          background: failed ? const Color(0xFFFFDAD6) : Fx.container,
          foreground: failed ? const Color(0xFFB91A24) : Fx.inkStrong,
          dot: success ? Fx.emerald : null,
          style: Fx.text(
            12,
            16,
            FontWeight.w600,
            0.24,
            color: failed ? const Color(0xFFB91A24) : Fx.inkStrong,
          ),
        ),
      ],
    );
  }
}
