import 'dart:async';
import 'dart:typed_data';

import 'package:api_client/api_client.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technician_app/src/features/inspection/clean_shared.dart';
import 'package:technician_app/src/features/inspection/evidence_capture_service.dart';
import 'package:technician_app/src/features/inspection/evidence_upload_queue.dart';
import 'package:technician_app/src/features/inspection/evidence_validation.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/offline/offline_store.dart';
import 'package:technician_app/src/offline/sync_service.dart';
import 'package:technician_app/src/technician_api.dart';

import 'support/test_offline_store.dart';

CapturedEvidence _captured({String source = 'CAMERA'}) => CapturedEvidence(
  type: 'PHOTO',
  bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
  mime: 'image/jpeg',
  capturedAt: DateTime.utc(2026, 11, 20, 10).toIso8601String(),
  captureSource: source,
  width: 640,
  height: 480,
);

Evidence _evidence(String status) => Evidence(
  id: 'server-1',
  jobId: 'job-1',
  itemCode: 'ITEM-1',
  type: 'PHOTO',
  status: status,
  mime: 'image/jpeg',
  bytes: 4,
  sha256: 'a'.padRight(64, 'a'),
  capturedAt: DateTime.utc(2026, 11, 20, 10).toIso8601String(),
  captureSource: 'CAMERA',
  deviceId: 'device-1',
  width: 640,
  height: 480,
  durationMs: null,
  captionEn: null,
  captionAr: null,
  posterAvailable: false,
  qualityStatus: null,
  contentUrl: null,
  createdAt: DateTime.utc(2026, 11, 20, 10).toIso8601String(),
);

class _FakeApi implements TechnicianApi {
  int initCalls = 0;
  int uploadCalls = 0;
  int completeCalls = 0;
  int active = 0;
  int maxActive = 0;
  int serverFailures = 0;
  int businessFailures = 0;
  bool offline = false;
  Completer<void>? gate;
  String? lastCaptureSource;

  @override
  Future<Evidence> cleanInitEvidence(
    String jobId,
    String itemCode,
    EvidenceInitRequest request, {
    String? idempotencyKey,
  }) async {
    initCalls += 1;
    lastCaptureSource = request.captureSource;
    active += 1;
    if (active > maxActive) {
      maxActive = active;
    }
    try {
      await Future<void>.delayed(const Duration(milliseconds: 1));
      final blocker = gate;
      if (blocker != null) {
        gate = null;
        await blocker.future;
      }
      if (offline) {
        throw const AppFailure(code: 'NETWORK', messageKey: 'error.network');
      }
      if (serverFailures > 0) {
        serverFailures -= 1;
        throw const AppFailure(
          code: 'SERVER_ERROR',
          messageKey: 'error.network',
          statusCode: 500,
        );
      }
      if (businessFailures > 0) {
        businessFailures -= 1;
        throw const AppFailure(
          code: 'EVIDENCE_INVALID',
          messageKey: 'error.technician.evidenceInvalid',
          statusCode: 422,
        );
      }
      return _evidence('PENDING');
    } finally {
      active -= 1;
    }
  }

  @override
  Future<Evidence> uploadEvidenceContent(
    String jobId,
    String itemCode,
    String evidenceId,
    List<int> bytes, {
    required String contentType,
    void Function(int sent, int total)? onSendProgress,
    RequestCancellation? cancellation,
  }) async {
    uploadCalls += 1;
    if (offline) {
      throw const AppFailure(code: 'NETWORK', messageKey: 'error.network');
    }
    onSendProgress?.call(bytes.length, bytes.length);
    return _evidence('UPLOADED');
  }

  @override
  Future<Evidence> cleanCompleteEvidence(
    String jobId,
    String itemCode,
    String evidenceId,
    EvidenceCompleteRequest request,
  ) async {
    completeCalls += 1;
    return _evidence('VERIFIED');
  }

  @override
  Future<List<Evidence>> evidenceList(String jobId, String itemCode) async =>
      const <Evidence>[];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late OfflineStore store;
  late _FakeApi api;

  setUp(() {
    store = createTestOfflineStore();
    api = _FakeApi();
  });

  tearDown(() async {
    await store.close();
  });

  EvidenceUploadQueue queue({_FakeApi? withApi}) {
    final client = withApi ?? api;
    return EvidenceUploadQueue(
      api: client,
      store: store,
      jobId: 'job-1',
      itemCode: 'ITEM-1',
      deviceId: () async => 'device-1',
      wait: (_) async {},
    );
  }

