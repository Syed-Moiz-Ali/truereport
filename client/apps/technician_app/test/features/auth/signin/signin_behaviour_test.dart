import 'dart:async';
import 'dart:io';

import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/features/auth/signin/technician_sign_in_page.dart';

import '../../../support/f2a_test_fonts.dart';

class _FakeAuthController extends AuthController {
  _FakeAuthController({required this.onSignIn, required this.onVerify});

  final Future<AuthResult> Function(String email, String password) onSignIn;
  final Future<AuthResult> Function(String token, String code) onVerify;

  int signInCalls = 0;
  int verifyCalls = 0;
  final List<String> codes = <String>[];
  final List<String> tokens = <String>[];

  @override
  Future<Session?> build() async => null;

  @override
  Future<AuthResult> signIn(String email, String password) {
    signInCalls++;
    return onSignIn(email, password);
  }

  @override
  Future<AuthResult> verifyTwoFactor(String challengeToken, String code) {
    verifyCalls++;
    tokens.add(challengeToken);
    codes.add(code);
    return onVerify(challengeToken, code);
  }
}

Session _technicianSession() => const Session(
  accessToken: 'access',
  refreshToken: 'refresh',
  user: User(
    id: 'u1',
    email: 'tech@example.com',
    displayName: 'Tech',
    platformAdmin: false,
    totpEnabled: false,
  ),
  memberships: [
    Membership(
      workshopId: 'w1',
      workshopName: 'Workshop',
      role: Role.technician,
    ),
  ],
);

