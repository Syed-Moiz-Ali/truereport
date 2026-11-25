import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../platform_theme.dart';
import 'trellis_ui.dart';

class TrellisActions extends StatelessWidget {
  const TrellisActions({
    super.key,
    required this.strings,
    required this.onOpen,
  });

  final UiMessageStrings strings;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        strings.tKey(PlatformAdminKeys.dashboardQuickActionsAddWorkshop),
        '/workshops/new',
      ),
      (
        strings.tKey(PlatformAdminKeys.dashboardQuickActionsCreateTemplate),
        '/checklist/items/new',
      ),
      (
        strings.tKey(PlatformAdminKeys.dashboardQuickActionsAddChecklistItem),
        '/checklist/items',
      ),
      (
        strings.tKey(PlatformAdminKeys.dashboardQuickActionsAddLanguage),
        '/profile/languages',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                strings.tKey(PlatformAdminKeys.dashboardQuickActionsTitle),
                style: Trellis.sectionTitle,
              ),
            ),
            Text(
              '${actions.length}',
              style: Trellis.text(
                11,
                weight: FontWeight.w700,
                tabular: true,
                color: PtTheme.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final action in actions)
              TrellisButton(
                label: action.$1,
                icon: Icons.add_rounded,
                variant: TrellisButtonVariant.secondary,
                compact: true,
                onPressed: () => onOpen(action.$2),
              ),
          ],
        ),
      ],
    );
  }
}
