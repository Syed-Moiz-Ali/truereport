import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:admin_app/src/admin_api.dart';
import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/pages/create_technician_sheet.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

import 'support/fidelity_output.dart';

/// F3-B Level 2 screen 6 — REAL product sheet vs Figma screen 6
/// "Add Staff / Create Account" (node `1:1642`, 1280 x 1024).
///
/// Opens the REAL [CreateTechnicianSheet.showCreateTechnicianSheet] sheet
/// content over a neutral 1280-wide board at the Figma frame size
/// (1280 x 1024, DPR 2, real shadows via `enableFidelityShadows`, restored
/// before the test body ends, bundled fonts test-only) inside a
/// [RepaintBoundary], then writes `render.png`, `geometry.json` and
/// `strings.json` under
/// `docs/ui/figma/fidelity/f3b/create-staff-product/`.
///
/// The board behind the sheet is a plain neutral fill; dimming comes from
/// the product scrim itself (`WorkshopSideSheet.show` barrier). No Figma
/// text, rasters, or export paths appear here — this capture renders
/// product copy only, so the SSIM gate is EXPECTED to fail by design (slot
/// replacements per `docs/ui/figma/f3-slot-sheet.md` row 50 + All-family
/// rows) while the text/forbidden checks should pass.
///
/// Nothing is added to any pubspec and `lib/` is untouched, so the admin
/// `source_scan_test.dart` stays green.
class _CreateProductApi implements AdminApi {
  @override
  Future<List<StaffMember>> staff() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadF3BFonts();
  });

  testWidgets('capture f3b create staff level2 product', (tester) async {
    final root = _repoRoot();
    final outDir =
        fidelityOutputDir(root, 'figma/fidelity/f3b/create-staff-product');
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

/// Mirrors the Level 1 capture: loads the bundled design-system fonts
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

Future<void> _render(WidgetTester tester, Directory outDir) async {
  if (debugDisableShadows) {
    throw StateError(
      'debugDisableShadows is true during fidelity capture; shadows would be '
      'solid blocks.',
    );
  }
  const dpr = 2.0;
  const width = 1280.0;
  const height = 1024.0;

  tester.view.physicalSize = const Size(width * dpr, height * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  const rootKey = ValueKey('f3b-product-capture-root');

  // The RepaintBoundary sits OUTSIDE MaterialApp so the sheet route opened
  // by [CreateTechnicianSheet.showCreateTechnicianSheet] (a Navigator
  // overlay entry) is inside the captured pixels.
  await tester.pumpWidget(
    const SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: Color(0xFFE9E8F0),
        child: RepaintBoundary(
          key: rootKey,
          child: _CaptureApp(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('open-product-sheet')));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(find.byType(WorkshopSideSheet), findsOneWidget);

  final boxes = <String, dynamic>{};
  final sheetFinder = find.byType(WorkshopSideSheet).first;
  if (sheetFinder.evaluate().isNotEmpty) {
    final rect = tester.getRect(sheetFinder);
    boxes['sheet'] = {
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
    throw StateError(
      'PNG encoding returned no data for f3b create staff level2',
    );
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
      'sample': 'create-staff-level2',
      'logicalSize': {'width': width, 'height': height},
      'devicePixelRatio': dpr,
      'boxes': boxes,
    }),
    flush: true,
  );
  File('${outDir.path}/strings.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'sample': 'create-staff-level2',
      'locale': 'en',
      'direction': 'ltr',
      'theme': 'light',
      'textScale': 1,
      'strings': strings,
    }),
    flush: true,
  );
}

class _CaptureApp extends StatelessWidget {
  const _CaptureApp();

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [adminApiProvider.overrideWithValue(_CreateProductApi())],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          backgroundColor: const Color(0xFFE9E8F0),
          body: Center(
            child: Builder(
              builder: (sheetContext) => ElevatedButton(
                key: const Key('open-product-sheet'),
                onPressed: () =>
                    CreateTechnicianSheet.showCreateTechnicianSheet(
                      sheetContext,
                    ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
