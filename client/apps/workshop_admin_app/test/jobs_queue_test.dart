import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/job_detail_page.dart';
import 'package:workshop_admin_app/src/features/jobs/jobs_tab.dart';
import 'package:workshop_admin_app/src/features/jobs/publish_checklist_page.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/jobs_queue_cards.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/jobs_queue_table.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

import 'support/fake_admin_api.dart';
import 'support/job_builders.dart';

class _Call {
  const _Call(this.page, this.size, this.status, this.search);

  final int page;
  final int size;
  final String status;
  final String search;
}

/// A true partition: the nine counts sum to `total`, and an unfiltered page
/// returns exactly `total` rows, so the strip and the footer can never
/// contradict each other by fixture accident.
const List<(String, int)> _statusSpec = [
  ('DRAFT', 3),
  ('SCHEDULED', 12),
  ('ASSIGNED', 2),
  ('IN_PROGRESS', 9),
  ('PENDING_REVIEW', 4),
  ('APPROVED', 1),
  ('PUBLISHED', 2),
  ('REJECTED', 1),
  ('CANCELLED', 2),
];

List<String> _statuses() {
  // job-1/2/3 keep the identities the flow tests rely on.
  final statuses = <String>['DRAFT', 'ASSIGNED', 'PENDING_REVIEW'];
  for (final (status, count) in _statusSpec) {
    final already = statuses.where((value) => value == status).length;
    for (var index = already; index < count; index++) {
      statuses.add(status);
    }
  }
  return statuses;
}

List<CleanJob> _queueJobs() {
  final statuses = _statuses();
  return [
    for (var index = 0; index < statuses.length; index++)
      _job(index + 1, status: statuses[index]),
  ];
}

CleanJob _job(
  int index, {
  String status = 'DRAFT',
  String? scheduledAt,
  bool consentGranted = true,
}) {
  final padded = index.toString().padLeft(4, '0');
  return CleanJob(
    id: 'job-$index',
    reference: 'JOB-$padded',
    status: status,
    reviewStatus: status == 'PENDING_REVIEW'
        ? 'PENDING_REVIEW'
        : 'NOT_SUBMITTED',
    publicationStatus: 'UNPUBLISHED',
    templateVersionId: 'version-1',
    templateNameEn: 'Full inspection',
    templateNameAr: 'فحص شامل',
    templateVersionNo: 1,
    assignedTechnicianId: status == 'DRAFT' ? null : 'tech-1',
    assignedTechnicianName: status == 'DRAFT' ? null : 'Technician A',
    customerName: 'Customer $index',
    customerPhone: '+971500000$index',
    customerEmail: 'customer$index@test.local',
    vehicleVin: 'TESTVIN000000000$index',
    vehicleMake: 'Toyota',
    vehicleModel: 'Camry',
    vehicleYear: 2022,
    vehiclePlate: 'A$padded',
    odometerValue: 12000 + index,
    odometerUnit: 'KM',
    transmission: 'AUTOMATIC',
    fuelType: 'PETROL',
    preferredLanguage: 'en',
    scheduledAt:
        scheduledAt ?? '2026-11-${index.toString().padLeft(2, '0')}T09:00',
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
    consentGranted: consentGranted,
    createdAt: '2026-11-01T08:00',
    updatedAt: '2026-11-01T09:00',
    version: 3,
  );
}

class _QueueApi implements AdminApi {
  _QueueApi({
    List<CleanJob>? jobsData,
    this.countsError,
    this.cancelConflict = false,
  }) : jobsData = jobsData ?? _queueJobs();

  final List<CleanJob> jobsData;
  final Object? countsError;
  final bool cancelConflict;

