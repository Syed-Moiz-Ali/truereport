import 'dart:async';

import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/app.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/auth/workshop_login_page.dart';
import 'package:workshop_admin_app/src/features/home/workshop_admin_home.dart';

import 'support/fake_admin_api.dart';

/// Characterization tests for the invariants in `docs/invariants.md`.
///
/// These pin *today's* behaviour. They were written before any behaviour
/// changed, so a later edit that alters them is a deliberate, reviewable
/// decision — not a silent drift.
const _workshopAdminSession = Session(
  accessToken: 'token',
  refreshToken: 'refresh',
  user: User(
    id: 'user-1',
    email: 'layla@marina-auto.ae',
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

const _technicianSession = Session(
  accessToken: 'token',
  refreshToken: 'refresh',
  user: User(
    id: 'user-2',
    email: 'tech@marina-auto.ae',
    displayName: 'Technician',
    platformAdmin: false,
    totpEnabled: false,
  ),
  memberships: [
    Membership(
      workshopId: 'workshop-1',
      workshopName: 'Marina Workshop',
      role: Role.technician,
    ),
  ],
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.restored,
    this.failure,
    this.restoreGate,
    this.signInGate,
  });

  final Session? restored;
  final Object? failure;

  /// When set, `restore()` never completes — pins the loading state.
  final Completer<Session?>? restoreGate;

  /// When set, `signIn()` waits on this before answering.
  final Completer<void>? signInGate;

  final List<({String email, String password})> signInCalls = [];

  @override
  Future<Session?> restore() {
    if (restoreGate != null) {
      return restoreGate!.future;
    }
    return Future<Session?>.value(restored);
  }

  @override
  Future<AuthResult> signIn(String email, String password) async {
    signInCalls.add((email: email, password: password));
    if (signInGate != null) {
      await signInGate!.future;
    }
    final thrown = failure;
    if (thrown != null) {
      throw thrown;
    }
    return const AuthSuccess(_workshopAdminSession);
  }

  @override
  Future<AuthResult> verifyTwoFactor(String challengeToken, String code) async {
    throw UnimplementedError('the workshop app must not call this');
  }

  @override
  Future<Session?> refresh(String refreshToken) async => null;

  @override
  Future<void> signOut() async {}
}

