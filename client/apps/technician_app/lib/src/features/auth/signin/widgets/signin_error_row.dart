import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../signin_tokens.dart';

/// Reserved status row of "The dock".
///
/// It always occupies at least [SignInDims.errorMinHeight] so a failure does
/// not move the primary action; the row may grow to two lines and the dock
/// grows upward from its fixed bottom edge. Announced as a live region.
class SignInErrorRow extends StatelessWidget {
  const SignInErrorRow({
    this.message,
    this.alignEnd = false,
    this.onDark = false,
    super.key,
  });

  final String? message;
  final bool alignEnd;

  /// Error colour for a dark translucent surface.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final errorColor = onDark ? const Color(0xFFFFC9C4) : scheme.error;
    final text = message;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: SignInDims.errorMinHeight),
      child: Semantics(
        liveRegion: true,
        child: text == null || text.isEmpty
            ? const SizedBox(height: SignInDims.errorMinHeight)
            : Row(
                mainAxisAlignment: alignEnd
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, size: 14, color: errorColor),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Fx.text(
                        12,
                        16,
                        FontWeight.w500,
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 0
                            : 0.1,
                        color: errorColor,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
