import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/features/audit/audit_log_screen.dart';
import 'package:platform_admin_app/src/features/dashboard/dashboard_screen.dart';
import 'package:platform_admin_app/src/features/documents/document_types_screen.dart';
import 'package:platform_admin_app/src/features/governance/config_health_screen.dart';
import 'package:platform_admin_app/src/features/languages/languages_screen.dart';
import 'package:platform_admin_app/src/features/languages/translation_queue_screen.dart';
import 'package:platform_admin_app/src/features/master_library/categories_screen.dart';
import 'package:platform_admin_app/src/features/master_library/master_library_screen.dart';
import 'package:platform_admin_app/src/features/master_library/option_sets_screen.dart';
import 'package:platform_admin_app/src/features/settings/platform_settings_screen.dart';
import 'package:platform_admin_app/src/features/templates/template_builder_screen.dart';
import 'package:platform_admin_app/src/features/templates/templates_screen.dart';
import 'package:platform_admin_app/src/features/workshops/workshop_detail_screen.dart';
import 'package:platform_admin_app/src/features/workshops/workshops_screen.dart';
import 'package:platform_admin_app/src/platform_catalogue_models.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/platform_translations.dart'
    as translations
    hide TranslationCoverage;

import 'support/fake_platform_api.dart';
import 'support/ui_message_fixtures.dart';

// Visual evidence: captures every Platform Admin screen at 1280, 1440,
// 768, 360 and Arabic RTL. Run with `flutter test` — PNGs land in
// test/screenshots/ and are committed as review evidence.

const _category = PlatformCategory(
  id: 'cat-1',
  code: 'CAT-BRK',
  nameEn: 'Braking Systems & Tyres',
  nameAr: 'أنظمة الفرامل والإطارات',
  labelEn: 'Braking Systems & Tyres',
  labelAr: 'أنظمة الفرامل والإطارات',
  status: 'ACTIVE',
  sortOrder: 1,
  active: true,
  itemCount: 5,
);

const _item = PlatformItem(
  id: 'item-1',
  code: 'BRK-PAD-01',
  categoryId: 'cat-1',
  categoryLabelEn: 'Braking Systems & Tyres',
  categoryLabelAr: 'أنظمة الفرامل والإطارات',
  status: 'PUBLISHED',
  currentVersion: 1,
  labelEn: 'Brake Pad Thickness',
  labelAr: 'سمك أقمشة الفرامل',
  sampleData: false,
  updatedAt: '',
  measurementUnit: 'MM',
  sensorTool: 'Vernier Caliper',
  standardSpecEn: 'Above 3.0 mm',
  standardSpecAr: 'أعلى من 3.0 مم',
  safetyCritical: true,
  multiPoint: true,
  maxTyreAgeYears: null,
  allowFreeTextNote: false,
  sortOrder: 1,
  guideImageId: '',
);

const _optionSet = OptionSet(
  id: 'set-1',
  code: 'CONDITION',
  nameEn: 'Overall Condition',
  nameAr: 'الحالة العامة',
  status: 'ACTIVE',
  sortOrder: 1,
  values: [
    OptionValue(
      id: 'value-1',
      code: 'GOOD',
      labelEn: 'Good',
      labelAr: 'جيد',
      status: 'ACTIVE',
      sortOrder: 1,
      metadataJson: '{}',
    ),
  ],
);

const _templateCategory = TemplateCategory(
  categoryId: 'cat-1',
  categoryCode: 'CAT-BRK',
  nameEn: 'Braking Systems & Tyres',
  nameAr: 'أنظمة الفرامل والإطارات',
  sortOrder: 1,
  itemCount: 1,
  includedCount: 1,
  included: true,
  items: [
    TemplateItem(
      id: 'ti-1',
      itemId: 'item-1',
      itemVersionId: 'v-1',
      itemCode: 'BRK-PAD-01',
      labelEn: 'Brake Pad Thickness',
      labelAr: 'سمك أقمشة الفرامل',
      categoryId: 'cat-1',
      categoryCode: 'CAT-BRK',
      categoryNameEn: 'Braking',
      categoryNameAr: 'الفرامل',
      sortOrder: 1,
      included: true,
      itemStatus: 'PUBLISHED',
    ),
  ],
);

const _template = GlobalTemplate(
  id: 'template-1',
  code: 'TPL-BRK',
  nameEn: 'Braking Inspection Template',
  nameAr: 'قالب فحص الفرامل',
  descriptionEn: 'Braking inspection',
  descriptionAr: 'فحص الفرامل',
  status: 'PUBLISHED',
  currentPublishedVersionId: 'version-1',
  versionCount: 1,
  currentVersionNo: 1,
  versions: [
    TemplateVersionSummary(
      id: 'version-1',
      versionNo: 1,
      status: 'PUBLISHED',
      publishedAt: '2026-01-01',
    ),
  ],
  categories: [_templateCategory],
);

const _versionDetail = TemplateVersionDetail(
  id: 'version-1',
  templateId: 'template-1',
  versionNo: 1,
  status: 'PUBLISHED',
  categoryCount: 1,
  itemCount: 1,
  categories: [_templateCategory],
);

