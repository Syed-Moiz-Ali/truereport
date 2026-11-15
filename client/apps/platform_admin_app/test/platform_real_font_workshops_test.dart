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
import 'package:platform_admin_app/src/components/platform_chips.dart';
import 'package:platform_admin_app/src/features/workshops/workshop_detail_screen.dart';
import 'package:platform_admin_app/src/features/workshops/workshop_form.dart';
import 'package:platform_admin_app/src/features/workshops/workshops_screen.dart';
import 'package:platform_admin_app/src/platform_catalogue_models.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/platform_theme.dart';

import 'support/fake_platform_api.dart';
import 'support/ui_message_fixtures.dart';

class _MockLocaleController extends LocaleController {
  _MockLocaleController(this._initial);
  final Locale _initial;

  @override
  Locale build() => _initial;
}

const _realScreenshotDir = 'test/screenshots/real';

const _expectedRealScreenshots = <String>[
  'workshops_1440.png',
  'workshops_1280.png',
  'workshops_768.png',
  'workshops_360.png',
  'workshops_ar_1280.png',
  'workshop_detail_1440.png',
  'workshop_detail_1280.png',
  'workshop_detail_768.png',
  'workshop_detail_360.png',
  'workshop_detail_ar_1280.png',
  'workshop_detail_staff_1280.png',
  'workshop_detail_staff_ar_1280.png',
  'workshop_detail_staff_empty_1280.png',
  'workshop_detail_templates_1280.png',
  'workshop_detail_templates_ar_1280.png',
  'workshop_detail_activity_1280.png',
  'workshop_detail_activity_ar_1280.png',
  'workshop_add_staff_dialog_1280.png',
  'workshop_add_staff_dialog_ar_1280.png',
  'workshop_form_1280.png',
  'workshop_form_360.png',
  'workshop_form_ar_1280.png',
  'workshop_form_validation_1280.png',
  'workshop_form_no_templates_1280.png',
];

bool _materialIconsLoaded = false;

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
  _materialIconsLoaded = true;
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

  await _loadMaterialIcons();
}

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

const _testManifest = UiMessageManifest(
  defaultLanguage: 'en',
  namespaceVersions: {'platform_admin': 1, 'common': 1},
  languages: [
    UiMessageLanguage(code: 'en', direction: 'ltr', nativeName: 'English'),
    UiMessageLanguage(code: 'ar', direction: 'rtl', nativeName: 'العربية'),
    UiMessageLanguage(code: 'zh-hans', direction: 'ltr', nativeName: '中文'),
  ],
);

