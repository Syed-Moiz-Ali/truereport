import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../signin_tokens.dart';

/// The brand mark + statement that sit on the photograph ("Bay Door").
///
/// Three blocks, nothing else: the product mark, one uppercase eyebrow, a two
/// line statement, and one supporting sentence. Everything is white on the
/// photograph, so each text block carries a soft shadow for legibility over
/// bright detail.
class SignInStatement extends StatelessWidget {
  const SignInStatement({
    required this.title,
    required this.tagline,
    required this.wide,
    super.key,
  });

  final String title;
  final String tagline;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shadow = [
      Shadow(
        color: Colors.black.withValues(alpha: 0.38),
        blurRadius: 20,
        offset: const Offset(0, 2),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: wide ? 34 : 30,
              height: wide ? 34 : 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(wide ? 10 : 9),
              ),
              child: Text(
                'TR',
                style: Fx.text(
                  wide ? 12 : 11,
                  wide ? 15 : 14,
                  FontWeight.w800,
                  0.2,
                  color: scheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'TrueReport',
              style: Fx.text(
                wide ? 15 : 14,
                19,
                FontWeight.w800,
                -0.2,
                color: Colors.white,
              ).copyWith(shadows: shadow),
            ),
          ],
        ),
        SizedBox(height: wide ? 20 : 22),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: wide
                ? SignInDims.statementMaxWide
                : SignInDims.statementMaxPhone,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 560 : 300),
                child: Text(
                  title,
                  style: Fx.text(
                    wide ? SignInDims.titleWide : SignInDims.titlePhone,
                    wide ? 58 : 36,
                    FontWeight.w800,
                    wide ? -1.4 : -0.9,
                    color: Colors.white,
                  ).copyWith(shadows: shadow),
                ),
              ),
              SizedBox(height: wide ? 12 : 10),
              Text(
                tagline,
                maxLines: 3,
                style: Fx.text(
                  wide ? 15 : 13,
                  wide ? 23 : 20,
                  FontWeight.w400,
                  0,
                  color: Colors.white.withValues(alpha: 0.80),
                ).copyWith(shadows: shadow),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
