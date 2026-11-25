import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'jobs_queue_style.dart';

enum QueueButtonVariant { primary, soft, ghost, onDark }

/// Rounded 14px house button, 48px tall, with hover, press, focus and inline
/// loading states.
class QueueButton extends StatefulWidget {
  const QueueButton({
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = QueueButtonVariant.primary,
    this.expand = false,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final QueueButtonVariant variant;
  final bool expand;
  final bool isLoading;

  @override
  State<QueueButton> createState() => _QueueButtonState();
}

class _QueueButtonState extends State<QueueButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final enabled = widget.onPressed != null && !widget.isLoading;
    final (
      Color base,
      Color foreground,
      Color? border,
    ) = switch (widget.variant) {
      QueueButtonVariant.primary => (brand.ink, Colors.white, null),
      QueueButtonVariant.soft => (
        colors.surfaceContainer,
        colors.onSurface,
        null,
      ),
      QueueButtonVariant.ghost => (
        Colors.transparent,
        colors.onSurface,
        colors.outlineVariant,
      ),
      QueueButtonVariant.onDark => (Colors.white, brand.ink, null),
    };
    final background = !enabled
        ? base.withValues(alpha: 0.42)
        : _hovered
        ? Color.alphaBlend(colors.onSurface.withValues(alpha: 0.07), base)
        : base;
    final label = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: queueText(
            context,
            14.5,
            weight: FontWeight.w700,
            height: 18,
            color: enabled ? foreground : foreground.withValues(alpha: 0.7),
          ),
        ),
        if (widget.icon != null) ...[
          const SizedBox(width: 8),
          Icon(
            widget.icon,
            size: 18,
            color: enabled ? foreground : foreground.withValues(alpha: 0.7),
            textDirection: Directionality.of(context),
          ),
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: enabled ? widget.onPressed : null,
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1,
            duration: context.motionDuration(const Duration(milliseconds: 120)),
            curve: Curves.easeOut,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: AnimatedContainer(
                duration: context.motionDuration(
                  const Duration(milliseconds: 140),
                ),
                height: QueueMetrics.buttonHeight,
                constraints: const BoxConstraints(minWidth: 48),
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(
                    QueueMetrics.radiusButton,
                  ),
                  border: Border.all(
                    color: _focused
                        ? colors.focus
                        : (border ?? Colors.transparent),
                    width: _focused ? 2 : 1,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(opacity: widget.isLoading ? 0 : 1, child: label),
                    if (widget.isLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground,
                        ),
                      ),
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

/// Compact filter chip: pill 999 visual, 44px touch target.
class QueueChip extends StatefulWidget {
  const QueueChip({
    required this.label,
    this.selected = false,
    this.dot,
    this.onPressed,
    super.key,
  });

  final String label;
  final bool selected;
  final Color? dot;
  final VoidCallback? onPressed;

  @override
  State<QueueChip> createState() => _QueueChipState();
}

class _QueueChipState extends State<QueueChip> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    return Semantics(
      button: widget.onPressed != null,
      selected: widget.selected,
      label: widget.label,
      child: FocusableActionDetector(
        enabled: widget.onPressed != null,
        mouseCursor: widget.onPressed == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AnimatedContainer(
              duration: context.motionDuration(
                const Duration(milliseconds: 140),
              ),
              height: 28,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: widget.selected ? brand.container : colors.surface,
                borderRadius: BorderRadius.circular(QueueMetrics.radiusChip),
                border: Border.all(
                  color: _focused
                      ? colors.focus
                      : widget.selected
                      ? brand.ink.withValues(alpha: 0.28)
                      : colors.outlineVariant,
                  width: _focused ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.dot != null) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: widget.dot,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    widget.label,
                    style: queueText(
                      context,
                      12.5,
                      weight: FontWeight.w600,
                      height: 16,
                      color: widget.selected
                          ? brand.onContainer
                          : colors.onSurfaceVariant,
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

class QueueStatusChip extends StatelessWidget {
  const QueueStatusChip({required this.label, required this.tone, super.key});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);
    // No fixed height: padding sets the 28 px resting size and the chip grows
    // with the text scale instead of clipping its word.
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: pair.background,
        borderRadius: BorderRadius.circular(QueueMetrics.radiusChip),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: pair.foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: queueText(
              context,
              12.5,
              weight: FontWeight.w600,
              height: 16,
              color: context.colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Plate-shaped identity mark. Not decorative: it is how a technician finds a
/// vehicle in a row of jobs.
class QueuePlate extends StatelessWidget {
  const QueuePlate(
    this.value, {
    this.large = false,
    this.onDark = false,
    super.key,
  });

  final String value;
  final bool large;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = onDark ? Colors.white : colors.onSurface;
    final border = onDark
        ? Colors.white.withValues(alpha: 0.38)
        : colors.outline;
    final accent = onDark
        ? Colors.white.withValues(alpha: 0.55)
        : context.brand.ink;
    // The plate is an identity run: Latin digits, tabular, never translated.
    // FittedBox shrinks instead of clipping when the text scale grows, so the
    // full plate stays visible instead of truncating.
    final label = Text(
      value,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      softWrap: false,
      style: queueText(
        context,
        large ? 20 : 12.5,
        weight: FontWeight.w700,
        height: large ? 24 : 16,
        tracking: large ? 1.4 : 0.7,
        tabular: true,
        color: foreground,
      ),
    );
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: large ? 14 : 8,
        vertical: large ? 7 : 3,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(large ? 10 : 7),
        border: Border.all(color: border, width: large ? 1.5 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: [
          Container(
            width: large ? 6 : 3,
            height: large ? 18 : 12,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: large ? 8 : 5),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: label,
            ),
          ),
        ],
      ),
    );
  }
}

class QueueProgressBar extends StatelessWidget {
  const QueueProgressBar({
    required this.value,
    required this.total,
    this.onDark = false,
    this.height = 6,
    super.key,
  });

  final int value;
  final int total;
  final bool onDark;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fraction = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    // Absent before work starts: the row shows the count alone until the
    // first item is assessed, so an untouched job never paints a stub bar.
    if (fraction <= 0) {
      return const SizedBox.shrink();
    }
    final track = onDark
        ? Colors.white.withValues(alpha: 0.24)
        : context.colors.surfaceContainerHighest;
    final fill = onDark ? Colors.white : context.brand.ink;
    return Semantics(
      label: '$value/$total',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(QueueMetrics.radiusChip),
        child: SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: track)),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    width: constraints.maxWidth * fraction,
                    color: fill,
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

class QueueSearchField extends StatefulWidget {
  const QueueSearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
    this.autofocus = false,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool autofocus;

  @override
  State<QueueSearchField> createState() => _QueueSearchFieldState();
}

class _QueueSearchFieldState extends State<QueueSearchField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocus);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocus)
      ..dispose();
    super.dispose();
  }

