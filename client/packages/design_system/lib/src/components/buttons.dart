import 'package:design_system/src/tokens.dart';
import 'package:flutter/material.dart';

enum AppButtonVariant { primary, tonal, text, destructive }

class AppButton extends StatefulWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool expand;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final sizing = context.sizing;
    final effective = widget.isLoading ? null : widget.onPressed;
    final isText = widget.variant == AppButtonVariant.text;
    final minimumHeight = isText ? sizing.targetMin : sizing.buttonHeight;

    final (Color background, Color baseForeground) = switch (widget.variant) {
      AppButtonVariant.primary => (brand.fill, brand.onFill),
      AppButtonVariant.tonal => (brand.container, brand.onContainer),
      AppButtonVariant.text => (colors.surface, brand.ink),
      AppButtonVariant.destructive => (colors.error, colors.onError),
    };
    final foreground = effective == null && !widget.isLoading
        ? colors.onSurfaceVariant
        : baseForeground;

    final child = widget.isLoading
        ? SizedBox.square(
            dimension: sizing.iconMd,
            child: CircularProgressIndicator(
              strokeWidth: context.spacing.xs / 2,
              color: foreground,
            ),
          )
        : Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: sizing.iconLg, color: foreground),
                SizedBox(width: context.spacing.sm),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: context.texts.labelLarge?.copyWith(color: foreground),
                ),
              ),
            ],
          );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(context.radii.pill),
    );

    final button = isText
        ? TextButton(
            onPressed: effective,
            onFocusChange: (value) => setState(() => _focused = value),
            style: TextButton.styleFrom(
              foregroundColor: foreground,
              disabledForegroundColor: colors.onSurfaceVariant,
              minimumSize: Size(sizing.targetMin, minimumHeight),
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: context.spacing.xl,
                vertical: context.spacing.md,
              ),
              shape: shape,
              textStyle: context.texts.labelLarge,
            ),
            child: child,
          )
        : FilledButton(
            onPressed: effective,
            onFocusChange: (value) => setState(() => _focused = value),
            style: FilledButton.styleFrom(
              backgroundColor: background,
              foregroundColor: foreground,
              disabledBackgroundColor: widget.isLoading
                  ? background
                  : colors.surfaceContainerHighest,
              disabledForegroundColor: colors.onSurfaceVariant,
              minimumSize: Size(sizing.targetMin, minimumHeight),
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: context.spacing.xl,
                vertical: context.spacing.md,
              ),
              shape: shape,
              textStyle: context.texts.labelLarge,
            ),
            child: child,
          );

    return Semantics(
      button: true,
      enabled: effective != null,
      label: widget.label,
      child: _PressScale(
        enabled: effective != null,
        child: AnimatedContainer(
          duration: context.motionDuration(context.motion.fast),
          curve: context.motion.enterCurve,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.radii.pill),
            boxShadow: <BoxShadow>[
              if (widget.variant == AppButtonVariant.primary)
                ...context.shadows.buttonSubtle,
              if (_focused) context.shadows.focus,
            ],
          ),
          child: SizedBox(
            width: widget.expand ? double.infinity : null,
            child: button,
          ),
        ),
      ),
    );
  }
}

class AppIconButton extends StatefulWidget {
  const AppIconButton({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.tooltip,
    this.filled = false,
    this.isSelected = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? tooltip;
  final bool filled;
  final bool isSelected;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  late final FocusNode _focusNode = FocusNode()..addListener(_handleFocus);
  bool _focused = false;

  void _handleFocus() {
    if (mounted) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final colors = context.colors;
    final sizing = context.sizing;
    final selected = widget.isSelected;
    final background = selected
        ? brand.fill
        : widget.filled
        ? brand.container
        : null;
    final foreground = selected
        ? brand.onFill
        : widget.filled
        ? brand.onContainer
        : brand.ink;

    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      selected: selected,
      label: widget.semanticLabel,
      child: AnimatedContainer(
        duration: context.motionDuration(context.motion.fast),
        curve: context.motion.enterCurve,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.radii.pill),
          boxShadow: _focused ? [context.shadows.focus] : null,
        ),
        child: Tooltip(
          message: widget.tooltip ?? widget.semanticLabel,
          excludeFromSemantics: true,
          child: IconButton(
            onPressed: widget.onPressed,
            focusNode: _focusNode,
            style: IconButton.styleFrom(
              minimumSize: Size(sizing.targetMin, sizing.targetMin),
              backgroundColor: background,
              foregroundColor: foreground,
              disabledForegroundColor: colors.onSurfaceVariant,
              iconSize: sizing.iconLg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.radii.pill),
              ),
            ),
            icon: Icon(widget.icon),
          ),
        ),
      ),
    );
  }
}

class _PressScale extends StatefulWidget {
  const _PressScale({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.enabled && _pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: widget.enabled ? (_) => _setPressed(true) : null,
      onPointerUp: widget.enabled ? (_) => _setPressed(false) : null,
      onPointerCancel: widget.enabled ? (_) => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _pressed ? context.motion.pressScale : 1,
        duration: context.motionDuration(context.motion.fast),
        curve: context.motion.enterCurve,
        child: widget.child,
      ),
    );
  }
}
