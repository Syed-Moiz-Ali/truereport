import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/features/audit/audit_log_screen.dart';
import 'package:platform_admin_app/src/features/languages/language_workspace_screen.dart';
import 'package:platform_admin_app/src/features/languages/languages_screen.dart';
import 'package:platform_admin_app/src/features/settings/platform_settings_screen.dart';
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

const _realScreenshotDir = 'test/screenshots/real';

const _expectedSettingsRealScreenshots = <String>[
  'settings_1280.png',
  'settings_ar_1280.png',
  'languages_1280.png',
  'languages_ar_1280.png',
  'language_workspace_1280.png',
  'language_workspace_ar_1280.png',
  'language_workspace_360.png',
  'audit_log_1280.png',
  'audit_log_768.png',
  'audit_log_360.png',
  'audit_log_ar_1280.png',
];

Future<void> _loadMaterialIcons() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final candidates = <File>[
    File('build/unit_test_assets/fonts/MaterialIcons-Regular.otf'),
    if (flutterRoot != null)
      File(
        '$flutterRoot/bin/cache/artifacts/material_fonts/'
        'materialicons-regular.otf',
      ),
  ];
  File? fontFile;
  for (final candidate in candidates) {
    if (candidate.existsSync()) {
      fontFile = candidate;
      break;
    }
  }
  if (fontFile == null) {
    throw StateError(
      'MaterialIcons font not found. Expected '
      'build/unit_test_assets/fonts/MaterialIcons-Regular.otf.',
    );
  }

  final bytes = await fontFile.readAsBytes();
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
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

    if (family != null) {
      final loader = families.putIfAbsent(family, () => FontLoader(family!));
      loader.addFont(entity.readAsBytes().then((b) => ByteData.sublistView(b)));
    }
  }

  for (final loader in families.values) {
    await loader.load();
  }
}

const _testLanguages = [
  PlatformLanguage(
    code: 'en',
    nativeName: 'English',
    direction: 'ltr',
    active: true,
    isDefault: true,
    sortOrder: 1,
    status: 'LIVE',
    uiMessagesPath: 'en.json',
  ),
  PlatformLanguage(
    code: 'ar',
    nativeName: 'العربية',
    direction: 'rtl',
    active: true,
    isDefault: false,
    sortOrder: 2,
    status: 'LIVE',
    uiMessagesPath: 'ar.json',
  ),
  PlatformLanguage(
    code: 'de',
    nativeName: 'Deutsch',
    direction: 'ltr',
    active: false,
    isDefault: false,
    sortOrder: 3,
    status: 'TRANSLATING',
    uiMessagesPath: 'de.json',
  ),
];

const _testCoverage = TranslationCoverage(
  languages: ['en', 'ar', 'de'],
  namespaces: {
    'platform_admin': CoverageNamespace(total: 450, missing: []),
    'common': CoverageNamespace(total: 58, missing: []),
  },
);

const _testHealth = ConfigHealth(
  healthy: true,
  checks: [
    HealthCheck(
      code: 'TRANSLATIONS_COMPLETE',
      severity: 'OK',
      messageEn: 'All translations complete',
      messageAr: 'جميع الترجمات مكتملة',
      messageKey: 'platform_admin.checklist.health.check.translations',
      affected: 0,
      references: [],
    ),
  ],
);

const _testAuditEvents = [
  PlatformAuditEvent(
    id: 'evt-1',
    action: 'WORKSHOP_REGISTERED',
    entityType: 'WORKSHOP',
    entityId: 'ws-dubai-01',
    actorRole: 'PLATFORM_ADMIN',
    occurredAt: '2026-11-15T10:30:00Z',
    reasonCode: 'INITIAL_SETUP',
    metadataJson: '{"branch":"Al Quoz","bays":8}',
  ),
  PlatformAuditEvent(
    id: 'evt-2',
    action: 'PUBLISH_ITEM',
    entityType: 'MASTER_ITEM',
    entityId: 'item-brake-pad-01',
    actorRole: 'PLATFORM_ADMIN',
    occurredAt: '2026-11-15T09:15:00Z',
    reasonCode: 'PUBLISH',
    metadataJson: '{"version":2,"safetyCritical":true}',
  ),
  PlatformAuditEvent(
    id: 'evt-3',
    action: 'CREATE_CATEGORY',
    entityType: 'CATEGORY',
    entityId: 'cat-powertrain',
    actorRole: 'PLATFORM_ADMIN',
    occurredAt: '2026-11-14T16:00:00Z',
    reasonCode: 'EXPANSION',
    metadataJson: '{"order":4}',
  ),
];

