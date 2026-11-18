import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/app.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/api_language_sync.dart';
import 'package:workshop_admin_app/src/features/auth/workshop_login_page.dart';

import 'support/fake_admin_api.dart';

/// Tests for the behaviour changes in Brief 1 (R5, R6, R7, R9).
///
/// Every assertion here would fail on the pre-brief code.
/// The pre-brief behaviour is preserved separately in
/// `signin_characterization_test.dart`.
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.result});

  final AuthResult? result;

  int signInCalls = 0;
  int verifyCalls = 0;

  @override
  Future<Session?> restore() async => null;

  @override
  Future<AuthResult> signIn(String email, String password) async {
    signInCalls++;
    return result!;
  }

  @override
  Future<AuthResult> verifyTwoFactor(String challengeToken, String code) async {
    verifyCalls++;
    throw StateError('the admin app must never call verifyTwoFactor');
  }

  @override
  Future<Session?> refresh(String refreshToken) async => null;

  @override
  Future<void> signOut() async {}
}

Session _sessionWithRoles(List<Role> roles) => Session(
  accessToken: 'token',
  refreshToken: 'refresh',
  user: const User(
    id: 'user-1',
    email: 'admin.a@truereport.test',
    displayName: 'Admin',
    platformAdmin: false,
    totpEnabled: false,
  ),
  memberships: [
    for (final (index, role) in roles.indexed)
      Membership(
        workshopId: 'workshop-$index',
        workshopName: 'Workshop $index',
        role: role,
      ),
  ],
);

Widget _harness(
  _FakeAuthRepository repository, {
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      home: const WorkshopLoginPage(),
    ),
  );
}

Future<void> _fill(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('sign-in-email')),
    'admin.a@truereport.test',
  );
  await tester.enterText(
    find.byKey(const Key('sign-in-password')),
    'local-password',
  );
  await tester.pumpAndSettle();
}

void main() {
  // R5 — a 2FA challenge is explained, never swallowed.
  group('R5 two-factor challenge', () {
    testWidgets('shows the localized message and does not enter TOTP', (
      tester,
    ) async {
      final repository = _FakeAuthRepository(
        result: const AuthChallenge('challenge-token'),
      );
      final en = await AppLocalizations.delegate.load(const Locale('en'));

      await tester.pumpWidget(_harness(repository));
      await tester.pumpAndSettle();
      await _fill(tester);
      await tester.tap(find.byKey(const Key('sign-in-submit')));
      await tester.pumpAndSettle();

      expect(find.text(en.twoFactorRequired), findsOneWidget);
      expect(repository.signInCalls, 1);
      expect(
        repository.verifyCalls,
        0,
        reason: 'the admin app has no TOTP UI by design',
      );
      expect(find.byKey(const Key('sign-in-submit')), findsOneWidget);
    });

    testWidgets('is localized in Arabic', (tester) async {
      final repository = _FakeAuthRepository(
        result: const AuthChallenge('challenge-token'),
      );
      final ar = await AppLocalizations.delegate.load(const Locale('ar'));

      await tester.pumpWidget(_harness(repository, locale: const Locale('ar')));
      await tester.pumpAndSettle();
      await _fill(tester);
      await tester.tap(find.byKey(const Key('sign-in-submit')));
      await tester.pumpAndSettle();

      expect(find.text(ar.twoFactorRequired), findsOneWidget);
    });
  });

  // R9 — password managers get a proper autofill scope.
  testWidgets('R9: the form is wrapped in an AutofillGroup', (tester) async {
    await tester.pumpWidget(_harness(_FakeAuthRepository()));
    await tester.pumpAndSettle();

    expect(find.byType(AutofillGroup), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AutofillGroup),
        matching: find.byKey(const Key('sign-in-email')),
      ),
      findsOneWidget,
    );
  });

  // R6 — membership order must not decide privilege.
  group('R6 session role', () {
    test('admin wins when the admin membership is second', () {
      expect(
        _sessionWithRoles([Role.technician, Role.workshopAdmin]).role,
        Role.workshopAdmin,
      );
    });

    test('admin wins when the admin membership is first', () {
      expect(
        _sessionWithRoles([Role.workshopAdmin, Role.technician]).role,
        Role.workshopAdmin,
      );
    });

    test('no memberships is least privilege', () {
      expect(_sessionWithRoles(const []).role, Role.technician);
    });

    test('platform admin flag still wins over memberships', () {
      const session = Session(
        accessToken: 't',
        refreshToken: 'r',
        user: User(
          id: 'u',
          email: 'p@truereport.test',
          displayName: 'P',
          platformAdmin: true,
          totpEnabled: false,
        ),
        memberships: [
          Membership(
            workshopId: 'w',
            workshopName: 'W',
            role: Role.workshopAdmin,
          ),
        ],
      );
      expect(session.role, Role.platformAdmin);
    });
  });

  // G5 — an unknown server role degrades to least privilege, loudly pinned.
  group('G5 unknown role', () {
    test('an unrecognised role string is not granted a known role', () {
      expect(Role.fromApi('SUPER_ADMIN'), isNull);
    });

    test('membership parsing falls back to least privilege', () {
      final membership = Membership.fromJson(const <String, dynamic>{
        'workshopId': 'w1',
        'workshopName': 'Workshop',
        'role': 'SUPER_ADMIN',
      });
      expect(membership.role, Role.leastPrivilege);
      expect(membership.role, Role.technician);
    });

    test('a null role falls back to least privilege', () {
      final membership = Membership.fromJson(const <String, dynamic>{
        'workshopId': 'w1',
        'workshopName': 'Workshop',
      });
      expect(membership.role, Role.technician);
    });
  });

  // R7 — Accept-Language and X-Client follow the locale.
  group('R7 API language sync', () {
    test('sets the client marker and the active language', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(apiLanguageSyncProvider);
      final api = container.read(apiClientProvider);

      expect(api.clientName, 'workshop_admin');
      expect(api.acceptLanguage, 'en');
    });

    test('follows a locale change', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // The root widget watches this provider, so keep it alive here too.
      container.listen<void>(
        apiLanguageSyncProvider,
        (_, _) {},
        fireImmediately: true,
      );
      container.read(localeProvider.notifier).setLocale(const Locale('ar'));
      // Recompute after the locale change (the app does this via ref.watch).
      container.read(apiLanguageSyncProvider);

      expect(container.read(apiClientProvider).acceptLanguage, 'ar');
    });

    testWidgets('the running app keeps the client in sync', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
            adminApiProvider.overrideWithValue(FakeAdminApi()),
          ],
          child: const AdminApp(),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AdminApp)),
      );
      expect(container.read(apiClientProvider).clientName, 'workshop_admin');
      expect(container.read(apiClientProvider).acceptLanguage, 'en');
    });
  });
}
