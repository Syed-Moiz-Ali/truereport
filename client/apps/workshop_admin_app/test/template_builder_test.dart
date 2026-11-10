import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/features/templates/template_builder_page.dart';
import 'package:workshop_admin_app/src/features/templates/template_version_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

// F3-B Step 2, screen 8 — Template Builder workbench.
//
// Covers the Figma 1280 two-column restyle with existing data only:
// catalog search (GET .../master/items?search=) + category filter,
// tap-to-add, numbered sequence cards with locked pills, move up/down/remove,
// drag-reorder via ReorderableDragStartListener (save persists the ordered
// item list with sortOrder), draft/publish/versions flows, locked pills,
// EN/AR preview, keyboard-only reorder and the locked-rule copy scan.
// No new endpoints or data are introduced.

ItemVersion _publishedVersion(String id, String label) {
  return ItemVersion(
    id: id,
    versionNo: 1,
    status: 'PUBLISHED',
    resultOptions: const ['NO_ISSUE_OBSERVED', 'DEFECT_FOUND'],
    severityPolicy: '{}',
    applicability: '{}',
    reasonCodes: const [],
    noteRequirement: 'REQUIRED',
    evidenceRequirement: 'REQUIRED',
    minPhotos: 1,
    equipmentIds: const [],
    guideImageId: null,
    publishedAt: '2026-11-03T10:00:00',
    translations: {
      'en': Translation(
        locale: 'en',
        label: label,
        instruction: '$label steps',
      ),
      'ar': Translation(
        locale: 'ar',
        label: '$label AR',
        instruction: '$label steps AR',
      ),
    },
  );
}

PublishedItem _published(
  String itemId,
  String versionId,
  String label,
  String categoryId,
  String categoryLabel,
) {
  final version = _publishedVersion(versionId, label);
  return PublishedItem(
    itemId: itemId,
    versionId: versionId,
    stableCode: 'STABLE-$itemId',
    categoryId: categoryId,
    categoryLabelEn: categoryLabel,
    categoryLabelAr: '$categoryLabel AR',
    labelEn: label,
    labelAr: '$label AR',
    sampleData: false,
    version: version,
  );
}

TemplateItemView _draftItem(String versionId, String label, int sortOrder) {
  return TemplateItemView(
    masterItemVersionId: versionId,
    sortOrder: sortOrder,
    stableCode: 'STABLE-$versionId',
    categoryLabelEn: 'Chassis',
    categoryLabelAr: 'Chassis AR',
    labelEn: label,
    labelAr: '$label AR',
    instructionEn: 'Instruction $versionId en',
    instructionAr: 'Instruction $versionId ar',
    versionNo: 1,
    resultOptions: const ['NO_ISSUE_OBSERVED'],
    severityPolicy: '{}',
    reasonCodes: const [],
    noteRequirement: 'REQUIRED',
    evidenceRequirement: 'REQUIRED',
    minPhotos: 1,
    equipmentIds: const [],
    guideImageId: null,
    sampleData: false,
  );
}

class _BuilderFakeApi implements AdminApi {
  _BuilderFakeApi({bool withDraft = true}) : _draftExists = withDraft;

  bool _draftExists;
  List<TemplateItemDraft>? savedItems;
  int publishCalls = 0;
  int retireCalls = 0;
  int createDraftCalls = 0;

  static final List<Category> _categories = [
    const Category(
      id: 'cat-chassis',
      slug: 'chassis',
      status: 'ACTIVE',
      sortOrder: 1,
      labelEn: 'Chassis',
      labelAr: 'Chassis AR',
      itemCount: 2,
    ),
    const Category(
      id: 'cat-engine',
      slug: 'engine',
      status: 'ACTIVE',
      sortOrder: 2,
      labelEn: 'Engine',
      labelAr: 'Engine AR',
      itemCount: 3,
    ),
  ];

  static final List<PublishedItem> _catalog = [
    _published(
      'item-brake',
      'mv-brake',
      'Brake pad wear check',
      'cat-chassis',
      'Chassis',
    ),
    _published('item-oil', 'mv-oil', 'Engine oil level', 'cat-engine', 'Engine'),
    _published(
      'item-battery',
      'mv-battery',
      'Battery health check',
      'cat-chassis',
      'Chassis',
    ),
    _published(
      'item-coolant',
      'mv-coolant',
      'Coolant level check',
      'cat-engine',
      'Engine',
    ),
    _published(
      'item-wiper',
      'mv-wiper',
      'Wiper blade check',
      'cat-engine',
      'Engine',
    ),
  ];

