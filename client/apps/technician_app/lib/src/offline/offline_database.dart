import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

class OfflineDatabase extends GeneratedDatabase {
  OfflineDatabase(super.executor);

  factory OfflineDatabase.production() => OfflineDatabase(
    driftDatabase(
      name: 'truereport_offline',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await customStatement(
        'CREATE TABLE IF NOT EXISTS local_store ('
        'key TEXT PRIMARY KEY NOT NULL, '
        'value TEXT NOT NULL, '
        'updated_at INTEGER NOT NULL)',
      );
      await customStatement(
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
      await customStatement(
        'CREATE TABLE IF NOT EXISTS evidence_blobs ('
        'evidence_id TEXT PRIMARY KEY NOT NULL, '
        'job_id TEXT NOT NULL, '
        'item_id TEXT NOT NULL, '
        'mime_type TEXT NOT NULL, '
        'sha256 TEXT NOT NULL, '
        'bytes BLOB NOT NULL, '
        'state TEXT NOT NULL, '
        'created_at INTEGER NOT NULL, '
        'type TEXT NOT NULL DEFAULT \'PHOTO\', '
        'caption_en TEXT, '
        'caption_ar TEXT, '
        'poster_base64 TEXT, '
        'duration_ms INTEGER, '
        'capture_source TEXT, '
        'device_id TEXT, '
        'width INTEGER, '
        'height INTEGER)',
      );
      await customStatement(
        'CREATE TABLE IF NOT EXISTS guide_blobs ('
        'job_id TEXT NOT NULL, '
        'item_id TEXT NOT NULL, '
        'content_type TEXT NOT NULL, '
        'bytes BLOB NOT NULL, '
        'PRIMARY KEY (job_id, item_id))',
      );
      await customStatement(
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
      await customStatement(
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
      await customStatement(
        'CREATE INDEX IF NOT EXISTS sync_operations_job '
        'ON sync_operations (job_id, state)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS evidence_blobs_item '
        'ON evidence_blobs (job_id, item_id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS sync_conflicts_job '
        'ON sync_conflicts (job_id, state)',
      );
    },
  );
}
