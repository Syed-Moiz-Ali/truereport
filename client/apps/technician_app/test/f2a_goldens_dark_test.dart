import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/f2a_fidelity_harness.dart';
import 'support/f2a_test_fonts.dart';
import 'support/f2a_views.dart';

const _heights = <String, double>{
  'login': 858,
  'assigned-jobs': 1002,
  'empty-state': 884,
  'job-intake': 1128,
  'consent': 972,
  'equipment': 910,
  'inspection-hub': 1130,
};

void main() {
  setUpAll(() async {
    await loadF2AFonts();
  });

  for (final id in f2aScreenIds) {
    testWidgets('$id golden EN dark (derived)', (tester) async {
      final previous = enableFidelityShadows();
      tester.view.physicalSize = Size(390, _heights[id]!);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        f2aHost(
          child: f2aScreen(id),
          locale: const Locale('en'),
          theme: AppTheme.dark,
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/f2a_${id}_en_dark.png'),
      );
      restoreFidelityShadows(previous);
    });
  }
}
