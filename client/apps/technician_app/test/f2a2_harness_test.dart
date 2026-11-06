import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/f2a_fidelity_harness.dart';
import 'support/f2a_test_fonts.dart';

void main() {
  testWidgets('fidelity capture runs with real shadows and restores the flag', (
    tester,
  ) async {
    // Evidence: the automated test binding disables shadows by default.
    expect(debugDisableShadows, isTrue);
    final previous = enableFidelityShadows();
    expect(debugDisableShadows, isFalse);
    var seenInBuild = true;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          seenInBuild = debugDisableShadows;
          return const SizedBox.shrink();
        },
      ),
    );
    expect(seenInBuild, isFalse);
    assertFidelityShadows();
    restoreFidelityShadows(previous);
  });

  test('capture sources enable fidelity shadows', () {
    final root = repoRoot();
    final files = <File>[
      File(
        '${root.path}/client/apps/technician_app/test/f2a_fidelity_capture_test.dart',
      ),
      File(
        '${root.path}/client/packages/design_system/test/fidelity_capture_test.dart',
      ),
      File(
        '${root.path}/client/apps/technician_app/test/f2a_goldens_test.dart',
      ),
      File(
        '${root.path}/client/apps/technician_app/test/f2a_goldens_dark_test.dart',
      ),
    ];
    for (final file in files) {
      expect(file.existsSync(), isTrue, reason: file.path);
      final source = file.readAsStringSync();
      expect(
        source.contains('enableFidelityShadows()'),
        isTrue,
        reason: '${file.path} must enable real shadows',
      );
      expect(
        source.contains('assertFidelityShadows()') ||
            file.path.contains('goldens'),
        isTrue,
        reason: '${file.path} must guard against disabled shadows',
      );
    }
  });
}
