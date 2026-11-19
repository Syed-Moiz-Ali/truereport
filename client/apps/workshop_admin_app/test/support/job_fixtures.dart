/// Server payload fixtures for the two workshop job API families.
///
/// Provenance: **derived-from-dto**. There is no reachable server in this
/// environment, so every payload below is copied field-for-field from the
/// server DTOs / controllers and the client mappers, exactly like
/// `docs/data/samples/`. They are honest about what they are: a shape lock, not
/// a captured response. When a live capture exists, replace the body and drop
/// this note.
///
/// Why these exist: every widget test in this app injects `FakeAdminApi`,
/// which builds models from *constructors*. That never exercises `fromJson`, so
/// a server field rename would be invisible until production. The tests in
/// `job_contract_test.dart` build every model from these maps instead. Rename a
/// key here and the test fails on a default value.
///
/// Datetimes are naive `LocalDateTime.toString()` (no offset) except where a
/// test needs an offset; see `docs/api/contracts.md` §B and T1.
library;

/// `JobDto` from `GET /workshop/jobs` (clean / platform_jobs family).
const Map<String, dynamic> cleanJobJson = <String, dynamic>{
  'id': '5c1b9d31-77e4-4a90-8c2f-0a1b2c3d4e5f',
  'reference': 'JOB-2026-0107',
  'status': 'PENDING_REVIEW',
  'reviewStatus': 'NOT_SUBMITTED',
  'publicationStatus': 'UNPUBLISHED',
  'templateVersionId': 'tv-2026-03',
  'templateNameEn': 'Pre-purchase inspection',
  'templateNameAr': 'فحص ما قبل الشراء',
  'templateVersionNo': 3,
  'assignedTechnicianId': '8f3d2c11-7a4b-4f2e-9c88-1d5b6a7e9f01',
  'assignedTechnicianName': 'Karim Ahmed',
  'customerName': 'Rashid Al Mansoori',
  'customerPhone': '+971500000000',
  'customerEmail': 'customer@example.test',
  'vehicleVin': 'WP0ZZZ99ZPS000000',
  'vehicleMake': 'Porsche',
  'vehicleModel': '911 GT3',
  'vehicleYear': 2023,
  'vehiclePlate': 'DXB 48291',
  'odometerValue': 18240,
  'odometerUnit': 'km',
  'transmission': 'PDK',
  'fuelType': 'PETROL',
  'preferredLanguage': 'en',
  'scheduledAt': '2026-11-18T10:00',
  'startedAt': '2026-11-18T10:22',
  'completedAt': '2026-11-18T11:40',
  'approvedAt': null,
  'publishedAt': null,
  'cancelledAt': null,
  'approvedBy': null,
  'cancelledBy': null,
  'cancelReason': null,
  'score': 82,
  'gradeCode': 'B',
  'safetyCapApplied': false,
  'safetyCapReason': null,
  'consentGranted': true,
  'createdAt': '2026-11-16T09:12',
  'updatedAt': '2026-11-18T11:40',
  'version': 7,
};

/// A clean job whose public link was revoked: `REVOKED` is never "live".
final Map<String, dynamic> revokedCleanJobJson = <String, dynamic>{
  ...cleanJobJson,
  'id': 'a1d2c3b4-0000-4a90-8c2f-111111111111',
  'reference': 'JOB-2026-0108',
  'status': 'PUBLISHED',
  'reviewStatus': 'APPROVED',
  'publicationStatus': 'REVOKED',
  'approvedAt': '2026-11-17T12:00',
  'publishedAt': '2026-11-17T13:00',
  'approvedBy': '0b6f8f0e-2b3c-4d5e-8f90-222222222222',
};

/// `JobPageDto { items, page, size, total, totalPages }`.
const Map<String, dynamic> jobPageJson = <String, dynamic>{
  'items': <Map<String, dynamic>>[cleanJobJson],
  'page': 0,
  'size': 10,
  'total': 24,
  'totalPages': 3,
};

