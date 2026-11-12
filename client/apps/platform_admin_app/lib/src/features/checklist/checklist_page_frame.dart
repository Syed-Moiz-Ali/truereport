import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_shell.dart';
import 'checklist_tab_bar.dart';

/// Shared frame for the five Checklist tabs.
///
/// Renders [PlatformShell] + [PlatformPage] + a page header with the
/// checklist title/helper plus the per-tab primary action, followed by the
/// [ChecklistTabBar] and the tab body.
class ChecklistPageFrame extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              title: l10n.checklistTitle,
              subtitle: l10n.checklistHelper,
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
