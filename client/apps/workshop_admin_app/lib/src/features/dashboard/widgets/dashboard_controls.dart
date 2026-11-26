import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_tokens.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/reference_status.dart';

enum QueueButtonVariant { primary, outline, ghost }

/// The dashboard's only button. 48 px tall, 14 px radius, hover tint, 0.985
/// press scale, a 2 px focus ring and a real disabled state.
///
/// Nothing in this file uses `ElevatedButton` / `OutlinedButton`: the house
/// geometry is local to the screen and must not inherit Material defaults.
class QueueButton extends StatefulWidget {
  const QueueButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = QueueButtonVariant.primary,
    this.loading = false,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final QueueButtonVariant variant;
  final bool loading;
  final bool expand;

  @override
  State<QueueButton> createState() => _QueueButtonState();
}

class _QueueButtonState extends State<QueueButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final primary = widget.variant == QueueButtonVariant.primary;
    final outline = widget.variant == QueueButtonVariant.outline;

    final background = !_enabled
        ? (primary ? ws.canvas : Colors.transparent)
        : primary
        ? (_hovered ? ws.accentHover : ws.accent)
        : outline && _hovered
        ? ws.accentSoft
        : Colors.transparent;
    final foreground = !_enabled
        ? ws.muted
        : primary
        ? ws.onAccent
        : (_hovered && outline ? ws.accentHover : ws.ink);
    final borderColor = _focused
        ? ws.focus
        : !_enabled
        ? ws.border
        : primary
        ? Colors.transparent
        : outline
        ? (_hovered ? ws.accent : ws.ink.withValues(alpha: 0.16))
        : Colors.transparent;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      excludeSemantics: true,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() {
            _hovered = false;
            _pressed = false;
          }),
          child: GestureDetector(
            onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
            onTapCancel: _enabled
                ? () => setState(() => _pressed = false)
                : null,
            onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
            onTap: _enabled ? widget.onPressed : null,
            child: AnimatedScale(
              scale: _pressed ? 0.985 : 1,
              duration: DashboardMotion.quick,
              curve: DashboardMotion.enter,
              child: AnimatedContainer(
                duration: DashboardMotion.settle,
                height: DashboardShape.controlHeight,
                width: widget.expand ? double.infinity : null,
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: widget.icon == null ? 20 : 16,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(DashboardShape.control),
                  border: Border.all(
                    color: borderColor,
                    width: DashboardShape.focusWidth,
                  ),
                ),
                child: Row(
                  mainAxisSize: widget.expand
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.loading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(foreground),
                        ),
                      )
                    else if (widget.icon != null)
                      Icon(widget.icon, size: 18, color: foreground),
                    if (widget.loading || widget.icon != null)
                      const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ws.body.copyWith(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w600,
                          color: foreground,
                        ),
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

/// A quiet text action with a 44 px touch target, used for per-section retry.
class QueueTextAction extends StatefulWidget {
  const QueueTextAction({
    required this.label,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  State<QueueTextAction> createState() => _QueueTextActionState();
}

class _QueueTextActionState extends State<QueueTextAction> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: FocusableActionDetector(
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        mouseCursor: SystemMouseCursors.click,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: DashboardMotion.settle,
              height: 44,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: _hovered ? ws.accentSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(DashboardShape.control),
                border: Border.all(
                  color: _focused ? ws.focus : Colors.transparent,
                  width: DashboardShape.focusWidth,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 16, color: ws.accent),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.label,
                    style: ws.meta.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ws.accent,
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

/// 28 px status pill: dot + label, never colour alone, 999 radius.
class QueueStatusPill extends StatelessWidget {
  const QueueStatusPill({required this.label, required this.tone, super.key});

  final String label;
  final WorkshopStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final (foreground, background) = workshopPillColors(tone, ws);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        height: DashboardShape.pillHeight,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(DashboardShape.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ws.meta.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
