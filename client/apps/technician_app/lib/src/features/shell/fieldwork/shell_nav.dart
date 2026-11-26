import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../inspection/fieldwork/fieldwork_ui.dart';

/// Navigation for the technician app in the Fieldwork language.
///
/// Two destinations only — Jobs and Profile. The dock is the phone/tablet
/// surface; the rail is the desktop surface. Both are presentational: the shell
/// resolves the labels and routes, and the preview harness mounts the same
/// widgets with a neutral body.

class TechnicianNavData {
  const TechnicianNavData({
    required this.jobsLabel,
    required this.profileLabel,
    required this.markLabel,
  });

  final String jobsLabel;
  final String profileLabel;

  /// Accessible name of the TR mark ("TrueReport"); the mark is decorative.
  final String markLabel;
}

/// The whole shell frame: a full-width bottom dock below 900, a left rail at or
/// above 900, with the page filling the remaining width.
class TechnicianShellFrame extends StatelessWidget {
  const TechnicianShellFrame({
    required this.index,
    required this.data,
    required this.onSelected,
    required this.body,
    super.key,
  });

  /// 0 = jobs, 1 = profile.
  final int index;
  final TechnicianNavData data;
  final ValueChanged<int> onSelected;
  final Widget body;

  /// The 200 labelled rail would leave less than the 760 board at 900; the
  /// 88 icon rail keeps both the 760/340 jobs board and the 620 profile
  /// fitting at every width at or above this breakpoint.
  static const double railBreakpoint = 900;
  static const double railWidth = 88;
  static const double dockHeight = 64;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= railBreakpoint;
    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      bottomNavigationBar: wide
          ? null
          : FieldworkDock(index: index, data: data, onSelected: onSelected),
      body: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FieldworkRail(index: index, data: data, onSelected: onSelected),
                Expanded(child: body),
              ],
            )
          : body,
    );
  }
}

/// Full-width Fieldwork dock: 64 + safe area, hairline top, two equal tabs.
/// No floating pill, no elevation.
class FieldworkDock extends StatelessWidget {
  const FieldworkDock({
    required this.index,
    required this.data,
    required this.onSelected,
    super.key,
  });

  final int index;
  final TechnicianNavData data;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final entries = <_NavEntry>[
      _NavEntry(
        label: data.jobsLabel,
        icon: Icons.work_outline_rounded,
        selectedIcon: Icons.work_rounded,
      ),
      _NavEntry(
        label: data.profileLabel,
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: TechnicianShellFrame.dockHeight,
          child: Row(
            children: [
              for (var position = 0; position < entries.length; position++)
                Expanded(
                  child: _DockTab(
                    entry: entries[position],
                    active: index == position,
                    onTap: () => onSelected(position),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockTab extends StatelessWidget {
  const _DockTab({
    required this.entry,
    required this.active,
    required this.onTap,
  });

  final _NavEntry entry;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final foreground = active ? brand.onContainer : colors.onSurfaceVariant;
    return FieldworkPress(
      onTap: onTap,
      radius: FieldworkMetrics.controlRadius,
      selected: active,
      semanticLabel: entry.label,
      child: ExcludeSemantics(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: context.motionDuration(context.motion.fast),
              curve: context.motion.enterCurve,
              width: 64,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? brand.container : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                active ? entry.selectedIcon : entry.icon,
                size: 22,
                color: foreground,
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 6),
              child: Text(
                entry.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: fieldworkText(
                  context,
                  11.5,
                  weight: FontWeight.w700,
                  height: 15,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-height Fieldwork rail: the TR mark, then the two destinations as
/// icon targets with a start indicator and a tonal active surface.
class FieldworkRail extends StatelessWidget {
  const FieldworkRail({
    required this.index,
    required this.data,
    required this.onSelected,
    super.key,
  });

  final int index;
  final TechnicianNavData data;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final entries = <_NavEntry>[
      _NavEntry(
        label: data.jobsLabel,
        icon: Icons.work_outline_rounded,
        selectedIcon: Icons.work_rounded,
      ),
      _NavEntry(
        label: data.profileLabel,
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
      ),
    ];
    return Container(
      width: TechnicianShellFrame.railWidth,
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        border: BorderDirectional(
          end: BorderSide(color: colors.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 16, bottom: 18),
            child: _Mark(label: data.markLabel),
          ),
          for (var position = 0; position < entries.length; position++) ...[
            if (position > 0) const SizedBox(height: 4),
            _RailItem(
              entry: entries[position],
              active: index == position,
              onTap: () => onSelected(position),
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.entry,
    required this.active,
    required this.onTap,
  });

  final _NavEntry entry;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final foreground = active ? brand.onContainer : colors.onSurfaceVariant;
    return SizedBox(
      height: 64,
      child: Stack(
        children: [
          if (active)
            PositionedDirectional(
              start: 0,
              top: 14,
              bottom: 14,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: brand.ink,
                  borderRadius: const BorderRadiusDirectional.only(
                    topEnd: Radius.circular(3),
                    bottomEnd: Radius.circular(3),
                  ),
                ),
              ),
            ),
          Center(
            child: Tooltip(
              message: entry.label,
              excludeFromSemantics: true,
              waitDuration: const Duration(milliseconds: 400),
              child: FieldworkPress(
                onTap: onTap,
                radius: 12,
                selected: active,
                semanticLabel: entry.label,
                child: ExcludeSemantics(
                  child: AnimatedContainer(
                    duration: context.motionDuration(context.motion.fast),
                    curve: context.motion.enterCurve,
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: active ? brand.container : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      active ? entry.selectedIcon : entry.icon,
                      size: 22,
                      color: foreground,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Semantics(
      label: label,
      image: true,
      child: ExcludeSemantics(
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: brand.fill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'TR',
            textDirection: TextDirection.ltr,
            style: fieldworkText(
              context,
              12,
              weight: FontWeight.w800,
              height: 15,
              tracking: 0.2,
              color: brand.onFill,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavEntry {
  const _NavEntry({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
