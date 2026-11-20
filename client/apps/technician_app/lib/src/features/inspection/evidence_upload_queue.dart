import 'package:api_client/api_client.dart';
import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:technician_app/src/features/inspection/clean_shared.dart';
import 'package:technician_app/src/features/inspection/evidence_capture_service.dart';
import 'package:technician_app/src/features/inspection/evidence_validation.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/offline/offline_store.dart';
import 'package:technician_app/src/technician_api.dart';

/// The visible stage of one item's evidence.
///
/// required -> capturing -> uploading -> complete, with queued/cancelled/failed
/// as the explicit exits the field actually needs. Derived from the server list
/// plus this queue, never from a local status table.
enum EvidenceUploadStage {
  idle,
  capturing,
  uploading,
  queued,
  failed,
  cancelled,
  complete,
}

@immutable
class EvidenceUploadState {
  const EvidenceUploadState({
    this.stage = EvidenceUploadStage.idle,
    this.type,
    this.sent = 0,
    this.total = 0,
    this.attempt = 0,
    this.failure,
    this.error,
    this.evidence,
  });

  final EvidenceUploadStage stage;
  final String? type;
  final int sent;
  final int total;
  final int attempt;
  final EvidenceValidationFailure? failure;
  final Object? error;
  final Evidence? evidence;

  bool get busy =>
      stage == EvidenceUploadStage.capturing ||
      stage == EvidenceUploadStage.uploading;

  double? get progress {
    if (stage != EvidenceUploadStage.uploading) {
      return null;
    }
    if (total <= 0) {
      return null;
    }
    return (sent / total).clamp(0, 1).toDouble();
  }

  EvidenceUploadState copyWith({
    EvidenceUploadStage? stage,
    String? type,
    int? sent,
    int? total,
    int? attempt,
    EvidenceValidationFailure? failure,
    Object? error,
    Evidence? evidence,
    bool clearFailure = false,
    bool clearError = false,
    bool clearEvidence = false,
  }) {
    return EvidenceUploadState(
      stage: stage ?? this.stage,
      type: type ?? this.type,
      sent: sent ?? this.sent,
      total: total ?? this.total,
      attempt: attempt ?? this.attempt,
      failure: clearFailure ? null : failure ?? this.failure,
      error: clearError ? null : error ?? this.error,
      evidence: clearEvidence ? null : evidence ?? this.evidence,
    );
  }
}

enum EvidenceUploadOutcome { uploaded, queued, failed, cancelled, invalid }

class EvidenceUploadResult {
  const EvidenceUploadResult({
    required this.outcome,
    this.failure,
    this.error,
    this.evidence,
  });

  final EvidenceUploadOutcome outcome;
  final EvidenceValidationFailure? failure;
  final Object? error;
  final Evidence? evidence;

  bool get ok =>
      outcome == EvidenceUploadOutcome.uploaded ||
      outcome == EvidenceUploadOutcome.queued;
}

@immutable
class _UploadTask {
  const _UploadTask({
    required this.id,
    required this.captured,
    required this.sha256,
    required this.captionEn,
    required this.captionAr,
    required this.idempotencyKey,
  });

  final String id;
  final CapturedEvidence captured;
  final String sha256;
  final String? captionEn;
  final String? captionAr;
  final String idempotencyKey;

  Uint8List get bytes => captured.bytes;
}

/// Sequential, retrying, cancellable evidence upload queue for one item.
///
/// The queue never hides a failure: every branch ends in uploading, complete,
/// queued (offline), cancelled, or failed with the server reason.
class EvidenceUploadQueue {
  EvidenceUploadQueue({
    required this.api,
    required this.store,
    required this.jobId,
    required this.itemCode,
    required this.deviceId,
    Future<void> Function(Duration)? wait,
  }) : _wait = wait ?? ((duration) => Future<void>.delayed(duration));

  final TechnicianApi api;
  final OfflineStore store;
  final String jobId;
  final String itemCode;
  final Future<String> Function() deviceId;
  final Future<void> Function(Duration) _wait;

  static const int maxAttempts = 3;
  static const Duration _firstBackoff = Duration(milliseconds: 400);
  static const Duration _secondBackoff = Duration(milliseconds: 1200);

  final ValueNotifier<EvidenceUploadState> state =
      ValueNotifier<EvidenceUploadState>(const EvidenceUploadState());

  final List<_UploadTask> _pending = <_UploadTask>[];
  _UploadTask? _lastTask;
  RequestCancellation? _cancellation;
  bool _cancelled = false;
  Future<EvidenceUploadResult>? _active;
  int _sequence = 0;

  bool get isBusy => state.value.busy;

