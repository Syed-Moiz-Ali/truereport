import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/f3b_create_staff_fixture.dart';
import 'support/fidelity_output.dart';

/// F3-B Step 3 screen 6 — Level 1 fidelity capture for Figma screen 6
/// "Add Staff / Create Account" (node `1:1642`, 1280 x 1024).
///
/// Renders the test-only [F3bCreateStaffFixture] (exact Figma structure from
/// the shared kits; never the product sheet) at 1280 logical px, DPR 2, with
/// real shadows (`enableFidelityShadows`, restored before the test body ends)
/// inside a [RepaintBoundary], then writes `render.png`, `geometry.json`
/// (key-box actuals for the `f3b` fixture) and `strings.json` under
/// `docs/ui/figma/fidelity/f3b/create-staff/`.
///
/// Sample images: none in the manifest (0 rasters). Figma icon SVGs are read
/// from the export by absolute path. Nothing is added to any pubspec and
/// `lib/` is untouched, so the admin `source_scan_test.dart` stays green.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadF3BFonts();
  });

  testWidgets('capture f3b create staff level1', (tester) async {
    final root = _repoRoot();
    final outDir = fidelityOutputDir(root, 'figma/fidelity/f3b/create-staff');
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

/// Mirrors the F3-A `loadF3AFonts`: loads the bundled design-system fonts
/// test-only (no pubspec change).
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
    'docs/ui/figma-export/Workshop_admin_figma/screens/07_6._Add_Staff_-_Create_Account';

const _svgFiles = <String, String>{
  'pillDot': 'assets/svg/Icon-1_1660.svg',
  'plus': 'assets/svg/Icon-1_1665.svg',
  'm1': 'assets/svg/Icon-1_1672.svg',
  'm2': 'assets/svg/Icon-1_1680.svg',
  'm3': 'assets/svg/Icon-1_1688.svg',
  'search': 'assets/svg/Icon-1_1742.svg',
  'avatarUser': 'assets/svg/Icon-1_1754.svg',
  'logo': 'assets/svg/Icon-1_1760.svg',
  'dash': 'assets/svg/Icon-1_1764.svg',
  'jobs': 'assets/svg/Icon-1_1767.svg',
  'gear': 'assets/svg/Icon-1_1770.svg',
  'help': 'assets/svg/Icon-1_1773.svg',
  'close': 'assets/svg/Icon-1_1784.svg',
  'user': 'assets/svg/Icon-1_1800.svg',
  'mail': 'assets/svg/Icon-1_1809.svg',
  'eye': 'assets/svg/Icon-1_1819.svg',
  'roleTech': 'assets/svg/Icon-1_1827.svg',
  'roleAdmin': 'assets/svg/Icon-1_1832.svg',
  'shield': 'assets/svg/Icon-1_1865.svg',
  'ctaArrow': 'assets/svg/Icon-1_1881.svg',
};

Future<void> _render(WidgetTester tester, Directory outDir) async {
  if (debugDisableShadows) {
    throw StateError(
      'debugDisableShadows is true during fidelity capture; shadows would be '
      'solid blocks.',
    );
  }
  const dpr = 2.0;
  const width = F3bCreateStaffFixture.width;
  const height = F3bCreateStaffFixture.height;
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
              child: F3bCreateStaffFixture(svgs: svgs),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  final boxFinders = <String, Finder>{
    'sheet': find.byKey(const ValueKey('f3b-sheet')),
    'sheet-head': find.byKey(const ValueKey('f3b-sheet-head')),
    'sheet-cta': find.byKey(const ValueKey('f3b-sheet-cta')),
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
    throw StateError('PNG encoding returned no data for f3b create staff');
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
      'sample': 'create-staff-level1',
      'logicalSize': {'width': width, 'height': height},
      'devicePixelRatio': dpr,
      'boxes': boxes,
    }),
    flush: true,
  );
  File('${outDir.path}/strings.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'sample': 'create-staff-level1',
      'locale': 'en',
      'direction': 'ltr',
      'theme': 'light',
      'textScale': 1,
      'strings': strings,
    }),
    flush: true,
  );
}
