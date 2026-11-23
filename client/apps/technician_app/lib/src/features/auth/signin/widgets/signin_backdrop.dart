import 'package:flutter/material.dart';

/// The full-bleed photograph behind "Bay Door".
///
/// One bundled technician photograph (credited in
/// `packages/auth/assets/images/CREDITS.md`) with a directional scrim: darkest
/// at the bottom-left where the statement sits, lighter through the middle so
/// the subject stays readable, and slightly darker again behind the sheet.
class SignInBackdrop extends StatelessWidget {
  const SignInBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/signin_hero_technician.jpg',
            package: 'auth',
            fit: BoxFit.cover,
            alignment: const Alignment(0.15, 0),
            filterQuality: FilterQuality.medium,
            // The photo is decorative: the copy and the form carry the meaning.
            excludeFromSemantics: true,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xCC0A1A16),
                  Color(0x590A1A16),
                  Color(0xD90A1A16),
                ],
                stops: [0, 0.45, 1],
              ),
            ),
          ),
          // Extra floor for the statement so its last line never sits on a
          // bright patch of the photograph.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0x99000000), Color(0x00000000)],
                stops: [0, 0.42],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
