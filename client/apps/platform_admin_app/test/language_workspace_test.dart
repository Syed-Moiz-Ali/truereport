import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/components/platform_buttons.dart';
import 'package:platform_admin_app/src/features/languages/language_workspace_screen.dart';
import 'package:platform_admin_app/src/features/languages/languages_screen.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/platform_translations.dart'
    hide TranslationCoverage;

import 'support/ui_message_fixtures.dart';

const _languageCode = 'ar';

class FakeWorkspaceTranslationApi extends TranslationApi {
  FakeWorkspaceTranslationApi({required List<TranslationItem> items})
    : _items = List<TranslationItem>.of(items),
      super(
        ApiClient(
          config: const ApiConfig(baseUrl: '', environment: 'test'),
        ),
        const ApiEndpoints(baseUrl: ''),
      );

  final List<TranslationItem> _items;
  final Map<String, String> savedReview = {};
  final List<TranslationItem> upserts = [];
  int approveCalls = 0;
  int publishCalls = 0;
  int retryCalls = 0;
  int generateUiCalls = 0;

  UiMessageReviewEntry _entry(
    String key,
    String source,
    String target, {
    bool changed = false,
    bool missing = false,
  }) => UiMessageReviewEntry(
    key: key,
    sourceText: source,
    targetText: target,
    changed: changed,
    missing: missing,
    untranslated: target.isEmpty,
    placeholderMismatch: false,
  );

  List<UiMessageReviewEntry> get _reviewEntries => [
    _entry('common.button.save', 'Save', 'حفظ'),
    _entry('common.button.cancel', 'Cancel', 'إلغاء', changed: true),
    _entry('common.empty.title', 'No data yet', '', missing: true),
  ];

  UiMessageReview _review() {
    final entries = _reviewEntries
        .map(
          (entry) => entry.copyWith(
            targetText: savedReview[entry.key] ?? entry.targetText,
          ),
        )
        .toList(growable: false);
    return UiMessageReview(
      language: _languageCode,
      status: 'REVIEW',
      path: 'i18n/platform_admin/ar.json',
      totalKeys: entries.length,
      changedKeys: entries.where((entry) => entry.changed).length,
      missingKeys: entries.where((entry) => entry.missing).length,
      entries: entries,
    );
  }

  @override
  Future<UiMessageReview> fetchUiMessageReview(String code) async => _review();

  @override
  Future<UiMessageReview> saveUiMessageReview(
    String code,
    Map<String, String> translations,
  ) async {
    savedReview.addAll(translations);
    return _review();
  }

  @override
  Future<UiMessageApproval> approveUiMessageReview(String code) async {
    approveCalls++;
    return UiMessageApproval(
      language: code,
      status: 'APPROVED',
      path: 'i18n/platform_admin/ar.json',
      hash: 'hash',
      totalKeys: _reviewEntries.length,
    );
  }

  @override
  Future<UiMessageGeneration> retryFailedUiMessageGeneration(
    String code,
  ) async {
    retryCalls++;
    return const UiMessageGeneration(
      language: _languageCode,
      jobId: 'ui-job',
      jobStatus: UiMessageGeneration.completed,
      status: 'COMPLETED',
      path: 'i18n/platform_admin/ar.json',
      keysTranslated: 3,
      failedKeys: [],
      totalKeys: 3,
      completedKeys: 3,
      error: '',
    );
  }

  @override
  Future<UiMessageGeneration> generateUiMessages({
    required String code,
    bool force = false,
    String reviewStatus = 'TRANSLATING',
  }) async {
    generateUiCalls++;
    return const UiMessageGeneration(
      language: _languageCode,
      jobId: 'ui-job',
      jobStatus: UiMessageGeneration.completed,
      status: 'COMPLETED',
      path: 'i18n/platform_admin/ar.json',
      keysTranslated: 3,
      failedKeys: [],
      totalKeys: 3,
      completedKeys: 3,
      error: '',
    );
  }

  @override
  Future<List<int>> downloadUiMessageJson(String code) async =>
      '{"common.button.save":"حفظ"}'.codeUnits;

