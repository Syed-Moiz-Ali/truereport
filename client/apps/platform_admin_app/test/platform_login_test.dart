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

Widget _buildLoginApp({
  Locale locale = const Locale('en'),
  Future<AuthResult> Function(String email, String password)? onSignIn,
}) {
  return ProviderScope(
    overrides: [
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
}
