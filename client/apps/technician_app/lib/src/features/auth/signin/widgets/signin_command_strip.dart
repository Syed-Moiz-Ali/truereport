import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../signin_tokens.dart';

/// The 56/72 px command strip: product name at the start, language at the end.
class SignInCommandStrip extends StatelessWidget {
  const SignInCommandStrip({
    required this.title,
    required this.englishLabel,
    required this.arabicLabel,
    required this.isArabic,
    required this.wide,
    required this.gutter,
    required this.onLanguageChanged,
    this.onImage = false,
    this.englishKey,
    this.arabicKey,
    super.key,
  });

  final String title;
  final String englishLabel;
  final String arabicLabel;
  final bool isArabic;
  final bool wide;
  final double gutter;
  final ValueChanged<bool> onLanguageChanged;
  final bool onImage;
  final Key? englishKey;
  final Key? arabicKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final twoRow = !wide && scale >= 1.8;
    final titleStyle = wide
        ? Fx.text(
            16,
            22,
            FontWeight.w800,
            isArabic ? 0 : -0.3,
            color: onImage ? Fx.white : scheme.onSurface,
          )
        : Fx.text(
            15,
            20,
            FontWeight.w800,
            isArabic ? 0 : -0.2,
            color: onImage ? Fx.white : scheme.onSurface,
          );
    // English-only product: the language switcher is not rendered.
    const Widget language = SizedBox.shrink();
    final titleText = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: titleStyle,
    );

    return SizedBox(
      height: twoRow
          ? SignInDims.stripPhone * 2
          : wide
          ? SignInDims.stripWide
          : SignInDims.stripPhone,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(gutter, 0, gutter, 0),
        child: twoRow
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  titleText,
                  const SizedBox(height: 4),
                  const Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: SizedBox.shrink(),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: titleText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  language,
                ],
              ),
      ),
    );
  }
}
