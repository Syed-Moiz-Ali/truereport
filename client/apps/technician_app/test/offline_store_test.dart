import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/offline/offline_database.dart';
import 'package:technician_app/src/offline/offline_store.dart';

void main() {
  late Directory directory;
  late File databaseFile;
  late OfflineStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('truereport_test');
    databaseFile = File('${directory.path}/offline.sqlite');
    store = OfflineStore(OfflineDatabase(NativeDatabase(databaseFile)));
  });

  tearDown(() async {
    await store.close();
    await directory.delete(recursive: true);
  });

  test('cached jobs and checklist survive reopening the database', () async {
    final checklist = _checklist();
    await store.saveJobs([checklist.job]);
    await store.saveChecklist(checklist);
    await store.queueEvidence(
      jobId: 'job-1',
      itemId: 'item-1',
      bytes: Uint8List.fromList([9, 8, 7]),
      mimeType: 'image/jpeg',
      sha256: 'hash',
    );
    await store.close();

    final reopened = OfflineStore(
      OfflineDatabase(NativeDatabase(databaseFile)),
    );
    final jobs = await reopened.loadJobs();
    final cachedChecklist = await reopened.loadChecklist('job-1');
    expect(jobs, hasLength(1));
    expect(jobs!.first.reference, 'TR-001');
    expect(cachedChecklist, isNotNull);
    expect(cachedChecklist!.items.single.stableCode, 'BRAKE-PAD');
    final photos = await reopened.evidenceForItem('job-1', 'item-1');
    expect(photos, hasLength(1));
    expect(photos.single.bytes, [9, 8, 7]);
    store = reopened;
  });

  test('local assessment and photo evidence stay queued until synced', () async {
    await store.saveChecklist(_checklist());
    await store.saveAssessmentLocally(
      jobId: 'job-1',
      itemId: 'item-1',
      body: {
        'baseVersion': 0,
        'clientRevision': 1,
        'resultCode': 'NO_ISSUE_OBSERVED',
      },
      assessment: {
        'id': 'local-item-1',
        'resultCode': 'NO_ISSUE_OBSERVED',
        'clientRevision': 1,
        'serverRevision': 0,
        'version': 0,
      },
    );
    final evidence = await store.queueEvidence(
      jobId: 'job-1',
      itemId: 'item-1',
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      mimeType: 'image/jpeg',
      sha256: 'abc123',
    );

    expect(await store.pendingCount(), 2);
    final cached = await store.loadChecklist('job-1');
    expect(cached!.items.single.syncState, 'LOCAL_ONLY');
    final photos = await store.evidenceForItem('job-1', 'item-1');
    expect(photos, hasLength(1));
    expect(photos.single.id, evidence.id);
    expect(photos.single.bytes, [1, 2, 3, 4]);
  });
}

InspectionChecklist _checklist() {
  return const InspectionChecklist(
    job: TechnicianJob(
      id: 'job-1',
      reference: 'TR-001',
      status: 'IN_PROGRESS',
      version: 1,
      templateVersionId: 'template-1',
      templateName: 'Vehicle check',
      templateVersionNo: 1,
      assignedTechnicianId: 'tech-1',
      assignedTechnicianName: 'Tech',
      scheduledAt: '2026-11-03T10:00:00Z',
      customerName: 'Customer',
      customerPhone: null,
      customerEmail: null,
      vehicleMake: 'Toyota',
      vehicleModel: 'Corolla',
      vehicleYear: 2020,
      vehicleVin: null,
      vehiclePlate: null,
      vehicleType: 'CAR',
      odometerValue: null,
      odometerUnit: 'KM',
      scope: 'FULL',
      startedAt: '2026-11-03T10:01:00Z',
      readyAt: '',
      finalizedAt: '',
    ),
    items: [
      InspectionItem(
        inspectionItemId: 'item-1',
        masterItemVersionId: 'master-1',
        sortOrder: 1,
        stableCode: 'BRAKE-PAD',
        categoryLabelEn: 'Brakes',
        categoryLabelAr: 'Brakes',
        labelEn: 'Brake pads',
        labelAr: 'Brake pads',
        instructionEn: 'Check pads',
        instructionAr: 'Check pads',
        versionNo: 1,
        resultOptions: ['NO_ISSUE_OBSERVED', 'DEFECT_FOUND'],
        severityPolicy: '{}',
        applicability: '{}',
        reasonCodes: [],
        noteRequirement: 'OPTIONAL',
        evidenceRequirement: 'REQUIRED',
        minPhotos: 1,
        equipmentIds: [],
        guideImageId: null,
        sampleData: false,
        assessment: null,
      ),
    ],
    completed: 0,
    total: 1,
  );
}
