// Phase 2c visual evidence: served metric cards and config-health rows.
//
// Writes real-font PNGs to test/screenshots/phase2c/. No assertions on pixels;
// the console gate is `tester.takeException()` plus the layout tests.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/features/dashboard/trellis/trellis_modules.dart';
import 'package:platform_admin_app/src/features/governance/config_health_screen.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/platform_theme.dart';
import 'package:reference_data/reference_data.dart';

import 'reference_test_support.dart';

Future<void> _loadRealFonts() async {
  final fontDir = Directory('../../packages/design_system/assets/fonts');
  if (!fontDir.existsSync()) return;
  final families = <String, FontLoader>{};
  await for (final entity in fontDir.list()) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (!name.endsWith('.ttf') && !name.endsWith('.otf')) continue;
    String? family;
    if (name.startsWith('PlusJakartaSans')) {
      family = TrFonts.latin;
    } else if (name.startsWith('NotoSansArabic')) {
      family = TrFonts.arabicDefault;
    }
    final resolved = family;
    if (resolved == null) continue;
    final bytes = await entity.readAsBytes();
    final loader = families.putIfAbsent(resolved, () => FontLoader(resolved));
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    final bare = resolved.replaceFirst('packages/design_system/', '');
    families
        .putIfAbsent(bare, () => FontLoader(bare))
        .addFont(Future.value(ByteData.sublistView(bytes)));
  }
  const materialPath = 'build/unit_test_assets/fonts/MaterialIcons-Regular.otf';
  final material = File(materialPath);
  if (material.existsSync()) {
    final bytes = await material.readAsBytes();
    families
        .putIfAbsent('MaterialIcons', () => FontLoader('MaterialIcons'))
        .addFont(Future.value(ByteData.sublistView(bytes)));
  }
  for (final loader in families.values) {
    await loader.load();
  }
}

final _cards = <OverviewMetricCard>[
  for (final entry in <(String, String, String, String)>[
    ('dashActiveWorkshops', '1,234', 'dashActiveWorkshopsCaption', 'success'),
    ('dashTechnicians', '87', 'dashTechniciansCaption', 'info'),
    ('dashActiveJobs', '42', 'dashActiveJobsCaption', 'info'),
    ('dashPendingReviews', '9', 'dashPendingReviewsCaption', 'warning'),
    ('dashPublishedReports', '318', 'dashPublishedReportsCaption', 'success'),
    ('dashChecklistHealth', '0', 'dashChecklistHealthCaption', 'success'),
    ('dashLanguagesLive', '4', 'dashLanguagesLiveCaption', 'info'),
  ].indexed)
    OverviewMetricCard(
      code: entry.$2.$1,
      labelKey: entry.$2.$1,
      value: entry.$2.$2,
      captionKey: entry.$2.$3,
      tone: entry.$2.$4,
      order: entry.$1 * 10,
    ),
];

const _health = ConfigHealth(
  healthy: false,
  checks: <HealthCheck>[
    HealthCheck(
      code: 'TRANSLATIONS',
      severity: 'ERROR',
      messageEn: '3 translation(s) missing',
      messageAr: '',
      affected: 3,
      references: <String>['items.name', 'items.code', 'templates.name'],
      labelKey: 'health.check.translations.label',
      descriptionKey: 'health.check.translations.description',
      tone: 'danger',
      status: 'ERROR',
    ),
    HealthCheck(
      code: 'MEASUREMENT_BANDS',
      severity: 'WARNING',
      messageEn: '1 item version(s) have overlapping measurement bands',
      messageAr: '',
      affected: 1,
      references: <String>['item.brakes'],
      labelKey: 'health.check.measurementBands.label',
      descriptionKey: 'health.check.measurementBands.description',
      tone: 'warning',
      status: 'WARNING',
    ),
    HealthCheck(
      code: 'TEMPLATE_ITEMS',
      severity: 'OK',
      messageEn: 'All active template versions contain items',
      messageAr: '',
      affected: 0,
      references: <String>[],
      labelKey: 'health.check.templateItems.label',
      descriptionKey: 'health.check.templateItems.description',
      tone: 'success',
      status: 'OK',
    ),
  ],
);

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return;
    final dir = Directory('test/screenshots/phase2c');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    File('${dir.path}/$name.png')
        .writeAsBytesSync(data.buffer.asUint8List(), flush: true);
  });
}

Widget _harness(GlobalKey boundaryKey, Widget child) {
  return ProviderScope(
    overrides: <Override>[
      uiStringsProvider.overrideWithValue(loadReferenceStrings()),
      statusesProvider('health').overrideWith(
        (ref) async => <ReferenceRecord>[
          const ReferenceRecord(
            code: 'ERROR',
            labelKey: 'checklist.health.severityBadgeError',
            tone: 'danger',
          ),
          const ReferenceRecord(
            code: 'WARNING',
            labelKey: 'checklist.health.severityBadgeWarning',
            tone: 'warning',
          ),
          const ReferenceRecord(
            code: 'OK',
            labelKey: 'checklist.health.severityBadgeHealthy',
            tone: 'success',
          ),
          const ReferenceRecord(
            code: 'UNHEALTHY',
            labelKey: 'checklist.health.severityBadgeError',
            tone: 'danger',
          ),
        ],
      ),
      statusesProvider('workshop')
          .overrideWith((ref) async => const <ReferenceRecord>[]),
      statusesProvider('checklist')
          .overrideWith((ref) async => const <ReferenceRecord>[]),
      statusesProvider('document')
          .overrideWith((ref) async => const <ReferenceRecord>[]),
      statusesProvider('chip')
          .overrideWith((ref) async => const <ReferenceRecord>[]),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: TrFonts.latin,
        scaffoldBackgroundColor: PtTheme.canvas,
      ),
      home: Scaffold(
        body: RepaintBoundary(
          key: boundaryKey,
          child: ColoredBox(
            color: PtTheme.canvas,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(_loadRealFonts);

  testWidgets('capture served metric grid', (tester) async {
    final key = GlobalKey();
    for (final size in const <Size>[
      Size(1440, 1200),
      Size(768, 1200),
      Size(360, 1400),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        _harness(
          key,
          TrellisBento(strings: loadReferenceStrings(), cards: _cards),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _capture(tester, key, 'metrics_${size.width.toInt()}');
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('capture served config health rows', (tester) async {
    final key = GlobalKey();
    for (final size in const <Size>[Size(1440, 1200), Size(360, 1600)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        _harness(key, const ConfigHealthContent(health: _health)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _capture(tester, key, 'health_${size.width.toInt()}');
    }
    await tester.binding.setSurfaceSize(null);
  });
}
