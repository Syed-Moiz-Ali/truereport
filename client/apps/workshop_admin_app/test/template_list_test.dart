import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/features/templates/template_route_page.dart';
import 'package:workshop_admin_app/src/features/templates/templates_tab.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

// F3-B Step 2, screen 7 — Template List.
//
// Covers the restyle with existing data only: one summary strip (templates,
// published, ΣitemCount = 179), status filter chips with real counts,
// client-side search, one responsive card grid (no grid/list toggle), the
// preserved create/navigation flows and the locked-rule copy scan.

class _TemplateFakeApi implements AdminApi {
  _TemplateFakeApi({this.empty = false, this.fail = false});

  final bool empty;
  final bool fail;

  static const _templates = <TemplateSummary>[
    TemplateSummary(
      id: 't-1',
      name: 'Full inspection',
      serviceType: 'FULL',
      vehicleType: 'CAR',
      status: 'PUBLISHED',
      currentVersion: 2,
      itemCount: 110,
      updatedAt: '2026-11-05T10:00:00',
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
  Future<List<TemplateSummary>> templates() async {
    if (fail) {
      throw StateError('templates failed');
    }
    return empty ? const [] : _templates;
  }

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
  _TemplateFakeApi? api,
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
      overrides: [
        adminApiProvider.overrideWithValue(api ?? _TemplateFakeApi()),
      ],
      child: _TemplateTestApp(locale: locale),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(TemplatesTab)));

List<WorkshopFilterChip> _chips(WidgetTester tester) => tester
    .widgetList<WorkshopFilterChip>(find.byType(WorkshopFilterChip))
    .toList(growable: false);

Future<void> _tapChip(WidgetTester tester, String label) async {
  final chip = find.byWidgetPredicate(
    (widget) => widget is WorkshopFilterChip && widget.label == label,
  );
  expect(chip, findsOneWidget);
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

Finder _card(String id) => find.byKey(Key('template-$id'));

Finder _inStrip(Finder strip, String text) =>
    find.descendant(of: strip, matching: find.text(text));

void main() {
  testWidgets('renders header, summary strip, counted chips and cards (EN)', (
    tester,
  ) async {
    await _pumpTemplates(tester, const Locale('en'));

    // Page header: title + subtitle + the single create entry.
    expect(find.text('Inspection templates'), findsOneWidget);
    expect(find.text('Reusable inspection checklists.'), findsOneWidget);
    expect(find.byKey(const Key('templates-search')), findsOneWidget);
    expect(find.widgetWithText(WorkshopButton, 'New template'), findsOneWidget);

    // One summary strip with three real metrics (110 + 24 + 45 = 179).
    final strip = find.byType(WorkshopMetricStrip);
    expect(strip, findsOneWidget);
    expect(_inStrip(strip, '3'), findsOneWidget);
    expect(_inStrip(strip, '1'), findsOneWidget);
    expect(_inStrip(strip, '179'), findsOneWidget);
    expect(_inStrip(strip, 'Templates'), findsOneWidget);
    expect(_inStrip(strip, 'Published'), findsOneWidget);
    expect(_inStrip(strip, 'Total checkpoints'), findsOneWidget);

    // Filter chips from the real statuses with client-side counts.
    final chips = _chips(tester);
    expect(chips.map((chip) => chip.label).toList(), [
      'All',
      'Published',
      'Draft',
      'Retired',
    ]);
    expect(chips.map((chip) => chip.count).toList(), [3, 1, 1, 1]);

    // One column of full-width rows — no grid/list toggle, no data table.
    expect(find.byKey(const Key('templates-view-toggle')), findsNothing);
    expect(find.text('Grid'), findsNothing);
    expect(find.text('List'), findsNothing);
    expect(find.byType(AppDataTable<TemplateSummary>), findsNothing);
    expect(find.byType(WorkshopTemplateCard), findsNothing);
    for (final id in const ['t-1', 't-2', 't-3']) {
      expect(_card(id), findsOneWidget);
    }
    // Single column at 1280: the rows stack and share one leading edge.
    final centers = [
      for (final id in const ['t-1', 't-2', 't-3']) tester.getCenter(_card(id)),
    ];
    for (var index = 1; index < centers.length; index++) {
      expect(centers[index].dy, greaterThan(centers[index - 1].dy));
      expect(centers[index].dx, moreOrLessEquals(centers[0].dx, epsilon: 1));
    }

    // Card fields: name · integer version + plural item count ·
    // `Service type: FULL` muted meta · status badge · updated date.
    final l10n = _l10n(tester);
    expect(find.text('v2 · ${l10n.templateItemsCount(110)}'), findsOneWidget);
    expect(find.text('v1 · ${l10n.templateItemsCount(24)}'), findsOneWidget);
    expect(find.text('v3 · ${l10n.templateItemsCount(45)}'), findsOneWidget);
    expect(
      find.descendant(of: _card('t-1'), matching: find.text('Published')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _card('t-2'), matching: find.text('Draft')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _card('t-3'), matching: find.text('Retired')),
      findsOneWidget,
    );
    expect(find.text('${l10n.serviceType}: FULL'), findsNWidgets(2));
    expect(find.text('${l10n.serviceType}: QUICK'), findsOneWidget);
    expect(
      find.descendant(
        of: _card('t-1'),
        matching: find.textContaining('Updated'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _card('t-2'),
        matching: find.textContaining('Updated'),
      ),
      findsNothing,
    );

    // No per-card Edit action; one secondary version-history action each.
    expect(find.text('Edit'), findsNothing);
    expect(
      find.widgetWithText(WorkshopButton, 'Version history'),
      findsNWidgets(3),
    );

    // Subtle validation-lock note at the end of the list.
    expect(find.text('Locked by platform'), findsOneWidget);
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

  testWidgets(
    'status chips filter client-side, counts and summary stay scoped',
    (tester) async {
      await _pumpTemplates(tester, const Locale('en'));

      await _tapChip(tester, 'Published');
      expect(tester.takeException(), isNull);
      expect(_card('t-1'), findsOneWidget);
      expect(_card('t-2'), findsNothing);
      expect(_card('t-3'), findsNothing);
      // Counts stay derived from the search-scoped (status-unfiltered) list.
      expect(_chips(tester).map((chip) => chip.count).toList(), [3, 1, 1, 1]);
      expect(_inStrip(find.byType(WorkshopMetricStrip), '179'), findsOneWidget);

      await _tapChip(tester, 'Retired');
      expect(tester.takeException(), isNull);
      expect(_card('t-3'), findsOneWidget);
      expect(_card('t-1'), findsNothing);

      await _tapChip(tester, 'All');
      expect(tester.takeException(), isNull);
      expect(_card('t-1'), findsOneWidget);
      expect(_card('t-2'), findsOneWidget);
      expect(_card('t-3'), findsOneWidget);
    },
  );

  testWidgets('search narrows the list and rescopes chip counts and summary', (
    tester,
  ) async {
    await _pumpTemplates(tester, const Locale('en'));

    await tester.enterText(find.byKey(const Key('templates-search')), 'quick');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Quick oil service'), findsOneWidget);
    expect(_card('t-1'), findsNothing);
    expect(_card('t-2'), findsOneWidget);
    expect(_card('t-3'), findsNothing);
    expect(_chips(tester).map((chip) => chip.count).toList(), [1, 0, 1, 0]);
    final strip = find.byType(WorkshopMetricStrip);
    expect(_inStrip(strip, '1'), findsWidgets);
    expect(_inStrip(strip, '0'), findsOneWidget);
    expect(_inStrip(strip, '24'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('templates-search')), '');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_chips(tester).map((chip) => chip.count).toList(), [3, 1, 1, 1]);
    expect(_card('t-1'), findsOneWidget);
  });

  testWidgets('whole card opens the existing builder', (tester) async {
    await _pumpTemplates(tester, const Locale('en'));

    final card = _card('t-1');
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(TemplateBuilderPage), findsOneWidget);
  });

  testWidgets('version-history secondary action opens the existing builder', (
    tester,
  ) async {
    await _pumpTemplates(tester, const Locale('en'));

    final action = find.widgetWithText(WorkshopButton, 'Version history').first;
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The builder hosts the version history leading to TemplateVersionPage.
    expect(find.byType(TemplateBuilderPage), findsOneWidget);
  });

  testWidgets('create flow is preserved (dialog payload + builder open)', (
    tester,
  ) async {
    await _pumpTemplates(tester, const Locale('en'));

    await tester.tap(find.widgetWithText(WorkshopButton, 'New template'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Template name'), findsOneWidget);

    await tester.enterText(find.byType(AppTextField).first, 'Walk-in check');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Create'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Existing navigation: create pushes the template builder.
    expect(find.byType(TemplateBuilderPage), findsOneWidget);
  });

  testWidgets('empty state keeps its create action', (tester) async {
    await _pumpTemplates(
      tester,
      const Locale('en'),
      api: _TemplateFakeApi(empty: true),
    );
    final l10n = _l10n(tester);
    expect(find.text(l10n.templatesEmptyTitle), findsOneWidget);
    expect(find.text(l10n.templatesEmptyBody), findsOneWidget);
    expect(
      find.widgetWithText(WorkshopButton, 'New template'),
      findsNWidgets(2),
    );
    expect(find.byType(WorkshopMetricStrip), findsOneWidget);
  });

  testWidgets('error state keeps its retry action', (tester) async {
    await _pumpTemplates(
      tester,
      const Locale('en'),
      api: _TemplateFakeApi(fail: true),
    );
    final l10n = _l10n(tester);
    expect(find.byType(WorkshopErrorState), findsOneWidget);
    expect(find.text(l10n.genericError), findsOneWidget);
    await tester.tap(find.text(l10n.retryAction));
    await tester.pumpAndSettle();
    expect(find.byType(WorkshopErrorState), findsOneWidget);
  });

  testWidgets('renders in Arabic RTL without exceptions', (tester) async {
    await _pumpTemplates(tester, const Locale('ar'));

    final l10n = _l10n(tester);
    expect(
      Directionality.of(tester.element(find.byType(TemplatesTab))),
      TextDirection.rtl,
    );
    expect(find.text(l10n.templateListTitle), findsOneWidget);
    expect(find.text(l10n.templatesSubtitle), findsOneWidget);
    expect(find.text(l10n.templateTotalCheckpoints), findsOneWidget);
    expect(find.text('179'), findsOneWidget);
    expect(_card('t-1'), findsOneWidget);
    expect(_card('t-2'), findsOneWidget);
    expect(_card('t-3'), findsOneWidget);
    expect(find.text('Full inspection'), findsOneWidget);

    for (final banned in ['DOT', 'ISO', 'Master Inspector', 'Export']) {
      expect(find.textContaining(banned), findsNothing, reason: banned);
    }
  });

  testWidgets('keyboard can reach search, chips, cards and actions', (
    tester,
  ) async {
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

  testWidgets('no overflow at 1280, 900, 768 and 390 up to 2.0x (EN+AR)', (
    tester,
  ) async {
    const sizes = [
      Size(1280, 800),
      Size(900, 800),
      Size(768, 900),
      Size(390, 844),
    ];
    for (final size in sizes) {
      for (final scale in const [1.0, 2.0]) {
        for (final locale in const [Locale('en'), Locale('ar')]) {
          await _pumpTemplates(tester, locale, size: size, textScale: scale);
        }
      }
    }
  });
}
