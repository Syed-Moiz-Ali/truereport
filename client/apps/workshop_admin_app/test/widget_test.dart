import 'package:workshop_admin_app/src/features/auth/workshop_login_page.dart';
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
      ProviderScope(
        child: _wrap(const WorkshopLoginPage(), const Locale('en')),
      ),
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
      ProviderScope(
        child: _wrap(const WorkshopLoginPage(), const Locale('ar')),
      ),
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

  testWidgets(
    'Workshop Admin login renders the desktop bay layout without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: _wrap(const WorkshopLoginPage(), const Locale('en')),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(WorkshopLoginPage)),
      );
      // The portal label appears exactly once on the door: the mark's
      // sub-label is suppressed at split widths because the accent eyebrow
      // already says it (printing both read as a mistake).
      expect(find.text(l10n.signInPortalLabel.toUpperCase()), findsOneWidget);
      // The committed signature is the labelled example job on the inspection
      // surface (docs/ui_brief.md, direction B). It replaced the old brand
      // line, which this test used to pin; the line is no longer rendered.
      expect(find.text(l10n.signInExampleLabel.toUpperCase()), findsOneWidget);
      // The photo hero replaced the ink inspection surface; the labelled
      // example job and its tick spine remain as the committed signature.
      expect(find.byType(WorkshopTickSpine), findsOneWidget);
      expect(find.text(l10n.signInTitle), findsWidgets);
      expect(find.text(l10n.signInHelp), findsOneWidget);
      expect(find.byKey(const Key('sign-in-email')), findsOneWidget);
      expect(find.byKey(const Key('sign-in-password')), findsOneWidget);
      expect(find.byKey(const Key('sign-in-submit')), findsOneWidget);
      expect(find.byKey(const Key('btn-fill-demo')), findsNothing);
      // No unverified certification, encryption, telemetry or telemetry-style
      // status claims on the sign-in surface.
      for (final banned in const [
        'SOC-2',
        'SOC 2',
        'TLS',
        'blockchain',
        'GRID',
        'Latency',
        'SECURED',
        'Telemetry',
        '256-bit',
      ]) {
        expect(
          find.textContaining(banned),
          findsNothing,
          reason: 'Unverified claim leaked into sign-in: $banned',
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Workshop Admin form accepts manually entered credentials', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: _wrap(const WorkshopLoginPage(), const Locale('en')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('sign-in-email')),
      'admin.a@truereport.test',
    );
    await tester.enterText(
      find.byKey(const Key('sign-in-password')),
      'local-password',
    );
    await tester.pumpAndSettle();

    final emailField = tester.widget<TextFormField>(
      find.byKey(const Key('sign-in-email')),
    );
    final passField = tester.widget<TextFormField>(
      find.byKey(const Key('sign-in-password')),
    );

    expect(emailField.controller?.text, 'admin.a@truereport.test');
    expect(passField.controller?.text, 'local-password');
  });

  testWidgets('Workshop Admin login renders mobile view without overflow', (
    tester,
  ) async {
    _phoneSize(tester);
    await tester.pumpWidget(
      ProviderScope(
        child: _wrap(const WorkshopLoginPage(), const Locale('en')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sign-in-submit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
