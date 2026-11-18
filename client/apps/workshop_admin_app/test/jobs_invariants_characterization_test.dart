import 'dart:convert';
import 'dart:io';

import 'package:api_client/api_client.dart';
import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/job_detail_page.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';
import 'package:workshop_admin_app/src/features/jobs/jobs_tab.dart';
import 'package:workshop_admin_app/src/job_counts.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

import 'support/fake_admin_api.dart';
import 'support/job_fixtures.dart';

/// Engineering-only characterization for the jobs module (Brief 1).
///
/// Every test here pins **today's behaviour** so Wave J1's replacement shows up
/// as a conscious diff. Nothing in `lib/` is changed to make these pass; a real
/// defect is pinned and marked `TODO(invariant-id)`.
///
/// Invariants under test:
/// - **J6** assign/cancel send the job `version`; a stale version surfaces a
///   failure and never silently overwrites (`docs/invariants.md`).
/// - **J10** `REVOKED` is never presented as live; every non-`ACTIVE`
///   publication status reads "Not published".
/// - **D1** the clean-job contract parses the committed samples without loss,
///   preserves unknown enums, and cannot crash on a missing/extra field.
/// - **J3/J5** the queue's chip counts stay client-derived from the
///   search-scoped, status-unfiltered list until they are replaced on purpose.
void main() {
  // ---------------------------------------------------------------------------
  // J6 — lifecycle mutations are optimistic-concurrency guarded
  // ---------------------------------------------------------------------------

  group('J6 — assign/cancel carry the job version', () {
    testWidgets('assign sends the version the page loaded', (tester) async {
      final api = FakeAdminApi(enforceVersions: true);
      await _pumpDetail(tester, api, 'job-1');
      final l10n = _l10n(tester, JobDetailPage);

      await _assignFirstTechnician(tester, l10n);

      expect(api.assignRequests, hasLength(1));
      expect(api.assignRequests.single['jobId'], 'job-1');
      // job-1 is seeded with version 3 in FakeAdminApi.
      expect(api.assignRequests.single['version'], 3);
      // The fake enforces the same guard, so the write was accepted.
      expect(api.statusOf('job-1'), 'ASSIGNED');
      expect(api.versionOf('job-1'), 4);
    });

    testWidgets(
      'a stale version surfaces a failure and does not overwrite the job',
      (tester) async {
        final api = FakeAdminApi(enforceVersions: true);
        await _pumpDetail(tester, api, 'job-1');
        final l10n = _l10n(tester, JobDetailPage);

        // Another client writes after this page loaded; the page still holds 3.
        api.bumpVersion('job-1');
        expect(api.versionOf('job-1'), 4);

        await _assignFirstTechnician(tester, l10n);

        expect(api.assignRequests.single['version'], 3);
        // The conflict is visible, not silent…
        expect(find.text(l10n.commonActionFailed), findsOneWidget);
        // …and the stored job was not moved by the stale write.
        expect(api.statusOf('job-1'), 'PENDING_REVIEW');
        expect(api.versionOf('job-1'), 4);
      },
    );

    test('a stale cancel is rejected without cancelling', () async {
      final api = FakeAdminApi(enforceVersions: true);
      api.bumpVersion('job-1');

      await expectLater(
        api.cancelCleanJob('job-1', 'Stale cancel', version: 3),
        throwsA(isA<FakeVersionConflict>()),
      );

      expect(api.cancelRequests.single['version'], 3);
      expect(api.statusOf('job-1'), 'PENDING_REVIEW');
      expect(api.versionOf('job-1'), 4);
    });

    test('cancel forwards reason + version on the HTTP wire', () async {
      // Pins `HttpAdminApi.cancelCleanJob`: the body carries the version.
      // (`assignCleanJob`'s body is already pinned in job_api_error_test.dart.)
      //
      // `job_widgets.dart` showJobReasonSheet used to dispose its
      // TextEditingController before the exit transition finished (J8). Fixed
      // by moving the controller into the sheet's State; the page-level test
      // above now drives that path.
      String? path;
      Map<String, dynamic>? body;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            path = options.path;
            body = options.data is Map<String, dynamic>
                ? options.data as Map<String, dynamic>
                : null;
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
              ),
            );
          },
        ),
      );
      final api = HttpAdminApi(
        ApiClient(
          config: const ApiConfig(
            baseUrl: 'http://localhost:8080',
            environment: 'test',
          ),
          dio: dio,
        ),
        const ApiEndpoints(baseUrl: 'http://localhost:8080'),
      );

      await expectLater(
        api.cancelCleanJob('job-1', 'Customer cancelled', version: 4),
        throwsA(anything),
      );

      expect(
        path,
        const ApiEndpoints(baseUrl: '').cancelCleanWorkshopJob('job-1'),
      );
      expect(body, {'reason': 'Customer cancelled', 'version': 4});
    });

    testWidgets(
      'cancel from the detail sheet forwards the reason and version',
      (tester) async {
        final api = FakeAdminApi(enforceVersions: true);
        await _pumpDetail(tester, api, 'job-1');
        final l10n = _l10n(tester, JobDetailPage);

        await tester.tap(find.byTooltip(l10n.jobDetailMoreActions).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.cancelJob).last);
        await tester.pumpAndSettle();

        // J8: the sheet owns its controller, so the field survives the route.
        expect(find.text(l10n.jobsCancelReason), findsOneWidget);
        await tester.enterText(
          find.byType(TextField).last,
          'Customer cancelled',
        );
        await tester.tap(find.widgetWithText(AppButton, l10n.cancelJob));
        await tester.pumpAndSettle();

        expect(api.cancelRequests, hasLength(1));
        expect(api.cancelRequests.single['jobId'], 'job-1');
        expect(api.cancelRequests.single['reason'], 'Customer cancelled');
        expect(api.cancelRequests.single['version'], 3);
        expect(api.statusOf('job-1'), 'CANCELLED');
        expect(tester.takeException(), isNull);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // J10 — a revoked public link is never presented as live
  // ---------------------------------------------------------------------------

  group('J10 — publication status mapping', () {
    // Values from the committed derived-from-DTO fixture (job_fixtures.dart).
    final revoked = CleanJob.fromJson(revokedCleanJobJson);

    final cases = <String, String Function(AppLocalizations)>{
      'ACTIVE': (l10n) => l10n.jobsStatusPublished,
      'REVOKED': (l10n) => l10n.linkRevoked,
      'UNPUBLISHED': (l10n) => l10n.notPublished,
      // Anything the server adds later must not read as live either.
      'SUPERSEDED': (l10n) => l10n.notPublished,
    };

    for (final entry in cases.entries) {
      testWidgets('publicationStatus ${entry.key} renders its own label', (
        tester,
      ) async {
        final job = revoked.copyWith(publicationStatus: entry.key);
        final api = _SingleJobApi(job);
        await _pumpDetail(tester, api, job.id);
        final l10n = _l10n(tester, JobDetailPage);

        final fact = find.ancestor(
          of: find.text(l10n.jobsPublicationStatus),
          matching: find.byType(JobFact),
        );
        expect(fact, findsOneWidget);
        expect(
          find.descendant(of: fact, matching: find.text(entry.value(l10n))),
          findsOneWidget,
        );
        if (entry.key != 'ACTIVE') {
          // The trap: a PUBLISHED job whose link was revoked must never show
          // the live "Published" publication label.
          expect(
            find.descendant(
              of: fact,
              matching: find.text(l10n.jobsStatusPublished),
            ),
            findsNothing,
          );
        }
      });
    }
  });

  // ---------------------------------------------------------------------------
  // D1 — clean-job contract from the committed samples
  // ---------------------------------------------------------------------------

  group('clean-job contract — committed docs/data/samples', () {
    test('CleanJob.fromJson maps every field of clean-jobs-page.json', () {
      final body = _sampleBody('clean-jobs-page.json');
      final page = JobPage.fromJson(body);

      expect(page.items, hasLength(1));
      expect(page.page, 0);
      expect(page.size, 10);
      expect(page.total, 24);
      expect(page.totalPages, 3);

      final job = page.items.single;
      expect(job.id, '5c1b9d31-77e4-4a90-8c2f-0a1b2c3d4e5f');
      expect(job.reference, 'JOB-2026-0107');
      expect(job.status, 'PENDING_REVIEW');
      expect(job.reviewStatus, 'NOT_SUBMITTED');
      expect(job.publicationStatus, 'UNPUBLISHED');
      expect(job.templateVersionId, 'tv-2026-03');
      expect(job.templateNameEn, 'Pre-purchase inspection');
      expect(job.templateNameAr, 'فحص ما قبل الشراء');
      expect(job.templateVersionNo, 3);
      expect(job.assignedTechnicianId, '8f3d2c11-7a4b-4f2e-9c88-1d5b6a7e9f01');
      expect(job.assignedTechnicianName, 'Karim Ahmed');
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
      expect(job.scheduledAt, '2026-11-18T10:00');
      expect(job.startedAt, '2026-11-18T10:22');
      expect(job.completedAt, '2026-11-18T11:40');
      expect(job.approvedAt, isNull);
      expect(job.publishedAt, isNull);
      // The sample omits these keys; the mapper defaults them rather than
      // throwing, which is the documented policy.
      expect(job.cancelledAt, isNull);
      expect(job.approvedBy, isNull);
      expect(job.cancelledBy, isNull);
      expect(job.cancelReason, isNull);
      expect(job.score, 82);
      expect(job.gradeCode, 'B');
      expect(job.safetyCapApplied, isFalse);
      expect(job.safetyCapReason, isNull);
      expect(job.consentGranted, isTrue);
      expect(job.createdAt, '2026-11-16T09:12');
      expect(job.updatedAt, '2026-11-18T11:40');
      expect(job.version, 7);

      // No loss: every sampled job key is consumed by the mapper, except the
      // one the wire carries but CleanJob does not model today.
      final sampleJob =
          (body['items'] as List<dynamic>).single as Map<String, dynamic>;
      for (final key in sampleJob.keys) {
        if (key == 'signaturePresent') {
          // TODO(J1): server sends signaturePresent; CleanJob drops it. Pinned
          // as-is — adding it is a lib change, not this brief.
          continue;
        }
        expect(
          _cleanJobKeys,
          contains(key),
          reason: 'sample key "$key" is not mapped by CleanJob',
        );
      }
    });

    test(
      'CleanJobCounts.fromJson maps clean-job-counts.json as a partition',
      () {
        final body = _sampleBody('clean-job-counts.json');
        final counts = CleanJobCounts.fromJson(body);

        expect(counts.draft, 0);
        expect(counts.scheduled, 2);
        expect(counts.assigned, 1);
        expect(counts.inProgress, 3);
        expect(counts.pendingReview, 4);
        expect(counts.approved, 2);
        expect(counts.published, 11);
        expect(counts.rejected, 1);
        expect(counts.cancelled, 0);
        expect(counts.total, 24);

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

        // Every sampled key is a field of the mapper.
        for (final key in body.keys) {
          expect(
            _cleanJobCountKeys,
            contains(key),
            reason: 'sample key "$key" is not mapped by CleanJobCounts',
          );
        }
      },
    );

    test('unknown enum values are preserved, never silently bucketed', () {
      final unknown = CleanJob.fromJson({
        ...cleanJobJson,
        'status': 'AWAITING_PARTS',
        'reviewStatus': 'AWAITING_REVIEW_V2',
        'publicationStatus': 'SUPERSEDED',
      });

      expect(unknown.status, 'AWAITING_PARTS');
      expect(unknown.reviewStatus, 'AWAITING_REVIEW_V2');
      expect(unknown.publicationStatus, 'SUPERSEDED');
      // The mapper is a pass-through; the tone falls back to neutral.
      expect(workshopJobTone(unknown.status), WorkshopStatusTone.neutral);
    });

    test('missing or extra fields cannot crash either mapper', () {
      final bare = CleanJob.fromJson(<String, dynamic>{});
      expect(bare.id, '');
      expect(bare.status, '');
      expect(bare.version, isNull);
      expect(bare.odometerValue, isNull);
      expect(bare.safetyCapApplied, isFalse);

      final extra = CleanJob.fromJson({
        ...cleanJobJson,
        'brandNewServerField': <String, dynamic>{'nested': true},
      });
      expect(extra.id, cleanJobJson['id']);

      // Non-map list entries are dropped, not cast-crashed.
      final page = JobPage.fromJson(<String, dynamic>{
        'items': <dynamic>[cleanJobJson, 'not-an-object', 42],
        'page': 0,
        'size': 10,
        'total': 1,
        'totalPages': 1,
      });
      expect(page.items, hasLength(1));

      final counts = CleanJobCounts.fromJson(<String, dynamic>{});
      expect(counts.total, 0);
      expect(counts.published, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // J3/J5 — queue chip counts are legacy client-derived, not the counts endpoint
  // ---------------------------------------------------------------------------

  group('queue counts scope (legacy, pinned until replaced)', () {
    testWidgets(
      'chips derive from the search-scoped list and never call jobCounts()',
      (tester) async {
        final api = _LegacyQueueApi(_queueJobs);
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await tester.pumpWidget(
          ProviderScope(
            overrides: [adminApiProvider.overrideWithValue(api)],
            child: MaterialApp(
              locale: const Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              theme: AppTheme.light,
              home: const Scaffold(body: JobsTab()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The seed list wins, not the 140-total counts endpoint.
        expect(find.text('All (3)'), findsOneWidget);
        expect(find.text('In progress (1)'), findsOneWidget);
        expect(find.text('Ready to finalize (1)'), findsOneWidget);
        expect(find.text('Finalized (1)'), findsOneWidget);
        expect(find.text('All (140)'), findsNothing);
        expect(api.countsCalls, 0);

        // Selecting a status does not rescope the chips.
        await tester.tap(find.text('In progress (1)'));
        await tester.pumpAndSettle();
        expect(find.text('All (3)'), findsOneWidget);
        expect(api.countsCalls, 0);

        // Search does rescope them, while the status filter stays applied.
        await tester.enterText(
          find.byKey(const Key('jobs-search')),
          'Customer B',
        );
        await tester.pumpAndSettle();
        expect(find.text('All (1)'), findsOneWidget);
        expect(find.text('In progress (0)'), findsOneWidget);
        expect(find.text('Ready to finalize (1)'), findsOneWidget);
        expect(api.countsCalls, 0);
      },
    );
  });
}

// -----------------------------------------------------------------------------
// Harness
// -----------------------------------------------------------------------------

AppLocalizations _l10n(WidgetTester tester, Type pageType) =>
    AppLocalizations.of(tester.element(find.byType(pageType)));

Future<void> _pumpDetail(
  WidgetTester tester,
  AdminApi api,
  String jobId,
) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminApiProvider.overrideWithValue(api)],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        home: JobDetailPage(jobId: jobId),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _assignFirstTechnician(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  await tester.tap(find.text(l10n.reassign));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(AppButton, l10n.assign));
  await tester.pumpAndSettle();
}

Map<String, dynamic> _sampleBody(String filename) {
  final file = File('docs/data/samples/$filename');
  expect(
    file.existsSync(),
    isTrue,
    reason: 'committed sample missing: ${file.absolute.path}',
  );
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  // Provenance guard: nothing here may be mistaken for a live capture.
  expect(decoded['provenance'], 'derived-from-dto');
  return decoded['body'] as Map<String, dynamic>;
}

/// Every DTO key [CleanJob.fromJson] reads.
const Set<String> _cleanJobKeys = <String>{
  'id',
  'reference',
  'status',
  'reviewStatus',
  'publicationStatus',
  'templateVersionId',
  'templateNameEn',
  'templateNameAr',
  'templateVersionNo',
  'assignedTechnicianId',
  'assignedTechnicianName',
  'customerName',
  'customerPhone',
  'customerEmail',
  'vehicleVin',
  'vehicleMake',
  'vehicleModel',
  'vehicleYear',
  'vehiclePlate',
  'odometerValue',
  'odometerUnit',
  'transmission',
  'fuelType',
  'preferredLanguage',
  'scheduledAt',
  'startedAt',
  'completedAt',
  'approvedAt',
  'publishedAt',
  'cancelledAt',
  'approvedBy',
  'cancelledBy',
  'cancelReason',
  'score',
  'gradeCode',
  'safetyCapApplied',
  'safetyCapReason',
  'consentGranted',
  'createdAt',
  'updatedAt',
  'version',
};

/// Every DTO key [CleanJobCounts.fromJson] reads.
const Set<String> _cleanJobCountKeys = <String>{
  'draft',
  'scheduled',
  'assigned',
  'inProgress',
  'pendingReview',
  'approved',
  'published',
  'rejected',
  'cancelled',
  'total',
};

/// Detail page backed by one job, used to pin the publication-status branch.
class _SingleJobApi extends FakeAdminApi {
  _SingleJobApi(this.job);

  final CleanJob job;

  @override
  Future<CleanJob> cleanJob(String id) async => job;
}

/// Legacy queue fake: the list endpoint is real, the counts endpoint is a trap.
class _LegacyQueueApi implements AdminApi {
  _LegacyQueueApi(this._jobs);

  final List<WorkshopJob> _jobs;
  int countsCalls = 0;

  @override
  Future<List<WorkshopJob>> jobs({
    String search = '',
    String status = '',
  }) async {
    final query = search.trim().toLowerCase();
    return _jobs
        .where((job) {
          if (status.isNotEmpty && job.status != status) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          return [
            job.reference,
            job.customerName,
            job.vehicleMake,
            job.vehicleModel,
            job.assignedTechnicianName ?? '',
          ].any((field) => field.toLowerCase().contains(query));
        })
        .toList(growable: false);
  }

  @override
  Future<JobCounts> jobCounts() async {
    countsCalls++;
    // Deliberately different from the list below: if a chip ever reads this,
    // the assertions fail loudly.
    return const JobCounts(
      draft: 10,
      scheduled: 24,
      newScheduled: 34,
      assigned: 14,
      inProgress: 9,
      readyToFinalize: 45,
      finalized: 60,
      finalizedToday: 56,
      cancelled: 3,
      total: 140,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const List<WorkshopJob> _queueJobs = [
  WorkshopJob(
    id: 'job-1',
    reference: 'JOB-0001',
    status: 'IN_PROGRESS',
    templateVersionId: 'version-1',
    templateName: 'Full inspection',
    templateVersionNo: 1,
    assignedTechnicianId: 'tech-1',
    assignedTechnicianName: 'Technician A',
    scheduledAt: '2026-11-05T09:00:00',
    customerName: 'Customer A',
    customerPhone: '+971500000001',
    customerEmail: 'customer.a@test.local',
    vehicleMake: 'Toyota',
    vehicleModel: 'Camry',
    vehicleYear: 2022,
    vehicleVin: 'TESTVIN00000000001',
    vehiclePlate: 'A12345',
    scope: 'Full inspection',
  ),
  WorkshopJob(
    id: 'job-2',
    reference: 'JOB-0002',
    status: 'READY_TO_FINALIZE',
    templateVersionId: 'version-1',
    templateName: 'Full inspection',
    templateVersionNo: 1,
    assignedTechnicianId: 'tech-1',
    assignedTechnicianName: 'Technician A',
    scheduledAt: '2026-11-05T10:00:00',
    customerName: 'Customer B',
    customerPhone: '+971500000002',
    customerEmail: 'customer.b@test.local',
    vehicleMake: 'Honda',
    vehicleModel: 'Civic',
    vehicleYear: 2023,
    vehicleVin: 'TESTVIN00000000002',
    vehiclePlate: 'B67890',
    scope: 'Full inspection',
  ),
  WorkshopJob(
    id: 'job-3',
    reference: 'JOB-0003',
    status: 'FINALIZED',
    templateVersionId: 'version-1',
    templateName: 'Full inspection',
    templateVersionNo: 1,
    assignedTechnicianId: null,
    assignedTechnicianName: null,
    scheduledAt: '2026-11-04T09:00:00',
    customerName: 'Customer C',
    customerPhone: '+971500000003',
    customerEmail: 'customer.c@test.local',
    vehicleMake: 'Ford',
    vehicleModel: 'Transit',
    vehicleYear: 2021,
    vehicleVin: 'TESTVIN00000000003',
    vehiclePlate: 'C13579',
    scope: 'Full inspection',
  ),
];
