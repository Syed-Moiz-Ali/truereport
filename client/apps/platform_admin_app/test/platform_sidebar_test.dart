import 'dart:async';

import 'package:auth/auth.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/components/platform_nav.dart';
import 'package:platform_admin_app/src/components/platform_shell.dart';
import 'package:platform_admin_app/src/components/platform_sidebar.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/platform_router.dart';
import 'package:platform_admin_app/src/platform_theme.dart';

import 'support/ui_message_fixtures.dart';

Widget _buildTestApp({
  required Widget child,
  Locale locale = const Locale('en'),
  Size surfaceSize = const Size(1280, 800),
}) {
  return ProviderScope(
    overrides: [
      uiStringsProvider.overrideWithValue(
        locale.languageCode == 'ar' ? fakeArUiStrings() : fakeEnUiStrings(),
      ),
      platformLocaleProvider.overrideWith(() => _MockLocaleController(locale)),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: <Locale>[const Locale('en'), const Locale('ar')],
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        fontFamily: 'Plus Jakarta Sans',
        scaffoldBackgroundColor: PtTheme.canvas,
      ),
      home: MediaQuery(
        data: MediaQueryData(size: surfaceSize),
        child: child,
      ),
    ),
  );
}

class _MockLocaleController extends LocaleController {
  _MockLocaleController(this._initial);
  final Locale _initial;

  @override
  Locale build() => _initial;
}

class _TestAuth extends AuthController {
  _TestAuth(this.session);

  final Session? session;

  @override
  Future<Session?> build() async => session;
}

Session _testSession() {
  return const Session(
    accessToken: 'access',
    refreshToken: 'refresh',
    user: User(
      id: 'u-1',
      email: 'admin@truereport.test',
      displayName: 'Test Admin',
      platformAdmin: true,
      totpEnabled: false,
    ),
    memberships: [],
  );
}

