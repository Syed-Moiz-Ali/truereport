import 'package:design_system/src/components/shell/shell_destination.dart';
import 'package:design_system/src/reduce_motion.dart';
import 'package:design_system/src/tokens.dart';
import 'package:design_system/src/workshop_tokens.dart';
import 'package:flutter/material.dart';

/// The workshop shell's only navigation surface (direction C "The dock").
///
/// Six destinations in one floating pill at the bottom of the window. The
/// selected item expands to carry its label; the other five stay icons. That is
/// the whole interaction: one surface, one name, always in the same place.
///
/// Contract rules it keeps:
/// - exactly the destinations it is given, in order — no overflow sheet and no
///   hidden "More" destination;
/// - the host's keys ride on the tappable item, so `workshop-tab-*` still finds
///   them at every width;
/// - the selected item is announced as selected, not merely coloured.
class WorkshopShellDock extends StatelessWidget {
  const WorkshopShellDock({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.navigationLabel = 'Main navigation',
    super.key,
  });

  final List<WorkshopNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String navigationLabel;

  /// Vertical space the content must leave clear so nothing hides behind the
  /// dock. The shell reserves this; screens must not add their own.
  static double reserve(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 680 ? 88 : 78;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Semantics(
      container: true,
      label: navigationLabel,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: ws.surface,
          border: Border.all(color: ws.border),
          borderRadius: BorderRadius.circular(ws.cardRadius),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Wide: the six items take only what they need (a compact pill).
            // Narrow: they share the full width, so the dock can never overflow
            // the phone. The decision uses the *screen* width, not the inner
            // box, so a 390 phone always gets the generous 3:1 split.
            final screenWidth = MediaQuery.sizeOf(context).width;
            final share = screenWidth < 600;
            final items = <Widget>[
              for (var index = 0; index < destinations.length; index++)
                _DockItem(
                  destination: destinations[index],
                  selected: index == selectedIndex,
                  expand: share,
                  onTap: () => onSelected(index),
                ),
            ];
            if (!share) {
              return Row(mainAxisSize: MainAxisSize.min, children: items);
            }
            return Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                for (var index = 0; index < items.length; index++)
                  Expanded(
                    // Keep the 3:1 split at every width down to the 360 px
                    // floor: the active item must still carry its name, and a
                    // 2:1 split clipped "Overview" to "Over…" (shell Gate 6 F1).
                    flex: index == selectedIndex ? 3 : 1,
                    child: items[index],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DockItem extends StatefulWidget {
  const _DockItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    this.expand = false,
  });

  final WorkshopNavDestination destination;
  final bool selected;
  final bool expand;
  final VoidCallback onTap;

  @override
  State<_DockItem> createState() => _DockItemState();
}

class _DockItemState extends State<_DockItem> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final fg = widget.selected ? ws.onAccent : ws.muted;
    final duration = ReduceMotion.duration(
      context,
      const Duration(milliseconds: 220),
    );
    // On the smallest supported phones the selected item shows its name
    // *instead of* its icon: the design promises one readable label, and at
    // 360 px an icon plus "Overview" does not fit.
    final tight = widget.expand && MediaQuery.sizeOf(context).width < 384;
    final showIcon = !(widget.selected && tight);

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.destination.label,
      child: Tooltip(
        // Icon-only destinations still say their name on hover and on long-press.
        message: widget.destination.label,
        excludeFromSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: widget.destination.key,
            onTap: widget.onTap,
            canRequestFocus: true,
            focusColor: ws.accentSoft,
            hoverColor: ws.canvas,
            borderRadius: BorderRadius.circular(ws.chipRadius + 2),
            onFocusChange: (value) => setState(() => _focused = value),
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              // 44 px minimum: the dock must meet the design system's own
              // touchTarget token (shell Gate 6, blocker 2).
              height: 44,
              // When the dock shares the width, the parent Expanded decides the
              // size; a minWidth here would fight it and overflow.
              constraints: widget.expand
                  ? null
                  : BoxConstraints(minWidth: widget.selected ? 104 : 44),
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: widget.selected && !widget.expand
                    ? spacing.md
                    : (tight && widget.selected ? spacing.xs : spacing.sm),
              ),
              decoration: BoxDecoration(
                color: widget.selected ? ws.accent : null,
                borderRadius: BorderRadius.circular(ws.chipRadius + 2),
                border: _focused
                    ? Border.all(color: ws.focus, width: 2)
                    : Border.all(color: Colors.transparent, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showIcon)
                    Icon(
                      // A destination may omit `selectedIcon`; falling back to
                      // `icon` keeps the active pill from losing its glyph
                      // (shell Gate 6 F5).
                      widget.selected
                          ? (widget.destination.selectedIcon ??
                                widget.destination.icon)
                          : widget.destination.icon,
                      size: 18,
                      color: fg,
                    ),
                  if (widget.selected) ...[
                    if (showIcon) SizedBox(width: spacing.sm),
                    Flexible(
                      child: Text(
                        widget.destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ws.bodyStrong.copyWith(color: fg),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
