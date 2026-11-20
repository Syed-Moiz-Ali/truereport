import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/reference_status.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

import 'support/job_fixtures.dart';

/// Contract tests for the job DTO mappers.
///
/// Every model is built **from JSON**, never from a constructor, so a server
/// field rename shows up as a test failure instead of a blank cell in
/// production. Expectations use values that differ from the mapper defaults
/// (`''`, `null`, `0`, `false`); if a fixture key is renamed the parsed value
/// falls back to the default and the expectation fails.
void main() {
  group('CleanJob.fromJson (platform_jobs JobDto)', () {
    final job = CleanJob.fromJson(cleanJobJson);

    test('identity, status and review/publication sub-state', () {
      expect(job.id, '5c1b9d31-77e4-4a90-8c2f-0a1b2c3d4e5f');
      expect(job.reference, 'JOB-2026-0107');
      expect(job.status, 'PENDING_REVIEW');
      expect(job.reviewStatus, 'NOT_SUBMITTED');
      expect(job.publicationStatus, 'UNPUBLISHED');
      expect(job.version, 7);
    });

    test('template and technician', () {
      expect(job.templateVersionId, 'tv-2026-03');
      expect(job.templateNameEn, 'Pre-purchase inspection');
      expect(job.templateNameAr, 'فحص ما قبل الشراء');
      expect(job.templateVersionNo, 3);
      expect(job.assignedTechnicianId, '8f3d2c11-7a4b-4f2e-9c88-1d5b6a7e9f01');
      expect(job.assignedTechnicianName, 'Karim Ahmed');
    });

    test('customer and vehicle', () {
      expect(job.customerName, 'Rashid Al Mansoori');
      expect(job.customerPhone, '+971500000000');
      expect(job.customerEmail, 'customer@example.test');
      expect(job.vehicleVin, 'WP0ZZZ99ZPS000000');
      expect(job.vehicleMake, 'Porsche');
      expect(job.vehicleModel, '911 GT3');
      expect(job.vehicleYear, 2023);
      expect(job.vehiclePlate, 'DXB 48291');
      expect(job.odometerValue, 18240);
      expect(job.odometerUnit, 'km');
      expect(job.transmission, 'PDK');
      expect(job.fuelType, 'PETROL');
      expect(job.preferredLanguage, 'en');
    });

    test('timestamps are kept verbatim for one display policy', () {
      expect(job.scheduledAt, '2026-11-18T10:00');
      expect(job.startedAt, '2026-11-18T10:22');
      expect(job.completedAt, '2026-11-18T11:40');
      expect(job.approvedAt, isNull);
      expect(job.publishedAt, isNull);
      expect(job.cancelledAt, isNull);
      expect(job.createdAt, '2026-11-16T09:12');
      expect(job.updatedAt, '2026-11-18T11:40');
    });

    test('inspection result, caps and consent', () {
      expect(job.score, 82);
      expect(job.gradeCode, 'B');
      expect(job.safetyCapApplied, isFalse);
      expect(job.safetyCapReason, isNull);
      expect(job.consentGranted, isTrue);
      expect(job.approvedBy, isNull);
      expect(job.cancelledBy, isNull);
      expect(job.cancelReason, isNull);
    });

    test('REVOKED publication is preserved, never mistaken for live', () {
      final revoked = CleanJob.fromJson(revokedCleanJobJson);
      expect(revoked.publicationStatus, 'REVOKED');
      expect(revoked.publicationStatus, isNot('ACTIVE'));
      expect(revoked.status, 'PUBLISHED');
      expect(revoked.approvedBy, '0b6f8f0e-2b3c-4d5e-8f90-222222222222');
      expect(revoked.publishedAt, '2026-11-17T13:00');
    });

    test('unknown status is preserved for the presentation layer', () {
      final unknown = CleanJob.fromJson({
        ...cleanJobJson,
        'status': 'AWAITING_PARTS',
      });
      expect(unknown.status, 'AWAITING_PARTS');
      // Unknown codes fall through to a neutral tone, never a crash.
      expect(
        referenceStatusTone(null, unknown.status),
        WorkshopStatusTone.neutral,
      );
    });

    test('missing optional keys default instead of throwing', () {
      final bare = CleanJob.fromJson(<String, dynamic>{
        'id': 'bare-1',
        'customerName': 'Walk-in',
        'vehicleMake': 'Nissan',
        'vehicleModel': 'Patrol',
      });
      expect(bare.reference, '');
      expect(bare.status, '');
      expect(bare.reviewStatus, '');
      expect(bare.publicationStatus, '');
      expect(bare.scheduledAt, isNull);
      expect(bare.vehiclePlate, isNull);
      expect(bare.odometerValue, isNull);
      expect(bare.templateVersionNo, isNull);
      expect(bare.version, isNull);
      expect(bare.score, isNull);
      expect(bare.safetyCapApplied, isFalse);
      expect(bare.consentGranted, isFalse);
    });

    test('numeric strings and zero are tolerated, not guessed', () {
      final drift = CleanJob.fromJson({
        ...cleanJobJson,
        'version': '9',
        'vehicleYear': '2024',
        'score': 0,
      });
      expect(drift.version, 9);
      expect(drift.vehicleYear, 2024);
      expect(drift.score, 0);
    });

    test('an unparseable date survives so the display layer can fall back', () {
      final broken = CleanJob.fromJson({
        ...cleanJobJson,
        'scheduledAt': 'not-a-date',
      });
      expect(broken.scheduledAt, 'not-a-date');
    });
  });

  group('JobPage.fromJson', () {
    test('maps items plus paging', () {
      final page = JobPage.fromJson(jobPageJson);
      expect(page.items, hasLength(1));
      expect(page.items.single.reference, 'JOB-2026-0107');
      expect(page.page, 0);
      expect(page.size, 10);
      expect(page.total, 24);
      expect(page.totalPages, 3);
    });

    test('an empty page maps to an empty item list, not a placeholder row', () {
      final empty = JobPage.fromJson(<String, dynamic>{
        'items': <dynamic>[],
        'page': 0,
        'size': 10,
        'total': 0,
        'totalPages': 0,
      });
      expect(empty.items, isEmpty);
      expect(empty.total, 0);
    });

    test('a missing items key is empty, never fabricated', () {
      final missing = JobPage.fromJson(<String, dynamic>{'page': 1});
      expect(missing.items, isEmpty);
      expect(missing.page, 1);
      expect(missing.total, 0);
    });
  });

  group('CleanJobCounts.fromJson (JobStatusCountsDto)', () {
    final counts = CleanJobCounts.fromJson(jobStatusCountsJson);

    test('maps all nine statuses and the total', () {
      expect(counts.draft, 5);
      expect(counts.scheduled, 2);
      expect(counts.assigned, 1);
      expect(counts.inProgress, 3);
      expect(counts.pendingReview, 4);
      expect(counts.approved, 2);
      expect(counts.published, 11);
      expect(counts.rejected, 1);
      expect(counts.cancelled, 6);
      expect(counts.total, 35);
    });

    test('the nine statuses are a true partition of the total', () {
      final sum =
          counts.draft +
          counts.scheduled +
          counts.assigned +
          counts.inProgress +
          counts.pendingReview +
          counts.approved +
          counts.published +
          counts.rejected +
          counts.cancelled;
      expect(sum, counts.total);
    });

    test('a missing status counts as zero, never as a derived value', () {
      final sparse = CleanJobCounts.fromJson(<String, dynamic>{
        'pendingReview': 4,
        'total': 4,
      });
      expect(sparse.pendingReview, 4);
      expect(sparse.draft, 0);
      expect(sparse.assigned, 0);
      expect(sparse.published, 0);
      expect(sparse.total, 4);
    });
  });

  group('JobAssignment.fromJson (AssignmentDto carries ids, not names)', () {
    test('maps ids, timestamps and reason', () {
      final assignment = JobAssignment.fromJson(assignmentJson);
      expect(assignment.id, '4f0e2a11-9c88-4f2e-9c88-333333333333');
      expect(assignment.technicianId, '8f3d2c11-7a4b-4f2e-9c88-1d5b6a7e9f01');
      expect(assignment.assignedBy, '0b6f8f0e-2b3c-4d5e-8f90-222222222222');
      expect(assignment.assignedAt, '2026-11-18T09:15');
      expect(assignment.unassignedAt, isNull);
      expect(assignment.reason, 'Customer requested the same technician');
    });

    test('a closed row keeps both timestamps', () {
      final closed = JobAssignment.fromJson(closedAssignmentJson);
      expect(closed.assignedAt, '2026-11-17T08:00');
      expect(closed.unassignedAt, '2026-11-17T16:30');
      expect(closed.reason, 'Shift change');
    });

    test('the DTO exposes no technician name field to lean on', () {
      // Guards against a mapper "fix" that invents `technicianName` locally:
      // names must be resolved through staffProvider, not parsed from here.
      expect(assignmentJson.containsKey('technicianName'), isFalse);
      expect(assignmentJson.containsKey('assignedByName'), isFalse);
    });
  });

  group('JobReview.fromJson + ReviewFinding.fromJson', () {
    final review = JobReview.fromJson(reviewJson);

    test('maps the summary preview', () {
      expect(review.jobId, '5c1b9d31-77e4-4a90-8c2f-0a1b2c3d4e5f');
      expect(review.status, 'PENDING_REVIEW');
      expect(review.itemsAssessed, 2);
      expect(review.itemsTotal, 3);
      expect(review.scorePreview, 82.5);
      expect(review.gradePreview, 'B');
      expect(review.safetyCapPreview, 'A');
    });

    test('maps every finding, preserving order and evidence counts', () {
      expect(review.findings, hasLength(2));
      final first = review.findings.first;
      expect(first.itemVersionId, 'iv-0001');
      expect(first.stableCode, 'EXT-001');
      expect(first.labelEn, 'Body panel check');
      expect(first.labelAr, 'فحص هيكل المركبة');
      expect(first.resultCode, 'NO_ISSUE_OBSERVED');
      expect(first.score, 100);
      expect(first.evidencePhotos, ['photo-1']);
      expect(first.evidenceVideos, isEmpty);
      expect(first.signaturePresent, isTrue);
      expect(first.completedAt, '2026-11-18T10:40');
      expect(first.issueValues, isEmpty);

      final second = review.findings.last;
      expect(second.stableCode, 'BRK-001');
      expect(second.evidencePhotos, ['photo-2', 'photo-3']);
      expect(second.evidenceVideos, ['video-1']);
      expect(second.issueValues, {'THICKNESS': '4.2'});
    });

    test('an empty review maps to zero findings, never a sample row', () {
      final empty = JobReview.fromJson(<String, dynamic>{
        'jobId': 'job-x',
        'status': 'PENDING_REVIEW',
        'findings': <dynamic>[],
      });
      expect(empty.findings, isEmpty);
      expect(empty.itemsAssessed, 0);
      expect(empty.scorePreview, isNull);
    });
  });
}
