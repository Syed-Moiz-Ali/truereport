import 'package:admin_app/src/pages/dashboard_tab.dart';
import 'package:admin_app/src/pages/jobs_tab.dart';
import 'package:admin_app/src/pages/staff_tab.dart';
import 'package:admin_app/src/pages/templates_tab.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

class WorkshopAdminHomePage extends ConsumerWidget {
  const WorkshopAdminHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    return DefaultTabController(
      length: 4,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= AppBreakpoints.tablet;
          final appBar = AppBar(
            title: Text(l10n.workshopAdminTitle),
            actions: [
              AppButton(
                label: locale.languageCode == 'ar'
                    ? l10n.languageEnglish
                    : l10n.languageArabic,
                onPressed: () => ref
                    .read(localeProvider.notifier)
                    .setLocale(
                      locale.languageCode == 'ar'
                          ? const Locale('en')
                          : const Locale('ar'),
                    ),
                variant: AppButtonVariant.text,
              ),
              IconButton(
                tooltip: l10n.signOut,
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                icon: const Icon(Icons.logout),
              ),
            ],
            bottom: wide
                ? null
                : TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(
                        key: const Key('workshop-tab-overview'),
                        icon: const Icon(Icons.dashboard_outlined),
                        text: l10n.dashboardTab,
                      ),
                      Tab(
                        key: const Key('workshop-tab-jobs'),
                        icon: const Icon(Icons.work_outline),
                        text: l10n.jobsTab,
                      ),
                      Tab(
                        key: const Key('workshop-tab-staff'),
                        icon: const Icon(Icons.groups_outlined),
                        text: l10n.staffTab,
                      ),
                      Tab(
                        key: const Key('workshop-tab-templates'),
                        icon: const Icon(Icons.dashboard_customize_outlined),
                        text: l10n.templatesTab,
                      ),
                    ],
                  ),
          );
          const tabs = TabBarView(
            children: [DashboardTab(), JobsTab(), StaffTab(), TemplatesTab()],
          );
          if (!wide) {
            return AppScaffold(appBar: appBar, body: tabs);
          }
          return AppScaffold(
            appBar: appBar,
            body: Row(
              children: [
                AnimatedBuilder(
                  animation: DefaultTabController.of(context),
                  builder: (context, _) {
                    final controller = DefaultTabController.of(context);
                    return NavigationRail(
                      selectedIndex: controller.index,
                      onDestinationSelected: controller.animateTo,
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        NavigationRailDestination(
                          icon: const Icon(Icons.dashboard_outlined),
                          selectedIcon: const Icon(Icons.dashboard),
                          label: Text(
                            l10n.dashboardTab,
                            key: const Key('workshop-tab-overview'),
                          ),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.work_outline),
                          selectedIcon: const Icon(Icons.work),
                          label: Text(
                            l10n.jobsTab,
                            key: const Key('workshop-tab-jobs'),
                          ),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.groups_outlined),
                          selectedIcon: const Icon(Icons.groups),
                          label: Text(
                            l10n.staffTab,
                            key: const Key('workshop-tab-staff'),
                          ),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.dashboard_customize_outlined),
                          selectedIcon: const Icon(Icons.dashboard_customize),
                          label: Text(
                            l10n.templatesTab,
                            key: const Key('workshop-tab-templates'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                VerticalDivider(
                  width: context.spacing.xs,
                  color: context.colors.outlineVariant,
                ),
                const Expanded(child: tabs),
              ],
            ),
          );
        },
      ),
    );
  }
}