  test('uploads once and reports complete with real byte progress', () async {
    final upload = queue();
    addTearDown(upload.dispose);

    final result = await upload.enqueue(_captured());

    expect(result.outcome, EvidenceUploadOutcome.uploaded);
    expect(api.initCalls, 1);
    expect(api.uploadCalls, 1);
    expect(api.completeCalls, 1);
    expect(upload.state.value.stage, EvidenceUploadStage.complete);
    expect(upload.state.value.sent, 4);
    expect(upload.state.value.total, 4);
  });

  test('rejects a duplicate sha256 before any server call', () async {
    final upload = queue();
    addTearDown(upload.dispose);
    final captured = _captured();
    final sha = _sha(captured.bytes);

    final result = await upload.enqueue(
      captured,
      existingSha256: <String>[sha],
    );

    expect(result.outcome, EvidenceUploadOutcome.invalid);
    expect(result.failure, EvidenceValidationFailure.duplicate);
    expect(api.initCalls, 0);
    expect(upload.state.value.stage, EvidenceUploadStage.failed);
  });

  test('rejects an oversized photo before any server call', () async {
    final upload = queue();
    addTearDown(upload.dispose);
    final oversized = CapturedEvidence(
      type: 'PHOTO',
      bytes: Uint8List(maxPhotoBytes + 1),
      mime: 'image/jpeg',
      capturedAt: DateTime.utc(2026).toIso8601String(),
      captureSource: 'CAMERA',
      width: 640,
      height: 480,
    );

    final result = await upload.enqueue(oversized);

    expect(result.failure, EvidenceValidationFailure.tooLarge);
    expect(api.initCalls, 0);
  });

  test('retries a 5xx with backoff and then completes', () async {
    api.serverFailures = 2;
    final upload = queue();
    addTearDown(upload.dispose);

    final result = await upload.enqueue(_captured());

    expect(result.outcome, EvidenceUploadOutcome.uploaded);
    expect(api.initCalls, 3);
    expect(api.uploadCalls, 1);
    expect(upload.state.value.attempt, 3);
  });

  test('does not retry a validation failure and keeps the error', () async {
    api.businessFailures = 1;
    final upload = queue();
    addTearDown(upload.dispose);

    final result = await upload.enqueue(_captured());

    expect(result.outcome, EvidenceUploadOutcome.failed);
    expect(result.error, isA<AppFailure>());
    expect(api.initCalls, 1);
    expect(upload.state.value.stage, EvidenceUploadStage.failed);
  });

  test('cancel stops the upload and never reports success', () async {
    final gate = Completer<void>();
    api.gate = gate;
    final upload = queue();
    addTearDown(upload.dispose);

    final future = upload.enqueue(_captured());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    upload.cancel();
    gate.complete();

    final result = await future;

    expect(result.outcome, EvidenceUploadOutcome.cancelled);
    expect(api.uploadCalls, 0);
    expect(api.completeCalls, 0);
    expect(upload.state.value.stage, EvidenceUploadStage.cancelled);
  });

  test('offline capture persists and replays through SyncService', () async {
    api.offline = true;
    final upload = queue();
    addTearDown(upload.dispose);

    final result = await upload.enqueue(_captured(source: 'FILE'));

    expect(result.outcome, EvidenceUploadOutcome.queued);
    expect(upload.state.value.stage, EvidenceUploadStage.queued);
    expect(await store.pendingCount(), 1);
    final queued = await store.evidenceForItem('job-1', 'ITEM-1');
    expect(queued, hasLength(1));
    expect(queued.single.captureSource, 'FILE');

    api.offline = false;
    final report = await SyncService(api, store).syncAll();

    expect(report.synced, 1);
    expect(report.failed, 0);
    expect(await store.pendingCount(), 0);
    expect(api.uploadCalls, 1);
    expect(api.completeCalls, 1);
    expect(api.lastCaptureSource, 'FILE');
  });

  test('two captures on one item upload sequentially', () async {
    final upload = queue();
    addTearDown(upload.dispose);

    final results = await Future.wait(<Future<EvidenceUploadResult>>[
      upload.enqueue(_captured()),
      upload.enqueue(_captured()),
    ]);

    expect(
      results.map((value) => value.outcome),
      everyElement(EvidenceUploadOutcome.uploaded),
    );
    expect(api.maxActive, 1);
    expect(api.uploadCalls, 2);
  });
}

String _sha(List<int> bytes) {
  return sha256Hex(bytes);
}
