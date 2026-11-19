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
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final double height;
  final Key? blockKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !busy;
    final fill = enabled || busy
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.12);
    final foreground = enabled || busy
        ? scheme.onPrimary
        : scheme.onSurface.withValues(alpha: 0.38);

    return Semantics(
      button: true,
      enabled: enabled,
      liveRegion: busy,
      label: label,
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(SignInDims.cellRadius),
        child: InkWell(
          key: blockKey,
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(SignInDims.cellRadius),
          child: SizedBox(
            height: height,
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
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