  /// Derived from the same rows the list serves, so the fixture is coherent by
  /// construction (the real endpoints are expected to agree when unfiltered).
  CleanJobCounts _counts() {
    int count(String status) =>
        jobsData.where((job) => job.status == status).length;
    return cleanCounts(
      draft: count('DRAFT'),
      scheduled: count('SCHEDULED'),
      assigned: count('ASSIGNED'),
      inProgress: count('IN_PROGRESS'),
      pendingReview: count('PENDING_REVIEW'),
      approved: count('APPROVED'),
      published: count('PUBLISHED'),
      rejected: count('REJECTED'),
      cancelled: count('CANCELLED'),
    );
  }

  final List<_Call> calls = [];

  @override
  Future<JobPage> cleanJobs({
    int page = 0,
    int size = 20,
    String status = '',
    String search = '',
    String from = '',
    String to = '',
  }) async {
    calls.add(_Call(page, size, status, search));
    final query = search.trim().toLowerCase();
    final filtered = jobsData
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
            job.vehiclePlate ?? '',
          ].any((field) => field.toLowerCase().contains(query));
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
    if (countsError != null) {
      throw countsError!;
    }
    return _counts();
  }

  @override
  Future<CleanJob> cleanJob(String id) async =>
      jobsData.firstWhere((job) => job.id == id);

  @override
  Future<CleanJob> cancelCleanJob(
    String jobId,
    String reason, {
    int? version,
  }) async {
    if (cancelConflict) {
      throw const FakeVersionConflict('JOB_VERSION_CONFLICT');
    }
    return cleanJob(jobId);
  }

  @override
  Future<List<StaffMember>> staff() async => const [
    StaffMember(
      userId: 'tech-1',
      displayName: 'Technician A',
      emailMasked: 't***@test.local',
      role: 'TECHNICIAN',
      status: 'ACTIVE',
    ),
  ];

  @override
  Future<JobReview> jobReview(String jobId) async => JobReview(
    jobId: jobId,
    status: 'ASSIGNED',
    itemsAssessed: 0,
    itemsTotal: 0,
    scorePreview: null,
    gradePreview: null,
    safetyCapPreview: null,
    findings: const [],
  );

  @override
  Future<List<JobAssignment>> jobAssignments(String jobId) async => const [];

  @override
  Future<PublishChecklist> publishChecklist(String jobId) async =>
      PublishChecklist(
        jobId: jobId,
        ready: false,
        items: const [],
        itemsAssessed: 0,
        itemsTotal: 0,
        score: null,
        gradeCode: null,
        safetyCapApplied: false,
        safetyCapReason: null,
        consentGranted: false,
        signaturePresent: false,
        documentsReady: false,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Unfiltered totals that disagree on purpose: 12 rows reachable, workshop 20.
class _InconsistentApi extends _QueueApi {
  _InconsistentApi()
    : super(
        jobsData: [for (var index = 0; index < 12; index++) _job(index + 1)],
      );

  @override
  Future<CleanJobCounts> cleanJobCounts() async => cleanCounts(draft: 20);
}

class _QueueApp extends StatelessWidget {
  const _QueueApp({required this.locale});

  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      home: const Scaffold(body: JobsTab()),
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  _QueueApi api, {
  Locale locale = const Locale('en'),
  Size size = const Size(1280, 900),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminApiProvider.overrideWithValue(api)],
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: _QueueApp(locale: locale),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('queue renders server totals, the sheet and a counted footer', (
    tester,
  ) async {
    final api = _QueueApi();
    await _pump(tester, api);
    final l10n = AppLocalizations.of(tester.element(find.byType(JobsTab)));

    expect(find.text('Job queue'), findsOneWidget);
    expect(find.byKey(const Key('jobs-search')), findsOneWidget);
    expect(find.text(l10n.jobsWorkshopTotals), findsOneWidget);
    expect(find.text('All (36)'), findsOneWidget);
    expect(find.text('In progress (9)'), findsOneWidget);
    expect(find.text('Pending review (4)'), findsOneWidget);
    expect(find.text('All (24)'), findsNothing);

    expect(find.byKey(const Key('job-job-1')), findsOneWidget);
    expect(find.text('JOB-0001'), findsOneWidget);
    expect(find.text('Toyota Camry'), findsWidgets);
    expect(find.text('Customer 1'), findsOneWidget);
    expect(find.text('Technician A'), findsWidgets);
    expect(find.text('Full inspection · v1'), findsWidgets);
    expect(find.byKey(const Key('jobs-queue-total')), findsOneWidget);
    expect(find.textContaining('1–10'), findsOneWidget);
    expect(find.text(l10n.jobsSortNote), findsWidgets);

    // Legacy vocabulary and derived counts are gone.
    expect(find.textContaining('Ready to finalize'), findsNothing);
    expect(find.textContaining('Finalized'), findsNothing);
    expect(find.textContaining('Submission'), findsNothing);
  });

  testWidgets('status filter is server-side and resets to the first page', (
    tester,
  ) async {
    final api = _QueueApi();
    await _pump(tester, api);

    await tester.tap(find.byKey(const Key('jobs-page-next')));
    await tester.pumpAndSettle();
    expect(api.calls.last.page, 1);
    expect(api.calls.last.status, '');

    await tester.tap(find.byKey(const Key('jobs-filter-PENDING_REVIEW')));
    await tester.pumpAndSettle();
    expect(api.calls.last.status, 'PENDING_REVIEW');
    expect(api.calls.last.page, 0);
    expect(find.byKey(const Key('job-job-3')), findsOneWidget);
    expect(find.byKey(const Key('job-job-1')), findsNothing);
  });

  testWidgets('search is debounced and server-side', (tester) async {
    final api = _QueueApi();
    await _pump(tester, api);
    final before = api.calls.length;

    await tester.enterText(find.byKey(const Key('jobs-search')), 'JOB-0021');
    await tester.pump(const Duration(milliseconds: 100));
    expect(api.calls.length, before);

    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    expect(api.calls.last.search, 'JOB-0021');
    expect(api.calls.last.page, 0);
    expect(find.byKey(const Key('job-job-21')), findsOneWidget);
  });

  testWidgets('pagination uses the server total and clears selection', (
    tester,
  ) async {
    final api = _QueueApi();
    await _pump(tester, api);

    await tester.tap(find.byKey(const Key('job-job-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('jobs-inspector')), findsOneWidget);

    await tester.tap(find.byKey(const Key('jobs-page-next')));
    await tester.pumpAndSettle();
    expect(find.textContaining('11–20'), findsOneWidget);
    expect(find.byKey(const Key('jobs-inspector-empty')), findsOneWidget);

    await tester.tap(find.byKey(const Key('jobs-page-prev')));
    await tester.pumpAndSettle();
    expect(find.textContaining('1–10'), findsOneWidget);
  });

  testWidgets('selecting a row fills the inspector; close clears it', (
    tester,
  ) async {
    final api = _QueueApi();
    await _pump(tester, api);
    final l10n = AppLocalizations.of(tester.element(find.byType(JobsTab)));

    expect(find.byKey(const Key('jobs-inspector-empty')), findsOneWidget);
    expect(find.text(l10n.jobsSelectJob), findsOneWidget);

    await tester.tap(find.byKey(const Key('job-job-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('jobs-inspector')), findsOneWidget);
    expect(find.text('+9715000001'), findsOneWidget);
    expect(find.byKey(const Key('job-detail-primary-action')), findsOneWidget);
    expect(find.byKey(const Key('job-detail-more')), findsOneWidget);

    await tester.tap(find.byKey(const Key('job-detail-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('jobs-inspector-empty')), findsOneWidget);
    expect(find.text(l10n.jobsNoSelection), findsOneWidget);
  });

  testWidgets('a stale cancel shows a reloadable conflict band', (
    tester,
  ) async {
    final api = _QueueApi(cancelConflict: true);
    await _pump(tester, api);
    final l10n = AppLocalizations.of(tester.element(find.byType(JobsTab)));

    await tester.tap(find.byKey(const Key('job-job-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('job-detail-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.cancelJob).last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('job-reason-field')),
      'Customer cancelled',
    );
    await tester.tap(find.byKey(const Key('job-reason-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('jobs-inspector-conflict')), findsOneWidget);
    expect(find.text(l10n.jobsConflictReload), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('jobs-inspector-conflict')),
        matching: find.byIcon(Icons.refresh),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('jobs-inspector-conflict')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone card action opens the job detail', (tester) async {
    final api = _QueueApi(jobsData: [_job(1, status: 'ASSIGNED')]);
    await _pump(tester, api, size: const Size(390, 844));

    expect(find.byKey(const Key('job-job-1')), findsOneWidget);
    expect(find.byKey(const Key('jobs-inspector')), findsNothing);
    await tester.tap(find.byKey(const Key('job-primary-job-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(JobDetailPage), findsOneWidget);
  });

  testWidgets('counts error keeps labels and the sheet, without numbers', (
    tester,
  ) async {
    final api = _QueueApi(countsError: StateError('counts down'));
    await _pump(tester, api);

    expect(find.text('All'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.textContaining('All ('), findsNothing);
    expect(find.byKey(const Key('jobs-counts-retry')), findsOneWidget);
    expect(find.byKey(const Key('job-job-1')), findsOneWidget);
  });

  testWidgets('filtered empty explains and offers clear filters', (
    tester,
  ) async {
    final api = _QueueApi();
    await _pump(tester, api);
    final l10n = AppLocalizations.of(tester.element(find.byType(JobsTab)));

    await tester.enterText(
      find.byKey(const Key('jobs-search')),
      'nothing matches this',
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.jobsNoJobsInView), findsOneWidget);
    expect(find.byKey(const Key('jobs-clear-filters')), findsOneWidget);

    await tester.tap(find.byKey(const Key('jobs-clear-filters')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('job-job-1')), findsOneWidget);
  });

  testWidgets('queue renders in Arabic RTL without exceptions', (tester) async {
    final api = _QueueApi();
    await _pump(tester, api, locale: const Locale('ar'));

    expect(
      Directionality.of(tester.element(find.byType(JobsTab))),
      TextDirection.rtl,
    );
    expect(find.byKey(const Key('job-job-1')), findsOneWidget);
  });

  testWidgets('Arabic queue pins dates and the range to Latin digits', (
    tester,
  ) async {
    final api = _QueueApi();
    await _pump(tester, api, locale: const Locale('ar'));
    final l10n = AppLocalizations.of(tester.element(find.byType(JobsTab)));

    expect(find.text('1/11/2026 09:00'), findsOneWidget);
    expect(find.textContaining('1–10'), findsOneWidget);
    expect(find.text('${l10n.filterAll} (36)'), findsOneWidget);
    expect(find.textContaining(RegExp('[٠-٩۰-۹]')), findsNothing);

    await tester.tap(find.byKey(const Key('job-job-1')));
    await tester.pumpAndSettle();
    expect(find.text('1/11/2026 09:00'), findsWidgets);
    expect(find.textContaining(RegExp('[٠-٩۰-۹]')), findsNothing);
  });

  testWidgets('Arabic phone card pins its scheduled date', (tester) async {
    final api = _QueueApi();
    await _pump(
      tester,
      api,
      locale: const Locale('ar'),
      size: const Size(390, 844),
    );
    expect(find.text('1/11/2026 09:00'), findsOneWidget);
    expect(find.textContaining(RegExp('[٠-٩۰-۹]')), findsNothing);
  });

  testWidgets('phone status strip is one horizontally scrollable row', (
    tester,
  ) async {
    final api = _QueueApi();
    await _pump(tester, api, size: const Size(390, 844));

    final row = find.byKey(const Key('jobs-status-row'));
    expect(row, findsOneWidget);
    expect(tester.getSize(row).height, lessThanOrEqualTo(56));

    await tester.drag(row, const Offset(-1600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('jobs-filter-CANCELLED')));
    await tester.pumpAndSettle();
    expect(api.calls.last.status, 'CANCELLED');
    expect(find.byKey(const Key('jobs-filter-CANCELLED')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('queue has no overflow from 360 to 1440 up to 2.0x', (
    tester,
  ) async {
    for (final size in const [
      Size(360, 800),
      Size(390, 844),
      Size(768, 900),
      Size(1024, 900),
      Size(1280, 800),
      Size(1440, 900),
    ]) {
      for (final scale in const [1.0, 1.5, 2.0]) {
        final api = _QueueApi();
        await _pump(tester, api, size: size, textScale: scale);
        expect(
          tester.takeException(),
          isNull,
          reason: '${size.width} scale $scale',
        );
      }
    }
  });

  testWidgets('unfiltered: the strip total is the footer total', (
    tester,
  ) async {
    await _pump(tester, _QueueApi());

    // Coherent fixture: All (36) and the server page total are the same number.
    expect(find.text('All (36)'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('jobs-queue-total')),
        matching: find.textContaining('of 36'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('filtered: the footer shows the view, the strip the workshop', (
    tester,
  ) async {
    final api = _QueueApi();
    await _pump(tester, api);

    await tester.tap(find.byKey(const Key('jobs-filter-PENDING_REVIEW')));
    await tester.pumpAndSettle();

    expect(find.text('Pending review (4)'), findsOneWidget);
    expect(find.text('All (36)'), findsOneWidget);
    final footer = find.byKey(const Key('jobs-queue-total'));
    expect(
      find.descendant(of: footer, matching: find.textContaining('1–4')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: footer, matching: find.textContaining('of 4')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: footer, matching: find.textContaining('of 36')),
      findsNothing,
    );
  });

  testWidgets('incoherent unfiltered totals are named, not left unexplained', (
    tester,
  ) async {
    await _pump(tester, _InconsistentApi());

    expect(find.text('All (20)'), findsOneWidget);
    final footer = find.byKey(const Key('jobs-queue-total'));
    expect(
      find.descendant(of: footer, matching: find.textContaining('of 12')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: footer,
        matching: find.textContaining('Workshop totals: 20'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: footer, matching: find.textContaining('of 20')),
      findsNothing,
    );
  });

  testWidgets('wide footer shares the sheet start and end edges', (
    tester,
  ) async {
    await _pump(tester, _QueueApi(), size: const Size(1440, 900));
    final sheet = tester.getRect(find.byKey(const Key('jobs-queue-sheet')));
    final footer = tester.getRect(find.byKey(const Key('jobs-queue-total')));

    expect(footer.left, closeTo(sheet.left, 0.5));
    expect(footer.right, closeTo(sheet.right, 0.5));
    expect(footer.top, greaterThanOrEqualTo(sheet.bottom));
  });

  testWidgets('wide inspector shows every decision fact above the action', (
    tester,
  ) async {
    final api = _QueueApi();
    await _pump(tester, api, size: const Size(1280, 900));
    final l10n = AppLocalizations.of(tester.element(find.byType(JobsTab)));

    await tester.tap(find.byKey(const Key('job-job-3')));
    await tester.pumpAndSettle();

    final inspector = find.byKey(const Key('jobs-inspector'));
    final action = tester.getRect(
      find.byKey(const Key('job-detail-primary-action')),
    );
    final inspectorRect = tester.getRect(inspector);
    for (final value in [
      'Technician A',
      '11/3/2026 09:00',
      'Full inspection · v1',
      '12,003 KM',
      l10n.jobsStatusPendingReview,
      l10n.commonYes,
    ]) {
      final fact = find.descendant(of: inspector, matching: find.text(value));
      expect(fact, findsWidgets, reason: value);
      final rect = tester.getRect(fact.last);
      expect(rect.top, greaterThanOrEqualTo(inspectorRect.top), reason: value);
      expect(rect.bottom, lessThanOrEqualTo(action.top), reason: value);
    }
  });

  testWidgets('no-jobs empty state teaches first use, not a filter', (
    tester,
  ) async {
    final api = _QueueApi(jobsData: const []);
    await _pump(tester, api);
    final l10n = AppLocalizations.of(tester.element(find.byType(JobsTab)));

    expect(find.text(l10n.jobsEmptyFirstUseTitle), findsOneWidget);
    expect(find.text(l10n.jobsEmptyFirstUseBody), findsOneWidget);
    expect(find.byKey(const Key('jobs-empty-create')), findsOneWidget);
    expect(find.byKey(const Key('jobs-clear-filters')), findsNothing);
    expect(find.text(l10n.jobsNoJobsInView), findsNothing);
  });

  testWidgets('phone card announces status, schedule and technician once', (
    tester,
  ) async {
    final api = _QueueApi(jobsData: [_job(1, status: 'PENDING_REVIEW')]);
    await _pump(tester, api, size: const Size(390, 844));
    final l10n = AppLocalizations.of(tester.element(find.byType(JobsTab)));

    final handle = tester.ensureSemantics();
    final node = tester.getSemantics(find.byKey(const Key('job-card-job-1')));
    expect(node.label, contains('JOB-0001'));
    expect(node.label, contains('Technician A'));
    expect(node.label, contains('11/1/2026 09:00'));
    expect(node.label, contains(l10n.jobsStatusPendingReview));
    handle.dispose();
  });

  testWidgets('pager ends show a muted label, not a dead button', (
    tester,
  ) async {
    await _pump(tester, _QueueApi());

    expect(
      find.descendant(
        of: find.byKey(const Key('jobs-page-prev')),
        matching: find.byType(WorkshopButton),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('jobs-page-next')),
        matching: find.byType(WorkshopButton),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Arabic scheduled header and cells share the column start', (
    tester,
  ) async {
    await _pump(tester, _QueueApi(), locale: const Locale('ar'));
    final l10n = AppLocalizations.of(tester.element(find.byType(JobsTab)));

    // The header and the data cell both use AlignmentDirectional.centerStart.
    final headerAlign = tester.widget<Align>(
      find.byKey(const Key('jobs-header-scheduled')),
    );
    final cellAlign = tester.widget<Align>(
      find.byKey(const Key('job-scheduled-job-1')),
    );
    expect(headerAlign.alignment, AlignmentDirectional.centerStart);
    expect(cellAlign.alignment, AlignmentDirectional.centerStart);

    final headerAlignRect = tester.getRect(
      find.byKey(const Key('jobs-header-scheduled')),
    );
    final cellAlignRect = tester.getRect(
      find.byKey(const Key('job-scheduled-job-1')),
    );
    // RTL: the column start is the right edge.
    expect(
      (headerAlignRect.right - cellAlignRect.right).abs(),
      lessThanOrEqualTo(1),
    );

    final header = tester.getRect(find.text(l10n.jobsListColumnScheduled));
    final cell = tester.getRect(find.text('1/11/2026 09:00').first);
    expect((header.right - cell.right).abs(), lessThanOrEqualTo(1));
  });

  testWidgets('large text swaps to cards at every width, never a table', (
    tester,
  ) async {
    for (final size in const [Size(1440, 900), Size(1024, 900)]) {
      for (final scale in const [1.5, 2.0]) {
        final api = _QueueApi();
        await _pump(tester, api, size: size, textScale: scale);
        final l10n = AppLocalizations.of(tester.element(find.byType(JobsTab)));
        final label = '${size.width} scale $scale';

        expect(find.byType(JobsQueueTable), findsNothing, reason: label);
        expect(find.byType(JobsQueueCards), findsOneWidget, reason: label);
        expect(find.byKey(const Key('jobs-inspector')), findsNothing);
        expect(
          find.byKey(const Key('jobs-inspector-empty')),
          findsNothing,
          reason: label,
        );
        // The strip, search, New job, archive and pager survive the swap.
        expect(find.byKey(const Key('jobs-status-row')), findsOneWidget);
        expect(find.byKey(const Key('jobs-search')), findsOneWidget);
        expect(find.byKey(const Key('jobs-new')), findsOneWidget);
        expect(find.byKey(const Key('jobs-queue-more')), findsOneWidget);
        expect(
          find.byKey(const Key('jobs-queue-total'), skipOffstage: false),
          findsOneWidget,
        );

        // The policy action label is painted in full, not ellipsized.
        final action = find.byKey(
          const Key('job-primary-job-3'),
          skipOffstage: false,
        );
        expect(action, findsOneWidget, reason: label);
        final text = find.descendant(
          of: action,
          matching: find.text(l10n.jobsNextReview, skipOffstage: false),
          skipOffstage: false,
        );
        expect(text, findsOneWidget, reason: label);
        final paragraph = tester.renderObject<RenderParagraph>(text);
        expect(
          paragraph.didExceedMaxLines,
          isFalse,
          reason: '$label paints "${l10n.jobsNextReview}" in full',
        );
        expect(tester.takeException(), isNull, reason: label);
      }
    }
  });

  testWidgets('table rows keep the 56 px rhythm at 1280/1024/768', (
    tester,
  ) async {
    for (final size in const [
      Size(1280, 900),
      Size(1024, 1100),
      Size(768, 1300),
    ]) {
      await _pump(tester, _QueueApi(), size: size);
      for (final id in ['job-1', 'job-2', 'job-3', 'job-4']) {
        expect(
          tester.getSize(find.byKey(Key('job-$id'))).height,
          56,
          reason: '${size.width} $id',
        );
      }
      // A one-line status badge is what keeps the row at 56.
      for (final id in ['job-1', 'job-3']) {
        final badge = tester.getSize(
          find.descendant(
            of: find.byKey(Key('job-$id')),
            matching: find.byType(WorkshopStatusBadge),
          ),
        );
        expect(
          badge.height,
          lessThanOrEqualTo(32),
          reason: '${size.width} $id',
        );
      }
      if (size.width >= 1100) {
        // The fixed sheet clips its last row; it must read as scrollable.
        expect(find.byKey(const Key('jobs-queue-fade')), findsOneWidget);
      }
    }
  });

  testWidgets('Arabic inspector anchors the reference and the mileage', (
    tester,
  ) async {
    await _pump(tester, _QueueApi(), locale: const Locale('ar'));
    await tester.tap(find.byKey(const Key('job-job-3')));
    await tester.pumpAndSettle();

    final inspector = tester.getRect(find.byKey(const Key('jobs-inspector')));
    final reference = tester.getRect(
      find.byKey(const Key('jobs-inspector-reference')),
    );
    // RTL: the reference sits at the start (right) edge of the identity block.
    expect(inspector.right - reference.right, lessThanOrEqualTo(20));
    expect(inspector.right - reference.right, greaterThanOrEqualTo(12));

    // The mileage keeps unit-last order: "12,003 KM", never "KM 12,003".
    expect(find.text('12,003 KM'), findsOneWidget);
    expect(find.text('KM 12,003'), findsNothing);
  });

  testWidgets('phone header keeps New job and the overflow on one row', (
    tester,
  ) async {
    await _pump(tester, _QueueApi(), size: const Size(390, 844));
    final create = tester.getRect(find.byKey(const Key('jobs-new')));
    final more = tester.getRect(find.byKey(const Key('jobs-queue-more')));

    expect((create.center.dy - more.center.dy).abs(), lessThanOrEqualTo(2));
    expect(create.right, lessThanOrEqualTo(more.left));
    expect(create.width, greaterThan(200));
    expect(more.width, greaterThanOrEqualTo(44));
  });

  testWidgets('phone status strip advertises its sideways scroll', (
    tester,
  ) async {
    await _pump(tester, _QueueApi(), size: const Size(390, 844));
    expect(find.byKey(const Key('jobs-status-more')), findsOneWidget);
    expect(find.byKey(const Key('jobs-status-fade')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360 status strip fades the clipped chip before the chevron', (
    tester,
  ) async {
    await _pump(tester, _QueueApi(), size: const Size(360, 740));
    final fade = tester.getRect(find.byKey(const Key('jobs-status-fade')));
    final chevron = tester.getRect(find.byKey(const Key('jobs-status-more')));
    final row = tester.getRect(find.byKey(const Key('jobs-status-row')));

    expect(fade.height, row.height);
    expect(fade.right, lessThanOrEqualTo(chevron.left));
    expect(chevron.width, lessThanOrEqualTo(18));
    expect(tester.takeException(), isNull);
  });

  testWidgets('consent-blocked inspector keeps checklist, Open job and menu', (
    tester,
  ) async {
    final api = _QueueApi(
      jobsData: [_job(1, status: 'APPROVED', consentGranted: false)],
    );
    await _pump(tester, api, size: const Size(1280, 900));
    final l10n = AppLocalizations.of(tester.element(find.byType(JobsTab)));

    await tester.tap(find.byKey(const Key('job-job-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('jobs-inspector')), findsOneWidget);
    expect(find.text(l10n.jobsPublicationBlocked), findsOneWidget);
    expect(find.text(l10n.jobsPublicationBlockedBody), findsOneWidget);
    expect(
      find.byKey(const Key('job-detail-publication-blocked')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('job-inspector-publish-checklist')),
      findsOneWidget,
    );
    expect(find.text(l10n.jobsViewChecklist), findsOneWidget);
    expect(find.byKey(const Key('job-detail-primary-action')), findsNothing);

    // N10: the record and the menu survive when there is no primary.
    final open = find.byKey(const Key('job-detail-open'));
    expect(open, findsOneWidget);
    expect(find.byKey(const Key('job-detail-more')), findsOneWidget);
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(find.byType(JobDetailPage), findsOneWidget);
  });

  testWidgets('consent-blocked card offers the checklist at 390', (
    tester,
  ) async {
    final api = _QueueApi(
      jobsData: [_job(1, status: 'APPROVED', consentGranted: false)],
    );
    await _pump(tester, api, size: const Size(390, 844));
    final l10n = AppLocalizations.of(tester.element(find.byType(JobsTab)));

    expect(find.byType(JobsQueueTable), findsNothing);
    expect(find.text(l10n.jobsPublicationBlocked), findsOneWidget);
    expect(find.text(l10n.jobsPublicationBlockedBody), findsOneWidget);
    expect(find.byKey(const Key('job-primary-job-1')), findsNothing);

    final checklist = find.byKey(const Key('job-card-publish-checklist-job-1'));
    expect(checklist, findsOneWidget);
    await tester.ensureVisible(checklist);
    await tester.pumpAndSettle();
    await tester.tap(checklist);
    await tester.pumpAndSettle();
    expect(find.byType(PublishChecklistPage), findsOneWidget);
  });

  testWidgets('consent-blocked card offers the checklist at 1440 2x', (
    tester,
  ) async {
    final api = _QueueApi(
      jobsData: [_job(1, status: 'APPROVED', consentGranted: false)],
    );
    await _pump(tester, api, size: const Size(1440, 900), textScale: 2);
    final l10n = AppLocalizations.of(tester.element(find.byType(JobsTab)));

    expect(find.byType(JobsQueueCards), findsOneWidget);
    expect(find.byType(JobsQueueTable), findsNothing);
    expect(find.byKey(const Key('jobs-inspector')), findsNothing);
    expect(find.text(l10n.jobsPublicationBlocked), findsOneWidget);
    expect(find.text(l10n.jobsPublicationBlockedBody), findsOneWidget);

    final checklist = find.byKey(const Key('job-card-publish-checklist-job-1'));
    expect(checklist, findsOneWidget);
    await tester.ensureVisible(checklist);
    await tester.pumpAndSettle();
    await tester.tap(checklist);
    await tester.pumpAndSettle();
    expect(find.byType(PublishChecklistPage), findsOneWidget);
  });
}
