import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_tokens.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/reference_status.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Where the floor is sitting on the lifecycle, stage by stage.
///
/// Seven on-route stages as proportional bars; rejected and cancelled sit below
/// the rule, off the route. Bar length is relative to the fullest stage, and the
/// count is always printed, so the chart is readable without guessing.
class DashboardLifecycle extends StatelessWidget {
  const DashboardLifecycle({
    required this.counts,
    required this.statuses,
    super.key,
  });

  final CleanJobCounts counts;
  final List<ReferenceRecord>? statuses;

  static const List<String> _route = <String>[
    'DRAFT',
    'SCHEDULED',
    'ASSIGNED',
    'IN_PROGRESS',
    'PENDING_REVIEW',
    'APPROVED',
    'PUBLISHED',
  ];

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    final values = [
      for (final code in _route) dashboardStatusCount(counts, code),
    ];
    final max = values.fold<int>(
      1,
      (best, value) => value > best ? value : best,
    );

    return Container(
      padding: const EdgeInsetsDirectional.all(20),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(DashboardShape.card),
        border: Border.all(color: ws.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t(WorkshopAdminKeys.dashboardPipeline),
            style: DashboardType.cardTitle(ws),
          ),
          const SizedBox(height: 16),
          for (final code in _route)
            _StageRow(
              label: referenceStatusText(statuses, code),
              count: dashboardStatusCount(counts, code),
              fraction: dashboardStatusCount(counts, code) / max,
              color: dashboardToneColor(
                referenceStatusTone(statuses, code),
                ws,
              ),
            ),
          const SizedBox(height: 8),
          Container(height: 1, color: ws.border),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _OffRoute(
                label: referenceStatusText(statuses, 'REJECTED'),
                count: counts.rejected,
                color: ws.danger,
              ),
              _OffRoute(
                label: referenceStatusText(statuses, 'CANCELLED'),
                count: counts.cancelled,
                color: ws.muted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.label,
    required this.count,
    required this.fraction,
    required this.color,
  });

  final String label;
  final int count;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 98,
            child: Text(label, style: DashboardType.registerLabel(ws)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DashboardShape.pill),
              child: Container(
                height: 6,
                color: ws.canvas,
                child: FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: fraction.clamp(0, 1),
                  child: ColoredBox(color: count == 0 ? ws.canvas : color),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 26,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: DashboardType.registerCount(ws)
                  .copyWith(color: count == 0 ? ws.muted : ws.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _OffRoute extends StatelessWidget {
  const _OffRoute({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: DashboardType.registerLabel(ws)),
        const SizedBox(width: 4),
        Text('$count', style: DashboardType.registerCount(ws)),
      ],
    );
  }
}
