import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_format.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_tokens.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/reference_status.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// What just happened on the floor: the last status moves, newest first.
/// A row opens the job it belongs to.
class DashboardActivityCard extends StatelessWidget {
  const DashboardActivityCard({
    required this.activity,
    required this.statuses,
    required this.onOpenJob,
    super.key,
  });

  final List<DashboardActivity> activity;
  final List<ReferenceRecord>? statuses;
  final void Function(String jobId) onOpenJob;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);

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
            t(WorkshopAdminKeys.dashActivityTitle),
            style: DashboardType.cardTitle(ws),
          ),
          const SizedBox(height: 10),
          if (activity.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 8, bottom: 4),
              child: Text(
                t(WorkshopAdminKeys.dashActivityEmpty),
                style: ws.meta.copyWith(color: ws.muted),
              ),
            )
          else
            for (var index = 0; index < activity.length; index++) ...[
              if (index > 0) Container(height: 1, color: ws.border),
              _ActivityRow(
                item: activity[index],
                statuses: statuses,
                onOpen: () => onOpenJob(activity[index].jobId),
              ),
            ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatefulWidget {
  const _ActivityRow({
    required this.item,
    required this.statuses,
    required this.onOpen,
  });

  final DashboardActivity item;
  final List<ReferenceRecord>? statuses;
  final VoidCallback onOpen;

  @override
  State<_ActivityRow> createState() => _ActivityRowState();
}

class _ActivityRowState extends State<_ActivityRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    final item = widget.item;
    final from = referenceStatusText(widget.statuses, item.fromStatus);
    final to = referenceStatusText(widget.statuses, item.toStatus);
    final relative = dashboardRelative(
      item.occurredAt,
      minutes: t(WorkshopAdminKeys.dashAgoMinutes),
      hours: t(WorkshopAdminKeys.dashAgoHours),
      days: t(WorkshopAdminKeys.dashAgoDays),
    );
    final actor = item.actor?.trim() ?? '';
    final enabled = item.jobId.isNotEmpty;

    return Semantics(
      button: enabled,
      label: [
        to,
        item.reference,
        if (actor.isNotEmpty) actor,
        relative,
      ].join('. '),
      excludeSemantics: true,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? widget.onOpen : null,
          child: AnimatedContainer(
            duration: DashboardMotion.quick,
            color: _hovered ? ws.canvas : Colors.transparent,
            padding: const EdgeInsetsDirectional.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3,
                  height: 30,
                  margin: const EdgeInsetsDirectional.only(top: 2),
                  decoration: BoxDecoration(
                    color: dashboardToneColor(
                      referenceStatusTone(widget.statuses, item.toStatus),
                      ws,
                    ),
                    borderRadius: BorderRadius.circular(DashboardShape.pill),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        from.isEmpty ? to : '$from  →  $to',
                        style: ws.body.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ws.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          item.reference,
                          if (actor.isNotEmpty) actor,
                          if (relative.isNotEmpty) relative,
                        ].join('  ·  '),
                        style: ws.meta.copyWith(
                          fontSize: 11.5,
                          color: ws.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (enabled)
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: _hovered ? ws.accent : ws.muted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
