import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/platform_shell.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import 'checklist_tab_bar.dart';

import 'package:l10n/l10n.dart';

/// Redesigned shared frame for the Checklist section:
/// - Page header with title, subtitle, and primary action
/// - Catalog snapshot strip: Items, Categories, Option Sets, Health
/// - Explanatory helper copy comes from the backend catalog.
/// - Scrollable tab bar with icon + label + count + active state
/// - Section body
class ChecklistPageFrame extends ConsumerWidget {
  const ChecklistPageFrame({
    super.key,
    required this.currentRoute,
    required this.currentTab,
    this.actions = const [],
    this.onSearchChanged,
    this.showSearch = true,
    required this.child,
  });

  final String currentRoute;
  final ChecklistTab currentTab;
  final List<Widget> actions;
  final ValueChanged<String>? onSearchChanged;
  final bool showSearch;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final itemsAsync = ref.watch(itemsProvider(const ItemQuery()));
    final categoriesAsync = ref.watch(categoriesProvider);
    final optionsAsync = ref.watch(optionSetsProvider);
    final healthAsync = ref.watch(configHealthProvider);

    return PlatformShell(
      currentRoute: currentRoute,
      onSearchChanged: onSearchChanged,
      showSearch: showSearch,
      onNavigate: (route) => context.go(route),
      child: PlatformPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlatformPageHeader(
              title: strings.tKey(PlatformAdminKeys.pageChecklistTitle),
              subtitle: strings.tKey(PlatformAdminKeys.pageChecklistHelper),
              actions: actions,
            ),
            const SizedBox(height: 16),
            _ChecklistCatalogSnapshot(
              itemsCount: itemsAsync.asData?.value.length,
              categoriesCount: categoriesAsync.asData?.value.length,
              optionsCount: optionsAsync.asData?.value.length,
              health: healthAsync.asData?.value,
            ),
            const SizedBox(height: 16),
            ChecklistTabBar(currentTab: currentTab),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChecklistCatalogSnapshot extends ConsumerWidget {
  const _ChecklistCatalogSnapshot({
    required this.itemsCount,
    required this.categoriesCount,
    required this.optionsCount,
    required this.health,
  });

  final int? itemsCount;
  final int? categoriesCount;
  final int? optionsCount;
  final ConfigHealth? health;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final healthIssues = health?.checks.where((c) => !c.ok).length ?? 0;
    final isHealthy = health != null && healthIssues == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: PtTheme.deepGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome_mosaic_outlined,
                  size: 16,
                  color: PtTheme.deepGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  strings.tKey(
                    PlatformAdminKeys.checklistCatalogSnapshotExplanation,
                  ),
                  style: PtTheme.font(
                    13,
                    lineHeight: 18,
                    weight: FontWeight.w600,
                    color: PtTheme.ink,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final tiles = [
                _SnapshotTile(
                  icon: Icons.checklist_rounded,
                  label: strings.tKey(PlatformAdminKeys.tabChecklistItems),
                  value: itemsCount != null ? '$itemsCount' : '—',
                  color: PtTheme.deepGreen,
                  onTap: () => context.go('/checklist/items'),
                ),
                _SnapshotTile(
                  icon: Icons.folder_outlined,
                  label: strings.tKey(PlatformAdminKeys.tabChecklistCategories),
                  value: categoriesCount != null ? '$categoriesCount' : '—',
                  color: PtTheme.deepGreen,
                  onTap: () => context.go('/checklist/categories'),
                ),
                _SnapshotTile(
                  icon: Icons.tune_rounded,
                  label: strings.tKey(
                    PlatformAdminKeys.tabChecklistIssueOptions,
                  ),
                  value: optionsCount != null ? '$optionsCount' : '—',
                  color: PtTheme.darkNavText,
                  onTap: () => context.go('/checklist/option-sets'),
                ),

                _SnapshotTile(
                  icon: isHealthy
                      ? Icons.check_circle_outline_rounded
                      : Icons.warning_amber_rounded,
                  label: strings.tKey(PlatformAdminKeys.tabChecklistHealth),
                  value: health == null
                      ? '—'
                      : (isHealthy
                            ? strings.tKey(CommonKeys.statusHealthy)
                            : '$healthIssues issues'),
                  color: isHealthy ? PtTheme.emerald : PtTheme.rose,
                  onTap: () => context.go('/checklist/health'),
                ),
              ];

              if (!isWide) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tile in tiles)
                      SizedBox(
                        width: (constraints.maxWidth - 8) / 2,
                        child: tile,
                      ),
                  ],
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: tiles[i]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SnapshotTile extends StatelessWidget {
  const _SnapshotTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: PtTheme.canvas,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: PtTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: PtTheme.font(
                        15,
                        lineHeight: 18,
                        weight: FontWeight.w800,
                        color: PtTheme.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: PtTheme.font(
                        11,
                        lineHeight: 14,
                        weight: FontWeight.w500,
                        color: PtTheme.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
