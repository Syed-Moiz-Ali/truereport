import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:admin_app/src/admin_api.dart';
import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/pages/templates_tab.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

import 'support/fidelity_output.dart';

/// F3-B Level 2 screen 7 — product capture for Figma screen 7
/// "Workshop Template List" (node `1:1307`, 1280 x 1586).
///
/// Pumps the REAL product `TemplatesTab`
/// (`client/apps/admin_app/lib/src/pages/templates_tab.dart`) — never the
/// Level 1 exact-structure fixture — at 1280 logical px wide x the Figma
/// frame height (1586), DPR 2, top-of-scroll, with real shadows
/// (`debugDisableShadows = false`, restored before the test body ends)
/// inside a [RepaintBoundary], then writes `render.png`, `geometry.json`
/// (product-anchored boxes, informational — the Level 2 fixture declares no
/// key boxes) and `strings.json` (the actually-rendered product copy) under
/// `docs/ui/figma/fidelity/f3b/template-list-product/`.
///
/// Fake data mirrors `test/template_list_test.dart` (three templates with
/// the real statuses and integer versions; 110 + 24 + 45 = 179 checkpoints)
/// with a minimal inline fake — no private helpers are imported.
/// Nothing is added to any pubspec and `lib/` is untouched, so the admin
/// `source_scan_test.dart` stays green.
class _TemplatesProductFakeApi implements AdminApi {
  static const _templates = <TemplateSummary>[
    TemplateSummary(
      id: 't-1',
      name: 'Full inspection',
      serviceType: 'FULL',
      vehicleType: 'CAR',
      status: 'PUBLISHED',
      currentVersion: 2,
      itemCount: 110,
    ),
    TemplateSummary(
      id: 't-2',
      name: 'Quick oil service',
      serviceType: 'QUICK',
      vehicleType: 'CAR',
      status: 'DRAFT',
      currentVersion: 1,
      itemCount: 24,
    ),
    TemplateSummary(
      id: 't-3',
      name: 'Highway check',
      serviceType: 'FULL',
      vehicleType: 'TRUCK',
      status: 'RETIRED',
      currentVersion: 3,
      itemCount: 45,
    ),
  ];

  @override
  Future<List<TemplateSummary>> templates() async => _templates;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadF3BFonts();
  });

  testWidgets('capture f3b templates product', (tester) async {
    final root = _repoRoot();
    final outDir =
        fidelityOutputDir(root, 'figma/fidelity/f3b/template-list-product');
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

Future<void> _render(WidgetTester tester, Directory outDir) async {
  if (debugDisableShadows) {
    throw StateError(
      'debugDisableShadows is true during fidelity capture; shadows would be '
      'solid blocks.',
    );
  }
  const dpr = 2.0;
  const width = 1280.0;
  const height = 1586.0;

  tester.view.physicalSize = const Size(width * dpr, height * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  const rootKey = ValueKey('f3b-capture-root');

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adminApiProvider.overrideWithValue(_TemplatesProductFakeApi()),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.noScaling),
          child: child ?? const SizedBox.shrink(),
        ),
        home: const Scaffold(
          body: SizedBox(
            width: width,
            height: height,
            child: RepaintBoundary(
              key: rootKey,
              child: TemplatesTab(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);

  final boxFinders = <String, Finder>{
    'header': find.byType(WorkshopHeader).first,
    'metric': find.byType(WorkshopMetric).first,
    'card-1': find.byKey(const Key('template-t-1')),
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
    throw StateError('PNG encoding returned no data for f3b templates product');
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
      'sample': 'templates-level2',
      'logicalSize': {'width': width, 'height': height},
      'devicePixelRatio': dpr,
      'boxes': boxes,
    }),
    flush: true,
  );
  File('${outDir.path}/strings.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'sample': 'templates-level2',
      'locale': 'en',
      'direction': 'ltr',
      'theme': 'light',
      'textScale': 1,
      'strings': strings,
    }),
    flush: true,
  );
}