const _documentType = ReportDocumentType(
  id: 'doc-1',
  code: 'DOC-PHOTO',
  nameEn: 'Photo Evidence',
  nameAr: 'دليل مصور',
  status: 'ACTIVE',
  required: true,
  sortOrder: 1,
);

const _language = PlatformLanguage(
  code: 'en',
  nativeName: 'English',
  direction: 'LTR',
  active: true,
  isDefault: true,
  sortOrder: 1,
);

const _coverage = TranslationCoverage(
  languages: ['en', 'ar'],
  namespaces: {
    'common': CoverageNamespace(total: 12, missing: ['missing.key']),
  },
);

const _configHealth = ConfigHealth(
  healthy: true,
  checks: [
    HealthCheck(
      code: 'TRANSLATIONS',
      severity: 'OK',
      messageEn: 'Translations complete.',
      messageAr: 'الترجمات مكتملة.',
      affected: 0,
      references: ['CAT-BRK'],
    ),
  ],
);

const _auditEvent = PlatformAuditEvent(
  id: 'audit-1',
  action: 'PUBLISH_ITEM',
  entityType: 'ITEM',
  entityId: 'item-1',
  actorRole: 'PRINCIPAL_ADMIN',
  occurredAt: '2026-01-01T10:00:00Z',
  reasonCode: 'REASON-WEAR',
  metadataJson: '{"version":1}',
);

class _MockLocaleController extends LocaleController {
  _MockLocaleController(this._initial);
  final Locale _initial;

  @override
  Locale build() => _initial;
}

Widget _screenshotApp({
  required Widget child,
  required GlobalKey boundaryKey,
  Locale locale = const Locale('en'),
  Size surfaceSize = const Size(1280, 900),
  List<Override> extraOverrides = const [],
  List<PlatformLanguage> languages = const [_language],
}) {
  return ProviderScope(
    overrides: [
      uiStringsProvider.overrideWithValue(
        locale.languageCode == 'ar' ? fakeArUiStrings() : fakeEnUiStrings(),
      ),
      platformLocaleProvider.overrideWith(() => _MockLocaleController(locale)),
      categoriesProvider.overrideWith((ref) async => const [_category]),
      itemsProvider.overrideWith((ref, query) async => const [_item]),
      optionSetsProvider.overrideWith((ref) async => const [_optionSet]),
      templatesProvider.overrideWith((ref) async => const [_template]),
      templateDetailProvider.overrideWith((ref, id) async => _template),
      templateVersionDetailProvider.overrideWith(
        (ref, key) async => _versionDetail,
      ),
      documentTypesProvider.overrideWith((ref) async => const [_documentType]),
      platformLanguagesProvider.overrideWith((ref) async => languages),
      translationCoverageProvider.overrideWith((ref) async => _coverage),
      configHealthProvider.overrideWith((ref) async => _configHealth),
      configReleasesProvider.overrideWith(
        (ref) async => const <ConfigRelease>[],
      ),
      auditEventsProvider.overrideWith((ref) async => const [_auditEvent]),
      platformApiProvider.overrideWithValue(FakePlatformAdminApi()),
      auditEventsPageProvider.overrideWith(
        (ref, query) async => const AuditEventPage(
          items: [_auditEvent],
          total: 1,
          page: 0,
          size: 25,
        ),
      ),
      ...extraOverrides,
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: <Locale>[const Locale('en'), const Locale('ar')],
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        key: boundaryKey,
        child: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: child,
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
    expect(byteData, isNotNull);
    final bytes = byteData!.buffer.asUint8List();
    final dir = Directory('test/screenshots');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    File('${dir.path}/$filename').writeAsBytesSync(bytes);
  });
}

