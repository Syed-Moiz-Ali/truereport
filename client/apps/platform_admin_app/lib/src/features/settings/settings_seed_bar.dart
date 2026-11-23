import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import 'settings_primitives.dart';
import 'settings_tokens.dart';

const String _maintain = 'MAINTAIN';

/// Region 4 — the only mutating action, separated from navigation and quiet
/// until called. Real copy and data only from the existing message catalog.
class SettingsSeedBar extends StatelessWidget {
  const SettingsSeedBar({
    super.key,
    required this.strings,
    required this.seeding,
    required this.onSeed,
  });

  final UiMessageStrings strings;
  final bool seeding;
  final VoidCallback onSeed;

  @override
  Widget build(BuildContext context) {
    final palette = DeckPalette.of(context);
    return DeckReveal(
      delay: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DeckGroupLabel(label: _maintain),
          const SizedBox(height: 9),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 520;
              final title = Text(
                strings.tKey(PlatformAdminKeys.settingsMaintenanceTitle),
                style: DeckType.style(14, 19, FontWeight.w600, palette.ink),
              );
              final body = Text(
                strings.tKey(PlatformAdminKeys.settingsMaintenanceBody),
                style: DeckType.style(12.5, 18, FontWeight.w400, palette.muted),
              );
              final button = DeckButton(
                label: strings.tKey(PlatformAdminKeys.buttonSeedLoadDefault),
                icon: Icons.cloud_download_outlined,
                loading: seeding,
                onPressed: seeding ? null : onSeed,
              );
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(DeckRadius.card),
                  border: Border.all(color: palette.border),
                ),
                child: stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          title,
                          const SizedBox(height: 6),
                          body,
                          const SizedBox(height: 16),
                          button,
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                title,
                                const SizedBox(height: 5),
                                body,
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          button,
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
