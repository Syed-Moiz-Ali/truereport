import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../signin_tokens.dart';

/// The single primary action of "The dock".
///
/// Keeps its accent fill while busy (a spinner replaces the label), blocks
/// re-entry, announces the in-flight state, and shows a 2 px focus ring for
/// keyboard users. The disabled style is only used when the action is
/// structurally unavailable, never for invalid input.
class SignInPrimary extends StatefulWidget {
  const SignInPrimary({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.busyLabel,
    this.height = SignInDims.primaryHeight,
    this.blockKey,
    this.onGlass = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  /// Announced instead of [label] while the request is in flight.
  final String? busyLabel;
  final double height;
  final Key? blockKey;

  /// On the dark glass sheet the action inverts: a white pill with ink text,
  /// which keeps the strongest contrast on the photograph.
  final bool onGlass;

  @override
  State<SignInPrimary> createState() => _SignInPrimaryState();
}

class _SignInPrimaryState extends State<SignInPrimary> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null && !widget.busy;
    final Color fill;
    final Color foreground;
    if (widget.onGlass) {
      fill = enabled || widget.busy
          ? Colors.white
          : Colors.white.withValues(alpha: 0.35);
      foreground = enabled || widget.busy
          ? scheme.onSurface
          : scheme.onSurface.withValues(alpha: 0.55);
    } else {
      fill = enabled || widget.busy
          ? scheme.primary
          : scheme.onSurface.withValues(alpha: 0.12);
      foreground = enabled || widget.busy
          ? scheme.onPrimary
          : scheme.onSurface.withValues(alpha: 0.38);
    }
    final radius = BorderRadius.circular(widget.height / 2);

    return Semantics(
      button: true,
      enabled: enabled,
      liveRegion: widget.busy,
      label: widget.busy && widget.busyLabel != null
          ? widget.busyLabel!
          : widget.label,
      child: Material(
        color: fill,
        borderRadius: radius,
        child: InkWell(
          key: widget.blockKey,
          onTap: enabled ? widget.onPressed : null,
          onFocusChange: (value) => setState(() => _focused = value),
          focusColor: Colors.transparent,
          borderRadius: radius,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: _focused
                  ? Border.all(color: context.colors.focus, width: 2)
                  : null,
            ),
            child: Center(
              child: widget.busy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.onGlass
                            ? scheme.onSurface
                            : scheme.onPrimary,
                      ),
                    )
                  : Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Fx.text(
                        15,
                        20,
                        FontWeight.w700,
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 0
                            : -0.1,
                        color: foreground,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
