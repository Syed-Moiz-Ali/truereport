import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/f2a_test_fonts.dart';

/// F2-B release guard (mirrors the F2-A.2 J7 guard
/// `f2a2_asset_guard_test.dart`).
///
/// F2-B screens render neutral silhouettes / initials discs in the Figma
/// media slots (see `docs/ui/figma/f2b-slot-sheet.md`); no Figma raster PNG is
/// decoded by any test helper and nothing under `docs/ui/figma-export` may
/// reach a release bundle. This test fails if:
///   - a pubspec asset section references the Figma export,
///   - `lib/` source references the Figma export, or
///   - the built web asset manifest bundles a Figma raster.
void main() {
  test('Figma rasters are test-only and never bundled (F2-B)', () {
    final root = repoRoot();
    final pubspecs = <File>[
      File('${root.path}/client/apps/technician_app/pubspec.yaml'),
      File('${root.path}/client/packages/design_system/pubspec.yaml'),
    ];
    for (final pubspec in pubspecs) {
      final source = pubspec.readAsStringSync();
      expect(source.contains('figma-export'), isFalse, reason: pubspec.path);
      expect(source.contains('docs/ui/figma'), isFalse, reason: pubspec.path);
    }

    final lib = Directory('${root.path}/client/apps/technician_app/lib');
    for (final file in lib.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      expect(
        source.contains('figma-export'),
        isFalse,
        reason: '${file.path} must not reference the Figma export',
      );
    }

    final support =
        Directory('${root.path}/client/apps/technician_app/test/support');
    final f2bViews =
        File('${support.path}/f2b_views.dart').readAsStringSync();
    expect(
      f2bViews.contains('.png'),
      isFalse,
      reason: 'f2b_views.dart must not decode raster fixtures',
    );

    final manifest = File(
      '${root.path}/client/apps/technician_app/build/web/assets/AssetManifest.json',
    );
    if (manifest.existsSync()) {
      final assets = (jsonDecode(manifest.readAsStringSync()) as Map)
          .keys
          .cast<String>();
      expect(
        assets.any(
          (key) =>
              key.contains('figma-export') || key.contains('docs/ui/figma'),
        ),
        isFalse,
        reason: 'The Figma export must not be in the web asset bundle.',
      );
    }
  });
}
