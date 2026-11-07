import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/f3a_assign_fixture.dart';

/// F3-A Step 4 screen 4 — Level 1 fidelity capture for Figma screen 4
/// "Assign Technician" (node `1:821`, 1280 x 1120).
///
/// Renders the test-only [F3aAssignFixture] (exact Figma structure from the
/// shared kits; never the production assign dialog) at 1280 logical px,
/// DPR 2, with real shadows (`enableFidelityShadows`, restored before the
/// test body ends) inside a [RepaintBoundary], then writes `render.png`,
/// `geometry.json` (key-box actuals for the `f3a` fixture) and `strings.json`
/// under `docs/ui/figma/fidelity/f3a/assign-technician/`.
///
/// The modal carries no rasters (0 in the export manifest; avatars are icon
/// placeholders), so nothing is decoded here. Figma icon SVGs are read from
/// the export by absolute path. Nothing is added to any pubspec and `lib/`
/// is untouched, so the admin `source_scan_test.dart` stays green.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadF3AFonts();
  });

  testWidgets('capture f3a assign level1', (tester) async {
    final root = _repoRoot();
    final outDir = Directory(
      '${root.path}/docs/ui/figma/fidelity/f3a/assign-technician',
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

/// Mirrors the technician `loadF2AFonts`: loads the bundled design-system
/// fonts test-only (no pubspec change). Workshop icon SVGs are read from the
/// Figma export by the render step, not from package assets.
Future<void> _loadF3AFonts() async {
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
    'docs/ui/figma-export/Workshop_admin_figma/screens/04_4._Assign_Technician';

const _svgFiles = <String, String>{
  'bg1': 'assets/svg/Icon-1_846.svg',
  'bg2': 'assets/svg/Icon-1_863.svg',
  'bg3': 'assets/svg/Icon-1_880.svg',
  'logo': 'assets/svg/Icon-1_916.svg',
  'nav1': 'assets/svg/Icon-1_920.svg',
  'nav2': 'assets/svg/Icon-1_923.svg',
  'nav3': 'assets/svg/Icon-1_926.svg',
  'help': 'assets/svg/Icon-1_929.svg',
  'search': 'assets/svg/Icon-1_898.svg',
  'userAv': 'assets/svg/Icon-1_910.svg',
  'close': 'assets/svg/Icon-1_949.svg',
  'veh': 'assets/svg/Icon-1_955.svg',
  'av1': 'assets/svg/Icon-1_970.svg',
  'check': 'assets/svg/Icon-1_982.svg',
  'av2': 'assets/svg/Icon-1_988.svg',
  'av3': 'assets/svg/Icon-1_1005.svg',
  'arrow': 'assets/svg/Icon-1_1025.svg',
};

Future<void> _render(WidgetTester tester, Directory outDir) async {
  if (debugDisableShadows) {
    throw StateError(
      'debugDisableShadows is true during fidelity capture; shadows would be '
      'solid blocks.',
    );
  }
  const dpr = 2.0;
  const width = F3aAssignFixture.width;
  const height = F3aAssignFixture.height;
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

  const rootKey = ValueKey('f3a-capture-root');

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
              child: F3aAssignFixture(svgs: svgs),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  final boxFinders = <String, Finder>{
    'modal': find.byKey(const ValueKey('f3a-modal')),
    'tech-card-1': find.byKey(const ValueKey('f3a-tech-1')),
    'confirm': find.byKey(const ValueKey('f3a-confirm')),
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
    throw StateError('PNG encoding returned no data for f3a assign');
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
      'sample': 'assign-level1',
      'logicalSize': {'width': width, 'height': height},
      'devicePixelRatio': dpr,
      'boxes': boxes,
    }),
    flush: true,
  );
  File('${outDir.path}/strings.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'sample': 'assign-level1',
      'locale': 'en',
      'direction': 'ltr',
      'theme': 'light',
      'textScale': 1,
      'strings': strings,
    }),
    flush: true,
  );
}
