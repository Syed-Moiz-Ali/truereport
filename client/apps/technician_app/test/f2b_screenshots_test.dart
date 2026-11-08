import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/f2a_test_fonts.dart';
import 'support/f2b_views.dart';

void main() {
  setUpAll(() async {
    await loadF2AFonts();
  });

  for (final id in f2bScreenIds) {
    for (final locale in const [Locale('en'), Locale('ar')]) {
      for (final scale in const [1.0, 2.0]) {
        testWidgets('screenshot $id ${locale.languageCode} ${scale}x', (
          tester,
        ) async {
          final height = f2bHeights[id]!;
          tester.view.physicalSize = Size(390 * scale, height * scale);
          tester.view.devicePixelRatio = scale;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });
          const rootKey = ValueKey('f2b-screenshot-root');
          await tester.pumpWidget(
            RepaintBoundary(
              key: rootKey,
              child: f2bHost(
                child: f2bScreen(id, figma: false),
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
          final root = repoRoot();
          for (final dir in ['f2b-screenshots', 'f2a-screenshots']) {
            final out = Directory('${root.path}/docs/ui/figma/$dir')
              ..createSync(recursive: true);
            File(
              '${out.path}/${id}_${locale.languageCode}_${scale}x.png',
            ).writeAsBytesSync(bytes!.buffer.asUint8List());
          }
        });
      }
    }
  }
}
