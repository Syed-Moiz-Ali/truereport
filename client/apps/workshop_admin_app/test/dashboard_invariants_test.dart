import 'dart:io';

import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_tab.dart';
import 'package:workshop_admin_app/src/features/home/workshop_admin_home.dart';
import 'package:workshop_admin_app/src/features/jobs/job_detail_page.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Behaviour contract for the rebuilt dashboard (direction B "The floor").
///
/// These tests pin *behaviour*, not widgets: what the page must say, never say,
/// and what it must do. Structural assertions live in `dashboard_test.dart`.
///
/// Truth rules under test (docs/invariants.md J2/J11/J19/J20/J21):
/// - counts come from the counts endpoint and nothing is derived from the list;
/// - a failure renders no number;
/// - the partition is the nine real buckets, plus an explicit remainder;
/// - the page opens the clean-world job surface, never the legacy family.
void main() {
  // ---------------------------------------------------------------------------
  // Fixtures — deliberately unequal bucket sizes so a wrong mapping shows up.
  // ---------------------------------------------------------------------------
  const counts24 = CleanJobCounts(
    draft: 1,
    scheduled: 4,
    assigned: 3,
    inProgress: 5,
    pendingReview: 4,
    approved: 2,
    published: 3,
    rejected: 1,
    cancelled: 1,
    total: 24,
  );

  CleanJob job({
    required String id,
    required String status,
    String make = 'Toyota',
    String model = 'Land Cruiser',
    String customer = 'Customer A',
    String? technician = 'Rashid K.',
    String reference = 'JOB-10482',
  }) => CleanJob(
    id: id,
    reference: reference,
    status: status,
    reviewStatus: status,
    publicationStatus: 'NOT_PUBLISHED',
    templateVersionId: 'version-1',
    templateNameEn: 'Full inspection',
    templateNameAr: 'فحص شامل',
    templateVersionNo: 1,
    assignedTechnicianId: technician == null ? null : 'tech-1',
    assignedTechnicianName: technician,
    customerName: customer,
    customerPhone: '+971500000100',
    customerEmail: 'jobs@test.local',
    vehicleVin: 'TESTVIN00000000002',
    vehicleMake: make,
    vehicleModel: model,
    vehicleYear: 2022,
    vehiclePlate: 'A12345',
    odometerValue: 45000,
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
    createdAt: '2026-11-04T08:00:00',
    updatedAt: '2026-11-05T10:00:00',
    version: 1,
  );

  final defaultJobs = <CleanJob>[
    job(
      id: 'job-1',
      status: 'PENDING_REVIEW',
      model: 'Patrol',
      customer: 'Ahmed Al Mansoori',
    ),
    job(
      id: 'job-2',
      status: 'IN_PROGRESS',
      make: 'Mercedes',
      model: 'G 63',
      technician: 'Mohan D.',
    ),
    job(
      id: 'job-3',
      status: 'APPROVED',
      make: 'Porsche',
      model: 'Macan',
      technician: null,
    ),
  ];

  Future<void> pumpHome(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    double textScale = 1,
    Size size = const Size(1280, 900),
    AdminApi? api,
    bool withSession = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer(
      overrides: [
        adminApiProvider.overrideWithValue(
          api ?? _FakeCleanApi(counts: counts24, fixtures: defaultJobs),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child ?? const SizedBox.shrink(),
          ),
          home: const WorkshopAdminHomePage(),
        ),
      ),
    );
    if (withSession) {
      container.read(authControllerProvider.notifier).state =
          const AsyncData<Session?>(_session);
    }
    await tester.pumpAndSettle();
  }

  // ---------------------------------------------------------------------------
  // The partition
  // ---------------------------------------------------------------------------

  testWidgets('total and the nine real buckets reach the page', (tester) async {
    await pumpHome(tester);
    expect(tester.takeException(), isNull);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(WorkshopAdminHomePage)),
    );

    // The hero total comes from the counts endpoint.
    expect(find.text('24'), findsWidgets);
    expect(find.text(l10n.dashFloorLabel), findsOneWidget);
    expect(find.text(l10n.dashDecisionWaiting(4)), findsOneWidget);

    // All nine labelled buckets exist, each with its own count.
    for (final status in const [
      'DRAFT',
      'SCHEDULED',
      'ASSIGNED',
      'IN_PROGRESS',
      'PENDING_REVIEW',
      'APPROVED',
      'PUBLISHED',
      'REJECTED',
      'CANCELLED',
    ]) {
      expect(
        find.byKey(Key('dashboard-legend-$status')),
        findsOneWidget,
        reason: 'segment $status must be drawn',
      );
    }
    // No remainder when the buckets already sum to the total.
    expect(find.text(l10n.dashSegmentOther), findsNothing);
  });

  testWidgets('an unaccounted total renders an explicit Other tail', (
    tester,
  ) async {
    // 24 accounted + 2 jobs whose status the client does not know.
    await pumpHome(
      tester,
      api: _FakeCleanApi(
        counts: const CleanJobCounts(
          draft: 1,
          scheduled: 4,
          assigned: 3,
          inProgress: 5,
          pendingReview: 4,
          approved: 2,
          published: 3,
          rejected: 1,
          cancelled: 1,
          total: 26,
        ),
        fixtures: defaultJobs,
      ),
    );
    expect(tester.takeException(), isNull);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(WorkshopAdminHomePage)),
    );
    expect(
      find.byKey(const Key('dashboard-segment-__other__')),
      findsOneWidget,
    );
    expect(find.text(l10n.dashSegmentOther), findsOneWidget);
    expect(find.text('26'), findsWidgets);
  });

  // ---------------------------------------------------------------------------
  // Failures never invent a number
  // ---------------------------------------------------------------------------

  testWidgets('a counts failure shows no number and keeps the lists', (
    tester,
  ) async {
    await pumpHome(
      tester,
      api: _FakeCleanApi(
        counts: counts24,
        fixtures: defaultJobs,
        countsError: true,
      ),
    );
    expect(tester.takeException(), isNull);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(WorkshopAdminHomePage)),
    );

    expect(find.text(l10n.commonLoadFailed), findsOneWidget);
    expect(find.text(l10n.retryAction), findsOneWidget);
    // No numeral and no atlas, because the counts endpoint failed.
    expect(find.text('24'), findsNothing);
    expect(find.byKey(const Key('dashboard-atlas')), findsNothing);
    expect(find.byKey(const Key('dashboard-segment-DRAFT')), findsNothing);
    // The lists are independent and must still be there.
    expect(find.text('Toyota Patrol'), findsOneWidget);
  });

  testWidgets('one failing group does not hide the others', (tester) async {
    await pumpHome(
      tester,
      api: _FakeCleanApi(
        counts: counts24,
        fixtures: defaultJobs,
        jobsErrorStatus: 'PENDING_REVIEW',
      ),
    );
    expect(tester.takeException(), isNull);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(WorkshopAdminHomePage)),
    );
    // The failing group shows a bounded error…
    expect(find.text(l10n.commonLoadFailed), findsOneWidget);
    // …while the other two still list their rows.
    expect(find.text('Mercedes G 63'), findsOneWidget);
    expect(find.text('Porsche Macan'), findsOneWidget);
    // Counts are unaffected.
    expect(find.text('24'), findsWidgets);
  });

  // ---------------------------------------------------------------------------
  // Empty workshop
  // ---------------------------------------------------------------------------

  testWidgets('an empty workshop shows one state and no atlas', (tester) async {
    await pumpHome(
      tester,
      api: _FakeCleanApi(
        counts: const CleanJobCounts(
          draft: 0,
          scheduled: 0,
          assigned: 0,
          inProgress: 0,
          pendingReview: 0,
          approved: 0,
          published: 0,
          rejected: 0,
          cancelled: 0,
          total: 0,
        ),
        fixtures: const [],
      ),
    );
    expect(tester.takeException(), isNull);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(WorkshopAdminHomePage)),
    );
    expect(find.text(l10n.dashFloorEmpty), findsOneWidget);
    expect(find.text(l10n.dashFloorEmptyBody), findsOneWidget);
    expect(find.byKey(const Key('dashboard-atlas')), findsNothing);
    // One primary action, still available.
    expect(find.text(l10n.newJob), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Interaction
  // ---------------------------------------------------------------------------

  testWidgets('a group row opens the clean job detail page', (tester) async {
    await pumpHome(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('dashboard-job-waiting-job-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(JobDetailPage), findsOneWidget);
  });

  testWidgets('the page exposes exactly one primary action', (tester) async {
    await pumpHome(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(WorkshopAdminHomePage)),
    );
    // "New job" appears once on the page (the shell has its own account menu,
    // not a create action).
    expect(find.text(l10n.newJob), findsOneWidget);
    expect(find.text(l10n.dashReviewVerb), findsWidgets);
  });

  testWidgets('no legacy mutation controls exist on the dashboard', (
    tester,
  ) async {
    await pumpHome(tester);
    for (final label in const ['Assign', 'Cancel job', 'Reassign']) {
      expect(find.text(label), findsNothing);
    }
  });

  // ---------------------------------------------------------------------------
  // Locale, direction, session
  // ---------------------------------------------------------------------------

  testWidgets('without a session the shell falls back to the role title', (
    tester,
  ) async {
    await pumpHome(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(WorkshopAdminHomePage)),
    );
    // The identity strip names the workshop; with no session it falls back to
    // the generic workshop title rather than showing an empty strip.
    expect(find.text(l10n.workshopAdminTitle), findsOneWidget);
  });

  testWidgets('with a session the shell names the workshop once', (
    tester,
  ) async {
    await pumpHome(tester, withSession: true);
    expect(find.text('Marina Workshop'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Layout matrix — no overflow at any width or scale
  // ---------------------------------------------------------------------------

  for (final locale in const [Locale('en')]) {
    for (final scale in const [1.0, 1.5, 2.0]) {
      for (final entry in const {
        'phone-360': Size(360, 800),
        'phone-390': Size(390, 844),
        'tablet-768': Size(768, 900),
        'desktop-1024': Size(1024, 800),
        'desktop-1280': Size(1280, 900),
        'desktop-1440': Size(1440, 900),
      }.entries) {
        testWidgets('no overflow ${locale.languageCode} x$scale ${entry.key}', (
          tester,
        ) async {
          await pumpHome(
            tester,
            locale: locale,
            textScale: scale,
            size: entry.value,
          );
          expect(tester.takeException(), isNull);
          await tester.drag(
            find.byType(CustomScrollView).first,
            const Offset(0, -600),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets(
    'a group with nothing in it prints no count above the empty line',
    (tester) async {
      // Counts say 4 pending; the filtered list is empty. Both can be true (a
      // race, or a permission boundary) and printing them together reads as a
      // contradiction, so the group drops the count.
      await pumpHome(
        tester,
        api: _FakeCleanApi(counts: counts24, fixtures: const []),
      );
      expect(tester.takeException(), isNull);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(WorkshopAdminHomePage)),
      );
      expect(find.text(l10n.dashGroupCountPending(4)), findsNothing);
      expect(find.text(l10n.dashGroupCountInBay(5)), findsNothing);
      expect(find.text(l10n.dashGroupCountReady(2)), findsNothing);
      expect(find.text(l10n.dashGroupEmpty), findsNWidgets(3));
      // The counts themselves are still true and still on the page.
      expect(find.text('24'), findsWidgets);
    },
  );

  test('row meta keeps machine-readable fields in logical order', () {
    final meta = dashboardRowMeta(
      reference: 'JOB-10482',
      customer: 'أحمد المنصوري',
      technician: 'Rashid K.',
      schedule: '2026/11/5 09:00',
    );
    // Reference first, schedule last, separators exactly once. The widget pins
    // the line's base direction to LTR, so this order is what the eye sees even
    // in an RTL build.
    expect(meta, startsWith('JOB-10482 · '));
    expect(meta, endsWith(' · 2026/11/5 09:00'));
    expect(meta, contains('أحمد المنصوري'));
    expect(' · '.allMatches(meta).length, 3);
    expect(dashboardRowMeta(reference: 'JOB-1'), 'JOB-1');
  });

  // ---------------------------------------------------------------------------
  // Source proof: the dashboard folder speaks only the clean family
  // ---------------------------------------------------------------------------

  test('dashboard sources do not reference the legacy job family', () {
    final folder = Directory('lib/src/features/dashboard');
    final files = folder
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    expect(files, isNotEmpty);
    // Word-boundary matches: `JobCounts` must not match `CleanJobCounts`, and a
    // plain substring check would make the rule impossible to satisfy.
    final forbidden = <String, RegExp>{
      'job_counts.dart': RegExp(r'job_counts\.dart'),
      'JobCounts': RegExp(r'\bJobCounts\b'),
      'jobsProvider': RegExp(r'\bjobsProvider\b'),
      'jobCountsProvider': RegExp(r'\bjobCountsProvider\b'),
      'JobListRow': RegExp(r'\bJobListRow\b'),
      'WorkshopJob': RegExp(r'\bWorkshopJob\b'),
      'inspection_jobs': RegExp(r'\binspection_jobs\b'),
      'legacy': RegExp(r'legacy', caseSensitive: false),
    };
    for (final file in files) {
      final text = file.readAsStringSync();
      for (final entry in forbidden.entries) {
        expect(
          entry.value.hasMatch(text),
          isFalse,
          reason: '${file.path} must not reference "${entry.key}"',
        );
      }
    }
  });
}

const _session = Session(
  accessToken: 'token',
  refreshToken: 'refresh',
  user: User(
    id: 'user-1',
    email: 'layla@test.local',
    displayName: 'Layla Haddad',
    platformAdmin: false,
    totpEnabled: false,
  ),
  memberships: [
    Membership(
      workshopId: 'workshop-1',
      workshopName: 'Marina Workshop',
      role: Role.workshopAdmin,
    ),
  ],
);

class _FakeCleanApi implements AdminApi {
  _FakeCleanApi({
    required this.counts,
    required this.fixtures,
    this.countsError = false,
    this.jobsErrorStatus,
  });

  final CleanJobCounts counts;
  final List<CleanJob> fixtures;
  final bool countsError;

  /// When set, `cleanJobs` throws for that status only.
  final String? jobsErrorStatus;

  @override
  Future<CleanJobCounts> cleanJobCounts() async {
    if (countsError) {
      throw StateError('counts failed');
    }
    return counts;
  }

  @override
  Future<JobPage> cleanJobs({
    int page = 0,
    int size = 20,
    String status = '',
    String search = '',
    String from = '',
    String to = '',
  }) async {
    if (jobsErrorStatus != null && status == jobsErrorStatus) {
      throw StateError('jobs failed');
    }
    final filtered = status.isEmpty
        ? fixtures
        : fixtures.where((job) => job.status == status).toList(growable: false);
    final safeSize = size <= 0 ? 20 : size;
    final items = filtered.take(safeSize).toList(growable: false);
    return JobPage(
      items: items,
      page: page,
      size: safeSize,
      total: filtered.length,
      totalPages: filtered.isEmpty ? 0 : (filtered.length / safeSize).ceil(),
    );
  }

  @override
  Future<CleanJob> cleanJob(String id) async =>
      fixtures.firstWhere((job) => job.id == id);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
