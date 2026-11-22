import 'dart:io';
import 'dart:ui' as ui;

import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/features/inspection/evidence_capture_sheet.dart';
import 'package:technician_app/src/features/inspection/vehicle_photo_gate.dart';
import 'package:technician_app/src/features/jobs/technician_jobs_clean_page.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/technician_providers.dart';

import 'support/f2a_test_fonts.dart';
import 'support/f2a_test_images.dart';
import 'support/f2a_views.dart';
import 'support/test_reference_overrides.dart';
import 'support/test_offline_store.dart';
import 'support/ui_strings_harness.dart';

/// Visual-token pass evidence: the technician queue and the inspection hub at
/// phone width, rendered with the bundled real fonts and fixture data.
///
/// Files are written outside the repo so the committed tree stays clean:
/// `${Directory.systemTemp.path}/truereport-visual-pass`.
const _outputDir = 'truereport-visual-pass';

const _session = Session(
  accessToken: 'token',
  refreshToken: 'refresh',
  user: User(
    id: 'user-1',
    email: 'david@test.local',
    displayName: 'David Vance',
    platformAdmin: false,
    totpEnabled: false,
  ),
  memberships: [
    Membership(
      workshopId: 'workshop-1',
      workshopName: 'Marina Workshop',
      role: Role.technician,
    ),
  ],
);

JobSummary _job({
  required String id,
  required String reference,
  required String status,
  required String make,
  required String model,
  required String plate,
  required String customer,
  required Duration offset,
  int completed = 0,
  int total = 12,
}) {
  final at = DateTime.now().add(offset);
  return JobSummary(
    id: id,
    reference: reference,
    status: status,
    reviewStatus: status,
    templateVersionId: 'version-1',
    templateNameEn: 'Full inspection',
    templateNameAr: 'فحص شامل',
    templateVersionNo: 1,
    assignedTechnicianId: 'tech-1',
    customerName: customer,
    customerPhone: '+971500000100',
    customerEmail: 'jobs@test.local',
    vehicleVin: 'TESTVIN00000000002',
    vehicleMake: make,
    vehicleModel: model,
    vehicleYear: 2023,
    vehiclePlate: plate,
    odometerValue: 45000,
    odometerUnit: 'KM',
    transmission: 'AUTOMATIC',
    fuelType: 'PETROL',
    vehicleType: 'SUV',
    preferredLanguage: 'en',
    scheduledAt: at.toIso8601String(),
    startedAt: null,
    assessmentState: null,
    completedItems: completed,
    totalItems: total,
    version: 1,
  );
}

final _jobs = <JobSummary>[
  _job(
    id: 'job-1',
    reference: 'JOB-10482',
    status: 'IN_PROGRESS',
    make: 'Toyota',
    model: 'Land Cruiser',
    plate: 'A12345',
    customer: 'Ahmed Al Mansoori',
    offset: const Duration(minutes: 45),
    completed: 5,
    total: 12,
  ),
  _job(
    id: 'job-2',
    reference: 'JOB-10483',
    status: 'ASSIGNED',
    make: 'Mercedes',
    model: 'G 63',
    plate: 'B67890',
    customer: 'Fatima Al Zaabi',
    offset: const Duration(hours: 2, minutes: 30),
    completed: 0,
    total: 9,
  ),
  _job(
    id: 'job-3',
    reference: 'JOB-10484',
    status: 'SCHEDULED',
    make: 'Porsche',
    model: 'Macan',
    plate: 'C24680',
    customer: 'Omar Haddad',
    offset: const Duration(hours: 4),
    completed: 0,
    total: 14,
  ),
  _job(
    id: 'job-4',
    reference: 'JOB-10485',
    status: 'ASSIGNED',
    make: 'Nissan',
    model: 'Patrol',
    plate: 'D13579',
    customer: 'Layla Hassan',
    offset: const Duration(hours: 5, minutes: 15),
    completed: 2,
    total: 10,
  ),
];

