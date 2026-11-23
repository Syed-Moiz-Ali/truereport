import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'settings_tokens.dart';

/// Local button: 14px radius / 48px tall, inline loading dots, hover, press and
/// a visible keyboard focus ring. No default Material button appearance.
class DeckButton extends StatefulWidget {
  const DeckButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = true,
    this.onHero = false,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool onHero;
  final IconData? icon;
  final bool loading;

  @override
  State<DeckButton> createState() => _DeckButtonState();
}

class _DeckButtonState extends State<DeckButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final palette = DeckPalette.of(context);
    final enabled = !widget.loading && widget.onPressed != null;

    final Color background;
    final Color foreground;
    final Color borderColor;
    if (widget.onHero) {
      background = widget.primary
          ? palette.heroAccent
          : palette.heroInk.withValues(alpha: 0.06);
      foreground = widget.primary ? palette.hero : palette.heroInk;
      borderColor = widget.primary
          ? palette.heroAccent
          : palette.heroMuted.withValues(alpha: 0.45);
    } else {
      background = widget.primary ? palette.accent : palette.surface;
      foreground = widget.primary ? Colors.white : palette.ink;
      borderColor = widget.primary ? palette.accent : palette.border;
    }

    final effectiveBg = !enabled
        ? background.withValues(alpha: 0.45)
        : _hovered
        ? _mix(background, foreground, 0.12)
        : background;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: Focus(
        onFocusChange: (value) => setState(() => _focused = value),
        onKeyEvent: (node, event) {
          if (!enabled) return KeyEventResult.ignored;
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            widget.onPressed?.call();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() {
            _hovered = false;
            _pressed = false;
          }),
          child: GestureDetector(
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
            onTapCancel: enabled
                ? () => setState(() => _pressed = false)
                : null,
            onTap: enabled ? widget.onPressed : null,
            child: AnimatedScale(
              scale: _pressed ? 0.98 : 1,
              duration: DeckMotion.feedback,
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: DeckMotion.feedback,
                curve: Curves.easeOut,
                height: DeckSize.buttonHeight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: effectiveBg,
                  borderRadius: BorderRadius.circular(DeckRadius.button),
                  border: Border.all(
                    color: _focused ? palette.accent : borderColor,
                    width: _focused ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.loading)
                      _LoadingDots(color: foreground)
                    else ...[
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 16, color: foreground),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: DeckType.style(
                          13,
                          18,
                          FontWeight.w600,
                          foreground,
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

  static Color _mix(Color base, Color other, double amount) =>
      Color.lerp(base, other, amount) ?? base;
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots({required this.color});
  final Color color;

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.25, end: 1).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: Interval(
                      i * 0.18,
                      i * 0.18 + 0.5,
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Status pill: 999 radius / 28 tall, dot + label (never colour alone).
class DeckChip extends StatelessWidget {
  const DeckChip({
    super.key,
    required this.label,
    required this.color,
    required this.soft,
    this.onHero = false,
  });

  final String label;
  final Color color;
  final Color soft;
  final bool onHero;

  @override
  Widget build(BuildContext context) {
    final palette = DeckPalette.of(context);
    final fg = onHero ? palette.heroInk : color;
    final bg = onHero ? color.withValues(alpha: 0.18) : soft;
    return Container(
      height: DeckSize.chipHeight,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DeckRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(label, style: DeckType.style(11.5, 15, FontWeight.w600, fg)),
        ],
      ),
    );
  }
}

/// Shaped placeholder in the final content's geometry — never a spinner.
class DeckSkeleton extends StatefulWidget {
  const DeckSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<DeckSkeleton> createState() => _DeckSkeletonState();
}

class _DeckSkeletonState extends State<DeckSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = DeckPalette.of(context);
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.45,
        end: 1,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: palette.skeletonBase,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// One quiet, physical entrance used by the hero and each row group.
class DeckReveal extends StatefulWidget {
  const DeckReveal({super.key, required this.child, this.delay = 0});

  final Widget child;
  final int delay;

  @override
  State<DeckReveal> createState() => _DeckRevealState();
}

class _DeckRevealState extends State<DeckReveal> {
  bool _visible = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduced) {
      _visible = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final delay = Duration(milliseconds: widget.delay.clamp(0, 240));
      if (delay.inMilliseconds == 0) {
        setState(() => _visible = true);
        return;
      }
      Future<void>.delayed(delay).then((_) {
        if (mounted) setState(() => _visible = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduced) return widget.child;
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 0.018),
      duration: DeckMotion.enter,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: DeckMotion.enter,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Non-blocking confirmation banner. Auto-dismisses; no SnackBar appearance.
class DeckToast extends StatelessWidget {
  const DeckToast({
    super.key,
    required this.message,
    required this.isError,
    required this.dismissLabel,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final String dismissLabel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final palette = DeckPalette.of(context);
    final bg = isError ? palette.danger : palette.accent;
    return Semantics(
      liveRegion: true,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(DeckRadius.button),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                message,
                style: DeckType.style(13, 19, FontWeight.w500, Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: dismissLabel,
              child: GestureDetector(
                onTap: onDismiss,
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small uppercase eyebrow used to separate the three intent groups.
class DeckGroupLabel extends StatelessWidget {
  const DeckGroupLabel({super.key, required this.label, this.onHero = false});

  final String label;
  final bool onHero;

  @override
  Widget build(BuildContext context) {
    final palette = DeckPalette.of(context);
    return Text(
      label,
      style: DeckType.style(
        11,
        14,
        FontWeight.w700,
        onHero ? palette.heroAccent : palette.accent,
        tracking: 1.3,
      ),
    );
  }
}
