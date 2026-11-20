import 'package:design_system/src/components/shell/shell_destination.dart';
import 'package:design_system/src/components/shell/shell_dock.dart';
import 'package:design_system/src/components/shell/shell_identity_strip.dart';
import 'package:design_system/src/workshop_tokens.dart';
import 'package:flutter/material.dart';

export 'shell/shell_destination.dart';

/// Responsive Workshop Admin chrome - direction C "The dock".
///
/// One identity strip at the top, one floating dock at the bottom, and the work
/// in between at full width. There is no sidebar, no top-bar breadcrumb and no
/// "More" sheet: the same six destinations are reachable at every size.
///
/// The content area reserves the dock's height ([WorkshopShellDock.reserve]), so
/// no screen has to know the dock exists and no list is ever trapped behind it.
///
/// Layout uses directional insets and alignment, so an RTL locale mirrors the
/// strip and the dock.
class WorkshopAppShell extends StatelessWidget {
  const WorkshopAppShell({
    required this.workshopName,
    required this.sectionLabel,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
    required this.accountInitials,
    required this.accountName,
    required this.accountEmail,
    required this.onSettings,
    required this.onSignOut,
    required this.onToggleLanguage,
    required this.languageLabel,
    required this.child,
    this.moreLabel = 'More',
    this.signOutLabel = '',
    this.settingsLabel = 'Settings',
    this.notificationsAction,
    this.navigationLabel = '',
    super.key,
  });

  final String workshopName;

  /// Kept for API compatibility with the host; the dock shows the selected
  /// destination's own label, so the breadcrumb no longer needs it.
  final String sectionLabel;

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<WorkshopNavDestination> destinations;

  final String accountInitials;
  final String accountName;
  final String accountEmail;
  final VoidCallback onSettings;
  final VoidCallback onSignOut;
  final VoidCallback onToggleLanguage;
  final String languageLabel;

  /// Kept for API compatibility. The dock never overflows, so no "More" surface
  /// exists any more.
  final String moreLabel;

  final String signOutLabel;
  final String settingsLabel;
  final Widget child;
  final Widget? notificationsAction;

  /// Screen-reader name for the navigation landmark.
  final String navigationLabel;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final reserve = WorkshopShellDock.reserve(context);
    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ShellIdentityStrip(
                  workshopName: workshopName,
                  accountInitials: accountInitials,
                  accountName: accountName,
                  accountEmail: accountEmail,
                  onSettings: onSettings,
                  onSignOut: onSignOut,
                  onToggleLanguage: onToggleLanguage,
                  languageLabel: languageLabel,
                  settingsLabel: settingsLabel,
                  signOutLabel: signOutLabel,
                  notificationsAction: notificationsAction,
                ),
                Expanded(
                  // The dock floats over this reserved band; content scrolls
                  // clear of it without knowing it is there.
                  child: Padding(
                    padding: EdgeInsets.only(bottom: reserve),
                    child: child,
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: WorkshopShellDock(
                      destinations: destinations,
                      selectedIndex: selectedIndex,
                      onSelected: onSelected,
                      navigationLabel: navigationLabel,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