  @override
  Future<TranslationBacklog> fetchBacklog(String code) async {
    final groups = <TranslationBacklogGroup>[];
    final grouped = <String, List<TranslationItem>>{};
    for (final item in _items) {
      grouped.putIfAbsent(item.entityType, () => []).add(item);
    }
    for (final entry in grouped.entries) {
      groups.add(
        TranslationBacklogGroup(
          entityType: entry.key,
          total: entry.value.length,
          approved: entry.value
              .where((item) => item.status == TranslationStatus.approved)
              .length,
          items: List<TranslationItem>.of(entry.value),
        ),
      );
    }
    final approved = _items
        .where((item) => item.status == TranslationStatus.approved)
        .length;
    return TranslationBacklog(
      languageCode: code,
      languageStatus: LanguageStatus.review,
      totalRequired: _items.length,
      approvedCount: approved,
      coveragePercent: _items.isEmpty ? 100 : approved / _items.length * 100,
      groups: groups,
    );
  }

  @override
  Future<TranslationItem> upsertTranslation({
    required String entityType,
    required String entityId,
    required String field,
    required String language,
    required String text,
    String? status,
  }) async {
    final index = _items.indexWhere(
      (item) =>
          item.entityType == entityType &&
          item.entityId == entityId &&
          item.field == field,
    );
    final updated = TranslationItem(
      entityType: entityType,
      entityId: entityId,
      entityCode: index >= 0 ? _items[index].entityCode : entityId,
      field: field,
      defaultText: index >= 0 ? _items[index].defaultText : '',
      text: text,
      status: TranslationStatus.normalize(status ?? TranslationStatus.draft),
    );
    upserts.add(updated);
    if (index >= 0) {
      _items[index] = updated;
    } else {
      _items.add(updated);
    }
    return updated;
  }

  @override
  Future<PlatformLanguage> publishLanguage(String code) async {
    publishCalls++;
    return const PlatformLanguage(
      code: _languageCode,
      nativeName: 'العربية',
      direction: 'rtl',
      active: true,
      isDefault: false,
      sortOrder: 2,
      status: 'LIVE',
    );
  }
}

LanguageReadiness _readiness({int percent = 60, bool withBlockers = true}) =>
    LanguageReadiness(
      language: _languageCode,
      status: 'REVIEW',
      nativeName: 'العربية',
      direction: 'rtl',
      isDefault: false,
      uiMessagesPath: 'i18n/platform_admin/ar.json',
      readinessPercent: percent,
      uiMessages: const UiMessageCoverage(
        total: 3,
        approved: 2,
        missing: 1,
        changed: 1,
        path: 'i18n/platform_admin/ar.json',
        generationStatus: 'COMPLETED',
      ),
      content: const {
        'CATEGORY': EntityReadiness(total: 1, approved: 0),
        'ITEM': EntityReadiness(total: 2, approved: 1),
      },
      blockers: withBlockers
          ? const [
              ReadinessBlocker(
                code: 'UI_TEXT_MISSING',
                tab: 'ui-text',
                count: 1,
                message: '1 UI message key(s) are missing',
              ),
              ReadinessBlocker(
                code: 'CATEGORY_TRANSLATION_MISSING',
                tab: 'categories',
                count: 1,
                message: '1 CATEGORY translation(s) missing',
              ),
            ]
          : const [],
    );

List<TranslationItem> _contentFixture() => [
  const TranslationItem(
    entityType: TranslationEntityType.category,
    entityId: 'cat-1',
    entityCode: 'ENGINE',
    field: 'name',
    defaultText: 'Engine',
    text: null,
    status: TranslationStatus.missing,
  ),
  const TranslationItem(
    entityType: TranslationEntityType.item,
    entityId: 'item-1',
    entityCode: 'ENG-OIL',
    field: 'label',
    defaultText: 'Engine oil',
    text: 'زيت المحرك',
    status: TranslationStatus.draft,
  ),
];

const _testLanguage = PlatformLanguage(
  code: _languageCode,
  nativeName: 'العربية',
  direction: 'rtl',
  active: true,
  isDefault: false,
  sortOrder: 2,
  status: 'REVIEW',
  uiMessagesPath: 'i18n/platform_admin/ar.json',
);

class _TestLocaleNotifier extends LocaleController {
  _TestLocaleNotifier(this._initial);

  final Locale _initial;

  @override
  Locale build() => _initial;
}

List<Override> _overrides({
  required FakeWorkspaceTranslationApi api,
  required LanguageReadiness readiness,
  ContentGeneration generation = ContentGeneration.idle,
}) => [
  uiStringsProvider.overrideWithValue(fakeEnUiStrings()),
  platformLocaleProvider.overrideWith(
    () => _TestLocaleNotifier(const Locale('en')),
  ),
  translationApiProvider.overrideWithValue(api),
  platformLanguagesProvider.overrideWith((ref) async => [_testLanguage]),
  translationCoverageProvider.overrideWith(
    (ref) async => const TranslationCoverage(
      languages: ['en', 'ar'],
      namespaces: {'common': CoverageNamespace(total: 3, missing: [])},
    ),
  ),
  readinessProvider.overrideWith((ref, code) async => readiness),
  contentGenerationProvider.overrideWith((ref, code) async => generation),
  languageBacklogProvider.overrideWith(
    (ref, code) async => api.fetchBacklog(code),
  ),
];

