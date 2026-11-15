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
import 'package:platform_admin_app/src/features/documents/document_types_screen.dart';
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

const _expectedReportsRealScreenshots = <String>[
  'reports_document_types_1440.png',
  'reports_document_types_1280.png',
  'reports_document_types_768.png',
  'reports_document_types_360.png',
  'reports_document_types_ar_1280.png',
  'reports_document_type_form_1280.png',
  'reports_document_type_review_1280.png',
  'reports_document_type_form_360.png',
  'reports_document_type_form_ar_1280.png',
  'reports_document_type_validation_1280.png',
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
}

const _testDocTypes = [
  ReportDocumentType(
    id: 'doc-1',
    code: 'INSPECTION',
    name: 'Inspection Certificate',
    status: 'ACTIVE',
    required: true,
    sortOrder: 1,
  ),
  ReportDocumentType(
    id: 'doc-2',
    code: 'ESTIMATE',
    name: 'Cost Estimate',
    status: 'DRAFT',
    required: false,
    sortOrder: 2,
  ),
  ReportDocumentType(
    id: 'doc-3',
    code: 'INVOICE',
    name: 'Final Customer Invoice',
    status: 'ACTIVE',
    required: true,
    sortOrder: 3,
  ),
  ReportDocumentType(
    id: 'doc-4',
    code: 'DIAGNOSTIC_LOG',
    name: 'OBD-II Diagnostic Log',
    status: 'RETIRED',
    required: false,
    sortOrder: 4,
  ),
];

const _testLanguages = [
  PlatformLanguage(
    code: 'en',
    nativeName: 'English',
    direction: 'ltr',
    active: true,
    isDefault: true,
    sortOrder: 1,
    status: 'LIVE',
  ),
  PlatformLanguage(
    code: 'ar',
    nativeName: 'العربية',
    direction: 'rtl',
    active: true,
    isDefault: false,
    sortOrder: 2,
    status: 'LIVE',
  ),
];

