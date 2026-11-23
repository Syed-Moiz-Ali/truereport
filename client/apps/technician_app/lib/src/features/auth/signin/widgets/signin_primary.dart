import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../signin_tokens.dart';

/// The single primary action of "The dock".
///
/// Keeps its accent fill while busy (a spinner replaces the label), blocks
/// re-entry, and announces the in-flight state. The disabled style is only
/// used when the action is structurally unavailable, never for invalid input.
class SignInPrimary extends StatelessWidget {
  const SignInPrimary({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.height = SignInDims.primaryHeight,
    this.blockKey,
    this.onGlass = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final double height;
  final Key? blockKey;

  /// On the dark glass sheet the action inverts: a white pill with ink text,
  /// which keeps the strongest contrast on the photograph.
  final bool onGlass;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !busy;
    final Color fill;
    final Color foreground;
    if (onGlass) {
      fill = enabled || busy
          ? Colors.white
          : Colors.white.withValues(alpha: 0.35);
      foreground = enabled || busy
          ? scheme.onSurface
          : scheme.onSurface.withValues(alpha: 0.55);
    } else {
      fill = enabled || busy
          ? scheme.primary
          : scheme.onSurface.withValues(alpha: 0.12);
      foreground = enabled || busy
          ? scheme.onPrimary
          : scheme.onSurface.withValues(alpha: 0.38);
    }

    return Semantics(
      button: true,
      enabled: enabled,
      liveRegion: busy,
      label: label,
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(height / 2),
        child: InkWell(
          key: blockKey,
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: onGlass ? scheme.onSurface : scheme.onPrimary,
                      ),
                    )
                  : Text(
                      label,
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
