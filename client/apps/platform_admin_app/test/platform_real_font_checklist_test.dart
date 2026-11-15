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
import 'package:platform_admin_app/src/features/governance/config_health_screen.dart';
import 'package:platform_admin_app/src/features/master_library/categories_screen.dart';
import 'package:platform_admin_app/src/features/master_library/master_item_editor_screen.dart';
import 'package:platform_admin_app/src/features/master_library/master_library_screen.dart';
import 'package:platform_admin_app/src/features/master_library/option_sets_screen.dart';
import 'package:platform_admin_app/src/features/templates/template_builder_screen.dart';
import 'package:platform_admin_app/src/features/templates/templates_screen.dart';
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

const _expectedChecklistRealScreenshots = <String>[
  'checklist_items_1440.png',
  'checklist_items_1280.png',
  'checklist_items_768.png',
  'checklist_items_360.png',
  'checklist_items_ar_1280.png',
  'checklist_item_editor_1440.png',
  'checklist_item_editor_1280.png',
  'checklist_item_editor_768.png',
  'checklist_item_editor_360.png',
  'checklist_item_editor_validation_1280.png',
  'checklist_item_editor_review_1280.png',
  'checklist_categories_1280.png',
  'checklist_categories_768.png',
  'checklist_categories_360.png',
  'checklist_categories_ar_1280.png',
  'checklist_options_1280.png',
  'checklist_options_768.png',
  'checklist_options_360.png',
  'checklist_options_ar_1280.png',
  'checklist_templates_1280.png',
  'checklist_templates_768.png',
  'checklist_templates_360.png',
  'checklist_templates_ar_1280.png',
  'checklist_builder_1440.png',
  'checklist_builder_1280.png',
  'checklist_builder_768.png',
  'checklist_builder_360.png',
  'checklist_builder_ar_1280.png',
  'checklist_builder_publish_blocked_1280.png',
  'checklist_health_1280.png',
  'checklist_health_768.png',
  'checklist_health_360.png',
  'checklist_health_ar_1280.png',
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

const _category = PlatformCategory(
  id: 'cat-1',
  code: 'CAT-BRK',
  name: 'Braking Systems & Tyres',
  nameEn: 'Braking Systems & Tyres',
  nameAr: 'أنظمة الفرامل والإطارات',
  labelEn: 'Braking Systems & Tyres',
  labelAr: 'أنظمة الفرامل والإطارات',
  status: 'ACTIVE',
  sortOrder: 1,
  active: true,
  itemCount: 4,
);

const _item = PlatformItem(
  id: 'item-1',
  code: 'BRK-PAD-01',
  categoryId: 'cat-1',
  categoryLabelEn: 'Braking Systems & Tyres',
  categoryLabelAr: 'أنظمة الفرامل والإطارات',
  status: 'PUBLISHED',
  currentVersion: 1,
  label: 'Brake Pad Thickness',
  labelEn: 'Brake Pad Thickness',
  labelAr: 'سمك أقمشة الفرامل',
  safetyCritical: true,
  multiPoint: false,
  measurementUnit: 'mm',
  sensorTool: 'Digital Caliper',
  maxTyreAgeYears: null,
  allowFreeTextNote: false,
  sortOrder: 1,
  guideImageId: '',
  sampleData: false,
  updatedAt: '2026-11-10T08:00:00Z',
);

const _itemDraft = PlatformItem(
  id: 'item-2',
  code: 'BRK-ROTOR-02',
  categoryId: 'cat-1',
  categoryLabelEn: 'Braking Systems & Tyres',
  categoryLabelAr: 'أنظمة الفرامل والإطارات',
  status: 'DRAFT',
  currentVersion: 1,
  label: 'Brake Rotor Runout',
  labelEn: 'Brake Rotor Runout',
  labelAr: 'انحراف قرص الفرامل',
  safetyCritical: false,
  multiPoint: true,
  measurementUnit: 'mm',
  sensorTool: 'Dial Gauge',
  maxTyreAgeYears: null,
  allowFreeTextNote: false,
  sortOrder: 2,
  guideImageId: '',
  sampleData: false,
  updatedAt: '2026-11-12T10:00:00Z',
);

const _itemVersionDraft = PlatformItemVersion(
  id: 'ver-draft',
  versionNo: 2,
  status: 'DRAFT',
  label: 'Brake Pad Thickness v2',
  instruction: 'Measure remaining friction material.',
  resultOptions: ['NO_ISSUE_OBSERVED', 'ATTENTION_RECOMMENDED', 'DEFECT_FOUND'],
  noteRequirement: 'OPTIONAL',
  evidenceRequirement: 'REQUIRED_MIN_N',
  minPhotos: 2,
  publishedAt: '2026-11-12T10:00:00Z',
);

const _itemDetail = PlatformItemDetail(
  item: _item,
  versions: [_itemVersionDraft],
);

const _itemConfig = ItemConfig(
  metadata: ItemMetadata(
    itemId: 'item-1',
    measurementUnit: 'mm',
    sensorTool: 'Digital Caliper',
    safetyCritical: true,
    multiPoint: false,
    maxTyreAgeYears: 5,
    allowFreeTextNote: true,
    sortOrder: 1,
    guideImageId: '',
  ),
  evidenceRules: [
    EvidenceRule(
      resultCode: 'DEFECT_FOUND',
      minPhotos: 2,
      minVideos: 1,
      minNotesChars: 10,
      requiredEvidenceType: 'PHOTO',
    ),
  ],
  issueFields: [
    IssueField(
      fieldCode: 'PAD_POSITION',
      label: 'Pad Position',
      inputType: 'SELECT',
      optionSetCode: 'PAD_POSITIONS',
      unitSetCode: '',
      required: true,
      requiredForStatuses: ['DEFECT_FOUND'],
      minValue: null,
      maxValue: null,
      decimalPlaces: 0,
      dependsOnFieldCode: '',
      dependsOnValueCode: '',
      allowMultiple: false,
      allowFreeText: false,
      sortOrder: 1,
      allowedValues: ['FRONT_LEFT', 'FRONT_RIGHT'],
    ),
  ],
  measurementBands: [
    MeasurementBand(
      fieldCode: 'PAD_THICKNESS',
      unitCode: 'mm',
      direction: 'LOWER_IS_BETTER',
      minValue: 7.0,
      maxValue: 12.0,
      resultCode: 'NO_ISSUE_OBSERVED',
      sortOrder: 1,
      label: 'Normal Thickness',
      labelEn: 'Normal Thickness',
      labelAr: 'سمك طبيعي',
    ),
    MeasurementBand(
      fieldCode: 'PAD_THICKNESS',
      unitCode: 'mm',
      direction: 'LOWER_IS_BETTER',
      minValue: 0.0,
      maxValue: 3.0,
      resultCode: 'DEFECT_FOUND',
      sortOrder: 2,
      label: 'Critical Wear Limit',
      labelEn: 'Critical Wear Limit',
      labelAr: 'حد التآكل الحرج',
    ),
  ],
);

const _optionValues = [
  OptionValue(
    id: 'value-1',
    code: 'FRONT_LEFT',
    label: 'Front Left Outer',
    labelEn: 'Front Left Outer',
    labelAr: 'أمامي أيسر خارجي',
    status: 'ACTIVE',
    sortOrder: 1,
    metadataJson: '{}',
  ),
  OptionValue(
    id: 'value-2',
    code: 'FRONT_RIGHT',
    label: 'Front Right Outer',
    labelEn: 'Front Right Outer',
    labelAr: 'أمامي أيمن خارجي',
    status: 'ACTIVE',
    sortOrder: 2,
    metadataJson: '{}',
  ),
  OptionValue(
    id: 'value-3',
    code: 'REAR_AXLE_OBSOLETE',
    label: 'Rear Axle Obsolete Type',
    labelEn: 'Rear Axle Obsolete Type',
    labelAr: 'محور خلفي نوع قديم',
    status: 'RETIRED',
    sortOrder: 3,
    metadataJson: '{}',
  ),
];

const _optionSet = OptionSet(
  id: 'opt-set-1',
  code: 'PAD_POSITIONS',
  name: 'Brake Pad Mounting Positions',
  nameEn: 'Brake Pad Mounting Positions',
  nameAr: 'مواضع تثبيت أقمشة الفرامل',
  status: 'ACTIVE',
  sortOrder: 1,
  values: _optionValues,
);

const _templateCategory = TemplateCategory(
  categoryId: 'cat-1',
  categoryCode: 'CAT-BRK',
  name: 'Braking Systems & Tyres',
  nameEn: 'Braking Systems & Tyres',
  nameAr: 'أنظمة الفرامل والإطارات',
  sortOrder: 1,
  itemCount: 1,
  includedCount: 1,
  included: true,
  items: [
    TemplateItem(
      id: 'tpl-item-1',
      itemVersionId: 'ver-draft',
      itemId: 'item-1',
      itemCode: 'BRK-PAD-01',
      label: 'Brake Pad Thickness',
      labelEn: 'Brake Pad Thickness',
      labelAr: 'سمك أقمشة الفرامل',
      categoryId: 'cat-1',
      categoryCode: 'CAT-BRK',
      categoryNameEn: 'Braking Systems & Tyres',
      categoryNameAr: 'أنظمة الفرامل والإطارات',
      sortOrder: 1,
      included: true,
      itemStatus: 'PUBLISHED',
    ),
  ],
);

const _templateCategory2 = TemplateCategory(
  categoryId: 'cat-2',
  categoryCode: 'CAT-SUS',
  name: 'Suspension & Steering',
  nameEn: 'Suspension & Steering',
  nameAr: 'التعليق والتوجيه',
  sortOrder: 2,
  itemCount: 2,
  includedCount: 2,
  included: true,
  items: [
    TemplateItem(
      id: 'tpl-item-2',
      itemVersionId: 'ver-sus-1',
      itemId: 'item-2',
      itemCode: 'SUS-SHOCK-01',
      label: 'Shock Absorber Leakage',
      labelEn: 'Shock Absorber Leakage',
      labelAr: 'تسرب ممتص الصدمات',
      categoryId: 'cat-2',
      categoryCode: 'CAT-SUS',
      categoryNameEn: 'Suspension & Steering',
      categoryNameAr: 'التعليق والتوجيه',
      sortOrder: 1,
      included: true,
      itemStatus: 'PUBLISHED',
    ),
    TemplateItem(
      id: 'tpl-item-3',
      itemVersionId: 'ver-sus-2',
      itemId: 'item-3',
      itemCode: 'SUS-BOOT-02',
      label: 'CV Boot Condition',
      labelEn: 'CV Boot Condition',
      labelAr: 'حالة غطاء المفصل',
      categoryId: 'cat-2',
      categoryCode: 'CAT-SUS',
      categoryNameEn: 'Suspension & Steering',
      categoryNameAr: 'التعليق والتوجيه',
      sortOrder: 2,
      included: true,
      itemStatus: 'PUBLISHED',
    ),
  ],
);

const _template = GlobalTemplate(
  id: 'template-1',
  code: 'TPL-BRK-STANDARD',
  name: 'Standard Comprehensive Fleet Inspection',
  nameEn: 'Standard Comprehensive Fleet Inspection',
  nameAr: 'الفحص القياسي الشامل للأسطول',
  description: 'Full statutory vehicle roadworthiness checklist.',
  descriptionEn: 'Full statutory vehicle roadworthiness checklist.',
  descriptionAr: 'قائمة فحص شاملة لصلاحية المركبات للسير.',
  status: 'PUBLISHED',
  currentPublishedVersionId: 'version-1',
  versionCount: 2,
  currentVersionNo: 1,
  versions: [
    TemplateVersionSummary(
      id: 'version-1',
      versionNo: 1,
      status: 'PUBLISHED',
      publishedAt: '2026-01-15',
    ),
    TemplateVersionSummary(
      id: 'version-2',
      versionNo: 2,
      status: 'DRAFT',
      publishedAt: '',
    ),
  ],
  categories: [_templateCategory, _templateCategory2],
);

const _versionDetail = TemplateVersionDetail(
  id: 'version-2',
  templateId: 'template-1',
  versionNo: 2,
  status: 'DRAFT',
  categoryCount: 2,
  itemCount: 3,
  categories: [_templateCategory, _templateCategory2],
);

const _blockedVersionDetail = TemplateVersionDetail(
  id: 'version-2',
  templateId: 'template-1',
  versionNo: 3,
  status: 'DRAFT',
  categoryCount: 2,
  itemCount: 0,
  categories: [
    TemplateCategory(
      categoryId: 'cat-1',
      categoryCode: 'CAT-BRK',
      nameEn: 'Braking Systems & Tyres',
      nameAr: 'أنظمة الفرامل والإطارات',
      sortOrder: 1,
      itemCount: 0,
      includedCount: 0,
      included: true,
      items: [],
    ),
    TemplateCategory(
      categoryId: 'cat-2',
      categoryCode: 'CAT-SUS',
      nameEn: 'Suspension & Steering',
      nameAr: 'التعليق والتوجيه',
      sortOrder: 2,
      itemCount: 0,
      includedCount: 0,
      included: true,
      items: [],
    ),
  ],
);

const _configHealth = ConfigHealth(
  healthy: false,
  checks: [
    HealthCheck(
      code: 'TRANSLATIONS',
      severity: 'OK',
      messageEn:
          'English and Arabic content is complete across active catalogues.',
      messageAr: 'المحتوى الإنجليزي والعربي مكتمل في كافة الكتالوجات النشطة.',
      affected: 0,
      references: ['CAT-BRK', 'BRK-PAD-01'],
    ),
    HealthCheck(
      code: 'SAFETY_EVIDENCE',
      severity: 'WARNING',
      messageEn:
          '1 safety-critical item missing required fail photo evidence rule.',
      messageAr: 'عنصر حرج واحد يفتقد لقاعدة أدلة الصور عند الفشل.',
      affected: 1,
      references: ['BRK-PAD-01'],
    ),
    HealthCheck(
      code: 'MEASUREMENT_BANDS',
      severity: 'ERROR',
      messageEn: '2 item versions have overlapping or non-contiguous measurement bands.',
      messageAr: 'إصداران من العناصر لديهما نطاقات قياس متداخلة أو غير متصلة.',
      affected: 2,
      references: ['BRK-ROTOR-02', 'TYRE-TREAD-01'],
    ),
  ],
);

const _languages = [
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

Widget _harness({
  required Widget child,
  required GlobalKey boundaryKey,
  Locale locale = const Locale('en'),
  Size surfaceSize = const Size(1280, 900),
  PlatformItemDetail itemDetail = _itemDetail,
  ItemConfig itemConfig = _itemConfig,
  List<OptionSet> optionSets = const [_optionSet],
  TemplateVersionDetail templateVersionDetail = _versionDetail,
}) {
  final langCode = locale.languageCode;
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      uiStringsProvider.overrideWithValue(
        langCode == 'ar' ? fakeArUiStrings() : fakeEnUiStrings(),
      ),
      uiMessageControllerProvider.overrideWith(
        () => _TestUiMessageController(langCode),
      ),
      platformLocaleProvider.overrideWith(() => _MockLocaleController(locale)),
      platformLanguagesProvider.overrideWith((ref) async => _languages),
      categoriesProvider.overrideWith((ref) async => const [_category]),
      itemsProvider(const ItemQuery())
          .overrideWith((ref) async => const [_item, _itemDraft]),
      itemDetailProvider('item-1').overrideWith((ref) async => itemDetail),
      itemConfigProvider(const ItemVersionKey('item-1', 'ver-draft'))
          .overrideWith((ref) async => itemConfig),
      optionSetsProvider.overrideWith((ref) async => optionSets),
      templatesProvider.overrideWith((ref) async => const [_template]),
      templateDetailProvider('template-1')
          .overrideWith((ref) async => _template),
      availableTemplatesProvider.overrideWith((ref) async => const [_template]),
      templateVersionDetailProvider(
        const ItemVersionKey('template-1', 'version-1'),
      ).overrideWith((ref) async => _versionDetail),
      templateVersionDetailProvider(
        const ItemVersionKey('template-1', 'version-2'),
      ).overrideWith((ref) async => templateVersionDetail),
      configHealthProvider.overrideWith((ref) async => _configHealth),
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
            fontFamily: langCode == 'ar'
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
    expect(byteData, isNotNull);
    final bytes = byteData!.buffer.asUint8List();
    final dir = Directory(_realScreenshotDir);
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
  });
}

