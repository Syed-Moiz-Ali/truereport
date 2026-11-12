import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:technician_app/src/inspection_models.dart';
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
    await _ensureColumns('evidence_blobs', {
      'type': "TEXT NOT NULL DEFAULT 'PHOTO'",
      'caption_en': 'TEXT',
      'caption_ar': 'TEXT',
      'poster_base64': 'TEXT',
      'duration_ms': 'INTEGER',
      'capture_source': 'TEXT',
      'device_id': 'TEXT',
      'width': 'INTEGER',
      'height': 'INTEGER',
    });
    await db.customStatement(
      'CREATE TABLE IF NOT EXISTS dynamic_assessments ('
      'job_id TEXT NOT NULL, '
      'item_code TEXT NOT NULL, '
      'result_code TEXT, '
      'score INTEGER, '
      'issue_values_json TEXT, '
      'measurements_json TEXT, '
      'notes_en TEXT, '
      'notes_ar TEXT, '
      'client_revision INTEGER NOT NULL, '
      'base_version INTEGER NOT NULL, '
      'state TEXT NOT NULL, '
      'data_json TEXT, '
      'evidence_json TEXT, '
      'updated_at INTEGER NOT NULL, '
      'PRIMARY KEY (job_id, item_code))',
    );
    await db.customStatement(
      'CREATE TABLE IF NOT EXISTS sync_conflicts ('
      'id TEXT PRIMARY KEY NOT NULL, '
      'job_id TEXT NOT NULL, '
      'item_code TEXT NOT NULL, '
      'client_revision INTEGER NOT NULL, '
      'server_revision INTEGER NOT NULL, '
      'server_payload_json TEXT, '
      'client_payload_json TEXT, '
      'state TEXT NOT NULL, '
      'created_at INTEGER NOT NULL, '
      'updated_at INTEGER NOT NULL)',
    );
  }

  Future<void> _ensureColumns(String table, Map<String, String> columns) async {
    final rows = await db.customSelect('PRAGMA table_info($table)').get();
    final existing = rows
        .map((row) => row.data['name']?.toString())
        .whereType<String>()
        .toSet();
    for (final entry in columns.entries) {
      if (!existing.contains(entry.key)) {
        await db.customStatement(
          'ALTER TABLE $table ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
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
    await _put('checklist:${checklist.job.id}', jsonEncode(checklist.toJson()));
    await saveJob(checklist.job);
  }

  Future<InspectionChecklist?> loadChecklist(String jobId) async {
    final raw = await _get('checklist:$jobId');
    return raw == null
        ? null
        : InspectionChecklist.fromJson(jsonDecode(raw) as Map<String, dynamic>);
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
    final rows = await db
        .customSelect(
          'SELECT content_type, bytes FROM guide_blobs '
          'WHERE job_id = ? AND item_id = ?',
          variables: [Variable.withString(jobId), Variable.withString(itemId)],
        )
        .get();
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
    String type = 'PHOTO',
    String? captionEn,
    String? captionAr,
    String? posterBase64,
    int? durationMs,
    String? captureSource,
    String? deviceId,
    int? width,
    int? height,
    bool clean = false,
  }) async {
    await _ensure();
    final id = const Uuid().v7();
    final now = DateTime.now();
    await db.customStatement(
      'INSERT INTO evidence_blobs '
      '(evidence_id, job_id, item_id, mime_type, sha256, bytes, state, created_at, '
      'type, caption_en, caption_ar, poster_base64, duration_ms, capture_source, '
      'device_id, width, height) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        id,
        jobId,
        itemId,
        mimeType,
        sha256,
        bytes,
        'PENDING',
        now.millisecondsSinceEpoch,
        type,
        captionEn,
        captionAr,
        posterBase64,
        durationMs,
        captureSource,
        deviceId,
        width,
        height,
      ],
    );
    await _queue(
      id: 'evidence-$id',
      jobId: jobId,
      type: clean ? 'evidence_clean' : 'evidence',
      payload: {
        'evidenceId': id,
        'jobId': jobId,
        'itemId': itemId,
        'itemCode': itemId,
        'mime': mimeType,
        'sha256': sha256,
        'type': type,
        'captionEn': captionEn,
        'captionAr': captionAr,
        'posterBase64': posterBase64,
        'durationMs': durationMs,
        'captureSource': captureSource,
        'deviceId': deviceId,
        'width': width,
        'height': height,
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
      type: type,
      captionEn: captionEn,
      captionAr: captionAr,
      posterBase64: posterBase64,
      durationMs: durationMs,
      captureSource: captureSource,
      deviceId: deviceId,
      width: width,
      height: height,
    );
  }

  Future<List<LocalEvidence>> evidenceForItem(
    String jobId,
    String itemId,
  ) async {
    await _ensure();
    final rows = await db
        .customSelect(
          'SELECT evidence_id, job_id, item_id, mime_type, sha256, bytes, state, '
          'created_at, type, caption_en, caption_ar, poster_base64, duration_ms, '
          'capture_source, device_id, width, height '
          'FROM evidence_blobs WHERE job_id = ? AND item_id = ? '
          'ORDER BY created_at ASC',
          variables: [Variable.withString(jobId), Variable.withString(itemId)],
        )
        .get();
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
            type: row.data['type'] as String? ?? 'PHOTO',
            captionEn: row.data['caption_en'] as String?,
            captionAr: row.data['caption_ar'] as String?,
            posterBase64: row.data['poster_base64'] as String?,
            durationMs: row.data['duration_ms'] as int?,
            captureSource: row.data['capture_source'] as String?,
            deviceId: row.data['device_id'] as String?,
            width: row.data['width'] as int?,
            height: row.data['height'] as int?,
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

  Future<void> saveCleanAssessmentLocally({
    required String jobId,
    required String itemCode,
    required AssessmentRequest request,
    required Map<String, dynamic> assessment,
    String? idempotencyKey,
  }) async {
    await _ensure();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.customStatement(
      'INSERT OR REPLACE INTO dynamic_assessments '
      '(job_id, item_code, result_code, score, issue_values_json, '
      'measurements_json, notes_en, notes_ar, client_revision, base_version, '
      'state, data_json, evidence_json, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        jobId,
        itemCode,
        request.resultCode,
        request.score,
        jsonEncode(
          request.issueValues
              .map((value) => value.toJson())
              .toList(growable: false),
        ),
        jsonEncode(
          request.measurements
              .map((value) => value.toJson())
              .toList(growable: false),
        ),
        request.notesEn,
        request.notesAr,
        request.clientRevision,
        request.baseVersion,
        'LOCAL_ONLY',
        jsonEncode(assessment),
        jsonEncode(assessment['evidence'] ?? const <dynamic>[]),
        now,
      ],
    );
    final key = idempotencyKey ?? const Uuid().v7();
    final mutation = SyncMutation.fromRequest(
      idempotencyKey: key,
      itemCode: itemCode,
      request: request,
    );
    await _queue(
      id: 'assessment-clean-$jobId-$itemCode',
      jobId: jobId,
      type: 'assessment_clean',
      payload: {
        'jobId': jobId,
        'itemCode': itemCode,
        'clientRevision': request.clientRevision,
        'baseVersion': request.baseVersion,
        'mutation': mutation.toJson(),
      },
    );
    await _updateCachedChecklistItem(
      jobId,
      itemCode,
      assessment: assessment,
      syncState: 'LOCAL_ONLY',
    );
  }

  Future<void> markCleanAssessmentReceived({
    required String jobId,
    required String itemCode,
    Map<String, dynamic>? assessment,
  }) async {
    await _ensure();
    if (assessment != null) {
      await db.customStatement(
        'UPDATE dynamic_assessments SET state = ?, data_json = ?, updated_at = ? '
        'WHERE job_id = ? AND item_code = ?',
        [
          'RECEIVED',
          jsonEncode(assessment),
          DateTime.now().millisecondsSinceEpoch,
          jobId,
          itemCode,
        ],
      );
      await _updateCachedChecklistItem(
        jobId,
        itemCode,
        assessment: assessment,
        syncState: 'RECEIVED',
      );
    } else {
      await db.customStatement(
        'UPDATE dynamic_assessments SET state = ?, updated_at = ? '
        'WHERE job_id = ? AND item_code = ?',
        ['RECEIVED', DateTime.now().millisecondsSinceEpoch, jobId, itemCode],
      );
      await _updateCachedChecklistItem(
        jobId,
        itemCode,
        assessment: null,
        syncState: 'RECEIVED',
      );
    }
    await removeOperation('assessment-clean-$jobId-$itemCode');
  }

  Future<void> markCleanAssessmentConflict({
    required String jobId,
    required String itemCode,
  }) async {
    await _ensure();
    await db.customStatement(
      'UPDATE dynamic_assessments SET state = ?, updated_at = ? '
      'WHERE job_id = ? AND item_code = ?',
      ['CONFLICT', DateTime.now().millisecondsSinceEpoch, jobId, itemCode],
    );
    await _updateCachedChecklistItem(
      jobId,
      itemCode,
      assessment: null,
      syncState: 'CONFLICT',
    );
  }

  Future<Map<String, dynamic>?> loadDynamicAssessment(
    String jobId,
    String itemCode,
  ) async {
    await _ensure();
    final rows = await db
        .customSelect(
          'SELECT data_json FROM dynamic_assessments '
          'WHERE job_id = ? AND item_code = ?',
          variables: [
            Variable.withString(jobId),
            Variable.withString(itemCode),
          ],
        )
        .get();
    if (rows.isEmpty) {
      return null;
    }
    final raw = rows.first.data['data_json'] as String?;
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> recordSyncConflict({
    required String jobId,
    required Conflict conflict,
  }) async {
    await _ensure();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.customStatement(
      'INSERT OR REPLACE INTO sync_conflicts '
      '(id, job_id, item_code, client_revision, server_revision, '
      'server_payload_json, client_payload_json, state, created_at, updated_at) '
      "VALUES (?, ?, ?, ?, ?, ?, ?, 'OPEN', ?, ?)",
      [
        'conflict-$jobId-${conflict.itemCode}-${conflict.clientRevision}',
        jobId,
        conflict.itemCode,
        conflict.clientRevision,
        conflict.serverRevision,
        conflict.serverPayloadJson,
        conflict.clientPayloadJson,
        now,
        now,
      ],
    );
  }

  Future<List<SyncConflictRecord>> openConflicts({String? jobId}) async {
    await _ensure();
    final rows = await db
        .customSelect(
          'SELECT id, job_id, item_code, client_revision, server_revision, '
          'server_payload_json, client_payload_json, state, created_at '
          'FROM sync_conflicts '
          "WHERE state = 'OPEN' ${jobId == null ? '' : 'AND job_id = ? '}"
          'ORDER BY created_at ASC',
          variables: jobId == null ? const [] : [Variable.withString(jobId)],
        )
        .get();
    return rows
        .map(
          (row) => SyncConflictRecord(
            id: row.data['id'] as String,
            jobId: row.data['job_id'] as String,
            itemCode: row.data['item_code'] as String,
            clientRevision: row.data['client_revision'] as int,
            serverRevision: row.data['server_revision'] as int,
            serverPayloadJson: row.data['server_payload_json'] as String?,
            clientPayloadJson: row.data['client_payload_json'] as String?,
            state: row.data['state'] as String,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              row.data['created_at'] as int,
            ),
          ),
        )
        .toList(growable: false);
  }

  Future<void> resolveConflict(String id) async {
    await _ensure();
    await db.customStatement(
      'UPDATE sync_conflicts SET state = ?, updated_at = ? WHERE id = ?',
      ['RESOLVED', DateTime.now().millisecondsSinceEpoch, id],
    );
  }

  Future<SyncQueueStatus> syncQueueStatus() async {
    await _ensure();
    final operations = await db
        .customSelect(
          'SELECT '
          "SUM(CASE WHEN state IN ('PENDING', 'SYNCING') THEN 1 ELSE 0 END) AS pending, "
          "SUM(CASE WHEN state = 'FAILED' THEN 1 ELSE 0 END) AS failed, "
          "SUM(CASE WHEN state = 'CONFLICT' THEN 1 ELSE 0 END) AS conflicts "
          'FROM sync_operations',
        )
        .get();
    final data = operations.first.data;
    return SyncQueueStatus(
      pending: (data['pending'] as int?) ?? 0,
      failed: (data['failed'] as int?) ?? 0,
      conflicts: (data['conflicts'] as int?) ?? 0,
    );
  }

  Future<List<SyncOperation>> pendingOperations({String? jobId}) async {
    await _ensure();
    final rows = await db
        .customSelect(
          'SELECT id, job_id, operation_type, payload, state, attempts, last_error, created_at '
          'FROM sync_operations '
          '${jobId == null ? '' : 'WHERE job_id = ? '}'
          'ORDER BY created_at ASC',
          variables: jobId == null ? const [] : [Variable.withString(jobId)],
        )
        .get();
    return rows
        .map(
          (row) => SyncOperation(
            id: row.data['id'] as String,
            jobId: row.data['job_id'] as String,
            type: row.data['operation_type'] as String,
            payload: jsonDecode(
              row.data['payload'] as String,
            ) as Map<String, dynamic>,
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
    final rows = await db
        .customSelect(
          'SELECT COUNT(*) AS total FROM sync_operations '
          "WHERE state IN ('PENDING', 'FAILED', 'SYNCING', 'CONFLICT')",
        )
        .get();
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
    await db.customStatement('DELETE FROM sync_operations WHERE id = ?', [id]);
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

  Future<void> _updateCachedChecklistItem(
    String jobId,
    String itemCode, {
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
      if (item['itemCode'] == itemCode ||
          item['inspectionItemId'] == itemCode) {
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
    final rows = await db
        .customSelect(
          'SELECT value FROM local_store WHERE key = ?',
          variables: [Variable.withString(key)],
        )
        .get();
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
