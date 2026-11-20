import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../signin_tokens.dart';

/// The 56/72 px command strip: product name at the start.
///
/// English-only product: no language switcher is rendered.
class SignInCommandStrip extends StatelessWidget {
  const SignInCommandStrip({
    required this.title,
    required this.wide,
    required this.gutter,
    this.onImage = false,
    super.key,
  });

  final String title;
  final bool wide;
  final double gutter;
  final bool onImage;

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
            -0.3,
            color: onImage ? Fx.white : scheme.onSurface,
          )
        : Fx.text(
            15,
            20,
            FontWeight.w800,
            -0.2,
            color: onImage ? Fx.white : scheme.onSurface,
          );
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
                children: [titleText],
              )
            : Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: titleText,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
