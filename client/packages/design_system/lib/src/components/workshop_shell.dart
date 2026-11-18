import 'package:design_system/src/components/workshop_ui.dart';
import 'package:design_system/src/tokens.dart';
import 'package:design_system/src/workshop_tokens.dart';
import 'package:flutter/material.dart';

/// A workshop shell navigation entry. [key] is placed on the rendered nav
/// item so tests and deep links can target it.
class WorkshopNavDestination {
  const WorkshopNavDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.key,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final Key? key;
}

/// Responsive Workshop Admin chrome.
///
/// - â‰¥ 1000 px: fixed 256 px sidebar (wordmark, workshop name, nav, account).
/// - 680â€“999 px: 84 px rail with icon + 11 px label.
/// - < 680 px: 60 px top bar + bottom navigation with the first four
///   destinations and a "More" sheet for the rest (settings, language, sign
///   out).
///
/// The shell paints the warm canvas, keeps the content area full height, and
/// exposes the same account menu in every layout. Layout uses directional
/// insets/alignment, so an RTL locale mirrors the sidebar and breadcrumb.
class WorkshopAppShell extends StatelessWidget {
  const WorkshopAppShell({
    required this.workshopName,
    required this.sectionLabel,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
    required this.child,
    required this.accountInitials,
    required this.accountName,
    required this.accountEmail,
    required this.onSettings,
    required this.onSignOut,
    required this.onToggleLanguage,
    required this.languageLabel,
    this.notificationsAction,
    this.moreLabel = 'More',
    this.signOutLabel = 'Sign out',
    this.settingsLabel = 'Settings',
    super.key,
  });

  final String workshopName;
  final String sectionLabel;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<WorkshopNavDestination> destinations;
  final Widget child;
  final String accountInitials;
  final String accountName;
  final String accountEmail;
  final VoidCallback onSettings;
  final VoidCallback onSignOut;
  final VoidCallback onToggleLanguage;
  final String languageLabel;
  final Widget? notificationsAction;