/// `JobStatusCountsDto` from `GET /workshop/jobs/counts`.
///
/// Nine mutually exclusive statuses; the fixture is a true partition
/// (`draft+scheduled+assigned+inProgress+pendingReview+approved+published+
/// rejected+cancelled == total`), which is what the dashboard pipeline is
/// allowed to draw.
const Map<String, dynamic> jobStatusCountsJson = <String, dynamic>{
  'draft': 5,
  'scheduled': 2,
  'assigned': 1,
  'inProgress': 3,
  'pendingReview': 4,
  'approved': 2,
  'published': 11,
  'rejected': 1,
  'cancelled': 6,
  'total': 35,
};

/// `CleanJobCounts` is the only counts shape the UI may read. The legacy
/// `JobCountsDto` fixture was removed with the legacy queue family.

/// `AssignmentDto` from `GET /workshop/jobs/{id}/assignments`.
///
/// Ids, not names: `technicianId` / `assignedBy` must be resolved through
/// `staffProvider` before anything human reads them.
const Map<String, dynamic> assignmentJson = <String, dynamic>{
  'id': '4f0e2a11-9c88-4f2e-9c88-333333333333',
  'technicianId': '8f3d2c11-7a4b-4f2e-9c88-1d5b6a7e9f01',
  'assignedBy': '0b6f8f0e-2b3c-4d5e-8f90-222222222222',
  'assignedAt': '2026-11-18T09:15',
  'unassignedAt': null,
  'reason': 'Customer requested the same technician',
};

/// A closed assignment row: every optional field populated.
const Map<String, dynamic> closedAssignmentJson = <String, dynamic>{
  'id': '4f0e2a11-9c88-4f2e-9c88-444444444444',
  'technicianId': '8f3d2c11-7a4b-4f2e-9c88-1d5b6a7e9f01',
  'assignedBy': '0b6f8f0e-2b3c-4d5e-8f90-222222222222',
  'assignedAt': '2026-11-17T08:00',
  'unassignedAt': '2026-11-17T16:30',
  'reason': 'Shift change',
};

/// `ReviewDto` from `GET /workshop/jobs/{id}/review`.
///
/// Two findings so a mapper that drops `findings` or only reads `[0]` fails.
const Map<String, dynamic> reviewJson = <String, dynamic>{
  'jobId': '5c1b9d31-77e4-4a90-8c2f-0a1b2c3d4e5f',
  'status': 'PENDING_REVIEW',
  'itemsAssessed': 2,
  'itemsTotal': 3,
  'scorePreview': 82.5,
  'gradePreview': 'B',
  'safetyCapPreview': 'A',
  'findings': <Map<String, dynamic>>[
    <String, dynamic>{
      'itemVersionId': 'iv-0001',
      'stableCode': 'EXT-001',
      'labelEn': 'Body panel check',
      'labelAr': 'فحص هيكل المركبة',
      'resultCode': 'NO_ISSUE_OBSERVED',
      'score': 100,
      'evidencePhotos': <String>['photo-1'],
      'evidenceVideos': <String>[],
      'signaturePresent': true,
      'completedAt': '2026-11-18T10:40',
      'issueValues': <String, dynamic>{},
    },
    <String, dynamic>{
      'itemVersionId': 'iv-0002',
      'stableCode': 'BRK-001',
      'labelEn': 'Brake pad thickness',
      'labelAr': 'سمك أقمشة الفرامل',
      'resultCode': 'ATTENTION_RECOMMENDED',
      'score': 70,
      'evidencePhotos': <String>['photo-2', 'photo-3'],
      'evidenceVideos': <String>['video-1'],
      'signaturePresent': true,
      'completedAt': '2026-11-18T10:55',
      'issueValues': <String, dynamic>{'THICKNESS': '4.2'},
    },
  ],
};
