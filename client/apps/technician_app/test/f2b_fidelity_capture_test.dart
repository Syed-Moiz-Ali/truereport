import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technician_app/src/shared/technician_kit.dart';

import 'support/f2a_fidelity_harness.dart';
import 'support/f2a_test_fonts.dart';
import 'support/f2a_test_images.dart';
import 'support/f2b_views.dart';
import 'support/fidelity_output.dart';

/// F2-B fidelity capture (mirrors `f2a_fidelity_capture_test.dart`).
///
/// Renders the six F2-B screens at 390 logical px, DPR 2, with real shadows
/// (`enableFidelityShadows`, restored before the test body ends) inside a
/// [RepaintBoundary], then writes `render.png`, `geometry.json` (key-box
/// actuals for the `f2b` fixtures) and `strings.json` under
/// `docs/ui/figma/fidelity/f2b/<screen>/<fixture>/`.
///
/// Both fixtures render the production widgets; the figma-text variant only
/// swaps in the test-only [f2bFigmaLocalizationsDelegates] via [f2bHost] —
/// there is no figmaText switch in `lib/`.
///
/// F2-B needs no Figma raster photos: the product slots deliberately render a
/// neutral silhouette / initials discs (see `docs/ui/figma/f2b-slot-sheet.md`),
/// so there is nothing to decode here. `f2b_release_guard_test.dart` locks
/// that property (no figma-export reference in `lib/`, pubspecs or the web
/// asset bundle).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadF2AFonts();
  });

  for (final id in f2bScreenIds) {
    for (final variant in _variants) {
      testWidgets('capture $id ${variant.id}', (tester) async {
        final root = repoRoot();
        final outDir = fidelityOutputDir(
          root,
          'figma/fidelity/f2b/$id/${variant.id}',
        );
        final previous = enableFidelityShadows();
        try {
          await _render(tester, id, variant, outDir);
        } finally {
          restoreFidelityShadows(previous);
        }
      });
    }
  }
}

class _Variant {
  const _Variant({required this.id});
  final String id;

  bool get figma => id == 'figma-text';
}

const _variants = <_Variant>[
  _Variant(id: 'figma-text'),
  _Variant(id: 'product-copy'),
];

/// Product-anchored key nodes recorded into `geometry.json` `boxes`.
///
/// Keys match the `keyBoxes` entries of the `fidelity/fixtures/f2b/*.json`
/// fixtures; expected rects are the Figma-slot-anchored values also asserted
/// in `f2b_geometry_test.dart`. Finders are type-based so both fixtures
/// resolve the same nodes (copy differs per fixture, layout does not).
Map<String, Finder> _boxFinders(String id) {
  switch (id) {
    case 'defect-detail':
      return {
        'segmented': find.byType(F2bSegmented).first,
        'save': find.byType(FxButton).last,
      };
    case 'photo-annotation':
      return {
        'card': find.byKey(const ValueKey('photo-annotation-card')),
        'tools': find.byKey(const ValueKey('photo-annotation-tools')),
        'draw': find.byKey(const ValueKey('photo-annotation-draw')),
        'save': find.byType(FxButton),
      };
    case 'dense-mechanical':
      return {
        'header': find.byType(FxHeader),
        'card': find.byType(FxCard).first,
        'cta': find.byType(FxButton).last,
      };
    case 'tire-condition':
      return {
        'header': find.byType(FxHeader),
        'chassisCard': find.byKey(const ValueKey('chassis-card')),
        'detailCard': find.byKey(const ValueKey('detail-card')),
        'saveButton': find.byKey(const ValueKey('save-button')),
      };
    case 'final-review':
      return {
        'header': find.byKey(const ValueKey('header')),
        'banner': find.byKey(const ValueKey('banner')),
        'continue': find.byKey(const ValueKey('continue')),
      };
    case 'finalize':
      return {
        'header': find.byKey(const ValueKey('header')),
        'summary': find.byKey(const ValueKey('summary')),
        'slide': find.byKey(const ValueKey('slide')),
      };
    case 'offline-sync':
      return {
        'header': find.byKey(const ValueKey('header')),
        'queue': find.byKey(const ValueKey('queue')),
        'retry': find.byKey(const ValueKey('retry')),
      };
    case 'success':
      return {
        'delivery': find.byKey(const ValueKey('delivery')),
        'cta': find.byKey(const ValueKey('cta')),
      };
    default:
      throw ArgumentError('Unknown F2-B screen: $id');
  }
}

