import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

import 'support/f2a_fidelity_harness.dart';
import 'support/f2a_test_images.dart';
import 'support/f2a_test_fonts.dart';
import 'support/f2a_views.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadF2AFonts();
  });

  for (final id in f2aScreenIds) {
    for (final variant in _variants) {
      testWidgets('capture $id ${variant.id}', (tester) async {
        final root = repoRoot();
        final outDir = Directory(
          '${root.path}/docs/ui/figma/fidelity/f2a1/$id/${variant.id}',
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

const _heights = <String, double>{
  'login': 858,
  'assigned-jobs': 1002,
  'empty-state': 883.75,
  'job-intake': 1128,
  'consent': 972,
  'equipment': 910,
  'inspection-hub': 1130,
};

Future<void> _render(
  WidgetTester tester,
  String id,
  _Variant variant,
  Directory outDir,
) async {
  assertFidelityShadows();
  const dpr = 2.0;
  final height = _heights[id]!;
  final root = repoRoot();
  final avatarPath =
      '${root.path}/docs/ui/figma-export/technision_figma/screens/02_2._Assigned_Jobs_Dashboard/assets/images/rendered_png/Profile-1_7264@2x.png';
  final intakeVehiclePath =
      '${root.path}/docs/ui/figma-export/technision_figma/screens/04_4._Job_Details_&_Intake/assets/images/rendered_png/AB6AXuB71CDXRlHtEOfV1SK653RSetUs96bOuWnsLkPx1a4loquzjeVaeOAO17e7cEbDln-JR38YAvJ7VdhdsZFFVEGGkfNOOKzu-1_7503@2x.png';
  final hubVehiclePath =
      '${root.path}/docs/ui/figma-export/technision_figma/screens/07_7._Main_Inspection_Hub/assets/images/rendered_png/AB6AXuB6_Pkv61jikWQ0s0IyLmWBs8UlV0z3xFmD3rVquFuXbT51TM8fZc4gbcvtwfCxcE9mMeECTG_MK7LApabA9-_p_e478eNX-1_7757@2x.png';
  var avatarImage = variant.figma
      ? await tester.runAsync(() => loadFigmaTestImage(avatarPath))
      : null;
  var vehicleImage = variant.figma
      ? await tester.runAsync(
          () => loadFigmaTestImage(
            id == 'job-intake' ? intakeVehiclePath : hubVehiclePath,
          ),
        )
      : null;
  if (id != 'job-intake' && id != 'inspection-hub') {
    vehicleImage = null;
  }
  tester.view.physicalSize = Size(390 * dpr, height * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  const rootKey = ValueKey('f2a-capture-root');
  final theme = AppTheme.light;

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(
            size: Size(390, height),
            devicePixelRatio: dpr,
            textScaler: TextScaler.noScaling,
          ),
          child: RepaintBoundary(
            key: rootKey,
            child: SizedBox(
              width: 390,
              height: height,
              child: ColoredBox(
                color: theme.colorScheme.surface,
                child: Material(
                  type: MaterialType.transparency,
                  child: Builder(
                    builder: (context) => f2aScreen(
                      id,
                      figma: variant.figma,
                      avatarImage: avatarImage,
                      vehicleImage: vehicleImage,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

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
  File('${outDir.path}/render.png').writeAsBytesSync(
    byteData.buffer.asUint8List(),
  );

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
      'boxes': <String, dynamic>{},
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
