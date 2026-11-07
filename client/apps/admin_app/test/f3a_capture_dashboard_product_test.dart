import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:admin_app/src/admin_api.dart';
import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/job_counts.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/pages/dashboard_tab.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

/// F3-A Level 2 screen 1 — product capture for Figma screen 1
/// "Workshop Dashboard" (node `1:299`, 1280 x 1230.672).
///
/// Pumps the REAL product `DashboardTab`
/// (`client/apps/admin_app/lib/src/pages/dashboard_tab.dart`) — never the
/// Level 1 exact-structure fixture — at 1280 logical px wide x the Figma
/// frame height (1230.672), DPR 2, top-of-scroll, with real shadows
/// (`debugDisableShadows = false`, restored before the test body ends)
/// inside a [RepaintBoundary], then writes `render.png`, `geometry.json`
/// (product-anchored boxes, informational — the Level 2 fixture declares no
/// key boxes) and `strings.json` (the actually-rendered product copy) under
/// `docs/ui/figma/fidelity/f3a/dashboard-product/`.
///
/// Fake data is realistic and status-spanning: counts from the counts
/// endpoint plus four jobs (`IN_PROGRESS`, `READY_TO_FINALIZE`, `FINALIZED`,
/// `ASSIGNED`). No session is provided, so the user chip is omitted — the
/// product only renders the signed-in account chip when a session exists.
/// Nothing is added to any pubspec and `lib/` is untouched, so the admin
/// `source_scan_test.dart` stays green.
const _counts = JobCounts(
  draft: 2,
  scheduled: 3,
  newScheduled: 5,
  assigned: 4,
  inProgress: 3,
  readyToFinalize: 2,
  finalized: 6,
  finalizedToday: 1,
  cancelled: 1,
  total: 17,
);

const _jobs = [
  WorkshopJob(
    id: 'p1',
    reference: 'JOB-0001',
    status: 'IN_PROGRESS',
    templateVersionId: 'version-1',
    templateName: 'Full inspection',
    templateVersionNo: 1,
    assignedTechnicianId: 'tech-1',
    assignedTechnicianName: 'Technician A',
    scheduledAt: '2026-11-05T09:00:00',
    customerName: 'Customer A',
    customerPhone: '+971500000001',
    customerEmail: 'customer.a@test.local',
    vehicleMake: 'Toyota',
    vehicleModel: 'Camry',
    vehicleYear: 2022,
    vehicleVin: 'TESTVIN00000000001',
    vehiclePlate: 'A12345',
    scope: 'Full inspection',
  ),
  WorkshopJob(
    id: 'p2',
    reference: 'JOB-0002',
    status: 'READY_TO_FINALIZE',
    templateVersionId: 'version-1',
    templateName: 'Full inspection',
    templateVersionNo: 1,
    assignedTechnicianId: 'tech-1',
    assignedTechnicianName: 'Technician A',
    scheduledAt: '2026-11-05T10:00:00',
    customerName: 'Customer B',
    customerPhone: '+971500000002',
    customerEmail: 'customer.b@test.local',
    vehicleMake: 'Honda',
    vehicleModel: 'Civic',
    vehicleYear: 2023,
    vehicleVin: 'TESTVIN00000000002',
    vehiclePlate: 'B67890',
    scope: 'Full inspection',
  ),
  WorkshopJob(
    id: 'p3',
    reference: 'JOB-0003',
    status: 'FINALIZED',
    templateVersionId: 'version-1',
    templateName: 'Full inspection',
    templateVersionNo: 1,
    assignedTechnicianId: null,
    assignedTechnicianName: null,
    scheduledAt: '2026-11-04T09:00:00',
    customerName: 'Customer C',
    customerPhone: '+971500000003',
    customerEmail: 'customer.c@test.local',
    vehicleMake: 'Ford',
    vehicleModel: 'Transit',
    vehicleYear: 2021,
    vehicleVin: 'TESTVIN00000000003',
    vehiclePlate: 'C13579',
    scope: 'Full inspection',
  ),
  WorkshopJob(
    id: 'p4',
    reference: 'JOB-0004',
    status: 'ASSIGNED',
    templateVersionId: 'version-1',
    templateName: 'Full inspection',
    templateVersionNo: 1,
    assignedTechnicianId: null,
    assignedTechnicianName: null,
    scheduledAt: '2026-11-06T09:00:00',
    customerName: 'Customer D',
    customerPhone: '+971500000004',
    customerEmail: 'customer.d@test.local',
    vehicleMake: 'Nissan',
    vehicleModel: 'Patrol',
    vehicleYear: 2024,
    vehicleVin: 'TESTVIN00000000004',
    vehiclePlate: 'D24680',
    scope: 'Full inspection',
  ),
];

class _ProductFakeApi implements AdminApi {
  @override
  Future<JobCounts> jobCounts() async => _counts;

  @override
  Future<List<WorkshopJob>> jobs({
    String search = '',
    String status = '',
  }) async {
    final query = search.trim().toLowerCase();
    return _jobs.where((job) {
      if (status.isNotEmpty && job.status != status) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return [
        job.reference,
        job.customerName,
        job.vehicleMake,
        job.vehicleModel,
        job.assignedTechnicianName ?? '',
      ].any((field) => field.toLowerCase().contains(query));
    }).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadF3AFonts();
  });

  testWidgets('capture f3a dashboard product', (tester) async {
    final root = _repoRoot();
    final outDir = Directory(
      '${root.path}/docs/ui/figma/fidelity/f3a/dashboard-product',
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

Future<void> _render(WidgetTester tester, Directory outDir) async {
  if (debugDisableShadows) {
    throw StateError(
      'debugDisableShadows is true during fidelity capture; shadows would be '
      'solid blocks.',
    );
  }
  const dpr = 2.0;
  const width = 1280.0;
  const height = 1230.672;

  tester.view.physicalSize = const Size(width * dpr, height * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  const rootKey = ValueKey('f3a-capture-root');

  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminApiProvider.overrideWithValue(_ProductFakeApi())],
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
              child: DashboardTab(),
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
    'stat-active': find.byKey(const Key('dashboard-stat-active')),
    'job-1': find.byKey(const Key('dashboard-job-p1')),
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
    throw StateError('PNG encoding returned no data for f3a dashboard product');
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
      'sample': 'dashboard-level2',
      'logicalSize': {'width': width, 'height': height},
      'devicePixelRatio': dpr,
      'boxes': boxes,
    }),
    flush: true,
  );
  File('${outDir.path}/strings.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'sample': 'dashboard-level2',
      'locale': 'en',
      'direction': 'ltr',
      'theme': 'light',
      'textScale': 1,
      'strings': strings,
    }),
    flush: true,
  );
}