  /// Labels for the mobile overflow sheet. Callers pass localized strings;
  /// the defaults keep the design-system widget usable in previews.
  final String moreLabel;
  final String signOutLabel;
  final String settingsLabel;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            if (width >= 1000) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Sidebar(
                    workshopName: workshopName,
                    selectedIndex: selectedIndex,
                    onSelected: onSelected,
                    destinations: destinations,
                    accountInitials: accountInitials,
                    accountName: accountName,
                    accountEmail: accountEmail,
                    onSettings: onSettings,
                    onSignOut: onSignOut,
                    onToggleLanguage: onToggleLanguage,
                    languageLabel: languageLabel,
                    settingsLabel: settingsLabel,
                    signOutLabel: signOutLabel,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _TopBar(
                          workshopName: workshopName,
                          sectionLabel: sectionLabel,
                          gutter: ws.pageGutter(width),
                          notificationsAction: notificationsAction,
                          accountInitials: accountInitials,
                          accountName: accountName,
                          accountEmail: accountEmail,
                          onSettings: onSettings,
                          onSignOut: onSignOut,
                          onToggleLanguage: onToggleLanguage,
                          languageLabel: languageLabel,
                          settingsLabel: settingsLabel,
                          signOutLabel: signOutLabel,
                        ),
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ],
              );
            }
            if (width >= 680) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Rail(
                    selectedIndex: selectedIndex,
                    onSelected: onSelected,
                    destinations: destinations,
                    accountInitials: accountInitials,
                    accountName: accountName,
                    accountEmail: accountEmail,
                    onSettings: onSettings,
                    onSignOut: onSignOut,
                    onToggleLanguage: onToggleLanguage,
                    languageLabel: languageLabel,
                    settingsLabel: settingsLabel,
                    signOutLabel: signOutLabel,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _TopBar(
                          workshopName: workshopName,
                          sectionLabel: sectionLabel,
                          gutter: ws.pageGutter(width),
                          notificationsAction: notificationsAction,
                          accountInitials: accountInitials,
                          accountName: accountName,
                          accountEmail: accountEmail,
                          onSettings: onSettings,
                          onSignOut: onSignOut,
                          onToggleLanguage: onToggleLanguage,
                          languageLabel: languageLabel,
                          settingsLabel: settingsLabel,
                          signOutLabel: signOutLabel,
                        ),
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                _MobileTopBar(
                  workshopName: workshopName,
                  notificationsAction: notificationsAction,
                  accountInitials: accountInitials,
                  accountName: accountName,
                  accountEmail: accountEmail,
                  onSettings: onSettings,
                  onSignOut: onSignOut,
                  onToggleLanguage: onToggleLanguage,
                  languageLabel: languageLabel,
                  settingsLabel: settingsLabel,
                  signOutLabel: signOutLabel,
                ),
                Expanded(child: child),
                _BottomBar(
                  selectedIndex: selectedIndex,
                  onSelected: onSelected,
                  destinations: destinations,
                  moreLabel: moreLabel,
                  signOutLabel: signOutLabel,
                  languageLabel: languageLabel,
                  onToggleLanguage: onToggleLanguage,
                  onSignOut: onSignOut,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account menu reused by every layout
// ---------------------------------------------------------------------------

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({
    required this.compact,
    required this.initials,
    required this.displayName,
    required this.email,
    required this.onSettings,
    required this.onSignOut,
    required this.onToggleLanguage,
    required this.languageLabel,
    required this.settingsLabel,
    required this.signOutLabel,
  });

  final bool compact;
  final String initials;
  final String displayName;
  final String email;
  final VoidCallback onSettings;
  final VoidCallback onSignOut;
  final VoidCallback onToggleLanguage;
  final String languageLabel;
  final String settingsLabel;
  final String signOutLabel;

  @override
  Widget build(BuildContext context) {
    return WorkshopAccountMenu(
      initials: initials,
      displayName: displayName,
      email: email,
      onSettings: onSettings,
      onSignOut: onSignOut,
      onToggleLanguage: onToggleLanguage,
      languageLabel: languageLabel,
      settingsLabel: settingsLabel,
      signOutLabel: signOutLabel,
      compact: compact,
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop sidebar
// ---------------------------------------------------------------------------

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.workshopName,
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
    required this.settingsLabel,
    required this.signOutLabel,
  });

  final String workshopName;
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
  final String settingsLabel;
  final String signOutLabel;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Container(
      width: ws.sidebarWidth,
      decoration: BoxDecoration(
        color: ws.surface,
        border: BorderDirectional(end: BorderSide(color: ws.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              ws.cardPadding,
              ws.cardPadding,
              ws.cardPadding,
              spacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TrueReport',
                  style: ws.sectionTitle.copyWith(color: ws.accent),
                ),
                SizedBox(height: spacing.xxs),
                Text(workshopName, style: ws.meta.copyWith(color: ws.muted)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsetsDirectional.symmetric(horizontal: spacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < destinations.length; index++)
                    _SidebarItem(
                      destination: destinations[index],
                      selected: index == selectedIndex,
                      onTap: () => onSelected(index),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              spacing.md,
              spacing.md,
              spacing.md,
              spacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const WorkshopDivider(),
                SizedBox(height: spacing.sm),
                _AccountMenu(
                  compact: false,
                  initials: accountInitials,
                  displayName: accountName,
                  email: accountEmail,
                  onSettings: onSettings,
                  onSignOut: onSignOut,
                  onToggleLanguage: onToggleLanguage,
                  languageLabel: languageLabel,
                  settingsLabel: settingsLabel,
                  signOutLabel: signOutLabel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final WorkshopNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: spacing.xxs),
      child: _NavSurface(
        key: destination.key,
        selected: selected,
        label: destination.label,
        onTap: onTap,
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xs,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: ws.touchTarget),
          child: Row(
            children: [
              if (selected) ...[
                Container(
                  width: 3,
                  height: 20,
                  decoration: BoxDecoration(
                    color: ws.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: spacing.sm),
              ],
              Icon(
                selected
                    ? (destination.selectedIcon ?? destination.icon)
                    : destination.icon,
                size: 18,
                color: selected ? ws.ink : ws.muted,
              ),
              SizedBox(width: spacing.md),
              Expanded(
                child: Text(
                  destination.label,
                  maxLines: 2,
                  style: selected ? ws.bodyStrong : ws.body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tablet rail
// ---------------------------------------------------------------------------

class _Rail extends StatelessWidget {
  const _Rail({
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
    required this.settingsLabel,
    required this.signOutLabel,
  });

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
  final String settingsLabel;
  final String signOutLabel;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Container(
      width: ws.railWidth,
      decoration: BoxDecoration(
        color: ws.surface,
        border: BorderDirectional(end: BorderSide(color: ws.border)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.symmetric(vertical: spacing.md),
            child: Container(
              width: ws.touchTarget,
              height: ws.touchTarget,
              decoration: BoxDecoration(
                color: ws.accentSoft,
                borderRadius: BorderRadius.circular(ws.controlRadius),
              ),
              alignment: Alignment.center,
              child: Text(
                'TR',
                style: ws.bodyStrong.copyWith(color: ws.accent),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsetsDirectional.symmetric(horizontal: spacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < destinations.length; index++)
                    _RailItem(
                      destination: destinations[index],
                      selected: index == selectedIndex,
                      onTap: () => onSelected(index),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.all(spacing.xs),
            child: _AccountMenu(
              compact: true,
              initials: accountInitials,
              displayName: accountName,
              email: accountEmail,
              onSettings: onSettings,
              onSignOut: onSignOut,
              onToggleLanguage: onToggleLanguage,
              languageLabel: languageLabel,
              settingsLabel: settingsLabel,
              signOutLabel: signOutLabel,
            ),
          ),
          SizedBox(height: spacing.sm),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final WorkshopNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: spacing.xxs),
      child: _NavSurface(
        key: destination.key,
        selected: selected,
        label: destination.label,
        onTap: onTap,
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: spacing.xxs,
          vertical: spacing.xs,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected
                    ? (destination.selectedIcon ?? destination.icon)
                    : destination.icon,
                size: 20,
                color: selected ? ws.accent : ws.muted,
              ),
              SizedBox(height: spacing.xxs),
              SizedBox(
                height: 14,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    style: ws.eyebrow.copyWith(
                      color: selected ? ws.accent : ws.muted,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bars
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.workshopName,
    required this.sectionLabel,
    required this.gutter,
    required this.notificationsAction,
    required this.accountInitials,
    required this.accountName,
    required this.accountEmail,
    required this.onSettings,
    required this.onSignOut,
    required this.onToggleLanguage,
    required this.languageLabel,
    required this.settingsLabel,
    required this.signOutLabel,
  });

  final String workshopName;
  final String sectionLabel;
  final double gutter;
  final Widget? notificationsAction;
  final String accountInitials;
  final String accountName;
  final String accountEmail;
  final VoidCallback onSettings;
  final VoidCallback onSignOut;
  final VoidCallback onToggleLanguage;
  final String languageLabel;
  final String settingsLabel;
  final String signOutLabel;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Container(
      height: ws.topBarHeight,
      decoration: BoxDecoration(
        color: ws.surface,
        border: BorderDirectional(bottom: BorderSide(color: ws.border)),
      ),
      padding: EdgeInsetsDirectional.symmetric(horizontal: gutter),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$workshopName / $sectionLabel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ws.meta.copyWith(color: ws.muted),
            ),
          ),
          if (notificationsAction != null) ...[
            notificationsAction!,
            SizedBox(width: spacing.sm),
          ],
          _AccountMenu(
            compact: true,
            initials: accountInitials,
            displayName: accountName,
            email: accountEmail,
            onSettings: onSettings,
            onSignOut: onSignOut,
            onToggleLanguage: onToggleLanguage,
            languageLabel: languageLabel,
            settingsLabel: settingsLabel,
            signOutLabel: signOutLabel,
          ),
        ],
      ),
    );
  }
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({
    required this.workshopName,
    required this.notificationsAction,
    required this.accountInitials,
    required this.accountName,
    required this.accountEmail,
    required this.onSettings,
    required this.onSignOut,
    required this.onToggleLanguage,
    required this.languageLabel,
    required this.settingsLabel,
    required this.signOutLabel,
  });

  final String workshopName;
  final Widget? notificationsAction;
  final String accountInitials;
  final String accountName;
  final String accountEmail;
  final VoidCallback onSettings;
  final VoidCallback onSignOut;
  final VoidCallback onToggleLanguage;
  final String languageLabel;
  final String settingsLabel;
  final String signOutLabel;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Container(
      height: ws.topBarHeight,
      decoration: BoxDecoration(
        color: ws.surface,
        border: BorderDirectional(bottom: BorderSide(color: ws.border)),
      ),
      padding: EdgeInsetsDirectional.symmetric(horizontal: ws.pageGutterPhone),
      child: Row(
        children: [
          Expanded(
            child: Text(
              workshopName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ws.cardTitle,
            ),
          ),
          if (notificationsAction != null) ...[
            notificationsAction!,
            SizedBox(width: spacing.xs),
          ],
          _AccountMenu(
            compact: true,
            initials: accountInitials,
            displayName: accountName,
            email: accountEmail,
            onSettings: onSettings,
            onSignOut: onSignOut,
            onToggleLanguage: onToggleLanguage,
            languageLabel: languageLabel,
            settingsLabel: settingsLabel,
            signOutLabel: signOutLabel,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phone bottom navigation
// ---------------------------------------------------------------------------

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
    required this.moreLabel,
    required this.signOutLabel,
    required this.languageLabel,
    required this.onToggleLanguage,
    required this.onSignOut,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<WorkshopNavDestination> destinations;
  final String moreLabel;
  final String signOutLabel;
  final String languageLabel;
  final VoidCallback onToggleLanguage;
  final VoidCallback onSignOut;

  static const int _visibleCount = 4;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final hasMore = destinations.length > _visibleCount;
    final visible = hasMore
        ? destinations.take(_visibleCount).toList(growable: false)
        : destinations;
    return Container(
      decoration: BoxDecoration(
        color: ws.surface,
        border: BorderDirectional(top: BorderSide(color: ws.border)),
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: spacing.xs,
        vertical: spacing.xxs,
      ),
      child: Row(
        children: [
          for (var index = 0; index < visible.length; index++)
            Expanded(
              child: _BottomItem(
                destination: visible[index],
                selected: index == selectedIndex,
                onTap: () => onSelected(index),
              ),
            ),
          if (hasMore)
            Expanded(
              child: _BottomItem(
                key: const Key('workshop-tab-more'),
                destination: WorkshopNavDestination(
                  label: moreLabel,
                  icon: Icons.more_horiz,
                ),
                selected: selectedIndex >= _visibleCount,
                onTap: () => showWorkshopMoreSheet(
                  context: context,
                  selectedIndex: selectedIndex,
                  onSelected: onSelected,
                  destinations: destinations,
                  languageLabel: languageLabel,
                  signOutLabel: signOutLabel,
                  onToggleLanguage: onToggleLanguage,
                  onSignOut: onSignOut,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final WorkshopNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return _NavSurface(
      key: destination.key,
      selected: selected,
      label: destination.label,
      onTap: onTap,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: spacing.xxs,
        vertical: spacing.xs,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: ws.touchTarget),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? (destination.selectedIcon ?? destination.icon)
                  : destination.icon,
              size: 22,
              color: selected ? ws.accent : ws.muted,
            ),
            SizedBox(height: spacing.xxs),
            SizedBox(
              height: 14,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  destination.label,
                  maxLines: 1,
                  style: ws.eyebrow.copyWith(
                    color: selected ? ws.accent : ws.muted,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w600,
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

/// Bottom-sheet overflow for the phone layout: remaining destinations plus
/// language and sign out.
Future<void> showWorkshopMoreSheet({
  required BuildContext context,
  required int selectedIndex,
  required ValueChanged<int> onSelected,
  required List<WorkshopNavDestination> destinations,
  required String languageLabel,
  required String signOutLabel,
  required VoidCallback onToggleLanguage,
  required VoidCallback onSignOut,
}) {
  final ws = context.ws;
  final spacing = context.spacing;
  final remaining = <int, WorkshopNavDestination>{
    for (var index = 4; index < destinations.length; index++)
      index: destinations[index],
  };
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: ws.surface,
    builder: (sheetContext) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsetsDirectional.only(bottom: spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in remaining.entries)
                ListTile(
                  key: entry.value.key,
                  leading: Icon(
                    entry.key == selectedIndex
                        ? (entry.value.selectedIcon ?? entry.value.icon)
                        : entry.value.icon,
                    color: entry.key == selectedIndex ? ws.accent : ws.muted,
                  ),
                  title: Text(
                    entry.value.label,
                    style: entry.key == selectedIndex ? ws.bodyStrong : ws.body,
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onSelected(entry.key);
                  },
                ),
              Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: spacing.md,
                ),
                child: const WorkshopDivider(),
              ),
              ListTile(
                leading: Icon(Icons.language, color: ws.muted),
                title: Text(languageLabel, style: ws.body),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onToggleLanguage();
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: ws.muted),
                title: Text(signOutLabel, style: ws.body),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onSignOut();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Shared nav focus surface
// ---------------------------------------------------------------------------

class _NavSurface extends StatefulWidget {
  const _NavSurface({
    required this.selected,
    required this.label,
    required this.onTap,
    required this.child,
    required this.padding,
    super.key,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  State<_NavSurface> createState() => _NavSurfaceState();
}

class _NavSurfaceState extends State<_NavSurface> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final radius = BorderRadius.circular(ws.controlRadius);
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: AnimatedContainer(
        duration: context.motionDuration(const Duration(milliseconds: 140)),
        curve: context.motion.enterCurve,
        decoration: BoxDecoration(
          color: widget.selected ? ws.accentSoft : Colors.transparent,
          borderRadius: radius,
          boxShadow: _focused
              ? <BoxShadow>[
                  BoxShadow(
                    color: ws.focus.withValues(alpha: 0.35),
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            onFocusChange: (value) => setState(() => _focused = value),
            borderRadius: radius,
            child: Padding(
              padding: widget.padding,
              child: ExcludeSemantics(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