  void markCapturing(String type) {
    state.value = EvidenceUploadState(
      stage: EvidenceUploadStage.capturing,
      type: type,
    );
  }

  void clearCapturing() {
    if (state.value.stage == EvidenceUploadStage.capturing) {
      state.value = const EvidenceUploadState();
    }
  }

  Future<EvidenceUploadResult> enqueue(
    CapturedEvidence captured, {
    String? captionEn,
    String? captionAr,
    Iterable<String> existingSha256 = const <String>[],
  }) async {
    final sha = sha256Hex(captured.bytes);
    final failure = validateEvidenceMetadata(
      type: captured.type,
      mime: captured.mime,
      bytes: captured.bytes.length,
      sha256: sha,
      captureSource: captured.captureSource,
      width: captured.width,
      height: captured.height,
      durationMs: captured.durationMs,
      existingSha256: existingSha256,
    );
    if (failure != null) {
      state.value = EvidenceUploadState(
        stage: EvidenceUploadStage.failed,
        type: captured.type,
        failure: failure,
      );
      return EvidenceUploadResult(
        outcome: EvidenceUploadOutcome.invalid,
        failure: failure,
      );
    }
    _sequence += 1;
    final id = '$sha-${DateTime.now().microsecondsSinceEpoch}-$_sequence';
    final task = _UploadTask(
      id: id,
      captured: captured,
      sha256: sha,
      captionEn: captionEn,
      captionAr: captionAr,
      idempotencyKey: 'evidence-$id',
    );
    _pending.add(task);
    return _drain();
  }

  Future<EvidenceUploadResult> retryLast() {
    final task = _lastTask;
    if (task == null) {
      return Future<EvidenceUploadResult>.value(
        const EvidenceUploadResult(outcome: EvidenceUploadOutcome.failed),
      );
    }
    _cancelled = false;
    _pending.add(task);
    return _drain();
  }

  void cancel() {
    _cancelled = true;
    _cancellation?.cancel();
    _pending.clear();
    final current = state.value;
    if (current.busy) {
      state.value = current.copyWith(
        stage: EvidenceUploadStage.cancelled,
        clearError: true,
      );
    }
  }

  Future<EvidenceUploadResult> _drain() {
    final active = _active;
    if (active != null) {
      // Join the active drain instead of starting a second upload.
      return active;
    }
    late final Future<EvidenceUploadResult> future;
    future = _runDrain().whenComplete(() {
      if (identical(_active, future)) {
        _active = null;
        _cancellation = null;
      }
    });
    _active = future;
    return future;
  }

  Future<EvidenceUploadResult> _runDrain() async {
    _cancelled = false;
    EvidenceUploadResult result = const EvidenceUploadResult(
      outcome: EvidenceUploadOutcome.failed,
    );
    while (_pending.isNotEmpty) {
      if (_cancelled) {
        result = const EvidenceUploadResult(
          outcome: EvidenceUploadOutcome.cancelled,
        );
        break;
      }
      final task = _pending.removeAt(0);
      _lastTask = task;
      result = await _attempt(task);
      if (result.outcome != EvidenceUploadOutcome.uploaded) {
        break;
      }
    }
    return result;
  }

