import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:l10n/l10n.dart';

import '../../../platform_theme.dart';

/// Dashboard-local semantic additions for the Orbit layout.
///
/// Colours come from [PtTheme]; the radius/height family is the premium house
/// style (14/16/999) and is flagged as a divergence from the older Platform
/// primitives (8–10px radius, 40–44px height).
abstract final class Trellis {
  static const buttonHeight = 48.0;
  static const buttonRadius = 999.0;
  static const surfaceRadius = 16.0;
  static const pillHeight = 30.0;
  static const gap = 16.0;
  static const fast = Duration(milliseconds: 140);

  static const tint = Color(0xFFE9F3EF);
  static const tintDeep = Color(0xFF04523A);
  static const neutralTint = Color(0xFFF3F1F7);
  static const amberTint = Color(0xFFFBF1E2);
  static const roseTint = Color(0xFFFCEBEF);
  static const blue = Color(0xFF1D4ED8);
  static const blueTint = Color(0xFFE9EEFC);
  static const darkStart = Color(0xFF0B3B2E);
  static const darkEnd = Color(0xFF00563C);
  static const onDarkMuted = Color(0xFFB7E4CE);

  static const railColors = <Color>[
    Color(0xFF5FD3A9),
    Color(0xFF9BE3C6),
    Color(0xFFF0B26A),
    Color(0xFF8FB7FF),
    Color(0xFFC9C6D4),
  ];

  static TextStyle text(
    double size, {
    FontWeight weight = FontWeight.w400,
    double height = 1.3,
    double tracking = 0,
    Color color = PtTheme.ink,
    bool tabular = false,
  }) {
    return PtTheme.font(
      size,
      lineHeight: size * height,
      weight: weight,
      tracking: tracking,
      color: color,
    ).copyWith(
      fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    );
  }

  static TextStyle get eyebrow =>
      text(10.5, weight: FontWeight.w800, tracking: 1.1, color: PtTheme.muted);

  static TextStyle get pageTitle =>
      text(30, weight: FontWeight.w800, tracking: -0.9, height: 1.15);

  static TextStyle get sectionTitle =>
      text(17, weight: FontWeight.w800, tracking: -0.2);

  static TextStyle get body => text(13, height: 1.5, color: PtTheme.muted);
}

class TrellisSurface extends StatelessWidget {
  const TrellisSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = PtTheme.white,
    this.radius = Trellis.surfaceRadius,
    this.border = PtTheme.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

enum TrellisButtonVariant { primary, secondary, ghost, danger }

class TrellisButton extends StatefulWidget {
  const TrellisButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = TrellisButtonVariant.primary,
    this.isLoading = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final TrellisButtonVariant variant;
  final bool isLoading;
  final bool compact;

