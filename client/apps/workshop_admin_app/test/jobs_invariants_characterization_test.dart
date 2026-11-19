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
      final api = _AssignableApi(enforceVersions: true);
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
        final api = _AssignableApi(enforceVersions: true);
        await _pumpDetail(tester, api, 'job-1');
        final l10n = _l10n(tester, JobDetailPage);

        // Another client writes after this page loaded; the page still holds 3.
        api.bumpVersion('job-1');
        expect(api.versionOf('job-1'), 4);

        await _assignFirstTechnician(tester, l10n);

        expect(api.assignRequests.single['version'], 3);
        // F7: the page names the conflict instead of hiding it behind a
        // generic failure.
        expect(find.text(l10n.jobsConflictReload), findsOneWidget);
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
          find.byKey(const Key('job-reason-field')),
          'Customer cancelled',
        );
        await tester.tap(find.byKey(const Key('job-reason-confirm')));
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
      // G-J2/J1a: the job's publication status is authoritative. The stale
      // `ACTIVE` value is not trusted and reads "Not published".
      'PUBLISHED': (l10n) => l10n.jobsStatusPublished,
      'ACTIVE': (l10n) => l10n.notPublished,
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
        if (entry.key != 'PUBLISHED') {
          // The trap: a PUBLISHED job whose link was revoked or stale must
          // never show the live "Published" publication label.
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
  // Queue counts and scope — server-authoritative (replaces the J3/J5 pins)
  // ---------------------------------------------------------------------------

  group('queue counts scope (server counts, server filters)', () {
    testWidgets('status strip reads the counts endpoint, never the page', (
      tester,
    ) async {
      final api = _QueueScriptedApi();
      await _pumpQueue(tester, api);

      // Coherent unfiltered fixture: 36 rows reachable, 36 in the workshop.
      expect(find.text('All (36)'), findsOneWidget);
      expect(find.text('In progress (9)'), findsOneWidget);
      expect(api.countsCalls, 1);

      // A filtered page is 9 rows, but the strip still describes the workshop.
      await tester.tap(find.byKey(const Key('jobs-filter-IN_PROGRESS')));
      await tester.pumpAndSettle();
      expect(api.calls.last.status, 'IN_PROGRESS');
      expect(find.text('All (36)'), findsOneWidget);
      expect(find.text('All (9)'), findsNothing);
      expect(find.textContaining('1–9'), findsOneWidget);
      expect(api.countsCalls, 1);
    });

    testWidgets('status filter is server-side and resets to page 0', (
      tester,
    ) async {
      final api = _QueueScriptedApi();
      await _pumpQueue(tester, api);

      await tester.tap(find.byKey(const Key('jobs-page-next')));
      await tester.pumpAndSettle();
      expect(api.calls.last.page, 1);

      await tester.tap(find.byKey(const Key('jobs-filter-IN_PROGRESS')));
      await tester.pumpAndSettle();
      expect(api.calls.last.status, 'IN_PROGRESS');
      expect(api.calls.last.page, 0);
      expect(find.byKey(const Key('job-job-1')), findsOneWidget);
      expect(find.byKey(const Key('job-job-2')), findsNothing);
    });

    testWidgets('search is server-side and resets to page 0', (tester) async {
      final api = _QueueScriptedApi();
      await _pumpQueue(tester, api);

      await tester.tap(find.byKey(const Key('jobs-page-next')));
      await tester.pumpAndSettle();
      expect(api.calls.last.page, 1);

      await tester.enterText(find.byKey(const Key('jobs-search')), 'JOB-0021');
      await tester.pumpAndSettle();
      expect(api.calls.last.search, 'JOB-0021');
      expect(api.calls.last.page, 0);
      expect(find.byKey(const Key('job-job-21')), findsOneWidget);
    });
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
  // J1a: the single assign sheet is reached from the policy primary action.
  await tester.tap(find.byKey(const Key('job-detail-primary-action')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('assign-confirm')));
  await tester.pumpAndSettle();
}

/// Fake whose loaded job is assignable (J1a removed assign from
/// PENDING_REVIEW, which the base fake seeds for job-1).
class _AssignableApi extends FakeAdminApi {
  _AssignableApi({super.enforceVersions});

  @override
  Future<CleanJob> cleanJob(String id) async =>
      (await super.cleanJob(id)).copyWith(status: 'DRAFT');
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

/// Server-scoped queue fake. The list and the counts endpoint are coherent when
/// unfiltered; a filtered page is where the strip must still show the workshop
/// total, so a client-derived chip fails loudly there.
class _QueueScriptedApi implements AdminApi {
  final List<_QueueCall> calls = <_QueueCall>[];
  int countsCalls = 0;
  final List<CleanJob> _items = _scriptedJobs();

  @override
  Future<JobPage> cleanJobs({
    int page = 0,
    int size = 20,
    String status = '',
    String search = '',
    String from = '',
    String to = '',
  }) async {
    calls.add(_QueueCall(page: page, status: status, search: search));
    final query = search.trim().toLowerCase();
    final filtered = _items
        .where((job) {
          if (status.isNotEmpty && job.status != status) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          return job.reference.toLowerCase().contains(query);
        })
        .toList(growable: false);
    final start = (page * size).clamp(0, filtered.length);
    final end = (start + size).clamp(0, filtered.length);
    return JobPage(
      items: filtered.sublist(start, end),
      page: page,
      size: size,
      total: filtered.length,
      totalPages: filtered.isEmpty ? 0 : (filtered.length / size).ceil(),
    );
  }

  @override
  Future<CleanJobCounts> cleanJobCounts() async {
    countsCalls++;
    int count(String status) =>
        _items.where((job) => job.status == status).length;
    final values = <String, int>{
      'draft': count('DRAFT'),
      'scheduled': count('SCHEDULED'),
      'assigned': count('ASSIGNED'),
      'inProgress': count('IN_PROGRESS'),
      'pendingReview': count('PENDING_REVIEW'),
      'approved': count('APPROVED'),
      'published': count('PUBLISHED'),
      'rejected': count('REJECTED'),
      'cancelled': count('CANCELLED'),
    };
    return CleanJobCounts.fromJson(<String, dynamic>{
      ...values,
      'total': values.values.fold<int>(0, (sum, value) => sum + value),
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const List<(String, int)> _scriptedSpec = [
  ('IN_PROGRESS', 9),
  ('PENDING_REVIEW', 4),
  ('DRAFT', 3),
  ('SCHEDULED', 12),
  ('ASSIGNED', 2),
  ('APPROVED', 1),
  ('PUBLISHED', 2),
  ('REJECTED', 1),
  ('CANCELLED', 2),
];

/// 36 rows whose statuses sum to the workshop total; job-1 is IN_PROGRESS so
/// the filtered flow can assert a row appears and another disappears.
List<CleanJob> _scriptedJobs() {
  final statuses = <String>['IN_PROGRESS', 'PENDING_REVIEW'];
  for (final (status, count) in _scriptedSpec) {
    final already = statuses.where((value) => value == status).length;
    for (var index = already; index < count; index++) {
      statuses.add(status);
    }
  }
  return [
    for (var index = 0; index < statuses.length; index++)
      _queueJob(index + 1, status: statuses[index]),
  ];
}

class _QueueCall {
  const _QueueCall({
    required this.page,
    required this.status,
    required this.search,
  });

  final int page;
  final String status;
  final String search;
}

CleanJob _queueJob(int index, {required String status}) {
  final padded = index.toString().padLeft(4, '0');
  return CleanJob(
    id: 'job-$index',
    reference: 'JOB-$padded',
    status: status,
    reviewStatus: status,
    publicationStatus: 'UNPUBLISHED',
    templateVersionId: 'version-1',
    templateNameEn: 'Full inspection',
    templateNameAr: 'فحص شامل',
    templateVersionNo: 1,
    assignedTechnicianId: 'tech-1',
    assignedTechnicianName: 'Technician A',
    customerName: 'Customer $index',
    customerPhone: '+971500000$index',
    customerEmail: 'customer$index@test.local',
    vehicleVin: 'TESTVIN000000000$index',
    vehicleMake: 'Toyota',
    vehicleModel: 'Camry',
    vehicleYear: 2022,
    vehiclePlate: 'A$padded',
    odometerValue: 12000,
    odometerUnit: 'KM',
    transmission: 'AUTOMATIC',
    fuelType: 'PETROL',
    preferredLanguage: 'en',
    scheduledAt: '2026-11-05T09:00:00',
    startedAt: null,
    completedAt: null,
    approvedAt: null,
    publishedAt: null,
    cancelledAt: null,
    approvedBy: null,
    cancelledBy: null,
    cancelReason: null,
    score: null,
    gradeCode: null,
    safetyCapApplied: false,
    safetyCapReason: null,
    consentGranted: true,
    createdAt: '2026-11-01T08:00',
    updatedAt: '2026-11-01T09:00',
    version: 3,
  );
}

Future<void> _pumpQueue(WidgetTester tester, AdminApi api) async {
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
        home: const Scaffold(body: JobsTab()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}
