import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/features/dashboard/dashboard_screen.dart';
import 'package:platform_admin_app/src/platform_catalogue_models.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'support/ui_message_fixtures.dart';

const _summary = OverviewSummary(
  workshops: OverviewWorkshops(total: 12, active: 9),
  staff: OverviewStaff(technicians: 34, admins: 5),
  jobs: OverviewJobs(
    active: 21,
    pendingReview: 4,
    byStatus: {'DRAFT': 3, 'IN_PROGRESS': 14, 'PENDING_REVIEW': 4},
  ),
  reports: OverviewReports(
    published: 17,
    byMonth: {'2026-09': 5, '2026-10': 12},
  ),
  checklist: OverviewChecklist(
    categories: 6,
    items: 30,
    templates: 2,
    healthy: false,
    issues: 2,
  ),
  languages: OverviewLanguages(live: 2, translating: 1),
  recentActivity: [
    OverviewActivityEntry(
      id: 'evt-1',
      action: 'MASTER_ITEM_PUBLISHED',
      entityType: 'MASTER_ITEM',
      entityId: 'item-1',
      actor: 'PLATFORM_ADMIN',
      occurredAt: '2026-11-11T10:00:00Z',
    ),
  ],
  alerts: [
    OverviewAlert(
      severity: 'WARNING',
      title: 'Unpublished reports',
      body: 'Reports are waiting to be published.',
      route: '/audit-log',
    ),
  ],
);

const _healthy = ConfigHealth(healthy: true, checks: []);

const _unhealthy = ConfigHealth(
  healthy: false,
  checks: [
    HealthCheck(
      code: 'MISSING_AR',
      severity: 'ERROR',
      messageEn: 'Missing Arabic labels',
      messageAr: 'تسميات عربية مفقودة',
      affected: 2,
      references: [],
    ),
  ],
);

const _languages = [
  PlatformLanguage(
    code: 'en',
    nameEn: 'English',
    nameAr: 'الإنجليزية',
    nativeName: 'English',
    direction: 'ltr',
    active: true,
    isDefault: true,
    sortOrder: 0,
    status: 'LIVE',
  ),
  PlatformLanguage(
    code: 'ar',
    nameEn: 'Arabic',
    nameAr: 'العربية',
    nativeName: 'العربية',
    direction: 'rtl',
    active: true,
    isDefault: false,
    sortOrder: 1,
    status: 'LIVE',
  ),
  PlatformLanguage(
    code: 'zh-Hans',
    nameEn: 'Chinese',
    nameAr: 'الصينية',
    nativeName: '中文',
    direction: 'ltr',
    active: true,
    isDefault: false,
    sortOrder: 2,
    status: 'TRANSLATING',
  ),
];

const _events = [
  PlatformAuditEvent(
    id: 'evt-9',
    action: 'WORKSHOP_REGISTERED',
    entityType: 'WORKSHOP',
    entityId: 'workshop-9',
    actorRole: 'PLATFORM_ADMIN',
    occurredAt: '2026-11-12T08:00:00Z',
    reasonCode: 'ONBOARDING',
    metadataJson: '{}',
  ),
];

Widget _app({
  Locale locale = const Locale('en'),
  double width = 1280,
  OverviewSummary summary = _summary,
  ConfigHealth health = _healthy,
}) {
  return ProviderScope(
    overrides: [uiStringsProvider.overrideWithValue(locale.languageCode == 'ar' ? fakeArUiStrings() : fakeEnUiStrings()), 
      overviewProvider.overrideWith((ref) async => summary),
      configHealthProvider.overrideWith((ref) async => health),
      platformLanguagesProvider.overrideWith((ref) async => _languages),
      auditEventsProvider.overrideWith((ref) async => _events),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: <Locale>[const Locale('en'), const Locale('ar')],
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 900)),
        child: const DashboardScreen(),
      ),
    ),
  );
}

