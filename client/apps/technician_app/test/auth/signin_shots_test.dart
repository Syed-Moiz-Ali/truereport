/// Real-font screenshots of the Bay Door sign-in in every audited state.
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';

import 'support/auth_sample.dart';

const _hero = AssetImage(
  'assets/images/signin_hero_technician.jpg',
  package: 'auth',
);

Future<void> _shot(
  WidgetTester tester, {
  required String name,
  required PreviewAuthState state,
  required double width,
  required double height,
  bool rtl = false,
  double scale = 1,
  bool settle = true,
  bool focusPrimary = false,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final data = PreviewAuthData(arabic: rtl);
  await tester.pumpWidget(
    UiStringsScope(
      strings: UiStrings.fromMessages(data.messages),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: Locale(rtl ? 'ar' : 'en'),
        supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        builder: (context, child) => Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        home: AuthPreviewScreen(data: data, state: state),
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(() async {
    try {
      await precacheImage(
        _hero,
        tester.element(find.byType(AuthPreviewScreen)),
      );
    } catch (_) {}
  });
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 250));
  }
  if (focusPrimary) {
    await tester.tap(find.byKey(const Key('sign-in-email')));
    await tester.pump();
    for (var step = 0; step < 3; step++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }
  expect(tester.takeException(), isNull);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('screenshots/$name.png'),
  );
}

void main() {
  testWidgets('signin_390', (tester) async {
    await _shot(
      tester,
      name: 'signin_390',
      state: PreviewAuthState.normal,
      width: 390,
      height: 844,
    );
  });

  testWidgets('signin_1440', (tester) async {
    await _shot(
      tester,
      name: 'signin_1440',
      state: PreviewAuthState.normal,
      width: 1440,
      height: 900,
    );
  });

  testWidgets('signin_390_challenge', (tester) async {
    await _shot(
      tester,
      name: 'signin_390_challenge',
      state: PreviewAuthState.challenge,
      width: 390,
      height: 844,
    );
  });

  testWidgets('signin_390_error', (tester) async {
    await _shot(
      tester,
      name: 'signin_390_error',
      state: PreviewAuthState.error,
      width: 390,
      height: 844,
    );
  });

  testWidgets('signin_390_submitting', (tester) async {
    await _shot(
      tester,
      name: 'signin_390_submitting',
      state: PreviewAuthState.submitting,
      width: 390,
      height: 844,
      settle: false,
    );
  });

  testWidgets('signin_390_rtl', (tester) async {
    await _shot(
      tester,
      name: 'signin_390_rtl',
      state: PreviewAuthState.normal,
      width: 390,
      height: 844,
      rtl: true,
    );
  });

  testWidgets('signin_390_scale', (tester) async {
    await _shot(
      tester,
      name: 'signin_390_scale',
      state: PreviewAuthState.normal,
      width: 390,
      height: 844,
      scale: 1.3,
    );
  });

  testWidgets('signin_390_focus', (tester) async {
    await _shot(
      tester,
      name: 'signin_390_focus',
      state: PreviewAuthState.normal,
      width: 390,
      height: 844,
      focusPrimary: true,
    );
  });
}
