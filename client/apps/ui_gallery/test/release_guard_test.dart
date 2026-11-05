import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_gallery/fixture_guard.dart';

void main() {
  test('fidelity fixtures are not opt-in by default', () {
    expect(FixtureGuard.allowInRelease, isFalse);
    expect(FixtureGuard.enabled, isTrue);
  });

  test('no production surface references ui_gallery', () {
    final root = _repoRoot();
    final files = <String>[
      'client/apps/technician_app/pubspec.yaml',
      'client/apps/admin_app/pubspec.yaml',
      'infra/docker-compose.prod.yml',
      'infra/nginx/nginx.conf',
      '.github/workflows/ci.yml',
    ];
    for (final relative in files) {
      final file = File('${root.path}/$relative');
      if (!file.existsSync()) continue;
      final contents = file.readAsStringSync();
      expect(
        contents.contains('ui_gallery'),
        isFalse,
        reason: '$relative must not reference the developer gallery',
      );
    }
  });

  test('gallery entry point refuses release without an explicit define', () {
    final root = _repoRoot();
    final main = File('${root.path}/client/apps/ui_gallery/lib/main.dart');
    final contents = main.readAsStringSync();
    expect(contents, contains('FixtureGuard.enabled'));
    expect(contents, contains('_ReleaseBlockedApp'));
  });
}

Directory _repoRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 12; i += 1) {
    if (Directory('${dir.path}/docs/ui/figma').existsSync() &&
        Directory('${dir.path}/client').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError('Could not find repository root from ${Directory.current}');
}
