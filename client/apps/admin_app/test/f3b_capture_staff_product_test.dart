import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:admin_app/src/admin_api.dart';
import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/pages/staff_tab.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

import 'support/fidelity_output.dart';

/// F3-B Level 2 screen 5 — product capture for Figma screen 5
/// "Workshop Staff Management" (node `1:1026`, 1280 x 1048).
///
/// Pumps the REAL product `StaffTab`
/// (`client/apps/admin_app/lib/src/pages/staff_tab.dart`) — never the
/// Level 1 exact-structure fixture — at 1280 logical px wide x the Figma
/// frame height (1048), DPR 2, top-of-scroll, with real shadows
/// (`debugDisableShadows = false`, restored before the test body ends)
/// inside a [RepaintBoundary], then writes `render.png`, `geometry.json`
/// (product-anchored boxes, informational — the Level 2 fixture declares no
/// key boxes) and `strings.json` (the actually-rendered product copy) under
/// `docs/ui/figma/fidelity/f3b/staff-management-product/`.
///
/// Fake data is realistic and role-spanning (2 TECHNICIAN + 2
/// WORKSHOP_ADMIN, one DISABLED). No session is provided, so the user chip
/// is omitted — the product only renders the signed-in account chip when a
/// session exists. Nothing is added to any pubspec and `lib/` is untouched,
/// so the admin `source_scan_test.dart` stays green.
///
/// No Figma copy is rendered here — this capture shows product copy only,
/// so the SSIM gate is EXPECTED to fail by design (slot replacements per
/// `docs/ui/figma/f3-slot-sheet.md` rows 48-49 + All-family rows) while the
/// text/forbidden checks should pass.
const _members = <StaffMember>[
  StaffMember(
    userId: 'tech-1',
    displayName: 'Technician A',
    emailMasked: 't***@test.local',
    role: 'TECHNICIAN',
    status: 'ACTIVE',
  ),
  StaffMember(
    userId: 'tech-2',
    displayName: 'Technician B',
    emailMasked: 'tb***@test.local',
    role: 'TECHNICIAN',
    status: 'DISABLED',
  ),
  StaffMember(
    userId: 'admin-1',
    displayName: 'Admin A',
    emailMasked: 'a***@test.local',
    role: 'WORKSHOP_ADMIN',
    status: 'ACTIVE',
  ),
  StaffMember(
    userId: 'admin-2',
    displayName: 'Admin B',
    emailMasked: 'ab***@test.local',
    role: 'WORKSHOP_ADMIN',
    status: 'ACTIVE',
  ),
];

class _StaffProductApi implements AdminApi {
  @override
  Future<List<StaffMember>> staff() async => _members;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadF3BFonts();
  });

  testWidgets('capture f3b staff level2 product', (tester) async {
    final root = _repoRoot();
    final outDir =
        fidelityOutputDir(root, 'figma/fidelity/f3b/staff-management-product');
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
  const height = 1048.0;

  tester.view.physicalSize = const Size(width * dpr, height * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  const rootKey = ValueKey('f3b-capture-root');

  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminApiProvider.overrideWithValue(_StaffProductApi())],
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
              child: StaffTab(),
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
    'card-tech-1': find.byKey(const Key('staff-tech-1')),
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
    throw StateError('PNG encoding returned no data for f3b staff level2');
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
      'sample': 'staff-level2',
      'logicalSize': {'width': width, 'height': height},
      'devicePixelRatio': dpr,
      'boxes': boxes,
    }),
    flush: true,
  );
  File('${outDir.path}/strings.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'sample': 'staff-level2',
      'locale': 'en',
      'direction': 'ltr',
      'theme': 'light',
      'textScale': 1,
      'strings': strings,
    }),
    flush: true,
  );
}
