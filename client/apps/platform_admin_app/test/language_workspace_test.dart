import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
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
  final List<TranslationItem> upserts = [];

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
      languageStatus: LanguageStatus.live,
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
}

LanguageReadiness _readiness({int percent = 60}) => LanguageReadiness(
  language: _languageCode,
  status: 'LIVE',
  nativeName: 'العربية',
  direction: 'rtl',
  isDefault: false,
  uiMessagesPath: 'platform_admin/ar.json',
  readinessPercent: percent,
  uiMessages: const UiMessageCoverage(
    total: 3,
    approved: 2,
    missing: 1,
    changed: 1,
    path: 'platform_admin/ar.json',
    generationStatus: '',
  ),
  content: const {
    'CATEGORY': EntityReadiness(total: 1, approved: 0),
    'ITEM': EntityReadiness(total: 2, approved: 1),
  },
  blockers: const [
    ReadinessBlocker(
      code: 'CATEGORY_TRANSLATION_MISSING',
      tab: 'categories',
      count: 1,
      message: '1 CATEGORY translation(s) missing',
    ),
  ],
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
  status: 'LIVE',
);

UiMessageManifest _manifest() => const UiMessageManifest(
  defaultLanguage: 'en',
  namespaceVersions: {'platform_admin': 1, 'common': 1},
  languages: [
    UiMessageLanguage(
      code: 'en',
      direction: 'ltr',
      nativeName: 'English',
      path: 'platform_admin/en.json',
      totalKeys: 3,
    ),
  ],
);

class _TestLocaleNotifier extends LocaleController {
  _TestLocaleNotifier(this._initial);

  final Locale _initial;

  @override
  Locale build() => _initial;
}

List<Override> _overrides({
  required FakeWorkspaceTranslationApi api,
  LanguageReadiness? readiness,
}) => [
  uiStringsProvider.overrideWithValue(fakeEnUiStrings()),
  platformLocaleProvider.overrideWith(
    () => _TestLocaleNotifier(const Locale('en')),
  ),
  translationApiProvider.overrideWithValue(api),
  platformLanguagesProvider.overrideWith((ref) async => [_testLanguage]),
  platformUiManifestProvider.overrideWithValue(_manifest()),
  translationCoverageProvider.overrideWith(
    (ref) async => const TranslationCoverage(
      languages: ['en', 'ar'],
      namespaces: {'common': CoverageNamespace(total: 3, missing: [])},
    ),
  ),
  if (readiness != null)
    readinessProvider.overrideWith((ref, code) async => readiness),
  languageBacklogProvider.overrideWith(
    (ref, code) async => api.fetchBacklog(code),
  ),
];

Widget _workspaceApp({
  required FakeWorkspaceTranslationApi api,
  LanguageReadiness? readiness,
  String? initialTab,
}) {
  return ProviderScope(
    overrides: _overrides(api: api, readiness: readiness ?? _readiness()),
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
  test('PlatformLanguage keeps native name fields', () {
    final language = PlatformLanguage.fromJson(const {
      'code': 'ar',
      'nativeName': 'العربية',
      'direction': 'rtl',
      'active': true,
      'isDefault': true,
      'sortOrder': 2,
      'status': 'LIVE',
    });
    expect(language.displayName, 'العربية');
    expect(language.isDefault, isTrue);
  });

  test('readiness parses blockers and per-entity coverage', () {
    final readiness = LanguageReadiness.fromJson(const {
      'language': 'ar',
      'status': 'LIVE',
      'nativeName': 'العربية',
      'direction': 'rtl',
      'isDefault': false,
      'uiMessagesPath': 'platform_admin/ar.json',
      'readinessPercent': 60,
      'uiMessages': {
        'total': 3,
        'approved': 2,
        'missing': 1,
        'changed': 1,
        'path': 'platform_admin/ar.json',
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
  });

  testWidgets('registry shows manifest languages without Add language', (
    tester,
  ) async {
    final api = FakeWorkspaceTranslationApi(items: _contentFixture());
    final router = GoRouter(
      initialLocation: '/settings/languages',
      routes: [
        GoRoute(
          path: '/settings/languages',
          builder: (context, state) => const LanguagesScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(api: api),
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

    expect(find.text('English'), findsWidgets);
    expect(find.text('Add language'), findsNothing);
  });

  testWidgets('workspace shows only dynamic content tabs', (tester) async {
    final api = FakeWorkspaceTranslationApi(items: _contentFixture());
    await tester.pumpWidget(_workspaceApp(api: api));
    await tester.pumpAndSettle();

    for (final label in const [
      'Overview',
      'Categories',
      'Checklist Items',
      'Option Sets',
      'Option Values',
      'Templates',
      'Document Types',
      'Issue Fields',
    ]) {
      expect(find.text(label), findsWidgets, reason: 'missing tab $label');
    }
    expect(find.text('App UI Text'), findsNothing);
    expect(find.text('Publish / Blockers'), findsNothing);
  });

  testWidgets('overview renders readiness and blockers', (tester) async {
    final api = FakeWorkspaceTranslationApi(items: _contentFixture());
    await tester.pumpWidget(_workspaceApp(api: api));
    await tester.pumpAndSettle();

    expect(find.text('1 CATEGORY translation(s) missing'), findsOneWidget);
    expect(find.text('Categories'), findsWidgets);
  });

  testWidgets('content tab edits inline and bulk approves', (tester) async {
    final api = FakeWorkspaceTranslationApi(items: _contentFixture());
    await tester.pumpWidget(
      _workspaceApp(api: api, initialTab: LanguageWorkspaceTab.categories),
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
}
