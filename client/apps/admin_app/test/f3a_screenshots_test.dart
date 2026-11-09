// F3-A Step 4 screenshots of the four product screens.
//
// Pumps the real product widgets with a small inline fake api and writes
// PNG files at DPR 2 with bundled fonts to docs/ui/figma/f3a-screenshots/.
// Shots only; the checks below are limited to takeException being null.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:admin_app/src/admin_api.dart';
import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/job_counts.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/pages/assign_technician_dialog.dart';
import 'package:admin_app/src/pages/jobs_tab.dart';
import 'package:admin_app/src/pages/schedule_job_sheet.dart';
import 'package:admin_app/src/pages/workshop_admin_home.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

import 'support/fidelity_output.dart';

const _shotCounts = JobCounts(
  draft: 10,
  scheduled: 24,
  newScheduled: 34,
  assigned: 14,
  inProgress: 9,
  readyToFinalize: 45,
  finalized: 60,
  finalizedToday: 56,
  cancelled: 3,
  total: 140,
);

const _shotJobs = [
  WorkshopJob(
    id: 'job-1',
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
    id: 'job-2',
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
    id: 'job-3',
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
    id: 'job-4',
    reference: 'JOB-0004',
    status: 'SCHEDULED',
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

const _shotAssignJob = WorkshopJob(
  id: 'job-7',
  reference: 'JOB-TEST0007',
  status: 'SCHEDULED',
  templateVersionId: 'version-1',
  templateName: 'Full inspection',
  templateVersionNo: 1,
  assignedTechnicianId: null,
  assignedTechnicianName: null,
  scheduledAt: '2026-11-05T09:00:00',
  customerName: 'Customer A',
  customerPhone: '+971500000000',
  customerEmail: 'customer@test.local',
  vehicleMake: 'Toyota',
  vehicleModel: 'Camry',
  vehicleYear: 2022,
  vehicleVin: 'TESTVIN00000000001',
  vehiclePlate: 'A12345',
  scope: 'Full inspection',
);

const _shotTechA = StaffMember(
  userId: 'tech-1',
  displayName: 'Technician A',
  emailMasked: 't***@test.local',
  role: 'TECHNICIAN',
  status: 'ACTIVE',
);

const _shotTechB = StaffMember(
  userId: 'tech-2',
  displayName: 'Technician B',
  emailMasked: 'u***@test.local',
  role: 'TECHNICIAN',
  status: 'ACTIVE',
);

class _ShotFakeApi implements AdminApi {
  @override
  Future<JobCounts> jobCounts() async => _shotCounts;

  @override
  Future<List<WorkshopJob>> jobs({
    String search = '',
    String status = '',
  }) async {
    final query = search.trim().toLowerCase();
    return _shotJobs.where((job) {
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
  Future<List<StaffMember>> staff() async => const [_shotTechA, _shotTechB];

  @override
  Future<List<TemplateSummary>> templates() async => const [
    TemplateSummary(
      id: 'template-1',
      name: 'Full inspection',
      serviceType: 'FULL',
      vehicleType: 'CAR',
      status: 'PUBLISHED',
      currentVersion: 1,
      itemCount: 12,
    ),
    TemplateSummary(
      id: 'template-2',
      name: 'Quick check',
      serviceType: 'QUICK',
      vehicleType: null,
      status: 'PUBLISHED',
      currentVersion: 2,
      itemCount: 5,
    ),
  ];

  @override
  Future<List<TemplateVersionOption>> templateVersionOptions() async =>
      const [
        TemplateVersionOption(
          versionId: 'version-1',
          templateId: 'template-1',
          templateName: 'Full inspection',
          versionNo: 1,
          serviceType: 'FULL',
          vehicleType: 'CAR',
        ),
        TemplateVersionOption(
          versionId: 'version-2',
          templateId: 'template-2',
          templateName: 'Quick check',
          versionNo: 2,
          serviceType: 'QUICK',
          vehicleType: null,
        ),
      ];

  @override
  Future<WorkshopJob> assignJob(
    String jobId,
    String technicianId,
    String? reason,
  ) async {
    return _shotAssignJob;
  }

  @override
  Future<WorkshopJob> createJob({
    required String templateVersionId,
    required String customerName,
    String? customerPhone,
    String? customerEmail,
    required String vehicleMake,
    required String vehicleModel,
    int? vehicleYear,
    String? vehicleVin,
    String? vehiclePlate,
    required String scope,
    String? scheduledAt,
  }) async {
    return _shotAssignJob;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _ShotHarness extends ConsumerStatefulWidget {
  const _ShotHarness({required this.home, required this.locale});

  final Widget home;
  final Locale locale;

  @override
  ConsumerState<_ShotHarness> createState() => _ShotHarnessState();
}

class _ShotHarnessState extends ConsumerState<_ShotHarness> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localeProvider.notifier).setLocale(widget.locale);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.noScaling),
        child: child ?? const SizedBox.shrink(),
      ),
      home: widget.home,
    );
  }
}

Directory _shotRepoRoot() {
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

Future<void> _loadShotFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final root = _shotRepoRoot();
  final fontDir = Directory(
    '${root.path}/client/packages/design_system/assets/fonts',
  );
  final families = <String, FontLoader>{};
  if (fontDir.existsSync()) {
    await for (final entity in fontDir.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (!name.endsWith('.ttf') && !name.endsWith('.otf')) continue;
      final family = _shotFamilyFor(name);
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

String? _shotFamilyFor(String fileName) {
  if (fileName.startsWith('PlusJakartaSans')) return TrFonts.latin;
  if (fileName.startsWith('NotoSansArabic')) return TrFonts.arabicDefault;
  if (fileName.startsWith('IBMPlexSansArabic')) {
    return TrFonts.arabicAlternative;
  }
  if (fileName.startsWith('NotoSansSC')) return TrFonts.cjkFallback;
  if (fileName.startsWith('NotoSans-')) return TrFonts.cyrillicFallback;
  return null;
}

bool _enableShotShadows() {
  final previous = debugDisableShadows;
  debugDisableShadows = false;
  if (debugDisableShadows) {
    throw StateError('Shot capture must run with shadows enabled.');
  }
  return previous;
}

void _restoreShotShadows(bool previous) {
  debugDisableShadows = previous;
}

Future<void> _writeShotPng(WidgetTester tester, String fileName) async {
  const dpr = 2.0;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('f3a-shot-root')),
  );
  final image = await boundary.toImage(pixelRatio: dpr);
  final byteData = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  if (byteData == null) {
    throw StateError('PNG encoding returned no data for $fileName');
  }
  final root = _shotRepoRoot();
  final outDir = fidelityOutputDir(root, 'figma/f3a-screenshots');
  outDir.createSync(recursive: true);
  File(
    '${outDir.path}/$fileName',
  ).writeAsBytesSync(byteData.buffer.asUint8List());
}

Future<void> _pumpShotRoot(
  WidgetTester tester, {
  required Locale locale,
  required Size logical,
  required Widget home,
}) async {
  const dpr = 2.0;
  tester.view.physicalSize = Size(logical.width * dpr, logical.height * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    SizedBox(
      width: logical.width,
      height: logical.height,
      child: RepaintBoundary(
        key: const ValueKey('f3a-shot-root'),
        child: ProviderScope(
          overrides: [adminApiProvider.overrideWithValue(_ShotFakeApi())],
          child: _ShotHarness(home: home, locale: locale),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _shotQueueHome() => const Scaffold(body: JobsTab());

Widget _shotScheduleHome() => Scaffold(
  body: Center(
    child: Builder(
      builder: (sheetContext) => ElevatedButton(
        key: const Key('open-shot-sheet'),
        onPressed: () =>
            ScheduleJobSheet.showScheduleJobSheet(sheetContext),
        child: const Text('Open'),
      ),
    ),
  ),
);

Widget _shotAssignHome() => Scaffold(
  body: Center(
    child: Builder(
      builder: (dialogContext) => ElevatedButton(
        key: const Key('open-shot-dialog'),
        onPressed: () =>
            WorkshopAssignDialog.show(dialogContext, _shotAssignJob),
        child: const Text('Open'),
      ),
    ),
  ),
);

Future<void> _capturePlain(
  WidgetTester tester, {
  required Locale locale,
  required Size logical,
  required Widget home,
  required String fileName,
}) async {
  final previous = _enableShotShadows();
  try {
    await _pumpShotRoot(
      tester,
      locale: locale,
      logical: logical,
      home: home,
    );
    expect(tester.takeException(), isNull);
    await _writeShotPng(tester, fileName);
  } finally {
    _restoreShotShadows(previous);
  }
}

Future<void> _captureWithOpenButton(
  WidgetTester tester, {
  required Locale locale,
  required Size logical,
  required Widget home,
  required Key openKey,
  required String fileName,
}) async {
  final previous = _enableShotShadows();
  try {
    await _pumpShotRoot(
      tester,
      locale: locale,
      logical: logical,
      home: home,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(openKey));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _writeShotPng(tester, fileName);
  } finally {
    _restoreShotShadows(previous);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadShotFonts();
  });

  const wide = Size(1280, 800);
  const phone = Size(390, 844);

  testWidgets('shot dashboard en 1280', (tester) async {
    await _capturePlain(
      tester,
      locale: const Locale('en'),
      logical: wide,
      home: const WorkshopAdminHomePage(),
      fileName: 'dashboard_en_1280.png',
    );
  });

  testWidgets('shot dashboard ar 1280', (tester) async {
    await _capturePlain(
      tester,
      locale: const Locale('ar'),
      logical: wide,
      home: const WorkshopAdminHomePage(),
      fileName: 'dashboard_ar_1280.png',
    );
  });

  testWidgets('shot dashboard en 390', (tester) async {
    await _capturePlain(
      tester,
      locale: const Locale('en'),
      logical: phone,
      home: const WorkshopAdminHomePage(),
      fileName: 'dashboard_en_390.png',
    );
  });

  testWidgets('shot queue en 1280', (tester) async {
    await _capturePlain(
      tester,
      locale: const Locale('en'),
      logical: wide,
      home: _shotQueueHome(),
      fileName: 'queue_en_1280.png',
    );
  });

  testWidgets('shot queue ar 1280', (tester) async {
    await _capturePlain(
      tester,
      locale: const Locale('ar'),
      logical: wide,
      home: _shotQueueHome(),
      fileName: 'queue_ar_1280.png',
    );
  });

  testWidgets('shot queue en 390', (tester) async {
    await _capturePlain(
      tester,
      locale: const Locale('en'),
      logical: phone,
      home: _shotQueueHome(),
      fileName: 'queue_en_390.png',
    );
  });

  testWidgets('shot schedule en 1280', (tester) async {
    await _captureWithOpenButton(
      tester,
      locale: const Locale('en'),
      logical: wide,
      home: _shotScheduleHome(),
      openKey: const Key('open-shot-sheet'),
      fileName: 'schedule_en_1280.png',
    );
  });

  testWidgets('shot schedule en 390', (tester) async {
    await _captureWithOpenButton(
      tester,
      locale: const Locale('en'),
      logical: phone,
      home: _shotScheduleHome(),
      openKey: const Key('open-shot-sheet'),
      fileName: 'schedule_en_390.png',
    );
  });

  testWidgets('shot assign en 1280', (tester) async {
    await _captureWithOpenButton(
      tester,
      locale: const Locale('en'),
      logical: wide,
      home: _shotAssignHome(),
      openKey: const Key('open-shot-dialog'),
      fileName: 'assign_en_1280.png',
    );
  });

  testWidgets('shot assign en 390', (tester) async {
    await _captureWithOpenButton(
      tester,
      locale: const Locale('en'),
      logical: phone,
      home: _shotAssignHome(),
      openKey: const Key('open-shot-dialog'),
      fileName: 'assign_en_390.png',
    );
  });
}
