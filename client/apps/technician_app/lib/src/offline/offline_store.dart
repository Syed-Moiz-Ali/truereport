import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/offline/offline_database.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:uuid/uuid.dart';

class OfflineStore {
  OfflineStore(this.db);

  final OfflineDatabase db;
  Future<void>? _opening;

  Future<void> _ensure() => _opening ??= _createSchema();

  Future<void> _createSchema() async {
    await db.customStatement(
      'CREATE TABLE IF NOT EXISTS local_store ('
      'key TEXT PRIMARY KEY NOT NULL, '
      'value TEXT NOT NULL, '
      'updated_at INTEGER NOT NULL)',
    );
    await db.customStatement(
      'CREATE TABLE IF NOT EXISTS sync_operations ('
      'id TEXT PRIMARY KEY NOT NULL, '
      'job_id TEXT NOT NULL, '
      'operation_type TEXT NOT NULL, '
      'payload TEXT NOT NULL, '
      'state TEXT NOT NULL, '
      'attempts INTEGER NOT NULL DEFAULT 0, '
      'last_error TEXT, '
      'created_at INTEGER NOT NULL, '
      'updated_at INTEGER NOT NULL)',
    );
    await db.customStatement(
      'CREATE TABLE IF NOT EXISTS evidence_blobs ('
      'evidence_id TEXT PRIMARY KEY NOT NULL, '
      'job_id TEXT NOT NULL, '
      'item_id TEXT NOT NULL, '
      'mime_type TEXT NOT NULL, '
      'sha256 TEXT NOT NULL, '
      'bytes BLOB NOT NULL, '
      'state TEXT NOT NULL, '
      'created_at INTEGER NOT NULL)',
    );
    await db.customStatement(
      'CREATE TABLE IF NOT EXISTS guide_blobs ('
      'job_id TEXT NOT NULL, '
      'item_id TEXT NOT NULL, '
      'content_type TEXT NOT NULL, '
      'bytes BLOB NOT NULL, '
      'PRIMARY KEY (job_id, item_id))',
    );
  }

  Future<void> close() => db.close();

  Future<void> saveJobs(List<TechnicianJob> jobs) async {
    await _put('jobs', jsonEncode(jobs.map((job) => job.toJson()).toList()));
  }

