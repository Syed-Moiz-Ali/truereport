import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client/api_client.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/features/inspection/evidence_capture_service.dart';
import 'package:technician_app/src/features/inspection/evidence_validation.dart';
import 'package:technician_app/src/features/inspection/inspection_deck.dart';
import 'package:technician_app/src/features/inspection/technician_workspace_page.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/technician_api.dart';
import 'package:technician_app/src/technician_providers.dart';

import 'support/ui_strings_harness.dart';

const String _jobId = 'job-1';

final Uint8List _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

JobSummary _jobSummary() => JobSummary.fromJson(<String, dynamic>{
  'id': _jobId,
  'reference': 'JOB-2026-0107',
  'status': 'ASSIGNED',
  'templateVersionId': 'version-1',
  'templateNameEn': 'Full inspection',
  'templateNameAr': 'فحص شامل',
  'customerName': 'Rashid Al Mansoori',
  'vehicleMake': 'Porsche',
  'vehicleModel': '911 GT3',
  'vehicleYear': 2023,
  'vehiclePlate': 'DXB 48291',
  'assessmentState': 'IN_PROGRESS',
  'version': 1,
});

Checklist _checklist({int completed = 0}) =>
    Checklist.fromJson(<String, dynamic>{
      'job': _jobSummary().toJson(),
      'categories': <dynamic>[],
      'items': <dynamic>[],
      'progress': <String, dynamic>{'completed': completed, 'total': 2},
      'serverRevision': 1,
    });

VehiclePhoto _photo(String status) => VehiclePhoto(
  id: 'photo-1',
  status: status,
  mime: 'image/jpeg',
  bytes: _pngBytes.length,
  sha256: 'a' * 64,
  capturedAt: '2026-11-22T09:00:00Z',
);

class _FakeApi implements TechnicianApi {
  _FakeApi({this.photo, this.uploadFails = false});

  VehiclePhoto? photo;
  final bool uploadFails;
  final List<String> calls = <String>[];
  VehiclePhotoInitRequest? initRequest;

  @override
  Future<VehiclePhoto?> getVehiclePhoto(String jobId) async => photo;

  @override
  Future<VehiclePhoto> initVehiclePhoto(
    String jobId,
    VehiclePhotoInitRequest request, {
    String? idempotencyKey,
  }) async {
    calls.add('init');
    initRequest = request;
    photo = _photo('PENDING_UPLOAD');
    return photo!;
  }

  @override
  Future<VehiclePhoto> uploadVehiclePhotoContent(
    String jobId,
    String photoId,
    List<int> bytes, {
    required String contentType,
    void Function(int sent, int total)? onSendProgress,
    RequestCancellation? cancellation,
  }) async {
    calls.add('upload');
    onSendProgress?.call(bytes.length, bytes.length);
    if (uploadFails) {
      throw const AppFailure(
        code: 'UPLOAD_FAILED',
        messageKey: 'error.network',
        statusCode: 500,
      );
    }
    photo = _photo('UPLOADED');
    return photo!;
  }

  @override
  Future<VehiclePhoto> completeVehiclePhoto(
    String jobId,
    String photoId,
  ) async {
    calls.add('complete');
    photo = _photo('READY');
    return photo!;
  }

  @override
  Future<List<int>> vehiclePhotoContent(String jobId) async => _pngBytes;

