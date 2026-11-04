import 'package:core/core.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/offline/offline_store.dart';
import 'package:technician_app/src/technician_api.dart';

class SyncReport {
  const SyncReport({
    required this.synced,
    required this.failed,
    required this.conflicts,
  });

  final int synced;
  final int failed;
  final int conflicts;
}

class SyncService {
  SyncService(this._api, this._store);

  final TechnicianApi _api;
  final OfflineStore _store;

  Future<SyncReport> syncAll() async {
    final operations = await _store.pendingOperations();
    var synced = 0;
    var failed = 0;
    var conflicts = 0;
    for (final operation in operations) {
      if (operation.state == 'CONFLICT') {
        conflicts += 1;
        continue;
      }
      await _store.setOperationState(operation.id, 'SYNCING');
      try {
        await _process(operation);
        synced += 1;
      } on AppFailure catch (error) {
        final isConflict =
            error.statusCode == 409 ||
            error.code.contains('CONFLICT') ||
            error.code.contains('VERSION');
        if (isConflict) {
          conflicts += 1;
          await _store.setOperationState(
            operation.id,
            'CONFLICT',
            error: error.code,
            attempts: operation.attempts + 1,
          );
          if (operation.type == 'assessment') {
            await _store.markAssessmentConflict(
              operation.payload['jobId'] as String,
              operation.payload['itemId'] as String,
            );
          }
          if (operation.type == 'evidence') {
            await _store.markEvidenceConflict(
              operation.payload['evidenceId'] as String,
            );
          }
        } else {
          failed += 1;
          await _store.setOperationState(
            operation.id,
            'FAILED',
            error: error.code,
            attempts: operation.attempts + 1,
          );
        }
      } on Object {
        failed += 1;
        await _store.setOperationState(
          operation.id,
          'FAILED',
          error: 'NETWORK',
          attempts: operation.attempts + 1,
        );
      }
    }
    return SyncReport(synced: synced, failed: failed, conflicts: conflicts);
  }

  Future<void> _process(SyncOperation operation) async {
    switch (operation.type) {
      case 'assessment':
        await _syncAssessment(operation);
      case 'evidence':
        await _syncEvidence(operation);
      case 'customer':
        await _syncCustomer(operation);
      case 'vehicle':
        await _syncVehicle(operation);
      case 'consent':
        await _syncConsent(operation);
    }
  }

  Future<void> _syncCustomer(SyncOperation operation) async {
    final jobId = operation.payload['jobId'] as String;
    final body = operation.payload['body'] as Map<String, dynamic>;
    final job = await _api.updateCustomer(
      jobId,
      customerName: body['customerName'] as String,
      customerPhone: body['customerPhone'] as String?,
      customerEmail: body['customerEmail'] as String?,
    );
    await _store.saveJob(job);
    await _store.removeOperation(operation.id);
  }

  Future<void> _syncVehicle(SyncOperation operation) async {
    final jobId = operation.payload['jobId'] as String;
    final body = operation.payload['body'] as Map<String, dynamic>;
    final job = await _api.updateVehicle(
      jobId,
      vehicleMake: body['vehicleMake'] as String,
      vehicleModel: body['vehicleModel'] as String,
      vehicleYear: body['vehicleYear'] as int?,
      vehicleVin: body['vehicleVin'] as String?,
      vehiclePlate: body['vehiclePlate'] as String?,
      odometerValue: body['odometerValue'] as int?,
      odometerUnit: body['odometerUnit'] as String?,
    );
    await _store.saveJob(job);
    await _store.removeOperation(operation.id);
  }

  Future<void> _syncConsent(SyncOperation operation) async {
    final jobId = operation.payload['jobId'] as String;
    final body = operation.payload['body'] as Map<String, dynamic>;
    await _api.recordConsent(
      jobId,
      consentType: body['consentType'] as String,
      status: body['status'] as String,
      wordingVersion: body['wordingVersion'] as String,
      channel: body['channel'] as String,
      evidenceRef: body['evidenceRef'] as String?,
    );
    await _store.removeOperation(operation.id);
  }

  Future<void> _syncAssessment(SyncOperation operation) async {
    final payload = operation.payload;
    final jobId = payload['jobId'] as String;
    final itemId = payload['itemId'] as String;
    final body = payload['body'] as Map<String, dynamic>;
    final item = await _api.assess(
      jobId,
      itemId,
      baseVersion: body['baseVersion'] as int? ?? 0,
      clientRevision: body['clientRevision'] as int? ?? 1,
      resultCode: body['resultCode'] as String,
      severityCode: body['severityCode'] as String?,
      note: body['note'] as String?,
      noteLanguage: body['noteLanguage'] as String?,
      reasonCode: body['reasonCode'] as String?,
      reasonText: body['reasonText'] as String?,
    );
    final assessment = item.assessment;
    if (assessment == null) {
      throw const AppFailure(
        code: 'ASSESSMENT_EMPTY',
        messageKey: 'error.unknown',
      );
    }
    await _store.markAssessmentReceived(
      jobId: jobId,
      itemId: itemId,
      assessment: assessment.toJson(),
    );
  }

  Future<void> _syncEvidence(SyncOperation operation) async {
    final payload = operation.payload;
    final jobId = payload['jobId'] as String;
    final itemId = payload['itemId'] as String;
    final evidenceId = payload['evidenceId'] as String;
    final evidence = await _findEvidence(jobId, itemId, evidenceId);
    if (evidence == null) {
      await _store.removeOperation(operation.id);
      return;
    }
    final init = await _api.initEvidence(
      jobId,
      itemId,
      evidenceId: evidenceId,
      mime: evidence.mimeType,
      bytes: evidence.bytes.length,
      sha256: evidence.sha256,
      capturedAt: payload['createdAt'] as String?,
    );
    if (init.status != 'VERIFIED') {
      final uploadUrl = init.uploadUrl;
      final uploadToken = init.uploadToken;
      if (uploadUrl == null || uploadToken == null) {
        throw const AppFailure(
          code: 'EVIDENCE_UPLOAD_UNAVAILABLE',
          messageKey: 'error.unknown',
        );
      }
      await _api.uploadEvidence(uploadUrl, uploadToken, evidence.bytes);
      await _api.completeEvidence(
        jobId,
        itemId,
        evidenceId,
        evidence.sha256,
      );
    }
    await _store.markEvidenceReceived(evidenceId);
  }

  Future<LocalEvidence?> _findEvidence(
    String jobId,
    String itemId,
    String evidenceId,
  ) async {
    final items = await _store.evidenceForItem(jobId, itemId);
    for (final item in items) {
      if (item.id == evidenceId) {
        return item;
      }
    }
    return null;
  }
}