  Future<List<TechnicianJob>?> loadJobs() async {
    final raw = await _get('jobs');
    if (raw == null) {
      return null;
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => TechnicianJob.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> saveJob(TechnicianJob job) async {
    await _put('job:${job.id}', jsonEncode(job.toJson()));
  }

  Future<TechnicianJob?> loadJob(String jobId) async {
    final raw = await _get('job:$jobId');
    return raw == null
        ? null
        : TechnicianJob.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveChecklist(InspectionChecklist checklist) async {
    await _put(
      'checklist:${checklist.job.id}',
      jsonEncode(checklist.toJson()),
    );
    await saveJob(checklist.job);
  }

  Future<InspectionChecklist?> loadChecklist(String jobId) async {
    final raw = await _get('checklist:$jobId');
    return raw == null
        ? null
        : InspectionChecklist.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          );
  }

  Future<void> cacheGuideImage(
    String jobId,
    String itemId,
    String contentType,
    Uint8List bytes,
  ) async {
    await _ensure();
    await db.customStatement(
      'INSERT OR REPLACE INTO guide_blobs '
      '(job_id, item_id, content_type, bytes) VALUES (?, ?, ?, ?)',
      [jobId, itemId, contentType, bytes],
    );
  }

  Future<({String contentType, Uint8List bytes})?> loadGuideImage(
    String jobId,
    String itemId,
  ) async {
    await _ensure();
    final rows = await db.customSelect(
      'SELECT content_type, bytes FROM guide_blobs '
      'WHERE job_id = ? AND item_id = ?',
      variables: [Variable.withString(jobId), Variable.withString(itemId)],
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    return (
      contentType: rows.first.data['content_type'] as String,
      bytes: _blob(rows.first.data['bytes']),
    );
  }

  Future<void> saveAssessmentLocally({
    required String jobId,
    required String itemId,
    required Map<String, dynamic> body,
    required Map<String, dynamic> assessment,
  }) async {
    await _updateCachedItem(
      jobId,
      itemId,
      assessment: assessment,
      syncState: 'LOCAL_ONLY',
    );
    await _queue(
      id: 'assessment-$jobId-$itemId',
      jobId: jobId,
      type: 'assessment',
      payload: {'jobId': jobId, 'itemId': itemId, 'body': body},
    );
  }

  Future<void> markAssessmentReceived({
    required String jobId,
    required String itemId,
    required Map<String, dynamic> assessment,
  }) async {
    await _updateCachedItem(
      jobId,
      itemId,
      assessment: assessment,
      syncState: 'RECEIVED',
    );
    await removeOperation('assessment-$jobId-$itemId');
  }

  Future<void> markAssessmentConflict(String jobId, String itemId) async {
    await _updateCachedItem(
      jobId,
      itemId,
      assessment: null,
      syncState: 'CONFLICT',
    );
  }

  Future<void> saveCustomerLocally({
    required String jobId,
    required Map<String, dynamic> body,
  }) async {
    await _updateCachedJob(jobId, {
      'customerName': body['customerName'],
      'customerPhone': body['customerPhone'],
      'customerEmail': body['customerEmail'],
    });
    await _queue(
      id: 'customer-$jobId',
      jobId: jobId,
      type: 'customer',
      payload: {'jobId': jobId, 'body': body},
    );
  }

  Future<void> saveVehicleLocally({
    required String jobId,
    required Map<String, dynamic> body,
  }) async {
    await _updateCachedJob(jobId, body);
    await _queue(
      id: 'vehicle-$jobId',
      jobId: jobId,
      type: 'vehicle',
      payload: {'jobId': jobId, 'body': body},
    );
  }

  Future<void> saveConsentLocally({
    required String jobId,
    required Map<String, dynamic> body,
  }) async {
    await _queue(
      id: 'consent-$jobId-${DateTime.now().microsecondsSinceEpoch}',
      jobId: jobId,
      type: 'consent',
      payload: {'jobId': jobId, 'body': body},
    );
  }

  Future<LocalEvidence> queueEvidence({
    required String jobId,
    required String itemId,
    required Uint8List bytes,
    required String mimeType,
    required String sha256,
  }) async {
    await _ensure();
    final id = const Uuid().v7();
    final now = DateTime.now();
    await db.customStatement(
      'INSERT INTO evidence_blobs '
      '(evidence_id, job_id, item_id, mime_type, sha256, bytes, state, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [
        id,
        jobId,
        itemId,
        mimeType,
        sha256,
        bytes,
        'PENDING',
        now.millisecondsSinceEpoch,
      ],
    );
    await _queue(
      id: 'evidence-$id',
      jobId: jobId,
      type: 'evidence',
      payload: {
        'evidenceId': id,
        'jobId': jobId,
        'itemId': itemId,
        'mime': mimeType,
        'sha256': sha256,
        'createdAt': now.toUtc().toIso8601String(),
      },
    );
    return LocalEvidence(
      id: id,
      jobId: jobId,
      itemId: itemId,
      mimeType: mimeType,
      sha256: sha256,
      bytes: bytes,
      state: 'PENDING',
      createdAt: now,
    );
  }

  Future<List<LocalEvidence>> evidenceForItem(
    String jobId,
    String itemId,
  ) async {
    await _ensure();
    final rows = await db.customSelect(
      'SELECT evidence_id, job_id, item_id, mime_type, sha256, bytes, state, created_at '
      'FROM evidence_blobs WHERE job_id = ? AND item_id = ? '
      'ORDER BY created_at ASC',
      variables: [Variable.withString(jobId), Variable.withString(itemId)],
    ).get();
    return rows
        .map(
          (row) => LocalEvidence(
            id: row.data['evidence_id'] as String,
            jobId: row.data['job_id'] as String,
            itemId: row.data['item_id'] as String,
            mimeType: row.data['mime_type'] as String,
            sha256: row.data['sha256'] as String,
            bytes: _blob(row.data['bytes']),
            state: row.data['state'] as String,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              row.data['created_at'] as int,
            ),
          ),
        )
        .toList(growable: false);
  }

  Future<void> markEvidenceReceived(String evidenceId) async {
    await _ensure();
    await db.customStatement(
      'UPDATE evidence_blobs SET state = ? WHERE evidence_id = ?',
      ['RECEIVED', evidenceId],
    );
    await removeOperation('evidence-$evidenceId');
  }

  Future<void> markEvidenceConflict(String evidenceId) async {
    await _ensure();
    await db.customStatement(
      'UPDATE evidence_blobs SET state = ? WHERE evidence_id = ?',
      ['CONFLICT', evidenceId],
    );
  }

  Future<List<SyncOperation>> pendingOperations({String? jobId}) async {
    await _ensure();
    final rows = await db.customSelect(
      'SELECT id, job_id, operation_type, payload, state, attempts, last_error, created_at '
      'FROM sync_operations '
      '${jobId == null ? '' : 'WHERE job_id = ? '}'
      'ORDER BY created_at ASC',
      variables: jobId == null
          ? const []
          : [Variable.withString(jobId)],
    ).get();
    return rows
        .map(
          (row) => SyncOperation(
            id: row.data['id'] as String,
            jobId: row.data['job_id'] as String,
            type: row.data['operation_type'] as String,
            payload:
                jsonDecode(row.data['payload'] as String)
                    as Map<String, dynamic>,
            state: row.data['state'] as String,
            attempts: row.data['attempts'] as int,
            lastError: row.data['last_error'] as String?,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              row.data['created_at'] as int,
            ),
          ),
        )
        .toList(growable: false);
  }

