import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/f3b_templates_fixture.dart';

/// F3-B Step 3 screen 7 — Level 1 fidelity capture for Figma screen 7
/// "Workshop Template List" (node `1:1307`, 1280 x 1586).
///
/// Renders the test-only [F3bTemplatesFixture] (exact Figma structure from the
/// shared kits; never the product `TemplatesTab`) at 1280 logical px,
/// DPR 2, with real shadows (`enableFidelityShadows`, restored before the test
/// body ends) inside a [RepaintBoundary], then writes `render.png`,
/// `geometry.json` (key-box actuals for the `f3b` fixture) and `strings.json`
/// under `docs/ui/figma/fidelity/f3b/template-list/`.
///
/// Figma icon SVGs are read from the export by absolute path. Nothing is
/// added to any pubspec and `lib/` is untouched, so the admin
/// `source_scan_test.dart` stays green.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadF3BFonts();
  });

  testWidgets('capture f3b templates level1', (tester) async {
    final root = _repoRoot();
    final outDir = Directory(
      '${root.path}/docs/ui/figma/fidelity/f3b/template-list',
    );
    final previous = _enableFidelityShadows();
    try {
      await _render(tester, outDir);
    } finally {
      _restoreFidelityShadows(previous);
    }
  });
}

bool _enableFidelityShadows() {
  final previous = debugDisableShadows;
  debugDisableShadows = false;
  if (debugDisableShadows) {
    throw StateError('Fidelity capture must run with shadows enabled.');
  }
  return previous;
}

void _restoreFidelityShadows(bool previous) {
  debugDisableShadows = previous;
}

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

/// Mirrors the F3-A `loadF3AFonts`: loads the bundled design-system
/// fonts test-only (no pubspec change). Workshop icon SVGs are read from the
/// Figma export by the render step, not from package assets.
Future<void> _loadF3BFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final root = _repoRoot();
  final fontDir = Directory(
    '${root.path}/client/packages/design_system/assets/fonts',
  );
  final families = <String, FontLoader>{};
  if (fontDir.existsSync()) {
    await for (final entity in fontDir.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (!name.endsWith('.ttf') && !name.endsWith('.otf')) continue;
      final family = _familyFor(name);
      if (family == null) continue;
      final bytes = await entity.readAsBytes();
      final loader = families.putIfAbsent(family, () => FontLoader(family));
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
  }
  for (final entry in families.entries) {
    await entry.value.load();
  }
  final materialCandidates = <String>[
    if (Platform.environment['FLUTTER_ROOT'] != null)
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ];
  for (final candidate in materialCandidates) {
    final file = File(candidate);
    if (!file.existsSync()) continue;
    final bytes = await file.readAsBytes();
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
    break;
  }
}

String? _familyFor(String fileName) {
  if (fileName.startsWith('PlusJakartaSans')) return TrFonts.latin;
  if (fileName.startsWith('NotoSansArabic')) return TrFonts.arabicDefault;
  if (fileName.startsWith('IBMPlexSansArabic')) {
    return TrFonts.arabicAlternative;
  }
  if (fileName.startsWith('NotoSansSC')) return TrFonts.cjkFallback;
  if (fileName.startsWith('NotoSans-')) return TrFonts.cyrillicFallback;
  return null;
}

const _screenDir =
    'docs/ui/figma-export/Workshop_admin_figma/screens/06_7._Workshop_Template_List';

const _svgFiles = <String, String>{
  'plus': 'assets/svg/Icon-1_1329.svg',
  'm1': 'assets/svg/Icon-1_1339.svg',
  'm2': 'assets/svg/Icon-1_1350.svg',
  'm3': 'assets/svg/Icon-1_1361.svg',
  'm4': 'assets/svg/Icon-1_1372.svg',
  'grid': 'assets/svg/Icon-1_1394.svg',
  'list': 'assets/svg/Icon-1_1397.svg',
  'c1': 'assets/svg/Icon-1_1404.svg',
  'r1': 'assets/svg/Icon-1_1416.svg',
  'u1': 'assets/svg/Icon-1_1425.svg',
  'e1': 'assets/svg/Icon-1_1430.svg',
  'c2': 'assets/svg/Icon-1_1438.svg',
  'r2': 'assets/svg/Icon-1_1450.svg',
  'u2': 'assets/svg/Icon-1_1459.svg',
  'e2': 'assets/svg/Icon-1_1464.svg',
  'c3': 'assets/svg/Icon-1_1472.svg',
  'r3': 'assets/svg/Icon-1_1484.svg',
  'u3': 'assets/svg/Icon-1_1493.svg',
  'e3': 'assets/svg/Icon-1_1498.svg',
  'c4': 'assets/svg/Icon-1_1506.svg',
  'r4': 'assets/svg/Icon-1_1518.svg',
  'u4': 'assets/svg/Icon-1_1527.svg',
  'e4': 'assets/svg/Icon-1_1532.svg',
  'c5': 'assets/svg/Icon-1_1540.svg',
  'r5': 'assets/svg/Icon-1_1552.svg',
  'u5': 'assets/svg/Icon-1_1561.svg',
  'e5': 'assets/svg/Icon-1_1566.svg',
  'cplus': 'assets/svg/Icon-1_1573.svg',
  'carrow': 'assets/svg/Icon-1_1584.svg',
  'shield': 'assets/svg/Icon-1_1590.svg',
  'search': 'assets/svg/Icon-1_1610.svg',
  'avatar': 'assets/svg/Icon-1_1622.svg',
  'logo': 'assets/svg/Icon-1_1628.svg',
  'dash': 'assets/svg/Icon-1_1632.svg',
  'jobs': 'assets/svg/Icon-1_1635.svg',
  'gear': 'assets/svg/Icon-1_1638.svg',
  'help': 'assets/svg/Icon-1_1641.svg',
};

Future<void> _render(WidgetTester tester, Directory outDir) async {
  if (debugDisableShadows) {
    throw StateError(
      'debugDisableShadows is true during fidelity capture; shadows would be '
      'solid blocks.',
    );
  }
  const dpr = 2.0;
  const width = F3bTemplatesFixture.width;
  const height = F3bTemplatesFixture.height;
  final root = _repoRoot();

  final svgs = <String, String>{};
  for (final entry in _svgFiles.entries) {
    svgs[entry.key] =
        File('${root.path}/$_screenDir/${entry.value}').readAsStringSync();
  }

  tester.view.physicalSize = const Size(width * dpr, height * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  const rootKey = ValueKey('f3b-capture-root');

  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(
        size: Size(width, height),
        devicePixelRatio: dpr,
        textScaler: TextScaler.noScaling,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: width,
          height: height,
          child: ColoredBox(
            color: Fx.white,
            child: RepaintBoundary(
              key: rootKey,
              child: F3bTemplatesFixture(svgs: svgs),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  final boxFinders = <String, Finder>{
    'card-1': find.byKey(const ValueKey('f3b-card-1')),
    'metric-1': find.byKey(const ValueKey('f3b-metric-1')),
    'add': find.byKey(const ValueKey('f3b-add')),
    'banner': find.byKey(const ValueKey('f3b-banner')),
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
    throw StateError('PNG encoding returned no data for f3b templates');
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
      'sample': 'templates-level1',
      'logicalSize': {'width': width, 'height': height},
      'devicePixelRatio': dpr,
      'boxes': boxes,
    }),
    flush: true,
  );
  File('${outDir.path}/strings.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'sample': 'templates-level1',
      'locale': 'en',
      'direction': 'ltr',
      'theme': 'light',
      'textScale': 1,
      'strings': strings,
    }),
    flush: true,
  );
}
