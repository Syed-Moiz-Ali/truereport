// Visual evidence for the rounded-controls token pass.
//
// Writes real-font PNGs to test/screenshots/token_pass/. No pixel assertions:
// the gate is `tester.takeException()` plus the widget tests.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/features/dashboard/dashboard_screen.dart';
import 'package:platform_admin_app/src/features/workshops/workshop_form.dart';
import 'package:platform_admin_app/src/platform_catalogue_models.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/platform_theme.dart';

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
    families
        .putIfAbsent(resolved, () => FontLoader(resolved))
        .addFont(Future.value(ByteData.sublistView(bytes)));
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

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return;
    final dir = Directory('test/screenshots/token_pass');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    File('${dir.path}/$name.png')
        .writeAsBytesSync(data.buffer.asUint8List(), flush: true);
  });
}

OverviewSummary _summary() => OverviewSummary.fromJson(<String, dynamic>{
  'workshops': <String, dynamic>{'total': 48, 'active': 42},
  'staff': <String, dynamic>{'technicians': 87, 'admins': 6},
  'jobs': <String, dynamic>{'active': 23, 'pendingReview': 4},
  'reports': <String, dynamic>{'published': 318},
  'checklist': <String, dynamic>{
    'categories': 12,
    'items': 186,
    'templates': 9,
    'healthy': false,
    'issues': 2,
  },
  'languages': <String, dynamic>{'live': 4, 'translating': 1},
  'recentActivity': <dynamic>[],
  'alerts': <dynamic>[],
  'metricCards': <Map<String, dynamic>>[
    <String, dynamic>{
      'code': 'activeWorkshops',
      'labelKey': 'dashActiveWorkshops',
      'value': '42',
      'captionKey': 'dashActiveWorkshopsCaption',
      'tone': 'success',
      'order': 10,
    },
    <String, dynamic>{
      'code': 'technicians',
      'labelKey': 'dashTechnicians',
      'value': '87',
      'captionKey': 'dashTechniciansCaption',
      'tone': 'info',
      'order': 20,
    },
    <String, dynamic>{
      'code': 'activeJobs',
      'labelKey': 'dashActiveJobs',
      'value': '23',
      'captionKey': 'dashActiveJobsCaption',
      'tone': 'info',
      'order': 30,
    },
    <String, dynamic>{
      'code': 'pendingReviews',
      'labelKey': 'dashPendingReviews',
      'value': '9',
      'captionKey': 'dashPendingReviewsCaption',
      'tone': 'warning',
      'order': 40,
    },
  ],
  'localizedAlerts': <Map<String, dynamic>>[
    <String, dynamic>{
      'code': 'checklistIssues',
      'severity': 'warning',
      'order': 10,
      'titleKey': 'dashboard.alert.checklistIssues.title',
      'bodyKey': 'dashboard.alert.checklistIssues.body',
      'args': <String, String>{'count': '2'},
      'action': <String, String>{
        'labelKey': 'dashboard.alert.checklistIssues.action',
        'route': '/checklist/health',
      },
    },
  ],
});

Widget _harness({
  required GlobalKey boundaryKey,
  required Widget child,
  List<Override> overrides = const <Override>[],
}) {
  return ProviderScope(
    overrides: [
      uiStringsProvider.overrideWithValue(loadReferenceStrings()),
      ...overrides,
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      supportedLocales: const <Locale>[Locale('en')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        fontFamily: TrFonts.latin,
        scaffoldBackgroundColor: PtTheme.canvas,
      ),
      home: RepaintBoundary(
        key: boundaryKey,
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  setUpAll(_loadRealFonts);

  testWidgets('capture dashboard at 1440', (tester) async {
    final key = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      _harness(
        boundaryKey: key,
        overrides: <Override>[
          overviewProvider.overrideWith((ref) async => _summary()),
          auditEventsProvider.overrideWith(
            (ref) async => const <PlatformAuditEvent>[],
          ),
        ],
        child: const DashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'dashboard_1440');
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('capture create-workshop form at 390', (tester) async {
    final key = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      _harness(
        boundaryKey: key,
        child: const SingleChildScrollView(
          padding: EdgeInsetsDirectional.fromSTEB(16, 20, 16, 32),
          child: WorkshopForm(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'create_workshop_390');
    await tester.binding.setSurfaceSize(null);
  });
}
