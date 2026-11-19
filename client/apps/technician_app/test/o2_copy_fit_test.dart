import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/features/auth/signin/technician_sign_in_page.dart';

import 'support/f2a_test_fonts.dart';
import 'support/f2a_views.dart';

/// O2 regression tests (F3-0), rewritten for the rebuilt sign-in (direction C).
///
/// The old login cases pinned two exact Figma slot widths (153.53 / 64.94 px)
/// from the deleted centring layout. The rebuilt screen wraps the same copy on
/// its own grid, so the intent is preserved instead: the access, help and
/// security lines must render completely — never ellipsized — at phone widths
/// in both locales. The empty-state header case is untouched.
void main() {
  setUpAll(loadF2AFonts);

  Future<void> pumpSignIn(
    WidgetTester tester,
    Locale locale, {
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width, 844);
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
          home: const TechnicianSignInPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final width in const [390.0, 360.0]) {
      testWidgets('O2 login footer copy is complete at ${width.toInt()} '
          '(${locale.languageCode})', (tester) async {
        await pumpSignIn(tester, locale, width: width);
        expect(tester.takeException(), isNull);

        final l10n = AppLocalizations.of(
          tester.element(find.byType(TechnicianSignInPage)),
        );
        final finders = <String, Finder>{
          'access prompt': find.text(l10n.technicianNeedTechnicianAccess),
          'help': find.text(l10n.technicianContactAdmin),
          'security': find.text(l10n.technicianSecurityLine),
        };
        for (final entry in finders.entries) {
          expect(entry.value, findsOneWidget, reason: entry.key);
          final paragraph = tester.renderObject<RenderParagraph>(entry.value);
          expect(
            paragraph.didExceedMaxLines,
            isFalse,
            reason: '${entry.key} truncated at ${width.toInt()}px',
          );
          expect(
            tester.getSize(entry.value).width,
            greaterThan(0),
            reason: '${entry.key} has no width',
          );
        }
      });
    }
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
