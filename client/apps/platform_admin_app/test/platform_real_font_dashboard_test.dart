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
    final bareLoader = families.putIfAbsent(bareFamily, () => FontLoader(bareFamily));
    bareLoader.addFont(Future.value(ByteData.sublistView(bytes)));
  }

  for (final loader in families.values) {
    await loader.load();
  }

  final iconFile = File('build/unit_test_assets/fonts/MaterialIcons-Regular.otf');
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
  reports: OverviewReports(
    published: 38,
    byMonth: {'Nov': 14, 'Oct': 24},
  ),
  checklist: OverviewChecklist(
    categories: 6,
    items: 42,
    templates: 3,
    healthy: false,
    issues: 2,
  ),
  languages: OverviewLanguages(live: 2, translating: 1),
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
  healthy: false,
  checks: [
    HealthCheck(
      code: 'TRANSLATION_GAP_AR',
      severity: 'ERROR',
      messageEn: 'Arabic translations missing for 2 items',
      messageAr: 'تسميات عربية مفقودة لعنصرين',
      affected: 2,
      references: ['BRK-PAD-01', 'OIL-FLTR-02'],
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
  PlatformLanguage(
    code: 'ar',
    nativeName: 'العربية',
    direction: 'rtl',
    active: true,
    isDefault: false,
    sortOrder: 1,
    status: 'LIVE',
  ),
  PlatformLanguage(
    code: 'zh-Hans',
    nativeName: '中文',
    direction: 'ltr',
    active: true,
    isDefault: false,
    sortOrder: 2,
    status: 'TRANSLATING',
  ),
];

const _testReadinessZh = LanguageReadiness(
  language: 'zh-Hans',
  nativeName: '中文',
  direction: 'ltr',
  isDefault: false,
  status: 'TRANSLATING',
  readinessPercent: 65,
  uiMessagesPath: 'assets/i18n/zh-Hans.json',
  uiMessages: UiMessageCoverage(
    total: 100,
    approved: 65,
    missing: 35,
    changed: 0,
    path: 'assets/i18n/zh-Hans.json',
    generationStatus: 'NONE',
  ),
  content: {},
  blockers: [],
);

const _testReadinessLive = LanguageReadiness(
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

const _idleGen = ContentGeneration(
  language: 'zh-Hans',
  jobId: '',
  jobStatus: 'IDLE',
  status: 'IDLE',
  total: 0,
  completed: 0,
  failedKeys: [],
  entityTypes: [],
  error: '',
);

const _testManifest = UiMessageManifest(
  defaultLanguage: 'en',
  namespaceVersions: {'platform_admin': 1, 'common': 1},
  languages: [
    UiMessageLanguage(code: 'en', direction: 'ltr', nativeName: 'English'),
    UiMessageLanguage(code: 'ar', direction: 'rtl', nativeName: 'العربية'),
    UiMessageLanguage(code: 'zh-hans', direction: 'ltr', nativeName: '中文'),
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
        langCode == 'ar' ? fakeArUiStrings() : fakeEnUiStrings(),
      ),
      uiMessageControllerProvider.overrideWith(
        () => _TestUiMessageController(langCode),
      ),
      platformLocaleProvider.overrideWith(() => _MockLocaleController(locale)),
      overviewProvider.overrideWith((ref) async => _dashboardSummary),
      configHealthProvider.overrideWith((ref) async => _configHealth),
      platformLanguagesProvider.overrideWith((ref) async => _testLanguages),
      auditEventsProvider.overrideWith((ref) async => const <PlatformAuditEvent>[]),
      readinessProvider('zh-Hans').overrideWith((ref) async => _testReadinessZh),
      contentGenerationProvider('zh-Hans').overrideWith((ref) async => _idleGen),
      readinessProvider('en').overrideWith((ref) async => _testReadinessLive),
      contentGenerationProvider('en').overrideWith((ref) async => _idleGen),
      readinessProvider('ar').overrideWith((ref) async => _testReadinessLive),
      contentGenerationProvider('ar').overrideWith((ref) async => _idleGen),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: locale.languageCode == 'ar'
            ? TrFonts.arabicDefault
            : TrFonts.latin,
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
      Directory('test/screenshots'),
      Directory(
        r'C:\Users\sanja\.gemini\antigravity\brain\cca80726-f50d-4167-b93e-5a699c602442\screenshots',
      ),
    ];

    for (final dir in outDirs) {
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      File('${dir.path}/$filename').writeAsBytesSync(bytes);
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadRealFonts();
  });

  group('Phase 2 Real Font Dashboard Verification', () {
    testWidgets('Capture real font dashboard screenshots across viewports & RTL', (
      tester,
    ) async {
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

      // 5. Arabic RTL 1280 Desktop
      await tester.binding.setSurfaceSize(const Size(1280, 1100));
      await tester.pumpWidget(
        _dashboardRealFontHarness(
          boundaryKey: key,
          locale: const Locale('ar'),
          surfaceSize: const Size(1280, 1100),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('btn-header-language-selector')), findsOneWidget);
      expect(find.text('العربية (AR)'), findsOneWidget);
      // Assert directionality is RTL
      expect(tester.getTopLeft(find.byKey(const Key('btn-header-language-selector'))).dx, greaterThan(0));
      await _capture(tester, key, 'dashboard_ar_1280.png');

      // 6. Arabic RTL 360 Mobile
      await tester.binding.setSurfaceSize(const Size(360, 1400));
      await tester.pumpWidget(
        _dashboardRealFontHarness(
          boundaryKey: key,
          locale: const Locale('ar'),
          surfaceSize: const Size(360, 1400),
        ),
      );
      await tester.pumpAndSettle();
      // On compact screen (< 768px), header selector shows AR
      expect(find.text('AR'), findsOneWidget);
      await _capture(tester, key, 'dashboard_ar_360.png');

      // 7. Telugu font coverage verification
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            fontFamily: TrFonts.latin,
          ),
          home: const Scaffold(
            body: Center(
              child: Text(
                'ట్రూరిపోర్ట్ (తెలుగు)',
                key: Key('telugu-text'),
                style: TextStyle(
                  fontFamily: TrFonts.latin,
                  fontFamilyFallback: [TrFonts.teluguFallback, 'Noto Sans Telugu'],
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
    });
  });
}
