import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import 'signin_example.dart';
import 'signin_language_toggle.dart';
import 'signin_mark.dart';
import 'signin_primitives.dart';

/// The identity band: the ink surface collapsed, not dropped.
///
/// Below 900 px a full inspection surface would cost a scroll before the first
/// field, so it becomes a band that still names the product and shows the
/// example vehicle. Above 600 px the band's content shares the form's 520 px
/// column, so the brand and the fields sit on one axis instead of two. Height
/// is a minimum, so 200 % text grows the band instead of clipping it.
class SigninIdentityBand extends StatelessWidget {
  const SigninIdentityBand({super.key, required this.onToggleLanguage});

  final VoidCallback onToggleLanguage;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    // At 1.5× text the band is a legibility strip, not an illustration.
    final largeText = textScale >= 1.5;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tablet = constraints.maxWidth >= 600;
        final showDrawing = tablet && !largeText;

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: SigninMark(
                    onAccent: true,
                    // The form's eyebrow already says "Workshop Admin" a few
                    // dozen pixels below; printing both read as a duplicate.
                    showPortalLabel: false,
                  ),
                ),
                SigninLanguageToggle(
                  onAccent: true,
                  onPressed: onToggleLanguage,
                ),
              ],
            ),
            SizedBox(height: spacing.md),
            Text(
              l10n.signInExampleLabel.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ws.eyebrow.copyWith(
                color: ws.onAccent.withValues(alpha: 0.72),
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: spacing.xs),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Padding(
                padding: EdgeInsetsDirectional.only(end: showDrawing ? 96 : 0),
                child: Text(
                  exampleVehicle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ws.cardTitle.copyWith(color: ws.onAccent),
                ),
              ),
            ),
          ],
        );

        return Container(
          color: ws.ink,
          constraints: const BoxConstraints(minHeight: 132),
          child: Stack(
            children: [
              if (showDrawing)
                PositionedDirectional(
                  end: spacing.lg,
                  top: 56,
                  child: WorkshopChassisMark(
                    width: 60,
                    color: ws.onAccent.withValues(alpha: 0.2),
                  ),
                ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  spacing.lg,
                  spacing.md,
                  spacing.lg,
                  spacing.md,
                ),
                child: tablet
                    ? Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: content,
                        ),
                      )
                    : content,
              ),
            ],
          ),
        );
      },
    );
  }
}
