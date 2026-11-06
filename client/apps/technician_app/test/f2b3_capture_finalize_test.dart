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
import 'support/f2b3_finalize_fixture.dart';
import 'support/f2b_views.dart';

/// F2-B.3 Part 2 — Level 1 fidelity capture for Figma screen 14
/// (Finalize & Approval (Swipe)).
///
/// Renders the test-only [F2b3FinalizeFixture] (exact Figma structure from
/// `Fx*` + `F2b*` shared kits; never the production `FinalizeView`) at
/// 390 logical px, DPR 2, with real shadows (`enableFidelityShadows`,
/// restored before the test body ends) inside a [RepaintBoundary], then
/// writes `render.png`, `geometry.json` (key-box actuals for the `f2b3`
/// fixture) and `strings.json` under
/// `docs/ui/figma/fidelity/f2b3/finalize/`.
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

  testWidgets('capture f2b3 finalize level1', (tester) async {
    final root = repoRoot();
    final outDir = Directory(
      '${root.path}/docs/ui/figma/fidelity/f2b3/finalize',
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
  const height = F2b3FinalizeFixture.height;
  final root = repoRoot();
  final avatarPath =
      '${root.path}/docs/ui/figma-export/technision_figma/screens/15_14._Finalize_&_Approval_(Swipe)/assets/images/rendered_png/AB6AXuA6dGDzYZ-RLaWksinhI7SgABKO8bMsu5g5yMUtDsLyRYHhXDRYb_zOrA_A_Ex8Th0NNXJfCUHR_XSUdAmTsbmZrwy0Ys4p-1_8859@2x.png';
  final vehiclePath =
      '${root.path}/docs/ui/figma-export/technision_figma/screens/15_14._Finalize_&_Approval_(Swipe)/assets/images/rendered_png/AB6AXuBC7qJfbrATy1AUuOCrOWmAPfTCHgkIEZHXcXCXZscxIWzB0SWT4WLRS-TpwOQqIHAC2adapAlluFOQv7DkK1cMcwPTKGyh-1_8874@2x.png';
  final avatar = await tester.runAsync(() => loadFigmaTestImage(avatarPath));
  final vehicle = await tester.runAsync(() => loadFigmaTestImage(vehiclePath));
  if (avatar == null || vehicle == null) {
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
            color: Fx.white,
            child: Material(
              type: MaterialType.transparency,
              child: F2b3FinalizeFixture(avatar: avatar, vehicle: vehicle),
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

  final boxes = <String, dynamic>{
    for (final key in ['f2b3-header', 'f2b3-summary', 'f2b3-slide'])
      key: () {
        final rect = tester.getRect(find.byKey(ValueKey(key)));
        return {
          'x': rect.left,
          'y': rect.top,
          'width': rect.width,
          'height': rect.height,
        };
      }(),
  };

  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(rootKey),
  );
  final image = await boundary.toImage(pixelRatio: dpr);
  final byteData = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  if (byteData == null) {
    throw StateError('PNG encoding returned no data for f2b3 finalize');
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
      'sample': 'f2b3-finalize-level1',
      'logicalSize': {'width': 390, 'height': height},
      'devicePixelRatio': dpr,
      'boxes': boxes,
    }),
    flush: true,
  );
  File('${outDir.path}/strings.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'sample': 'f2b3-finalize-level1',
      'locale': 'en',
      'direction': 'ltr',
      'theme': 'light',
      'textScale': 1,
      'strings': strings,
    }),
    flush: true,
  );
}