void main() {
  group('OverviewSummary model', () {
    test('parses an empty payload with zero/empty fallbacks', () {
      const summary = OverviewSummary.empty;
      expect(summary.workshops.total, 0);
      expect(summary.jobs.byStatus, isEmpty);
      expect(summary.recentActivity, isEmpty);
      expect(summary.alerts, isEmpty);

      final parsed = OverviewSummary.fromJson(const {});
      expect(parsed.workshops.total, 0);
      expect(parsed.staff.technicians, 0);
      expect(parsed.jobs.pendingReview, 0);
      expect(parsed.reports.published, 0);
      expect(parsed.checklist.healthy, isTrue);
      expect(parsed.languages.live, 0);
      expect(parsed.recentActivity, isEmpty);
      expect(parsed.alerts, isEmpty);
    });

    test('parses a full payload defensively', () {
      final parsed = OverviewSummary.fromJson(const {
        'workshops': {'total': 12, 'active': 9},
        'staff': {'technicians': 34},
        'jobs': {
          'active': 21,
          'pendingReview': 4,
          'byStatus': {'DRAFT': 3},
        },
        'reports': {
          'published': 17,
          'byMonth': [
            {'month': '2026-10', 'count': 12},
          ],
        },
        'checklist': {'issues': 2},
        'languages': {'live': 2, 'translating': 1},
        'recentActivity': [
          {'action': 'PUBLISHED', 'actor': 'ADMIN'},
        ],
        'alerts': [
          {'title': 'Heads up', 'route': '/audit-log'},
        ],
      });
      expect(parsed.workshops.total, 12);
      expect(parsed.staff.admins, 0);
      expect(parsed.jobs.byStatus, {'DRAFT': 3});
      expect(parsed.reports.byMonth, {'2026-10': 12});
      expect(parsed.checklist.healthy, isFalse);
      expect(parsed.recentActivity.single.action, 'PUBLISHED');
      expect(parsed.alerts.single.route, '/audit-log');
    });
  });

  group('DashboardScreen', () {
    testWidgets('shows a loading state while the overview loads', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [uiStringsProvider.overrideWithValue(fakeEnUiStrings()), 
            overviewProvider.overrideWith(
              (ref) => Completer<OverviewSummary>().future,
            ),
          ],
          child: const MaterialApp(
            supportedLocales: <Locale>[Locale('en'), Locale('ar')],
            localizationsDelegates: <LocalizationsDelegate<dynamic>>[GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
            home: MediaQuery(
              data: MediaQueryData(size: Size(1280, 900)),
              child: DashboardScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows an error state and retries into data', (tester) async {
      var fail = true;
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [uiStringsProvider.overrideWithValue(fakeEnUiStrings()), 
            overviewProvider.overrideWith((ref) async {
              if (fail) throw Exception('offline');
              return _summary;
            }),
            configHealthProvider.overrideWith((ref) async => _healthy),
            platformLanguagesProvider.overrideWith((ref) async => _languages),
            auditEventsProvider.overrideWith((ref) async => _events),
          ],
          child: const MaterialApp(
            supportedLocales: <Locale>[Locale('en'), Locale('ar')],
            localizationsDelegates: <LocalizationsDelegate<dynamic>>[GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
            home: MediaQuery(
              data: MediaQueryData(size: Size(1280, 900)),
              child: DashboardScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Total workshops'), findsOneWidget);
      expect(find.text('12'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the empty state with a CTA to workshops', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(_app(summary: OverviewSummary.empty));
      await tester.pumpAndSettle();

      expect(
        find.text('No data yet — add your first workshop to get started.'),
        findsOneWidget,
      );
      expect(find.text('Register Workshop'), findsOneWidget);
      expect(find.byType(DataTable), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders KPIs, quick actions, and alert links', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(_app(health: _unhealthy));
      await tester.pumpAndSettle();

      // KPI cards.
      expect(find.text('Total workshops'), findsOneWidget);
      expect(find.text('Technicians'), findsOneWidget);
      expect(find.text('Pending reviews'), findsOneWidget);
      expect(find.text('Published reports'), findsOneWidget);
      expect(find.text('Checklist health'), findsOneWidget);
      expect(find.text('Languages live'), findsOneWidget);
      expect(find.text('2/1'), findsOneWidget);

      // Distribution summaries.
      expect(find.text('Jobs by status'), findsOneWidget);
      expect(find.text('Reports by month'), findsOneWidget);
      expect(find.text('DRAFT'), findsWidgets);

      // Recent activity.
      expect(find.text('Recent activity'), findsOneWidget);
      expect(find.text('MASTER_ITEM_PUBLISHED'), findsOneWidget);
      expect(find.text('View all'), findsWidgets);

      // Alerts: overview alert + health alert + translation alert.
      expect(find.text('Unpublished reports'), findsOneWidget);
      expect(find.text('Issues found'), findsOneWidget);
      expect(find.text('中文 translation incomplete'), findsOneWidget);

      // Quick actions navigate to tabs instead of opening forms.
      expect(find.text('Register Workshop'), findsOneWidget);
      expect(find.text('Add item'), findsOneWidget);
      expect(find.text('Create template'), findsOneWidget);
      expect(find.text('Add language'), findsOneWidget);

      // Read-only: no CRUD tables or edit forms.
      expect(find.byType(DataTable), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders on compact width without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 900));
      await tester.pumpWidget(_app(width: 360));
      await tester.pumpAndSettle();

      expect(find.text('Total workshops'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders Arabic RTL without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(
        _app(locale: const Locale('ar'), health: _unhealthy),
      );
      await tester.pumpAndSettle();

      expect(find.text('إجمالي الورش'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(const Size(360, 900));
      await tester.pumpWidget(
        _app(locale: const Locale('ar'), width: 360, health: _unhealthy),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
