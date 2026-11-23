import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import 'settings_primitives.dart';
import 'settings_tokens.dart';

/// Region 1 — identity. One scope badge, one title, one sentence. No actions.
class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key, required this.strings});

  final UiMessageStrings strings;

  @override
  Widget build(BuildContext context) {
    final palette = DeckPalette.of(context);
    final compact = MediaQuery.sizeOf(context).width < 640;
    return DeckReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.tKey(PlatformAdminKeys.settingsScopeBadge),
            style: DeckType.style(
              11,
              14,
              FontWeight.w700,
              palette.accent,
              tracking: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.tKey(PlatformAdminKeys.pageSettingsHeading),
            style: DeckType.style(
              compact ? 26 : 30,
              compact ? 32 : 37,
              FontWeight.w700,
              palette.ink,
              tracking: -0.8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            strings.tKey(PlatformAdminKeys.pageSettingsSubtitle),
            style: DeckType.style(13, 19, FontWeight.w400, palette.muted),
          ),
        ],
      ),
    );
  }
}