  @override
  Future<void> deleteVehiclePhoto(String jobId) async {
    calls.add('delete');
    photo = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeCapture extends EvidenceCaptureService {
  _FakeCapture();

  @override
  Future<CapturedEvidence?> captureVehiclePhoto({
    required EvidenceSource source,
  }) async => CapturedEvidence(
    type: 'PHOTO',
    bytes: _pngBytes,
    mime: 'image/png',
    capturedAt: '2026-11-22T09:00:00Z',
    captureSource: source.wire,
    width: 1280,
    height: 720,
  );
}

class _FailingCapture extends EvidenceCaptureService {
  @override
  Future<CapturedEvidence?> captureVehiclePhoto({
    required EvidenceSource source,
  }) async {
    throw const EvidenceCaptureException(
      EvidenceValidationFailure.resolutionTooLow,
    );
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required _FakeApi api,
  required Checklist checklist,
  EvidenceCaptureService? capture,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        technicianApiProvider.overrideWithValue(api),
        technicianChecklistProvider(_jobId)
            .overrideWith((ref) async => checklist),
        evidenceCaptureServiceProvider.overrideWithValue(
          capture ?? _FakeCapture(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: testLocalizationsDelegates,
        builder: (context, child) => UiStringsScope(
          strings: baseStrings(),
          child: child ?? const SizedBox.shrink(),
        ),
        home: const TechnicianWorkspacePage(jobId: _jobId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('no photo and no completed items blocks the deck', (
    tester,
  ) async {
    await _pump(tester, api: _FakeApi(), checklist: _checklist());

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('vehicle-photo-gate')), findsOneWidget);
    expect(find.byType(InspectionDeck), findsNothing);
  });

  testWidgets('capture runs init, upload, complete and opens the deck', (
    tester,
  ) async {
    final api = _FakeApi();
    await _pump(tester, api: api, checklist: _checklist());

    await tester.tap(find.byKey(const Key('vehicle-photo-camera')));
    await tester.pumpAndSettle();

    expect(api.calls, <String>['init', 'upload', 'complete']);
    expect(api.initRequest?.mime, 'image/png');
    expect(api.initRequest?.bytes, _pngBytes.length);
    expect(api.initRequest?.captureSource, 'CAMERA');
    expect(api.initRequest?.sha256, hasLength(64));
    expect(find.byKey(const Key('vehicle-photo-gate')), findsNothing);
    expect(find.byType(InspectionDeck), findsOneWidget);
  });

  testWidgets('existing photo shows Retake and never blocks', (tester) async {
    await _pump(
      tester,
      api: _FakeApi(photo: _photo('READY')),
      checklist: _checklist(),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('vehicle-photo-gate')), findsNothing);
    expect(find.byType(InspectionDeck), findsOneWidget);
    expect(find.byKey(const Key('vehicle-photo-retake')), findsOneWidget);
  });

  testWidgets('upload failure offers retry and continue unlocks the deck', (
    tester,
  ) async {
    final api = _FakeApi(uploadFails: true);
    await _pump(tester, api: api, checklist: _checklist());

    await tester.tap(find.byKey(const Key('vehicle-photo-camera')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('vehicle-photo-retry')), findsOneWidget);
    expect(find.byKey(const Key('vehicle-photo-continue')), findsOneWidget);

    await tester.tap(find.byKey(const Key('vehicle-photo-continue')));
    await tester.pumpAndSettle();

    expect(find.byType(InspectionDeck), findsOneWidget);
    expect(find.byKey(const Key('vehicle-photo-banner')), findsOneWidget);
  });

  testWidgets('small photo shows the specific copy, not the generic one', (
    tester,
  ) async {
    await _pump(
      tester,
      api: _FakeApi(),
      checklist: _checklist(),
      capture: _FailingCapture(),
    );

    await tester.tap(find.byKey(const Key('vehicle-photo-camera')));
    await tester.pumpAndSettle();

    final t = UiStrings.of(
      tester.element(find.byType(TechnicianWorkspacePage)),
    );
    expect(find.text(t(TechnicianKeys.vehiclePhotoTooSmall)), findsOneWidget);
    expect(find.text(t(TechnicianKeys.vehiclePhotoFailed)), findsNothing);
    expect(find.byKey(const Key('vehicle-photo-continue')), findsOneWidget);
  });

  testWidgets('completed items never block; the banner is the only prompt', (
    tester,
  ) async {
    await _pump(tester, api: _FakeApi(), checklist: _checklist(completed: 1));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('vehicle-photo-gate')), findsNothing);
    expect(find.byType(InspectionDeck), findsOneWidget);
    expect(find.byKey(const Key('vehicle-photo-banner')), findsOneWidget);
  });
}