  TemplateDetail _detail() {
    return TemplateDetail(
      id: 't-1',
      name: 'Comprehensive Inspection',
      description: 'Workshop template',
      serviceType: 'FULL',
      vehicleType: 'CAR',
      status: 'DRAFT',
      currentPublishedVersionId: 'v-1',
      versions: const [
        TemplateVersionSummary(
          id: 'v-1',
          versionNo: 1,
          status: 'PUBLISHED',
          publishedAt: '2026-11-03T10:00:00',
          itemCount: 3,
        ),
      ],
      draft: _draftExists
          ? TemplateVersionView(
              id: 'draft-2',
              versionNo: 2,
              status: 'DRAFT',
              publishedAt: '',
              items: [
                _draftItem('mv-brake', 'Brake pad wear check', 0),
                _draftItem('mv-oil', 'Engine oil level', 1),
                _draftItem('mv-battery', 'Battery health check', 2),
              ],
            )
          : null,
    );
  }

  @override
  Future<TemplateDetail> templateDetail(String id) async => _detail();

  @override
  Future<List<Category>> workshopCategories() async => _categories;

  @override
  Future<List<PublishedItem>> publishedItems({
    String search = '',
    String categoryId = '',
  }) async {
    final query = search.trim().toLowerCase();
    return _catalog.where((item) {
      if (categoryId.isNotEmpty && item.categoryId != categoryId) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return item.labelEn.toLowerCase().contains(query) ||
          item.categoryLabelEn.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Future<TemplateDetail> saveTemplateDraft({
    required String id,
    required String name,
    String? description,
    required String serviceType,
    String? vehicleType,
    required List<TemplateItemDraft> items,
  }) async {
    savedItems = items;
    return _detail();
  }

  @override
  Future<TemplateDetail> publishTemplate(String id) async {
    publishCalls++;
    return _detail();
  }

  @override
  Future<TemplateDetail> retireTemplate(String id) async {
    retireCalls++;
    return _detail();
  }

  @override
  Future<TemplateDetail> createTemplateDraft(String id) async {
    createDraftCalls++;
    _draftExists = true;
    return _detail();
  }

  @override
  Future<TemplateVersionView> templateVersion(
    String id,
    String versionId,
  ) async =>
      TemplateVersionView(
        id: versionId,
        versionNo: 1,
        status: 'PUBLISHED',
        publishedAt: '2026-11-03T10:00:00',
        items: [_draftItem('mv-brake', 'Brake pad wear check', 0)],
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _BuilderTestApp extends ConsumerStatefulWidget {
  const _BuilderTestApp({
    required this.locale,
    required this.reduceMotion,
  });

  final Locale locale;
  final bool reduceMotion;

  @override
  ConsumerState<_BuilderTestApp> createState() => _BuilderTestAppState();
}

class _BuilderTestAppState extends ConsumerState<_BuilderTestApp> {
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
    const home = TemplateBuilderPage(templateId: 't-1');
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildAppTheme(),
      home: widget.reduceMotion
          ? Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: true),
                child: home,
              ),
            )
          : home,
    );
  }
}

