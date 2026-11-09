import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/fidelity_output.dart';

/// Step 2a write-routing guard: normal test runs must never modify tracked
/// files under `docs/`. Captures route to system temp unless the suite runs
/// with `--dart-define=UPDATE_FIDELITY=true`.
void main() {
  test('fidelity output defaults to temp when the flag is unset', () {
    const update = bool.fromEnvironment('UPDATE_FIDELITY');
    if (update) {
      return;
    }
    final resolved = resolveFidelityPath(
      repoRootPath: '/repo',
      docsUiRelative: 'figma/fidelity/f2a1/login/figma-text',
      update: update,
    );
    expect(resolved.startsWith('/repo/docs'), isFalse);
    expect(resolved, contains('truereport-fidelity'));
    expect(
      resolveFidelityPath(
        repoRootPath: '/repo',
        docsUiRelative: 'figma/fidelity/f2a1/login/figma-text',
        update: true,
      ),
      '/repo/docs/ui/figma/fidelity/f2a1/login/figma-text',
    );
  });

  test('no hardcoded docs/ui/figma write targets remain in tests', () {
    final separator = Platform.pathSeparator;
    var directory = Directory.current;
    while (true) {
      final marker = File(
        '${directory.path}${separator}apps${separator}technician_app'
        '${separator}lib${separator}src${separator}models.dart',
      );
      if (marker.existsSync()) {
        break;
      }
      final parent = directory.parent;
      if (parent.path == directory.path) {
        throw StateError('Could not find the Flutter client root.');
      }
      directory = parent;
    }
    final testDir = Directory(
      '${directory.path}${separator}apps${separator}technician_app'
      '${separator}test',
    );
    final offenders = <String>[];
    for (final entity in testDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      if (entity.path.endsWith('fidelity_write_guard_test.dart') ||
          entity.path.endsWith('fidelity_output.dart')) {
        continue;
      }
      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final trimmed = lines[index].trimLeft();
        if (trimmed.startsWith('//')) {
          continue;
        }
        if (RegExp(r'docs/ui/figma/(fidelity|f2a-screenshots|f3a-screenshots|f2b-screenshots)')
            .hasMatch(lines[index])) {
          offenders.add('${entity.path}:${index + 1}');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
