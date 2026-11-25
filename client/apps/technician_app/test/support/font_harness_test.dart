/// Proves the harness registered real Plus Jakarta Sans faces.
///
/// Under the default test font (Ahem) every glyph is the same square, so `III`
/// and `WWW` measure the same width. Real faces do not: if this test fails the
/// config stopped loading the bundled fonts and screenshots would be lying.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../flutter_test_config.dart';

double _width(String text, String family) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: family, fontSize: 40),
    ),
    textDirection: TextDirection.ltr,
  );
  painter.layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

void main() {
  test('registers Plus Jakarta Sans with real glyph metrics, not Ahem', () {
    final narrow = _width('III', plusJakartaSans);
    final wide = _width('WWW', plusJakartaSans);

    expect(
      wide,
      greaterThan(narrow * 1.3),
      reason: 'identical widths mean the family fell back to Ahem',
    );
  });

  test('registers the package-prefixed family with the same faces', () {
    const vehicle = 'Toyota Land Cruiser 2023';

    expect(
      _width(vehicle, 'packages/design_system/Plus Jakarta Sans'),
      closeTo(_width(vehicle, plusJakartaSans), 0.5),
    );
  });
}