Future<void> _shoot(
  WidgetTester tester,
  GlobalKey key,
  Widget screen,
  String name, {
  List<Override> extraOverrides = const [],
  List<PlatformLanguage> languages = const [_language],
}) async {
  final viewports = <String, Size>{
    '1280': const Size(1280, 900),
    '1440': const Size(1440, 900),
    '768': const Size(768, 1024),
    '360': const Size(360, 800),
  };
  for (final entry in viewports.entries) {
    await tester.binding.setSurfaceSize(entry.value);
    await tester.pumpWidget(
      _screenshotApp(
        boundaryKey: key,
        surfaceSize: entry.value,
        child: screen,
        extraOverrides: extraOverrides,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: '$name@${entry.key}');
    await _capture(tester, key, '${name}_${entry.key}.png');
  }
  for (final entry in {
    'ar_1280': const Size(1280, 900),
    'ar_360': const Size(360, 800),
  }.entries) {
    await tester.binding.setSurfaceSize(entry.value);
    await tester.pumpWidget(
      _screenshotApp(
        boundaryKey: key,
        locale: const Locale('ar'),
        surfaceSize: entry.value,
        child: screen,
        extraOverrides: extraOverrides,
        languages: languages,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: '$name@${entry.key}');
    await _capture(tester, key, '${name}_${entry.key}.png');
  }
  await tester.binding.setSurfaceSize(null);
}

void main() {
  testWidgets('Screenshots: workshops + checklist tabs', (tester) async {
    final key = GlobalKey();
    await _shoot(tester, key, const MasterLibraryScreen(), 'checklist_items');
    await _shoot(tester, key, const CategoriesScreen(), 'checklist_categories');
    await _shoot(tester, key, const OptionSetsScreen(), 'checklist_options');
  });

  testWidgets('Screenshots: templates + builder + health', (tester) async {
    final key = GlobalKey();
    await _shoot(tester, key, const TemplatesScreen(), 'checklist_templates');
    await _shoot(
      tester,
      key,
      const TemplateBuilderScreen(templateId: 'template-1'),
      'checklist_builder',
    );
    await _shoot(tester, key, const ConfigHealthScreen(), 'checklist_health');
  });

  testWidgets('Screenshots: reports + settings + audit', (tester) async {
    final key = GlobalKey();
    await _shoot(tester, key, const DocumentTypesScreen(), 'reports_documents');
    await _shoot(tester, key, const PlatformSettingsScreen(), 'settings');
    await _shoot(tester, key, const LanguagesScreen(), 'settings_languages');
    await _shoot(tester, key, const AuditLogScreen(), 'audit');
  });

  testWidgets('Screenshots: dashboard', (tester) async {
    final key = GlobalKey();
    const overview = OverviewSummary(
      workshops: OverviewWorkshops(total: 3, active: 2),
      staff: OverviewStaff(technicians: 14, admins: 3),
      jobs: OverviewJobs(
        active: 9,
        pendingReview: 2,
        byStatus: {'ASSIGNED': 4, 'IN_PROGRESS': 3, 'PENDING_REVIEW': 2},
      ),
      reports: OverviewReports(published: 21, byMonth: {'Nov': 9, 'Oct': 12}),
      checklist: OverviewChecklist(
        categories: 6,
        items: 30,
        templates: 2,
        healthy: true,
        issues: 0,
      ),
      languages: OverviewLanguages(live: 2, translating: 0),
      recentActivity: [
        OverviewActivityEntry(
          id: 'a1',
          action: 'PUBLISH_ITEM',
          entityType: 'ITEM',
          entityId: 'item-1',
          actor: 'admin@truereport.test',
          occurredAt: '2026-01-01T10:00:00Z',
        ),
      ],
      alerts: [],
    );
    await _shoot(
      tester,
      key,
      const DashboardScreen(),
      'dashboard',
      extraOverrides: [overviewProvider.overrideWith((ref) async => overview)],
    );
  });

  testWidgets('Screenshots: workshops', (tester) async {
    final key = GlobalKey();
    await _shoot(tester, key, const WorkshopsScreen(), 'workshops');
  });

  testWidgets('Screenshots: workshop detail', (tester) async {
    final key = GlobalKey();
    await _shoot(
      tester,
      key,
      const WorkshopDetailScreen(workshopId: 'workshop-1'),
      'workshop_detail',
    );
  });

  testWidgets('Screenshots: translation queue + zh-Hans fixture', (
    tester,
  ) async {
    final key = GlobalKey();
    const zhBacklog = translations.TranslationBacklog(
      languageCode: 'zh-hans',
      languageStatus: 'TRANSLATING',
      totalRequired: 3,
      approvedCount: 1,
      coveragePercent: 33.3,
      groups: [
        translations.TranslationBacklogGroup(
          entityType: 'CATEGORY',
          total: 1,
          approved: 1,
          items: [
            translations.TranslationItem(
              entityType: 'CATEGORY',
              entityId: 'cat-1',
              entityCode: 'CAT-BRK',
              field: 'name',
              defaultText: 'Braking Systems & Tyres',
              text: '???????',
              status: 'APPROVED',
            ),
          ],
        ),
        translations.TranslationBacklogGroup(
          entityType: 'ITEM',
          total: 2,
          approved: 0,
          items: [
            translations.TranslationItem(
              entityType: 'ITEM',
              entityId: 'v-1',
              entityCode: 'BRK-PAD-01',
              field: 'label',
              defaultText: 'Brake Pad Thickness',
              text: '?????',
              status: 'DRAFT',
            ),
            translations.TranslationItem(
              entityType: 'ITEM',
              entityId: 'v-1',
              entityCode: 'BRK-PAD-01',
              field: 'instruction',
              defaultText: 'Measure with a digital caliper.',
              text: null,
              status: 'MISSING',
            ),
          ],
        ),
      ],
    );
    const zhLanguage = PlatformLanguage(
      code: 'zh-hans',
      nativeName: '??',
      direction: 'ltr',
      active: false,
      isDefault: false,
      sortOrder: 3,
      status: 'TRANSLATING',
    );
    await _shoot(
      tester,
      key,
      const TranslationQueueScreen(languageCode: 'zh-hans'),
      'queue_zh',
      extraOverrides: [
        translations.languageBacklogProvider.overrideWith(
          (ref, code) async => zhBacklog,
        ),
      ],
      languages: const [_language, zhLanguage],
    );
  });
}
