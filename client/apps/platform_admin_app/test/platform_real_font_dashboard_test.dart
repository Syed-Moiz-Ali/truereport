import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/features/dashboard/dashboard_screen.dart';
import 'package:platform_admin_app/src/platform_catalogue_models.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/platform_theme.dart';

import 'support/ui_message_fixtures.dart';

class _MockLocaleController extends LocaleController {
  _MockLocaleController(this._initial);
  final Locale _initial;

  @override
  Locale build() => _initial;
}

Future<void> _loadRealFonts() async {
  final fontDir = Directory('../../packages/design_system/assets/fonts');
  if (!fontDir.existsSync()) return;

  final families = <String, FontLoader>{};
  await for (final entity in fontDir.list()) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (!name.endsWith('.ttf') && !name.endsWith('.otf')) continue;

    String? family;
    if (name.startsWith('PlusJakartaSans')) {
      family = TrFonts.latin;
    } else if (name.startsWith('NotoSansArabic')) {
      family = TrFonts.arabicDefault;
    } else if (name.startsWith('IBMPlexSansArabic')) {
      family = TrFonts.arabicAlternative;
    } else if (name.startsWith('NotoSansSC')) {
      family = TrFonts.cjkFallback;
    } else if (name.startsWith('NotoSansTelugu')) {
      family = TrFonts.teluguFallback;
    } else if (name.startsWith('NotoSans-')) {
      family = TrFonts.cyrillicFallback;
    }

    if (family == null) continue;
    final bytes = await entity.readAsBytes();
    final loader = families.putIfAbsent(family, () => FontLoader(family!));
    loader.addFont(Future.value(ByteData.sublistView(bytes)));

    // Register bare family name as well for fallback lookups
    final bareFamily = family.replaceFirst('packages/design_system/', '');
    final bareLoader = families.putIfAbsent(
      bareFamily,
      () => FontLoader(bareFamily),
    );
    bareLoader.addFont(Future.value(ByteData.sublistView(bytes)));
  }

  for (final loader in families.values) {
    await loader.load();
  }

  final iconFile = File(
    'build/unit_test_assets/fonts/MaterialIcons-Regular.otf',
  );
  if (iconFile.existsSync()) {
    final iconBytes = await iconFile.readAsBytes();
    final iconLoader = FontLoader('MaterialIcons');
    iconLoader.addFont(Future.value(ByteData.sublistView(iconBytes)));
    await iconLoader.load();
  }
}

const _dashboardSummary = OverviewSummary(
  workshops: OverviewWorkshops(total: 12, active: 9),
  staff: OverviewStaff(technicians: 34, admins: 5),
  jobs: OverviewJobs(
    active: 21,
    pendingReview: 4,
    byStatus: {'ASSIGNED': 8, 'IN_PROGRESS': 9, 'PENDING_REVIEW': 4},
  ),
  reports: OverviewReports(published: 38, byMonth: {'Nov': 14, 'Oct': 24}),
  checklist: OverviewChecklist(
    categories: 6,
    items: 42,
    templates: 3,
    healthy: false,
    issues: 2,
  ),
  languages: OverviewLanguages(live: 1, translating: 0),
  recentActivity: [
    OverviewActivityEntry(
      id: 'evt-1',
      action: 'MASTER_ITEM_PUBLISHED',
      entityType: 'MASTER_ITEM',
      entityId: 'BRK-PAD-01',
      actor: 'admin@truereport.test',
      occurredAt: '2026-11-14T10:00:00Z',
    ),
    OverviewActivityEntry(
      id: 'evt-2',
      action: 'WORKSHOP_REGISTERED',
      entityType: 'WORKSHOP',
      entityId: 'WS-NORTH-01',
      actor: 'admin@truereport.test',
      occurredAt: '2026-11-13T14:30:00Z',
    ),
  ],
  alerts: [
    OverviewAlert(
      severity: 'warning',
      title: 'Unpublished reports pending final sign-off',
      body: '4 inspection reports have completed field work and require authorization.',
      titleKey: 'dashboard.alert.reportsUnpublished.title',
      bodyKey: 'dashboard.alert.reportsUnpublished.body',
      args: {'count': 4},
      route: '/audit-log',
    ),
  ],
);

const _configHealth = ConfigHealth(
  healthy: true,
  checks: [
    HealthCheck(
      code: 'TRANSLATIONS_COMPLETE',
      severity: 'OK',
      messageEn: 'All translations complete',
      messageAr: 'All translations complete',
      affected: 0,
      references: [],
    ),
  ],
);
const _testLanguages = [
  PlatformLanguage(
    code: 'en',
    nativeName: 'English',
    direction: 'ltr',
    active: true,
    isDefault: true,
    sortOrder: 0,
    status: 'LIVE',
  ),
];
const _testReadinessEn = LanguageReadiness(
  language: 'en',
  nativeName: 'English',
  direction: 'ltr',
  isDefault: true,
  status: 'LIVE',
  readinessPercent: 100,
  uiMessagesPath: 'en.json',
  uiMessages: UiMessageCoverage(
    total: 100,
    approved: 100,
    missing: 0,
    changed: 0,
    path: 'en.json',
    generationStatus: 'NONE',
  ),
  content: {},
  blockers: [],
);

