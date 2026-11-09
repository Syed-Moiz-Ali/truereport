import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/f2a_fidelity_harness.dart';
import 'support/f2a_test_fonts.dart';
import 'support/f2a_test_images.dart';
import 'support/f2b3_defect_detail_fixture.dart';
import 'support/f2b_views.dart';
import 'support/fidelity_output.dart';

/// F2-B.3 Part 2 — Level 1 fidelity capture for Figma screen 09
/// (Defect Detail & Evidence).
///
/// Renders the test-only [F2b3DefectDetailFixture] (exact Figma structure from
/// `Fx*` + `F2b*` shared kits; never the production `DefectDetailView`) at
/// 390 logical px, DPR 2, with real shadows (`enableFidelityShadows`,
/// restored before the test body ends) inside a [RepaintBoundary], then
/// writes `render.png`, `geometry.json` (key-box actuals for the `f2b3`
/// fixture) and `strings.json` under
/// `docs/ui/figma/fidelity/f2b3/defect-detail/`.
///
/// Sample images are decoded from the Figma export rasters by absolute path
/// (same pattern as `loadFigmaTestImage` in the F2-A capture). Nothing is
/// added to any pubspec and `lib/` is untouched, so
/// `f2b_release_guard_test.dart` stays green.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadF2AFonts();
  });

  testWidgets('capture f2b3 defect-detail level1', (tester) async {
    final root = repoRoot();
    final outDir = fidelityOutputDir(
      root,
      'figma/fidelity/f2b3/defect-detail',
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
  const height = F2b3DefectDetailFixture.height;
  final root = repoRoot();
  final wireframePath =
      '${root.path}/docs/ui/figma-export/technision_figma/screens/09_9._Defect_Detail_&_Evidence/assets/composed/png/Blur-1_8036@2x.png';
  final evidencePath =
      '${root.path}/docs/ui/figma-export/technision_figma/screens/09_9._Defect_Detail_&_Evidence/assets/images/rendered_png/AB6AXuClXyUAQtLTkS7GotDu0YwpZvc-mLvq2FI2ng933ExC4Uq4qbafLdUeOK0C434imw-CoHDYH2ZRbZY5uYmsPeWxH5U4_PyY-1_8104@2x.png';
  final wireframe = await tester.runAsync(
    () => loadFigmaTestImage(wireframePath),
  );
  final evidence = await tester.runAsync(
    () => loadFigmaTestImage(evidencePath),
  );
  if (wireframe == null || evidence == null) {
    throw StateError('Figma raster decode returned no image');
  }
  tester.view.physicalSize = const Size(390 * dpr, height * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  const rootKey = ValueKey('f2b3-capture-root');

  await tester.pumpWidget(
    f2bHost(
      child: RepaintBoundary(
        key: rootKey,
        child: SizedBox(
          width: 390,
          height: height,
          child: ColoredBox(
            color: AppTheme.light.colorScheme.surface,
            child: Material(
              type: MaterialType.transparency,
              child: F2b3DefectDetailFixture(
                wireframe: wireframe,
                evidence: evidence,
              ),
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
    // The Level 1 fixture composes the segmented track and save button
    // exact from kit tokens (kit defaults differ from Figma), so boxes are
    // found by key; expected rects are unchanged Figma slots.
    'segmented': find.byKey(const ValueKey('f2b3-segmented-track')),
    'save': find.byKey(const ValueKey('f2b3-save-button')),
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
    throw StateError('PNG encoding returned no data for f2b3 defect-detail');
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
      'sample': 'defect-detail-level1',
      'logicalSize': {'width': 390, 'height': height},
      'devicePixelRatio': dpr,
      'boxes': boxes,
    }),
    flush: true,
  );
  File('${outDir.path}/strings.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'sample': 'defect-detail-level1',
      'locale': 'en',
      'direction': 'ltr',
      'theme': 'light',
      'textScale': 1,
      'strings': strings,
    }),
    flush: true,
  );
}
