import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

class PlatformNavEntry {
  const PlatformNavEntry({
    required this.id,
    required this.route,
    required this.icon,
    required this.labelKey,
    this.isConfiguration = false,
  });

  final String id;
  final String route;
  final IconData icon;
  final UiMessageKey labelKey;
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
    // The Profile tab covers the account screen, the language workspace,
    // the configuration pages reached from the ledger, and the audit log,
    // which lives inside the profile ledger (MONITOR group) rather than as
    // its own dock destination. The route stays /settings so deep links
    // and bookmarks keep working; only the visible name changed.
    if (id == 'settings') {
      return currentRoute.startsWith('/settings') ||
          currentRoute.startsWith('/configuration') ||
          currentRoute == '/audit-log';
    }
    return currentRoute.startsWith(route);
  }
}

/// Centralized navigation definition: exactly 5 primary dock items.
/// Audit log is not a dock destination; it lives inside the profile ledger.
class PlatformNavData {
  const PlatformNavData._();

  /// Primary navigation items, in rail / dock order.
  static const primaryItems = <PlatformNavEntry>[
    PlatformNavEntry(
      id: 'dashboard',
      route: '/dashboard',
      icon: Icons.dashboard_outlined,
      labelKey: PlatformAdminKeys.navDashboard,
    ),
    PlatformNavEntry(
      id: 'workshops',
      route: '/workshops',
      icon: Icons.apartment_rounded,
      labelKey: PlatformAdminKeys.navWorkshops,
    ),
    PlatformNavEntry(
      id: 'checklist',
      route: '/checklist/items',
      icon: Icons.menu_book_rounded,
      labelKey: PlatformAdminKeys.navChecklist,
    ),
    PlatformNavEntry(
      id: 'reports',
      route: '/reports/document-types',
      icon: Icons.description_outlined,
      labelKey: PlatformAdminKeys.navReports,
    ),
    PlatformNavEntry(
      id: 'settings',
      route: '/settings',
      icon: Icons.settings_outlined,
      labelKey: PlatformAdminKeys.pageProfileTitle,
    ),
  ];

  static List<PlatformNavEntry> get allItems => [...primaryItems];
}
