import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/real_fonts.dart';

/// Proves the harness renders real glyphs.
///
/// Ahem (the engine's fallback in tests) draws every glyph as a full em square,
/// so a 10-character string at 14 px measures exactly 140 px wide. Real Latin
/// text is far narrower. If this test ever sees 140, the font loader regressed
/// and every downstream "no overflow" assertion became meaningless.
void main() {
  test('every theme family is registered in the harness', () {
    expect(
      RealFonts.isLoaded,
      isTrue,
      reason: 'flutter_test_config.dart did not load fonts',
    );
    expect(RealFonts.missingFamilies, isEmpty);
    expect(RealFonts.families, contains(TrFonts.latin));
    expect(RealFonts.families, contains(TrFonts.arabicDefault));
    expect(RealFonts.families, contains('MaterialIcons'));
  });

  testWidgets('theme text resolves Plus Jakarta Sans with real metrics', (
    tester,
  ) async {
    const sample = 'Inspection';
    const fontSize = 14.0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Align(alignment: Alignment.topLeft, child: Text(sample)),
        ),
      ),
    );

    final element = tester.element(find.text(sample));
    final style = DefaultTextStyle.of(element).style;
    expect(style.fontFamily, TrFonts.latin);
    expect(style.fontSize, fontSize);

    final width = tester.getSize(find.text(sample)).width;
    const ahemWidth = fontSize * sample.length;
    expect(
      width,
      isNot(closeTo(ahemWidth, 0.5)),
      reason: 'Text measured ${width}px — that is Ahem, not Plus Jakarta Sans',
    );
    expect(width, lessThan(ahemWidth));
  });
}
