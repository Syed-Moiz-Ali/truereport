import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/features/auth/platform_login_page.dart';

Widget _buildLoginApp({
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      home: const PlatformLoginPage(),
    ),
  );
}

void _setViewport(WidgetTester tester, {double width = 1280, double height = 800}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets('Platform login renders desktop split view without overflow', (tester) async {
    _setViewport(tester, width: 1280, height: 800);
    await tester.pumpWidget(_buildLoginApp());
    await tester.pumpAndSettle();

    // Showcase panel
    expect(find.text('PLATFORM ADMINISTRATION'), findsWidgets);
    expect(find.text('Global Automotive Diagnostic Network Administration'), findsWidgets);
    expect(find.text('Multi-Tenant Workshop Hierarchy'), findsOneWidget);
    expect(find.text('Global Master Item Library'), findsOneWidget);
    expect(find.text('Immutable Security Ledger'), findsOneWidget);

    // Auth Card
    expect(find.text('Sign in to Portal'), findsOneWidget);
    expect(find.text('AUTHORIZED ACCESS ONLY'), findsOneWidget);
    expect(find.byKey(const Key('sign-in-email')), findsOneWidget);
    expect(find.byKey(const Key('sign-in-password')), findsOneWidget);
    expect(find.byKey(const Key('sign-in-submit')), findsOneWidget);
    expect(find.byKey(const Key('btn-fill-demo')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Quick fill demo fills platform credentials', (tester) async {
    _setViewport(tester, width: 1280, height: 800);
    await tester.pumpWidget(_buildLoginApp());
    await tester.pumpAndSettle();

    final demoBtn = find.byKey(const Key('btn-fill-demo'));
    await tester.ensureVisible(demoBtn);
    await tester.tap(demoBtn);
    await tester.pumpAndSettle();

    final emailField = tester.widget<TextFormField>(find.byKey(const Key('sign-in-email')));
    final passField = tester.widget<TextFormField>(find.byKey(const Key('sign-in-password')));

    expect(emailField.controller?.text, 'admin@test.local');
    expect(passField.controller?.text, 'pass123');
  });

  testWidgets('Platform login renders Arabic RTL without overflow', (tester) async {
    _setViewport(tester, width: 1280, height: 800);
    await tester.pumpWidget(_buildLoginApp(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sign-in-submit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Platform login renders compact view on mobile without overflow', (tester) async {
    _setViewport(tester, width: 400, height: 840);
    await tester.pumpWidget(_buildLoginApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sign-in-email')), findsOneWidget);
    expect(find.byKey(const Key('sign-in-password')), findsOneWidget);
    expect(find.byKey(const Key('sign-in-submit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
