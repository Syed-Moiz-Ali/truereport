import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/features/dashboard/dashboard_screen.dart';
import 'package:platform_admin_app/src/features/dashboard/dashboard_states.dart';
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
    nativeName: 'English',
    direction: 'ltr',
    active: true,
    isDefault: true,
    sortOrder: 0,
    status: 'LIVE',
  ),
  PlatformLanguage(
    code: 'ar',
    nativeName: 'العربية',
    direction: 'rtl',
    active: true,
    isDefault: false,
    sortOrder: 1,
    status: 'LIVE',
  ),
  PlatformLanguage(
    code: 'zh-Hans',
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

const _fakeReadinessZh = LanguageReadiness(
  language: 'zh-Hans',
  nativeName: '中文',
  direction: 'ltr',
  isDefault: false,
  status: 'TRANSLATING',
  readinessPercent: 45,
  uiMessagesPath: 'assets/i18n/zh-Hans.json',
  uiMessages: UiMessageCoverage(
    total: 100,
    approved: 45,
    missing: 55,
    changed: 0,
    path: 'assets/i18n/zh-Hans.json',
    generationStatus: 'NONE',
  ),
  content: {},
  blockers: [],
);

Widget _app({
  Locale locale = const Locale('en'),
  double width = 1280,
  OverviewSummary summary = _summary,
  ConfigHealth health = _healthy,
  List<PlatformLanguage> languages = _languages,
}) {
  return ProviderScope(
    overrides: [
      uiStringsProvider.overrideWithValue(
        locale.languageCode == 'ar' ? fakeArUiStrings() : fakeEnUiStrings(),
      ),
      overviewProvider.overrideWith((ref) async => summary),
      configHealthProvider.overrideWith((ref) async => health),
      platformLanguagesProvider.overrideWith((ref) async => languages),
      auditEventsProvider.overrideWith((ref) async => _events),
      readinessProvider('zh-Hans')
          .overrideWith((ref) async => _fakeReadinessZh),
      readinessProvider('en').overrideWith(
        (ref) async => const LanguageReadiness(
          language: 'en',
          nativeName: 'English',
          direction: 'ltr',
          isDefault: true,
          status: 'LIVE',
          readinessPercent: 100,
          uiMessagesPath: 'en.json',
          uiMessages: UiMessageCoverage(
            total: 100,
            approved: 100,
            missing: 0,
            changed: 0,
            path: 'en.json',
            generationStatus: 'NONE',
          ),
          content: {},
          blockers: [],
        ),
      ),
      readinessProvider('ar').overrideWith(
        (ref) async => const LanguageReadiness(
          language: 'ar',
          nativeName: 'العربية',
          direction: 'rtl',
          isDefault: false,
          status: 'LIVE',
          readinessPercent: 100,
          uiMessagesPath: 'ar.json',
          uiMessages: UiMessageCoverage(
            total: 100,
            approved: 100,
            missing: 0,
            changed: 0,
            path: 'ar.json',
            generationStatus: 'NONE',
          ),
          content: {},
          blockers: [],
        ),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
          overrides: [
            uiStringsProvider.overrideWithValue(fakeEnUiStrings()),
            overviewProvider.overrideWith(
              (ref) => Completer<OverviewSummary>().future,
            ),
            platformLanguagesProvider.overrideWith((ref) async => _languages),
            readinessProvider('zh-Hans')
                .overrideWith((ref) async => _fakeReadinessZh),
          ],
          child: const MaterialApp(
            supportedLocales: <Locale>[Locale('en'), Locale('ar')],
            localizationsDelegates: <LocalizationsDelegate<dynamic>>[
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: MediaQuery(
              data: MediaQueryData(size: Size(1280, 900)),
              child: DashboardScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(DashboardSkeleton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows an error state and retries into data', (tester) async {
      var fail = true;
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            uiStringsProvider.overrideWithValue(fakeEnUiStrings()),
            overviewProvider.overrideWith((ref) async {
              if (fail) throw Exception('offline');
              return _summary;
            }),
            configHealthProvider.overrideWith((ref) async => _healthy),
            platformLanguagesProvider.overrideWith((ref) async => _languages),
            auditEventsProvider.overrideWith((ref) async => _events),
            readinessProvider('zh-Hans')
                .overrideWith((ref) async => _fakeReadinessZh),
          ],
          child: const MaterialApp(
            supportedLocales: <Locale>[Locale('en'), Locale('ar')],
            localizationsDelegates: <LocalizationsDelegate<dynamic>>[
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
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

      expect(find.text('Active workshops'), findsOneWidget);
      expect(find.text('9'), findsWidgets);
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

    testWidgets(
      'renders operational status, KPIs, needs attention, language action center, and quick actions',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        await tester.pumpWidget(_app(health: _unhealthy));
        await tester.pumpAndSettle();

        // 1. Verdict slab
        expect(find.text('Items need attention'), findsOneWidget);
        expect(find.text('Active workshops'), findsOneWidget);
        expect(find.text('Published reports'), findsOneWidget);
        expect(find.text('Languages live'), findsOneWidget);
        expect(find.byKey(const Key('btn-dashboard-refresh')), findsOneWidget);

        // 2. Job lifecycle rail
        expect(find.text('JOBS BY STATUS'), findsOneWidget);
        expect(find.text('In progress'), findsOneWidget);

        // 3. Needs attention ledger
        expect(find.text('Needs attention'), findsOneWidget);
        expect(
          find.textContaining('Checklist health issues detected'),
          findsOneWidget,
        );
        expect(
          find.textContaining('1 checklist configuration issue'),
          findsOneWidget,
        );
        // Ensure raw code is NOT rendered in Needs Attention
        expect(find.textContaining('MISSING_AR'), findsNothing);
        expect(find.textContaining('TRANSLATION_GAP'), findsNothing);
        // Localized language status label instead of raw TRANSLATING
        expect(
          find.textContaining('setup incomplete (Translating)'),
          findsOneWidget,
        );
        expect(
          find.textContaining('setup incomplete (TRANSLATING)'),
          findsNothing,
        );

        // 4. Recent activity — humanized actions, never raw codes
        expect(find.text('Recent activity'), findsOneWidget);
        expect(find.text('Master item published'), findsOneWidget);
        expect(find.text('MASTER_ITEM_PUBLISHED'), findsNothing);
        expect(
          find.byKey(const Key('btn-activity-view-audit-log')),
          findsOneWidget,
        );

        // 5. Language setup is surfaced through the ledger, not a card grid
        expect(
          find.textContaining('(ZH-HANS) setup incomplete'),
          findsOneWidget,
        );

        // 6. Quick actions
        expect(find.text('Add workshop'), findsOneWidget);
        expect(find.text('Add checklist item'), findsOneWidget);
        expect(find.text('Add language'), findsOneWidget);
        expect(find.text('View checklist health'), findsOneWidget);

        // Read-only: no CRUD tables or edit forms.
        expect(find.byType(DataTable), findsNothing);
        expect(find.byType(TextFormField), findsNothing);
        expect(find.byType(DropdownButtonFormField<String>), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders quiet success states when health is clear and all languages live',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        const liveLanguages = [
          PlatformLanguage(
            code: 'en',
            nativeName: 'English',
            direction: 'ltr',
            active: true,
            isDefault: true,
            sortOrder: 0,
            status: 'LIVE',
          ),
          PlatformLanguage(
            code: 'ar',
            nativeName: 'العربية',
            direction: 'rtl',
            active: true,
            isDefault: false,
            sortOrder: 1,
            status: 'LIVE',
          ),
        ];
        final clearSummary = OverviewSummary(
          workshops: _summary.workshops,
          staff: _summary.staff,
          jobs: const OverviewJobs(active: 10, pendingReview: 0, byStatus: {}),
          reports: _summary.reports,
          checklist: const OverviewChecklist(
            categories: 2,
            items: 10,
            templates: 1,
            healthy: true,
            issues: 0,
          ),
          languages: const OverviewLanguages(live: 2, translating: 0),
          recentActivity: _summary.recentActivity,
          alerts: const [],
        );

        await tester.pumpWidget(
          _app(
            summary: clearSummary,
            health: _healthy,
            languages: liveLanguages,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('All systems healthy'), findsOneWidget);
        expect(find.textContaining('No items need attention'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('renders on compact width without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 900));
      await tester.pumpWidget(_app(width: 360));
      await tester.pumpAndSettle();

      expect(find.text('Active workshops'), findsOneWidget);
      expect(find.text('Add workshop'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders Arabic RTL without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(
        _app(locale: const Locale('ar'), health: _unhealthy),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn-dashboard-refresh')), findsOneWidget);
      expect(find.byKey(const Key('btn-attention-view-all')), findsOneWidget);
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
