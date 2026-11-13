import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/platform_chips.dart';
import '../../platform_providers.dart';

import 'package:l10n/l10n.dart';

/// Checklist tabs. Items is the default landing tab.
enum ChecklistTab {
  categories('/checklist/categories', 'categories'),
  items('/checklist/items', 'items'),
  templates('/checklist/templates', 'templates'),
  issueOptions('/checklist/option-sets', 'issue-options'),
  health('/checklist/health', 'health');

  const ChecklistTab(this.route, this.key);

  final String route;
  final String key;

  String label(dynamic strings) {
    switch (this) {
      case ChecklistTab.categories:
        return strings.tKey(PlatformAdminKeys.tabChecklistCategories);
      case ChecklistTab.items:
        return strings.tKey(PlatformAdminKeys.tabChecklistItems);
      case ChecklistTab.templates:
        return strings.tKey(PlatformAdminKeys.tabChecklistTemplates);
      case ChecklistTab.issueOptions:
        return strings.tKey(PlatformAdminKeys.tabChecklistIssueOptions);
      case ChecklistTab.health:
        return strings.tKey(PlatformAdminKeys.tabChecklistHealth);
    }
  }

  static ChecklistTab fromRoute(String route) {
    for (final tab in ChecklistTab.values) {
      if (route == tab.route || route.startsWith('${tab.route}/')) {
        return tab;
      }
    }
    return ChecklistTab.items;
  }
}

/// Segmented tab bar for the Checklist section.
///
/// Tabs navigate to routes so the selected tab persists in the URL.
/// Wraps on compact widths (no overflow) and follows the ambient
/// [Directionality], so it is RTL-safe.
class ChecklistTabBar extends ConsumerWidget {
  const ChecklistTabBar({super.key, required this.currentTab});

  final ChecklistTab currentTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final tab in ChecklistTab.values)
          PlatformFilterChip(
            key: Key('checklist-tab-${tab.key}'),
            label: tab.label(strings),
            selected: tab == currentTab,
            onTap: () {
              if (tab != currentTab) context.go(tab.route);
            },
          ),
      ],
    );
  }
}
