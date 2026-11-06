import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/f2a_test_fonts.dart';

void main() {
  test('Figma raster fixtures are test-only and never bundled', () {
    final root = repoRoot();
    final pubspecs = <File>[
      File('${root.path}/client/apps/technician_app/pubspec.yaml'),
      File('${root.path}/client/packages/design_system/pubspec.yaml'),
    ];
    for (final pubspec in pubspecs) {
      final source = pubspec.readAsStringSync();
      expect(source.contains('figma-export'), isFalse, reason: pubspec.path);
      expect(source.contains('docs/ui/figma'), isFalse, reason: pubspec.path);
      expect(source.contains('Profile-1_7264'), isFalse, reason: pubspec.path);
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
              key.contains('figma-export') ||
              key.contains('Profile-1_7264') ||
              key.contains('1_7503') ||
              key.contains('1_7757'),
        ),
        isFalse,
        reason: 'The Figma raster fixtures must not be in the web asset bundle.',
      );
    }
  });
}