Future<void> _write(WidgetTester tester, Key key, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final image = await boundary.toImage(pixelRatio: 1);
  final data = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  if (data == null) {
    throw StateError('PNG encoding returned no data for $name');
  }
  final directory = Directory('${Directory.systemTemp.path}/$_outputDir')
    ..createSync(recursive: true);
  final file = File('${directory.path}/$name.png')
    ..writeAsBytesSync(data.buffer.asUint8List(), flush: true);
  // ignore: avoid_print
  print('VISUAL_PASS_SCREENSHOT ${file.absolute.path}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadF2AFonts();
  });

  testWidgets('technician queue at 390', (tester) async {
    const size = Size(390, 900);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = createTestOfflineStore();
    addTearDown(store.close);
    final overrides = <Override>[
      ...testReferenceStatusOverrides(),
      offlineStoreProvider.overrideWithValue(store),
      technicianJobPageProvider.overrideWith(
        (ref, query) async => JobSummaryPage(
          items: _jobs,
          page: 0,
          size: 50,
          total: _jobs.length,
          totalPages: 1,
        ),
      ),
      syncQueueStatusProvider.overrideWith(
        (ref) async =>
            const SyncQueueStatus(pending: 2, failed: 0, conflicts: 0),
      ),
      connectivityProvider.overrideWith((ref) => Stream<bool>.value(true)),
    ];
    final container = ProviderContainer(
      overrides: overrides,
      retry: (retryCount, error) => null,
    );
    addTearDown(container.dispose);
    container.read(authControllerProvider.notifier).state =
        const AsyncData<Session?>(_session);

    const rootKey = ValueKey('visual-pass-queue');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: const <Locale>[Locale('en')],
          localizationsDelegates: testLocalizationsDelegates,
          builder: (context, child) => UiStringsScope(
            strings: baseStrings(),
            child: child ?? const SizedBox.shrink(),
          ),
          home: RepaintBoundary(
            key: rootKey,
            child: MediaQuery(
              data: const MediaQueryData(size: size, devicePixelRatio: 1),
              child: SizedBox.fromSize(
                size: size,
                child: const TechnicianJobsCleanPage(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await _write(tester, rootKey, 'technician_queue_390');
  });

  testWidgets('technician inspection hub at 390', (tester) async {
    const size = Size(390, 1130);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final root = repoRoot();
    final avatar = await tester.runAsync(
      () => loadFigmaTestImage(
        '${root.path}/docs/ui/figma-export/technision_figma/screens/02_2._Assigned_Jobs_Dashboard/assets/images/rendered_png/Profile-1_7264@2x.png',
      ),
    );
    final vehicle = await tester.runAsync(
      () => loadFigmaTestImage(
        '${root.path}/docs/ui/figma-export/technision_figma/screens/07_7._Main_Inspection_Hub/assets/images/rendered_png/AB6AXuB6_Pkv61jikWQ0s0IyLmWBs8UlV0z3xFmD3rVquFuXbT51TM8fZc4gbcvtwfCxcE9mMeECTG_MK7LApabA9-_p_e478eNX-1_7757@2x.png',
      ),
    );

    const rootKey = ValueKey('visual-pass-hub');
    await tester.pumpWidget(
      RepaintBoundary(
        key: rootKey,
        child: SizedBox.fromSize(
          size: size,
          child: f2aHost(
            child: f2aScreen(
              'inspection-hub',
              figma: true,
              avatarImage: avatar,
              vehicleImage: vehicle,
            ),
            locale: const Locale('en'),
            theme: AppTheme.light,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await _write(tester, rootKey, 'technician_inspection_hub_390');
  });

  testWidgets('vehicle photo gate at 390', (tester) async {
    const size = Size(390, 844);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const rootKey = ValueKey('visual-pass-photo-gate');
    await tester.pumpWidget(
      ProviderScope(
        overrides: testReferenceStatusOverrides(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: const <Locale>[Locale('en')],
          localizationsDelegates: testLocalizationsDelegates,
          builder: (context, child) => UiStringsScope(
            strings: baseStrings(),
            child: child ?? const SizedBox.shrink(),
          ),
          home: RepaintBoundary(
            key: rootKey,
            child: MediaQuery(
              data: const MediaQueryData(size: size, devicePixelRatio: 1),
              child: SizedBox.fromSize(
                size: size,
                child: Scaffold(
                  body: VehiclePhotoGate(jobId: 'job-1', onDone: () {}),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await _write(tester, rootKey, 'technician_vehicle_photo_gate_390');
  });

  testWidgets('evidence capture sheet at 390', (tester) async {
    const size = Size(390, 844);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const rootKey = ValueKey('visual-pass-evidence-sheet');
    await tester.pumpWidget(
      RepaintBoundary(
        key: rootKey,
        child: SizedBox.fromSize(
          size: size,
          child: ProviderScope(
            overrides: testReferenceStatusOverrides(),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              locale: const Locale('en'),
              supportedLocales: const <Locale>[Locale('en')],
              localizationsDelegates: testLocalizationsDelegates,
              builder: (context, child) => UiStringsScope(
                strings: baseStrings(),
                child: child ?? const SizedBox.shrink(),
              ),
              home: MediaQuery(
                data: const MediaQueryData(size: size, devicePixelRatio: 1),
                child: Scaffold(
                  body: Builder(
                    builder: (context) => Center(
                      child: TextButton(
                        onPressed: () => showEvidenceCaptureSheet(
                          context,
                          evidenceTypes: testEvidenceTypeEnums,
                          evidenceType: 'PHOTO',
                        ),
                        child: const Text('open evidence sheet'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open evidence sheet'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await _write(tester, rootKey, 'technician_evidence_sheet_390');
  });
}
