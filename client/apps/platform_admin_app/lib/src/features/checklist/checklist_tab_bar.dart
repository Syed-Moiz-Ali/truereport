import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../platform_providers.dart';
import '../../platform_theme.dart';

import 'package:l10n/l10n.dart';

/// Checklist tabs with assigned icons and routing.
enum ChecklistTab {
  items('/checklist/items', 'items', Icons.checklist_rounded),
  categories('/checklist/categories', 'categories', Icons.folder_outlined),
  issueOptions('/checklist/option-sets', 'issue-options', Icons.tune_rounded),
  health('/checklist/health', 'health', Icons.health_and_safety_outlined);

  const ChecklistTab(this.route, this.key, this.icon);

  final String route;
  final String key;
  final IconData icon;

  String label(dynamic strings) {
    switch (this) {
      case ChecklistTab.categories:
        return strings.tKey(PlatformAdminKeys.tabChecklistCategories);
      case ChecklistTab.items:
        return strings.tKey(PlatformAdminKeys.tabChecklistItems);
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

/// Redesigned Segmented Tab Bar for Checklist with:
/// - icon + label + count
/// - strong active state
/// - scrollable on compact widths
/// - full RTL alignment
class ChecklistTabBar extends ConsumerWidget {
  const ChecklistTabBar({super.key, required this.currentTab});

  final ChecklistTab currentTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final itemsCount = ref
        .watch(itemsProvider(const ItemQuery()))
        .asData
        ?.value
        .length;
    final categoriesCount = ref.watch(categoriesProvider).asData?.value.length;
    final optionsCount = ref.watch(optionSetsProvider).asData?.value.length;
    final healthData = ref.watch(configHealthProvider).asData?.value;
    final healthIssueCount = healthData?.checks.where((c) => !c.ok).length;

    int? getCount(ChecklistTab tab) {
      switch (tab) {
        case ChecklistTab.items:
          return itemsCount;
        case ChecklistTab.categories:
          return categoriesCount;
        case ChecklistTab.issueOptions:
          return optionsCount;
        case ChecklistTab.health:
          return healthIssueCount;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < ChecklistTab.values.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _ChecklistTabButton(
              tab: ChecklistTab.values[i],
              isSelected: ChecklistTab.values[i] == currentTab,
              label: ChecklistTab.values[i].label(strings),
              count: getCount(ChecklistTab.values[i]),
              isHealthTab: ChecklistTab.values[i] == ChecklistTab.health,
              onTap: () {
                if (ChecklistTab.values[i] != currentTab) {
                  context.go(ChecklistTab.values[i].route);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ChecklistTabButton extends StatelessWidget {
  const _ChecklistTabButton({
    required this.tab,
    required this.isSelected,
    required this.label,
    required this.count,
    required this.isHealthTab,
    required this.onTap,
  });

  final ChecklistTab tab;
  final bool isSelected;
  final String label;
  final int? count;
  final bool isHealthTab;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasIssues = isHealthTab && (count ?? 0) > 0;
    final activeBg = isSelected ? PtTheme.canvas : Colors.transparent;
    final borderColor = isSelected ? PtTheme.deepGreen : PtTheme.border;
    final textColor = isSelected ? PtTheme.ink : PtTheme.muted;
    final iconColor = isSelected
        ? PtTheme.deepGreen
        : (hasIssues ? PtTheme.rose : PtTheme.muted);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('checklist-tab-${tab.key}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: const BoxConstraints(minHeight: 44),
          decoration: BoxDecoration(
            color: activeBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tab.icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: PtTheme.font(
                  13,
                  lineHeight: 18,
                  weight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: textColor,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (hasIssues
                              ? PtTheme.rose.withValues(alpha: 0.15)
                              : PtTheme.deepGreen.withValues(alpha: 0.12))
                        : (hasIssues
                              ? PtTheme.rose.withValues(alpha: 0.12)
                              : PtTheme.canvas),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasIssues
                          ? PtTheme.rose.withValues(alpha: 0.3)
                          : (isSelected
                                ? PtTheme.deepGreen.withValues(alpha: 0.25)
                                : PtTheme.border),
                    ),
                  ),
                  child: Text(
                    '$count',
                    style: PtTheme.font(
                      11,
                      lineHeight: 14,
                      weight: FontWeight.w700,
                      color: hasIssues
                          ? PtTheme.rose
                          : (isSelected ? PtTheme.deepGreen : PtTheme.muted),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
