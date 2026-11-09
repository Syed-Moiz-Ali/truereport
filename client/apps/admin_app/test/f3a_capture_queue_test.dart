import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/f3a_queue_fixture.dart';
import 'support/fidelity_output.dart';

/// F3-A Step 4 screen 2 — Level 1 fidelity capture for Figma screen 2
/// "Live Job Queue" (node `1:529`, 1280 x 1125).
///
/// Renders the test-only [F3aQueueFixture] (exact Figma structure from the
/// shared kits; never the production `JobsTab`) at 1280 logical px, DPR 2,
/// with real shadows (`enableFidelityShadows`, restored before the test body
/// ends) inside a [RepaintBoundary], then writes `render.png`,
/// `geometry.json` (key-box actuals for the `f3a` fixture) and `strings.json`
/// under `docs/ui/figma/fidelity/f3a/live-job-queue/`.
///
/// Sample images are decoded from the Figma export rasters by absolute path
/// (same pattern as `loadFigmaTestImage` in the technician F2-A capture) and
/// Figma icon SVGs are read from the export by absolute path. Nothing is
/// added to any pubspec and `lib/` is untouched, so the admin
/// `source_scan_test.dart` stays green.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadF3AFonts();
  });

  testWidgets('capture f3a queue level1', (tester) async {
    final root = _repoRoot();
    final outDir =
        fidelityOutputDir(root, 'figma/fidelity/f3a/live-job-queue');
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

/// Same pattern as the technician `loadFigmaTestImage`: decodes a
/// Figma-exported raster by absolute path. The file lives under
/// docs/ui/figma-export and is never listed in a pubspec asset section.
Future<ui.Image> _loadFigmaTestImage(String absolutePath) async {
  final bytes = File(absolutePath).readAsBytesSync();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

const _screenDir =
    'docs/ui/figma-export/Workshop_admin_figma/screens/03_2._Live_Job_Queue';

const _svgFiles = <String, String>{
  'plus': 'assets/svg/Icon-1_559.svg',
  'sort': 'assets/svg/Icon-1_576.svg',
  'filter': 'assets/svg/Icon-1_581.svg',
  'person1': 'assets/svg/Icon-1_605.svg',
  'person3': 'assets/svg/Icon-1_696.svg',
  'person4': 'assets/svg/Icon-1_742.svg',
  'chev1': 'assets/svg/Icon-1_628.svg',
  'chev2': 'assets/svg/Icon-1_673.svg',
  'chev3': 'assets/svg/Icon-1_719.svg',
  'chev4': 'assets/svg/Icon-1_765.svg',
  'bldg': 'assets/svg/Icon-1_651.svg',
  'clock': 'assets/svg/Icon-1_759.svg',
  'search': 'assets/svg/Icon-1_789.svg',
  'avatarUser': 'assets/svg/Icon-1_801.svg',
  'logo': 'assets/svg/Icon-1_807.svg',
  'dash': 'assets/svg/Icon-1_811.svg',
  'jobs': 'assets/svg/Icon-1_814.svg',
  'gear': 'assets/svg/Icon-1_817.svg',
  'help': 'assets/svg/Icon-1_820.svg',
};

const _imageFiles = <String, String>{
  'v1':
      'assets/images/rendered_png/AB6AXuC8mLfOdkQ3Vj0JFZs7u_UqIQkAxTxKcCePY4AM5bWdIa7QKZcXU-MjUtn8OrsAjaBfOS51mPsNlUoIQ5SgyCXNyjyO1s1Q-1_587@2x.png',
  'v2':
      'assets/images/rendered_png/AB6AXuBlryfqU0r1mBnXXtNippJLhmxmRMRI5xl8XDWiWFqiLvKOFJIqn6YGBdKn8vtgpPn8KfFnlAf-qJJBUfeaZ-u5GLLoKzVQ-1_633@2x.png',
  'v3':
      'assets/images/rendered_png/AB6AXuBHBHIYuqNObSegsMOLgiX9bnHJTOIWci4WiXADl4G329FCBccHwzpNOvoQQIs-LtShsYZPRwhhqJGM85aQEGyXA69CRRNT-1_678@2x.png',
  'v4':
      'assets/images/rendered_png/AB6AXuAEDEKBmfqB4IQKsX5vzFenIirwk75Fy0oudNpsMCP02--so49od6T9qrePkqBDEJYzmkNMN-Ge8sqZzGJiXSsIHM53YyuG-1_724@2x.png',
};

Future<void> _render(WidgetTester tester, Directory outDir) async {
  if (debugDisableShadows) {
    throw StateError(
      'debugDisableShadows is true during fidelity capture; shadows would be '
      'solid blocks.',
    );
  }
  const dpr = 2.0;
  const width = F3aQueueFixture.width;
  const height = F3aQueueFixture.height;
  final root = _repoRoot();

  final svgs = <String, String>{};
  for (final entry in _svgFiles.entries) {
    svgs[entry.key] =
        File('${root.path}/$_screenDir/${entry.value}').readAsStringSync();
  }
  final images = <String, ui.Image>{};
  for (final entry in _imageFiles.entries) {
    final image = await tester.runAsync(
      () => _loadFigmaTestImage('${root.path}/$_screenDir/${entry.value}'),
    );
    images[entry.key] = image!;
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
              child: F3aQueueFixture(images: images, svgs: svgs),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  final boxFinders = <String, Finder>{
    'queue-card-1': find.byKey(const ValueKey('f3a-card-1')),
    'queue-filters': find.byKey(const ValueKey('f3a-filters')),
    'queue-new-job': find.byKey(const ValueKey('f3a-new-job')),
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
    throw StateError('PNG encoding returned no data for f3a queue');
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
      'sample': 'queue-level1',
      'logicalSize': {'width': width, 'height': height},
      'devicePixelRatio': dpr,
      'boxes': boxes,
    }),
    flush: true,
  );
  File('${outDir.path}/strings.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'sample': 'queue-level1',
      'locale': 'en',
      'direction': 'ltr',
      'theme': 'light',
      'textScale': 1,
      'strings': strings,
    }),
    flush: true,
  );
}
