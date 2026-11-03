import 'package:admin_app/src/pages/audit_tab.dart';
import 'package:admin_app/src/pages/hierarchy_tab.dart';
import 'package:admin_app/src/pages/master_content_tab.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

class PlatformAdminHomePage extends ConsumerWidget {
  const PlatformAdminHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    return DefaultTabController(
      length: 3,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= AppBreakpoints.tablet;
          final appBar = AppBar(
            title: Text(l10n.platformAdminTitle),
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
                        icon: const Icon(Icons.account_tree_outlined),
                        text: l10n.hierarchyTab,
                      ),
                      Tab(
                        icon: const Icon(Icons.library_books_outlined),
                        text: l10n.masterContentTab,
                      ),
                      Tab(
                        icon: const Icon(Icons.receipt_long_outlined),
                        text: l10n.auditTab,
                      ),
                    ],
                  ),
          );
          const tabs = TabBarView(
            children: [HierarchyTab(), MasterContentTab(), AuditTab()],
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
                          icon: const Icon(Icons.account_tree_outlined),
                          selectedIcon: const Icon(Icons.account_tree),
                          label: Text(l10n.hierarchyTab),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.library_books_outlined),
                          selectedIcon: const Icon(Icons.library_books),
                          label: Text(l10n.masterContentTab),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.receipt_long_outlined),
                          selectedIcon: const Icon(Icons.receipt_long),
                          label: Text(l10n.auditTab),
                        ),
                      ],
                    );
                  },
                ),
                VerticalDivider(width: 1, color: context.colors.outlineVariant),
                const Expanded(child: tabs),
              ],
            ),
          );
        },
      ),
    );
  }
}
