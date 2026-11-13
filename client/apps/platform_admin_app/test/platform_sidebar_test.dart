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
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
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
    testWidgets('renders brand block with CoreOS and Platform Admin', (
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

      expect(find.text('CoreOS'), findsOneWidget);
      expect(find.text('Platform Admin'), findsOneWidget);
    });

    testWidgets('renders bottom status capsule: GRID V4.2 ONLINE', (
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

      expect(find.text('GRID V4.2 ONLINE'), findsOneWidget);
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
      expect(entry('checklist').isActive('/checklist/templates'), isTrue);
      expect(entry('checklist').isActive('/checklist/templates/tpl-1'), isTrue);
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
          ],
          child: Consumer(
            builder: (context, ref, _) {
              router = ref.watch(platformRouterProvider);
              return MaterialApp.router(
                locale: const Locale('en'),
                supportedLocales: <Locale>[const Locale('en'), const Locale('ar')],
                localizationsDelegates: <LocalizationsDelegate<dynamic>>[GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
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
        '/templates': '/checklist/templates',
        '/templates/tpl-1': '/checklist/templates/tpl-1',
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
  });
}
