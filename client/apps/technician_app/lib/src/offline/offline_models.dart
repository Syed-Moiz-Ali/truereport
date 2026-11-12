import 'dart:typed_data';

class SyncOperation {
  const SyncOperation({
    required this.id,
    required this.jobId,
    required this.type,
    required this.payload,
    required this.state,
    required this.attempts,
    required this.lastError,
    required this.createdAt,
  });

  final String id;
  final String jobId;
  final String type;
  final Map<String, dynamic> payload;
  final String state;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;

  bool get isPending =>
      state == 'PENDING' || state == 'FAILED' || state == 'SYNCING';
  bool get isConflict => state == 'CONFLICT';

  SyncOperation copyWith({String? state, int? attempts, String? lastError}) =>
      SyncOperation(
        id: id,
        jobId: jobId,
        type: type,
        payload: payload,
        state: state ?? this.state,
        attempts: attempts ?? this.attempts,
        lastError: lastError ?? this.lastError,
        createdAt: createdAt,
      );
}

class LocalEvidence {
  const LocalEvidence({
    required this.id,
    required this.jobId,
    required this.itemId,
    required this.mimeType,
    required this.sha256,
    required this.bytes,
    required this.state,
    required this.createdAt,
    this.type = 'PHOTO',
    this.captionEn,
    this.captionAr,
    this.posterBase64,
    this.durationMs,
    this.captureSource,
    this.deviceId,
    this.width,
    this.height,
  });

  final String id;
  final String jobId;
  final String itemId;
  final String mimeType;
  final String sha256;
  final Uint8List bytes;
  final String state;
  final DateTime createdAt;
  final String type;
  final String? captionEn;
  final String? captionAr;
  final String? posterBase64;
  final int? durationMs;
  final String? captureSource;
  final String? deviceId;
  final int? width;
  final int? height;
}

class SyncQueueStatus {
  const SyncQueueStatus({
    required this.pending,
    required this.failed,
    required this.conflicts,
  });

  final int pending;
  final int failed;
  final int conflicts;

  int get total => pending + failed + conflicts;

  bool get isEmpty => total == 0;

  bool get hasConflicts => conflicts > 0;
}

class SyncConflictRecord {
  const SyncConflictRecord({
    required this.id,
    required this.jobId,
    required this.itemCode,
    required this.clientRevision,
    required this.serverRevision,
    required this.serverPayloadJson,
    required this.clientPayloadJson,
    required this.state,
    required this.createdAt,
  });

  final String id;
  final String jobId;
  final String itemCode;
  final int clientRevision;
  final int serverRevision;
  final String? serverPayloadJson;
  final String? clientPayloadJson;
  final String state;
  final DateTime createdAt;

  bool get isOpen => state == 'OPEN';
}