Future<void> _render(
  WidgetTester tester,
  String id,
  _Variant variant,
  Directory outDir,
) async {
  assertFidelityShadows();
  const dpr = 2.0;
  final height = f2bHeights[id]!;
  final root = repoRoot();
  ui.Image? wireframe;
  ui.Image? evidence;
  ui.Image? avatar;
  ui.Image? vehicle;
  if (id == 'defect-detail' && variant.figma) {
    final wireframePath =
        '${root.path}/docs/ui/figma-export/technision_figma/screens/09_9._Defect_Detail_&_Evidence/assets/composed/png/Blur-1_8036@2x.png';
    final evidencePath =
        '${root.path}/docs/ui/figma-export/technision_figma/screens/09_9._Defect_Detail_&_Evidence/assets/images/rendered_png/AB6AXuClXyUAQtLTkS7GotDu0YwpZvc-mLvq2FI2ng933ExC4Uq4qbafLdUeOK0C434imw-CoHDYH2ZRbZY5uYmsPeWxH5U4_PyY-1_8104@2x.png';
    wireframe = await tester.runAsync(() => loadFigmaTestImage(wireframePath));
    evidence = await tester.runAsync(() => loadFigmaTestImage(evidencePath));
  }
  if (id == 'photo-annotation' && variant.figma) {
    final photoPath =
        '${root.path}/docs/ui/figma-export/technision_figma/screens/10_10._Photo_Annotation_&_Markup/assets/images/rendered_png/AB6AXuD3XXJzF6MEUCcBeU_H4M_jmvT2FUGx-Ol0A3FvS-e95O1kqrVyGqFqUlheLIpPRAcDv-D5elTQrPUpnkI1q0U1nrldpvf8-1_8151@2x.png';
    evidence = await tester.runAsync(() => loadFigmaTestImage(photoPath));
  }
  if (id == 'finalize' && variant.figma) {
    final avatarPath =
        '${root.path}/docs/ui/figma-export/technision_figma/screens/15_14._Finalize_&_Approval_(Swipe)/assets/images/rendered_png/AB6AXuA6dGDzYZ-RLaWksinhI7SgABKO8bMsu5g5yMUtDsLyRYHhXDRYb_zOrA_A_Ex8Th0NNXJfCUHR_XSUdAmTsbmZrwy0Ys4p-1_8859@2x.png';
    final vehiclePath =
        '${root.path}/docs/ui/figma-export/technision_figma/screens/15_14._Finalize_&_Approval_(Swipe)/assets/images/rendered_png/AB6AXuBC7qJfbrATy1AUuOCrOWmAPfTCHgkIEZHXcXCXZscxIWzB0SWT4WLRS-TpwOQqIHAC2adapAlluFOQv7DkK1cMcwPTKGyh-1_8874@2x.png';
    avatar = await tester.runAsync(() => loadFigmaTestImage(avatarPath));
    vehicle = await tester.runAsync(() => loadFigmaTestImage(vehiclePath));
  }

  tester.view.physicalSize = Size(390 * dpr, height * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  const rootKey = ValueKey('f2b-capture-root');

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
              child: f2bScreen(
                id,
                figma: variant.figma,
                wireframeImage: wireframe,
                evidenceImage: evidence,
                vehicleImage: vehicle,
                avatarImage: avatar,
              ),
            ),
          ),
        ),
      ),
      locale: const Locale('en'),
      theme: AppTheme.light,
      figmaStrings: variant.figma,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  final boxes = <String, dynamic>{};
  for (final entry in _boxFinders(id).entries) {
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
    throw StateError('PNG encoding returned no data for $id');
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
      'sample': '$id-${variant.id}',
      'logicalSize': {'width': 390, 'height': height},
      'devicePixelRatio': dpr,
      'boxes': boxes,
    }),
    flush: true,
  );
  File('${outDir.path}/strings.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'sample': '$id-${variant.id}',
      'locale': 'en',
      'direction': 'ltr',
      'theme': 'light',
      'textScale': 1,
      'strings': strings,
    }),
    flush: true,
  );
}
