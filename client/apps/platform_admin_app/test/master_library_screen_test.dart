import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/components/platform_category_picker.dart';
import 'package:platform_admin_app/src/features/master_library/master_library_screen.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';

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
  sensorTool: 'Vernier',
  standardSpecEn: 'Above 3.0 mm',
  standardSpecAr: 'أعلى من 3.0 مم',
  safetyCritical: true,
  multiPoint: true,
  maxTyreAgeYears: null,
  allowFreeTextNote: false,
  sortOrder: 1,
  guideImageId: '',
);

const _healthy = ConfigHealth(healthy: true, checks: []);

const _unhealthy = ConfigHealth(
  healthy: false,
  checks: [
    HealthCheck(
      code: 'TRANSLATIONS',
      severity: 'ERROR',
      messageEn: 'Missing Arabic labels.',
      messageAr: 'تسميات عربية مفقودة.',
      affected: 2,
      references: ['BRK-PAD-01'],
    ),
  ],
);

Widget _app({
  Locale locale = const Locale('en'),
  double width = 1280,
  ConfigHealth health = _healthy,
}) {
  return ProviderScope(
    overrides: [
      categoriesProvider.overrideWith((ref) async => const [_category]),
      itemsProvider.overrideWith((ref, query) async => const [_item]),
      configHealthProvider.overrideWith((ref) async => health),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 900)),
        child: const MasterLibraryScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('renders checklist items tab with tab bar from API providers', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Brake Pad Thickness'), findsWidgets);
    expect(find.textContaining('BRK-PAD-01'), findsWidgets);

    // Checklist tab bar: Items is the default landing tab.
    expect(find.byKey(const Key('checklist-tab-categories')), findsOneWidget);
    expect(find.byKey(const Key('checklist-tab-items')), findsOneWidget);
    expect(find.byKey(const Key('checklist-tab-templates')), findsOneWidget);
    expect(
      find.byKey(const Key('checklist-tab-issue-options')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('checklist-tab-health')), findsOneWidget);

    // Healthy checklist shows no health banner.
    expect(find.text('Review health'), findsNothing);
  });

  testWidgets('shows health banner with review action when unhealthy', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(_app(health: _unhealthy));
    await tester.pumpAndSettle();

    expect(find.text('Brake Pad Thickness'), findsWidgets);
    expect(find.text('Issues found'), findsOneWidget);
    expect(find.text('Review health'), findsOneWidget);
  });

  testWidgets('uses picker filter with result count and no seed action', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Seed action moved to Settings → Developer; never on the items tab.
    expect(find.text('Load default checklist'), findsNothing);
    // Scalable category filter (never a wall of chips) + result count.
    expect(find.byType(PlatformCategoryPicker), findsOneWidget);
    expect(find.text('All categories'), findsOneWidget);
    expect(find.text('1 items'), findsOneWidget);
    // Rich checklist rows: code, labels, unit, safety, status, updated.
    expect(find.textContaining('BRK-PAD-01'), findsWidgets);
    expect(find.text('MM'), findsOneWidget);
    expect(find.text('Safety critical'), findsWidgets);
  });

  testWidgets('renders on compact width without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    await tester.pumpWidget(_app(width: 400));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
