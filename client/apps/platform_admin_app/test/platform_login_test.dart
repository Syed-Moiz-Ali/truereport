import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/features/auth/platform_login_page.dart';
import 'package:platform_admin_app/src/platform_providers.dart';

import 'support/ui_message_fixtures.dart';

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._onSignIn);

  final Future<AuthResult> Function(String email, String password) _onSignIn;

  @override
  Future<Session?> build() async => null;

  @override
  Future<AuthResult> signIn(String email, String password) {
    return _onSignIn(email, password);
  }
}

Session _session() => const Session(
  accessToken: 'test-access',
  refreshToken: 'test-refresh',
  user: User(
    id: 'user-1',
    email: 'admin@truereport.test',
    displayName: 'Platform Admin',
    platformAdmin: true,
    totpEnabled: false,
  ),
  memberships: [],
);

GoRouter _router() => GoRouter(
  initialLocation: '/signin',
  routes: [
    GoRoute(
      path: '/signin',
      builder: (context, state) => const PlatformLoginPage(),
    ),
    GoRoute(
      path: '/workshops',
      builder: (context, state) =>
          const Scaffold(body: Text('WORKSHOPS_ROUTE')),
    ),
  ],
);

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

Widget _buildLoginApp({
  Locale locale = const Locale('en'),
  Future<AuthResult> Function(String email, String password)? onSignIn,
  UiMessageManifest? manifest,
}) {
  return ProviderScope(
    overrides: [
      uiStringsProvider.overrideWithValue(
        locale.languageCode == 'ar' ? fakeArUiStrings() : fakeEnUiStrings(),
      ),
      if (manifest != null)
        uiMessageControllerProvider.overrideWith(
          () => _FakeUiMessageController(manifest),
        ),
      authControllerProvider.overrideWith(
        () => _FakeAuthController(
          onSignIn ?? (email, password) async => AuthSuccess(_session()),
        ),
      ),
    ],
    child: MaterialApp.router(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      routerConfig: _router(),
    ),
  );
}

void _setViewport(
  WidgetTester tester, {
  double width = 1280,
  double height = 800,
}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _submit(
  WidgetTester tester, {
  String email = 'admin@truereport.test',
  String password = 'local-test-password',
}) async {
  await tester.enterText(find.byKey(const Key('sign-in-email')), email);
  await tester.enterText(find.byKey(const Key('sign-in-password')), password);
  await tester.tap(find.byKey(const Key('sign-in-submit')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Platform login renders desktop split view without overflow', (
    tester,
  ) async {
    _setViewport(tester, width: 1280, height: 800);
    await tester.pumpWidget(_buildLoginApp());
    await tester.pumpAndSettle();

    expect(find.text('PLATFORM ADMINISTRATION'), findsWidgets);
    expect(
      find.text('Global Automotive Diagnostic Network Administration'),
      findsWidgets,
    );
    expect(find.text('Workshop Management'), findsOneWidget);
    expect(find.text('Checklist Library'), findsOneWidget);
    expect(find.text('Immutable Security Ledger'), findsOneWidget);

    expect(find.text('Sign in to Portal'), findsOneWidget);
    expect(find.text('AUTHORIZED ACCESS ONLY'), findsOneWidget);
    expect(find.byKey(const Key('sign-in-email')), findsOneWidget);
    expect(find.byKey(const Key('sign-in-password')), findsOneWidget);
    expect(find.byKey(const Key('sign-in-submit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Demo login chip and quick-fill button are absent', (
    tester,
  ) async {
    _setViewport(tester, width: 1280, height: 800);
    await tester.pumpWidget(_buildLoginApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn-direct-demo-access')), findsNothing);
    expect(find.byKey(const Key('btn-fill-demo')), findsNothing);
    expect(find.textContaining('Demo'), findsNothing);
  });

  testWidgets('Invalid credentials show an error and do not navigate', (
    tester,
  ) async {
    _setViewport(tester, width: 1280, height: 800);
    await tester.pumpWidget(
      _buildLoginApp(
        onSignIn: (email, password) async {
          throw const AppFailure(
            code: 'AUTH_INVALID_CREDENTIALS',
            messageKey: 'invalidCredentials',
            statusCode: 401,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await _submit(tester, email: 'admin@truereport.test', password: 'wrong');

    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    expect(find.byKey(const Key('sign-in-submit')), findsOneWidget);
    expect(find.text('WORKSHOPS_ROUTE'), findsNothing);
  });

  testWidgets('Successful login navigates to the authenticated route', (
    tester,
  ) async {
    _setViewport(tester, width: 1280, height: 800);
    await tester.pumpWidget(_buildLoginApp());
    await tester.pumpAndSettle();

    await _submit(tester);

    expect(find.text('WORKSHOPS_ROUTE'), findsOneWidget);
    expect(find.byKey(const Key('sign-in-submit')), findsNothing);
  });

  testWidgets('Platform login renders Arabic RTL without overflow', (
    tester,
  ) async {
    _setViewport(tester, width: 1280, height: 800);
    await tester.pumpWidget(_buildLoginApp(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sign-in-submit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Platform login renders compact view on mobile without overflow',
    (tester) async {
      _setViewport(tester, width: 400, height: 840);
      await tester.pumpWidget(_buildLoginApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sign-in-email')), findsOneWidget);
      expect(find.byKey(const Key('sign-in-password')), findsOneWidget);
      expect(find.byKey(const Key('sign-in-submit')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Login language picker lists every manifest language', (
    tester,
  ) async {
    _setViewport(tester, width: 1280, height: 800);
    await tester.pumpWidget(_buildLoginApp(manifest: _testManifest()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sign-in-language-menu')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sign-in-language-en')), findsOneWidget);
    expect(find.byKey(const Key('sign-in-language-ar')), findsOneWidget);
    expect(find.byKey(const Key('sign-in-language-zh-hans')), findsOneWidget);
    expect(find.text('English'), findsWidgets);
    expect(find.text('العربية'), findsWidgets);
    expect(find.text('中文'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Selecting zh-hans on login switches locale without auth', (
    tester,
  ) async {
    _setViewport(tester, width: 1280, height: 800);
    await tester.pumpWidget(_buildLoginApp(manifest: _testManifest()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sign-in-language-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sign-in-language-zh-hans')));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('sign-in-submit'))),
    );
    final locale = container.read(platformLocaleProvider);
    expect(locale.languageCode, 'zh');
    expect(locale.scriptCode, 'Hans');
    expect(
      container.read(uiMessageControllerProvider).activeLanguage,
      'zh-hans',
    );
    expect(find.byKey(const Key('sign-in-submit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AdminSignInView legacy toggle still works without options', (
    tester,
  ) async {
    _setViewport(tester, width: 1280, height: 800);
    var arabic = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminSignInView(
            portalType: AdminPortalType.platform,
            emailController: TextEditingController(),
            passwordController: TextEditingController(),
            codeController: TextEditingController(),
            formKey: GlobalKey<FormState>(),
            isArabic: arabic,
            onLocaleChanged: (value) => arabic = value,
            onSubmit: () {},
            onValidateEmail: (_) => null,
            onValidateRequired: (_) => null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('العربية'), findsOneWidget);
    expect(find.byKey(const Key('sign-in-language-menu')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
