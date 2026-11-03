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

  bool get isPending => state == 'PENDING' || state == 'FAILED';
  bool get isConflict => state == 'CONFLICT';

  SyncOperation copyWith({
    String? state,
    int? attempts,
    String? lastError,
  }) => SyncOperation(
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
  });

  final String id;
  final String jobId;
  final String itemId;
  final String mimeType;
  final String sha256;
  final Uint8List bytes;
  final String state;
  final DateTime createdAt;
}
