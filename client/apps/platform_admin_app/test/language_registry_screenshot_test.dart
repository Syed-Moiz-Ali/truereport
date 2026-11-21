import 'dart:io';
import 'dart:ui' as ui;

import 'package:api_client/api_client.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/components/platform_buttons.dart';
import 'package:platform_admin_app/src/features/languages/language_workspace_screen.dart';
import 'package:platform_admin_app/src/features/languages/languages_screen.dart';
import 'package:platform_admin_app/src/platform_config_api.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/platform_theme.dart';
import 'package:reference_data/reference_data.dart';

import 'reference_test_support.dart';

/// Real-font evidence for the language registry (Add language, registered
/// without-catalog cards) and the workspace header (Retire language).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadRealFonts);

  testWidgets('capture the language registry at desktop, tablet and phone', (
    tester,
  ) async {
    for (final size in const <Size>[
      Size(1440, 900),
      Size(1440, 1200),
      Size(1024, 768),
      Size(390, 844),
      Size(360, 740),
    ]) {
      final key = GlobalKey();
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(_harness(key, const LanguagesScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await _capture(
        tester,
        key,
        'languages_${size.width.toInt()}x${size.height.toInt()}.png',
      );
    }
    tester.binding.setSurfaceSize(null);
  });

  testWidgets('capture the Add language dialog at desktop and phone', (
    tester,
  ) async {
    for (final size in const <Size>[Size(1440, 900), Size(390, 844)]) {
      final key = GlobalKey();
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(_harness(key, const LanguagesScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn-add-language')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _capture(
        tester,
        key,
        'add_language_dialog_${size.width.toInt()}.png',
      );
      await tester.tap(find.byKey(const Key('add-language-cancel')));
      await tester.pumpAndSettle();
    }
    tester.binding.setSurfaceSize(null);
  });

  testWidgets('capture the workspace header with the retire action', (
    tester,
  ) async {
    for (final size in const <Size>[Size(1440, 900), Size(390, 844)]) {
      final key = GlobalKey();
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        _harness(key, const LanguageWorkspaceScreen(languageCode: 'de')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await _capture(
        tester,
        key,
        'language_workspace_retire_${size.width.toInt()}.png',
      );

      await tester.tap(find.byKey(const Key('btn-retire-language')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _capture(tester, key, 'retire_confirm_${size.width.toInt()}.png');
      await tester.tap(find.widgetWithText(PlatformGhostButton, 'Cancel'));
      await tester.pumpAndSettle();
    }
    tester.binding.setSurfaceSize(null);
  });
}

const _manifest = UiMessageManifest(
  defaultLanguage: 'en',
  namespaceVersions: <String, int>{'common': 1, 'platform_admin': 1},
  languages: <UiMessageLanguage>[
    UiMessageLanguage(
      code: 'en',
      direction: 'ltr',
      nativeName: 'English',
      path: 'platform_admin/en.json',
      totalKeys: 963,
      missingKeys: 0,
    ),
    UiMessageLanguage(
      code: 'es',
      direction: 'ltr',
      nativeName: 'Español',
      path: 'platform_admin/es.json',
      totalKeys: 963,
      missingKeys: 41,
      placeholderMismatch: 2,
    ),
    UiMessageLanguage(
      code: 'fr',
      direction: 'ltr',
      nativeName: 'Français',
      path: 'platform_admin/fr.json',
      totalKeys: 963,
      missingKeys: 0,
    ),
  ],
);

const _registry = <PlatformLanguage>[
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
    code: 'de',
    nativeName: 'Deutsch',
    direction: 'ltr',
    active: true,
    isDefault: false,
    sortOrder: 4,
    status: 'DRAFT',
  ),
];

const _coverage = TranslationCoverage(
  languages: <String>['en', 'es', 'fr'],
  namespaces: <String, CoverageNamespace>{
    'platform_admin': CoverageNamespace(
      total: 963,
      missing: <String>['es:languages.add.button'],
    ),
    'common': CoverageNamespace(total: 154, missing: <String>[]),
  },
);

Widget _harness(GlobalKey key, Widget child) {
  return ProviderScope(
    overrides: [
      uiStringsProvider.overrideWithValue(loadReferenceStrings()),
      platformConfigApiProvider.overrideWithValue(_FakeConfigApi()),
      platformUiManifestProvider.overrideWithValue(_manifest),
      platformLanguagesProvider.overrideWith((ref) async => _registry),
      translationCoverageProvider.overrideWith((ref) async => _coverage),
      readinessProvider('en').overrideWith((ref) async => _readiness('en')),
      readinessProvider('de').overrideWith((ref) async => _readiness('de')),
      statusesProvider('translation-status')
          .overrideWith((ref) async => const <ReferenceRecord>[]),
      statusesProvider('workshop')
          .overrideWith((ref) async => const <ReferenceRecord>[]),
      statusesProvider('checklist')
          .overrideWith((ref) async => const <ReferenceRecord>[]),
      statusesProvider('health')
          .overrideWith((ref) async => const <ReferenceRecord>[]),
      statusesProvider('document')
          .overrideWith((ref) async => const <ReferenceRecord>[]),
      statusesProvider('chip')
          .overrideWith((ref) async => const <ReferenceRecord>[]),
      sessionStoreProvider.overrideWithValue(_MemorySessionStore()),
    ],
    child: RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          fontFamily: TrFonts.latin,
          scaffoldBackgroundColor: PtTheme.canvas,
        ),
        home: child,
      ),
    ),
  );
}

LanguageReadiness _readiness(String code) => LanguageReadiness(
  language: code,
  status: code == 'de' ? 'DRAFT' : 'LIVE',
  nativeName: code == 'de' ? 'Deutsch' : 'English',
  direction: 'ltr',
  isDefault: code == 'en',
  uiMessagesPath: 'platform_admin/$code.json',
  readinessPercent: code == 'de' ? 42 : 100,
  uiMessages: UiMessageCoverage(
    total: 963,
    approved: code == 'de' ? 402 : 963,
    missing: code == 'de' ? 561 : 0,
    changed: 0,
    path: 'platform_admin/$code.json',
    generationStatus: 'IDLE',
  ),
  content: const <String, EntityReadiness>{
    'CATEGORY': EntityReadiness(total: 18, approved: 7),
    'ITEM': EntityReadiness(total: 240, approved: 96),
  },
  blockers: code == 'de'
      ? const <ReadinessBlocker>[
          ReadinessBlocker(
            code: 'UI_TEXT',
            tab: 'overview',
            count: 561,
            message: '561 interface text keys are still untranslated.',
          ),
        ]
      : const <ReadinessBlocker>[],
);

class _FakeConfigApi extends PlatformConfigApi {
  _FakeConfigApi()
    : super(
        ApiClient(
          config: const ApiConfig(
            baseUrl: 'http://localhost:8080',
            environment: 'test',
          ),
        ),
        const ApiEndpoints(baseUrl: 'http://localhost:8080'),
      );

  @override
  Future<List<PlatformLanguage>> platformLanguages() async => _registry;

  @override
  Future<TranslationCoverage> translationCoverage() async => _coverage;

  @override
  Future<LanguageReadiness> readiness(String code) async => _readiness(code);
}

class _MemorySessionStore implements SessionStore {
  @override
  Future<void> save(Map<String, dynamic> session) async {}

  @override
  Future<Map<String, dynamic>?> read() async => null;

  @override
  Future<void> clear() async {}
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
    final bareFamily = family.replaceFirst('packages/design_system/', '');
    final bareLoader = families.putIfAbsent(
      bareFamily,
      () => FontLoader(bareFamily),
    );
    bareLoader.addFont(Future.value(ByteData.sublistView(bytes)));
  }

  const materialPath = 'build/unit_test_assets/fonts/MaterialIcons-Regular.otf';
  final materialFile = File(materialPath);
  if (materialFile.existsSync()) {
    final bytes = await materialFile.readAsBytes();
    final loader = families.putIfAbsent(
      'MaterialIcons',
      () => FontLoader('MaterialIcons'),
    );
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }

  for (final entry in families.entries) {
    await entry.value.load();
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
    final dir = Directory('test/screenshots/languages');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    File('${dir.path}/$filename').writeAsBytesSync(bytes, flush: true);
  });
}
