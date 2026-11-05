import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_gallery/gallery_app.dart';

void main() {
  testWidgets('gallery renders and switches locale, theme and text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const GalleryApp());
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Dark').first);
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('2.0x').first);
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('العربية').first);
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('gallery shows the Figma-exact and button-option sections', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const GalleryApp());
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Figma-exact variants (test-only)'), findsOneWidget);
    expect(find.text('Primary button options (A2 re-opened)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
