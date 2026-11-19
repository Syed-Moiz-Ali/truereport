import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import 'dashboard_palette.dart';
import 'dashboard_primitives.dart';

/// Skeleton in the shape of the final page. No page-level spinner.
class DashboardSkeleton extends StatefulWidget {
  const DashboardSkeleton({super.key});

  @override
  State<DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<DashboardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      return;
    }
    if (!_controller.isAnimating) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        Color bar(double phase, {double alpha = 1}) {
          final wave = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
          return Color.lerp(
            palette.track,
            palette.borderStrong,
            wave * 0.55 * alpha,
          )!;
        }

        Widget block(double height, double radius, double phase) => Container(
          height: height,
          decoration: BoxDecoration(
            color: bar(phase),
            borderRadius: BorderRadius.circular(radius),
          ),
        );

        Widget barLine(double width, double height, double phase) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: bar(phase, alpha: 0.8),
            borderRadius: BorderRadius.circular(4),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            block(300, 18, _controller.value),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                final queue = DashboardSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          16,
                          18,
                          16,
                          16,
                        ),
                        child: barLine(160, 12, (_controller.value + 0.1) % 1),
                      ),
                      for (var i = 0; i < 4; i++)
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            16,
                            10,
                            16,
                            10,
                          ),
                          child: Row(
                            children: [
                              barLine(34, 34, (_controller.value + i * .1) % 1),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    barLine(
                                      double.infinity,
                                      11,
                                      (_controller.value + i * .12) % 1,
                                    ),
                                    const SizedBox(height: 6),
                                    barLine(
                                      140,
                                      9,
                                      (_controller.value + .3) % 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
                final feed = DashboardSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          16,
                          18,
                          16,
                          16,
                        ),
                        child: barLine(120, 12, (_controller.value + .2) % 1),
                      ),
                      for (var i = 0; i < 4; i++)
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            16,
                            10,
                            16,
                            10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              barLine(
                                double.infinity,
                                11,
                                (_controller.value + i * .15) % 1,
                              ),
                              const SizedBox(height: 6),
                              barLine(170, 9, (_controller.value + .4) % 1),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: queue),
                      const SizedBox(width: 16),
                      Expanded(flex: 5, child: feed),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [queue, const SizedBox(height: 16), feed],
                );
              },
            ),
            const SizedBox(height: 16),
            block(64, 14, (_controller.value + .25) % 1),
          ],
        );
      },
    );
  }
}

/// Scoped error panel. The rest of the page is not rendered because the
/// overview is the page.
class DashboardError extends StatelessWidget {
  const DashboardError({
    super.key,
    required this.strings,
    required this.onRetry,
  });

  final UiMessageStrings strings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return DashboardSurface(
      radius: 18,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 620;
          final lead = Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: palette.badSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.bad.withValues(alpha: 0.2)),
            ),
            child: Icon(Icons.cloud_off_rounded, size: 22, color: palette.bad),
          );
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                strings.tKey(CommonKeys.statusUnhealthy),
                style: DashboardType.sectionTitle(palette.ink)
                    .copyWith(fontSize: 17, height: 23),
              ),
              const SizedBox(height: 4),
              Text(
                strings.tKey(PlatformAdminKeys.pageDashboardSubtitle),
                style: DashboardType.meta(palette.muted),
              ),
            ],
          );
          final action = _RetryButton(
            label: strings.tKey(CommonKeys.buttonRetry),
            onPressed: onRetry,
          );

          return Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 22, 20, 22),
            child: horizontal
                ? Row(
                    children: [
                      lead,
                      const SizedBox(width: 14),
                      Expanded(child: copy),
                      const SizedBox(width: 16),
                      action,
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      lead,
                      const SizedBox(height: 14),
                      copy,
                      const SizedBox(height: 16),
                      action,
                    ],
                  ),
          );
        },
      ),
    );
  }
}

/// First-run state. The same deep panel as the hero, so the page keeps its
/// identity even when there is nothing to report.
class DashboardEmpty extends StatelessWidget {
  const DashboardEmpty({
    super.key,
    required this.strings,
    required this.onRegister,
  });

  final UiMessageStrings strings;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.slabTop, palette.slabBottom],
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 44, 24, 44),
          child: Column(
            children: [
              const _RailMark(),
              const SizedBox(height: 22),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  strings.tKey(PlatformAdminKeys.emptyDashboardTitle),
                  textAlign: TextAlign.center,
                  style: DashboardType.sectionTitle(palette.onSlab).copyWith(
                    fontSize: 20,
                    height: 28,
                    letterSpacing: -0.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _RegisterButton(
                label: strings.tKey(PlatformAdminKeys.pageWorkshopsRegister),
                onPressed: onRegister,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailMark extends StatelessWidget {
  const _RailMark();

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return SizedBox(
      width: 148,
      height: 12,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: ColoredBox(color: palette.railA)),
          const SizedBox(width: 3),
          Expanded(flex: 3, child: ColoredBox(color: palette.railB)),
          const SizedBox(width: 3),
          Expanded(
            flex: 2,
            child: ColoredBox(color: palette.railWarn.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return _SolidButton(
      label: label,
      onPressed: onPressed,
      background: palette.accent,
      hover: palette.accentHover,
      foreground: Colors.white,
      icon: Icons.refresh_rounded,
    );
  }
}

class _RegisterButton extends StatelessWidget {
  const _RegisterButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return _SolidButton(
      label: label,
      onPressed: onPressed,
      background: palette.surface,
      hover: const Color(0xFFEAF3EF),
      foreground: palette.slabTop,
      icon: null,
    );
  }
}

class _SolidButton extends StatefulWidget {
  const _SolidButton({
    required this.label,
    required this.onPressed,
    required this.background,
    required this.hover,
    required this.foreground,
    required this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final Color background;
  final Color hover;
  final Color foreground;
  final IconData? icon;

  @override
  State<_SolidButton> createState() => _SolidButtonState();
}

class _SolidButtonState extends State<_SolidButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? 0.985 : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              height: 44,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _hovered ? widget.hover : widget.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 15, color: widget.foreground),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    widget.label,
                    style: DashboardType.button(widget.foreground),
                  ),
                  if (widget.icon == null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: widget.foreground,
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
