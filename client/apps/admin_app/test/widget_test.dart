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
}
