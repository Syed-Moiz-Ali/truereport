import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fidelity_harness.dart';

/// Fidelity capture for the Figma-exact component variants.
///
/// Each sample renders only the Figma node bounding box (button 342 x 56,
/// delivery card 350 x 145, result selector 350 x 70) at DPR 2. The harness in
/// `tools/figma_fidelity` measures the render against the `@2x` export crop.
/// These fixtures are test-only and guarded by living under `test/`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadBundledFonts();
  });

  for (final sample in _samples) {
    testWidgets('capture ${sample.id}', (tester) async {
      final root = _repoRoot();
      final outDir = Directory(
        '${root.path}/docs/ui/figma/fidelity/component-samples/${sample.id}',
      );
      final previous = enableFidelityShadows();
      try {
        await _render(tester, sample, outDir);
      } finally {
        restoreFidelityShadows(previous);
      }
    });
  }
}

class _Sample {
  const _Sample({
    required this.id,
    required this.width,
    required this.height,
    required this.keyBoxKey,
  });

  final String id;
  final double width;
  final double height;
  final String keyBoxKey;
}

const _samples = <_Sample>[
  _Sample(
    id: 'primary-button-en-light-1x',
    width: 342,
    height: 56,
    keyBoxKey: 'primary-button',
  ),
  _Sample(
    id: 'delivery-status-card-en-light-1x',
    width: 350,
    height: 145,
    keyBoxKey: 'delivery-status-card',
  ),
  _Sample(
    id: 'inspection-result-selector-en-light-1x',
    width: 350,
    height: 70,
    keyBoxKey: 'inspection-result-selector',
  ),
];

Future<void> _render(
  WidgetTester tester,
  _Sample sample,
  Directory outDir,
) async {
  assertFidelityShadows();
  const dpr = 2.0;
  tester.view.physicalSize = Size(sample.width * dpr, sample.height * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  const rootKey = ValueKey('sample-root');
  final theme = AppTheme.light;

  debugPrint('[fidelity] pumpWidget ${sample.id}');
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: const Locale('en'),
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(
            size: Size(sample.width, sample.height),
            devicePixelRatio: dpr,
            textScaler: TextScaler.noScaling,
          ),
          child: RepaintBoundary(
            key: rootKey,
            child: SizedBox(
              width: sample.width,
              height: sample.height,
              child: ColoredBox(
                color: theme.colorScheme.surface,
                child: Material(
                  type: MaterialType.transparency,
                  child: Builder(
                    builder: (context) => _sampleWidget(context, sample.id),
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
  debugPrint('[fidelity] pumped ${sample.id}');

  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(rootKey),
  );
  final image = await boundary.toImage(pixelRatio: dpr);
  final byteData = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  if (byteData == null) {
    throw StateError('PNG encoding returned no data for ${sample.id}');
  }
  outDir.createSync(recursive: true);
  File('${outDir.path}/render.png').writeAsBytesSync(
    byteData.buffer.asUint8List(),
  );

  final rootRect = tester.getRect(find.byKey(rootKey));
  final finder = find.byKey(ValueKey(sample.keyBoxKey));
  if (finder.evaluate().isEmpty) {
    throw StateError('Missing key box ${sample.keyBoxKey} for ${sample.id}');
  }
  final rect = tester.getRect(finder.first);
  final geometry = <String, Map<String, double>>{
    sample.keyBoxKey: {
      'x': _round(rect.left - rootRect.left),
      'y': _round(rect.top - rootRect.top),
      'width': _round(rect.width),
      'height': _round(rect.height),
    },
  };
  final strings = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  File('${outDir.path}/geometry.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'sample': sample.id,
      'logicalSize': {'width': sample.width, 'height': sample.height},
      'devicePixelRatio': dpr,
      'boxes': geometry,
    }),
    flush: true,
  );
  File('${outDir.path}/strings.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'sample': sample.id,
      'locale': 'en',
      'direction': 'ltr',
      'theme': 'light',
      'textScale': 1,
      'strings': strings,
    }),
    flush: true,
  );
  debugPrint('[fidelity] wrote ${sample.id}');
}

Widget _sampleWidget(BuildContext context, String id) {
  switch (id) {
    case 'primary-button-en-light-1x':
      return Align(
        alignment: Alignment.topLeft,
        child: FigmaPrimaryButton(
          key: const ValueKey('primary-button'),
          label: 'Sign In',
          onPressed: () {},
        ),
      );
    case 'delivery-status-card-en-light-1x':
      return Align(
        alignment: Alignment.topLeft,
        child: FigmaDeliveryStatusCard(
          key: const ValueKey('delivery-status-card'),
          semanticLabel: 'Delivery status',
          items: const [
            FigmaDeliveryItem(
              icon: AppIconName.deliveryReportLink,
              label: 'WhatsApp',
              status: 'Sent',
            ),
            FigmaDeliveryItem(
              icon: AppIconName.deliveryWorkshopCopy,
              label: 'Fleet Portal',
              status: 'Synced',
              iconWidth: 18.33,
              iconHeight: 13.33,
            ),
          ],
        ),
      );
    case 'inspection-result-selector-en-light-1x':
      return Align(
        alignment: Alignment.topLeft,
        child: FigmaThreeWaySelector<String>(
          key: const ValueKey('inspection-result-selector'),
          label: 'Inspection status',
          semanticLabel: 'INSPECTION STATUS',
          options: const [
            FigmaResultOption(value: 'pass', label: 'Pass'),
            FigmaResultOption(value: 'minor', label: 'Minor'),
            FigmaResultOption(value: 'major', label: 'Major'),
          ],
          selected: 'minor',
          onChanged: (_) {},
        ),
      );
    default:
      throw UnsupportedError('Unknown fidelity sample: $id');
  }
}

double _round(double value) => double.parse(value.toStringAsFixed(2));

Directory _repoRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 12; i += 1) {
    if (Directory('${dir.path}/docs/ui/figma').existsSync() &&
        Directory('${dir.path}/client').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'Could not find repository root from ${Directory.current.path}',
  );
}

Future<void> _loadBundledFonts() async {
  final fontDir = Directory(
    '${_repoRoot().path}/client/packages/design_system/assets/fonts',
  );
  if (!fontDir.existsSync()) {
    debugPrint('[fidelity] font directory missing: ${fontDir.path}');
    return;
  }
  final families = <String, FontLoader>{};
  var loaded = 0;
  await for (final entity in fontDir.list()) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (!name.endsWith('.ttf') && !name.endsWith('.otf')) continue;
    final family = _familyFor(name);
    if (family == null) continue;
    final bytes = await entity.readAsBytes();
    final loader = families.putIfAbsent(family, () => FontLoader(family));
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    loaded += 1;
  }
  for (final entry in families.entries) {
    await entry.value.load();
  }
  debugPrint(
    '[fidelity] loaded $loaded font file(s) across ${families.length} families',
  );
}

String? _familyFor(String fileName) {
  if (fileName.startsWith('PlusJakartaSans')) return 'Plus Jakarta Sans';
  if (fileName.startsWith('NotoSansArabic')) return 'Noto Sans Arabic';
  if (fileName.startsWith('IBMPlexSansArabic')) return 'IBM Plex Sans Arabic';
  if (fileName.startsWith('NotoSansSC')) return 'Noto Sans SC';
  if (fileName.startsWith('NotoSans-')) return 'Noto Sans';
  return null;
}
