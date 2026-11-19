import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../signin_tokens.dart';
import 'signin_command_strip.dart';

/// Full-bleed hero at the top of the technician sign-in.
///
/// A real workshop/inspection photograph (bundled, so the screen works offline)
/// with the command strip over a top scrim and the statement/tagline stacked
/// over a bottom scrim. The dock sits below it.
class SignInHero extends StatelessWidget {
  const SignInHero({
    required this.title,
    required this.statement,
    required this.tagline,
    required this.englishLabel,
    required this.arabicLabel,
    required this.isArabic,
    required this.wide,
    required this.gutter,
    required this.onLanguageChanged,
    this.englishKey,
    this.arabicKey,
    super.key,
  });

  final String title;
  final String statement;
  final String tagline;
  final String englishLabel;
  final String arabicLabel;
  final bool isArabic;
  final bool wide;
  final double gutter;
  final ValueChanged<bool> onLanguageChanged;
  final Key? englishKey;
  final Key? arabicKey;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compact = textScale >= 1.5;

    final statementStyle =
        (wide
                ? Fx.text(
                    isArabic ? (compact ? 38 : 56) : (compact ? 36 : 58),
                    isArabic ? (compact ? 50 : 74) : (compact ? 44 : 62),
                    FontWeight.w800,
                    isArabic ? 0 : (compact ? -0.8 : -1.6),
                    color: Fx.white,
                  )
                : Fx.text(
                    compact ? 26 : (isArabic ? 30 : 32),
                    compact ? (isArabic ? 36 : 30) : (isArabic ? 41 : 37),
                    FontWeight.w800,
                    isArabic ? 0 : -0.8,
                    color: Fx.white,
                  ))
            .copyWith(
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 2),
                ),
              ],
            );
    final taglineStyle =
        Fx.text(
          wide ? (compact ? 14 : 16) : 15,
          isArabic
              ? (wide ? (compact ? 24 : 28) : 26)
              : (wide ? (compact ? 20 : 24) : 22),
          FontWeight.w400,
          0,
          color: Fx.white.withValues(alpha: 0.86),
        ).copyWith(
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 1),
            ),
          ],
        );

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/signin_hero.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
          ),
          // Top scrim for the command strip.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x99000000), Color(0x00000000)],
                stops: [0, 0.38],
              ),
            ),
          ),
          // Dark scrim for the stacked statement. The photo stays crisp at the
          // bottom edge; the credential sheet overlaps it for the layered look.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x99000000),
                  Color(0xB3000000),
                ],
                stops: [0.32, 0.60, 1],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SignInCommandStrip(
                title: title,
                englishLabel: englishLabel,
                arabicLabel: arabicLabel,
                isArabic: isArabic,
                wide: wide,
                gutter: gutter,
                onImage: true,
                onLanguageChanged: onLanguageChanged,
                englishKey: englishKey,
                arabicKey: arabicKey,
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  gutter,
                  0,
                  gutter,
                  wide ? 112 : 78,
                ),
                child: Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: wide
                              ? SignInDims.statementMaxWide
                              : SignInDims.statementMaxPhone,
                        ),
                        child: Text(statement, style: statementStyle),
                      ),
                      SizedBox(height: wide ? 18 : 12),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: wide
                              ? SignInDims.taglineMaxWide
                              : SignInDims.taglineMaxPhone,
                        ),
                        child: Text(tagline, style: taglineStyle),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
