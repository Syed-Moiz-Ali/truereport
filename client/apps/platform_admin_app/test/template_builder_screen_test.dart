import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/features/templates/template_builder_screen.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';

const _itemOne = TemplateItem(
  id: 'ti-1',
  itemId: 'item-1',
  itemVersionId: 'version-item-1',
  itemCode: 'BRK-PAD-01',
  labelEn: 'Brake Pad Thickness',
  labelAr: 'سمك أقمشة الفرامل',
  categoryId: 'cat-1',
  categoryCode: 'CAT-BRK',
  categoryNameEn: 'Braking Systems & Tyres',
  categoryNameAr: 'أنظمة الفرامل والإطارات',
  sortOrder: 1,
  included: true,
  itemStatus: 'PUBLISHED',
);

const _itemTwo = TemplateItem(
  id: 'ti-2',
  itemId: 'item-2',
  itemVersionId: 'version-item-2',
  itemCode: 'BRK-ROT-01',
  labelEn: 'Brake Rotors',
  labelAr: 'أقراص الفرامل',
  categoryId: 'cat-1',
  categoryCode: 'CAT-BRK',
  categoryNameEn: 'Braking Systems & Tyres',
  categoryNameAr: 'أنظمة الفرامل والإطارات',
  sortOrder: 2,
  included: true,
  itemStatus: 'PUBLISHED',
);

const _category = TemplateCategory(
  categoryId: 'cat-1',
  categoryCode: 'CAT-BRK',
  nameEn: 'Braking Systems & Tyres',
  nameAr: 'أنظمة الفرامل والإطارات',
  sortOrder: 1,
  itemCount: 2,
  includedCount: 2,
  included: true,
  items: [_itemOne, _itemTwo],
);

const _otherCategory = PlatformCategory(
  id: 'cat-2',
  code: 'CAT-ENG',
  nameEn: 'Powertrain & Mechanical',
  nameAr: 'مجموعة الحركة والميكانيكا',
  labelEn: 'Powertrain & Mechanical',
  labelAr: 'مجموعة الحركة والميكانيكا',
  status: 'ACTIVE',
  sortOrder: 2,
  active: true,
  itemCount: 3,
);

const _template = GlobalTemplate(
  id: 'template-1',
  code: 'TPL-BRK',
  nameEn: 'Braking Template',
  nameAr: 'قالب الفرامل',
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
      status: 'DRAFT',
      publishedAt: '',
    ),
  ],
  categories: [_category],
);

const _versionDetail = TemplateVersionDetail(
  id: 'version-1',
  templateId: 'template-1',
  versionNo: 1,
  status: 'DRAFT',
  categoryCount: 1,
  itemCount: 2,
  categories: [_category],
);

Widget _app({Locale locale = const Locale('en')}) {
  return ProviderScope(
    overrides: [
      templateDetailProvider.overrideWith((ref, id) async => _template),
      templateVersionDetailProvider.overrideWith(
        (ref, key) async => _versionDetail,
      ),
      categoriesProvider.overrideWith((ref) async => [_otherCategory]),
      itemsProvider.overrideWith((ref, query) async => const <PlatformItem>[]),
      platformLanguagesProvider.overrideWith(
        (ref) async => const <PlatformLanguage>[],
      ),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const TemplateBuilderScreen(templateId: 'template-1'),
    ),
  );
}

Future<void> _goToStep(WidgetTester tester, int step) async {
  for (var i = 0; i < step; i++) {
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('renders categories with nested items and no scoring UI', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Details step shows the template names (summary + prefilled fields).
    expect(find.text('Braking Template'), findsWidgets);

    await _goToStep(tester, 1);
    expect(find.text('Braking Systems & Tyres'), findsOneWidget);

    await _goToStep(tester, 1);
    expect(find.text('Braking Systems & Tyres'), findsOneWidget);
    expect(find.text('BRK-PAD-01'), findsOneWidget);
    expect(find.text('BRK-ROT-01'), findsOneWidget);
    expect(find.textContaining('Score'), findsNothing);
    expect(find.textContaining('Weight'), findsNothing);
    expect(find.byType(Checkbox), findsNWidgets(2));
  });

  testWidgets('adds and removes categories via the searchable picker', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await _goToStep(tester, 1);

    // Searchable picker (never a chip wall): open it, then pick a category.
    await tester.tap(find.text('All categories'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Powertrain & Mechanical'));
    await tester.pumpAndSettle();
    expect(find.textContaining('CAT-ENG'), findsOneWidget);

    // Remove the added category via its row delete action.
    await tester.tap(find.byIcon(Icons.delete_outline_rounded).last);
    await tester.pumpAndSettle();
    expect(find.textContaining('CAT-ENG'), findsNothing);
  });

  testWidgets('renders grouped template on compact RTL layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(locale: const Locale('ar')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
