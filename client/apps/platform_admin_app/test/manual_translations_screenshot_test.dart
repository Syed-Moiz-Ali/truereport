import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:api_client/api_client.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/components/platform_states.dart';
import 'package:platform_admin_app/src/features/languages/manual_translation_models.dart';
import 'package:platform_admin_app/src/features/languages/manual_translation_providers.dart';
import 'package:platform_admin_app/src/features/languages/manual_translations_screen.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/platform_theme.dart';
import 'package:platform_admin_app/src/reference_status_lookup.dart';
import 'package:reference_data/reference_data.dart';

import 'reference_test_support.dart';

/// Real-font evidence for the manual translations screen at the desktop,
/// tablet and phone breakpoints, plus the "nothing missing" empty state.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadRealFonts);

  testWidgets('capture manual translations at desktop, tablet and phone', (
    tester,
  ) async {
    final sizes = <Size>[
      const Size(1440, 900),
      const Size(1024, 768),
      const Size(390, 844),
      const Size(360, 740),
    ];

    for (final size in sizes) {
      final key = GlobalKey();
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(_harness(key));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await _capture(
        tester,
        key,
        'manual_translations_${size.width.toInt()}.png',
      );
    }

    tester.binding.setSurfaceSize(null);
  });

  testWidgets('capture the missing-filter empty state', (tester) async {
    final key = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(
      _harness(
        key,
        summary: const ManualTranslationSummary(total: 394, missing: 0),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Missing'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Nothing missing for this language'), findsOneWidget);
    await _capture(tester, key, 'manual_translations_empty_missing.png');

    tester.binding.setSurfaceSize(null);
  });

  testWidgets('capture the loading skeleton and scoped error state', (
    tester,
  ) async {
    final loadingKey = GlobalKey();
    final loading = Completer<ManualTranslationPage>();
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(
      _harness(loadingKey, pageLoader: (_) => loading.future),
    );
    await tester.pump();

    expect(find.byType(PlatformSkeletonList), findsOneWidget);
    await _capture(tester, loadingKey, 'manual_translations_loading.png');

    loading.complete(_populatedPage);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    final errorKey = GlobalKey();
    await tester.pumpWidget(
      _harness(
        errorKey,
        pageLoader: (_) async => throw const ApiFailure(
          code: 'SERVER_ERROR',
          messageKey: 'error.generic',
          statusCode: 500,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    await _capture(tester, errorKey, 'manual_translations_error.png');

    tester.binding.setSurfaceSize(null);
  });
}

Widget _harness(
  GlobalKey boundaryKey, {
  ManualTranslationSummary summary = const ManualTranslationSummary(
    total: 394,
    missing: 17,
  ),
  Future<ManualTranslationPage> Function(ManualTranslationQuery query)?
  pageLoader,
}) {
  const populated = ManualTranslationQuery(lang: 'es');
  const missingFilter = ManualTranslationQuery(
    lang: 'es',
    filter: ManualTranslationFilter.missing,
  );

  return ProviderScope(
    overrides: [
      uiStringsProvider.overrideWithValue(loadReferenceStrings()),
      platformLanguagesProvider.overrideWith(
        (ref) async => const <PlatformLanguage>[
          PlatformLanguage(
            code: 'es',
            nativeName: 'Español',
            direction: 'ltr',
            active: true,
            isDefault: false,
            sortOrder: 1,
            status: 'LIVE',
          ),
        ],
      ),
      enumsProvider(contentTypeEnum).overrideWith(
        (ref) async => const <ReferenceRecord>[
          ReferenceRecord(
            code: 'CATEGORY',
            labelKey: 'languageWorkspace.tab.categories',
          ),
          ReferenceRecord(
            code: 'ITEM',
            labelKey: 'languageWorkspace.tab.checklistItems',
          ),
          ReferenceRecord(
            code: 'OPTION_SET',
            labelKey: 'languageWorkspace.tab.optionSets',
          ),
          ReferenceRecord(
            code: 'OPTION_VALUE',
            labelKey: 'languageWorkspace.tab.optionValues',
          ),
          ReferenceRecord(
            code: 'TEMPLATE',
            labelKey: 'languageWorkspace.tab.templates',
          ),
          ReferenceRecord(
            code: 'DOCUMENT_TYPE',
            labelKey: 'languageWorkspace.tab.documentTypes',
          ),
          ReferenceRecord(
            code: 'ISSUE_FIELD',
            labelKey: 'languageWorkspace.tab.issueFields',
          ),
        ],
      ),
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
      manualTranslationSummaryProvider('es')
          .overrideWith((ref) async => summary),
      manualTranslationsPageProvider(populated).overrideWith(
        (ref) async =>
            pageLoader == null ? _populatedPage : await pageLoader(populated),
      ),
      manualTranslationsPageProvider(missingFilter).overrideWith(
        (ref) async => const ManualTranslationPage(
          lang: 'es',
          total: 0,
          page: 0,
          size: 50,
          items: <ManualTranslationUnit>[],
        ),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
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
        child: const ManualTranslationsScreen(languageCode: 'es'),
      ),
    ),
  );
}

const ManualTranslationPage _populatedPage = ManualTranslationPage(
  lang: 'es',
  total: 394,
  page: 0,
  size: 50,
  items: <ManualTranslationUnit>[
    ManualTranslationUnit(
      entityType: 'CATEGORY',
      entityId: '8f14e45f-ceea-4a3a-9d1f-2b7c6a4d0e11',
      field: 'name',
      sourceText: 'Suspension, Steering & Underbody',
      text: 'Suspensión, dirección y bajo cuerpo',
      status: 'PENDING_REVIEW',
      origin: 'AUTHORED',
      safetyCritical: true,
    ),
    ManualTranslationUnit(
      entityType: 'CATEGORY',
      entityId: 'a2c7d9b1-0e34-4c9a-8b5f-1d2e3f4a5b6c',
      field: 'name',
      sourceText: 'Braking System and Hydraulic Lines',
      text: null,
      safetyCritical: true,
    ),
    ManualTranslationUnit(
      entityType: 'ITEM',
      entityId: 'b7c8d9e0-1f2a-4b3c-9d4e-5f6a7b8c9d0e',
      field: 'label',
      sourceText: 'Inspect the front lower control arm bushings for cracks, perishing or excessive play',
      text:
          'Inspeccione los casquillos del brazo de control inferior delantero',
      status: 'REVIEWED',
      origin: 'REVIEWED',
    ),
    ManualTranslationUnit(
      entityType: 'ITEM',
      entityId: 'c1d2e3f4-5a6b-4c7d-8e9f-0a1b2c3d4e5f',
      field: 'instruction',
      sourceText: 'Replace if any play is detected',
      text: null,
    ),
    ManualTranslationUnit(
      entityType: 'OPTION_SET',
      entityId: 'd4e5f6a7-b8c9-4d0e-9f1a-2b3c4d5e6f70',
      field: 'name',
      sourceText: 'Brake pad wear result',
      text: 'Resultado del desgaste de la pastilla de freno',
      status: 'DRAFT',
      origin: 'AUTHORED',
    ),
    ManualTranslationUnit(
      entityType: 'OPTION_VALUE',
      entityId: 'e7f8a9b0-c1d2-4e3f-8a4b-5c6d7e8f9a0b',
      field: 'label',
      sourceText: 'Attention recommended',
      text: 'Atención recomendada',
      status: 'STALE',
      origin: 'REVIEWED',
    ),
    ManualTranslationUnit(
      entityType: 'TEMPLATE',
      entityId: 'f0a1b2c3-d4e5-4f6a-9b7c-8d9e0f1a2b3c',
      field: 'name',
      sourceText: 'Pre-purchase inspection — comprehensive',
      text: null,
    ),
    ManualTranslationUnit(
      entityType: 'DOCUMENT_TYPE',
      entityId: 'a3b4c5d6-e7f8-4a9b-8c0d-1e2f3a4b5c6d',
      field: 'name',
      sourceText: 'Vehicle inspection report',
      text: 'Informe de inspección del vehículo',
      status: 'DRAFT',
      origin: 'AUTHORED',
    ),
    ManualTranslationUnit(
      entityType: 'ISSUE_FIELD',
      entityId: 'b5c6d7e8-f9a0-4b1c-9d2e-3f4a5b6c7d8e',
      field: 'label',
      sourceText: 'Measured tread depth',
      text: null,
    ),
  ],
);

Future<void> _loadRealFonts() async {
  final fontDir = Directory('../../packages/design_system/assets/fonts');
  if (fontDir.existsSync()) {
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

    const materialPath =
        'build/unit_test_assets/fonts/MaterialIcons-Regular.otf';
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
    final dir = Directory('test/screenshots/manual_translations');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    File('${dir.path}/$filename').writeAsBytesSync(bytes, flush: true);
  });
}
