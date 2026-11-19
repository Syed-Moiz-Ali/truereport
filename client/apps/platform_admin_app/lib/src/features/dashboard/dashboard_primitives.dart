import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dashboard_data.dart';
import 'dashboard_palette.dart';

/// Local type scale. Base family and fallbacks come from the design system so
/// Arabic, Cyrillic, CJK and Telugu keep rendering with the shipped fonts.
abstract final class DashboardType {
  static TextStyle _style(
    double size,
    double lineHeight,
    FontWeight weight,
    double tracking,
    Color color,
  ) => Fx.text(size, lineHeight, weight, tracking, color: color);

  static TextStyle hero(Color color) => _style(
    38,
    42,
    FontWeight.w800,
    -1.2,
    color,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static TextStyle heroCompact(Color color) => _style(
    34,
    38,
    FontWeight.w800,
    -1.0,
    color,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static TextStyle stat(Color color) => _style(
    38,
    40,
    FontWeight.w800,
    -1.2,
    color,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static TextStyle statCompact(Color color) => _style(
    36,
    38,
    FontWeight.w800,
    -1.0,
    color,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static TextStyle sectionTitle(Color color) =>
      _style(15, 20, FontWeight.w800, -0.2, color);

  static TextStyle rowTitle(Color color) =>
      _style(14, 20, FontWeight.w600, 0, color);

  static TextStyle cardTitle(Color color) =>
      _style(14, 19, FontWeight.w700, -0.1, color);

  static TextStyle body(Color color) =>
      _style(13.5, 20, FontWeight.w400, 0, color);

  static TextStyle meta(Color color) =>
      _style(12, 17, FontWeight.w400, 0, color);

  static TextStyle eyebrow(Color color) =>
      _style(12, 16, FontWeight.w800, 0.9, color);

  static TextStyle numberSmall(Color color) => _style(
    20,
    24,
    FontWeight.w800,
    -0.5,
    color,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static TextStyle button(Color color) =>
      _style(13, 17, FontWeight.w700, 0, color);
}

/// One bordered surface per logical group. No shadows: borders and tone carry
/// containment in this product.
class DashboardSurface extends StatelessWidget {
  const DashboardSurface({
    super.key,
    required this.child,
    this.radius = 14,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final double radius;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: color ?? palette.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class DashboardEyebrow extends StatelessWidget {
  const DashboardEyebrow(this.label, {super.key, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Text(
      label.toUpperCase(),
      style: DashboardType.eyebrow(color ?? palette.muted),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

@immutable
class DashboardPressState {
  const DashboardPressState({
    this.hovered = false,
    this.focused = false,
    this.pressed = false,
  });

  final bool hovered;
  final bool focused;
  final bool pressed;
}

/// Custom pressable: hover tint, physical press, keyboard activation and a
/// painted focus ring that never shifts layout.
class DashboardPressable extends StatefulWidget {
  const DashboardPressable({
    super.key,
    required this.onTap,
    required this.semanticLabel,
    required this.builder,
    this.borderRadius = 10,
  });

  final VoidCallback? onTap;
  final String semanticLabel;
  final Widget Function(BuildContext context, DashboardPressState state)
  builder;
  final double borderRadius;

  @override
  State<DashboardPressable> createState() => _DashboardPressableState();
}

class _DashboardPressableState extends State<DashboardPressable> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.994 : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: Stack(
              children: [
                widget.builder(
                  context,
                  DashboardPressState(
                    hovered: _hovered,
                    focused: _focused,
                    pressed: _pressed,
                  ),
                ),
                if (_focused)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            widget.borderRadius,
                          ),
                          border: Border.all(color: palette.accent, width: 2),
                        ),
                      ),
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

/// Proportional band. Used for the job lifecycle in the hero.
class DashboardRail extends StatelessWidget {
  const DashboardRail({
    super.key,
    required this.segments,
    this.onSlab = false,
    this.showLegend = true,
  });

  final List<DashboardRailSegment> segments;
  final bool onSlab;
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final visible = segments.where((segment) => segment.count > 0).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    final legendLabel = onSlab ? palette.onSlabMuted : palette.muted;
    final legendCount = onSlab ? palette.onSlab : palette.ink;
    final trackColor = onSlab
        ? Colors.white.withValues(alpha: 0.10)
        : palette.track;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.all(2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 9,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < visible.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      flex: visible[i].count,
                      child: ColoredBox(color: visible[i].color),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (showLegend) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              for (final segment in visible)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: segment.color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      segment.label,
                      style: DashboardType.meta(legendLabel)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${segment.count}',
                      style: DashboardType.meta(legendCount)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class DashboardMeter extends StatelessWidget {
  const DashboardMeter({super.key, required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final filled = (value.clamp(0.0, 1.0) * 1000).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 5,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: filled == 0 ? 1 : filled,
              child: ColoredBox(color: filled == 0 ? palette.track : color),
            ),
            Expanded(
              flex: filled == 0 ? 999 : 1000 - filled,
              child: ColoredBox(color: palette.track),
            ),
          ],
        ),
      ),
    );
  }
}

/// First-reveal motion: 8px rise + fade, 260ms, staggered by section.
class DashboardReveal extends StatefulWidget {
  const DashboardReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<DashboardReveal> createState() => _DashboardRevealState();
}

class _DashboardRevealState extends State<DashboardReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    if (_scheduled) return;
    _scheduled = true;
    if (widget.delay == Duration.zero) {
      _controller.forward();
      return;
    }
    unawaited(
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      }),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - curved.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Human-facing label for a route target, used for semantics on action rows.
String dashboardActionSemantics(String title, String meta) =>
    meta.isEmpty ? title : '$title, $meta';
