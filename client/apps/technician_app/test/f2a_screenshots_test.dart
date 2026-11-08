import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

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
  'exterior-wireframe': 906.25,
};

void main() {
  setUpAll(() async {
    await loadF2AFonts();
  });

  for (final id in f2aScreenIds) {
    for (final locale in const [Locale('en'), Locale('ar')]) {
      for (final scale in const [1.0, 2.0]) {
        testWidgets('screenshot $id ${locale.languageCode} ${scale}x', (
          tester,
        ) async {
          final height = _heights[id]!;
          tester.view.physicalSize = Size(390 * scale, height * scale);
          tester.view.devicePixelRatio = scale;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });
          const rootKey = ValueKey('f2a-screenshot-root');
          await tester.pumpWidget(
            RepaintBoundary(
              key: rootKey,
              child: f2aHost(
                child: f2aScreen(id),
                locale: locale,
                theme: AppTheme.build(
                  isArabic: locale.languageCode == 'ar',
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 400));
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(rootKey),
          );
          final image = await boundary.toImage(pixelRatio: scale);
          final bytes = await tester.runAsync(
            () => image.toByteData(format: ui.ImageByteFormat.png),
          );
          final out = Directory(
            '${repoRoot().path}/docs/ui/figma/f2a-screenshots',
          )..createSync(recursive: true);
          File(
            '${out.path}/${id}_${locale.languageCode}_${scale}x.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
    }
  }
}

