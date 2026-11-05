import 'package:flutter/material.dart';
import 'package:ui_gallery/fixture_guard.dart';
import 'package:ui_gallery/gallery_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!FixtureGuard.enabled) {
    runApp(const _ReleaseBlockedApp());
    return;
  }
  runApp(const GalleryApp());
}

const double _blockedPadding = 24;

/// Shown only if someone builds the gallery in release mode without the
/// explicit `ALLOW_FIDELITY_FIXTURES=true` opt-in. No fixtures are mounted.
class _ReleaseBlockedApp extends StatelessWidget {
  const _ReleaseBlockedApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(_blockedPadding),
            child: Text(
              'TrueReport UI gallery is a development tool and is disabled in '
              'release builds.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ),
    );
  }
}
