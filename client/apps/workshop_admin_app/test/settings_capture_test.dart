import 'dart:io';
import 'dart:ui' as ui;

import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/home/workshop_admin_home.dart';
import 'package:workshop_admin_app/src/features/settings/workshop_settings_page.dart';

import 'support/fake_admin_api.dart';

/// Real-font evidence for the rebuilt settings screen.
///
/// Sizes: 1440, 1024, 390 EN, 390 AR, plus a dark capture. The app ships
/// light-only (`ThemeMode.light`), so the dark capture renders the same screen
/// against a dark token set to prove the composition reads tokens rather than
/// hardcoded colours — the same convention as `jobs_queue_instant_capture_test`.
const String _outDir = 'docs/evidence/settings';

const Session _latinSession = Session(
  accessToken: 'token',
  refreshToken: 'refresh',
  user: User(
    id: 'user-1',
    email: 'layla@marina-auto.ae',
    displayName: 'Layla Haddad',
    platformAdmin: false,
    totpEnabled: false,
  ),
  memberships: [
    Membership(
      workshopId: 'workshop-1',
      workshopName: 'Marina Workshop',
      role: Role.workshopAdmin,
    ),
  ],
);

const Session _arabicSession = Session(
  accessToken: 'token',
  refreshToken: 'refresh',
  user: User(
    id: 'user-1',
    email: 'layla@marina-auto.ae',
    displayName: 'ليلى حداد',
    platformAdmin: false,
    totpEnabled: false,
  ),
  memberships: [
    Membership(
      workshopId: 'workshop-1',
      workshopName: 'ورشة المارينا',
      role: Role.workshopAdmin,
    ),
  ],
);

/// Dark evidence tokens (light-only app; see header comment).
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
  cardPadding: 20,
  cardPaddingDesktop: 24,
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
  final textTheme = base.textTheme.apply(
    bodyColor: const Color(0xFFF3F1EA),
    displayColor: const Color(0xFFF3F1EA),
  );
  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: const Color(0xFF131511),
    colorScheme: base.colorScheme.copyWith(
      brightness: Brightness.dark,
      surface: const Color(0xFF1B1E18),
      onSurface: const Color(0xFFF3F1EA),
      onSurfaceVariant: const Color(0xFF9EA69C),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      _darkTokens,
      AppSpacingTokens.standard,
      AppMotionTokens.standard,
    ],
  );
}

Future<void> _capture(GlobalKey key, String name) async {
  final boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  expect(boundary, isNotNull, reason: name);
  final image = await boundary!.toImage(pixelRatio: 1);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  expect(data, isNotNull, reason: name);
  final dir = Directory(_outDir);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  File('${dir.path}/$name.png')
      .writeAsBytesSync(data!.buffer.asUint8List(), flush: true);
}

void main() {
  testWidgets('settings real-font evidence', (tester) async {
    final cases = <(String, Size, Locale, Session, bool)>[
      (
        'settings_1440',
        const Size(1440, 900),
        const Locale('en'),
        _latinSession,
        false,
      ),
      (
        'settings_1024',
        const Size(1024, 768),
        const Locale('en'),
        _latinSession,
        false,
      ),
      (
        'settings_390',
        const Size(390, 844),
        const Locale('en'),
        _latinSession,
        false,
      ),
      (
        'settings_390_ar',
        const Size(390, 844),
        const Locale('ar'),
        _arabicSession,
        false,
      ),
      (
        'settings_1440_dark',
        const Size(1440, 900),
        const Locale('en'),
        _latinSession,
        true,
      ),
    ];

    for (final (name, size, locale, session, dark) in cases) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      final key = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [adminApiProvider.overrideWithValue(FakeAdminApi())],
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: dark
                  ? _darkTheme()
                  : AppTheme.build(isArabic: locale.languageCode == 'ar'),
              home: Builder(
                builder: (context) => Material(
                  color: context.ws.canvas,
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: const WorkshopSettingsPage(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WorkshopSettingsPage)),
      );
      container.read(localeProvider.notifier).setLocale(locale);
      container.read(authControllerProvider.notifier).state = AsyncData(
        session,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.runAsync(() => _capture(key, name));
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('settings inside the real shell', (tester) async {
    const size = Size(1440, 900);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final key = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [adminApiProvider.overrideWithValue(FakeAdminApi())],
        child: RepaintBoundary(
          key: key,
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
            home: const WorkshopAdminHomePage(),
          ),
        ),
      ),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(WorkshopAdminHomePage)),
    );
    container.read(authControllerProvider.notifier).state = const AsyncData(
      _latinSession,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('workshop-tab-settings')).first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.runAsync(() => _capture(key, 'settings_shell_1440'));
  });
}