const _testReadinessAr = LanguageReadiness(
  language: 'ar',
  nativeName: 'العربية',
  direction: 'rtl',
  isDefault: false,
  status: 'LIVE',
  uiMessagesPath: 'ar.json',
  readinessPercent: 100,
  uiMessages: UiMessageCoverage(
    approved: 450,
    total: 450,
    missing: 0,
    changed: 0,
    path: 'ar.json',
    generationStatus: 'COMPLETED',
  ),
  content: {
    'CATEGORY': EntityReadiness(approved: 12, total: 12),
    'ITEM': EntityReadiness(approved: 84, total: 84),
    'OPTION_SET': EntityReadiness(approved: 18, total: 18),
    'OPTION_VALUE': EntityReadiness(approved: 64, total: 64),
    'TEMPLATE': EntityReadiness(approved: 6, total: 6),
    'DOCUMENT_TYPE': EntityReadiness(approved: 4, total: 4),
    'ISSUE_FIELD': EntityReadiness(approved: 22, total: 22),
  },
  blockers: [],
);

const _testContentGenerationAr = ContentGeneration(
  language: 'ar',
  jobId: 'job-1',
  jobStatus: 'COMPLETED',
  status: 'COMPLETED',
  total: 210,
  completed: 210,
  failedKeys: [],
  entityTypes: [],
  error: '',
);

const _testReadinessDe = LanguageReadiness(
  language: 'de',
  nativeName: 'Deutsch',
  direction: 'ltr',
  isDefault: false,
  status: 'TRANSLATING',
  uiMessagesPath: 'de.json',
  readinessPercent: 42,
  uiMessages: UiMessageCoverage(
    approved: 42,
    total: 100,
    missing: 58,
    changed: 0,
    path: 'de.json',
    generationStatus: 'NONE',
  ),
  content: {},
  blockers: [],
);

const _testContentGenerationDe = ContentGeneration(
  language: 'de',
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
    UiMessageLanguage(code: 'de', direction: 'ltr', nativeName: 'Deutsch'),
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

Widget _realFontHarness({
  required Widget child,
  required GlobalKey boundaryKey,
  Locale locale = const Locale('en'),
  Size surfaceSize = const Size(1280, 900),
}) {
  final langCode = locale.languageCode;
  return ProviderScope(
    key: ValueKey('real-$langCode-${surfaceSize.width}-${child.runtimeType}'),
    overrides: [
      uiStringsProvider.overrideWithValue(
        langCode == 'ar' ? fakeArUiStrings() : fakeEnUiStrings(),
      ),
      uiMessageControllerProvider.overrideWith(
        () => _TestUiMessageController(langCode),
      ),
      platformLocaleProvider.overrideWith(() => _MockLocaleController(locale)),
      platformLanguagesProvider.overrideWith((ref) async => _testLanguages),
      translationCoverageProvider.overrideWith((ref) async => _testCoverage),
      configHealthProvider.overrideWith((ref) async => _testHealth),
      auditEventsProvider.overrideWith((ref) async => _testAuditEvents),
      auditEventsPageProvider.overrideWith(
        (ref, query) async => const AuditEventPage(
          items: _testAuditEvents,
          total: 3,
          page: 0,
          size: 25,
        ),
      ),
      readinessProvider('ar').overrideWith((ref) async => _testReadinessAr),
      contentGenerationProvider('ar')
          .overrideWith((ref) async => _testContentGenerationAr),
      readinessProvider('en').overrideWith((ref) async => _testReadinessAr),
      contentGenerationProvider('en')
          .overrideWith((ref) async => _testContentGenerationAr),
      readinessProvider('de').overrideWith((ref) async => _testReadinessDe),
      contentGenerationProvider('de')
          .overrideWith((ref) async => _testContentGenerationDe),
    ],
    child: RepaintBoundary(
      key: boundaryKey,
      child: MediaQuery(
        data: MediaQueryData(size: surfaceSize),
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
          home: child,
        ),
      ),
    ),
  );
}

