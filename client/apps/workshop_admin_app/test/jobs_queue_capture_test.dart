import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/archive/legacy_archive_page.dart';
import 'package:workshop_admin_app/src/features/jobs/jobs_tab.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/jobs_queue_cards.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/jobs_queue_table.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

import 'support/job_builders.dart';

const String _outDir = 'docs/evidence/jobs_j1';

CleanJob _job(
  int index, {
  String status = 'PENDING_REVIEW',
  bool consentGranted = true,
}) => cleanJob(
  overrides: {
    'id': 'job-$index',
    'reference': 'JOB-${index.toString().padLeft(4, '0')}',
    'status': status,
    'reviewStatus': status,
    'publicationStatus': status == 'PUBLISHED' ? 'PUBLISHED' : 'UNPUBLISHED',
    'customerName': 'Customer $index',
    'customerPhone': '+971500000$index',
    'customerEmail': 'customer$index@test.local',
    'vehiclePlate': 'DXB ${10000 + index}',
    'scheduledAt': '2026-11-${index.toString().padLeft(2, '0')}T10:00',
    'assignedTechnicianId': status == 'DRAFT' ? null : 'tech-1',
    'assignedTechnicianName': status == 'DRAFT' ? null : 'Karim Ahmed',
    'consentGranted': consentGranted,
    'version': 3,
  },
);

/// A true partition: the nine counts sum to the list total, so the strip and
/// the footer agree in every unfiltered capture.
const List<(String, int)> _captureSpec = [
  ('DRAFT', 3),
  ('SCHEDULED', 4),
  ('ASSIGNED', 2),
  ('IN_PROGRESS', 3),
  ('PENDING_REVIEW', 4),
  ('APPROVED', 1),
  ('PUBLISHED', 1),
  ('REJECTED', 1),
  ('CANCELLED', 1),
];

/// Job-1 is PENDING_REVIEW: the selected row in the captures carries the full
/// fact set (technician, schedule, template, mileage, review, consent).
List<CleanJob> _captureJobs() {
  final statuses = <String>['PENDING_REVIEW'];
  for (final (status, count) in _captureSpec) {
    final already = statuses.where((value) => value == status).length;
    for (var index = already; index < count; index++) {
      statuses.add(status);
    }
  }
  return [
    for (var index = 0; index < statuses.length; index++)
      _job(index + 1, status: statuses[index]),
  ];
}

class _CaptureApi implements AdminApi {
  _CaptureApi({List<CleanJob>? jobsData, bool empty = false})
    : jobsData = empty ? const [] : (jobsData ?? _captureJobs());

  final List<CleanJob> jobsData;

