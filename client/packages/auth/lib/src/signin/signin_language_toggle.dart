import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// The one escape hatch on this screen: switch the whole app between EN and AR.
///
/// A text button rather than a `WorkshopButton` so it reads as a quiet utility
/// on both the paper canvas and the ink band, and keeps a 44 px target.
class SigninLanguageToggle extends StatelessWidget {
  const SigninLanguageToggle({
    super.key,
    required this.onAccent,
    required this.onPressed,
  });

  final bool onAccent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final foreground = onAccent ? ws.onAccent.withValues(alpha: 0.9) : ws.muted;

    return TextButton(
      key: const Key('sign-in-language'),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xs,
        ),
        minimumSize: Size(ws.touchTarget, ws.touchTarget),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.language, size: 16, color: foreground),
          SizedBox(width: spacing.xs),
          Text(
            isArabic ? l10n.languageEnglish : l10n.languageArabic,
            style: ws.meta.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
