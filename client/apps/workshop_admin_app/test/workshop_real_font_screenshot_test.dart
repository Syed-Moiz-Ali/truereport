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
import 'package:workshop_admin_app/src/features/auth/workshop_login_page.dart';
import 'package:workshop_admin_app/src/features/home/workshop_admin_home.dart';
import 'package:workshop_admin_app/src/features/jobs/job_detail_page.dart';
import 'package:workshop_admin_app/src/features/reports/report_page.dart';
import 'package:workshop_admin_app/src/features/templates/template_builder_page.dart';

import 'support/fake_admin_api.dart';
import 'support/real_fonts.dart';

/// Real-font visual evidence for every required Workshop Admin screen.
///
/// Screens: sign in, dashboard, jobs queue, job detail, staff, templates,
/// template builder, reports, settings.
/// Sizes: 1440 EN, 1280 EN, 768 EN, 360 EN, 1280 AR.
///
/// Fonts are registered globally by `test/flutter_test_config.dart`
/// ([RealFonts]); the first test fails if they are missing, so this suite can
/// never silently capture Ahem boxes.
///
/// The report screen intentionally captures the published fixture job
/// (`job-3`) so evidence shows a real report preview, never an error state.

class _ScreenshotHarness extends ConsumerStatefulWidget {
  const _ScreenshotHarness({
    required this.child,
    required this.locale,
    required this.boundaryKey,
    required this.surfaceSize,
  });

  final Widget child;
  final Locale locale;
  final GlobalKey boundaryKey;
  final Size surfaceSize;

  @override
  ConsumerState<_ScreenshotHarness> createState() => _ScreenshotHarnessState();
}

class _ScreenshotHarnessState extends ConsumerState<_ScreenshotHarness> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localeProvider.notifier).setLocale(widget.locale);
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeLocale = ref.watch(localeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: activeLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      home: RepaintBoundary(
        key: widget.boundaryKey,
        child: MediaQuery(
          data: MediaQueryData(size: widget.surfaceSize),
          child: widget.child,
        ),
      ),
    );
  }
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey key,
  String filename,
) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final bytes = byteData.buffer.asUint8List();

    final dir = Directory('test/screenshots/real');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final file = File('${dir.path}/$filename.png');
    file.writeAsBytesSync(bytes, flush: true);
  });
}

const _testSession = Session(
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

Future<void> _pumpApp(
  WidgetTester tester, {
  required Widget child,
  required GlobalKey boundaryKey,
  required Size surfaceSize,
  Locale locale = const Locale('en'),
  Session? session,
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminApiProvider.overrideWithValue(FakeAdminApi())],
      child: _ScreenshotHarness(
        locale: locale,
        boundaryKey: boundaryKey,
        surfaceSize: surfaceSize,
        child: child,
      ),
    ),
  );
  if (session != null) {
    final element = tester.element(find.byType(_ScreenshotHarness));
    final container = ProviderScope.containerOf(element);
    container.read(authControllerProvider.notifier).state = AsyncData<Session?>(
      session,
    );
  }
  await tester.pumpAndSettle();
}

Future<void> _openWorkshopSection(WidgetTester tester, Key key) async {
  // Every destination lives in the dock at every width, so the old "More sheet"
  // fallback is gone with the widget it existed for.
  final target = find.byKey(key);
  expect(target, findsWidgets);
  await tester.tap(target.first);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await RealFonts.load();
  });

  const sizes = <String, Size>{
    '1440': Size(1440, 900),
    '1280': Size(1280, 800),
    '1024': Size(1024, 768),
    '768': Size(768, 1024),
    '390': Size(390, 844),
    '360': Size(360, 800),
  };

  final screens = <String, Widget Function()>{
    'signin': () => const WorkshopLoginPage(),
    'dashboard': () => const WorkshopAdminHomePage(),
    'jobs': () => const WorkshopAdminHomePage(),
    'job_detail': () => const JobDetailPage(jobId: 'job-1'),
    'staff': () => const WorkshopAdminHomePage(),
    'templates': () => const WorkshopAdminHomePage(),
    'board': () => const WorkshopAdminHomePage(),
    'template_builder': () =>
        const TemplateBuilderPage(templateId: 'template-1'),
    'reports': () => const ReportPage(jobId: 'job-3'),
    'settings': () => const WorkshopAdminHomePage(),
  };

  Future<void> captureScreen(
    WidgetTester tester, {
    required String screen,
    required String sizeLabel,
    required Size size,
    required Locale locale,
    required bool isShell,
  }) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final key = GlobalKey();
    final suffix = locale.languageCode == 'ar' ? '_ar' : '';
    final name = 'workshop_${screen}_$sizeLabel$suffix';
    await _pumpApp(
      tester,
      child: screens[screen]!(),
      boundaryKey: key,
      surfaceSize: size,
      locale: locale,
      session: screen == 'signin' ? null : _testSession,
    );
    if (isShell && screen != 'dashboard') {
      final keyByScreen = <String, Key>{
        'jobs': const Key('workshop-tab-jobs'),
        'staff': const Key('workshop-tab-staff'),
        'templates': const Key('workshop-tab-templates'),
        'board': const Key('workshop-tab-job-board'),
        'settings': const Key('workshop-tab-settings'),
      };
      final navKey = keyByScreen[screen];
      if (navKey != null) {
        await _openWorkshopSection(tester, navKey);
      }
    }
    await _capture(tester, key, name);
  }

  group('Workshop Admin real-font screenshots', () {
    test('real fonts are loaded (never Ahem-only evidence)', () {
      expect(RealFonts.isLoaded, isTrue);
      expect(RealFonts.missingFamilies, isEmpty);
    });

    for (final entry in sizes.entries) {
      for (final screen in screens.keys) {
        testWidgets('$screen ${entry.key} EN', (tester) async {
          await captureScreen(
            tester,
            screen: screen,
            sizeLabel: entry.key,
            size: entry.value,
            locale: const Locale('en'),
            isShell:
                screen != 'signin' &&
                screen != 'job_detail' &&
                screen != 'template_builder' &&
                screen != 'reports',
          );
        });
      }
    }

    for (final screen in screens.keys) {
      testWidgets('$screen 1280 AR', (tester) async {
        await captureScreen(
          tester,
          screen: screen,
          sizeLabel: '1280',
          size: const Size(1280, 800),
          locale: const Locale('ar'),
          isShell:
              screen != 'signin' &&
              screen != 'job_detail' &&
              screen != 'template_builder' &&
              screen != 'reports',
        );
      });
    }
  });
}
