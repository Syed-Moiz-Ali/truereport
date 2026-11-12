import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../platform_theme.dart';

/// Navigation entry data model.
class PlatformNavEntry {
  const PlatformNavEntry({
    required this.id,
    required this.route,
    required this.icon,
    required this.getLabel,
    this.isConfiguration = false,
  });

  final String id;
  final String route;
  final IconData icon;
  final String Function(AppLocalizations?) getLabel;
  final bool isConfiguration;

  bool isActive(String currentRoute) {
    if (id == 'dashboard') {
      return currentRoute == '/dashboard' ||
          currentRoute.startsWith('/dashboard');
    }
    if (id == 'workshops') {
      return currentRoute == '/workshops' ||
          currentRoute.startsWith('/workshops');
    }
    // The Checklist tab is the landing route for every checklist tab page.
    if (id == 'checklist') {
      return currentRoute.startsWith('/checklist');
    }
    // The Reports tab covers every reports page.
    if (id == 'reports') {
      return currentRoute.startsWith('/reports');
    }
    // The Settings tab covers settings and its sub-pages (e.g. languages).
    if (id == 'settings') {
      return currentRoute.startsWith('/settings');
    }
    // Audit Log is a single page: exact match only.
    if (id == 'audit-log') {
      return currentRoute == '/audit-log';
    }
    return currentRoute.startsWith(route);
  }
}

/// Centralized navigation definition: exactly 6 primary items (D-074/D-075).
class PlatformNavData {
  const PlatformNavData._();

  /// Primary navigation items, in sidebar order.
  static final List<PlatformNavEntry> primaryItems = [
    PlatformNavEntry(
      id: 'dashboard',
      route: '/dashboard',
      icon: Icons.dashboard_outlined,
      getLabel: (l10n) => l10n?.navDashboard ?? 'Dashboard',
    ),
    PlatformNavEntry(
      id: 'workshops',
      route: '/workshops',
      icon: Icons.apartment_rounded,
      getLabel: (l10n) => l10n?.workshops ?? 'Workshops',
    ),
    PlatformNavEntry(
      id: 'checklist',
      route: '/checklist/items',
      icon: Icons.menu_book_rounded,
      getLabel: (l10n) => l10n?.navChecklist ?? 'Checklist',
    ),
    PlatformNavEntry(
      id: 'reports',
      route: '/reports/document-types',
      icon: Icons.description_outlined,
      getLabel: (l10n) => l10n?.navReports ?? 'Reports',
    ),
    PlatformNavEntry(
      id: 'audit-log',
      route: '/audit-log',
      icon: Icons.verified_user_outlined,
      getLabel: (l10n) => l10n?.auditLog ?? 'Audit Log',
    ),
    PlatformNavEntry(
      id: 'settings',
      route: '/settings',
      icon: Icons.settings_outlined,
      getLabel: (l10n) => l10n?.settings ?? 'Settings',
    ),
  ];

  static List<PlatformNavEntry> get allItems => [...primaryItems];
}

/// Reusable navigation item widget used in desktop sidebar and mobile sheet.
class PlatformNavItem extends StatelessWidget {
  const PlatformNavItem({
    super.key,
    required this.entry,
    required this.isActive,
    required this.onTap,
    this.keyPrefix = 'nav-',
  });

  final PlatformNavEntry entry;
  final bool isActive;
  final VoidCallback onTap;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final label = entry.getLabel(l10n);
    final fg = isActive ? PtTheme.ink : PtTheme.darkNavText;
    final iconColor = isActive ? PtTheme.emerald : PtTheme.muted;
    final bg = isActive ? PtTheme.canvas : Colors.transparent;

    return Semantics(
      selected: isActive,
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('$keyPrefix${entry.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: PtTheme.canvas.withValues(alpha: 0.6),
          focusColor: PtTheme.emerald.withValues(alpha: 0.08),
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              boxShadow: isActive
                  ? const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive
                        ? PtTheme.emerald.withValues(alpha: 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(entry.icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: PtTheme.font(
                      14,
                      lineHeight: 20,
                      weight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: fg,
                      tracking: -0.07,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders the complete navigation list (primary items only).
class PlatformNavList extends StatelessWidget {
  const PlatformNavList({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    this.keyPrefix = 'nav-',
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = false,
  });

  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final String keyPrefix;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding,
      shrinkWrap: shrinkWrap,
      children: [
        for (var i = 0; i < PlatformNavData.primaryItems.length; i++) ...[
          if (i > 0) const SizedBox(height: 4),
          PlatformNavItem(
            entry: PlatformNavData.primaryItems[i],
            isActive: PlatformNavData.primaryItems[i].isActive(currentRoute),
            onTap: () => onNavigate(PlatformNavData.primaryItems[i].route),
            keyPrefix: keyPrefix,
          ),
        ],
      ],
    );
  }
}