Widget _pageHarness(
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

Future<AppLocalizations> _l10n(Locale locale) =>
    AppLocalizations.delegate.load(locale);

Future<void> _fillCredentials(WidgetTester tester) async {
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
  // ---------------------------------------------------------------------
  // I11 — stable widget keys the harness and tests depend on
  // ---------------------------------------------------------------------
  testWidgets('I11: the three stable keys resolve', (tester) async {
    await tester.pumpWidget(_pageHarness(_FakeAuthRepository()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sign-in-email')), findsOneWidget);
    expect(find.byKey(const Key('sign-in-password')), findsOneWidget);
    expect(find.byKey(const Key('sign-in-submit')), findsOneWidget);
  });

  // ---------------------------------------------------------------------
  // I7 — client-side validation blocks the request
  // ---------------------------------------------------------------------
  testWidgets('I7: empty form shows requiredField twice and sends nothing', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    final en = await _l10n(const Locale('en'));
    await tester.pumpWidget(_pageHarness(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();

    expect(find.text(en.requiredField), findsNWidgets(2));
    expect(repository.signInCalls, isEmpty);
  });

  testWidgets('I7: malformed email shows invalidEmail and sends nothing', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    final en = await _l10n(const Locale('en'));
    await tester.pumpWidget(_pageHarness(repository));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('sign-in-email')),
      'not-an-email',
    );
    await tester.enterText(find.byKey(const Key('sign-in-password')), 'secret');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();

    expect(find.text(en.invalidEmail), findsOneWidget);
    expect(repository.signInCalls, isEmpty);
  });

  // ---------------------------------------------------------------------
  // I8 — no double submit
  // ---------------------------------------------------------------------
  testWidgets('I8: double tap sends exactly one request', (tester) async {
    final gate = Completer<void>();
    final repository = _FakeAuthRepository(signInGate: gate);
    await tester.pumpWidget(_pageHarness(repository));
    await tester.pumpAndSettle();
    await _fillCredentials(tester);

    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('sign-in-submit')),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(repository.signInCalls, hasLength(1));

    gate.complete();
    await tester.pumpAndSettle();
  });

  // ---------------------------------------------------------------------
  // I9 — the eye toggle is local and never submits
  // ---------------------------------------------------------------------
  testWidgets('I9: eye toggle flips obscureText and sends nothing', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_pageHarness(repository));
    await tester.pumpAndSettle();
    await _fillCredentials(tester);

    bool passwordObscured() => tester
        .widget<EditableText>(
          find.descendant(
            of: find.byKey(const Key('sign-in-password')),
            matching: find.byType(EditableText),
          ),
        )
        .obscureText;

    expect(passwordObscured(), isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();

    expect(passwordObscured(), isFalse);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    expect(repository.signInCalls, isEmpty);
  });

  // ---------------------------------------------------------------------
  // I5 — failure code → localized copy
  // ---------------------------------------------------------------------
  for (final probe in <({String code, String Function(AppLocalizations) copy})>[
    (
      code: 'AUTH_INVALID_CREDENTIALS',
      copy: (AppLocalizations l10n) => l10n.invalidCredentials,
    ),
    (
      code: 'CONNECTIONERROR',
      copy: (AppLocalizations l10n) => l10n.networkError,
    ),
    (code: 'WEIRD_UNKNOWN', copy: (AppLocalizations l10n) => l10n.genericError),
  ]) {
    testWidgets('I5: ${probe.code} shows the mapped copy', (tester) async {
      final repository = _FakeAuthRepository(
        failure: AppFailure(
          code: probe.code,
          messageKey: 'error.test',
          statusCode: 401,
        ),
      );
      final en = await _l10n(const Locale('en'));
      await tester.pumpWidget(_pageHarness(repository));
      await tester.pumpAndSettle();
      await _fillCredentials(tester);

      await tester.tap(find.byKey(const Key('sign-in-submit')));
      await tester.pumpAndSettle();

      expect(find.text(probe.copy(en)), findsOneWidget);
      expect(
        find.byKey(const Key('sign-in-submit')),
        findsOneWidget,
        reason: 'the form stays usable after a failure',
      );
    });
  }

  // ---------------------------------------------------------------------
  // I2 — a failed attempt must not reset the form
  // ---------------------------------------------------------------------
  testWidgets('I2: a failed sign-in keeps the typed email', (tester) async {
    final repository = _FakeAuthRepository(
      failure: const AppFailure(
        code: 'AUTH_INVALID_CREDENTIALS',
        messageKey: 'error.auth.invalidCredentials',
        statusCode: 401,
      ),
    );
    await tester.pumpWidget(_pageHarness(repository));
    await tester.pumpAndSettle();
    await _fillCredentials(tester);

    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();

    final email = tester.widget<TextFormField>(
      find.byKey(const Key('sign-in-email')),
    );
    expect(email.controller?.text, 'admin.a@truereport.test');
  });

  // ---------------------------------------------------------------------
  // Arabic — the error copy is translated, not just the labels
  // ---------------------------------------------------------------------
  testWidgets('I5 ar: invalid credentials is localized in Arabic', (
    tester,
  ) async {
    final repository = _FakeAuthRepository(
      failure: const AppFailure(
        code: 'AUTH_INVALID_CREDENTIALS',
        messageKey: 'error.auth.invalidCredentials',
        statusCode: 401,
      ),
    );
    final ar = await _l10n(const Locale('ar'));
    await tester.pumpWidget(
      _pageHarness(repository, locale: const Locale('ar')),
    );
    await tester.pumpAndSettle();
    await _fillCredentials(tester);

    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();

    expect(find.text(ar.invalidCredentials), findsOneWidget);
    expect(find.text(ar.invalidCredentials), isNot(find.text('')));
  });

  // ---------------------------------------------------------------------
  // I1 — the redirect matrix (router behaviour)
  // ---------------------------------------------------------------------
  group('I1 redirect matrix', () {
    Future<void> pumpApp(
      WidgetTester tester,
      _FakeAuthRepository repository,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repository),
            adminApiProvider.overrideWithValue(FakeAdminApi()),
          ],
          child: const AdminApp(),
        ),
      );
    }

    testWidgets('no session lands on sign-in', (tester) async {
      await pumpApp(tester, _FakeAuthRepository());
      await tester.pumpAndSettle();

      expect(find.byType(WorkshopLoginPage), findsOneWidget);
      expect(find.byType(WorkshopAdminHomePage), findsNothing);
    });

    testWidgets('a workshop admin lands on the workshop home', (tester) async {
      await pumpApp(
        tester,
        _FakeAuthRepository(restored: _workshopAdminSession),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WorkshopAdminHomePage), findsOneWidget);
      expect(find.byType(WorkshopLoginPage), findsNothing);
    });

    testWidgets('a technician lands on unauthorized, never the shell', (
      tester,
    ) async {
      final en = await _l10n(const Locale('en'));
      await pumpApp(tester, _FakeAuthRepository(restored: _technicianSession));
      await tester.pumpAndSettle();

      expect(find.byType(WorkshopAdminHomePage), findsNothing);
      expect(find.text(en.signOut), findsOneWidget);
    });

    testWidgets('a pending restore does not redirect away from sign-in', (
      tester,
    ) async {
      final gate = Completer<Session?>();
      await pumpApp(tester, _FakeAuthRepository(restoreGate: gate));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(WorkshopLoginPage), findsOneWidget);
      expect(find.byType(WorkshopAdminHomePage), findsNothing);

      gate.complete(null);
      await tester.pumpAndSettle();
      expect(find.byType(WorkshopLoginPage), findsOneWidget);
    });
  });
}
