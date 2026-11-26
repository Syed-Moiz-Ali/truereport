/// Audit tests for the Bay Door sign-in: states, focus, targets, RTL and text
/// scaling. The production view is mounted with preview-only controllers.
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

Future<void> _pump(
  WidgetTester tester, {
  PreviewAuthState state = PreviewAuthState.normal,
  Size size = const Size(390, 844),
  bool rtl = false,
  double scale = 1,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
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
    } catch (_) {
      // The test asset bundle may not expose the package photo; the layout
      // still renders over the scrim, which is what these assertions cover.
    }
  });
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  testWidgets('normal state exposes the fields and the single primary', (
    tester,
  ) async {
    await _pump(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('sign-in-email')), findsOneWidget);
    expect(find.byKey(const Key('sign-in-password')), findsOneWidget);
    expect(find.byKey(const Key('sign-in-code')), findsNothing);
    expect(find.byKey(const Key('sign-in-submit')), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byTooltip('Show password'), findsOneWidget);
  });

  testWidgets('the whole 56 px cell focuses the field', (tester) async {
    await _pump(tester);
    final field = find.byKey(const Key('sign-in-email'));
    final node = tester.widget<TextField>(field).focusNode!;
    node.unfocus();
    await tester.pump();
    expect(node.hasFocus, isFalse);
    final rect = tester.getRect(field);
    await tester.tapAt(Offset(rect.center.dx, rect.top - 8));
    await tester.pump();
    expect(node.hasFocus, isTrue);
  });

  testWidgets('the reveal control announces show/hide and toggles', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byTooltip('Show password'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Hide password'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    final password = tester.widget<TextField>(
      find.byKey(const Key('sign-in-password')),
    );
    expect(password.obscureText, isFalse);
  });

  testWidgets('challenge swaps the password for the code and locks the email', (
    tester,
  ) async {
    await _pump(tester, state: PreviewAuthState.challenge);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('sign-in-code')), findsOneWidget);
    expect(find.byKey(const Key('sign-in-password')), findsNothing);
    final email = tester.widget<TextField>(
      find.byKey(const Key('sign-in-email')),
    );
    expect(email.enabled, isFalse);
    expect(find.text('Verify'), findsOneWidget);
  });

  testWidgets('an error is announced and leaves the action available', (
    tester,
  ) async {
    await _pump(tester, state: PreviewAuthState.error);
    expect(tester.takeException(), isNull);
    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    final primary = tester.widget<InkWell>(
      find.byKey(const Key('sign-in-submit')),
    );
    expect(primary.onTap, isNotNull);
  });

  testWidgets('submitting shows a spinner and announces progress', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, state: PreviewAuthState.submitting, settle: false);
    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
    expect(find.bySemanticsLabel('Signing in…'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('focus moves from email to password with Tab', (tester) async {
    await _pump(tester);
    final email = find.byKey(const Key('sign-in-email'));
    final password = find.byKey(const Key('sign-in-password'));
    await tester.tap(email);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(tester.widget<TextField>(password).focusNode!.hasFocus, isTrue);
  });

  testWidgets('targets meet the 44 px floor', (tester) async {
    await _pump(tester);
    final primary = tester.getSize(find.byKey(const Key('sign-in-submit')));
    expect(primary.height, greaterThanOrEqualTo(44));
    final reveal = tester.getSize(find.byType(IconButton));
    expect(reveal.width, greaterThanOrEqualTo(44));
    expect(reveal.height, greaterThanOrEqualTo(44));
  });

  testWidgets('RTL keeps the email hint aligned with its LTR input', (
    tester,
  ) async {
    await _pump(tester, rtl: true);
    expect(tester.takeException(), isNull);
    expect(find.text('تسجيل دخول الفني'), findsOneWidget);
    final email = tester.widget<TextField>(
      find.byKey(const Key('sign-in-email')),
    );
    expect(email.decoration?.hintTextDirection, TextDirection.ltr);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('sign-in-password')))
          .decoration
          ?.hintTextDirection,
      isNull,
    );
  });

  testWidgets('1440 layout renders the statement and the sheet', (
    tester,
  ) async {
    await _pump(tester, size: const Size(1440, 900));
    expect(tester.takeException(), isNull);
    expect(find.text('Every inspection, started right.'), findsOneWidget);
    expect(find.text('Technician sign in'), findsOneWidget);
    expect(find.byKey(const Key('sign-in-submit')), findsOneWidget);
  });

  testWidgets('130% text at 390 does not overflow', (tester) async {
    await _pump(tester, scale: 1.3);
    expect(tester.takeException(), isNull);
    expect(find.text('Technician sign in'), findsOneWidget);
    expect(find.byKey(const Key('sign-in-submit')), findsOneWidget);
  });
}
