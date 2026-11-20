import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import 'widgets/settings_geometry.dart';
import 'widgets/settings_language_surface.dart';
import 'widgets/settings_record_plate.dart';
import 'widgets/settings_session_surface.dart';

/// Workshop settings, rebuilt around a workshop record.
///
/// Only real session data and real preferences: the workshop, the signed-in
/// administrator, the interface language and sign-out. There are no feature
/// toggles, no security switches and no invented account fields.
///
/// Wide layouts read as a record plate (identity) beside a working column
/// (language, then session). Phones stack the same three regions in the same
/// order, with the destructive action last and full width.
class WorkshopSettingsPage extends ConsumerWidget {
  const WorkshopSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(authControllerProvider).value;

    final displayName = session?.user.displayName.trim() ?? '';
    final email = session?.user.email.trim() ?? '';
    final workshopName = session != null && session.memberships.isNotEmpty
        ? session.memberships.first.workshopName
        : l10n.workshopAdminTitle;
    final accountName = displayName.isEmpty
        ? l10n.roleWorkshopAdmin
        : displayName;

    return WorkshopPageScroll(
      key: const Key('settings-screen'),
      children: [
        const _SettingsHeading(),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumn =
                constraints.maxWidth >= SettingsGeometry.twoColumnBreakpoint;
            final record = SettingsRecordPlate(
              workshopName: workshopName,
              personName: accountName,
              email: email,
              roleLabel: l10n.roleWorkshopAdmin,
              isCompact: !twoColumn,
            );
            final working = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SettingsLanguageSurface(),
                const SizedBox(height: SettingsGeometry.sectionGap),
                SettingsSessionSurface(
                  onSignOut: () =>
                      ref.read(authControllerProvider.notifier).signOut(),
                ),
              ],
            );

            if (!twoColumn) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [record, const SizedBox(height: 24), working],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: SettingsGeometry.recordWidth, child: record),
                const SizedBox(width: SettingsGeometry.columnGap),
                Expanded(child: working),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

/// Page identity: what this page is, in one line, without repeating the
/// workshop name that the record plate already carries.
class _SettingsHeading extends StatelessWidget {
  const _SettingsHeading();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.settings, style: ws.pageTitle),
        ),
        const SizedBox(height: 6),
        Text(l10n.settingsSubtitle, style: ws.body.copyWith(color: ws.muted)),
      ],
    );
  }
}
