import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../signin_tokens.dart';

/// The focal point: one statement and the tagline, top-aligned on the canvas.
class SignInStatement extends StatelessWidget {
  const SignInStatement({
    required this.statement,
    required this.tagline,
    required this.wide,
    required this.gutter,
    super.key,
  });

  final String statement;
  final String tagline;
  final bool wide;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final compactScale = scale >= 1.5;
    final phoneSize = compactScale ? 26.0 : 34.0;
    final wideSize = compactScale ? 44.0 : 60.0;

    final statementStyle = wide
        ? Fx.text(
            isArabic ? wideSize - 2 : wideSize,
            isArabic ? wideSize * 1.31 : wideSize * 1.07,
            FontWeight.w800,
            isArabic ? 0 : -1.8,
            color: scheme.onSurface,
          )
        : Fx.text(
            isArabic ? phoneSize - 2 : phoneSize,
            isArabic ? phoneSize * 1.38 : phoneSize * 1.15,
            FontWeight.w800,
            isArabic ? 0 : -0.9,
            color: scheme.onSurface,
          );
    final taglineStyle = wide
        ? Fx.text(
            16,
            isArabic ? 28 : 24,
            FontWeight.w400,
            isArabic ? 0 : -0.1,
            color: scheme.onSurfaceVariant,
          )
        : Fx.text(
            15,
            isArabic ? 26 : 22,
            FontWeight.w400,
            0,
            color: scheme.onSurfaceVariant,
          );

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(gutter, 0, gutter, 0),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            top: wide ? SignInDims.canvasTopWide : SignInDims.canvasTopPhone,
          ),
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
              SizedBox(height: wide ? 24 : 20),
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
    );
  }
}
