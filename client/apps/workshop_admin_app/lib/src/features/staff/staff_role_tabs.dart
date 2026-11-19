import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/staff/staff_atoms.dart';

/// Role filter as an underlined text row, not a chip bar.
///
/// Each tab carries its own count so the roster size is readable without
/// opening a filter menu. '' = all roles.
class StaffRoleTabs extends StatelessWidget {
  const StaffRoleTabs({
    required this.counts,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// Role code ('' for all) to count.
  final Map<String, int> counts;
  final String selected;
  final ValueChanged<String> onSelected;

  static const _order = ['', 'TECHNICIAN', 'WORKSHOP_ADMIN'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    String labelFor(String value) => switch (value) {
      '' => l10n.filterAll,
      'TECHNICIAN' => l10n.staffFilterTechnicians,
      _ => l10n.staffFilterAdmins,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final value in _order)
            StaffTappable(
              key: Key('staff-role-$value'),
              onTap: () => onSelected(value),
              semanticLabel: '${labelFor(value)} (${counts[value] ?? 0})',
              selected: selected == value,
              selectedSemantics: true,
              builder: (context, state) {
                final active = selected == value;
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Text(
                              labelFor(value),
                              style: ws.body.copyWith(
                                color: active
                                    ? ws.ink
                                    : state.hovered
                                    ? ws.ink
                                    : ws.muted,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${counts[value] ?? 0}',
                              style: ws.meta.copyWith(
                                color: active ? ws.accent : ws.muted,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        height: 2,
                        width: active ? 22 : 0,
                        decoration: BoxDecoration(
                          color: ws.accent,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
