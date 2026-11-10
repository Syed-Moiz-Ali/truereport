import 'package:admin_app/src/pages/workshop_login_page.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

Widget _wrap(Widget child, Locale locale) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: buildAppTheme(),
    home: child,
  );
}

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets('English admin sign-in shell renders without overflow', (
    tester,
  ) async {
    _phoneSize(tester);
    await tester.pumpWidget(
      ProviderScope(child: _wrap(const SignInPage(), const Locale('en'))),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('sign-in-submit')), findsOneWidget);
  });

  testWidgets('Arabic admin sign-in shell renders RTL without overflow', (
    tester,
  ) async {
    _phoneSize(tester);
    await tester.pumpWidget(
      ProviderScope(child: _wrap(const SignInPage(), const Locale('ar'))),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      Directionality.of(
        tester.element(find.byKey(const Key('sign-in-submit'))),
      ),
      TextDirection.rtl,
    );
  });

  testWidgets('Platform Admin home renders in Arabic without overflow', (
    tester,
  ) async {
    _phoneSize(tester);
    await tester.pumpWidget(
      _wrap(
        RoleHomeScaffold(
          role: Role.platformAdmin,
          locale: const Locale('ar'),
          onLanguageChanged: (_) {},
          onSignOut: () {},
        ),
        const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('مدير المنصة'), findsOneWidget);
  });

  testWidgets('Workshop Admin login renders desktop split view without overflow', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(child: _wrap(const WorkshopLoginPage(), const Locale('en'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('WORKSHOP OPERATIONS'), findsWidgets);
    expect(find.text('Live Bay Telemetry & Queue'), findsOneWidget);
    expect(find.text('Adaptive SOP Builder'), findsOneWidget);
    expect(find.text('Cryptographic Audit Clearance'), findsOneWidget);
    expect(find.byKey(const Key('sign-in-email')), findsOneWidget);
    expect(find.byKey(const Key('sign-in-password')), findsOneWidget);
    expect(find.byKey(const Key('sign-in-submit')), findsOneWidget);
    expect(find.byKey(const Key('btn-fill-demo')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Workshop Admin quick fill demo sets workshop credentials', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(child: _wrap(const WorkshopLoginPage(), const Locale('en'))),
    );
    await tester.pumpAndSettle();

    final demoBtn = find.byKey(const Key('btn-fill-demo'));
    await tester.ensureVisible(demoBtn);
    await tester.tap(demoBtn);
    await tester.pumpAndSettle();

    final emailField = tester.widget<TextFormField>(find.byKey(const Key('sign-in-email')));
    final passField = tester.widget<TextFormField>(find.byKey(const Key('sign-in-password')));

    expect(emailField.controller?.text, 'wa@test.local');
    expect(passField.controller?.text, 'pass123');
  });

  testWidgets('Workshop Admin login renders mobile view without overflow', (tester) async {
    _phoneSize(tester);
    await tester.pumpWidget(
      ProviderScope(child: _wrap(const WorkshopLoginPage(), const Locale('en'))),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sign-in-submit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
