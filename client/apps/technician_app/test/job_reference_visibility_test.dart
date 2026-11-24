import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/features/inspection/inspection_deck.dart';
import 'package:technician_app/src/features/review/signoff_screen.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/technician_providers.dart';

import 'support/f2a_test_fonts.dart';
import 'support/test_reference_overrides.dart';
import 'support/ui_strings_harness.dart';

const String _reference = 'JOB-2026-0107';

Map<String, dynamic> _jobJson({required String plate}) => <String, dynamic>{
  'id': 'job-1',
  'reference': _reference,
  'status': 'IN_PROGRESS',
  'templateVersionId': 'version-1',
  'templateNameEn': 'Full inspection',
  'templateNameAr': 'فحص شامل',
  'customerName': 'Rashid Al Mansoori',
  'customerPhone': '+971500000000',
  'vehicleMake': 'Porsche',
  'vehicleModel': '911 GT3',
  'vehicleYear': 2023,
  'vehiclePlate': plate,
  'preferredLanguage': 'en',
  'assessmentState': 'IN_PROGRESS',
  'completedItems': 0,
  'totalItems': 0,
  'version': 1,
};

JobSummary _job({required String plate}) =>
    JobSummary.fromJson(_jobJson(plate: plate));

Checklist _checklist({required String plate}) =>
    Checklist.fromJson(<String, dynamic>{
      'job': _jobJson(plate: plate),
      'categories': <dynamic>[],
      'items': <dynamic>[],
      'progress': <String, dynamic>{'completed': 0, 'total': 0},
      'serverRevision': 1,
    });

Future<void> _pumpHub(
  WidgetTester tester, {
  required String plate,
  Size size = const Size(1280, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: const <Locale>[Locale('en')],
      localizationsDelegates: testLocalizationsDelegates,
      builder: (context, child) => UiStringsScope(
        strings: baseStrings(),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: InspectionDeck(
          checklist: _checklist(plate: plate),
          jobId: 'job-1',
          selectedCategory: null,
          focusedItemCode: null,
          onCategory: (_) {},
          onFocus: (_) {},
          onOpen: (_) {},
          onSummary: () {},
          onBack: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpSummary(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final overrides = <Override>[
    ...testReferenceStatusOverrides(),
    technicianJobSummaryProvider('job-1')
        .overrideWith((ref) async => _job(plate: 'DXB 48291')),
    technicianSummaryProvider('job-1').overrideWith(
      (ref) async => Summary.fromJson(<String, dynamic>{
        'jobId': 'job-1',
        'status': 'IN_PROGRESS',
        'itemsAssessed': 0,
        'itemsTotal': 0,
        'blockers': <dynamic>[],
        'warnings': <dynamic>[],
      }),
    ),
    technicianReviewProvider('job-1').overrideWith(
      (ref) async => const Review(
        jobId: 'job-1',
        status: 'IN_PROGRESS',
        blockers: <Blocker>[],
        warnings: <Blocker>[],
        findings: <Map<String, dynamic>>[],
      ),
    ),
    technicianConflictsProvider('job-1')
        .overrideWith((ref) async => const <SyncConflictRecord>[]),
  ];
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: testLocalizationsDelegates,
        builder: (context, child) => UiStringsScope(
          strings: baseStrings(),
          child: child ?? const SizedBox.shrink(),
        ),
        home: const TechnicianSummaryPage(jobId: 'job-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadF2AFonts);

  testWidgets('hub header shows the job reference beside the plate', (
    tester,
  ) async {
    await _pumpHub(tester, plate: 'DXB 48291');

    expect(find.byKey(const Key('inspection-job-reference')), findsOneWidget);
    expect(find.text(_reference), findsOneWidget);
    expect(find.text('DXB 48291'), findsOneWidget);
  });

  testWidgets('hub shows the reference once when the plate is empty', (
    tester,
  ) async {
    await _pumpHub(tester, plate: '');

    expect(find.text(_reference), findsOneWidget);
    expect(find.byKey(const Key('inspection-job-reference')), findsNothing);
  });

  testWidgets('hub header has no overflow at 390', (tester) async {
    await _pumpHub(tester, plate: 'DXB 48291', size: const Size(390, 844));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('inspection-job-reference')), findsOneWidget);
  });

  testWidgets('summary bar shows the reference without overflow at 390', (
    tester,
  ) async {
    await _pumpSummary(tester);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('summary-job-reference')), findsOneWidget);
    expect(find.text(_reference), findsOneWidget);
  });
}
