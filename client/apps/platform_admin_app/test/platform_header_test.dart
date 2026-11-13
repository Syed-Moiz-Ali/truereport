import 'package:api_client/api_client.dart';
import 'package:auth/auth.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/components/platform_context_bar.dart';
import 'package:platform_admin_app/src/components/platform_header.dart';
import 'package:platform_admin_app/src/platform_config_api.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';

import 'support/ui_message_fixtures.dart';

class _TestAuth extends AuthController {
  _TestAuth(this.session, {this.onSignOut});

  final Session? session;
  final VoidCallback? onSignOut;

  @override
  Future<Session?> build() async => session;

  @override
  Future<void> signOut() async {
    onSignOut?.call();
    state = const AsyncData(null);
  }
}

Session _session({String name = 'Test Admin', bool admin = true}) {
  return Session(
    accessToken: 'access',
    refreshToken: 'refresh',
    user: User(
      id: 'u-1',
      email: 'admin@truereport.test',
      displayName: name,
      platformAdmin: admin,
      totpEnabled: false,
    ),
    memberships: const [],
  );
}

UiMessageManifest _testManifest() => const UiMessageManifest(
  defaultLanguage: 'en',
  namespaceVersions: {'platform_admin': 1, 'common': 1},
  languages: [
    UiMessageLanguage(
      code: 'en',
      direction: 'ltr',
      nativeName: 'English',
      nameEn: 'English',
    ),
    UiMessageLanguage(
      code: 'ar',
      direction: 'rtl',
      nativeName: 'العربية',
      nameEn: 'Arabic',
    ),
    UiMessageLanguage(
      code: 'zh-hans',
      direction: 'ltr',
      nativeName: '中文',
      nameEn: 'Chinese',
    ),
  ],
);

class _FakeUiMessageController extends UiMessageController {
  _FakeUiMessageController(this.manifest);

  final UiMessageManifest manifest;

  @override
  UiMessageState build() => UiMessageState(
    manifest: manifest,
    activeLanguage: 'en',
    defaultLanguage: 'en',
    ready: true,
    revision: 1,
  );

  @override
  Future<bool> useLanguage(String code) async {
    state = state.copyWith(activeLanguage: code, revision: state.revision + 1);
    return true;
  }
}

class _RecordingConfigApi extends PlatformConfigApi {
  _RecordingConfigApi()
    : super(
        ApiClient(
          config: const ApiConfig(
            baseUrl: 'http://localhost',
            environment: 'test',
          ),
        ),
        const ApiEndpoints(baseUrl: 'http://localhost'),
      );

  final List<String> persistedLanguages = [];

  @override
  Future<MeLanguage> setMeLanguage(String code) async {
    persistedLanguages.add(code);
    return MeLanguage(language: code, direction: 'ltr', fallback: 'en');
  }
}

