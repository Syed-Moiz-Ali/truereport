import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/job_counts.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_tab.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';
import 'package:workshop_admin_app/src/features/jobs/jobs_tab.dart';
import 'package:workshop_admin_app/src/features/staff/staff_tab.dart';
import 'package:workshop_admin_app/src/features/templates/templates_tab.dart';
import 'package:workshop_admin_app/src/features/home/workshop_admin_home.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

const _counts = JobCounts(
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

const _jobOpen = WorkshopJob(
  id: 'job-1',
  reference: 'JOB-TEST0001',
  status: 'ASSIGNED',
  templateVersionId: 'version-1',
  templateName: 'Full inspection',
  templateVersionNo: 1,
  assignedTechnicianId: 'tech-1',
  assignedTechnicianName: 'Technician A',
  scheduledAt: '2026-11-05T09:00:00',
  customerName: 'Customer A',
  customerPhone: '+971500000000',
  customerEmail: 'customer@test.local',
  vehicleMake: 'Toyota',
  vehicleModel: 'Camry',
  vehicleYear: 2022,
  vehicleVin: 'TESTVIN00000000001',
  vehiclePlate: 'A12345',
  scope: 'Full inspection',
);

const _jobDone = WorkshopJob(
  id: 'job-2',
  reference: 'JOB-TEST0002',
  status: 'FINALIZED',
  templateVersionId: 'version-1',
  templateName: 'Full inspection',
  templateVersionNo: 1,
  assignedTechnicianId: null,
  assignedTechnicianName: null,
  scheduledAt: '2026-11-04T09:00:00',
  customerName: 'Customer B',
  customerPhone: null,
  customerEmail: null,
  vehicleMake: 'Toyota',
  vehicleModel: 'Corolla',
  vehicleYear: 2021,
  vehicleVin: 'TESTVIN00000000002',
  vehiclePlate: 'B67890',
  scope: 'Full inspection',
);

class _FakeDashboardApi implements AdminApi {
  _FakeDashboardApi({
    this.countsError = false,
    this.jobList = const [_jobOpen, _jobDone],
    this.jobsError = false,
  });

  final bool countsError;
  final List<WorkshopJob> jobList;
  final bool jobsError;

  @override
  Future<JobCounts> jobCounts() async {
    if (countsError) {
      throw StateError('counts failed');
    }
    return _counts;
  }

  @override
  Future<List<WorkshopJob>> jobs({
    String search = '',
    String status = '',
  }) async {
    if (jobsError) {
      throw StateError('jobs failed');
    }
    return jobList;
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
  Future<List<TemplateSummary>> templates() async => const [
    TemplateSummary(
      id: 'template-1',
      name: 'Full inspection',
      serviceType: 'FULL',
      vehicleType: 'CAR',
      status: 'PUBLISHED',
      currentVersion: 1,
      itemCount: 1,
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Harness extends ConsumerStatefulWidget {
  const _Harness({
    required this.home,
    required this.locale,
    this.textScale = 1,
  });

  final Widget home;
  final Locale locale;
  final double textScale;

  @override
  ConsumerState<_Harness> createState() => _HarnessState();
}

class _HarnessState extends ConsumerState<_Harness> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localeProvider.notifier).setLocale(widget.locale);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(widget.textScale)),
        child: child ?? const SizedBox.shrink(),
      ),
      home: widget.home,
    );
  }
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required Locale locale,
  double textScale = 1,
  _FakeDashboardApi? api,
  Session? session,
}) async {
  final container = ProviderContainer(
    overrides: [adminApiProvider.overrideWithValue(api ?? _FakeDashboardApi())],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: _Harness(
        home: const WorkshopAdminHomePage(),
        locale: locale,
        textScale: textScale,
      ),
    ),
  );
  if (session != null) {
    container.read(authControllerProvider.notifier).state = AsyncData<Session?>(
      session,
    );
  }
  await tester.pumpAndSettle();
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