  Future<EvidenceUploadResult> _attempt(_UploadTask task) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (_cancelled) {
        state.value = state.value.copyWith(
          stage: EvidenceUploadStage.cancelled,
        );
        return const EvidenceUploadResult(
          outcome: EvidenceUploadOutcome.cancelled,
        );
      }
      state.value = EvidenceUploadState(
        stage: EvidenceUploadStage.uploading,
        type: task.captured.type,
        sent: 0,
        total: task.bytes.length,
        attempt: attempt,
      );
      try {
        final evidence = await _uploadOnce(task);
        state.value = EvidenceUploadState(
          stage: EvidenceUploadStage.complete,
          type: task.captured.type,
          sent: task.bytes.length,
          total: task.bytes.length,
          attempt: attempt,
          evidence: evidence,
        );
        return EvidenceUploadResult(
          outcome: EvidenceUploadOutcome.uploaded,
          evidence: evidence,
        );
      } on _UploadCancelled {
        state.value = EvidenceUploadState(
          stage: EvidenceUploadStage.cancelled,
          type: task.captured.type,
        );
        return const EvidenceUploadResult(
          outcome: EvidenceUploadOutcome.cancelled,
        );
      } on Object catch (error) {
        if (_cancelled || _isCancelled(error)) {
          state.value = EvidenceUploadState(
            stage: EvidenceUploadStage.cancelled,
            type: task.captured.type,
          );
          return const EvidenceUploadResult(
            outcome: EvidenceUploadOutcome.cancelled,
          );
        }
        if (isNetworkFailure(error)) {
          return _queueOffline(task, error);
        }
        if (_isRetryable(error) && attempt < maxAttempts) {
          await _wait(attempt == 1 ? _firstBackoff : _secondBackoff);
          continue;
        }
        state.value = EvidenceUploadState(
          stage: EvidenceUploadStage.failed,
          type: task.captured.type,
          attempt: attempt,
          error: error,
        );
        return EvidenceUploadResult(
          outcome: EvidenceUploadOutcome.failed,
          error: error,
        );
      }
    }
    state.value = EvidenceUploadState(
      stage: EvidenceUploadStage.failed,
      type: task.captured.type,
      error: const AppFailure(
        code: 'EVIDENCE_RETRY_EXHAUSTED',
        messageKey: 'error.technician.evidenceFailed',
      ),
    );
    return EvidenceUploadResult(
      outcome: EvidenceUploadOutcome.failed,
      error: state.value.error,
    );
  }

  Future<Evidence> _uploadOnce(_UploadTask task) async {
    final device = await deviceId();
    final init = await api.cleanInitEvidence(
      jobId,
      itemCode,
      EvidenceInitRequest(
        type: task.captured.type,
        mime: task.captured.mime,
        bytes: task.bytes.length,
        sha256: task.sha256,
        capturedAt: task.captured.capturedAt,
        captureSource: task.captured.captureSource,
        deviceId: device,
        width: task.captured.width,
        height: task.captured.height,
        durationMs: task.captured.durationMs,
        captionEn: task.captionEn,
        captionAr: task.captionAr,
        posterBase64: task.captured.posterBase64,
      ),
      idempotencyKey: task.idempotencyKey,
    );
    if (_cancelled) {
      throw const _UploadCancelled();
    }
    if (init.status == 'VERIFIED') {
      return init;
    }
    final cancellation = RequestCancellation();
    _cancellation = cancellation;
    await api.uploadEvidenceContent(
      jobId,
      itemCode,
      init.id,
      task.bytes,
      contentType: 'application/octet-stream',
      cancellation: cancellation,
      onSendProgress: (sent, total) {
        if (_cancelled) {
          return;
        }
        state.value = state.value.copyWith(
          stage: EvidenceUploadStage.uploading,
          sent: sent,
          total: total > 0 ? total : task.bytes.length,
        );
      },
    );
    if (_cancelled) {
      throw const _UploadCancelled();
    }
    return api.cleanCompleteEvidence(
      jobId,
      itemCode,
      init.id,
      EvidenceCompleteRequest(
        captionEn: task.captionEn,
        captionAr: task.captionAr,
        posterBase64: task.captured.posterBase64,
      ),
    );
  }

  Future<EvidenceUploadResult> _queueOffline(
    _UploadTask task,
    Object error,
  ) async {
    try {
      await store.queueEvidence(
        jobId: jobId,
        itemId: itemCode,
        bytes: task.bytes,
        mimeType: task.captured.mime,
        sha256: task.sha256,
        type: task.captured.type,
        captionEn: task.captionEn,
        captionAr: task.captionAr,
        posterBase64: task.captured.posterBase64,
        durationMs: task.captured.durationMs,
        captureSource: task.captured.captureSource,
        deviceId: await deviceId(),
        width: task.captured.width,
        height: task.captured.height,
        capturedAt: task.captured.capturedAt,
        clean: true,
      );
      state.value = EvidenceUploadState(
        stage: EvidenceUploadStage.queued,
        type: task.captured.type,
        sent: task.bytes.length,
        total: task.bytes.length,
        error: error,
      );
      return EvidenceUploadResult(
        outcome: EvidenceUploadOutcome.queued,
        error: error,
      );
    } on Object catch (queueError) {
      state.value = EvidenceUploadState(
        stage: EvidenceUploadStage.failed,
        type: task.captured.type,
        error: queueError,
      );
      return EvidenceUploadResult(
        outcome: EvidenceUploadOutcome.failed,
        error: queueError,
      );
    }
  }

  bool _isCancelled(Object error) =>
      error is AppFailure && error.code == 'CANCELLED';

  bool _isRetryable(Object error) {
    if (error is! AppFailure) {
      return false;
    }
    final status = error.statusCode;
    if (status == null) {
      return false;
    }
    return status == 408 || status == 429 || status >= 500;
  }

  void dispose() {
    // The notifier may still receive the cancelled future's completion after
    // the page is gone; cancelling is enough and avoids writes to a disposed
    // notifier.
    cancel();
  }
}

class _UploadCancelled implements Exception {
  const _UploadCancelled();
}
