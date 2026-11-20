import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import 'settings_primitives.dart';

/// Session region: the only destructive action on the screen.
///
/// Kept apart from the language preference so "sign out" can never be hit
/// while reaching for a language. On wide layouts the action sits at the end of
/// the row; on phones it becomes a full-width, thumb-reachable button.
class SettingsSessionSurface extends StatelessWidget {
  const SettingsSessionSurface({required this.onSignOut, super.key});

  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final ws = context.ws;

    return SettingsSurface(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t(WorkshopAdminKeys.settingsSession),
                style: ws.sectionTitle,
              ),
              const SizedBox(height: 8),
              Text(
                t(WorkshopAdminKeys.settingsSignOutBody),
                style: ws.body.copyWith(color: ws.muted),
              ),
            ],
          );
          final action = SettingsActionButton(
            key: const Key('settings-sign-out'),
            label: t(WorkshopAdminKeys.signOut),
            icon: Icons.logout,
            expand: constraints.maxWidth < 420,
            onPressed: onSignOut,
          );

          if (constraints.maxWidth < 420) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [copy, const SizedBox(height: 20), action],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: copy),
              const SizedBox(width: 24),
              action,
            ],
          );
        },
      ),
    );
  }
}
