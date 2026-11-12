import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_chips.dart';

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

  String label(AppLocalizations l10n) {
    switch (this) {
      case ChecklistTab.categories:
        return l10n.categoriesTab;
      case ChecklistTab.items:
        return l10n.itemsTab;
      case ChecklistTab.templates:
        return l10n.checklistTabTemplates;
      case ChecklistTab.issueOptions:
        return l10n.checklistTabIssueOptions;
      case ChecklistTab.health:
        return l10n.checklistTabHealth;
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
class ChecklistTabBar extends StatelessWidget {
  const ChecklistTabBar({super.key, required this.currentTab});

  final ChecklistTab currentTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final tab in ChecklistTab.values)
          PlatformFilterChip(
            key: Key('checklist-tab-${tab.key}'),
            label: tab.label(l10n),
            selected: tab == currentTab,
            onTap: () {
              if (tab != currentTab) context.go(tab.route);
            },
          ),
      ],
    );
  }
}
