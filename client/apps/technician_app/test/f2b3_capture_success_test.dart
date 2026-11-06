import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/f2a_fidelity_harness.dart';
import 'support/f2a_test_fonts.dart';
import 'support/f2b3_success_fixture.dart';
import 'support/f2b_views.dart';

/// F2-B.3 Part 2 — Level 1 fidelity capture for Figma screen 16
/// (Post-Finalization Success).
///
/// Renders the test-only [F2b3SuccessFixture] (exact Figma structure from
/// `Fx*` + `F2b*` shared kits; never the production `SuccessView`) at
/// 390 logical px, DPR 2, with real shadows (`enableFidelityShadows`,
/// restored before the test body ends) inside a [RepaintBoundary], then
/// writes `render.png`, `geometry.json` (key-box actuals for the `f2b3`
/// fixture) and `strings.json` under
/// `docs/ui/figma/fidelity/f2b3/success/`.
///
/// This screen exports no photo/avatar/vehicle raster (spec §5: four SVG
/// icons only, all already in the design-system Figma set and registered by
/// `loadF2AFonts`), so there is nothing to decode here. Nothing is added
/// to any pubspec and `lib/` is untouched, so
/// `f2b_release_guard_test.dart` stays green.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadF2AFonts();
  });

  testWidgets('capture f2b3 success level1', (tester) async {
    final root = repoRoot();
    final outDir = Directory(
      '${root.path}/docs/ui/figma/fidelity/f2b3/success',
    );
    final previous = enableFidelityShadows();
    try {
      await _render(tester, outDir);
    } finally {
      restoreFidelityShadows(previous);
    }
  });
}

Future<void> _render(WidgetTester tester, Directory outDir) async {
  assertFidelityShadows();
  const dpr = 2.0;
  const height = F2b3SuccessFixture.height;
  tester.view.physicalSize = const Size(390 * dpr, height * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  const rootKey = ValueKey('f2b3-capture-root');

  await tester.pumpWidget(
    f2bHost(
      child: const RepaintBoundary(
        key: rootKey,
        child: SizedBox(
          width: 390,
          height: height,
          child: ColoredBox(
            color: Fx.white,
            child: Material(
              type: MaterialType.transparency,
              child: F2b3SuccessFixture(),
            ),
          ),
        ),
      ),
      locale: const Locale('en'),
      theme: AppTheme.light,
      figmaStrings: true,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  final boxFinders = <String, Finder>{
    'f2b3-badge': find.byKey(const ValueKey('f2b3-badge')),
    'f2b3-delivery': find.byKey(const ValueKey('f2b3-delivery')),
    'f2b3-cta': find.byKey(const ValueKey('f2b3-cta')),
  };
  final boxes = <String, dynamic>{};
  for (final entry in boxFinders.entries) {
    if (entry.value.evaluate().isEmpty) continue;
    final rect = tester.getRect(entry.value.first);
    boxes[entry.key] = {
      'x': rect.left,
      'y': rect.top,
      'width': rect.width,
      'height': rect.height,
    };
  }

  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(rootKey),
  );
  final image = await boundary.toImage(pixelRatio: dpr);
  final byteData = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  if (byteData == null) {
    throw StateError('PNG encoding returned no data for f2b3 success');
  }
  outDir.createSync(recursive: true);
  File('${outDir.path}/render.png')
      .writeAsBytesSync(byteData.buffer.asUint8List());

  final strings = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  File('${outDir.path}/geometry.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'sample': 'success-level1',
      'logicalSize': {'width': 390, 'height': height},
      'devicePixelRatio': dpr,
      'boxes': boxes,
    }),
    flush: true,
  );
  File('${outDir.path}/strings.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'sample': 'success-level1',
      'locale': 'en',
      'direction': 'ltr',
      'theme': 'light',
      'textScale': 1,
      'strings': strings,
    }),
    flush: true,
  );
}
