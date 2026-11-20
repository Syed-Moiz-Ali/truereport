import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/reference_status.dart';
import 'package:workshop_admin_app/src/features/templates/template_pills.dart';

/// Role filter as counted pill chips — the control language the jobs and
/// templates modules already use.
///
/// Role codes and labels come from `enumsProvider('role')`; '' = all roles.
/// While the roster is loading the counts are unknown (`null`) and no number is
/// drawn, so the filter never shows a fabricated zero.
class StaffRoleFilters extends ConsumerWidget {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final roles =
        ref.watch(enumsProvider('role')).value ?? const <ReferenceRecord>[];
    final filters = <({String code, String label})>[
      (code: '', label: t(WorkshopAdminKeys.filterAll)),
      for (final record in roles)
        if (record.selectable)
          (
            code: record.code,
            label:
                referenceLabelFor(record) ?? humanizeReferenceCode(record.code),
          ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < filters.length; index++) ...[
            TemplatePillChip(
              key: Key('staff-role-${filters[index].code}'),
              label: filters[index].label,
              count: counts?[filters[index].code],
              selected: selected == filters[index].code,
              onTap: () => onSelected(filters[index].code),
            ),
            if (index != filters.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}
