import 'package:admin_app/src/admin_api.dart';
import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/pages/template_builder_page.dart';
import 'package:admin_app/src/pages/templates_tab.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

// F3-B Step 2, screen 7 — Template List.
//
// Covers the Figma 1280 restyle with existing data only: KPI = client-side
// ΣitemCount, status filter chips with counts, client-side search, grid/list
// toggle (both real), preserved create/edit navigation, and the locked-rule
// copy scan (no DOT/ISO/certification/semver/photo-gate/cycle/PPE/bay/export
// wording). No new endpoints or data are introduced.

class _TemplateFakeApi implements AdminApi {
  static const _templates = <TemplateSummary>[
    TemplateSummary(
      id: 't-1',
      name: 'Full inspection',
      serviceType: 'FULL',
      vehicleType: 'CAR',
      status: 'PUBLISHED',
      currentVersion: 2,
      itemCount: 110,
    ),
    TemplateSummary(
      id: 't-2',
      name: 'Quick oil service',
      serviceType: 'QUICK',
      vehicleType: 'CAR',
      status: 'DRAFT',
      currentVersion: 1,
      itemCount: 24,
    ),
    TemplateSummary(
      id: 't-3',
      name: 'Fleet check',
      serviceType: 'FULL',
      vehicleType: 'TRUCK',
      status: 'RETIRED',
      currentVersion: 3,
      itemCount: 45,
    ),
  ];

  @override
  Future<List<TemplateSummary>> templates() async => _templates;

  @override
  Future<TemplateDetail> createTemplate({
    required String name,
    String? description,
    required String serviceType,
    String? vehicleType,
  }) async {
    return TemplateDetail(
      id: 't-new',
      name: name,
      description: description,
      serviceType: serviceType,
      vehicleType: vehicleType,
      status: 'DRAFT',
      currentPublishedVersionId: null,
      versions: const [],
      draft: null,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _TemplateTestApp extends ConsumerStatefulWidget {
  const _TemplateTestApp({required this.locale});

  final Locale locale;

  @override
  ConsumerState<_TemplateTestApp> createState() => _TemplateTestAppState();
}

class _TemplateTestAppState extends ConsumerState<_TemplateTestApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localeProvider.notifier).setLocale(widget.locale);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildAppTheme(),
      home: const Scaffold(body: TemplatesTab()),
    );
  }
}