void main() {
  setUpAll(loadF2AFonts);

  Future<AppLocalizations> pumpPage(
    WidgetTester tester,
    _FakeAuthController fake, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith(() => fake)],
        child: Consumer(
          builder: (context, ref, _) {
            final active = ref.watch(localeProvider);
            return MaterialApp(
              locale: active,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              theme: buildAppTheme(),
              home: const TechnicianSignInPage(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.of(
      tester.element(find.byType(TechnicianSignInPage)),
    );
  }

  _FakeAuthController successFake() => _FakeAuthController(
    onSignIn: (_, _) async => AuthSuccess(_technicianSession()),
    onVerify: (_, _) async => AuthSuccess(_technicianSession()),
  );

  testWidgets('invalid submit never calls the repository', (tester) async {
    final fake = successFake();
    final l10n = await pumpPage(tester, fake);

    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();

    expect(fake.signInCalls, 0);
    expect(find.text(l10n.requiredField), findsNWidgets(2));
  });

  testWidgets('double submit issues exactly one request', (tester) async {
    final completer = Completer<AuthResult>();
    final fake = _FakeAuthController(
      onSignIn: (_, _) => completer.future,
      onVerify: (_, _) async => AuthSuccess(_technicianSession()),
    );
    await pumpPage(tester, fake);

    await tester.enterText(
      find.byKey(const Key('sign-in-email')),
      'tech@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('sign-in-password')),
      'secret-password',
    );

    // Enter submits from the password; the second Enter arrives while the
    // first request is still in flight.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(fake.signInCalls, 1);

    completer.complete(AuthSuccess(_technicianSession()));
    await tester.pumpAndSettle();
  });

  for (final entry in <(String, String Function(AppLocalizations))>[
    ('AUTH_INVALID_CREDENTIALS', (l10n) => l10n.invalidCredentials),
    ('CONNECTIONERROR', (l10n) => l10n.networkError),
    ('ACCOUNT_DISABLED', (l10n) => l10n.genericError),
  ]) {
    testWidgets('error mapping: ${entry.$1}', (tester) async {
      final fake = _FakeAuthController(
        onSignIn: (_, _) async =>
            throw AppFailure(code: entry.$1, messageKey: 'error.unauthorized'),
        onVerify: (_, _) async => AuthSuccess(_technicianSession()),
      );
      final l10n = await pumpPage(tester, fake);
      await tester.enterText(
        find.byKey(const Key('sign-in-email')),
        'tech@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('sign-in-password')),
        'secret-password',
      );
      await tester.tap(find.byKey(const Key('sign-in-submit')));
      await tester.pumpAndSettle();
      expect(find.text(entry.$2(l10n)), findsOneWidget, reason: entry.$1);
    });
  }

  testWidgets('2FA challenge renders the code cell and verifies', (
    tester,
  ) async {
    final fake = _FakeAuthController(
      onSignIn: (_, _) async => const AuthChallenge('challenge-1'),
      onVerify: (_, _) async => AuthSuccess(_technicianSession()),
    );
    final l10n = await pumpPage(tester, fake);

    await tester.enterText(
      find.byKey(const Key('sign-in-email')),
      'tech@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('sign-in-password')),
      'secret-password',
    );
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sign-in-code')), findsOneWidget);
    expect(find.text(l10n.verifyButton), findsOneWidget);
    // The account stays visible, read-only.
    expect(find.byKey(const Key('sign-in-email')), findsOneWidget);
    expect(find.byKey(const Key('sign-in-password')), findsNothing);

    await tester.enterText(find.byKey(const Key('sign-in-code')), '123456');
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();

    expect(fake.verifyCalls, 1);
    expect(fake.tokens.single, 'challenge-1');
    expect(fake.codes.single, '123456');
  });

  testWidgets('2FA accepts an 11-character recovery code', (tester) async {
    final fake = _FakeAuthController(
      onSignIn: (_, _) async => const AuthChallenge('challenge-2'),
      onVerify: (_, _) async => AuthSuccess(_technicianSession()),
    );
    await pumpPage(tester, fake);

    await tester.enterText(
      find.byKey(const Key('sign-in-email')),
      'tech@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('sign-in-password')),
      'secret-password',
    );
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('sign-in-code')),
      'ABCDE-FGHIJ',
    );
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();

    expect(fake.verifyCalls, 1);
    expect(fake.codes.single, 'ABCDE-FGHIJ');
  });

  testWidgets('a malformed code never reaches the repository', (tester) async {
    final fake = _FakeAuthController(
      onSignIn: (_, _) async => const AuthChallenge('challenge-3'),
      onVerify: (_, _) async => AuthSuccess(_technicianSession()),
    );
    final l10n = await pumpPage(tester, fake);

    await tester.enterText(
      find.byKey(const Key('sign-in-email')),
      'tech@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('sign-in-password')),
      'secret-password',
    );
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('sign-in-code')), 'ABC');
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();

    expect(fake.verifyCalls, 0);
    expect(find.text(l10n.requiredField), findsOneWidget);
  });

  testWidgets('locale switch flips direction and preserves values', (
    tester,
  ) async {
    final fake = successFake();
    await pumpPage(tester, fake);

    await tester.enterText(
      find.byKey(const Key('sign-in-email')),
      'tech@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('sign-in-password')),
      'secret-password',
    );

    await tester.tap(find.byKey(const Key('sign-in-language-ar')));
    await tester.pumpAndSettle();

    expect(
      Directionality.of(
        tester.element(find.byKey(const Key('sign-in-submit'))),
      ),
      TextDirection.rtl,
    );
    expect(find.text('tech@example.com'), findsOneWidget);
  });

  testWidgets('language switch is keyboard operable and first in tab order', (
    tester,
  ) async {
    final fake = successFake();
    await pumpPage(tester, fake);

    // Tab reaches the English segment, then the Arabic segment; Enter
    // activates it (WCAG 2.1.1 — the switch was pointer-only before this test).
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(
      Directionality.of(
        tester.element(find.byKey(const Key('sign-in-submit'))),
      ),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a 2FA failure maps to the credential copy and keeps the token', (
    tester,
  ) async {
    final fake = _FakeAuthController(
      onSignIn: (_, _) async => const AuthChallenge('token-2fa'),
      onVerify: (_, _) async => throw const AppFailure(
        code: 'AUTH_2FA_INVALID',
        messageKey: 'error.unauthorized',
      ),
    );
    final l10n = await pumpPage(tester, fake);

    await tester.enterText(
      find.byKey(const Key('sign-in-email')),
      'tech@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('sign-in-password')),
      'secret-password',
    );
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('sign-in-code')), '123456');
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();

    expect(fake.tokens.single, 'token-2fa');
    expect(find.text(l10n.invalidCredentials), findsOneWidget);
  });

  testWidgets('invalid submit moves focus to the first invalid field', (
    tester,
  ) async {
    final fake = successFake();
    await pumpPage(tester, fake);

    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();

    final email = tester.widget<TextField>(
      find.byKey(const Key('sign-in-email')),
    );
    expect(email.focusNode?.hasFocus, isTrue);
  });

  testWidgets('an auth failure returns focus to the password', (tester) async {
    final fake = _FakeAuthController(
      onSignIn: (_, _) async => throw const AppFailure(
        code: 'AUTH_INVALID_CREDENTIALS',
        messageKey: 'error.unauthorized',
      ),
      onVerify: (_, _) async => AuthSuccess(_technicianSession()),
    );
    await pumpPage(tester, fake);

    await tester.enterText(
      find.byKey(const Key('sign-in-email')),
      'tech@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('sign-in-password')),
      'secret-password',
    );
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();

    final password = tester.widget<TextField>(
      find.byKey(const Key('sign-in-password')),
    );
    expect(password.focusNode?.hasFocus, isTrue);
  });

  testWidgets('the reveal target is at least 44 x 44', (tester) async {
    final fake = successFake();
    await pumpPage(tester, fake);

    final size = tester.getSize(find.byType(IconButton));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('the audited widget keys are present', (tester) async {
    final fake = successFake();
    await pumpPage(tester, fake);

    for (final key in const [
      'sign-in-email',
      'sign-in-password',
      'sign-in-submit',
      'sign-in-language-en',
      'sign-in-language-ar',
      'sign-in-access-prompt',
      'sign-in-security-line',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
  });

  testWidgets('the reveal control has an accessible name', (tester) async {
    final fake = successFake();
    final l10n = await pumpPage(tester, fake);

    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(button.tooltip, l10n.passwordLabel);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  test('the sign-in page never logs credentials', () {
    final file = File(
      '${repoRoot().path}/client/apps/technician_app/lib/src/'
      'features/auth/signin/technician_sign_in_page.dart',
    );
    final source = file.readAsStringSync();
    expect(source.contains('debugPrint'), isFalse);
    expect(RegExp(r'\bprint\s*\(').hasMatch(source), isFalse);
    expect(source.contains('_password.text'), isTrue);
  });
}