Widget _workspaceApp({
  required FakeWorkspaceTranslationApi api,
  required LanguageReadiness readiness,
  ContentGeneration generation = ContentGeneration.idle,
  String? initialTab,
}) {
  return ProviderScope(
    overrides: _overrides(
      api: api,
      readiness: readiness,
      generation: generation,
    ),
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: LanguageWorkspaceScreen(
        languageCode: _languageCode,
        initialTab: initialTab,
      ),
    ),
  );
}

void main() {
  test('PlatformLanguage keeps only native name and lifecycle fields', () {
    final language = PlatformLanguage.fromJson(const {
      'code': 'ar',
      'nativeName': 'العربية',
      'direction': 'rtl',
      'active': true,
      'isDefault': true,
      'sortOrder': 2,
      'status': 'REVIEW',
      'uiMessagesPath': 'i18n/platform_admin/ar.json',
      'uiMessagesHash': 'abc',
      'reviewedAt': '2026-01-01',
      'reviewedBy': 'admin',
    });
    expect(language.displayName, 'العربية');
    expect(language.isDefault, isTrue);
    expect(language.uiMessagesHash, 'abc');
    expect(language.reviewedBy, 'admin');
    expect(language.displayName, isNot('Arabic'));
  });

  test('content translations stay field-keyed without synthesized locales', () {
    final category = PlatformCategory.fromJson(const {
      'id': 'cat-1',
      'code': 'ENGINE',
      'name': 'Engine',
      'translations': {
        'name': {'ar': 'المحرك'},
      },
      'status': 'ACTIVE',
      'sortOrder': 1,
      'active': true,
      'itemCount': 1,
    });
    expect(category.name, 'Engine');
    expect(category.nameEn, 'Engine');
    expect(category.nameAr, 'المحرك');
    expect(category.translations['name']!.containsKey('en'), isFalse);
  });

  test('readiness parses blockers and per-entity coverage', () {
    final readiness = LanguageReadiness.fromJson(const {
      'language': 'ar',
      'status': 'REVIEW',
      'nativeName': 'العربية',
      'direction': 'rtl',
      'isDefault': false,
      'uiMessagesPath': 'i18n/platform_admin/ar.json',
      'readinessPercent': 60,
      'uiMessages': {
        'total': 3,
        'approved': 2,
        'missing': 1,
        'changed': 1,
        'path': 'i18n/platform_admin/ar.json',
        'generationStatus': 'COMPLETED',
      },
      'content': {
        'CATEGORY': {'total': 1, 'approved': 0},
      },
      'blockers': [
        {
          'code': 'CATEGORY_TRANSLATION_MISSING',
          'tab': 'categories',
          'count': 1,
          'message': '1 missing',
        },
      ],
    });
    expect(readiness.readinessPercent, 60);
    expect(readiness.content['CATEGORY']!.missing, 1);
    expect(readiness.blockers.single.tab, 'categories');
    expect(readiness.ready, isFalse);
  });

  testWidgets('Manage opens the language workspace', (tester) async {
    final api = FakeWorkspaceTranslationApi(items: _contentFixture());
    final router = GoRouter(
      initialLocation: '/settings/languages',
      routes: [
        GoRoute(
          path: '/settings/languages',
          builder: (context, state) => const LanguagesScreen(),
        ),
        GoRoute(
          path: '/settings/languages/:code',
          builder: (context, state) => LanguageWorkspaceScreen(
            languageCode: state.pathParameters['code']!,
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(api: api, readiness: _readiness()),
        child: MaterialApp.router(
          locale: const Locale('en'),
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final manage = find.widgetWithText(PlatformPrimaryButton, 'Manage').first;
    await tester.ensureVisible(manage);
    await tester.tap(manage);
    await tester.pumpAndSettle();

    expect(find.byType(LanguageWorkspaceScreen), findsOneWidget);
    expect(find.text('Overview'), findsWidgets);
  });

  testWidgets('workspace shows all ten tabs', (tester) async {
    final api = FakeWorkspaceTranslationApi(items: _contentFixture());
    await tester.pumpWidget(_workspaceApp(api: api, readiness: _readiness()));
    await tester.pumpAndSettle();

    for (final label in const [
      'Overview',
      'App UI Text',
      'Categories',
      'Checklist Items',
      'Option Sets',
      'Option Values',
      'Templates',
      'Document Types',
      'Issue Fields',
      'Publish / Blockers',
    ]) {
      expect(find.text(label), findsWidgets, reason: 'missing tab $label');
    }
  });

  testWidgets('overview renders readiness and blockers', (tester) async {
    final api = FakeWorkspaceTranslationApi(items: _contentFixture());
    await tester.pumpWidget(_workspaceApp(api: api, readiness: _readiness()));
    await tester.pumpAndSettle();

    expect(find.textContaining('60%'), findsWidgets);
    expect(find.text('1 UI message key(s) are missing'), findsOneWidget);
    expect(find.text('CATEGORY'), findsOneWidget);
    expect(find.textContaining('Readiness'), findsWidgets);
  });

  testWidgets('App UI Text tab saves and approves review', (tester) async {
    final api = FakeWorkspaceTranslationApi(items: _contentFixture());
    await tester.pumpWidget(
      _workspaceApp(
        api: api,
        readiness: _readiness(),
        initialTab: LanguageWorkspaceTab.uiText,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('common.button.save'), findsOneWidget);
    final target = find.byKey(
      const ValueKey('ui-text-target-common.button.save'),
    );
    await tester.enterText(target, 'حفظ الآن');
    await tester.pump();
    final save = find.widgetWithText(PlatformPrimaryButton, 'Save review');
    expect(
      tester.widget<PlatformPrimaryButton>(save).onPressed,
      isNotNull,
      reason: 'entering text should enable Save review',
    );
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(api.savedReview['common.button.save'], 'حفظ الآن');

    final approve = find
        .widgetWithText(PlatformSecondaryButton, 'Approve review')
        .last;
    await tester.ensureVisible(approve);
    await tester.tap(approve);
    await tester.pumpAndSettle();
    expect(api.approveCalls, 1);
  });

  testWidgets('content tab edits inline and bulk approves', (tester) async {
    final api = FakeWorkspaceTranslationApi(items: _contentFixture());
    await tester.pumpWidget(
      _workspaceApp(
        api: api,
        readiness: _readiness(),
        initialTab: LanguageWorkspaceTab.categories,
      ),
    );
    await tester.pumpAndSettle();

    final editor = find.byKey(
      const ValueKey('content-edit-CATEGORY|cat-1|name'),
    );
    expect(editor, findsOneWidget);
    await tester.ensureVisible(editor);
    await tester.enterText(editor, 'المحرك');
    final bulk = find.text('Bulk approve');
    await tester.ensureVisible(bulk);
    await tester.tap(bulk);
    await tester.pumpAndSettle();

    expect(api.upserts, isNotEmpty);
    expect(api.upserts.last.entityType, TranslationEntityType.category);
    expect(api.upserts.last.text, 'المحرك');
    expect(api.upserts.last.status, TranslationStatus.approved);
  });

  testWidgets('publish stays disabled while blockers exist', (tester) async {
    final api = FakeWorkspaceTranslationApi(items: _contentFixture());
    await tester.pumpWidget(
      _workspaceApp(
        api: api,
        readiness: _readiness(percent: 60),
        initialTab: LanguageWorkspaceTab.publish,
      ),
    );
    await tester.pumpAndSettle();

    final publish = tester.widget<PlatformPrimaryButton>(
      find.byKey(const ValueKey('languagePublishButton')),
    );
    expect(publish.onPressed, isNull);
    expect(find.text('Publishing is blocked'), findsOneWidget);
  });

  testWidgets('publish is enabled at 100 percent readiness', (tester) async {
    final api = FakeWorkspaceTranslationApi(items: _contentFixture());
    await tester.pumpWidget(
      _workspaceApp(
        api: api,
        readiness: _readiness(percent: 100, withBlockers: false),
        initialTab: LanguageWorkspaceTab.publish,
      ),
    );
    await tester.pumpAndSettle();

    final publish = tester.widget<PlatformPrimaryButton>(
      find.byKey(const ValueKey('languagePublishButton')),
    );
    expect(publish.onPressed, isNotNull);

    final publishButton = find.byKey(const ValueKey('languagePublishButton'));
    await tester.ensureVisible(publishButton);
    await tester.tap(publishButton);
    await tester.pumpAndSettle();
    expect(api.publishCalls, 1);
    expect(find.text('Language published.'), findsOneWidget);
  });
}
