import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/jobs_tab.dart';

import 'support/fake_admin_api.dart';

const String _outDir = 'docs/evidence/jobs_instant';

/// Dark evidence tokens. The app ships light-only (`ThemeMode.light`), so the
/// dark capture renders the queue against a dark token set to prove the
/// composition does not depend on the warm paper palette.
const WorkshopTokens _darkTokens = WorkshopTokens(
  canvas: Color(0xFF131511),
  surface: Color(0xFF1B1E18),
  ink: Color(0xFFF3F1EA),
  muted: Color(0xFF9EA69C),
  border: Color(0xFF2C3128),
  accent: Color(0xFF4FC79C),
  accentHover: Color(0xFF66D6AF),
  accentSoft: Color(0xFF1D3A2E),
  onAccent: Color(0xFF06231A),
  warning: Color(0xFFE8A54B),
  warningSoft: Color(0xFF33260F),
  danger: Color(0xFFF2837B),
  dangerSoft: Color(0xFF3A1D1B),
  success: Color(0xFF5CC98A),
  successSoft: Color(0xFF16301F),
  focus: Color(0xFF7FB2FF),
  cardRadius: 16,
  cardLargeRadius: 20,
  controlRadius: 14,
  chipRadius: 999,
  controlHeight: 48,
  touchTarget: 48,
  topBarHeight: 60,
  sidebarWidth: 256,
  railWidth: 72,
  contentMaxWidth: 1200,
  pageGutterDesktop: 32,
  pageGutterTablet: 20,
  pageGutterPhone: 16,
  cardPadding: 18,
  cardPaddingDesktop: 20,
  pageTitle: TextStyle(
    fontSize: 30,
    height: 38 / 30,
    fontWeight: FontWeight.w700,
  ),
  sectionTitle: TextStyle(
    fontSize: 19,
    height: 26 / 19,
    fontWeight: FontWeight.w700,
  ),
  cardTitle: TextStyle(
    fontSize: 15.5,
    height: 22 / 15.5,
    fontWeight: FontWeight.w700,
  ),
  body: TextStyle(color: Color(0xFFF3F1EA), fontSize: 14, height: 21 / 14),
  bodyStrong: TextStyle(
    fontSize: 14,
    height: 21 / 14,
    fontWeight: FontWeight.w600,
  ),
  meta: TextStyle(color: Color(0xFF9EA69C), fontSize: 12.5, height: 18 / 12.5),
  eyebrow: TextStyle(
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
  ),
  panelHeadline: TextStyle(fontSize: 34, height: 42 / 34),
  panelBody: TextStyle(fontSize: 15, height: 22 / 15),
);

ThemeData _darkTheme() {
  final base = AppTheme.light;
  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFF131511),
    colorScheme: base.colorScheme.copyWith(
      brightness: Brightness.dark,
      surface: const Color(0xFF1B1E18),
      onSurface: const Color(0xFFF3F1EA),
      onSurfaceVariant: const Color(0xFF9EA69C),
    ),
    extensions: const <ThemeExtension<dynamic>>[_darkTokens],
  );
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    expect(boundary, isNotNull, reason: name);
    final image = await boundary!.toImage(pixelRatio: 1.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(data, isNotNull, reason: name);
    final dir = Directory(_outDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    File('${dir.path}/$name.png')
        .writeAsBytesSync(data!.buffer.asUint8List(), flush: true);
  });
}

Future<GlobalKey> _pumpQueue(
  WidgetTester tester, {
  required Size size,
  Locale locale = const Locale('en'),
  bool dark = false,
  bool selectFirst = false,
}) async {
  final key = GlobalKey();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminApiProvider.overrideWithValue(FakeAdminApi())],
      child: MediaQuery(
        data: MediaQueryData(size: size),
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: dark ? _darkTheme() : AppTheme.light,
            home: Material(
              color: dark
                  ? const Color(0xFF131511)
                  : AppTheme.light.scaffoldBackgroundColor,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: const JobsTab(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  if (selectFirst) {
    final row = find.byKey(const Key('job-job-1'));
    expect(row, findsOneWidget);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }
  return key;
}

void main() {
  testWidgets('capture 1440 EN list', (tester) async {
    final key = await _pumpQueue(tester, size: const Size(1440, 900));
    await _capture(tester, key, 'queue_1440_en');
  });

  testWidgets('capture 1440 EN detail route', (tester) async {
    final key = await _pumpQueue(
      tester,
      size: const Size(1440, 900),
      selectFirst: true,
    );
    await _capture(tester, key, 'job_1440_en');
  });

  testWidgets('capture 1024 EN list', (tester) async {
    final key = await _pumpQueue(tester, size: const Size(1024, 768));
    await _capture(tester, key, 'queue_1024_en');
  });

  testWidgets('capture 390 EN', (tester) async {
    final key = await _pumpQueue(tester, size: const Size(390, 844));
    await _capture(tester, key, 'queue_390_en');
  });

  testWidgets('capture 390 AR', (tester) async {
    final key = await _pumpQueue(
      tester,
      size: const Size(390, 844),
      locale: const Locale('ar'),
    );
    await _capture(tester, key, 'queue_390_ar');
  });

  testWidgets('capture 390 dark', (tester) async {
    final key = await _pumpQueue(
      tester,
      size: const Size(390, 844),
      dark: true,
    );
    await _capture(tester, key, 'queue_390_dark');
  });

  testWidgets('capture 360 clip check', (tester) async {
    final key = await _pumpQueue(tester, size: const Size(360, 800));
    await _capture(tester, key, 'queue_360_en');
  });
}