  Future<int> pendingCount() async {
    await _ensure();
    final rows = await db.customSelect(
      'SELECT COUNT(*) AS total FROM sync_operations '
      "WHERE state IN ('PENDING', 'FAILED', 'SYNCING', 'CONFLICT')",
    ).get();
    return rows.first.data['total'] as int;
  }

  Future<void> setOperationState(
    String id,
    String state, {
    String? error,
    int? attempts,
  }) async {
    await _ensure();
    await db.customStatement(
      'UPDATE sync_operations SET state = ?, last_error = ?, '
      'attempts = COALESCE(?, attempts), updated_at = ? WHERE id = ?',
      [state, error, attempts, DateTime.now().millisecondsSinceEpoch, id],
    );
  }

  Future<void> removeOperation(String id) async {
    await _ensure();
    await db.customStatement(
      'DELETE FROM sync_operations WHERE id = ?',
      [id],
    );
  }

  Future<void> _queue({
    required String id,
    required String jobId,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    await _ensure();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.customStatement(
      'INSERT OR REPLACE INTO sync_operations '
      '(id, job_id, operation_type, payload, state, attempts, last_error, created_at, updated_at) '
      "VALUES (?, ?, ?, ?, 'PENDING', 0, NULL, ?, ?)",
      [id, jobId, type, jsonEncode(payload), now, now],
    );
  }

  Future<void> _updateCachedJob(
    String jobId,
    Map<String, dynamic> values,
  ) async {
    final raw = await _get('job:$jobId');
    if (raw == null) {
      return;
    }
    final job = jsonDecode(raw) as Map<String, dynamic>;
    job.addAll(values);
    await _put('job:$jobId', jsonEncode(job));
  }

  Future<void> _updateCachedItem(
    String jobId,
    String itemId, {
    required Map<String, dynamic>? assessment,
    required String syncState,
  }) async {
    final raw = await _get('checklist:$jobId');
    if (raw == null) {
      return;
    }
    final checklist = jsonDecode(raw) as Map<String, dynamic>;
    final items = checklist['items'] as List<dynamic>? ?? <dynamic>[];
    for (final value in items) {
      final item = value as Map<String, dynamic>;
      if (item['inspectionItemId'] == itemId) {
        item['assessment'] = assessment;
        item['syncState'] = syncState;
        break;
      }
    }
    await _put('checklist:$jobId', jsonEncode(checklist));
  }

  Future<void> _put(String key, String value) async {
    await _ensure();
    await db.customStatement(
      'INSERT OR REPLACE INTO local_store (key, value, updated_at) '
      'VALUES (?, ?, ?)',
      [key, value, DateTime.now().millisecondsSinceEpoch],
    );
  }

  Future<String?> _get(String key) async {
    await _ensure();
    final rows = await db.customSelect(
      'SELECT value FROM local_store WHERE key = ?',
      variables: [Variable.withString(key)],
    ).get();
    return rows.isEmpty ? null : rows.first.data['value'] as String;
  }

  Uint8List _blob(Object? value) {
    if (value is Uint8List) {
      return value;
    }
    if (value is List<int>) {
      return Uint8List.fromList(value);
    }
    return Uint8List(0);
  }
}

class DriftOfflineStore extends OfflineStore {
  DriftOfflineStore() : super(OfflineDatabase.production());
}
