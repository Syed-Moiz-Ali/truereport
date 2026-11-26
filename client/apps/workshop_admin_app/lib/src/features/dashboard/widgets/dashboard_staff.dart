import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_tokens.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_controls.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Who is carrying the floor. Open assignments and completed jobs in the
/// selected range, top five by open work.
class DashboardStaffCard extends StatelessWidget {
  const DashboardStaffCard({
    required this.staff,
    required this.onOpenStaff,
    super.key,
  });

  final DashboardStaff staff;
  final VoidCallback onOpenStaff;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    final maxOpen = staff.top.isEmpty
        ? 1
        : staff.top
              .map((member) => member.openJobs)
              .fold<int>(1, (best, value) => value > best ? value : best);

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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t(WorkshopAdminKeys.dashStaffTitle),
                      style: DashboardType.cardTitle(ws),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      t(WorkshopAdminKeys.dashStaffTechnicians, {
                        'count': staff.technicians,
                      }),
                      style: ws.meta.copyWith(color: ws.muted),
                    ),
                  ],
                ),
              ),
              QueueTextAction(
                label: t(WorkshopAdminKeys.dashViewAll),
                onTap: onOpenStaff,
                icon: Icons.arrow_forward_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: ws.border),
          if (staff.top.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 16),
              child: Text(
                t(WorkshopAdminKeys.dashStaffEmpty),
                style: ws.meta.copyWith(color: ws.muted),
              ),
            )
          else
            for (var index = 0; index < staff.top.length; index++) ...[
              if (index > 0) Container(height: 1, color: ws.border),
              _StaffRow(
                member: staff.top[index],
                maxOpen: maxOpen,
                onTap: onOpenStaff,
              ),
            ],
        ],
      ),
    );
  }
}

class _StaffRow extends StatefulWidget {
  const _StaffRow({
    required this.member,
    required this.maxOpen,
    required this.onTap,
  });

  final DashboardStaffLoad member;
  final int maxOpen;
  final VoidCallback onTap;

  @override
  State<_StaffRow> createState() => _StaffRowState();
}

class _StaffRowState extends State<_StaffRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    return Semantics(
      button: true,
      label:
          '${widget.member.name}, ${t(WorkshopAdminKeys.dashStaffOpen, {'count': widget.member.openJobs})}',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: DashboardMotion.quick,
            color: _hovered ? ws.canvas : Colors.transparent,
            padding: const EdgeInsetsDirectional.symmetric(vertical: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.member.name,
                        style: ws.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ws.ink,
                        ),
                      ),
                    ),
                    Text(
                      t(WorkshopAdminKeys.dashStaffOpen, {
                        'count': widget.member.openJobs,
                      }),
                      style: ws.meta.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ws.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          DashboardShape.pill,
                        ),
                        child: Container(
                          height: 5,
                          color: ws.canvas,
                          child: FractionallySizedBox(
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor:
                                (widget.member.openJobs / widget.maxOpen).clamp(
                                  0,
                                  1,
                                ),
                            child: ColoredBox(color: ws.accent),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t(WorkshopAdminKeys.dashStaffCompleted, {
                        'count': widget.member.completed,
                      }),
                      style: ws.meta.copyWith(fontSize: 11.5, color: ws.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
