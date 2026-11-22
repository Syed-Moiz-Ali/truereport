import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../platform_providers.dart';
import '../platform_theme.dart';
import 'platform_nav.dart';

/// Compact-width primary navigation.
///
/// Five destinations, always visible at the foot of the window. Audit log is
/// intentionally absent: it is reachable from the full navigation sheet behind
/// the menu button, which keeps the dock to the five places an admin visits.
class PlatformMobileDock extends ConsumerWidget {
  const PlatformMobileDock({
    super.key,
    required this.currentRoute,
    this.onNavigate,
  });

  final String currentRoute;
  final ValueChanged<String>? onNavigate;

  static const _visibleIds = <String>{
    'dashboard',
    'workshops',
    'checklist',
    'reports',
    'settings',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final visible = PlatformNavData.primaryItems
        .where((entry) => _visibleIds.contains(entry.id))
        .toList();

    void navigate(String route) {
      if (onNavigate != null) {
        onNavigate!(route);
        return;
      }
      try {
        context.go(route);
      } catch (_) {}
    }

    return Container(
      decoration: const BoxDecoration(
        color: PtTheme.white,
        border: Border(top: BorderSide(color: PtTheme.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (final entry in visible)
                Expanded(
                  child: _DockDestination(
                    entry: entry,
                    label: strings.tKey(entry.labelKey),
                    active: entry.isActive(currentRoute),
                    onTap: () => navigate(entry.route),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockDestination extends StatelessWidget {
  const _DockDestination({
    required this.entry,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final PlatformNavEntry entry;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('mobile-dock-${entry.id}'),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                width: 40,
                height: 26,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFEAF4EF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  entry.icon,
                  size: 19,
                  color: active ? PtTheme.deepGreen : PtTheme.muted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PtTheme.font(
                  10,
                  lineHeight: 13,
                  weight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? PtTheme.deepGreen : PtTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