Future<void> _pumpTemplates(
  WidgetTester tester,
  Locale locale, {
  Size size = const Size(1280, 800),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminApiProvider.overrideWithValue(_TemplateFakeApi())],
      child: _TemplateTestApp(locale: locale),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('renders header, KPI sum, counted chips and grid cards (EN)',
      (tester) async {
    await _pumpTemplates(tester, const Locale('en'));

    // Figma header slot: neutral title + existing search + New Template.
    expect(find.text('Inspection templates'), findsOneWidget);
    expect(find.byKey(const Key('templates-search')), findsOneWidget);
    expect(
      find.widgetWithText(AppButton, 'New template'),
      findsOneWidget,
    );

    // KPI row: client-side ΣitemCount (110 + 24 + 45 = 179).
    expect(find.text('Total checkpoints'), findsOneWidget);
    expect(find.text('179'), findsOneWidget);
    expect(find.byType(WorkshopMetric), findsOneWidget);

    // Filter chips from the real statuses with client-side counts.
    expect(find.text('All (3)'), findsOneWidget);
    expect(find.text('Published (1)'), findsOneWidget);
    expect(find.text('Draft (1)'), findsOneWidget);
    expect(find.text('Retired (1)'), findsOneWidget);

    // Grid/list toggle defaults to the Figma grid.
    expect(find.text('Grid'), findsOneWidget);
    expect(find.text('List'), findsOneWidget);
    expect(find.byType(WorkshopTemplateCard), findsNWidgets(3));

    // Cards: name · integer version · item count · status chip ·
    // serviceType tag. No descriptions, photo gates, cycle/PPE, bays.
    expect(find.text('v2 · 110 items selected'), findsOneWidget);
    expect(find.text('v1 · 24 items selected'), findsOneWidget);
    expect(find.text('v3 · 45 items selected'), findsOneWidget);
    expect(find.text('Published'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.text('Retired'), findsOneWidget);
    expect(find.text('FULL'), findsNWidgets(2));
    expect(find.text('QUICK'), findsOneWidget);
    expect(
      find.widgetWithText(AppButton, 'Edit'),
      findsNWidgets(3),
    );

    // Dashed create tile + neutral footnote (validation lock without any
    // approval-gate copy; version audit routes to the existing pages).
    expect(find.text('Locked by platform'), findsOneWidget);
    expect(
      find.widgetWithText(AppButton, 'Version history'),
      findsOneWidget,
    );
  });

  testWidgets('locked-rule copy never renders (EN)', (tester) async {
    await _pumpTemplates(tester, const Locale('en'));

    for (final banned in [
      'DOT',
      'ISO',
      'certifi',
      'Certifi',
      'Master Inspector',
      'Master-Inspector',
      'Photo gate',
      'photo gate',
      'Cycle time',
      'Target Cycle',
      'PPE',
      'Export',
      'Bays Bound',
      'bay bound',
      'threshold',
      'Threshold',
      'trigger',
      'Trigger',
      'micrometer',
      'telematics',
      'BLE',
    ]) {
      expect(find.textContaining(banned), findsNothing, reason: banned);
    }
    // Integer versions only: no semver copy such as "v2.0".
    expect(find.textContaining(RegExp(r'v\d+\.\d+')), findsNothing);
  });

  testWidgets('status chips filter client-side, counts stay scoped',
      (tester) async {
    await _pumpTemplates(tester, const Locale('en'));

    await tester.tap(find.text('Published (1)'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Full inspection'), findsOneWidget);
    expect(find.text('Quick oil service'), findsNothing);
    expect(find.text('Fleet check'), findsNothing);
    // Counts stay derived from the search-scoped (status-unfiltered) list.
    expect(find.text('All (3)'), findsOneWidget);

    await tester.tap(find.text('Retired (1)'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Fleet check'), findsOneWidget);
    expect(find.text('Full inspection'), findsNothing);

    await tester.tap(find.text('All (3)'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(WorkshopTemplateCard), findsNWidgets(3));
  });

  testWidgets('search narrows the list and rescopes chip counts',
      (tester) async {
    await _pumpTemplates(tester, const Locale('en'));

    await tester.enterText(
      find.byKey(const Key('templates-search')),
      'quick',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Quick oil service'), findsOneWidget);
    expect(find.text('Full inspection'), findsNothing);
    expect(find.byType(WorkshopTemplateCard), findsNWidgets(1));
    expect(find.text('All (1)'), findsOneWidget);
    expect(find.text('Draft (1)'), findsOneWidget);
    expect(find.text('Published (0)'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('templates-search')), '');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(WorkshopTemplateCard), findsNWidgets(3));
    expect(find.text('All (3)'), findsOneWidget);
  });

  testWidgets('grid/list toggle renders both real views', (tester) async {
    await _pumpTemplates(tester, const Locale('en'));

    expect(find.byType(WorkshopTemplateCard), findsNWidgets(3));
    expect(find.byType(AppDataTable<TemplateSummary>), findsNothing);

    await tester.tap(find.text('List'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(AppDataTable<TemplateSummary>), findsOneWidget);
    expect(find.byType(WorkshopTemplateCard), findsNothing);
    // List columns: name / serviceType / version / items / status.
    expect(find.text('Template'), findsOneWidget);
    expect(find.text('Service type'), findsOneWidget);
    expect(find.text('Versions'), findsOneWidget);
    expect(find.text('items selected'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Full inspection'), findsOneWidget);
    expect(find.text('QUICK'), findsOneWidget);

    await tester.tap(find.text('Grid'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(WorkshopTemplateCard), findsNWidgets(3));
  });

  testWidgets('create flow is preserved (dialog payload + builder open)',
      (tester) async {
    await _pumpTemplates(tester, const Locale('en'));

    await tester.tap(find.widgetWithText(AppButton, 'New template'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Template name'), findsOneWidget);

    await tester.enterText(
      find.byType(AppTextField).first,
      'Walk-in check',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Create'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Existing navigation: create pushes the template builder.
    expect(find.byType(TemplateBuilderPage), findsOneWidget);
  });

  testWidgets('edit opens the existing builder', (tester) async {
    await _pumpTemplates(tester, const Locale('en'));

    final edit = find.widgetWithText(AppButton, 'Edit').first;
    await tester.ensureVisible(edit);
    await tester.pumpAndSettle();
    await tester.tap(edit);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(TemplateBuilderPage), findsOneWidget);
  });

  testWidgets('footnote version audit opens the existing builder',
      (tester) async {
    await _pumpTemplates(tester, const Locale('en'));

    final audit = find.widgetWithText(AppButton, 'Version history');
    await tester.ensureVisible(audit);
    await tester.pumpAndSettle();
    await tester.tap(audit);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The builder hosts the version history leading to TemplateVersionPage.
    expect(find.byType(TemplateBuilderPage), findsOneWidget);
  });

  testWidgets('renders in Arabic RTL without exceptions', (tester) async {
    await _pumpTemplates(tester, const Locale('ar'));

    expect(find.text('قوالب الفحص'), findsOneWidget);
    expect(find.text('إجمالي نقاط الفحص'), findsOneWidget);
    expect(find.text('179'), findsOneWidget);
    expect(find.byType(WorkshopTemplateCard), findsNWidgets(3));
    expect(find.text('Full inspection'), findsOneWidget);

    for (final banned in ['DOT', 'ISO', 'Master Inspector', 'Export']) {
      expect(find.textContaining(banned), findsNothing, reason: banned);
    }

    await tester.tap(find.text('قائمة'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(AppDataTable<TemplateSummary>), findsOneWidget);
  });

  testWidgets('keyboard can reach search, toggle, cards and actions',
      (tester) async {
    await _pumpTemplates(tester, const Locale('en'));

    await tester.tap(find.byKey(const Key('templates-search')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 12; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(tester.takeException(), isNull);
    expect(FocusManager.instance.primaryFocus, isNotNull);
  });

  testWidgets('no overflow at 1280, 900 and 390 up to 2.0x (EN+AR)',
      (tester) async {
    const sizes = [
      Size(1280, 800),
      Size(900, 800),
      Size(390, 844),
    ];
    for (final size in sizes) {
      for (final scale in const [1.0, 2.0]) {
        for (final locale in const [Locale('en'), Locale('ar')]) {
          await _pumpTemplates(
            tester,
            locale,
            size: size,
            textScale: scale,
          );
        }
      }
    }
  });

  testWidgets('list view has no overflow at 390 AR 2.0x', (tester) async {
    await _pumpTemplates(
      tester,
      const Locale('ar'),
      size: const Size(390, 844),
      textScale: 2,
    );
    await tester.tap(find.text('قائمة'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(AppDataTable<TemplateSummary>), findsOneWidget);
  });
}