Widget _app({
  Session? session,
  VoidCallback? onSignOut,
  Locale locale = const Locale('en'),
  Size size = const Size(1280, 800),
  List<ContextBreadcrumbItem>? breadcrumbs,
  List<Widget>? actions,
  ValueChanged<String>? onSearchChanged,
  _RecordingConfigApi? configApi,
}) {
  final manifest = _testManifest();
  return ProviderScope(
    overrides: [
      uiStringsProvider.overrideWith((ref) {
        final effectiveLocale = ref.watch(platformLocaleProvider);
        return effectiveLocale.languageCode == 'ar'
            ? fakeArUiStrings()
            : fakeEnUiStrings();
      }),
      uiMessageControllerProvider.overrideWith(
        () => _FakeUiMessageController(manifest),
      ),
      platformConfigApiProvider.overrideWithValue(
        configApi ?? _RecordingConfigApi(),
      ),
      authControllerProvider.overrideWith(
        () => _TestAuth(session, onSignOut: onSignOut),
      ),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        // Bind the test MaterialApp to the shared locale provider so the
        // language toggle test observes a real EN<->AR switch.
        ref.watch(platformLocaleProvider);
        final effective = ref.read(platformLocaleProvider);
        return MaterialApp(
          locale: effective,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: Scaffold(
              body: Column(
                children: [
                  PlatformHeader(onSearchChanged: onSearchChanged ?? (_) {}),
                  if (breadcrumbs != null)
                    PlatformContextBar(
                      breadcrumbs: breadcrumbs,
                      actions: actions ?? const [],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets(
    'header renders Figma search pill from ARB with no hardcoded identity',
    (tester) async {
      _setSize(tester, const Size(1280, 800));
      await tester.pumpWidget(_app(session: _session()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('header-search')), findsOneWidget);
      expect(
        find.text('Search platform assets, specs, workshop nodes...'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('btn-header-notifications')), findsOneWidget);
      expect(find.byKey(const Key('btn-header-help')), findsOneWidget);
      expect(find.byKey(const Key('btn-header-user-menu')), findsOneWidget);
      // Real session data, never the old hardcoded person.
      expect(find.text('Test Admin'), findsOneWidget);
      expect(find.text('Platform Admin'), findsOneWidget);
      expect(find.text('Alex Vance'), findsNothing);
      expect(find.text('Principal Admin'), findsNothing);
      expect(find.text('AV'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('notification button opens an empty-state sheet (not dead)', (
    tester,
  ) async {
    _setSize(tester, const Size(1280, 800));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn-header-notifications')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notifications-sheet')), findsOneWidget);
    expect(find.text('No notifications yet'), findsOneWidget);
  });

  testWidgets('help button opens a help sheet with support contact', (
    tester,
  ) async {
    _setSize(tester, const Size(1280, 800));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn-header-help')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('help-sheet')), findsOneWidget);
    expect(find.text('Help & support'), findsOneWidget);
    expect(find.text('support@truereport.test'), findsOneWidget);
  });

  testWidgets('user menu lists every manifest language and sign out', (
    tester,
  ) async {
    _setSize(tester, const Size(1280, 800));
    await tester.pumpWidget(_app(session: _session()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn-header-user-menu')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('menu-language-en')), findsOneWidget);
    expect(find.byKey(const Key('menu-language-ar')), findsOneWidget);
    expect(find.byKey(const Key('menu-language-zh-hans')), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('中文'), findsOneWidget);
    expect(find.byKey(const Key('menu-sign-out')), findsOneWidget);
    expect(find.byKey(const Key('menu-toggle-language')), findsNothing);
  });

  testWidgets('selecting a manifest language switches locale and persists', (
    tester,
  ) async {
    _setSize(tester, const Size(1280, 800));
    final configApi = _RecordingConfigApi();
    await tester.pumpWidget(_app(session: _session(), configApi: configApi));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn-header-user-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-language-zh-hans')));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PlatformHeader)),
    );
    final locale = container.read(platformLocaleProvider);
    expect(locale.languageCode, 'zh');
    expect(locale.scriptCode, 'Hans');
    expect(
      container.read(uiMessageControllerProvider).activeLanguage,
      'zh-hans',
    );
    expect(container.read(apiClientProvider).acceptLanguage, 'zh-hans');
    expect(configApi.persistedLanguages, ['zh-hans']);
  });

  testWidgets('user menu sign out calls the auth controller', (tester) async {
    var signedOut = false;
    _setSize(tester, const Size(1280, 800));
    await tester.pumpWidget(
      _app(session: _session(), onSignOut: () => signedOut = true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn-header-user-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-sign-out')));
    await tester.pumpAndSettle();

    expect(signedOut, isTrue);
  });

  testWidgets('compact width hides name/role and keeps avatar menu', (
    tester,
  ) async {
    _setSize(tester, const Size(360, 800));
    await tester.pumpWidget(_app(session: _session()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn-header-user-menu')), findsOneWidget);
    // Identity text is hidden on compact; the avatar menu remains.
    expect(find.text('Test Admin'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('context bar renders passed breadcrumbs and page actions', (
    tester,
  ) async {
    _setSize(tester, const Size(1280, 800));
    await tester.pumpWidget(
      _app(
        breadcrumbs: const [
          ContextBreadcrumbItem(label: 'HIERARCHY ROOT'),
          ContextBreadcrumbItem(label: 'EMEA INDUSTRIAL HUB'),
          ContextBreadcrumbItem(label: 'Active Workshops'),
        ],
        actions: const [Text('Directory View'), Text('Throughput')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HIERARCHY ROOT'), findsOneWidget);
    expect(find.text('EMEA INDUSTRIAL HUB'), findsOneWidget);
    expect(find.text('Active Workshops'), findsOneWidget);
    expect(find.text('Directory View'), findsOneWidget);
    expect(find.text('Throughput'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RTL Arabic header and context bar do not overflow', (
    tester,
  ) async {
    for (final size in [const Size(1280, 800), const Size(360, 800)]) {
      _setSize(tester, size);
      await tester.pumpWidget(
        _app(
          session: _session(name: 'مدير المنصة'),
          locale: const Locale('ar'),
          size: size,
          breadcrumbs: const [
            ContextBreadcrumbItem(label: 'جذر الهيكل'),
            ContextBreadcrumbItem(label: 'EMEA INDUSTRIAL HUB'),
            ContextBreadcrumbItem(label: 'الورش النشطةة'),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('desktop sizes 1280/1440 and compact 768/360 do not overflow', (
    tester,
  ) async {
    for (final width in [1280.0, 1440.0, 768.0, 360.0]) {
      _setSize(tester, Size(width, 800));
      await tester.pumpWidget(
        _app(session: _session(), size: Size(width, 800)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