Future<void> _captureAcrossViewports(
  WidgetTester tester,
  GlobalKey key,
  Widget Function() builder,
  String prefix, {
  bool includeAr = true,
  PlatformItemDetail itemDetail = _itemDetail,
  List<OptionSet> optionSets = const [_optionSet],
}) async {
  final viewports = <String, Size>{
    '1440': const Size(1440, 900),
    '1280': const Size(1280, 900),
    '768': const Size(768, 1024),
    '360': const Size(360, 800),
  };

  for (final entry in viewports.entries) {
    await tester.binding.setSurfaceSize(entry.value);
    await tester.pumpWidget(
      _harness(
        boundaryKey: key,
        surfaceSize: entry.value,
        itemDetail: itemDetail,
        optionSets: optionSets,
        child: builder(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: '$prefix@${entry.key}');
    await _capture(tester, key, '${prefix}_${entry.key}.png');
  }

  if (includeAr) {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(
      _harness(
        boundaryKey: key,
        locale: const Locale('ar'),
        surfaceSize: const Size(1280, 900),
        itemDetail: itemDetail,
        optionSets: optionSets,
        child: builder(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: '$prefix@ar_1280');
    await _capture(tester, key, '${prefix}_ar_1280.png');
  }
}

void main() {
  setUpAll(() async {
    initializeDateFormatting('en', null);
    initializeDateFormatting('ar', null);
    await _loadRealFonts();
  });

  group('Checklist Real-Font Visual Proof', () {
    testWidgets(
      'captures real-font checklist items list across viewports & AR',
      (tester) async {
        final key = GlobalKey();
        await _captureAcrossViewports(
          tester,
          key,
          () => const MasterLibraryScreen(),
          'checklist_items',
        );
        tester.binding.setSurfaceSize(null);
      },
    );

    testWidgets(
      'captures real-font checklist categories across viewports & AR',
      (tester) async {
        final key = GlobalKey();
        for (final entry in {
          '1280': const Size(1280, 900),
          '768': const Size(768, 1024),
          '360': const Size(360, 800),
        }.entries) {
          await tester.binding.setSurfaceSize(entry.value);
          await tester.pumpWidget(
            _harness(
              boundaryKey: key,
              surfaceSize: entry.value,
              child: const CategoriesScreen(),
            ),
          );
          await tester.pumpAndSettle();
          await _capture(tester, key, 'checklist_categories_${entry.key}.png');
        }

        await tester.binding.setSurfaceSize(const Size(1280, 900));
        await tester.pumpWidget(
          _harness(
            boundaryKey: key,
            locale: const Locale('ar'),
            surfaceSize: const Size(1280, 900),
            child: const CategoriesScreen(),
          ),
        );
        await tester.pumpAndSettle();
        await _capture(tester, key, 'checklist_categories_ar_1280.png');

        tester.binding.setSurfaceSize(null);
      },
    );

    testWidgets(
      'captures real-font option sets & values across viewports & AR',
      (tester) async {
        final key = GlobalKey();
        for (final entry in {
          '1280': const Size(1280, 900),
          '768': const Size(768, 1024),
          '360': const Size(360, 800),
        }.entries) {
          await tester.binding.setSurfaceSize(entry.value);
          await tester.pumpWidget(
            _harness(
              boundaryKey: key,
              surfaceSize: entry.value,
              child: const OptionSetsScreen(),
            ),
          );
          await tester.pumpAndSettle();
          await _capture(tester, key, 'checklist_options_${entry.key}.png');
        }

        await tester.binding.setSurfaceSize(const Size(1280, 900));
        await tester.pumpWidget(
          _harness(
            boundaryKey: key,
            locale: const Locale('ar'),
            surfaceSize: const Size(1280, 900),
            child: const OptionSetsScreen(),
          ),
        );
        await tester.pumpAndSettle();
        await _capture(tester, key, 'checklist_options_ar_1280.png');

        tester.binding.setSurfaceSize(null);
      },
    );

    testWidgets('captures real-font templates list across viewports & AR', (
      tester,
    ) async {
      final key = GlobalKey();
      for (final entry in {
        '1280': const Size(1280, 900),
        '768': const Size(768, 1024),
        '360': const Size(360, 800),
      }.entries) {
        await tester.binding.setSurfaceSize(entry.value);
        await tester.pumpWidget(
          _harness(
            boundaryKey: key,
            surfaceSize: entry.value,
            child: const TemplatesScreen(),
          ),
        );
        await tester.pumpAndSettle();
        await _capture(tester, key, 'checklist_templates_${entry.key}.png');
      }

      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(
        _harness(
          boundaryKey: key,
          locale: const Locale('ar'),
          surfaceSize: const Size(1280, 900),
          child: const TemplatesScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'checklist_templates_ar_1280.png');

      tester.binding.setSurfaceSize(null);
    });

    testWidgets('captures real-font template builder across viewports & AR', (
      tester,
    ) async {
      final key = GlobalKey();
      final viewports = <String, Size>{
        '1440': const Size(1440, 900),
        '1280': const Size(1280, 900),
        '768': const Size(768, 1024),
        '360': const Size(360, 800),
      };

      for (final entry in viewports.entries) {
        await tester.binding.setSurfaceSize(entry.value);
        await tester.pumpWidget(
          _harness(
            boundaryKey: key,
            surfaceSize: entry.value,
            child: const TemplateBuilderScreen(templateId: 'template-1'),
          ),
        );
        await tester.pumpAndSettle();
        final itemsStep = find.text('3. Inspection items');
        if (entry.value.width < 500) {
          await tester.ensureVisible(itemsStep);
        }
        await tester.tap(itemsStep);
        await tester.pumpAndSettle();
        expect(find.textContaining('Step 3 of 4'), findsOneWidget);
        expect(find.text('Braking Systems & Tyres'), findsWidgets);
        expect(find.text('Suspension & Steering'), findsWidgets);
        expect(find.text('Brake Pad Thickness'), findsWidgets);
        expect(find.text('Shock Absorber Leakage'), findsWidgets);
        expect(find.text('Search items'), findsOneWidget);
        expect(find.text('Filter items in this category'), findsNWidgets(2));
        expect(find.textContaining('2 categories'), findsWidgets);
        expect(find.textContaining('3 items'), findsWidgets);
        expect(find.textContaining(' / '), findsNothing);
        await _capture(tester, key, 'checklist_builder_${entry.key}.png');
      }

      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(
        _harness(
          boundaryKey: key,
          locale: const Locale('ar'),
          surfaceSize: const Size(1280, 900),
          child: const TemplateBuilderScreen(templateId: 'template-1'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PlatformFilterChip).at(2));
      await tester.pumpAndSettle();
      await _capture(tester, key, 'checklist_builder_ar_1280.png');

      tester.binding.setSurfaceSize(null);
    });

    testWidgets('captures blocked template builder readiness', (tester) async {
      final key = GlobalKey();
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(
        _harness(
          boundaryKey: key,
          surfaceSize: const Size(1280, 900),
          templateVersionDetail: _blockedVersionDetail,
          child: const TemplateBuilderScreen(templateId: 'template-1'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Needs'), findsWidgets);
      await _capture(tester, key, 'checklist_builder_publish_blocked_1280.png');
      tester.binding.setSurfaceSize(null);
    });

    testWidgets('captures real-font config health across viewports & AR', (
      tester,
    ) async {
      final key = GlobalKey();
      for (final entry in {
        '1280': const Size(1280, 900),
        '768': const Size(768, 1024),
        '360': const Size(360, 800),
      }.entries) {
        await tester.binding.setSurfaceSize(entry.value);
        await tester.pumpWidget(
          _harness(
            boundaryKey: key,
            surfaceSize: entry.value,
            child: const ConfigHealthScreen(),
          ),
        );
        await tester.pumpAndSettle();
        await _capture(tester, key, 'checklist_health_${entry.key}.png');
      }

      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(
        _harness(
          boundaryKey: key,
          locale: const Locale('ar'),
          surfaceSize: const Size(1280, 900),
          child: const ConfigHealthScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'checklist_health_ar_1280.png');

      tester.binding.setSurfaceSize(null);
    });

    testWidgets(
      'captures real-font item editor across viewports, validation & review',
      (tester) async {
        final key = GlobalKey();
        final viewports = <String, Size>{
          '1440': const Size(1440, 900),
          '1280': const Size(1280, 900),
          '768': const Size(768, 1024),
          '360': const Size(360, 800),
        };

        for (final entry in viewports.entries) {
          await tester.binding.setSurfaceSize(entry.value);
          await tester.pumpWidget(
            _harness(
              boundaryKey: key,
              surfaceSize: entry.value,
              child: const MasterItemEditorScreen(itemId: 'item-1'),
            ),
          );
          await tester.pumpAndSettle();
          await _capture(tester, key, 'checklist_item_editor_${entry.key}.png');
        }

        // 2. Validation errors screenshot: create mode, click Next with empty code and category
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        await tester.pumpWidget(
          _harness(
            boundaryKey: key,
            surfaceSize: const Size(1280, 900),
            child: const MasterItemEditorScreen(), // create mode
          ),
        );
        await tester.pumpAndSettle();
        final nextButton = find.byKey(const Key('stepper-next'));
        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton.first);
          await tester.pumpAndSettle();
        }
        await _capture(
          tester,
          key,
          'checklist_item_editor_validation_1280.png',
        );

        // 3. Review step screenshot: item editor in edit mode at Review step.
        await tester.pumpWidget(
          _harness(
            boundaryKey: key,
            surfaceSize: const Size(1280, 900),
            child: const MasterItemEditorScreen(
              itemId: 'item-1',
              initialStep: 5,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Step 6 of 6'), findsOneWidget);
        expect(find.text('Measurement bands'), findsWidgets);
        expect(find.text('Evidence rules'), findsWidgets);
        await _capture(tester, key, 'checklist_item_editor_review_1280.png');

        final normalBytes = File(
          '$_realScreenshotDir/checklist_item_editor_1280.png',
        ).readAsBytesSync();
        final reviewBytes = File(
          '$_realScreenshotDir/checklist_item_editor_review_1280.png',
        ).readAsBytesSync();
        expect(reviewBytes, isNot(equals(normalBytes)));

        tester.binding.setSurfaceSize(null);
      },
    );

    test('real-font checklist screenshots exist and are not empty', () {
      expect(_materialIconsLoaded, isTrue);
      for (final filename in _expectedChecklistRealScreenshots) {
        final file = File('$_realScreenshotDir/$filename');
        expect(file.existsSync(), isTrue, reason: 'missing $filename');
        expect(file.lengthSync(), greaterThan(2000), reason: 'empty $filename');
      }
    });
  });
}