void main() {
  testWidgets('dashboard wide EN renders counts, next up and recent jobs', (
    tester,
  ) async {
    _setSize(tester, const Size(1280, 800));
    await _pumpHome(tester, locale: const Locale('en'));
    expect(tester.takeException(), isNull);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(WorkshopAdminHomePage)),
    );
    // Active is derived client-side as assigned + in progress (14 + 9).
    expect(find.text('23'), findsOneWidget);
    // Pipeline legend repeats the same real counts.
    expect(find.text('34'), findsWidgets);
    expect(find.text('9'), findsWidgets);
    expect(find.text('45'), findsWidgets);
    expect(find.text('56'), findsWidgets);
    expect(find.text(l10n.dashboardStatActive), findsOneWidget);
    expect(find.text(l10n.dashboardStatNewScheduled), findsWidgets);
    expect(find.text(l10n.statusInProgress), findsWidgets);
    expect(find.text(l10n.statusReadyToFinalize), findsWidgets);
    expect(find.text(l10n.dashboardStatFinalizedToday), findsWidgets);

    // One page header, one KPI strip, four modules.
    expect(find.byType(WorkshopPageHeader), findsOneWidget);
    expect(find.byType(WorkshopMetricStrip), findsOneWidget);
    expect(find.text(l10n.dashboardNextUp), findsOneWidget);
    expect(find.text(l10n.dashboardRecentJobs), findsOneWidget);
    expect(find.text(l10n.dashboardPipeline), findsOneWidget);
    expect(find.text(l10n.dashQuickActions), findsOneWidget);

    // Next up is the open job; the finalized job stays in Recent jobs.
    expect(find.byKey(const Key('dashboard-job-job-1')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-job-job-2')), findsOneWidget);
    expect(find.textContaining('JOB-TEST0001'), findsOneWidget);
    expect(find.textContaining('JOB-TEST0002'), findsOneWidget);

    // The dashboard search bar and KPI cards are gone by design.
    expect(find.byKey(const Key('dashboard-search')), findsNothing);
    expect(find.byType(WorkshopStatCard), findsNothing);
    expect(find.byType(WorkshopHeader), findsNothing);

    // Header semantics are exposed once.
    expect(
      find.descendant(
        of: find.byType(WorkshopPageHeader),
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.header == true,
        ),
      ),
      findsOneWidget,
    );
    // Metric semantics keep the value + label pairing.
    expect(
      find.descendant(
        of: find.byKey(const Key('dashboard-stat-active')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == '23, ${l10n.dashboardStatActive}',
        ),
      ),
      findsOneWidget,
    );

    // The pipeline bar is a real 8 px stacked bar with one segment per
    // non-zero stage.
    final bar = tester.getSize(find.byKey(const Key('dashboard-pipeline-bar')));
    expect(bar.height, 8);
    expect(bar.width, greaterThan(0));
    expect(
      find.descendant(
        of: find.byKey(const Key('dashboard-pipeline-bar')),
        matching: find.byType(ColoredBox),
      ),
      findsNWidgets(4),
    );
    // Each segment paints at the full 8 px bar height (a centred Row would
    // collapse childless ColoredBoxes to zero height).
    expect(
      tester
          .getSize(
            find
                .descendant(
                  of: find.byKey(const Key('dashboard-pipeline-bar')),
                  matching: find.byType(ColoredBox),
                )
                .first,
          )
          .height,
      8,
    );
  });

  testWidgets('dashboard phone AR renders stacked with RTL', (tester) async {
    _setSize(tester, const Size(390, 844));
    await _pumpHome(tester, locale: const Locale('ar'));
    expect(tester.takeException(), isNull);

    expect(
      Directionality.of(tester.element(find.byType(WorkshopAdminHomePage))),
      TextDirection.rtl,
    );
    expect(find.text('23'), findsOneWidget);
    await tester.dragUntilVisible(
      find.textContaining('JOB-TEST0002'),
      find.byType(CustomScrollView),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('JOB-TEST0002'), findsWidgets);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard layouts: no search field and no floating stat cards', (
    tester,
  ) async {
    _setSize(tester, const Size(1280, 800));
    await _pumpHome(tester, locale: const Locale('en'));
    expect(tester.takeException(), isNull);

    expect(find.byType(AppTextField), findsNothing);
    expect(find.byType(WorkshopStatCard), findsNothing);
    expect(find.byType(WorkshopStatusBadge), findsWidgets);
    // Exactly one primary action on the page.
    expect(find.text('New job'), findsOneWidget);
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final scale in const [1.5, 2.0]) {
      for (final entry in const {
        'phone-360': Size(360, 800),
        'phone': Size(390, 844),
        'tablet': Size(768, 900),
        'wide': Size(1280, 800),
      }.entries) {
        testWidgets(
          'dashboard ${locale.languageCode} scale $scale ${entry.key} no overflow',
          (tester) async {
            _setSize(tester, entry.value);
            await _pumpHome(tester, locale: locale, textScale: scale);
            expect(tester.takeException(), isNull);
            await tester.drag(
              find.byType(CustomScrollView),
              const Offset(0, -600),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('dashboard empty jobs shows one empty state with New job', (
    tester,
  ) async {
    _setSize(tester, const Size(1280, 800));
    await _pumpHome(
      tester,
      locale: const Locale('en'),
      api: _FakeDashboardApi(jobList: const []),
    );
    expect(tester.takeException(), isNull);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(WorkshopAdminHomePage)),
    );
    expect(find.text(l10n.jobsEmpty), findsOneWidget);
    expect(find.text(l10n.dashboardNoUpcoming), findsNothing);
    expect(find.byType(WorkshopEmptyState), findsOneWidget);
    // Counts still render from the counts endpoint.
    expect(find.text('23'), findsOneWidget);
    expect(find.text(l10n.newJob), findsWidgets);
  });

  testWidgets('dashboard single job keeps a compact recent card', (
    tester,
  ) async {
    _setSize(tester, const Size(1280, 800));
    await _pumpHome(
      tester,
      locale: const Locale('en'),
      api: _FakeDashboardApi(jobList: const [_jobOpen]),
    );
    expect(tester.takeException(), isNull);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(WorkshopAdminHomePage)),
    );
    // Next up + a deliberately quiet Recent jobs card instead of dead canvas.
    expect(find.text(l10n.dashboardNextUp), findsOneWidget);
    expect(find.text(l10n.dashboardRecentJobs), findsOneWidget);
    expect(find.text(l10n.dashboardNoRecentJobs), findsOneWidget);
    expect(find.byKey(const Key('dashboard-job-job-1')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-job-job-2')), findsNothing);
    // No fake rows and no second primary action in the note.
    expect(find.byType(JobListRow), findsOneWidget);
  });

  testWidgets('dashboard counts error shows one bounded error, no numbers', (
    tester,
  ) async {
    _setSize(tester, const Size(1280, 800));
    await _pumpHome(
      tester,
      locale: const Locale('en'),
      api: _FakeDashboardApi(countsError: true),
    );
    expect(tester.takeException(), isNull);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(WorkshopAdminHomePage)),
    );
    expect(find.byType(WorkshopErrorState), findsOneWidget);
    expect(find.text(l10n.error), findsOneWidget);
    expect(find.text(l10n.retryAction), findsOneWidget);
    expect(find.byType(WorkshopMetricStrip), findsNothing);
    // No invented KPI numbers leak into the failure view.
    for (final value in const ['23', '34', '9', '45', '56']) {
      expect(find.text(value), findsNothing);
    }

    await tester.tap(find.text(l10n.retryAction).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(WorkshopErrorState), findsOneWidget);
  });

  testWidgets('dashboard jobs error keeps the counts visible', (tester) async {
    _setSize(tester, const Size(1280, 800));
    await _pumpHome(
      tester,
      locale: const Locale('en'),
      api: _FakeDashboardApi(jobsError: true),
    );
    expect(tester.takeException(), isNull);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(WorkshopAdminHomePage)),
    );
    expect(find.byType(WorkshopErrorState), findsOneWidget);
    expect(find.text(l10n.commonLoadFailed), findsOneWidget);
    expect(find.text('23'), findsOneWidget);
  });

  testWidgets('dashboard tab navigation reaches every tab', (tester) async {
    _setSize(tester, const Size(1280, 800));
    await _pumpHome(tester, locale: const Locale('en'));
    expect(tester.takeException(), isNull);

    expect(find.byType(DashboardTab), findsOneWidget);

    final jobsTab = find.byKey(const Key('workshop-tab-jobs')).first;
    await tester.ensureVisible(jobsTab);
    await tester.tap(jobsTab);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(JobsTab), findsOneWidget);

    final staffTab = find.byKey(const Key('workshop-tab-staff')).first;
    await tester.ensureVisible(staffTab);
    await tester.tap(staffTab);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(StaffTab), findsOneWidget);
    expect(find.text('Technician A'), findsWidgets);

    final templatesTab = find.byKey(const Key('workshop-tab-templates')).first;
    await tester.ensureVisible(templatesTab);
    await tester.tap(templatesTab);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(TemplatesTab), findsOneWidget);

    final overviewTab = find.byKey(const Key('workshop-tab-overview')).first;
    await tester.ensureVisible(overviewTab);
    await tester.tap(overviewTab);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(DashboardTab), findsOneWidget);
    expect(find.text('23'), findsOneWidget);
  });

  testWidgets('dashboard next up opens the quick sheet with reassign', (
    tester,
  ) async {
    _setSize(tester, const Size(1280, 800));
    await _pumpHome(tester, locale: const Locale('en'));
    expect(tester.takeException(), isNull);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(WorkshopAdminHomePage)),
    );
    await tester.tap(find.byKey(const Key('dashboard-job-job-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(l10n.reassign), findsWidgets);
    expect(find.text(l10n.cancelJob), findsOneWidget);
    expect(find.text('+971500000000'), findsOneWidget);
    // The sheet repeats the vehicle title above the dashboard card.
    expect(find.text('Toyota Camry'), findsWidgets);
    expect(find.bySemanticsLabel(l10n.close), findsOneWidget);
  });

  testWidgets('dashboard finalized job offers the report, no mutations', (
    tester,
  ) async {
    _setSize(tester, const Size(1280, 800));
    await _pumpHome(tester, locale: const Locale('en'));
    expect(tester.takeException(), isNull);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(WorkshopAdminHomePage)),
    );
    await tester.tap(find.byKey(const Key('dashboard-job-job-2')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(l10n.report), findsWidgets);
    expect(find.text(l10n.assign), findsNothing);
    expect(find.text(l10n.reassign), findsNothing);
    expect(find.text(l10n.cancelJob), findsNothing);
  });

  testWidgets('dashboard greets the signed-in admin with the workshop name', (
    tester,
  ) async {
    _setSize(tester, const Size(1280, 800));
    await _pumpHome(tester, locale: const Locale('en'), session: _session);
    expect(tester.takeException(), isNull);
    // The account/workshop name appears in the shell chrome and the page
    // header, so multiple matches are expected.
    expect(find.text('Layla Haddad'), findsWidgets);
    expect(find.text('Marina Workshop'), findsWidgets);
    expect(find.textContaining('Welcome back, Layla'), findsOneWidget);
  });

  testWidgets('dashboard without a session keeps a page title', (tester) async {
    _setSize(tester, const Size(1280, 800));
    await _pumpHome(tester, locale: const Locale('en'));
    expect(tester.takeException(), isNull);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(WorkshopAdminHomePage)),
    );
    expect(find.text(l10n.dashboardTab), findsWidgets);
    expect(find.byType(WorkshopPageHeader), findsOneWidget);
    expect(find.byType(WorkshopAvatar), findsWidgets);
  });
}
