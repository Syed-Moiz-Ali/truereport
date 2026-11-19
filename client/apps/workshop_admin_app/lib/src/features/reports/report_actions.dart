import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

enum ReportActionVariant { primary, secondary, ghost, danger }

/// The certificate's action button: radius 14, height 48, inline loading and a
/// keyboard focus ring. One shape for every button on the screen, so the sheet
/// footer region can never mix radii.
class ReportActionButton extends StatefulWidget {
  const ReportActionButton({
    required this.label,
    required this.onPressed,
    this.variant = ReportActionVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = false,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final ReportActionVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final String? semanticLabel;

  static const double height = 48;
  static const double radius = 14;

  @override
  State<ReportActionButton> createState() => _ReportActionButtonState();
}

class _ReportActionButtonState extends State<ReportActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final enabled = widget.onPressed != null && !widget.loading;

    late final Color background;
    late final Color foreground;
    late final Color border;
    if (!enabled) {
      background = ws.canvas;
      foreground = ws.muted;
      border = ws.border;
    } else {
      switch (widget.variant) {
        case ReportActionVariant.primary:
          background = _hovered || _pressed ? ws.accentHover : ws.accent;
          foreground = ws.onAccent;
          border = ws.accent;
        case ReportActionVariant.secondary:
          background = _hovered || _pressed ? ws.canvas : ws.surface;
          foreground = ws.ink;
          border = ws.border;
        case ReportActionVariant.ghost:
          background = _hovered || _pressed ? ws.canvas : ws.surface;
          foreground = ws.ink;
          border = ws.surface;
        case ReportActionVariant.danger:
          background = _hovered || _pressed ? ws.dangerSoft : ws.surface;
          foreground = ws.danger;
          border = ws.danger.withValues(alpha: 0.45);
      }
    }

    final borderRadius = BorderRadius.circular(ReportActionButton.radius);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final child = widget.loading
        ? SizedBox.square(
            dimension: spacing.lg,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: foreground),
                SizedBox(width: spacing.sm),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: ws.bodyStrong.copyWith(color: foreground),
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      child: AnimatedScale(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.985 : 1,
        child: AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 140),
          height: ReportActionButton.height,
          width: widget.expand ? double.infinity : null,
          decoration: BoxDecoration(
            color: background,
            borderRadius: borderRadius,
            border: Border.all(
              color: _focused ? ws.focus : border,
              width: _focused ? 2 : 1,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: enabled ? widget.onPressed : null,
              onFocusChange: (value) => setState(() => _focused = value),
              onHover: (value) => setState(() => _hovered = value),
              onHighlightChanged: (value) => setState(() => _pressed = value),
              borderRadius: borderRadius,
              canRequestFocus: enabled,
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: spacing.gutter,
                ),
                child: Center(
                  widthFactor: widget.expand ? null : 1,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
