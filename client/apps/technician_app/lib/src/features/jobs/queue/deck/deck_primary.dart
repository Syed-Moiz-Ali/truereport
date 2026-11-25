import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../jobs_queue_style.dart';

/// The deck primary action: a 56 px brand-ink button with the label leading
/// and a trailing arrow riding in a circle, pinned in the thumb zone.
///
/// One explicit action per screen; the label comes from the caller so the
/// verb copy stays with the page's l10n resolution.
class DeckPrimaryButton extends StatefulWidget {
  const DeckPrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  State<DeckPrimaryButton> createState() => _DeckPrimaryButtonState();
}

class _DeckPrimaryButtonState extends State<DeckPrimaryButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final enabled = widget.onPressed != null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final background = !enabled
        ? brand.ink.withValues(alpha: 0.42)
        : _hovered
        ? Color.alphaBlend(colors.onSurface.withValues(alpha: 0.12), brand.ink)
        : brand.ink;
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
            child: AnimatedContainer(
              duration: context.motionDuration(
                const Duration(milliseconds: 140),
              ),
              height: QueueMetrics.buttonHeight,
              padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 12, 8),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(QueueMetrics.radiusButton),
                border: Border.all(
                  color: _focused ? colors.focus : Colors.transparent,
                  width: 2,
                ),
                boxShadow: enabled ? context.shadows.buttonSubtle : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: queueText(
                        context,
                        16,
                        weight: FontWeight.w700,
                        height: 22,
                        tracking: -0.2,
                        color: enabled
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      rtl
                          ? Icons.arrow_back_rounded
                          : Icons.arrow_forward_rounded,
                      size: 20,
                      color: Colors.white,
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
