import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workshop_admin_app/src/features/staff/staff_atoms.dart';
import 'package:workshop_admin_app/src/models.dart';

/// One person in the roster table.
///
/// The row is an index entry, not an editor: monogram, name, role, account
/// state and the masked email, and it opens the member page. Below 1000 px the
/// role and email move under the name so the table never squeezes the identity.
class StaffRosterRow extends ConsumerWidget {
  const StaffRosterRow({
    required this.member,
    required this.wide,
    required this.onTap,
    super.key,
  });

  final StaffMember member;

  /// True when the roster lays out as a table line with header row columns.
  final bool wide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = context.ws;
    final roleLabel = staffRoleLabel(ref, member.role);
    final semantics = [
      member.displayName,
      roleLabel,
      staffStatusLabel(ref, member.status),
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
          border: state.focused
              ? Border.all(color: ws.focus, width: 2)
              : BorderDirectional(top: BorderSide(color: ws.border)),
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(18, 13, 14, 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            StaffMonogram(name: member.displayName, size: wide ? 38 : 34),
            SizedBox(width: wide ? 14 : 10),
            Expanded(
              child: wide
                  ? Text(
                      member.displayName,
                      style: ws.body.copyWith(
                        color: ws.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : _stacked(context, roleLabel),
            ),
            if (wide) ...[
              SizedBox(
                width: 110,
                child: Text(
                  roleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ws.meta.copyWith(color: ws.muted),
                ),
              ),
              SizedBox(
                width: 140,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: StaffStatusDot(status: member.status, pill: true),
                ),
              ),
              SizedBox(
                width: 220,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 10),
                  child: Text(
                    member.emailMasked,
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ws.meta.copyWith(color: ws.muted),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(width: 10),
            ],
            const SizedBox(width: 6),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              size: 18,
              color: state.hovered ? ws.ink : ws.muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stacked(BuildContext context, String roleLabel) {
    final ws = context.ws;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          member.displayName,
          style: ws.body.copyWith(color: ws.ink, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 3),
        Text(roleLabel, style: ws.meta.copyWith(color: ws.muted)),
        const SizedBox(height: 3),
        Text(
          member.emailMasked,
          textDirection: TextDirection.ltr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ws.meta.copyWith(color: ws.muted),
        ),
        const SizedBox(height: 10),
        StaffStatusDot(status: member.status, pill: true),
      ],
    );
  }
}
