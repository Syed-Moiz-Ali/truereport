import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

import 'support/f2a_test_fonts.dart';
import 'support/f2a_views.dart';

/// O2 regression tests (F3-0): the login footer copy must fit the exact
/// Figma slots without truncation, and the empty-state header row must not
/// clip its trailing pill.
///
/// Figma slots (auth `sign_in_view.dart` `_M`): prompt 153.53 px at
/// [Fx.body13], action 64.94 px at [Fx.label12]. Empty-state header content
/// is 334 px wide starting at x=20, so every pill must end at x <= 354.
void main() {
  setUpAll(loadF2AFonts);

  Future<void> pumpSignIn(WidgetTester tester, Locale locale) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: buildAppTheme(),
          home: const SignInPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double intrinsicWidth(String text, TextStyle style, TextDirection dir) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: dir,
    )..layout();
    return tp.width;
  }

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets(
      'O2 login footer copy fits Figma slots (${locale.languageCode})',
      (tester) async {
        await pumpSignIn(tester, locale);
        expect(tester.takeException(), isNull);

        final l10n = AppLocalizations.of(
          tester.element(find.byType(SignInPage)),
        );
        final dir = locale.languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr;
        final promptW = intrinsicWidth(
          l10n.technicianNeedTechnicianAccess,
          Fx.body13,
          dir,
        );
        final actionW = intrinsicWidth(
          l10n.technicianContactAdmin,
          Fx.label12,
          dir,
        );
        expect(
          promptW,
          lessThanOrEqualTo(153.53),
          reason: 'prompt "${l10n.technicianNeedTechnicianAccess}" '
              'is ${promptW.toStringAsFixed(2)} px, slot is 153.53 px',
        );
        expect(
          actionW,
          lessThanOrEqualTo(64.94),
          reason: 'action "${l10n.technicianContactAdmin}" '
              'is ${actionW.toStringAsFixed(2)} px, slot is 64.94 px',
        );
      },
    );
  }

  testWidgets('O2 empty-state header does not clip the trailing pill', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 884);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      f2aHost(
        child: f2aScreen('empty-state', figma: true),
        locale: const Locale('en'),
        theme: AppTheme.light,
        figmaStrings: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    // Viewport for the header row: body gutter 20 + 334 px content.
    final pill = find.text('Bay 04');
    expect(pill, findsOneWidget);
    expect(
      tester.getRect(pill).right,
      lessThanOrEqualTo(354.0),
      reason: 'trailing pill must end inside the 334 px header viewport',
    );
  });
}
