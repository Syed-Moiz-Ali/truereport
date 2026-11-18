import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/auth/workshop_login_page.dart';

import 'support/real_fonts.dart';

/// Gate 6 state evidence: error, submitting, validation and large text.
///
/// Default states at every breakpoint live in `workshop_real_font_screenshot_test.dart`.
/// Output: `docs/evidence/states/`.
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.failure, this.gate});

  final AppFailure? failure;
  final Completer<void>? gate;

  @override
  Future<Session?> restore() async => null;

  @override
  Future<AuthResult> signIn(String email, String password) async {
    if (gate != null) {
      await gate!.future;
    }
    final failure = this.failure;
    if (failure != null) {
      throw failure;
    }
    return const AuthChallenge('challenge');
  }

  @override
  Future<AuthResult> verifyTwoFactor(
    String challengeToken,
    String code,
  ) async => throw UnimplementedError();

  @override
  Future<Session?> refresh(String refreshToken) async => null;

  @override
  Future<void> signOut() async {}
}

void main() {
  Future<GlobalKey> pump(
    WidgetTester tester, {
    required _FakeAuthRepository repository,
    Size size = const Size(1280, 800),
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) async {
    expect(RealFonts.isLoaded, isTrue);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final key = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child ?? const SizedBox.shrink(),
          ),
          home: RepaintBoundary(
            key: key,
            child: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(textScale),
              ),
              child: const WorkshopLoginPage(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return key;
  }

  Future<void> fill(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('sign-in-email')),
      'admin.a@truereport.test',
    );
    await tester.enterText(
      find.byKey(const Key('sign-in-password')),
      'wrong-password',
    );
    await tester.pumpAndSettle();
  }

  testWidgets('error 1280 EN', (tester) async {
    final key = await pump(
      tester,
      repository: _FakeAuthRepository(
        failure: const AppFailure(
          code: 'AUTH_INVALID_CREDENTIALS',
          messageKey: 'error.auth.invalidCredentials',
          statusCode: 401,
        ),
      ),
    );
    await fill(tester);
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();
    await _captureWith(tester, key, 'signin_error_1280_en');
  });

  testWidgets('error 1280 AR', (tester) async {
    final key = await pump(
      tester,
      locale: const Locale('ar'),
      repository: _FakeAuthRepository(
        failure: const AppFailure(
          code: 'AUTH_INVALID_CREDENTIALS',
          messageKey: 'error.auth.invalidCredentials',
          statusCode: 401,
        ),
      ),
    );
    await fill(tester);
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();
    await _captureWith(tester, key, 'signin_error_1280_ar');
  });

  testWidgets('error 390 EN', (tester) async {
    final key = await pump(
      tester,
      size: const Size(390, 844),
      repository: _FakeAuthRepository(
        failure: const AppFailure(
          code: 'CONNECTIONERROR',
          messageKey: 'error.network',
        ),
      ),
    );
    await fill(tester);
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();
    await _captureWith(tester, key, 'signin_network_error_390_en');
  });

  testWidgets('submitting 1280 EN', (tester) async {
    final gate = Completer<void>();
    final key = await pump(tester, repository: _FakeAuthRepository(gate: gate));
    await fill(tester);
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    // Two pumps: one to build the submitting state, one to let the pending
    // transition settle. A single pump captured a 140 ms colour tween at t=0
    // (green fill with an invisible grey spinner).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.liveRegion == true &&
            widget.properties.label ==
                AppLocalizations.of(
                  tester.element(find.byType(WorkshopLoginPage)),
                ).signingIn,
      ),
      findsOneWidget,
      reason: 'the in-flight state must be announced',
    );
    await _captureWith(tester, key, 'signin_submitting_1280_en');
    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('AR progress figure keeps an RTL base direction', (tester) async {
    await pump(
      tester,
      locale: const Locale('ar'),
      repository: _FakeAuthRepository(),
    );
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    final figure = find.text(ar.signInExampleProgress(18, 24, 75));
    expect(figure, findsOneWidget);
    // Forcing an LTR base on this phrase reorders the Arabic counts; only the
    // ARB's own isolation of the percent is allowed here.
    expect(Directionality.of(tester.element(figure)), TextDirection.rtl);
  });

  testWidgets('AR progress figure keeps its percent and no bidi isolates', (
    tester,
  ) async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    final value = ar.signInExampleProgress(18, 24, 75);
    // The original string wrapped the percent in U+2066…U+2069. Under an RTL
    // base that pair made the renderer reserve the advance and paint nothing,
    // so the Arabic figure lost its 75%. The isolate must never come back.
    expect(value.contains('\u2066'), isFalse);
    expect(value.contains('\u2069'), isFalse);
    expect(
      RegExp(r'[%٪]\s*$').hasMatch(value),
      isTrue,
      reason: 'the figure must end with a percent sign: $value',
    );
  });

  testWidgets('validation 390 EN', (tester) async {
    final key = await pump(
      tester,
      size: const Size(390, 844),
      repository: _FakeAuthRepository(),
    );
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();
    await _captureWith(tester, key, 'signin_validation_390_en');
  });

  testWidgets('text scale 1.5 at 390', (tester) async {
    final key = await pump(
      tester,
      size: const Size(390, 844),
      textScale: 1.5,
      repository: _FakeAuthRepository(),
    );
    await _captureWith(tester, key, 'signin_textscale150_390_en');
  });

  testWidgets('text scale 2.0 at 1440', (tester) async {
    final key = await pump(
      tester,
      size: const Size(1440, 900),
      textScale: 2,
      repository: _FakeAuthRepository(),
    );
    await _captureWith(tester, key, 'signin_textscale200_1440_en');
  });

  testWidgets('text scale 2.0 at 360', (tester) async {
    final key = await pump(
      tester,
      size: const Size(360, 800),
      textScale: 2,
      repository: _FakeAuthRepository(),
    );
    await _captureWith(tester, key, 'signin_textscale200_360_en');
  });

  testWidgets('2FA required 390 EN', (tester) async {
    final key = await pump(
      tester,
      size: const Size(390, 844),
      repository: _FakeAuthRepository(),
    );
    await fill(tester);
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sign-in-submit')), findsOneWidget);
    await _captureWith(tester, key, 'signin_twofactor_390_en');
  });

  // Arabic is first-class: the phone band in RTL has never been captured, and
  // the 2FA banner is the only copy that has no dedicated key review yet.
  testWidgets('default 390 AR', (tester) async {
    final key = await pump(
      tester,
      size: const Size(390, 844),
      locale: const Locale('ar'),
      repository: _FakeAuthRepository(),
    );
    await _captureWith(tester, key, 'signin_default_390_ar');
  });

  testWidgets('error 390 AR', (tester) async {
    final key = await pump(
      tester,
      size: const Size(390, 844),
      locale: const Locale('ar'),
      repository: _FakeAuthRepository(
        failure: const AppFailure(
          code: 'AUTH_INVALID_CREDENTIALS',
          messageKey: 'error.auth.invalidCredentials',
          statusCode: 401,
        ),
      ),
    );
    await fill(tester);
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();
    await _captureWith(tester, key, 'signin_error_390_ar');
  });

  testWidgets('2FA required 390 AR', (tester) async {
    final key = await pump(
      tester,
      size: const Size(390, 844),
      locale: const Locale('ar'),
      repository: _FakeAuthRepository(),
    );
    await fill(tester);
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();
    await _captureWith(tester, key, 'signin_twofactor_390_ar');
  });
}

Future<void> _captureWith(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  final boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  expect(boundary, isNotNull);
  expect(tester.takeException(), isNull);
  await tester.runAsync(() async {
    final image = await boundary!.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('docs/evidence/states');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    File('${directory.path}/$name.png')
        .writeAsBytesSync(data!.buffer.asUint8List(), flush: true);
  });
}
