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
    // The Settings tab covers settings, the language workspace and the
    // configuration pages that are reached from settings.
    if (id == 'settings') {
      return currentRoute.startsWith('/settings') ||
          currentRoute.startsWith('/configuration');
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
      id: 'audit-log',
      route: '/audit-log',
      icon: Icons.verified_user_outlined,
      labelKey: PlatformAdminKeys.pageAuditTitle,
    ),
    PlatformNavEntry(
      id: 'settings',
      route: '/settings',
      icon: Icons.settings_outlined,
      labelKey: PlatformAdminKeys.pageSettingsTitle,
    ),
  ];

  static List<PlatformNavEntry> get allItems => [...primaryItems];
}
