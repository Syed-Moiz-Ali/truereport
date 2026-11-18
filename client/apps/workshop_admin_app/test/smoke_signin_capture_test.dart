import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/auth/workshop_login_page.dart';

import 'support/real_fonts.dart';

/// Gate 4 smoke capture: one screen, real glyphs, written to `docs/evidence/`.
///
/// Unlike `test/screenshots/real/` (which is regenerated wholesale), this file is
/// a single, reviewable artifact proving the harness renders real type.
void main() {
  testWidgets('sign-in smoke capture at 1280x800 renders real glyphs', (
    tester,
  ) async {
    expect(RealFonts.isLoaded, isTrue);
    expect(RealFonts.missingFamilies, isEmpty);

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light,
          home: RepaintBoundary(
            key: boundaryKey,
            child: const MediaQuery(
              data: MediaQueryData(size: Size(1280, 800)),
              child: WorkshopLoginPage(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    expect(boundary, isNotNull);
    expect(boundary!.size, const Size(1280, 800));

    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(data, isNotNull);
      final directory = Directory('docs/evidence');
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      File('${directory.path}/phase-4-signin-smoke.png')
          .writeAsBytesSync(data!.buffer.asUint8List(), flush: true);
    });
  });
}
