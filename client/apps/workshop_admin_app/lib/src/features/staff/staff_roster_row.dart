import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:workshop_admin_app/src/features/staff/staff_atoms.dart';
import 'package:workshop_admin_app/src/models.dart';

/// One person in the roster.
///
/// The row is an index entry, not an editor: name, role and account state, and
/// it opens the member page. No email here — the member page owns the
/// credential detail, so nothing is duplicated between the two screens.
class StaffRosterRow extends StatelessWidget {
  const StaffRosterRow({
    required this.member,
    required this.wide,
    required this.roomy,
    required this.onTap,
    super.key,
  });

  final StaffMember member;

  /// True when the row lays out as a table line (single line, trailing chevron).
  final bool wide;

  /// True when the ledger has room for a separate role column.
  final bool roomy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final roleLabel = staffRoleLabel(context, member.role);
    final semantics = [
      member.displayName,
      roleLabel,
      staffStatusLabel(context, member.status),
    ].join(', ');

    return StaffTappable(
      key: Key('staff-${member.userId}'),
      onTap: onTap,
      semanticLabel: semantics,
      builder: (context, state) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: state.hovered ? ws.canvas : ws.surface,
          border: BorderDirectional(top: BorderSide(color: ws.border)),
          boxShadow: state.focused
              ? [
                  BoxShadow(
                    color: ws.focus.withValues(alpha: 0.55),
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        padding: EdgeInsetsDirectional.fromSTEB(22, 14, wide ? 14 : 10, 14),
        child: Row(
          children: [
            StaffMonogram(name: member.displayName, size: wide ? 38 : 34),
            SizedBox(width: wide ? 14 : 10),
            Expanded(
              child: wide && roomy
                  ? Text(
                      member.displayName,
                      style: ws.rowName.copyWith(color: ws.ink),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          member.displayName,
                          style: ws.rowName.copyWith(color: ws.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          roleLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ws.meta.copyWith(color: ws.muted),
                        ),
                      ],
                    ),
            ),
            if (wide && roomy) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: Text(
                  roleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ws.meta.copyWith(color: ws.muted),
                ),
              ),
            ],
            SizedBox(
              width: wide ? 150 : 132,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: StaffStatusDot(status: member.status),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: state.hovered ? ws.ink : ws.muted,
            ),
          ],
        ),
      ),
    );
  }
}
