import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../platform_theme.dart';

class PlatformSidebar extends StatelessWidget {
  const PlatformSidebar({
    super.key,
    required this.currentRoute,
    this.onNavigate,
  });

  final String currentRoute;
  final ValueChanged<String>? onNavigate;

  void _navigate(BuildContext context, String route) {
    if (onNavigate != null) {
      onNavigate!(route);
    } else {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      decoration: const BoxDecoration(
        color: PtTheme.white,
        border: Border(
          right: BorderSide(color: PtTheme.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Branding Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: PtTheme.emerald,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x4710B981),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.terminal_rounded,
                      color: PtTheme.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CoreOS',
                      style: PtTheme.font(
                        16,
                        lineHeight: 16,
                        weight: FontWeight.w700,
                        color: PtTheme.ink,
                        tracking: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Platform Admin',
                      style: PtTheme.font(
                        11,
                        lineHeight: 14,
                        weight: FontWeight.w600,
                        color: PtTheme.muted,
                        tracking: 0.44,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _NavItem(
                  key: const Key('nav-workshops'),
                  icon: Icons.apartment_rounded,
                  label: 'Workshops',
                  isActive: currentRoute == '/' || currentRoute.startsWith('/workshops'),
                  onTap: () => _navigate(context, '/workshops'),
                ),
                const SizedBox(height: 4),
                _NavItem(
                  key: const Key('nav-master-library'),
                  icon: Icons.menu_book_rounded,
                  label: 'Master Library',
                  isActive: currentRoute.startsWith('/master-library'),
                  onTap: () => _navigate(context, '/master-library'),
                ),
                const SizedBox(height: 4),
                _NavItem(
                  key: const Key('nav-data-catalogues'),
                  icon: Icons.folder_open_rounded,
                  label: 'Data Catalogues',
                  isActive: currentRoute.startsWith('/data-catalogues'),
                  onTap: () => _navigate(context, '/data-catalogues'),
                ),
                const SizedBox(height: 4),
                _NavItem(
                  key: const Key('nav-equipment'),
                  icon: Icons.construction_rounded,
                  label: 'Equipment',
                  isActive: currentRoute.startsWith('/equipment'),
                  onTap: () => _navigate(context, '/equipment'),
                ),
                const SizedBox(height: 4),
                _NavItem(
                  key: const Key('nav-settings'),
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  isActive: currentRoute.startsWith('/settings'),
                  onTap: () => _navigate(context, '/settings'),
                ),
                const SizedBox(height: 4),
                _NavItem(
                  key: const Key('nav-audit-log'),
                  icon: Icons.verified_user_outlined,
                  label: 'Audit Log',
                  isActive: currentRoute.startsWith('/audit-log'),
                  onTap: () => _navigate(context, '/audit-log'),
                ),
              ],
            ),
          ),

          // 3. Bottom Status Capsule: GRID V4.2 ONLINE
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: PtTheme.canvas,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: PtTheme.border.withValues(alpha: 0.7)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x04000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: PtTheme.emerald,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x8010B981),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'GRID V4.2 ONLINE',
                      style: PtTheme.font(
                        11,
                        lineHeight: 14,
                        weight: FontWeight.w600,
                        color: PtTheme.muted,
                        tracking: 0.44,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.bolt_rounded,
                    size: 15,
                    color: PtTheme.muted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = isActive ? PtTheme.ink : PtTheme.darkNavText;
    final iconColor = isActive ? PtTheme.emerald : PtTheme.muted;
    final bg = isActive ? PtTheme.canvas : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 16),
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
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