  @override
  Future<JobPage> cleanJobs({
    int page = 0,
    int size = 20,
    String status = '',
    String search = '',
    String from = '',
    String to = '',
  }) async {
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

  @override
  Future<CleanJob> cleanJob(String id) async =>
      jobsData.firstWhere((job) => job.id == id);

  @override
  Future<List<StaffMember>> staff() async => const [
    StaffMember(
      userId: 'tech-1',
      displayName: 'Karim Ahmed',
      emailMasked: 'k***@test.local',
      role: 'TECHNICIAN',
      status: 'ACTIVE',
    ),
  ];

  @override
  Future<JobReview> jobReview(String jobId) async => JobReview(
    jobId: jobId,
    status: 'PENDING_REVIEW',
    itemsAssessed: 8,
    itemsTotal: 8,
    scorePreview: 82,
    gradePreview: 'B',
    safetyCapPreview: null,
    findings: const [],
  );

  @override
  Future<List<JobAssignment>> jobAssignments(String jobId) async => const [];

  @override
  Future<List<WorkshopJob>> jobs({
    String search = '',
    String status = '',
  }) async => const [
    WorkshopJob(
      id: 'legacy-1',
      reference: 'LEG-0001',
      status: 'IN_PROGRESS',
      templateVersionId: 'version-1',
      templateName: 'Legacy inspection',
      templateVersionNo: 1,
      assignedTechnicianId: 'tech-1',
      assignedTechnicianName: 'Karim Ahmed',
      scheduledAt: '2026-11-05T09:00:00',
      customerName: 'Legacy Customer A',
      customerPhone: '+971500000001',
      customerEmail: 'legacy.a@test.local',
      vehicleMake: 'Toyota',
      vehicleModel: 'Land Cruiser',
      vehicleYear: 2020,
      vehicleVin: 'TESTVIN00000000001',
      vehiclePlate: 'L-100',
      scope: 'Legacy inspection',
    ),
    WorkshopJob(
      id: 'legacy-2',
      reference: 'LEG-0002',
      status: 'FINALIZED',
      templateVersionId: 'version-1',
      templateName: 'Legacy inspection',
      templateVersionNo: 1,
      assignedTechnicianId: null,
      assignedTechnicianName: null,
      scheduledAt: '2026-11-04T09:00:00',
      customerName: 'Legacy Customer B',
      customerPhone: '+971500000002',
      customerEmail: 'legacy.b@test.local',
      vehicleMake: 'Nissan',
      vehicleModel: 'Patrol',
      vehicleYear: 2021,
      vehicleVin: 'TESTVIN00000000002',
      vehiclePlate: 'L-200',
      scope: 'Legacy inspection',
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _ErrorApi extends _CaptureApi {
  @override
  Future<JobPage> cleanJobs({
    int page = 0,
    int size = 20,
    String status = '',
    String search = '',
    String from = '',
    String to = '',
  }) async => throw StateError('queue down');
}

class _LoadingApi extends _CaptureApi {
  final Completer<JobPage> _jobs = Completer<JobPage>();
  final Completer<CleanJobCounts> _counts = Completer<CleanJobCounts>();

  @override
  Future<JobPage> cleanJobs({
    int page = 0,
    int size = 20,
    String status = '',
    String search = '',
    String from = '',
    String to = '',
  }) => _jobs.future;

  @override
  Future<CleanJobCounts> cleanJobCounts() => _counts.future;
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    expect(boundary, isNotNull, reason: name);
    final image = await boundary!.toImage(pixelRatio: 1.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(data, isNotNull, reason: name);
    final dir = Directory(_outDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    File('${dir.path}/$name.png')
        .writeAsBytesSync(data!.buffer.asUint8List(), flush: true);
  });
}

Future<GlobalKey> _pumpQueue(
  WidgetTester tester, {
  required AdminApi api,
  required Size size,
  Locale locale = const Locale('en'),
  bool settle = true,
  bool selectFirst = false,
  double textScale = 1,
}) async {
  final key = GlobalKey();
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
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light,
          home: RepaintBoundary(
            key: key,
            child: Material(
              color: AppTheme.light.scaffoldBackgroundColor,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: const JobsTab(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }
  expect(tester.takeException(), isNull);
  if (selectFirst) {
    await tester.tap(find.byKey(const Key('job-job-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }
  return key;
}

Future<GlobalKey> _pumpArchive(
  WidgetTester tester, {
  required Size size,
}) async {
  final key = GlobalKey();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminApiProvider.overrideWithValue(_CaptureApi())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        home: RepaintBoundary(
          key: key,
          child: Material(
            color: AppTheme.light.scaffoldBackgroundColor,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: const LegacyArchivePage(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return key;
}

void _expectLargeTextCards(WidgetTester tester) {
  final l10n = AppLocalizations.of(tester.element(find.byType(JobsTab)));
  expect(find.byType(JobsQueueTable), findsNothing);
  expect(find.byType(JobsQueueCards), findsOneWidget);
  expect(find.byKey(const Key('jobs-inspector')), findsNothing);
  expect(find.byKey(const Key('jobs-inspector-empty')), findsNothing);
  expect(find.byKey(const Key('jobs-status-row')), findsOneWidget);
  expect(find.byKey(const Key('jobs-search')), findsOneWidget);
  expect(find.byKey(const Key('jobs-new')), findsOneWidget);
  expect(find.byKey(const Key('jobs-queue-more')), findsOneWidget);
  expect(
    find.byKey(const Key('jobs-queue-total'), skipOffstage: false),
    findsOneWidget,
  );

  final action = find.byKey(
    const Key('job-primary-job-1'),
    skipOffstage: false,
  );
  expect(action, findsOneWidget);
  final label = find.descendant(
    of: action,
    matching: find.text(l10n.jobsNextReview, skipOffstage: false),
    skipOffstage: false,
  );
  expect(label, findsOneWidget);
  expect(
    tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
    isFalse,
  );
}

void main() {
  for (final entry in const <String, (Size, bool)>{
    'queue_1440': (Size(1440, 900), true),
    'queue_1280': (Size(1280, 900), true),
    'queue_1024': (Size(1024, 1100), true),
    'queue_768': (Size(768, 1300), true),
    'queue_390': (Size(390, 1600), false),
    'queue_360': (Size(360, 1600), false),
  }.entries) {
    testWidgets(entry.key, (tester) async {
      final key = await _pumpQueue(
        tester,
        api: _CaptureApi(),
        size: entry.value.$1,
        selectFirst: entry.value.$2,
      );
      await _capture(tester, key, entry.key);
    });
  }

  testWidgets('queue_1280_ar', (tester) async {
    final key = await _pumpQueue(
      tester,
      api: _CaptureApi(),
      size: const Size(1280, 900),
      locale: const Locale('ar'),
      selectFirst: true,
    );
    expect(find.text('1/11/2026 10:00'), findsWidgets);
    expect(find.textContaining('1–10'), findsOneWidget);
    expect(find.textContaining(RegExp('[٠-٩۰-۹]')), findsNothing);

    // F9: the scheduled header and cell resolve the same start edge.
    final header = tester.getRect(
      find.byKey(const Key('jobs-header-scheduled')),
    );
    final cell = tester.getRect(find.byKey(const Key('job-scheduled-job-1')));
    expect((header.right - cell.right).abs(), lessThanOrEqualTo(1));
    expect(
      tester
          .widget<Align>(find.byKey(const Key('jobs-header-scheduled')))
          .alignment,
      AlignmentDirectional.centerStart,
    );

    // N3: the inspector reference sits at the RTL start, beside the close.
    final inspector = tester.getRect(find.byKey(const Key('jobs-inspector')));
    final reference = tester.getRect(
      find.byKey(const Key('jobs-inspector-reference')),
    );
    expect(inspector.right - reference.right, lessThanOrEqualTo(20));
    // N4: unit-last mileage in the inspector.
    expect(find.text('18,240 km'), findsOneWidget);
    expect(find.text('km 18,240'), findsNothing);

    await _capture(tester, key, 'queue_1280_ar');
  });

  testWidgets('queue_loading_1280', (tester) async {
    final key = await _pumpQueue(
      tester,
      api: _LoadingApi(),
      size: const Size(1280, 900),
      settle: false,
    );
    await _capture(tester, key, 'queue_loading_1280');
  });

  testWidgets('queue_error_1280', (tester) async {
    final key = await _pumpQueue(
      tester,
      api: _ErrorApi(),
      size: const Size(1280, 900),
    );
    expect(find.byType(WorkshopErrorState), findsOneWidget);
    await _capture(tester, key, 'queue_error_1280');
  });

  testWidgets('queue_empty_1280', (tester) async {
    final key = await _pumpQueue(
      tester,
      api: _CaptureApi(empty: true),
      size: const Size(1280, 900),
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(JobsTab)));
    expect(find.text(l10n.jobsEmptyFirstUseTitle), findsOneWidget);
    expect(find.text(l10n.jobsEmptyFirstUseBody), findsOneWidget);
    await _capture(tester, key, 'queue_empty_1280');
  });

  testWidgets('queue_filtered_1280', (tester) async {
    final key = await _pumpQueue(
      tester,
      api: _CaptureApi(),
      size: const Size(1280, 900),
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(JobsTab)));
    await tester.tap(find.byKey(const Key('jobs-filter-PENDING_REVIEW')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The strip count and the rows agree under the filter.
    expect(find.text('${l10n.jobsCountPendingReview} (4)'), findsOneWidget);
    expect(find.textContaining('1–4'), findsOneWidget);
    expect(find.byKey(const Key('job-job-1')), findsOneWidget);
    expect(find.byKey(const Key('job-job-2')), findsNothing);
    await _capture(tester, key, 'queue_filtered_1280');
  });

  testWidgets('queue_consent_blocked_1280', (tester) async {
    final key = await _pumpQueue(
      tester,
      api: _CaptureApi(
        jobsData: [
          _job(1, status: 'APPROVED', consentGranted: false),
          _job(2, status: 'PENDING_REVIEW'),
          _job(3, status: 'DRAFT'),
        ],
      ),
      size: const Size(1280, 900),
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(JobsTab)));
    await tester.tap(find.byKey(const Key('job-job-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(l10n.jobsPublicationBlocked), findsOneWidget);
    expect(find.text(l10n.jobsPublicationBlockedBody), findsOneWidget);
    expect(
      find.byKey(const Key('job-inspector-publish-checklist')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('job-detail-open')), findsOneWidget);
    expect(find.byKey(const Key('job-detail-more')), findsOneWidget);
    await _capture(tester, key, 'queue_consent_blocked_1280');
  });

  testWidgets('queue_consent_blocked_390', (tester) async {
    final key = await _pumpQueue(
      tester,
      api: _CaptureApi(
        jobsData: [_job(1, status: 'APPROVED', consentGranted: false)],
      ),
      size: const Size(390, 844),
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(JobsTab)));
    expect(tester.takeException(), isNull);
    expect(find.byType(JobsQueueCards), findsOneWidget);
    expect(find.text(l10n.jobsPublicationBlocked), findsOneWidget);
    expect(find.text(l10n.jobsPublicationBlockedBody), findsOneWidget);
    expect(
      find.byKey(const Key('job-card-publish-checklist-job-1')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('job-primary-job-1')), findsNothing);
    await _capture(tester, key, 'queue_consent_blocked_390');
  });

  testWidgets('queue_1440_2x', (tester) async {
    final key = await _pumpQueue(
      tester,
      api: _CaptureApi(),
      size: const Size(1440, 900),
      textScale: 2,
    );
    _expectLargeTextCards(tester);
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'queue_1440_2x');
  });

  testWidgets('queue_1440_15x', (tester) async {
    final key = await _pumpQueue(
      tester,
      api: _CaptureApi(),
      size: const Size(1440, 900),
      textScale: 1.5,
    );
    _expectLargeTextCards(tester);
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'queue_1440_15x');
  });

  testWidgets('queue_1024_2x', (tester) async {
    final key = await _pumpQueue(
      tester,
      api: _CaptureApi(),
      size: const Size(1024, 900),
      textScale: 2,
    );
    _expectLargeTextCards(tester);
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'queue_1024_2x');
  });

  testWidgets('queue_390_2x', (tester) async {
    final key = await _pumpQueue(
      tester,
      api: _CaptureApi(),
      size: const Size(390, 1600),
      textScale: 2,
    );
    _expectLargeTextCards(tester);
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'queue_390_2x');
  });

  testWidgets('queue_filtered_empty_1280', (tester) async {
    final key = await _pumpQueue(
      tester,
      api: _CaptureApi(),
      size: const Size(1280, 900),
    );
    await tester.enterText(find.byKey(const Key('jobs-search')), 'no such job');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final l10n = AppLocalizations.of(tester.element(find.byType(JobsTab)));
    expect(find.text(l10n.jobsNoJobsInView), findsOneWidget);
    await _capture(tester, key, 'queue_filtered_empty_1280');
  });

  testWidgets('archive_1280', (tester) async {
    final key = await _pumpArchive(tester, size: const Size(1280, 900));
    await _capture(tester, key, 'archive_1280');
  });
}