  @override
  State<TrellisButton> createState() => _TrellisButtonState();
}

class _TrellisButtonState extends State<TrellisButton> {
  bool _hover = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final v = widget.variant;
    final background = switch (v) {
      TrellisButtonVariant.primary =>
        _hover ? Trellis.tintDeep : PtTheme.deepGreen,
      TrellisButtonVariant.secondary =>
        _hover ? Trellis.neutralTint : PtTheme.white,
      TrellisButtonVariant.ghost =>
        _hover ? Trellis.neutralTint : Colors.transparent,
      TrellisButtonVariant.danger =>
        _hover ? const Color(0xFFB3123B) : PtTheme.rose,
    };
    final foreground = switch (v) {
      TrellisButtonVariant.primary ||
      TrellisButtonVariant.danger => PtTheme.white,
      TrellisButtonVariant.secondary => PtTheme.ink,
      TrellisButtonVariant.ghost => PtTheme.muted,
    };
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (enabled) widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: enabled ? widget.onPressed : null,
            child: AnimatedContainer(
              duration: Trellis.fast,
              height: Trellis.buttonHeight,
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 14 : 20,
              ),
              decoration: BoxDecoration(
                color: enabled ? background : Trellis.neutralTint,
                borderRadius: BorderRadius.circular(Trellis.buttonRadius),
                border: Border.all(
                  color: _focused
                      ? PtTheme.deepGreen
                      : v == TrellisButtonVariant.secondary
                      ? PtTheme.border
                      : Colors.transparent,
                  width: _focused ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foreground,
                      ),
                    )
                  else if (widget.icon != null)
                    Icon(
                      widget.icon,
                      size: 18,
                      color: enabled
                          ? foreground
                          : PtTheme.muted.withValues(alpha: 0.6),
                    ),
                  if (widget.isLoading || widget.icon != null)
                    const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Trellis.text(
                        13.5,
                        weight: FontWeight.w700,
                        color: enabled
                            ? foreground
                            : PtTheme.muted.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum TrellisTone { positive, neutral, warning, danger, info }

class TrellisPill extends StatelessWidget {
  const TrellisPill({
    super.key,
    required this.label,
    this.tone = TrellisTone.neutral,
    this.dot = true,
  });

  final String label;
  final TrellisTone tone;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (tone) {
      TrellisTone.positive => (PtTheme.deepGreen, Trellis.tint),
      TrellisTone.neutral => (PtTheme.muted, Trellis.neutralTint),
      TrellisTone.warning => (PtTheme.gold, Trellis.amberTint),
      TrellisTone.danger => (PtTheme.rose, Trellis.roseTint),
      TrellisTone.info => (Trellis.blue, Trellis.blueTint),
    };
    return Container(
      height: Trellis.pillHeight,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Trellis.text(11.5, weight: FontWeight.w700, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

class TrellisSkeleton extends StatefulWidget {
  const TrellisSkeleton({super.key});

  @override
  State<TrellisSkeleton> createState() => _TrellisSkeletonState();
}

class _TrellisSkeletonState extends State<TrellisSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 1000;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 24, wide ? 28 : 16, 40),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final alpha = animate ? 0.45 + _controller.value * 0.3 : 0.6;
              Widget block({double? height, double? width}) => Container(
                height: height,
                width: width,
                decoration: BoxDecoration(
                  color: PtTheme.border.withValues(alpha: alpha * 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
              );
              Widget smallBar(double width) => Container(
                width: width,
                height: 10,
                decoration: BoxDecoration(
                  color: PtTheme.border.withValues(alpha: alpha),
                  borderRadius: BorderRadius.circular(5),
                ),
              );
              Widget moduleRow(List<int> spans) => Row(
                children: [
                  for (var i = 0; i < spans.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(flex: spans[i], child: block(height: 190)),
                  ],
                ],
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  smallBar(160),
                  const SizedBox(height: 10),
                  smallBar(240),
                  const SizedBox(height: 18),
                  block(height: 56),
                  const SizedBox(height: 16),
                  moduleRow(const [5, 4, 3]),
                  const SizedBox(height: 12),
                  moduleRow(const [4, 3, 5]),
                  const SizedBox(height: 24),
                  smallBar(120),
                  const SizedBox(height: 10),
                  block(height: 48),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class TrellisEmpty extends StatelessWidget {
  const TrellisEmpty({
    super.key,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: TrellisSurface(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Trellis.tint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    size: 26,
                    color: PtTheme.deepGreen,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Trellis.text(17, weight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(body, textAlign: TextAlign.center, style: Trellis.body),
                const SizedBox(height: 20),
                TrellisButton(
                  label: actionLabel,
                  icon: Icons.add_rounded,
                  onPressed: onAction,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TrellisError extends StatelessWidget {
  const TrellisError({super.key, required this.strings, required this.onRetry});

  final UiMessageStrings strings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: TrellisSurface(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strings.tKey(CommonKeys.stateError),
                  textAlign: TextAlign.center,
                  style: Trellis.text(14, weight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TrellisButton(
                  label: strings.tKey(CommonKeys.buttonRetry),
                  variant: TrellisButtonVariant.secondary,
                  onPressed: onRetry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