  void _handleFocus() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasText = widget.controller.text.isNotEmpty;
    return Semantics(
      label: widget.hint,
      textField: true,
      child: SizedBox(
        height: QueueMetrics.fieldHeight,
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          onChanged: widget.onChanged,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: [LengthLimitingTextInputFormatter(60)],
          style: queueBody(context),
          cursorColor: context.brand.ink,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: queueBody(context, color: colors.onSurfaceVariant),
            filled: true,
            fillColor: colors.surface,
            isDense: true,
            contentPadding: const EdgeInsetsDirectional.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: colors.onSurfaceVariant,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 46,
              minHeight: 48,
            ),
            suffixIcon: hasText
                ? Semantics(
                    button: true,
                    label: MaterialLocalizations.of(context)
                        .deleteButtonTooltip,
                    child: GestureDetector(
                      onTap: () {
                        widget.controller.clear();
                        widget.onChanged('');
                        widget.onClear();
                      },
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.close_rounded, size: 18),
                      ),
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(QueueMetrics.radiusField),
              borderSide: BorderSide(color: colors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(QueueMetrics.radiusField),
              borderSide: BorderSide(color: colors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(QueueMetrics.radiusField),
              borderSide: BorderSide(color: context.brand.ink, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

class QueueSkeleton extends StatefulWidget {
  const QueueSkeleton({super.key});

  @override
  State<QueueSkeleton> createState() => _QueueSkeletonState();
}

class _QueueSkeletonState extends State<QueueSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.colors.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final alpha = 0.45 + (_controller.value * 0.35);
        final color = base.withValues(alpha: alpha);
        Widget block(double width, double height, [double radius = 8]) =>
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(radius),
              ),
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 176,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
              ),
            ),
            const SizedBox(height: 24),
            block(140, 12),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
                border: Border.all(color: context.colors.outlineVariant),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < 5; i++)
                    Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          block(44, 14),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                block(180, 14),
                                const SizedBox(height: 8),
                                block(120, 11),
                              ],
                            ),
                          ),
                          block(76, 20, 999),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class QueueEmptyPanel extends StatelessWidget {
  const QueueEmptyPanel({
    required this.title,
    required this.body,
    this.action,
    // Kept so existing call sites compile; the deck empty state is
    // illustration-free by design (one sentence + one action).
    this.showRoute = true,
    super.key,
  });

  final String title;
  final String body;
  final Widget? action;
  final bool showRoute;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: queueSection(context),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: queueText(
                context,
                13,
                height: 18,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}

class QueueErrorPanel extends StatelessWidget {
  const QueueErrorPanel({
    required this.title,
    required this.body,
    required this.retryLabel,
    required this.onRetry,
    super.key,
  });

  final String title;
  final String body;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.statusColors.danger.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              size: 22,
              color: context.statusColors.danger.foreground,
            ),
          ),
          const SizedBox(height: 14),
          Text(title, style: queueSection(context)),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: queueText(
                context,
                13,
                height: 18,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 18),
          QueueButton(
            label: retryLabel,
            variant: QueueButtonVariant.soft,
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

/// Small inline note used for offline/sync state.
class QueueNote extends StatelessWidget {
  const QueueNote({
    required this.icon,
    required this.label,
    this.tone = StatusTone.warning,
    super.key,
  });

  final IconData icon;
  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: pair.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: pair.foreground),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: queueText(
                  context,
                  13,
                  height: 18,
                  color: pair.foreground,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
