import 'dart:io';
import 'dart:ui' as ui;

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'support/ui_strings_harness.dart';

import 'package:technician_app/src/features/inspection/assessment_screen.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/technician_providers.dart';

import 'support/f2a_test_fonts.dart';
import 'support/test_offline_store.dart';
import 'support/test_reference_overrides.dart';

const _jobId = 'job-1';
const _itemCode = 'BRK-01';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadF2AFonts();
  });

  testWidgets('evidence required at phone width', (tester) async {
    await _capture(
      tester,
      'item_required_390x900',
      const Size(390, 900),
      evidence: const <Evidence>[],
    );
  });

  testWidgets('evidence complete at phone width', (tester) async {
    await _capture(
      tester,
      'item_complete_390x1000',
      const Size(390, 1000),
      evidence: _completeEvidence(),
    );
  });

  testWidgets('evidence required at tablet width', (tester) async {
    await _capture(
      tester,
      'item_required_1024x820',
      const Size(1024, 820),
      evidence: const <Evidence>[],
    );
  });

  testWidgets('evidence required at 1.5x text scale', (tester) async {
    await _capture(
      tester,
      'item_required_390x1200_text150',
      const Size(390, 1200),
      evidence: const <Evidence>[],
      textScale: 1.5,
    );
  });

  testWidgets('real phone viewport, scrolled to evidence', (tester) async {
    await _capture(
      tester,
      'item_required_390x844_evidence',
      const Size(390, 844),
      evidence: const <Evidence>[],
      scrollToEvidence: true,
    );
  });

  testWidgets('checklist error is scoped with retry', (tester) async {
    await _capture(
      tester,
      'item_error_390x844',
      const Size(390, 844),
      evidence: const <Evidence>[],
      checklistError: const AppFailure(
        code: 'SERVER_ERROR',
        messageKey: 'error.unknown',
        statusCode: 500,
      ),
    );
  });
}

Future<void> _capture(
  WidgetTester tester,
  String name,
  Size size, {
  required List<Evidence> evidence,
  double textScale = 1,
  bool scrollToEvidence = false,
  Object? checklistError,
}) async {
  const dpr = 2.0;
  tester.view.physicalSize = size * dpr;
  tester.view.devicePixelRatio = dpr;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  const rootKey = ValueKey('phase4-evidence-root');
  final store = createTestOfflineStore();
  addTearDown(store.close);
  final overrides = <Override>[
    ...testReferenceStatusOverrides(),
    offlineStoreProvider.overrideWithValue(store),
    if (checklistError != null)
      technicianChecklistProvider(_jobId)
          .overrideWith((ref) async => throw checklistError)
    else
      technicianChecklistProvider(
        _jobId,
      ).overrideWith((ref) async => _checklist(complete: evidence.isNotEmpty)),
    technicianEvidenceListProvider((jobId: _jobId, itemCode: _itemCode))
        .overrideWith((ref) async => evidence),
    connectivityProvider.overrideWith((ref) => Stream<bool>.value(true)),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      retry: (_, _) => null,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: testLocalizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(size: size, textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        ),
        home: RepaintBoundary(
          key: rootKey,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: const TechnicianItemPage(jobId: _jobId, itemCode: _itemCode),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
  if (scrollToEvidence) {
    await tester.scrollUntilVisible(
      find.text('Take photo'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  expect(
    tester.takeException(),
    isNull,
    reason: '$name rendered without an exception',
  );
  if (checklistError != null) {
    expect(find.byType(ErrorState), findsOneWidget);
  }

  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(rootKey),
  );
  final image = await boundary.toImage(pixelRatio: dpr);
  final data = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  if (data == null) {
    throw StateError('PNG encoding returned no data for $name');
  }
  final directory = Directory(
    '${Directory.systemTemp.path}/truereport-phase4-evidence',
  )..createSync(recursive: true);
  final file = File('${directory.path}/$name.png');
  file.writeAsBytesSync(data.buffer.asUint8List());
  // ignore: avoid_print
  print('PHASE4_SCREENSHOT ${file.absolute.path}');
}

Checklist _checklist({required bool complete}) => Checklist.fromJson({
  'job': {
    'id': _jobId,
    'reference': 'JOB-7F3A21',
    'status': 'IN_PROGRESS',
    'customerName': 'Layla Hassan',
    'vehicleMake': 'Toyota',
    'vehicleModel': 'Hilux',
    'vehiclePlate': 'A 12345',
    'completedItems': complete ? 1 : 0,
    'totalItems': 1,
    'version': 1,
  },
  'categories': [
    {
      'code': 'BRAKES',
      'nameEn': 'Brakes',
      'nameAr': '',
      'iconCode': 'BRAKES',
      'sortOrder': 0,
    },
  ],
  'items': [
    {
      'itemCode': _itemCode,
      'itemVersionId': 'item-version-1',
      'categoryCode': 'BRAKES',
      'sortOrder': 0,
      'labelEn': 'Front brake pads',
      'labelAr': '',
      'instructionEn': 'Inspect the pads and record photo and video evidence.',
      'resultOptions': ['NO_ISSUE_OBSERVED', 'DEFECT_FOUND'],
      'evidenceRules': [
        {
          'resultCode': 'NO_ISSUE_OBSERVED',
          'minPhotos': 1,
          'minVideos': 1,
          'minNotesChars': 0,
          'requiredEvidenceType': null,
        },
      ],
      'assessment': complete
          ? {'resultCode': 'NO_ISSUE_OBSERVED', 'version': 1}
          : null,
    },
  ],
  'progress': {'completed': complete ? 1 : 0, 'total': 1},
  'serverRevision': 4,
});

List<Evidence> _completeEvidence() => <Evidence>[
  Evidence.fromJson({
    'id': 'evidence-photo',
    'jobId': _jobId,
    'itemCode': _itemCode,
    'type': 'PHOTO',
    'status': 'VERIFIED',
    'mime': 'image/jpeg',
    'bytes': 482133,
    'sha256': 'a'.padRight(64, 'a'),
    'captureSource': 'CAMERA',
    'width': 1600,
    'height': 1200,
    'captionEn': 'Front pads - outer face',
  }),
  Evidence.fromJson({
    'id': 'evidence-video',
    'jobId': _jobId,
    'itemCode': _itemCode,
    'type': 'VIDEO',
    'status': 'UPLOADED',
    'mime': 'video/mp4',
    'bytes': 5242880,
    'sha256': 'b'.padRight(64, 'b'),
    'captureSource': 'CAMERA',
    'durationMs': 22000,
  }),
];
