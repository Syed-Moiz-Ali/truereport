import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/features/audit/audit_log_screen.dart';
import 'package:platform_admin_app/src/features/catalogues/data_catalogues_screen.dart';
import 'package:platform_admin_app/src/features/documents/document_types_screen.dart';
import 'package:platform_admin_app/src/features/equipment/equipment_library_screen.dart';
import 'package:platform_admin_app/src/features/governance/config_health_screen.dart';
import 'package:platform_admin_app/src/features/languages/languages_screen.dart';
import 'package:platform_admin_app/src/features/master_library/categories_screen.dart';
import 'package:platform_admin_app/src/features/master_library/master_item_editor_screen.dart';
import 'package:platform_admin_app/src/features/master_library/master_library_screen.dart';
import 'package:platform_admin_app/src/features/master_library/option_sets_screen.dart';
import 'package:platform_admin_app/src/features/scoring/scoring_screen.dart';
import 'package:platform_admin_app/src/features/templates/templates_screen.dart';
import 'package:platform_admin_app/src/platform_catalogue_models.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';

const _category = PlatformCategory(
  id: 'cat-1',
  code: 'CAT-BRK',
  nameEn: 'Braking Systems & Tyres',
  nameAr: 'أنظمة الفرامل والإطارات',
  labelEn: 'Braking Systems & Tyres',
  labelAr: 'أنظمة الفرامل والإطارات',
  weightPercentage: 20,
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
);

const _scoringDetail = ScoringRuleDetail(
  rule: ScoringRule(
    id: 'rule-1',
    code: 'SCORE-V1',
    nameEn: 'Default Scoring Rule',
    nameAr: 'قاعدة التقييم الافتراضية',
    active: true,
    categoryWeightMode: 'CONFIGURED',
    hardFailCapEnabled: true,
    hardFailCapGrade: 'A',
    pendingApproval: false,
    version: 1,
  ),
  gradeBoundaries: [
    GradeBoundary(
      gradeCode: 'A',
      minScore: 90,
      maxScore: 100,
      labelEn: 'Excellent',
      labelAr: 'ممتاز',
      sortOrder: 1,
      approved: true,
    ),
  ],
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
  nameEn: 'English',
  nameAr: 'الإنجليزية',
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
      code: 'WEIGHTS',
      severity: 'OK',
      messageEn: 'Category weights total 100%.',
      messageAr: 'أوزان الفئات تساوي 100٪.',
      affected: 0,
      references: ['CAT-BRK'],
    ),
  ],
);

const _catalogueEntry = PlatformCatalogueEntry(
  id: 'catalogue-1',
  code: 'REASON-WEAR',
  status: 'ACTIVE',
  sortOrder: 1,
  labelEn: 'Normal Wear and Tear',
  labelAr: 'تآكل طبيعي',
  values: [
    PlatformCatalogueValue(
      id: 'catalogue-value-1',
      code: 'WEAR',
      status: 'ACTIVE',
      sortOrder: 1,
      labelEn: 'Wear',
      labelAr: 'تآكل',
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

const _weightCheck = CategoryWeightCheck(
  valid: true,
  total: 100,
  expected: 100,
  categories: [],
);

List<Override> _overrides() => [
  categoriesProvider.overrideWith((ref) async => const [_category]),
  categoryWeightCheckProvider.overrideWith((ref) async => _weightCheck),
  itemsProvider.overrideWith((ref, query) async => const [_item]),
  optionSetsProvider.overrideWith((ref) async => const [_optionSet]),
  templatesProvider.overrideWith((ref) async => const [_template]),
  scoringRuleProvider.overrideWith((ref) async => _scoringDetail),
  documentTypesProvider.overrideWith((ref) async => const [_documentType]),
  platformLanguagesProvider.overrideWith((ref) async => const [_language]),
  translationCoverageProvider.overrideWith((ref) async => _coverage),
  configHealthProvider.overrideWith((ref) async => _configHealth),
  reasonsProvider.overrideWith((ref) async => const [_catalogueEntry]),
  dropdownsProvider.overrideWith((ref) async => const [_catalogueEntry]),
  equipmentProvider.overrideWith((ref) async => const [_catalogueEntry]),
  auditEventsProvider.overrideWith((ref) async => const [_auditEvent]),
];

Widget _app(Widget screen, Locale locale, Size size) {
  return ProviderScope(
    overrides: _overrides(),
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: screen,
      ),
    ),
  );
}

final _screens = <String, Widget>{
  'MasterLibraryScreen': const MasterLibraryScreen(),
  'MasterItemEditorScreen': const MasterItemEditorScreen(),
  'CategoriesScreen': const CategoriesScreen(),
  'OptionSetsScreen': const OptionSetsScreen(),
  'TemplatesScreen': const TemplatesScreen(),
  'ScoringScreen': const ScoringScreen(),
  'DocumentTypesScreen': const DocumentTypesScreen(),
  'LanguagesScreen': const LanguagesScreen(),
  'ConfigHealthScreen': const ConfigHealthScreen(),
  'DataCataloguesScreen': const DataCataloguesScreen(),
  'EquipmentLibraryScreen': const EquipmentLibraryScreen(),
  'AuditLogScreen': const AuditLogScreen(),
};

const _sizes = <Size>[
  Size(360, 900),
  Size(600, 900),
  Size(768, 1024),
  Size(1024, 768),
  Size(1440, 900),
];

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget screen,
  Size size,
  Locale locale,
) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_app(screen, locale, size));
  await tester.pumpAndSettle();
}

void main() {
  for (final entry in _screens.entries) {
    for (final size in _sizes) {
      testWidgets(
        '${entry.key} has no overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await _pumpScreen(tester, entry.value, size, const Locale('en'));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final entry in _screens.entries) {
    for (final size in const [Size(360, 900), Size(1440, 900)]) {
      testWidgets(
        '${entry.key} has no overflow in Arabic at ${size.width.toInt()}',
        (tester) async {
          await _pumpScreen(tester, entry.value, size, const Locale('ar'));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