void _expectArabicActive(WidgetTester tester, Type screenType) {
  final finder = find.byType(screenType);
  expect(finder, findsOneWidget);
  final element = tester.element(finder);
  final container = ProviderScope.containerOf(element, listen: false);
  expect(container.read(uiMessageControllerProvider).activeLanguage, 'ar');
  expect(Localizations.localeOf(element).languageCode, 'ar');
  expect(Directionality.of(element), TextDirection.rtl);
  expect(find.text('العربية (AR)'), findsOneWidget);
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey key,
  String filename,
) async {
  _expectActionableSidebarIfVisible(tester);
  await tester.runAsync(() async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    expect(boundary, isNotNull, reason: 'missing boundary for $filename');
    final image = await boundary!.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(byteData, isNotNull, reason: 'no PNG bytes for $filename');
    final bytes = byteData!.buffer.asUint8List();

    final dir = Directory(_realScreenshotDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final file = File('${dir.path}/$filename');
    for (var attempt = 0; attempt < 6; attempt++) {
      try {
        await file.writeAsBytes(bytes, flush: true);
        break;
      } on FileSystemException {
        if (attempt == 5) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }
    expect(file.existsSync(), isTrue, reason: 'missing $filename');
    expect(file.lengthSync(), greaterThan(2000), reason: 'empty $filename');
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadMaterialIcons();
    await _loadRealFonts();
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  group('Phase 6 Settings, Languages, Workspace, and Audit Real-Font Screenshots', () {
    testWidgets('captures Settings landing real-font screenshots', (
      tester,
    ) async {
      final key = GlobalKey();

      // 1280 Desktop
      await tester.binding.setSurfaceSize(const Size(1280, 950));
      await tester.pumpWidget(
        _realFontHarness(
          boundaryKey: key,
          surfaceSize: const Size(1280, 950),
          child: const PlatformSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Languages & Coverage'), findsOneWidget);
      expect(find.text('Audit & Compliance'), findsOneWidget);
      expect(find.text('Configuration health'), findsOneWidget);
      expect(find.text('Developer / Maintenance'), findsOneWidget);
      await _capture(tester, key, 'settings_1280.png');

      // 1280 Arabic RTL
      final keyAr = GlobalKey();
      await tester.pumpWidget(
        _realFontHarness(
          boundaryKey: keyAr,
          locale: const Locale('ar'),
          surfaceSize: const Size(1280, 950),
          child: const PlatformSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();
      _expectArabicActive(tester, PlatformSettingsScreen);
      await _capture(tester, keyAr, 'settings_ar_1280.png');
    });

    testWidgets('captures Languages registry real-font screenshots', (
      tester,
    ) async {
      final key = GlobalKey();

      // 1280 Desktop
      await tester.binding.setSurfaceSize(const Size(1280, 1100));
      await tester.pumpWidget(
        _realFontHarness(
          boundaryKey: key,
          surfaceSize: const Size(1280, 1100),
          child: const LanguagesScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'languages_1280.png');

      // 1280 Arabic RTL
      final keyAr = GlobalKey();
      await tester.pumpWidget(
        _realFontHarness(
          boundaryKey: keyAr,
          locale: const Locale('ar'),
          surfaceSize: const Size(1280, 1100),
          child: const LanguagesScreen(),
        ),
      );
      await tester.pumpAndSettle();
      _expectArabicActive(tester, LanguagesScreen);
      await _capture(tester, keyAr, 'languages_ar_1280.png');
    });

    testWidgets('captures Language Workspace real-font screenshots', (
      tester,
    ) async {
      final key = GlobalKey();

      // 1280 Desktop
      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      await tester.pumpWidget(
        _realFontHarness(
          boundaryKey: key,
          surfaceSize: const Size(1280, 1000),
          child: const LanguageWorkspaceScreen(languageCode: 'ar'),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'language_workspace_1280.png');

      // 1280 Arabic RTL
      final keyAr = GlobalKey();
      await tester.pumpWidget(
        _realFontHarness(
          boundaryKey: keyAr,
          locale: const Locale('ar'),
          surfaceSize: const Size(1280, 1000),
          child: const LanguageWorkspaceScreen(languageCode: 'ar'),
        ),
      );
      await tester.pumpAndSettle();
      _expectArabicActive(tester, LanguageWorkspaceScreen);
      await _capture(tester, keyAr, 'language_workspace_ar_1280.png');

      // 360 Mobile
      final keyMobile = GlobalKey();
      await tester.binding.setSurfaceSize(const Size(360, 900));
      await tester.pumpWidget(
        _realFontHarness(
          boundaryKey: keyMobile,
          surfaceSize: const Size(360, 900),
          child: const LanguageWorkspaceScreen(languageCode: 'ar'),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, keyMobile, 'language_workspace_360.png');
    });

    testWidgets('captures Audit Log real-font screenshots', (tester) async {
      final key = GlobalKey();

      // 1280 Desktop
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(
        _realFontHarness(
          boundaryKey: key,
          surfaceSize: const Size(1280, 900),
          child: const AuditLogScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'audit_log_1280.png');

      // 768 Tablet
      final key768 = GlobalKey();
      await tester.binding.setSurfaceSize(const Size(768, 900));
      await tester.pumpWidget(
        _realFontHarness(
          boundaryKey: key768,
          surfaceSize: const Size(768, 900),
          child: const AuditLogScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key768, 'audit_log_768.png');

      // 360 Mobile
      final key360 = GlobalKey();
      await tester.binding.setSurfaceSize(const Size(360, 900));
      await tester.pumpWidget(
        _realFontHarness(
          boundaryKey: key360,
          surfaceSize: const Size(360, 900),
          child: const AuditLogScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key360, 'audit_log_360.png');

      // 1280 Arabic RTL
      final keyAr = GlobalKey();
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(
        _realFontHarness(
          boundaryKey: keyAr,
          locale: const Locale('ar'),
          surfaceSize: const Size(1280, 900),
          child: const AuditLogScreen(),
        ),
      );
      await tester.pumpAndSettle();
      _expectArabicActive(tester, AuditLogScreen);
      await _capture(tester, keyAr, 'audit_log_ar_1280.png');
    });

    test('verifies all expected Phase 6 real-font screenshots exist and are valid', () {
      final dir = Directory(_realScreenshotDir);
      for (final filename in _expectedSettingsRealScreenshots) {
        final file = File('${dir.path}/$filename');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'Expected screenshot $filename was not created.',
        );
        expect(
          file.lengthSync(),
          greaterThan(2000),
          reason:
              'Screenshot $filename is suspiciously small (${file.lengthSync()} bytes).',
        );
      }
    });
  });
}

void _expectActionableSidebarIfVisible(WidgetTester tester) {
  if (find
      .byKey(const Key('sidebar-language-status-card'))
      .evaluate()
      .isEmpty) {
    return;
  }
  expect(find.byKey(const Key('sidebar-language-loading')), findsNothing);
  expect(find.text('Deutsch (DE)'), findsOneWidget);
  expect(find.byKey(const Key('btn-sidebar-language-action')), findsOneWidget);
  if (find.text('Translating').evaluate().isNotEmpty) {
    expect(find.text('42 of 100 translated (42%)'), findsOneWidget);
    expect(find.text('Continue generation'), findsOneWidget);
  } else {
    expect(find.text('قيد الترجمة'), findsWidgets);
    expect(find.text('42 من 100 مترجم (42%)'), findsOneWidget);
    expect(find.text('متابعة التوليد'), findsOneWidget);
  }
}
