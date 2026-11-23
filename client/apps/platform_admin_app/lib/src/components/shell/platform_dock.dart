import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform_providers.dart';
import '../../platform_theme.dart';
import '../platform_nav.dart';
import 'reduce_motion.dart';

/// Platform Admin floating dock — direction A "Docked Command".
///
/// One pill at the bottom of the window owns the five destinations, exactly
/// like the workshop shell: the selected item expands to carry its label,
/// the other four stay icon-only. No overflow sheet, no hidden destination.
/// Audit log is not a dock item; it lives inside Settings (MONITOR group)
/// and the Settings item stays selected while it is open.
///
/// Contract:
/// - exactly the destinations it is given, in order;
/// - host keys ride on the tappable item (`nav-<id>`) so existing tests keep
///   finding them;
/// - the selected item is announced as selected, not merely coloured;
/// - content reserves [reserve] so no list is ever trapped behind the dock.
class PlatformDock extends ConsumerWidget {
  const PlatformDock({
    super.key,
    required this.currentRoute,
    this.onNavigate,
    this.navigationLabel = '',
  });

  final String currentRoute;
  final ValueChanged<String>? onNavigate;

  /// Screen-reader name for the navigation landmark.
  final String navigationLabel;

  /// Vertical space the content must leave clear so nothing hides behind
  /// the dock. The shell reserves this; screens must not add their own.
  static double reserve(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 680 ? 88 : 78;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    const items = PlatformNavData.primaryItems;
    return Semantics(
      container: true,
      label: navigationLabel,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: PtTheme.white,
          border: Border.all(color: PtTheme.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.sizeOf(context).width;
            final share = screenWidth < 600;
            final children = <Widget>[
              for (final entry in items)
                _DockItem(
                  entry: entry,
                  label: strings.tKey(entry.labelKey),
                  selected: entry.isActive(currentRoute),
                  expand: share,
                  onNavigate: onNavigate,
                ),
            ];
            if (!share) {
              return Row(mainAxisSize: MainAxisSize.min, children: children);
            }
            return Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                for (var i = 0; i < children.length; i++)
                  Expanded(
                    // 3:1 split down to the 360px floor: the active item must
                    // still carry its name without clipping.
                    flex: items[i].isActive(currentRoute) ? 3 : 1,
                    child: children[i],
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
    required this.entry,
    required this.label,
    required this.selected,
    required this.expand,
    this.onNavigate,
  });

  final PlatformNavEntry entry;
  final String label;
  final bool selected;
  final bool expand;
  final ValueChanged<String>? onNavigate;

  @override
  State<_DockItem> createState() => _DockItemState();
}

class _DockItemState extends State<_DockItem> {
  bool _focused = false;
  bool _pressed = false;

  void _go(BuildContext context) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(widget.entry.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = PtReduceMotion.duration(
      context,
      const Duration(milliseconds: 220),
    );
    // On the smallest phones the selected item shows its name *instead of*
    // its icon: at 360px an icon plus label does not fit.
    final tight = widget.expand && MediaQuery.sizeOf(context).width < 384;
    final showIcon = !(widget.selected && tight);
    final fg = widget.selected ? PtTheme.white : PtTheme.muted;

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: Tooltip(
        message: widget.label,
        excludeFromSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: Key('nav-${widget.entry.id}'),
            onTap: () => _go(context),
            canRequestFocus: true,
            focusColor: PtTheme.canvas,
            hoverColor: PtTheme.canvas,
            borderRadius: BorderRadius.circular(14),
            onFocusChange: (v) => setState(() => _focused = v),
            onHighlightChanged: (v) => setState(() => _pressed = v),
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                height: 44,
                constraints: widget.expand
                    ? null
                    : BoxConstraints(minWidth: widget.selected ? 104 : 44),
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: widget.selected && !widget.expand ? 14 : 10,
                ),
                decoration: BoxDecoration(
                  color: widget.selected ? PtTheme.deepGreen : null,
                  borderRadius: BorderRadius.circular(14),
                  border: _focused
                      ? Border.all(color: PtTheme.deepGreen, width: 2)
                      : Border.all(color: Colors.transparent, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (showIcon) Icon(widget.entry.icon, size: 18, color: fg),
                    if (widget.selected) ...[
                      if (showIcon) const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PtTheme.font(
                            13,
                            lineHeight: 18,
                            weight: FontWeight.w600,
                            color: fg,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
