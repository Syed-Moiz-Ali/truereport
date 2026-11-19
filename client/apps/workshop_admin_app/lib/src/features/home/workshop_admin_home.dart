import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_tab.dart';
import 'package:workshop_admin_app/src/features/jobs/jobs_tab.dart';
import 'package:workshop_admin_app/src/features/jobs/workshop_notifications_page.dart';
import 'package:workshop_admin_app/src/features/settings/workshop_settings_page.dart';
import 'package:workshop_admin_app/src/features/staff/staff_tab.dart';
import 'package:workshop_admin_app/src/features/templates/templates_tab.dart';

/// Exposes the shell's section selector to descendants.
class WorkshopNavigationScope extends InheritedWidget {
  const WorkshopNavigationScope({
    required this.select,
    required super.child,
    super.key,
  });

  final ValueChanged<int> select;

  static WorkshopNavigationScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WorkshopNavigationScope>();

  @override
  bool updateShouldNotify(WorkshopNavigationScope oldWidget) =>
      select != oldWidget.select;
}

/// Workshop Admin shell host.
class WorkshopAdminHomePage extends ConsumerStatefulWidget {
  const WorkshopAdminHomePage({super.key});

  @override
  ConsumerState<WorkshopAdminHomePage> createState() =>
      _WorkshopAdminHomePageState();
}

class _WorkshopAdminHomePageState extends ConsumerState<WorkshopAdminHomePage> {
  int _selectedIndex = 0;

  void _select(int index) {
    if (index == _selectedIndex) {
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const WorkshopNotificationsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final session = ref.watch(authControllerProvider).value;
    final displayName = session?.user.displayName.trim() ?? '';
    final email = session?.user.email.trim() ?? '';
    final workshopName = session != null && session.memberships.isNotEmpty
        ? session.memberships.first.workshopName
        : l10n.workshopAdminTitle;
    final accountName = displayName.isEmpty
        ? l10n.roleWorkshopAdmin
        : displayName;

    final destinations = <WorkshopNavDestination>[
      WorkshopNavDestination(
        label: l10n.dashboardTab,
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        key: const Key('workshop-tab-overview'),
      ),
      WorkshopNavDestination(
        label: l10n.jobsTab,
        icon: Icons.work_outline,
        selectedIcon: Icons.work,
        key: const Key('workshop-tab-jobs'),
      ),
      WorkshopNavDestination(
        label: l10n.staffTab,
        icon: Icons.groups_outlined,
        selectedIcon: Icons.groups,
        key: const Key('workshop-tab-staff'),
      ),
      WorkshopNavDestination(
        label: l10n.templatesTab,
        icon: Icons.dashboard_customize_outlined,
        selectedIcon: Icons.dashboard_customize,
        key: const Key('workshop-tab-templates'),
      ),
      WorkshopNavDestination(
        label: l10n.settings,
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        key: const Key('workshop-tab-settings'),
      ),
    ];

    return WorkshopNavigationScope(
      select: _select,
      child: WorkshopAppShell(
        workshopName: workshopName,
        sectionLabel: destinations[_selectedIndex].label,
        selectedIndex: _selectedIndex,
        onSelected: _select,
        destinations: destinations,
        accountInitials: _initials(accountName),
        accountName: accountName,
        accountEmail: email,
        onSettings: () => _select(4),
        onSignOut: () => ref.read(authControllerProvider.notifier).signOut(),
        onToggleLanguage: () => ref.read(localeProvider.notifier).toggle(),
        languageLabel: locale.languageCode == 'ar'
            ? l10n.languageEnglish
            : l10n.languageArabic,
        moreLabel: l10n.navMore,
        navigationLabel: l10n.navMain,
        signOutLabel: l10n.signOut,
        settingsLabel: l10n.settings,
        notificationsAction: WorkshopIconButton(
          key: const Key('workshop-notifications'),
          icon: Icons.notifications_none,
          semanticLabel: l10n.jobsNotificationsTab,
          onPressed: _openNotifications,
        ),
        child: _SectionHost(
          index: _selectedIndex,
          children: const [
            DashboardTab(),
            JobsTab(),
            StaffTab(),
            TemplatesTab(),
            WorkshopSettingsPage(),
          ],
        ),
      ),
    );
  }
}

/// Mounts a section the first time it is visited, then keeps it alive.
///
/// The previous `IndexedStack` built all six sections on app open, so all six
/// provider families fetched before the admin had seen anything (audit S4).
/// Lazy mounting keeps the same "state survives tab switches" behaviour but
/// costs one build per section actually used.
class _SectionHost extends StatefulWidget {
  const _SectionHost({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<_SectionHost> createState() => _SectionHostState();
}

class _SectionHostState extends State<_SectionHost> {
  late final Set<int> _visited = {widget.index};

  @override
  void didUpdateWidget(_SectionHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visited.add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var index = 0; index < widget.children.length; index++)
          if (_visited.contains(index))
            Offstage(
              offstage: index != widget.index,
              child: TickerMode(
                enabled: index == widget.index,
                child: widget.children[index],
              ),
            ),
      ],
    );
  }
}

String _initials(String displayName) {
  final parts = displayName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return '';
  }
  if (parts.length == 1) {
    return parts.first.characters.first.toUpperCase();
  }
  return (parts.first.characters.first + parts[1].characters.first)
      .toUpperCase();
}