Future<void> _pumpBuilder(
  WidgetTester tester,
  _BuilderFakeApi api,
  Locale locale, {
  Size size = const Size(1280, 800),
  double textScale = 1,
  bool reduceMotion = false,
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
      overrides: [adminApiProvider.overrideWithValue(api)],
      child: _BuilderTestApp(locale: locale, reduceMotion: reduceMotion),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

List<String> _sequenceTitles(WidgetTester tester) {
  return tester
      .widgetList<WorkshopSequenceCard>(find.byType(WorkshopSequenceCard))
      .map((card) => card.title)
      .toList();
}

bool _focusedWithin(WidgetTester tester, Key key) {
  final node = FocusManager.instance.primaryFocus;
  final context = node?.context;
  if (context == null) {
    return false;
  }
  return find
      .ancestor(
        of: find.byWidget(context.widget),
        matching: find.byKey(key),
      )
      .evaluate()
      .isNotEmpty;
}

String _renderedText(WidgetTester tester) {
  return find
      .byType(Text)
      .evaluate()
      .map((element) {
        final widget = element.widget as Text;
        return widget.data ?? widget.textSpan?.toPlainText() ?? '';
      })
      .join('\n')
      .toLowerCase();
}

void main() {
  testWidgets('renders two-column workbench with catalog and sequence (EN)',
      (tester) async {
    final api = _BuilderFakeApi();
    await _pumpBuilder(tester, api, const Locale('en'));

    // Top bar: title + integer version pill + publish flow entry points.
    expect(find.byKey(const Key('builder-title')), findsOneWidget);
    expect(find.text('Comprehensive Inspection'), findsWidgets);
    expect(find.text('v2'), findsOneWidget);
    expect(
      find.widgetWithText(AppButton, 'Publish template'),
      findsOneWidget,
    );
    expect(find.byType(WorkshopMetric), findsNothing);

    // Left catalog: search, category filter and tap-to-add cards.
    expect(find.textContaining('Master items'), findsOneWidget);
    expect(find.byKey(const Key('builder-search')), findsOneWidget);
    expect(find.byKey(const Key('builder-category')), findsOneWidget);
    expect(find.byKey(const Key('published-item-mv-brake')), findsOneWidget);
    expect(find.byKey(const Key('published-item-mv-wiper')), findsOneWidget);
    expect(find.byKey(const Key('catalog-add-mv-oil')), findsOneWidget);

    // Right sequence: numbered cards with locked pills + reorder controls.
    expect(find.text('Template sequence'), findsOneWidget);
    expect(find.text('3 items selected'), findsOneWidget);
    expect(find.byType(WorkshopSequenceCard), findsNWidgets(3));
    expect(find.byType(WorkshopLockedPill), findsNWidgets(3));
    expect(find.textContaining('Locked by platform'), findsNWidgets(3));
    expect(find.byKey(const Key('seq-up-0')), findsOneWidget);
    expect(find.byKey(const Key('seq-down-0')), findsOneWidget);
    expect(find.byKey(const Key('seq-remove-0')), findsOneWidget);
    expect(find.byKey(const Key('seq-drag-0')), findsOneWidget);
    expect(find.byKey(const Key('seq-drag-1')), findsOneWidget);
    expect(find.byKey(const Key('seq-drag-2')), findsOneWidget);
    expect(find.byKey(const Key('builder-dropzone')), findsOneWidget);
    expect(find.byType(WorkshopDropZone), findsOneWidget);

    // Versions history preserved (below the fold: scroll into view first).
    await tester.scrollUntilVisible(
      find.byKey(const Key('template-version-v-1')),
      300,
      scrollable: find.ancestor(of: find.byType(ReorderableListView), matching: find.byType(Scrollable)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Version history'), findsOneWidget);
    expect(find.byKey(const Key('template-version-v-1')), findsOneWidget);
  });

  testWidgets('locked-rule copy never renders (EN)', (tester) async {
    final api = _BuilderFakeApi();
    await _pumpBuilder(tester, api, const Locale('en'));

    final text = _renderedText(tester);
    for (final banned in [
      'autosave',
      'auto-save',
      'active',
      'automated',
      'optical',
      'laser',
      'telemetry',
      'bluetooth',
      'bt calibration',
      'obd',
      'iso',
      'custom',
      'range',
      'of 14',
      '14 configured',
      'photo gate',
      'cycle time',
      'target cycle',
      'compliance',
      'certifi',
      'threshold',
      'trigger',
      'micrometer',
      'telematics',
      'fast track',
      'quality assurance',
      'active policy',
      'quad-sensor',
      'spectro',
      'boilover',
      '32nd',
      'minutes estimated',
      'flow',
      'value range',
      'ble',
    ]) {
      expect(text.contains(banned), isFalse, reason: banned);
    }
    // Integer versions only: no semver copy such as "v2.4".
    expect(text.contains(RegExp(r'v\d+\.\d+')), isFalse);
  });

  testWidgets('search narrows the catalog via the items endpoint (EN)',
      (tester) async {
    final api = _BuilderFakeApi();
    await _pumpBuilder(tester, api, const Locale('en'));

    expect(find.byKey(const Key('published-item-mv-brake')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('builder-search')),
      'battery',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('published-item-mv-battery')), findsOneWidget);
    expect(find.byKey(const Key('published-item-mv-brake')), findsNothing);

    await tester.enterText(find.byKey(const Key('builder-search')), '');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('published-item-mv-brake')), findsOneWidget);
  });

  testWidgets('category filter scopes the catalog (EN)', (tester) async {
    final api = _BuilderFakeApi();
    await _pumpBuilder(tester, api, const Locale('en'));

    await tester.tap(find.byKey(const Key('builder-category')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Engine'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('published-item-mv-oil')), findsOneWidget);
    expect(find.byKey(const Key('published-item-mv-coolant')), findsOneWidget);
    expect(find.byKey(const Key('published-item-mv-brake')), findsNothing);
  });

  testWidgets('tap-to-add appends to the sequence (EN)', (tester) async {
    final api = _BuilderFakeApi();
    await _pumpBuilder(tester, api, const Locale('en'));

    expect(_sequenceTitles(tester), hasLength(3));
    await tester.ensureVisible(find.byKey(const Key('catalog-add-mv-coolant')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('catalog-add-mv-coolant')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_sequenceTitles(tester), hasLength(4));
    expect(_sequenceTitles(tester).last, 'Coolant level check');
    expect(find.text('4 items selected'), findsOneWidget);
    // Already-selected items cannot be added twice.
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('catalog-add-mv-brake')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('drop zone tap adds the first available catalog item (EN)',
      (tester) async {
    final api = _BuilderFakeApi();
    await _pumpBuilder(tester, api, const Locale('en'));

    await tester.ensureVisible(find.byKey(const Key('builder-dropzone')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('builder-dropzone')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // mv-coolant is the first catalog entry not already in the sequence.
    expect(_sequenceTitles(tester), hasLength(4));
    expect(_sequenceTitles(tester).last, 'Coolant level check');
  });

  testWidgets('remove deletes the row (EN)', (tester) async {
    final api = _BuilderFakeApi();
    await _pumpBuilder(tester, api, const Locale('en'));

    await tester.ensureVisible(find.byKey(const Key('seq-remove-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('seq-remove-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      _sequenceTitles(tester),
      ['Brake pad wear check', 'Battery health check'],
    );
  });

  testWidgets('move up/down reorder the sequence (EN)', (tester) async {
    final api = _BuilderFakeApi();
    await _pumpBuilder(tester, api, const Locale('en'));

    await tester.ensureVisible(find.byKey(const Key('seq-down-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('seq-down-0')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      _sequenceTitles(tester),
      ['Engine oil level', 'Brake pad wear check', 'Battery health check'],
    );

    await tester.ensureVisible(find.byKey(const Key('seq-up-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('seq-up-2')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      _sequenceTitles(tester),
      ['Engine oil level', 'Battery health check', 'Brake pad wear check'],
    );
  });

  testWidgets('reorder then save sends the ordered item list (EN)',
      (tester) async {
    final api = _BuilderFakeApi();
    await _pumpBuilder(tester, api, const Locale('en'));

    await tester.ensureVisible(find.byKey(const Key('seq-down-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('seq-down-0')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Content saved'), findsOneWidget);

    final saved = api.savedItems!;
    expect(
      saved.map((item) => item.masterItemVersionId),
      ['mv-oil', 'mv-brake', 'mv-battery'],
    );
    expect(saved.map((item) => item.sortOrder), [0, 1, 2]);
  });

  testWidgets('drag handle reorder updates order and save order (EN)',
      (tester) async {
    final api = _BuilderFakeApi();
    await _pumpBuilder(tester, api, const Locale('en'));

    // Drag the middle row above the first one: the drag starts mid-viewport
    // so the pointer stays on the surface for the whole gesture. The moves
    // are incremental (like a real finger): a single-jump drag can lose the
    // gesture arena to the outer list, while progressive moves let the row's
    // drag handle claim the gesture and reorder.
    await tester.ensureVisible(find.byKey(const Key('seq-drag-1')));
    await tester.pumpAndSettle();
    final handleCenter = tester.getCenter(find.byKey(const Key('seq-drag-1')));
    final drag = await tester.startGesture(handleCenter);
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await drag.moveBy(const Offset(0, -25));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
    await drag.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The dragged middle row now sits above the first row.
    expect(
      _sequenceTitles(tester),
      ['Engine oil level', 'Brake pad wear check', 'Battery health check'],
    );

    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final saved = api.savedItems!;
    expect(
      saved.map((item) => item.masterItemVersionId),
      ['mv-oil', 'mv-brake', 'mv-battery'],
    );
    expect(saved.map((item) => item.sortOrder), [0, 1, 2]);
    // Every handle is present: one per sequence row.
    expect(
      find.byType(ReorderableDragStartListener),
      findsNWidgets(3),
    );
  });

  testWidgets('publish saves the draft then publishes (EN)', (tester) async {
    final api = _BuilderFakeApi();
    await _pumpBuilder(tester, api, const Locale('en'));

    await tester.tap(find.byKey(const Key('builder-publish')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(api.savedItems, isNotNull);
    expect(api.publishCalls, 1);
    expect(find.text('Template published'), findsOneWidget);
  });

  testWidgets('retire confirms then retires (EN)', (tester) async {
    final api = _BuilderFakeApi();
    await _pumpBuilder(tester, api, const Locale('en'));

    await tester.tap(find.byIcon(Icons.archive_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Retire'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(api.retireCalls, 1);
  });

  testWidgets('versions open the existing version page (EN)', (tester) async {
    final api = _BuilderFakeApi();
    await _pumpBuilder(tester, api, const Locale('en'));

    // The version card is lazily built below the fold: scroll it into view.
    await tester.scrollUntilVisible(
      find.byKey(const Key('template-version-v-1')),
      300,
      scrollable: find.ancestor(of: find.byType(ReorderableListView), matching: find.byType(Scrollable)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('template-version-v-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(TemplateVersionPage), findsOneWidget);
  });

  testWidgets('read-only template offers create draft (EN)', (tester) async {
    final api = _BuilderFakeApi(withDraft: false);
    await _pumpBuilder(tester, api, const Locale('en'));

    expect(find.text('Read-only version'), findsOneWidget);
    expect(find.byType(WorkshopSequenceCard), findsNothing);
    await tester.tap(find.widgetWithText(AppButton, 'Create new draft'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(api.createDraftCalls, 1);
    expect(find.byType(WorkshopSequenceCard), findsNWidgets(3));
  });

  testWidgets('preview opens with EN/AR toggle (EN)', (tester) async {
    final api = _BuilderFakeApi();
    await _pumpBuilder(tester, api, const Locale('en'));

    await tester.tap(find.byKey(const Key('builder-preview')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('English preview'), findsOneWidget);
    expect(find.text('Arabic preview'), findsOneWidget);
    expect(find.text('Brake pad wear check'), findsWidgets);

    await tester.tap(find.text('Arabic preview'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Brake pad wear check AR'), findsWidgets);
  });

  testWidgets('keyboard-only reorder via move controls (EN)', (tester) async {
    final api = _BuilderFakeApi();
    await _pumpBuilder(tester, api, const Locale('en'));

    expect(
      _sequenceTitles(tester),
      ['Brake pad wear check', 'Engine oil level', 'Battery health check'],
    );
    var moved = false;
    for (var i = 0; i < 160 && !moved; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      if (_focusedWithin(tester, const Key('seq-down-0'))) {
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        if (_sequenceTitles(tester).first == 'Brake pad wear check') {
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pumpAndSettle();
        }
        moved = _sequenceTitles(tester).first != 'Brake pad wear check';
      }
    }
    expect(moved, isTrue);
    expect(
      _sequenceTitles(tester),
      ['Engine oil level', 'Brake pad wear check', 'Battery health check'],
    );
  });

  testWidgets('renders in Arabic RTL without exceptions', (tester) async {
    final api = _BuilderFakeApi();
    await _pumpBuilder(tester, api, const Locale('ar'));

    expect(
      Directionality.of(tester.element(find.byType(TemplateBuilderPage))),
      TextDirection.rtl,
    );
    expect(find.text('Comprehensive Inspection'), findsWidgets);
    expect(find.text('v2'), findsOneWidget);
    expect(find.byType(WorkshopSequenceCard), findsNWidgets(3));
    expect(find.byType(WorkshopLockedPill), findsNWidgets(3));
    expect(find.byKey(const Key('seq-drag-0')), findsOneWidget);

    final text = _renderedText(tester);
    for (final banned in ['autosave', 'telemetry', 'iso', 'custom']) {
      expect(text.contains(banned), isFalse, reason: banned);
    }
  });

  testWidgets('reduce-motion renders and reorders without animations',
      (tester) async {
    final api = _BuilderFakeApi();
    await _pumpBuilder(
      tester,
      api,
      const Locale('en'),
      reduceMotion: true,
    );

    expect(find.byType(WorkshopSequenceCard), findsNWidgets(3));
    await tester.tap(find.byKey(const Key('seq-down-0')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_sequenceTitles(tester).first, 'Engine oil level');
  });

  testWidgets('no overflow at 1280, 900 and 390 up to 2.0x (EN+AR)',
      (tester) async {
    const sizes = [
      Size(1280, 800),
      Size(900, 800),
      Size(390, 844),
    ];
    for (final size in sizes) {
      for (final scale in const [1.0, 1.5, 2.0]) {
        for (final locale in const [Locale('en'), Locale('ar')]) {
          final api = _BuilderFakeApi();
          await _pumpBuilder(
            tester,
            api,
            locale,
            size: size,
            textScale: scale,
          );
        }
      }
    }
  });
}