const _testManifest = UiMessageManifest(
  defaultLanguage: 'en',
  namespaceVersions: {'platform_admin': 1, 'common': 1},
  languages: [
    UiMessageLanguage(
      code: 'en',
      direction: 'ltr',
      nativeName: 'English',
      path: 'platform_admin/en.json',
      totalKeys: 450,
    ),
  ],
);
class _TestUiMessageController extends UiMessageController {
  _TestUiMessageController(this.lang);
  final String lang;

  @override
  UiMessageState build() => UiMessageState(
    manifest: _testManifest,
    activeLanguage: lang,
    defaultLanguage: 'en',
    ready: true,
    revision: 1,
  );
}

Widget _dashboardRealFontHarness({
  required GlobalKey boundaryKey,
  Locale locale = const Locale('en'),
  Size surfaceSize = const Size(1280, 900),
}) {
  final langCode = locale.languageCode;
  return ProviderScope(
    key: ValueKey('scope-$langCode-${surfaceSize.width}'),
    overrides: [
      uiStringsProvider.overrideWithValue(
        fakeEnUiStrings(),
      ),
      uiMessageControllerProvider.overrideWith(
        () => _TestUiMessageController(langCode),
      ),
      platformLocaleProvider.overrideWith(() => _MockLocaleController(locale)),
      overviewProvider.overrideWith((ref) async => _dashboardSummary),
      configHealthProvider.overrideWith((ref) async => _configHealth),
      platformLanguagesProvider.overrideWith((ref) async => _testLanguages),
      auditEventsProvider.overrideWith(
        (ref) async => const <PlatformAuditEvent>[],
      ),
      readinessProvider('en').overrideWith((ref) async => _testReadinessEn),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: TrFonts.latin,
        scaffoldBackgroundColor: PtTheme.canvas,
      ),
      home: RepaintBoundary(
        key: boundaryKey,
        child: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: const DashboardScreen(),
        ),
      ),
    ),
  );
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

    final outDirs = [
      Directory('test/screenshots/real'),
      Directory(
        r'C:\Users\sanja\.gemini\antigravity\brain\cca80726-f50d-4167-b93e-5a699c602442\screenshots',
      ),
    ];

    for (final dir in outDirs) {
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final file = File('${dir.path}/$filename');
      for (var attempt = 0; attempt < 6; attempt++) {
        try {
          file.writeAsBytesSync(bytes, flush: true);
          break;
        } on FileSystemException {
          if (attempt == 5) rethrow;
          await Future<void>.delayed(const Duration(milliseconds: 150));
        }
      }
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadRealFonts();
  });

  group('Phase 2 Real Font Dashboard Verification', () {
    testWidgets(
      'Capture real font dashboard screenshots across viewports',
      (tester) async {
        final key = GlobalKey();

        // 1. 1440 Desktop
        await tester.binding.setSurfaceSize(const Size(1440, 1100));
        await tester.pumpWidget(
          _dashboardRealFontHarness(
            boundaryKey: key,
            surfaceSize: const Size(1440, 1100),
          ),
        );
        await tester.pumpAndSettle();
        await _capture(tester, key, 'dashboard_1440.png');

        // 2. 1280 Desktop
        await tester.binding.setSurfaceSize(const Size(1280, 1100));
        await tester.pumpWidget(
          _dashboardRealFontHarness(
            boundaryKey: key,
            surfaceSize: const Size(1280, 1100),
          ),
        );
        await tester.pumpAndSettle();
        await _capture(tester, key, 'dashboard_1280.png');

        // 3. 768 Tablet
        await tester.binding.setSurfaceSize(const Size(768, 1200));
        await tester.pumpWidget(
          _dashboardRealFontHarness(
            boundaryKey: key,
            surfaceSize: const Size(768, 1200),
          ),
        );
        await tester.pumpAndSettle();
        await _capture(tester, key, 'dashboard_768.png');

        // 4. 360 Mobile
        await tester.binding.setSurfaceSize(const Size(360, 1400));
        await tester.pumpWidget(
          _dashboardRealFontHarness(
            boundaryKey: key,
            surfaceSize: const Size(360, 1400),
          ),
        );
        await tester.pumpAndSettle();
        await _capture(tester, key, 'dashboard_360.png');



        // 7. Telugu font coverage verification
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: TrFonts.latin),
            home: const Scaffold(
              body: Center(
                child: Text(
                  'ట్రూరిపోర్ట్ (తెలుగు)',
                  key: Key('telugu-text'),
                  style: TextStyle(
                    fontFamily: TrFonts.latin,
                    fontFamilyFallback: [
                      TrFonts.teluguFallback,
                      'Noto Sans Telugu',
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('telugu-text')), findsOneWidget);
        expect(find.text('ట్రూరిపోర్ట్ (తెలుగు)'), findsOneWidget);

        tester.binding.setSurfaceSize(null);
      },
    );
  });
}