const _testReadinessZh = LanguageReadiness(
  language: 'zh-Hans',
  nativeName: '中文',
  direction: 'ltr',
  isDefault: false,
  status: 'TRANSLATING',
  readinessPercent: 42,
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

const _template = GlobalTemplate(
  id: 'tpl-1',
  code: 'TPL-30-GCC',
  nameEn: 'GCC Standard Fleet Inspection',
  nameAr: 'الفحص القياسي لأسطول الخليج',
  descriptionEn:
      'Official GCC multi-point vehicle roadworthiness specification.',
  descriptionAr: 'المواصفة الرسمية الخليجية لصلاحية المركبات للسير على الطرق.',
  status: 'PUBLISHED',
  currentPublishedVersionId: 'v1',
  versionCount: 1,
  currentVersionNo: 1,
  versions: [],
  categories: [],
);

const _testAuditEvents = [
  PlatformAuditEvent(
    id: 'audit-1',
    action: 'WORKSHOP_REGISTERED',
    entityType: 'WORKSHOP',
    entityId: 'workshop-1',
    actorRole: 'PLATFORM_ADMIN',
    occurredAt: '2026-11-12T10:00:00Z',
    reasonCode: 'INITIAL_SETUP',
    metadataJson: '{"workshopId":"workshop-1"}',
  ),
];

Widget _realFontHarness({
  required Widget child,
  required GlobalKey boundaryKey,
  Locale locale = const Locale('en'),
  Size surfaceSize = const Size(1280, 900),
  FakePlatformAdminApi? api,
  List<GlobalTemplate> templates = const [_template],
}) {
  final fakeApi = api ?? FakePlatformAdminApi();
  final langCode = locale.languageCode;
  return ProviderScope(
    key: ValueKey(
      'scope-$langCode-${surfaceSize.width}-${child.runtimeType}-'
      '${templates.length}',
    ),
    overrides: [
      uiStringsProvider.overrideWithValue(
        langCode == 'ar' ? fakeArUiStrings() : fakeEnUiStrings(),
      ),
      uiMessageControllerProvider.overrideWith(
        () => _TestUiMessageController(langCode),
      ),
      platformLocaleProvider.overrideWith(() => _MockLocaleController(locale)),
      platformApiProvider.overrideWithValue(fakeApi),
      platformLanguagesProvider.overrideWith((ref) async => _testLanguages),
      templatesProvider.overrideWith((ref) => Future.value(templates)),
      availableTemplatesProvider.overrideWith((ref) => Future.value(templates)),
      auditEventsProvider.overrideWith((ref) async => _testAuditEvents),
      readinessProvider('zh-Hans')
          .overrideWith((ref) async => _testReadinessZh),
      contentGenerationProvider('zh-Hans')
          .overrideWith((ref) async => _idleGen),
      readinessProvider('en').overrideWith((ref) async => _testReadinessLive),
      contentGenerationProvider('en').overrideWith((ref) async => _idleGen),
      readinessProvider('ar').overrideWith((ref) async => _testReadinessLive),
      contentGenerationProvider('ar').overrideWith((ref) async => _idleGen),
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

Future<void> _capture(
  WidgetTester tester,
  GlobalKey key,
  String filename,
) async {
  expect(filename, isNot(startsWith('real/')));
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
    await _loadRealFonts();
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  group('Workshops Real Font Screenshots', () {
    testWidgets('captures real-font workshops list screenshots', (
      tester,
    ) async {
      final key = GlobalKey();
      final api = FakePlatformAdminApi();

      // 1. 1440 Desktop
      await tester.binding.setSurfaceSize(const Size(1440, 1000));
      await tester.pumpWidget(
        _realFontHarness(
          child: const WorkshopsScreen(),
          boundaryKey: key,
          surfaceSize: const Size(1440, 1000),
          api: api,
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'workshops_1440.png');

      // 2. 1280 Desktop
      await tester.binding.setSurfaceSize(const Size(1280, 950));
      await tester.pumpWidget(
        _realFontHarness(
          child: const WorkshopsScreen(),
          boundaryKey: key,
          surfaceSize: const Size(1280, 950),
          api: api,
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'workshops_1280.png');

      // 3. 768 Tablet
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pumpWidget(
        _realFontHarness(
          child: const WorkshopsScreen(),
          boundaryKey: key,
          surfaceSize: const Size(768, 1024),
          api: api,
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'workshops_768.png');

      // 4. 360 Mobile
      await tester.binding.setSurfaceSize(const Size(360, 1200));
      await tester.pumpWidget(
        _realFontHarness(
          child: const WorkshopsScreen(),
          boundaryKey: key,
          surfaceSize: const Size(360, 1200),
          api: api,
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'workshops_360.png');

      // 5. Arabic RTL 1280
      await tester.binding.setSurfaceSize(const Size(1280, 950));
      await tester.pumpWidget(
        _realFontHarness(
          child: const WorkshopsScreen(),
          boundaryKey: key,
          locale: const Locale('ar'),
          surfaceSize: const Size(1280, 950),
          api: api,
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'workshops_ar_1280.png');

      tester.binding.setSurfaceSize(null);
    });

    testWidgets('captures real-font workshop detail screenshots', (
      tester,
    ) async {
      final key = GlobalKey();
      final api = FakePlatformAdminApi();

      // 1. 1440 Desktop
      await tester.binding.setSurfaceSize(const Size(1440, 1100));
      await tester.pumpWidget(
        _realFontHarness(
          child: const WorkshopDetailScreen(workshopId: 'workshop-1'),
          boundaryKey: key,
          surfaceSize: const Size(1440, 1100),
          api: api,
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'workshop_detail_1440.png');

      // 2. 1280 Desktop
      await tester.binding.setSurfaceSize(const Size(1280, 1050));
      await tester.pumpWidget(
        _realFontHarness(
          child: const WorkshopDetailScreen(workshopId: 'workshop-1'),
          boundaryKey: key,
          surfaceSize: const Size(1280, 1050),
          api: api,
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'workshop_detail_1280.png');

      // 3. 768 Tablet
      await tester.binding.setSurfaceSize(const Size(768, 1100));
      await tester.pumpWidget(
        _realFontHarness(
          child: const WorkshopDetailScreen(workshopId: 'workshop-1'),
          boundaryKey: key,
          surfaceSize: const Size(768, 1100),
          api: api,
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'workshop_detail_768.png');

      // 4. 360 Mobile
      await tester.binding.setSurfaceSize(const Size(360, 1400));
      await tester.pumpWidget(
        _realFontHarness(
          child: const WorkshopDetailScreen(workshopId: 'workshop-1'),
          boundaryKey: key,
          surfaceSize: const Size(360, 1400),
          api: api,
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'workshop_detail_360.png');

      // 5. Arabic RTL 1280
      await tester.binding.setSurfaceSize(const Size(1280, 1050));
      await tester.pumpWidget(
        _realFontHarness(
          child: const WorkshopDetailScreen(workshopId: 'workshop-1'),
          boundaryKey: key,
          locale: const Locale('ar'),
          surfaceSize: const Size(1280, 1050),
          api: api,
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'workshop_detail_ar_1280.png');

      tester.binding.setSurfaceSize(null);
    });

    testWidgets('captures real-font workshop tab and add-staff screenshots', (
      tester,
    ) async {
      final api = FakePlatformAdminApi();
      final key = GlobalKey();

      await tester.binding.setSurfaceSize(const Size(1280, 1300));
      await tester.pumpWidget(
        _realFontHarness(
          child: const WorkshopDetailScreen(workshopId: 'workshop-1'),
          boundaryKey: key,
          surfaceSize: const Size(1280, 1300),
          api: api,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PlatformFilterChip).at(1));
      await tester.pumpAndSettle();
      expect(find.text('Workshop Admins (0)'), findsOneWidget);
      expect(find.text('Technicians (4)'), findsOneWidget);
      expect(find.text('Pending invitations (0)'), findsOneWidget);
      await _capture(tester, key, 'workshop_detail_staff_1280.png');

      await tester.tap(find.text('Add staff'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('input-staff-name')), findsOneWidget);
      expect(find.byKey(const Key('input-staff-email')), findsOneWidget);
      expect(find.byKey(const Key('input-staff-password')), findsOneWidget);
      await _capture(tester, key, 'workshop_add_staff_dialog_1280.png');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PlatformFilterChip).at(2));
      await tester.pumpAndSettle();
      expect(find.text('Available templates'), findsWidgets);
      expect(
        find.text('Published global templates available to this workshop.'),
        findsOneWidget,
      );
      await _capture(tester, key, 'workshop_detail_templates_1280.png');

      await tester.tap(find.byType(PlatformFilterChip).at(3));
      await tester.pumpAndSettle();
      expect(find.text('Workshop registered'), findsWidgets);
      expect(find.textContaining('Platform Admin'), findsWidgets);
      expect(find.textContaining('Initial setup'), findsWidgets);
      expect(find.text('WORKSHOP_REGISTERED'), findsNothing);
      expect(find.text('2026-11-12T10:00:00Z'), findsNothing);
      await _capture(tester, key, 'workshop_detail_activity_1280.png');

      final emptyApi = FakePlatformAdminApi();
      emptyApi.workshops = [
        const HierarchyWorkshop(
          id: 'workshop-1',
          name: 'Workshop A',
          branchName: 'EMEA Industrial Hub',
          status: 'ACTIVE',
          memberCount: 14,
          bayCount: 8,
          assignedCapacityPercent: 88,
          admins: [],
          technicians: [],
          pendingInvitations: [],
        ),
      ];
      final emptyKey = GlobalKey();
      await tester.pumpWidget(
        _realFontHarness(
          child: const WorkshopDetailScreen(workshopId: 'workshop-1'),
          boundaryKey: emptyKey,
          surfaceSize: const Size(1280, 1300),
          api: emptyApi,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PlatformFilterChip).at(1));
      await tester.pumpAndSettle();
      expect(find.text('No workshop admins yet.'), findsOneWidget);
      expect(find.text('No technicians yet.'), findsOneWidget);
      expect(find.text('No pending invitations.'), findsOneWidget);
      await _capture(tester, emptyKey, 'workshop_detail_staff_empty_1280.png');

      final arabicKey = GlobalKey();
      await tester.pumpWidget(
        _realFontHarness(
          child: const WorkshopDetailScreen(workshopId: 'workshop-1'),
          boundaryKey: arabicKey,
          locale: const Locale('ar'),
          surfaceSize: const Size(1280, 1300),
          api: api,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PlatformFilterChip).at(1));
      await tester.pumpAndSettle();
      await _capture(tester, arabicKey, 'workshop_detail_staff_ar_1280.png');

      await tester.tap(find.text('إضافة موظف'));
      await tester.pumpAndSettle();
      await _capture(
        tester,
        arabicKey,
        'workshop_add_staff_dialog_ar_1280.png',
      );
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PlatformFilterChip).at(2));
      await tester.pumpAndSettle();
      await _capture(
        tester,
        arabicKey,
        'workshop_detail_templates_ar_1280.png',
      );

      await tester.tap(find.byType(PlatformFilterChip).at(3));
      await tester.pumpAndSettle();
      expect(find.text('تم تسجيل الورشة'), findsWidgets);
      expect(find.textContaining('مدير المنصة'), findsWidgets);
      expect(find.textContaining('الإعداد الأولي'), findsWidgets);
      expect(find.text('WORKSHOP_REGISTERED'), findsNothing);
      expect(find.text('2026-11-12T10:00:00Z'), findsNothing);
      await _capture(tester, arabicKey, 'workshop_detail_activity_ar_1280.png');

      tester.binding.setSurfaceSize(null);
    });

    testWidgets('captures real-font workshop form screenshots', (tester) async {
      final key = GlobalKey();
      final api = FakePlatformAdminApi();

      // 1. 1280 Desktop
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(
        _realFontHarness(
          child: const WorkshopFormPage(),
          boundaryKey: key,
          surfaceSize: const Size(1280, 900),
          api: api,
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'workshop_form_1280.png');

      // 2. Validation state at 1280
      await tester.enterText(
        find.byKey(const Key('input-workshop-email')),
        'not-an-email',
      );
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('This field is required.'), findsWidgets);
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      await _capture(tester, key, 'workshop_form_validation_1280.png');

      // 3. 360 Mobile
      final mobileKey = GlobalKey();
      await tester.binding.setSurfaceSize(const Size(360, 1000));
      await tester.pumpWidget(
        _realFontHarness(
          child: const WorkshopFormPage(),
          boundaryKey: mobileKey,
          surfaceSize: const Size(360, 1000),
          api: api,
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, mobileKey, 'workshop_form_360.png');

      // 4. Arabic RTL 1280
      final arabicKey = GlobalKey();
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(
        _realFontHarness(
          child: const WorkshopFormPage(),
          boundaryKey: arabicKey,
          locale: const Locale('ar'),
          surfaceSize: const Size(1280, 900),
          api: api,
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, arabicKey, 'workshop_form_ar_1280.png');

      // 5. No published templates at 1280
      final noTemplatesKey = GlobalKey();
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(
        _realFontHarness(
          child: const WorkshopFormPage(),
          boundaryKey: noTemplatesKey,
          surfaceSize: const Size(1280, 900),
          api: api,
          templates: const [],
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'No published templates available. Create and publish a template first.',
        ),
        findsOneWidget,
      );
      expect(find.text('View templates'), findsOneWidget);
      final saveButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Save'),
      );
      expect(saveButton.onPressed, isNull);
      await _capture(
        tester,
        noTemplatesKey,
        'workshop_form_no_templates_1280.png',
      );

      tester.binding.setSurfaceSize(null);
    });

    test('real-font workshop screenshots and MaterialIcons are available', () {
      expect(_materialIconsLoaded, isTrue);
      for (final filename in _expectedRealScreenshots) {
        final file = File('$_realScreenshotDir/$filename');
        expect(file.existsSync(), isTrue, reason: 'missing $filename');
        expect(file.lengthSync(), greaterThan(2000), reason: 'empty $filename');
      }
    });
  });
}
