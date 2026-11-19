import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/auth/workshop_login_page.dart';

import 'support/real_fonts.dart';

/// CR-5 workshop sign-in capture and copy smoke.
///
/// Imported directly (not through the router) so it is not blocked by unrelated
/// in-flight work in other features. Writes PNGs to
/// `docs/evidence/signin_workshop_cr5/`.
void main() {
  setUpAll(RealFonts.load);

  Widget app(Locale locale) => ProviderScope(
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildAppTheme(),
      home: const WorkshopLoginPage(),
    ),
  );

  Future<void> capture(
    WidgetTester tester, {
    required String name,
    required Size size,
    required Locale locale,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const rootKey = ValueKey('workshop-signin-cr5');
    await tester.pumpWidget(RepaintBoundary(key: rootKey, child: app(locale)));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage(
          'assets/images/signin_hero_admin.jpg',
          package: 'auth',
        ),
        tester.element(find.byKey(rootKey)),
      );
    });
    await tester.pump();
    expect(tester.takeException(), isNull, reason: name);

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(rootKey),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.png),
    );
    final dir = Directory('docs/evidence/signin_workshop_cr5')
      ..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
  }

  testWidgets('workshop sign-in renders the shared photo bay', (tester) async {
    await capture(
      tester,
      name: 'workshop_1440_en',
      size: const Size(1440, 900),
      locale: const Locale('en'),
    );
    await capture(
      tester,
      name: 'workshop_390_en',
      size: const Size(390, 844),
      locale: const Locale('en'),
    );
    await capture(
      tester,
      name: 'workshop_390_ar',
      size: const Size(390, 844),
      locale: const Locale('ar'),
    );

    final l10n = AppLocalizations.of(
      tester.element(find.byType(WorkshopLoginPage)),
    );
    expect(find.text(l10n.signInExampleLabel.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.signInTitle), findsWidgets);
    expect(find.byKey(const Key('sign-in-email')), findsOneWidget);
    expect(find.byKey(const Key('sign-in-password')), findsOneWidget);
    expect(find.byKey(const Key('sign-in-submit')), findsOneWidget);
    expect(find.text(l10n.signinEmailHint), findsOneWidget);
    expect(find.text(l10n.signinPasswordHint), findsOneWidget);
  });
}
