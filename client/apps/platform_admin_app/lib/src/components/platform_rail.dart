import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../platform_providers.dart';
import '../platform_theme.dart';
import 'platform_brand_icon.dart';
import 'platform_nav.dart';

/// The command-deck rail: one 76px column that owns navigation for the whole
/// admin. Six destinations, an edge marker for the active one, and a single
/// system-status light at the foot. Labels live in tooltips and in the
/// accessible name, so the rail can stay icon-only without hiding anything
/// from a screen reader or a first-time pointer user.
class PlatformRail extends ConsumerWidget {
  const PlatformRail({super.key, required this.currentRoute, this.onNavigate});

  final String currentRoute;
  final ValueChanged<String>? onNavigate;

  void _navigate(BuildContext context, String route) {
    if (onNavigate != null) {
      onNavigate!(route);
      return;
    }
    try {
      context.go(route);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);

    return Container(
      width: 76,
      decoration: const BoxDecoration(
        color: PtTheme.white,
        border: BorderDirectional(
          end: BorderSide(color: PtTheme.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 18),
          const Center(child: PlatformBrandMark(size: 36)),
          const SizedBox(height: 24),
          for (final entry in PlatformNavData.primaryItems)
            _RailDestination(
              entry: entry,
              label: strings.tKey(entry.labelKey),
              active: entry.isActive(currentRoute),
              onTap: () => _navigate(context, entry.route),
            ),
          const Spacer(),
          Center(child: Container(width: 30, height: 1, color: PtTheme.border)),
          const SizedBox(height: 10),
          Center(
            child: _SystemStatusLight(
              label: strings.tKey(PlatformAdminKeys.sidebarSystemOperational),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// The TrueReport circular brand mark. Shared by the rail, the command bar's
/// mobile header and the mobile navigation sheet so the mark never redraws at
/// a different size or colour in different chrome regions.
class PlatformBrandMark extends StatelessWidget {
  const PlatformBrandMark({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'TrueReport',
      waitDuration: const Duration(milliseconds: 400),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: PtTheme.deepGreen,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SvgPicture.string(
            platformBrandIconSvg,
            width: size * 0.5,
            height: size * 0.5,
            colorFilter: const ColorFilter.mode(PtTheme.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

class _RailDestination extends StatelessWidget {
  const _RailDestination({
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
      child: Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 250),
        excludeFromSemantics: true,
        child: SizedBox(
          height: 54,
          child: Stack(
            children: [
              if (active)
                PositionedDirectional(
                  start: 0,
                  top: 16,
                  child: Container(
                    width: 3,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: PtTheme.deepGreen,
                      borderRadius: BorderRadiusDirectional.horizontal(
                        end: Radius.circular(3),
                      ),
                    ),
                  ),
                ),
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: Key('nav-${entry.id}'),
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(14),
                    hoverColor: PtTheme.canvas,
                    focusColor: PtTheme.deepGreen.withValues(alpha: 0.08),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutCubic,
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFFEAF4EF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        entry.icon,
                        size: 21,
                        color: active ? PtTheme.deepGreen : PtTheme.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemStatusLight extends StatelessWidget {
  const _SystemStatusLight({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 300),
      child: Semantics(
        label: label,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: PtTheme.canvas,
            shape: BoxShape.circle,
            border: Border.all(color: PtTheme.border),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: PtTheme.emerald,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
