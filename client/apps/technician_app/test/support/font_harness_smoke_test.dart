import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'f2a_test_fonts.dart';

/// Gate 4-lite harness proof: the suite paints *real* bundled glyphs.
///
/// Ahem (and any block font) advances every glyph by the same em square.
/// Real proportional fonts do not: six W are much wider than six i. If the
/// loader silently failed, this assertion fails before any screenshot does.
void main() {
  setUpAll(loadF2AFonts);

  double widthOf(String text) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: Fx.display26),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  testWidgets('bundled fonts have proportional real metrics', (tester) async {
    final wide = widthOf('WWWWWW');
    final narrow = widthOf('iiiiii');
    expect(
      wide,
      greaterThan(narrow * 2.0),
      reason:
          'WWWWWW ($wide) should be at least twice iiii ii ($narrow) in a real '
          'proportional font; equal widths mean a fallback block font.',
    );
  });

  testWidgets('a real-font smoke capture encodes a non-empty PNG', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(480, 160);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const key = ValueKey('font-smoke-root');
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ColoredBox(
            color: const Color(0xFFFFFFFF),
            child: Center(
              child: Text(
                'TrueReport',
                style: Fx.display26.copyWith(color: Fx.ink),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(key),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.png),
    );
    expect(data, isNotNull);
    expect(data!.lengthInBytes, greaterThan(1000));
  });
}
