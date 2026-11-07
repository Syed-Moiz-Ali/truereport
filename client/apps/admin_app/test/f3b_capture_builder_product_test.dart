import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:admin_app/src/admin_api.dart';
import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/pages/template_builder_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

/// F3-B Level 2 screen 8 — product capture for Figma screen 8
/// "Template Builder" (node `1:1882`, 1280 x 1251.5).
///
/// Pumps the REAL product `TemplateBuilderPage`
/// (`client/apps/admin_app/lib/src/pages/template_builder_page.dart`) — never
/// the Level 1 exact-structure fixture — at 1280 logical px wide x the Figma
/// frame height (1251.5), DPR 2, top-of-scroll, with real shadows
/// (`debugDisableShadows = false`, restored before the test body ends)
/// inside a [RepaintBoundary], then writes `render.png`, `geometry.json`
/// (product-anchored boxes, informational — the Level 2 fixture declares no
/// key boxes) and `strings.json` (the actually-rendered product copy) under
/// `docs/ui/figma/fidelity/f3b/template-builder-product/`.
///
/// Fake data mirrors `test/template_builder_test.dart` (two workshop
/// categories, five published master items, a draft with three sequence
/// items) with a minimal inline fake — no private helpers are imported.
/// Nothing is added to any pubspec and `lib/` is untouched, so the admin
/// `source_scan_test.dart` stays green.
ItemVersion _productVersion(String id, String label) {
  return ItemVersion(
    id: id,
    versionNo: 1,
    status: 'PUBLISHED',
    resultOptions: const ['NO_ISSUE_OBSERVED', 'DEFECT_FOUND'],
    severityPolicy: '{}',
    applicability: '{}',
    reasonCodes: const [],
    noteRequirement: 'REQUIRED',
    evidenceRequirement: 'REQUIRED',
    minPhotos: 1,
    equipmentIds: const [],
    guideImageId: null,
    publishedAt: '2026-11-03T10:00:00',
    translations: {
      'en': Translation(
        locale: 'en',
        label: label,
        instruction: '$label steps',
      ),
      'ar': Translation(
        locale: 'ar',
        label: '$label AR',
        instruction: '$label steps AR',
      ),
    },
  );
}

PublishedItem _productPublished(
  String itemId,
  String versionId,
  String label,
  String categoryId,
  String categoryLabel,
) {
  final version = _productVersion(versionId, label);
  return PublishedItem(
    itemId: itemId,
    versionId: versionId,
    stableCode: 'STABLE-$itemId',
    categoryId: categoryId,
    categoryLabelEn: categoryLabel,
    categoryLabelAr: '$categoryLabel AR',
    labelEn: label,
    labelAr: '$label AR',
    sampleData: false,
    version: version,
  );
}

TemplateItemView _productDraftItem(String versionId, String label, int order) {
  return TemplateItemView(
    masterItemVersionId: versionId,
    sortOrder: order,
    stableCode: 'STABLE-$versionId',
    categoryLabelEn: 'Chassis',
    categoryLabelAr: 'Chassis AR',
    labelEn: label,
    labelAr: '$label AR',
    instructionEn: 'Instruction $versionId en',
    instructionAr: 'Instruction $versionId ar',
    versionNo: 1,
    resultOptions: const ['NO_ISSUE_OBSERVED'],
    severityPolicy: '{}',
    reasonCodes: const [],
    noteRequirement: 'REQUIRED',
    evidenceRequirement: 'REQUIRED',
    minPhotos: 1,
    equipmentIds: const [],
    guideImageId: null,
    sampleData: false,
  );
}

class _BuilderProductFakeApi implements AdminApi {
  static final List<Category> _categories = [
    const Category(
      id: 'cat-chassis',
      slug: 'chassis',
      status: 'ACTIVE',
      sortOrder: 1,
      labelEn: 'Chassis',
      labelAr: 'Chassis AR',
      itemCount: 2,
    ),
    const Category(
      id: 'cat-engine',
      slug: 'engine',
      status: 'ACTIVE',
      sortOrder: 2,
      labelEn: 'Engine',
      labelAr: 'Engine AR',
      itemCount: 3,
    ),
  ];

  static final List<PublishedItem> _catalog = [
    _productPublished('item-brake', 'mv-brake', 'Brake pad wear check',
        'cat-chassis', 'Chassis'),
    _productPublished(
        'item-oil', 'mv-oil', 'Engine oil level', 'cat-engine', 'Engine'),
    _productPublished('item-battery', 'mv-battery', 'Battery health check',
        'cat-chassis', 'Chassis'),
    _productPublished('item-coolant', 'mv-coolant', 'Coolant level check',
        'cat-engine', 'Engine'),
    _productPublished('item-wiper', 'mv-wiper', 'Wiper blade check',
        'cat-engine', 'Engine'),
  ];

  TemplateDetail _detail() {
    return TemplateDetail(
      id: 't-1',
      name: 'Comprehensive Inspection',
      description: 'Workshop template',
      serviceType: 'FULL',
      vehicleType: 'CAR',
      status: 'DRAFT',
      currentPublishedVersionId: 'v-1',
      versions: const [
        TemplateVersionSummary(
          id: 'v-1',
          versionNo: 1,
          status: 'PUBLISHED',
          publishedAt: '2026-11-03T10:00:00',
          itemCount: 3,
        ),
      ],
      draft: TemplateVersionView(
        id: 'draft-2',
        versionNo: 2,
        status: 'DRAFT',
        publishedAt: '',
        items: [
          _productDraftItem('mv-brake', 'Brake pad wear check', 0),
          _productDraftItem('mv-oil', 'Engine oil level', 1),
          _productDraftItem('mv-battery', 'Battery health check', 2),
        ],
      ),
    );
  }

  @override
  Future<TemplateDetail> templateDetail(String id) async => _detail();

  @override
  Future<List<Category>> workshopCategories() async => _categories;

  @override
  Future<List<PublishedItem>> publishedItems({
    String search = '',
    String categoryId = '',
  }) async {
    final query = search.trim().toLowerCase();
    return _catalog.where((item) {
      if (categoryId.isNotEmpty && item.categoryId != categoryId) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return item.labelEn.toLowerCase().contains(query) ||
          item.categoryLabelEn.toLowerCase().contains(query);
    }).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadF3BFonts();
  });

  testWidgets('capture f3b builder product', (tester) async {
    final root = _repoRoot();
    final outDir = Directory(
      '${root.path}/docs/ui/figma/fidelity/f3b/template-builder-product',
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
  const height = 1251.5;

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
        adminApiProvider.overrideWithValue(_BuilderProductFakeApi()),
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
              child: TemplateBuilderPage(templateId: 't-1'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);

  final boxFinders = <String, Finder>{
    'title': find.byKey(const Key('builder-title')),
    'dropzone': find.byKey(const Key('builder-dropzone')),
    'seq-0': find.byKey(const Key('seq-remove-0')),
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
    throw StateError('PNG encoding returned no data for f3b builder product');
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
      'sample': 'builder-level2',
      'logicalSize': {'width': width, 'height': height},
      'devicePixelRatio': dpr,
      'boxes': boxes,
    }),
    flush: true,
  );
  File('${outDir.path}/strings.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'sample': 'builder-level2',
      'locale': 'en',
      'direction': 'ltr',
      'theme': 'light',
      'textScale': 1,
      'strings': strings,
    }),
    flush: true,
  );
}
