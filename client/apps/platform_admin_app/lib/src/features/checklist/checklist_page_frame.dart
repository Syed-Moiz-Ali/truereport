import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/platform_shell.dart';
import '../../platform_providers.dart';
import 'checklist_tab_bar.dart';

import 'package:l10n/l10n.dart';

/// Shared frame for the five Checklist tabs.
///
/// Renders [PlatformShell] + [PlatformPage] + a page header with the
/// checklist title/helper plus the per-tab primary action, followed by the
/// [ChecklistTabBar] and the tab body.
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
            ChecklistTabBar(currentTab: currentTab),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
