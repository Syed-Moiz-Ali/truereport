enum SyncState {
  localOnly,
  queued,
  uploading,
  received,
  failed,
  conflict,
}

abstract interface class SyncQueue {
  Future<void> enqueue(String operationId);

  Future<SyncState> state(String operationId);

  Future<void> retry(String operationId);
}