void main() {
  group('PlatformSidebar and Nav Unit/Widget Tests', () {
    testWidgets('renders brand block with TrueReport and Platform Admin', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          child: const Scaffold(
            body: PlatformSidebar(currentRoute: '/workshops'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TrueReport'), findsOneWidget);
      expect(find.text('Platform Admin'), findsOneWidget);
    });

    testWidgets('renders bottom status capsule: System Operational', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          child: const Scaffold(
            body: PlatformSidebar(currentRoute: '/workshops'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('System Operational'), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
    });

    test('primary items are exactly the 6 IA entries in order', () {
      const items = PlatformNavData.primaryItems;
      expect(items.map((item) => item.id).toList(), [
        'dashboard',
        'workshops',
        'checklist',
        'reports',
        'audit-log',
        'settings',
      ]);
      expect(items.map((item) => item.route).toList(), [
        '/dashboard',
        '/workshops',
        '/checklist/items',
        '/reports/document-types',
        '/audit-log',
        '/settings',
      ]);
      expect(PlatformNavData.allItems.map((item) => item.id).toList(), [
        'dashboard',
        'workshops',
        'checklist',
        'reports',
        'audit-log',
        'settings',
      ]);
    });

    test('nav active state prefixes checklist, reports and settings pages', () {
      PlatformNavEntry entry(String id) =>
          PlatformNavData.primaryItems.firstWhere((item) => item.id == id);

      expect(entry('dashboard').isActive('/dashboard'), isTrue);
      expect(entry('dashboard').isActive('/dashboard?range=30d'), isTrue);
      expect(entry('dashboard').isActive('/workshops'), isFalse);
      expect(entry('workshops').isActive('/'), isFalse);
      expect(entry('workshops').isActive('/workshops'), isTrue);
      expect(entry('workshops').isActive('/workshops/new'), isTrue);
      expect(entry('workshops').isActive('/workshops/w-1'), isTrue);
      expect(entry('workshops').isActive('/dashboard'), isFalse);
      expect(entry('checklist').isActive('/checklist/items'), isTrue);
      expect(entry('checklist').isActive('/checklist/categories'), isTrue);
      expect(entry('checklist').isActive('/checklist/option-sets'), isTrue);
      expect(entry('checklist').isActive('/checklist/health'), isTrue);
      expect(entry('checklist').isActive('/workshops'), isFalse);
      expect(entry('reports').isActive('/reports/document-types'), isTrue);
      expect(entry('reports').isActive('/checklist/items'), isFalse);
      expect(entry('settings').isActive('/settings'), isTrue);
      expect(entry('settings').isActive('/settings/languages'), isTrue);
      expect(
        entry('settings').isActive('/settings/languages/zh-Hans/translations'),
        isTrue,
      );
      expect(entry('settings').isActive('/audit-log'), isFalse);
      expect(entry('audit-log').isActive('/audit-log'), isTrue);
      expect(entry('audit-log').isActive('/audit-log/extra'), isFalse);
    });

    testWidgets('renders the 6 primary items with no configuration group', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          child: const Scaffold(
            body: PlatformSidebar(currentRoute: '/workshops'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Primary items presence
      expect(find.byKey(const Key('nav-dashboard')), findsOneWidget);
      expect(find.byKey(const Key('nav-workshops')), findsOneWidget);
      expect(find.byKey(const Key('nav-checklist')), findsOneWidget);
      expect(find.byKey(const Key('nav-reports')), findsOneWidget);
      expect(find.byKey(const Key('nav-audit-log')), findsOneWidget);
      expect(find.byKey(const Key('nav-settings')), findsOneWidget);

      // Removed IA entries are gone, along with the configuration section.
      expect(find.byKey(const Key('nav-master-library')), findsNothing);
      expect(find.byKey(const Key('nav-data-catalogues')), findsNothing);
      expect(find.byKey(const Key('nav-equipment')), findsNothing);
      expect(find.byKey(const Key('nav-templates')), findsNothing);
      expect(find.byKey(const Key('nav-document-types')), findsNothing);
      expect(find.byKey(const Key('nav-languages')), findsNothing);
      expect(find.byKey(const Key('nav-config-health')), findsNothing);
      expect(find.text('CONFIGURATION'), findsNothing);

      // Verify vertical ordering: Dashboard first, Settings last.
      final dashboardTop = tester
          .getTopLeft(find.byKey(const Key('nav-dashboard')))
          .dy;
      final workshopsTop = tester
          .getTopLeft(find.byKey(const Key('nav-workshops')))
          .dy;
      final checklistTop = tester
          .getTopLeft(find.byKey(const Key('nav-checklist')))
          .dy;
      final reportsTop = tester
          .getTopLeft(find.byKey(const Key('nav-reports')))
          .dy;
      final auditLogTop = tester
          .getTopLeft(find.byKey(const Key('nav-audit-log')))
          .dy;
      final settingsTop = tester
          .getTopLeft(find.byKey(const Key('nav-settings')))
          .dy;

      expect(dashboardTop < workshopsTop, isTrue);
      expect(workshopsTop < checklistTop, isTrue);
      expect(checklistTop < reportsTop, isTrue);
      expect(reportsTop < auditLogTop, isTrue);
      expect(auditLogTop < settingsTop, isTrue);
    });

    testWidgets('active nav item styling matches Figma specs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          child: const Scaffold(
            body: PlatformSidebar(currentRoute: '/checklist/items'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Container inside the active item
      final activeItemFinder = find.descendant(
        of: find.byKey(const Key('nav-checklist')),
        matching: find.byType(Container),
      );
      expect(activeItemFinder, findsWidgets);

      // Verify active label style
      final activeText = tester.widget<Text>(find.text('Checklist'));
      expect(activeText.style?.color, equals(PtTheme.ink));
      expect(activeText.style?.fontWeight, equals(FontWeight.w600));

      // Verify active icon color
      final activeIcon = tester.widget<Icon>(
        find.byIcon(Icons.menu_book_rounded),
      );
      expect(activeIcon.color, equals(PtTheme.emerald));

      // Verify inactive item label style
      final inactiveText = tester.widget<Text>(find.text('Reports'));
      expect(inactiveText.style?.color, equals(PtTheme.darkNavText));
      expect(inactiveText.style?.fontWeight, equals(FontWeight.w500));

      // Verify inactive icon color
      final inactiveIcon = tester.widget<Icon>(
        find.byIcon(Icons.description_outlined),
      );
      expect(inactiveIcon.color, equals(PtTheme.muted));
    });

    testWidgets(
      'responsive shell: shows sidebar >= 900px, hides on compact < 900px',
      (tester) async {
        // 1. Desktop 1280px
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _buildTestApp(
            surfaceSize: const Size(1280, 900),
            child: const PlatformShell(
              currentRoute: '/workshops',
              child: Text('Content'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PlatformSidebar), findsOneWidget);
        expect(find.byKey(const Key('btn-mobile-nav-menu')), findsNothing);

        // 2. Compact 768px
        await tester.binding.setSurfaceSize(const Size(768, 1024));
        await tester.pumpWidget(
          _buildTestApp(
            surfaceSize: const Size(768, 1024),
            child: const PlatformShell(
              currentRoute: '/workshops',
              child: Text('Content'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PlatformSidebar), findsNothing);
        expect(find.byKey(const Key('btn-mobile-nav-menu')), findsOneWidget);

        // 3. Compact 360px
        await tester.binding.setSurfaceSize(const Size(360, 800));
        await tester.pumpWidget(
          _buildTestApp(
            surfaceSize: const Size(360, 800),
            child: const PlatformShell(
              currentRoute: '/workshops',
              child: Text('Content'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PlatformSidebar), findsNothing);
        expect(find.byKey(const Key('btn-mobile-nav-menu')), findsOneWidget);
      },
    );

    testWidgets(
      'mobile nav sheet opens, renders exact shared items, and navigates',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(768, 1024));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        String navigatedRoute = '';
        await tester.pumpWidget(
          _buildTestApp(
            surfaceSize: const Size(768, 1024),
            child: PlatformShell(
              currentRoute: '/workshops',
              onNavigate: (r) => navigatedRoute = r,
              child: Builder(builder: (ctx) => const Text('Page Body')),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap hamburger menu
        await tester.tap(find.byKey(const Key('btn-mobile-nav-menu')));
        await tester.pumpAndSettle();

        // Verify sheet title and shared nav items in sheet
        expect(find.text('Platform Admin'), findsWidgets);
        expect(find.byKey(const Key('mobile-nav-dashboard')), findsOneWidget);
        expect(find.byKey(const Key('mobile-nav-workshops')), findsOneWidget);
        expect(find.byKey(const Key('mobile-nav-checklist')), findsOneWidget);
        expect(find.byKey(const Key('mobile-nav-reports')), findsOneWidget);
        expect(find.byKey(const Key('mobile-nav-audit-log')), findsOneWidget);
        expect(find.byKey(const Key('mobile-nav-settings')), findsOneWidget);
        expect(find.text('CONFIGURATION'), findsNothing);

        // Tap an item in sheet
        await tester.tap(find.byKey(const Key('mobile-nav-reports')));
        await tester.pumpAndSettle();

        // Bottom sheet is closed and route was dispatched
        expect(find.byKey(const Key('mobile-nav-workshops')), findsNothing);
        expect(navigatedRoute, equals('/reports/document-types'));
      },
    );

    testWidgets(
      'RTL Arabic layout renders with no overflow across breakpoints',
      (tester) async {
        final widths = [1440.0, 1280.0, 768.0, 360.0];

        for (final width in widths) {
          await tester.binding.setSurfaceSize(Size(width, 900));
          await tester.pumpWidget(
            _buildTestApp(
              locale: const Locale('ar'),
              surfaceSize: Size(width, 900),
              child: const PlatformShell(
                currentRoute: '/workshops',
                child: Text('Content Arabic'),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason: 'Overflow in Arabic RTL at width $width',
          );
        }
        tester.binding.setSurfaceSize(null);
      },
    );

    testWidgets('legacy IA routes redirect to the new checklist IA', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      late final GoRouter router;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            uiStringsProvider.overrideWithValue(fakeEnUiStrings()),
            authControllerProvider.overrideWith(
              () => _TestAuth(_testSession()),
            ),
            platformLocaleProvider.overrideWith(
              () => _MockLocaleController(const Locale('en')),
            ),
            platformUiManifestProvider.overrideWithValue(
              const UiMessageManifest(
                defaultLanguage: 'en',
                namespaceVersions: {'platform_admin': 1, 'common': 1},
                languages: [
                  UiMessageLanguage(
                    code: 'en',
                    direction: 'ltr',
                    nativeName: 'English',
                    path: 'platform_admin/en.json',
                  ),
                ],
              ),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              router = ref.watch(platformRouterProvider);
              return MaterialApp.router(
                locale: const Locale('en'),
                supportedLocales: <Locale>[
                  const Locale('en'),
                  const Locale('ar'),
                ],
                localizationsDelegates: <LocalizationsDelegate<dynamic>>[
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                routerConfig: router,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final redirects = <String, String>{
        '/': '/dashboard',
        '/master-library': '/checklist/items',
        '/master-library/categories': '/checklist/categories',
        '/master-library/option-sets': '/checklist/option-sets',
        '/master-library/new': '/checklist/items/new',
        '/master-library/item-1/edit': '/checklist/items/item-1/edit',
        '/config-health': '/checklist/health',
        '/checklist': '/checklist/items',
        '/document-types': '/reports/document-types',
        '/reports': '/reports/document-types',
        '/languages': '/settings/languages',
        '/data-catalogues': '/checklist/option-sets',
        '/equipment': '/checklist/items',
        '/workshops/add-staff': '/workshops',
        '/workshops/register': '/workshops/new',
      };

      for (final entry in redirects.entries) {
        router.go(entry.key);
        await tester.pumpAndSettle();
        expect(
          router.state.uri.path,
          equals(entry.value),
          reason: '${entry.key} should redirect to ${entry.value}',
        );
      }

      // Legacy query-param detail route redirects to the path-param detail.
      router.go('/workshops/details?id=workshop-1');
      await tester.pumpAndSettle();
      expect(router.state.uri.path, equals('/workshops/workshop-1'));
    });

    testWidgets(
      'actionable sidebar language card shows correct status, action CTA and route',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final languages = [
          const PlatformLanguage(
            code: 'en',
            nativeName: 'English',
            direction: 'ltr',
            status: 'LIVE',
            isDefault: true,
            active: true,
            sortOrder: 0,
          ),
          const PlatformLanguage(
            code: 'es',
            nativeName: 'Español',
            direction: 'ltr',
            status: 'DRAFT',
            isDefault: false,
            active: false,
            sortOrder: 1,
          ),
        ];

        const readiness = LanguageReadiness(
          language: 'es',
          status: 'DRAFT',
          nativeName: 'Español',
          direction: 'ltr',
          isDefault: false,
          uiMessagesPath: '',
          readinessPercent: 40,
          uiMessages: UiMessageCoverage(
            total: 100,
            approved: 40,
            missing: 60,
            changed: 0,
            path: '',
            generationStatus: 'NONE',
          ),
          content: {},
          blockers: [
            ReadinessBlocker(
              code: 'CATEGORY_TRANSLATION_MISSING',
              tab: 'categories',
              count: 60,
              message: 'Category translations missing',
            ),
          ],
        );

        String? pushedRoute;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              uiStringsProvider.overrideWithValue(fakeEnUiStrings()),
              platformLocaleProvider.overrideWith(
                () => _MockLocaleController(const Locale('en')),
              ),
              platformLanguagesProvider.overrideWith((ref) async => languages),
              readinessProvider('es').overrideWith((ref) async => readiness),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: PlatformSidebar(
                  currentRoute: '/dashboard',
                  onNavigate: (route) => pushedRoute = route,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Card appears with native name and status
        expect(
          find.byKey(const Key('sidebar-language-status-card')),
          findsOneWidget,
        );
        expect(find.text('Español (ES)'), findsOneWidget);
        expect(find.text('40 of 100 translated (40%)'), findsOneWidget);
        expect(find.text('View language'), findsOneWidget);

        // Tap CTA -> routes directly to the ui-text tab
        await tester.tap(find.text('View language'));
        await tester.pumpAndSettle();
        expect(pushedRoute, equals('/settings/languages/es?tab=categories'));
      },
    );

    testWidgets('sidebar loading language card is visibly distinct', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const languages = [
        PlatformLanguage(
          code: 'de',
          nativeName: 'Deutsch',
          direction: 'ltr',
          status: 'TRANSLATING',
          isDefault: false,
          active: false,
          sortOrder: 1,
        ),
      ];
      final pendingReadiness = Completer<LanguageReadiness>();

      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('loading-scope'),
          overrides: [
            uiStringsProvider.overrideWithValue(fakeEnUiStrings()),
            platformLocaleProvider.overrideWith(
              () => _MockLocaleController(const Locale('en')),
            ),
            platformLanguagesProvider.overrideWith((ref) async => languages),
            readinessProvider('de')
                .overrideWith((ref) => pendingReadiness.future),
          ],
          child: const MaterialApp(
            home: Scaffold(body: PlatformSidebar(currentRoute: '/dashboard')),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('sidebar-language-loading')), findsOneWidget);
      expect(find.text('Deutsch (DE)'), findsOneWidget);
      expect(find.text('Continue generation'), findsNothing);
      expect(
        find.byKey(const Key('btn-sidebar-language-action')),
        findsNothing,
      );
    });

    testWidgets(
      'sidebar TRANSLATING language shows progress and continue CTA',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        const languages = [
          PlatformLanguage(
            code: 'en',
            nativeName: 'English',
            direction: 'ltr',
            status: 'LIVE',
            isDefault: true,
            active: true,
            sortOrder: 0,
          ),
          PlatformLanguage(
            code: 'de',
            nativeName: 'Deutsch',
            direction: 'ltr',
            status: 'TRANSLATING',
            isDefault: false,
            active: false,
            sortOrder: 1,
          ),
        ];
        const readiness = LanguageReadiness(
          language: 'de',
          status: 'TRANSLATING',
          nativeName: 'Deutsch',
          direction: 'ltr',
          isDefault: false,
          uiMessagesPath: 'de.json',
          readinessPercent: 42,
          uiMessages: UiMessageCoverage(
            total: 100,
            approved: 42,
            missing: 58,
            changed: 0,
            path: 'de.json',
            generationStatus: 'NONE',
          ),
          content: {},
          blockers: [],
        );

        String? pushedRoute;
        await tester.pumpWidget(
          ProviderScope(
            key: const ValueKey('translating-scope'),
            overrides: [
              uiStringsProvider.overrideWithValue(fakeEnUiStrings()),
              platformLocaleProvider.overrideWith(
                () => _MockLocaleController(const Locale('en')),
              ),
              platformLanguagesProvider.overrideWith((ref) async => languages),
              readinessProvider('de').overrideWith((ref) async => readiness),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: PlatformSidebar(
                  currentRoute: '/dashboard',
                  onNavigate: (route) => pushedRoute = route,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Deutsch (DE)'), findsOneWidget);
        expect(find.text('TRANSLATING'), findsOneWidget);
        expect(find.text('42 of 100 translated (42%)'), findsOneWidget);
        expect(find.text('View language'), findsOneWidget);

        await tester.tap(find.text('View language'));
        await tester.pumpAndSettle();
        expect(pushedRoute, equals('/settings/languages/de?tab=overview'));
      },
    );
    testWidgets('sidebar language card shows +N more', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Multiple incomplete languages -> shows +N more
      final multiLanguages = [
        const PlatformLanguage(
          code: 'en',
          nativeName: 'English',
          direction: 'ltr',
          status: 'LIVE',
          isDefault: true,
          active: true,
          sortOrder: 0,
        ),
        const PlatformLanguage(
          code: 'es',
          nativeName: 'Español',
          direction: 'ltr',
          status: 'DRAFT',
          isDefault: false,
          active: false,
          sortOrder: 1,
        ),
        const PlatformLanguage(
          code: 'fr',
          nativeName: 'Français',
          direction: 'ltr',
          status: 'TRANSLATING',
          isDefault: false,
          active: false,
          sortOrder: 2,
        ),
      ];

      const readinessEs = LanguageReadiness(
        language: 'es',
        status: 'DRAFT',
        nativeName: 'Español',
        direction: 'ltr',
        isDefault: false,
        uiMessagesPath: '/assets/i18n/es.json',
        readinessPercent: 100,
        uiMessages: UiMessageCoverage(
          total: 100,
          approved: 100,
          missing: 0,
          changed: 0,
          path: '/assets/i18n/es.json',
          generationStatus: 'COMPLETED',
        ),
        content: {},
        blockers: [],
      );

      String? pushedRoute;
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('multi-incomplete-scope'),
          overrides: [
            uiStringsProvider.overrideWithValue(fakeEnUiStrings()),
            platformLocaleProvider.overrideWith(
              () => _MockLocaleController(const Locale('en')),
            ),
            platformLanguagesProvider.overrideWith(
              (ref) async => multiLanguages,
            ),
            readinessProvider('es').overrideWith((ref) async => readinessEs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PlatformSidebar(
                currentRoute: '/dashboard',
                onNavigate: (route) => pushedRoute = route,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+1 more'), findsOneWidget);
      expect(find.text('View all languages'), findsOneWidget);
      expect(find.text('View language'), findsOneWidget);

      await tester.tap(find.text('View language'));
      await tester.pumpAndSettle();
      expect(pushedRoute, equals('/settings/languages/es?tab=overview'));
    });

    testWidgets('sidebar language card shows quiet all-live state', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final allLive = [
        const PlatformLanguage(
          code: 'en',
          nativeName: 'English',
          direction: 'ltr',
          status: 'LIVE',
          isDefault: true,
          active: true,
          sortOrder: 0,
        ),
        const PlatformLanguage(
          code: 'ar',
          nativeName: 'العربية',
          direction: 'rtl',
          status: 'LIVE',
          isDefault: false,
          active: true,
          sortOrder: 1,
        ),
      ];

      String? pushedRoute;
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('all-live-scope'),
          overrides: [
            uiStringsProvider.overrideWithValue(fakeEnUiStrings()),
            platformLocaleProvider.overrideWith(
              () => _MockLocaleController(const Locale('en')),
            ),
            platformLanguagesProvider.overrideWith((ref) async => allLive),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PlatformSidebar(
                currentRoute: '/dashboard',
                onNavigate: (route) => pushedRoute = route,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All languages live'), findsOneWidget);
      expect(find.text('View languages'), findsOneWidget);

      await tester.tap(find.text('View languages'));
      await tester.pumpAndSettle();
      expect(pushedRoute, equals('/settings/languages'));
    });

    testWidgets('retired languages are excluded from setup and +N more count', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final languagesWithRetired = [
        const PlatformLanguage(
          code: 'en',
          nativeName: 'English',
          direction: 'ltr',
          status: 'LIVE',
          isDefault: true,
          active: true,
          sortOrder: 0,
        ),
        const PlatformLanguage(
          code: 'es',
          nativeName: 'Español',
          direction: 'ltr',
          status: 'DRAFT',
          isDefault: false,
          active: false,
          sortOrder: 1,
        ),
        const PlatformLanguage(
          code: 'de',
          nativeName: 'Deutsch',
          direction: 'ltr',
          status: 'RETIRED',
          isDefault: false,
          active: false,
          sortOrder: 2,
        ),
      ];

      const readinessEs = LanguageReadiness(
        language: 'es',
        status: 'DRAFT',
        nativeName: 'Español',
        direction: 'ltr',
        isDefault: false,
        uiMessagesPath: '',
        readinessPercent: 0,
        uiMessages: UiMessageCoverage(
          total: 100,
          approved: 0,
          missing: 100,
          changed: 0,
          path: '',
          generationStatus: 'NONE',
        ),
        content: {},
        blockers: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('retired-exclusion-scope'),
          overrides: [
            uiStringsProvider.overrideWithValue(fakeEnUiStrings()),
            platformLocaleProvider.overrideWith(
              () => _MockLocaleController(const Locale('en')),
            ),
            platformLanguagesProvider.overrideWith(
              (ref) async => languagesWithRetired,
            ),
            readinessProvider('es').overrideWith((ref) async => readinessEs),
          ],
          child: const MaterialApp(
            home: Scaffold(body: PlatformSidebar(currentRoute: '/dashboard')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only 'es' is in setup; 'de' is retired so moreCount is 0 (+N more not shown)
      expect(find.text('Español (ES)'), findsOneWidget);
      expect(find.textContaining('more'), findsNothing);
      expect(find.text('Deutsch (DE)'), findsNothing);

      // Now test: if all non-retired languages are LIVE, retired languages do not prevent all-live state
      final liveAndRetiredOnly = [
        const PlatformLanguage(
          code: 'en',
          nativeName: 'English',
          direction: 'ltr',
          status: 'LIVE',
          isDefault: true,
          active: true,
          sortOrder: 0,
        ),
        const PlatformLanguage(
          code: 'de',
          nativeName: 'Deutsch',
          direction: 'ltr',
          status: 'RETIRED',
          isDefault: false,
          active: false,
          sortOrder: 1,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('retired-all-live-scope'),
          overrides: [
            uiStringsProvider.overrideWithValue(fakeEnUiStrings()),
            platformLocaleProvider.overrideWith(
              () => _MockLocaleController(const Locale('en')),
            ),
            platformLanguagesProvider.overrideWith(
              (ref) async => liveAndRetiredOnly,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: PlatformSidebar(currentRoute: '/dashboard')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All languages live'), findsOneWidget);
    });

    testWidgets(
      'priority order selects the most urgent setup language regardless of list order',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // Two incomplete languages:
        // List has 'es' (DRAFT no UI path -> priority 5) before 'fr' (REVIEW no blockers -> priority 1)
        final reversedLanguages = [
          const PlatformLanguage(
            code: 'es',
            nativeName: 'Español',
            direction: 'ltr',
            status: 'DRAFT',
            isDefault: false,
            active: false,
            sortOrder: 0,
          ),
          const PlatformLanguage(
            code: 'fr',
            nativeName: 'Français',
            direction: 'ltr',
            status: 'REVIEW',
            isDefault: false,
            active: false,
            sortOrder: 1,
          ),
        ];

        const readinessEs = LanguageReadiness(
          language: 'es',
          status: 'DRAFT',
          nativeName: 'Español',
          direction: 'ltr',
          isDefault: false,
          uiMessagesPath: '',
          readinessPercent: 10,
          uiMessages: UiMessageCoverage(
            total: 100,
            approved: 10,
            missing: 90,
            changed: 0,
            path: '',
            generationStatus: 'NONE',
          ),
          content: {},
          blockers: [],
        );

        const readinessFr = LanguageReadiness(
          language: 'fr',
          status: 'REVIEW',
          nativeName: 'Français',
          direction: 'ltr',
          isDefault: false,
          uiMessagesPath: '/assets/i18n/fr.json',
          readinessPercent: 95,
          uiMessages: UiMessageCoverage(
            total: 100,
            approved: 95,
            missing: 5,
            changed: 0,
            path: '/assets/i18n/fr.json',
            generationStatus: 'COMPLETED',
          ),
          content: {},
          blockers: [],
        );

        String? pushedRoute;
        await tester.pumpWidget(
          ProviderScope(
            key: const ValueKey('priority-order-scope'),
            overrides: [
              uiStringsProvider.overrideWithValue(fakeEnUiStrings()),
              platformLocaleProvider.overrideWith(
                () => _MockLocaleController(const Locale('en')),
              ),
              platformLanguagesProvider.overrideWith(
                (ref) async => reversedLanguages,
              ),
              readinessProvider('es').overrideWith((ref) async => readinessEs),
              readinessProvider('fr').overrideWith((ref) async => readinessFr),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: PlatformSidebar(
                  currentRoute: '/dashboard',
                  onNavigate: (route) => pushedRoute = route,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The first non-default language is selected when readiness ties.
        expect(find.textContaining('(ES)'), findsOneWidget);
        expect(find.text('View language'), findsOneWidget);
        expect(find.text('+1 more'), findsOneWidget);

        await tester.tap(find.text('View language'));
        await tester.pumpAndSettle();
        expect(pushedRoute, equals('/settings/languages/es?tab=overview'));
      },
    );
  });
}
