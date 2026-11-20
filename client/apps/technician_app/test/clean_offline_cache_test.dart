import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/offline/offline_database.dart';
import 'package:technician_app/src/offline/offline_store.dart';

void main() {
  late Directory directory;
  late File databaseFile;
  late OfflineStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('truereport_clean_cache');
    databaseFile = File('${directory.path}/offline.sqlite');
    store = OfflineStore(OfflineDatabase(NativeDatabase(databaseFile)));
  });

  tearDown(() async {
    await store.close();
    await directory.delete(recursive: true);
  });

  test('a clean checklist survives reopening for an offline start', () async {
    await store.saveCleanChecklist(_checklist());
    await store.close();

    final reopened = OfflineStore(
      OfflineDatabase(NativeDatabase(databaseFile)),
    );
    final cached = await reopened.loadCleanChecklist('job-1');

    expect(cached, isNotNull);
    expect(cached!.job.reference, 'TR-1');
    expect(cached.serverRevision, 7);
    store = reopened;
  });

  test('jobs pages and server evidence are cached per key', () async {
    await store.saveCleanJobsPage('0:50:', _page());
    await store.saveCleanEvidence('job-1', 'ITEM-1', [_evidence()]);

    final page = await store.loadCleanJobsPage('0:50:');
    final evidence = await store.loadCleanEvidence('job-1', 'ITEM-1');

    expect(page, isNotNull);
    expect(page!.items.single.reference, 'TR-1');
    expect(page.total, 1);
    expect(evidence, isNotNull);
    expect(evidence!.single.status, 'VERIFIED');
  });

  test('queued evidence keeps the real capture timestamp', () async {
    await store.queueEvidence(
      jobId: 'job-1',
      itemId: 'ITEM-1',
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      mimeType: 'image/jpeg',
      sha256: 'a'.padRight(64, 'a'),
      capturedAt: '2026-11-20T10:00:00.000Z',
      clean: true,
    );

    final operations = await store.pendingOperations();
    expect(operations, hasLength(1));
    expect(operations.single.payload['createdAt'], '2026-11-20T10:00:00.000Z');
  });

  test(
    'deleting a local-only capture also clears its sync operation',
    () async {
      final local = await store.queueEvidence(
        jobId: 'job-1',
        itemId: 'ITEM-1',
        bytes: Uint8List.fromList(<int>[1]),
        mimeType: 'image/jpeg',
        sha256: 'a'.padRight(64, 'a'),
        clean: true,
      );
      expect(await store.pendingCount(), 1);

      await store.deleteLocalEvidence(local.id);

      expect(await store.pendingCount(), 0);
      expect(await store.evidenceForItem('job-1', 'ITEM-1'), isEmpty);
    },
  );
}

Checklist _checklist() => Checklist.fromJson({
  'job': {'id': 'job-1', 'reference': 'TR-1'},
  'items': const <dynamic>[],
  'categories': const <dynamic>[],
  'progress': {'completed': 0, 'total': 0},
  'serverRevision': 7,
});

JobSummaryPage _page() => JobSummaryPage.fromJson({
  'items': [
    {'id': 'job-1', 'reference': 'TR-1'},
  ],
  'page': 0,
  'size': 50,
  'total': 1,
  'totalPages': 1,
});

Evidence _evidence() => Evidence.fromJson({
  'id': 'evidence-1',
  'jobId': 'job-1',
  'itemCode': 'ITEM-1',
  'type': 'PHOTO',
  'status': 'VERIFIED',
  'mime': 'image/jpeg',
  'bytes': 3,
  'sha256': 'a'.padRight(64, 'a'),
  'captureSource': 'CAMERA',
  'width': 640,
  'height': 480,
  'posterAvailable': false,
});
