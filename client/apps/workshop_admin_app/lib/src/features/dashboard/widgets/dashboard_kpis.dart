import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_tokens.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Four real counts, not four cards of prose: waiting, in the bay, ready,
/// published. The total lives in the header, so it is not repeated here.
class DashboardKpis extends StatelessWidget {
  const DashboardKpis({required this.counts, required this.compact, super.key});

  final CleanJobCounts counts;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    final tiles = [
      _Kpi(
        label: t(WorkshopAdminKeys.dashPendingReviews),
        value: counts.pendingReview,
        tone: ws.warning,
      ),
      _Kpi(
        label: t(WorkshopAdminKeys.dashGroupInBay),
        value: counts.inProgress,
        tone: ws.accent,
      ),
      _Kpi(
        label: t(WorkshopAdminKeys.dashGroupReady),
        value: counts.approved,
        tone: ws.success,
      ),
      _Kpi(
        label: t(WorkshopAdminKeys.dashPublishedReports),
        value: counts.published,
        tone: ws.ink,
      ),
    ];

    Widget tile(_Kpi item) => Expanded(
      child: Container(
        padding: EdgeInsetsDirectional.all(compact ? 16 : 20),
        decoration: BoxDecoration(
          color: ws.surface,
          borderRadius: BorderRadius.circular(DashboardShape.card),
          border: Border.all(color: ws.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: item.tone,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    item.label,
                    style: ws.meta.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ws.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$item',
              style: DashboardType.tileNumber(ws).copyWith(color: ws.ink),
            ),
          ],
        ),
      ),
    );

    if (!compact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < tiles.length; index++) ...[
            if (index > 0) const SizedBox(width: 12),
            tile(tiles[index]),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [tile(tiles[0]), const SizedBox(width: 12), tile(tiles[1])],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [tile(tiles[2]), const SizedBox(width: 12), tile(tiles[3])],
        ),
      ],
    );
  }
}

class _Kpi {
  const _Kpi({required this.label, required this.value, required this.tone});

  final String label;
  final int value;
  final Color tone;

  @override
  String toString() => '$value';
}
