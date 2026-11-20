import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/f2a_fidelity_harness.dart';

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
}
