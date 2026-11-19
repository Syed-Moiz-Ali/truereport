import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/templates/template_pills.dart';

/// Role filter as counted pill chips — the control language the jobs and
/// templates modules already use.
///
/// Each chip carries its own count so the roster size is readable without
/// opening a filter menu. '' = all roles. While the roster is loading the
/// counts are unknown (`null`) and no number is drawn, exactly like the jobs
/// queue, so the filter never shows a fabricated zero.
class StaffRoleFilters extends StatelessWidget {
  const StaffRoleFilters({
    required this.counts,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// Role code ('' for all) to count; null while the list is loading.
  final Map<String, int>? counts;
  final String selected;
  final ValueChanged<String> onSelected;

  static const _order = ['', 'TECHNICIAN', 'WORKSHOP_ADMIN'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String labelFor(String value) => switch (value) {
      '' => l10n.filterAll,
      'TECHNICIAN' => l10n.staffFilterTechnicians,
      _ => l10n.staffFilterAdmins,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final value in _order) ...[
            TemplatePillChip(
              key: Key('staff-role-$value'),
              label: labelFor(value),
              count: counts?[value],
              selected: selected == value,
              onTap: () => onSelected(value),
            ),
            if (value != _order.last) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}