const _testManifest = UiMessageManifest(
  defaultLanguage: 'en',
  namespaceVersions: {'platform_admin': 1, 'common': 1},
  languages: [
    UiMessageLanguage(code: 'en', direction: 'ltr', nativeName: 'English'),
    UiMessageLanguage(code: 'ar', direction: 'rtl', nativeName: 'العربية'),
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

Widget _realFontHarness({
  required Widget child,
  required GlobalKey boundaryKey,
  Locale locale = const Locale('en'),
  Size surfaceSize = const Size(1280, 900),
  List<ReportDocumentType> docTypes = _testDocTypes,
}) {
  final langCode = locale.languageCode;
  return ProviderScope(
    key: ValueKey(
      'reports-$langCode-${surfaceSize.width}-${child.runtimeType}',
    ),
    overrides: [
      uiStringsProvider.overrideWithValue(
        langCode == 'ar' ? fakeArUiStrings() : fakeEnUiStrings(),
      ),
      uiMessageControllerProvider.overrideWith(
        () => _TestUiMessageController(langCode),
      ),
      platformLocaleProvider.overrideWith(() => _MockLocaleController(locale)),
      platformLanguagesProvider.overrideWith((ref) async => _testLanguages),
      documentTypesProvider.overrideWith((ref) async => docTypes),
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

  group('Reports Document Types Real Font Screenshots', () {
    testWidgets('captures real-font document types list screenshots', (
      tester,
    ) async {
      final key = GlobalKey();

      // 1. 1440 Desktop Wide
      await tester.binding.setSurfaceSize(const Size(1440, 1000));
      await tester.pumpWidget(
        _realFontHarness(
          child: const DocumentTypesScreen(),
          boundaryKey: key,
          surfaceSize: const Size(1440, 1000),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'reports_document_types_1440.png');

      // 2. 1280 Desktop
      await tester.binding.setSurfaceSize(const Size(1280, 950));
      await tester.pumpWidget(
        _realFontHarness(
          child: const DocumentTypesScreen(),
          boundaryKey: key,
          surfaceSize: const Size(1280, 950),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'reports_document_types_1280.png');

      // 3. 768 Tablet
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pumpWidget(
        _realFontHarness(
          child: const DocumentTypesScreen(),
          boundaryKey: key,
          surfaceSize: const Size(768, 1024),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'reports_document_types_768.png');

      // 4. 360 Mobile
      await tester.binding.setSurfaceSize(const Size(360, 1200));
      await tester.pumpWidget(
        _realFontHarness(
          child: const DocumentTypesScreen(),
          boundaryKey: key,
          surfaceSize: const Size(360, 1200),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'reports_document_types_360.png');

      // 5. Arabic RTL 1280
      await tester.binding.setSurfaceSize(const Size(1280, 950));
      await tester.pumpWidget(
        _realFontHarness(
          child: const DocumentTypesScreen(),
          boundaryKey: key,
          locale: const Locale('ar'),
          surfaceSize: const Size(1280, 950),
        ),
      );
      await tester.pumpAndSettle();
      _expectArabicActive(tester, DocumentTypesScreen);
      await _capture(tester, key, 'reports_document_types_ar_1280.png');

      tester.binding.setSurfaceSize(null);
    });

    testWidgets('captures real-font document type dialog/form screenshots', (
      tester,
    ) async {
      // 1. Form 1280
      final formKey1280 = GlobalKey();
      await tester.binding.setSurfaceSize(const Size(1280, 950));
      await tester.pumpWidget(
        _realFontHarness(
          child: DocumentTypesScreen.buildDialog(initial: _testDocTypes.first),
          boundaryKey: formKey1280,
          surfaceSize: const Size(1280, 950),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(
        tester,
        formKey1280,
        'reports_document_type_form_1280.png',
      );

      await tester.ensureVisible(find.text('Review & Save'));
      await tester.pumpAndSettle();
      await _capture(
        tester,
        formKey1280,
        'reports_document_type_review_1280.png',
      );

      // 2. Form 360 Mobile
      final formKey360 = GlobalKey();
      await tester.binding.setSurfaceSize(const Size(360, 800));
      await tester.pumpWidget(
        _realFontHarness(
          child: DocumentTypesScreen.buildDialog(initial: _testDocTypes.first),
          boundaryKey: formKey360,
          surfaceSize: const Size(360, 800),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, formKey360, 'reports_document_type_form_360.png');

      // 3. Form Arabic 1280
      final formKeyAr = GlobalKey();
      await tester.binding.setSurfaceSize(const Size(1280, 950));
      await tester.pumpWidget(
        _realFontHarness(
          child: DocumentTypesScreen.buildDialog(initial: _testDocTypes.first),
          boundaryKey: formKeyAr,
          locale: const Locale('ar'),
          surfaceSize: const Size(1280, 950),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(
        tester,
        formKeyAr,
        'reports_document_type_form_ar_1280.png',
      );

      // 4. Form Validation Error at 1280
      final valKey = GlobalKey();
      await tester.binding.setSurfaceSize(const Size(1280, 950));
      await tester.pumpWidget(
        _realFontHarness(
          child: DocumentTypesScreen.buildDialog(),
          boundaryKey: valKey,
          surfaceSize: const Size(1280, 950),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Save with empty fields to trigger validation state
      await tester.tap(find.byKey(const Key('doc-type-save')));
      await tester.pumpAndSettle();

      expect(find.text('This field is required.'), findsWidgets);
      await _capture(
        tester,
        valKey,
        'reports_document_type_validation_1280.png',
      );

      tester.binding.setSurfaceSize(null);
    });

    test('real-font reports screenshots and MaterialIcons are available', () {
      expect(_materialIconsLoaded, isTrue);
      for (final filename in _expectedReportsRealScreenshots) {
        final file = File('$_realScreenshotDir/$filename');
        expect(file.existsSync(), isTrue, reason: 'missing $filename');
        expect(file.lengthSync(), greaterThan(2000), reason: 'empty $filename');
      }
    });
  });
}
