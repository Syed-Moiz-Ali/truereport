import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/components/platform_buttons.dart';
import 'package:platform_admin_app/src/components/platform_toolbar.dart';
import 'package:platform_admin_app/src/features/languages/translation_queue_screen.dart';
import 'package:platform_admin_app/src/platform_config_models.dart'
    hide TranslationCoverage;
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/platform_translations.dart';
import 'support/ui_message_fixtures.dart';

// Local fake only: never imports test/support/fake_platform_api.dart.
// Subclasses the real TranslationApi with the same constructor shape so the
// providers under test are exercised through their real wiring.
class FakeTranslationApi extends TranslationApi {
  FakeTranslationApi({
    List<TranslationItem>? items,
    this._languageStatus = LanguageStatus.draft,
  }) : _items = List<TranslationItem>.of(items ?? const <TranslationItem>[]),
       super(
         ApiClient(
           config: const ApiConfig(baseUrl: '', environment: 'test'),
         ),
         const ApiEndpoints(baseUrl: ''),
       );

  final List<TranslationItem> _items;
  String _languageStatus;

  String get languageStatus => _languageStatus;

  TranslationBacklog _backlog(String code) {
    final grouped = <String, List<TranslationItem>>{};
    for (final item in _items) {
      grouped.putIfAbsent(item.entityType, () => <TranslationItem>[]).add(item);
    }
    final groups = <TranslationBacklogGroup>[];
    var approved = 0;
    for (final entry in grouped.entries) {
      final count = entry.value
          .where((item) => item.status == TranslationStatus.approved)
          .length;
      approved += count;
      groups.add(
        TranslationBacklogGroup(
          entityType: entry.key,
          total: entry.value.length,
          approved: count,
          items: List<TranslationItem>.of(entry.value),
        ),
      );
    }
    final total = _items.length;
    return TranslationBacklog(
      languageCode: code,
      languageStatus: LanguageStatus.normalize(_languageStatus),
      totalRequired: total,
      approvedCount: approved,
      coveragePercent: total == 0 ? 100 : approved / total * 100,
      groups: groups,
    );
  }

  PlatformLanguage _language(String code) => PlatformLanguage(
    code: code,
    nameEn: code == 'zh-Hans' ? 'Chinese (Simplified)' : code,
    nameAr: '',
    nativeName: code == 'zh-Hans' ? '中文' : code,
    direction: 'ltr',
    active: true,
    isDefault: false,
    sortOrder: 3,
    status: _languageStatus,
  );

  @override
  Future<TranslationBacklog> fetchBacklog(String code) async => _backlog(code);

  @override
  Future<TranslationCoverage> fetchCoverage(String code) async {
    final backlog = _backlog(code);
    return TranslationCoverage(
      language: code,
      totalRequired: backlog.totalRequired,
      approvedCount: backlog.approvedCount,
      coveragePercent: backlog.coveragePercent,
      byEntity: {
        for (final group in backlog.groups)
          group.entityType: EntityCoverage(
            total: group.total,
            approved: group.approved,
          ),
      },
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
    if (index >= 0) {
      _items[index] = updated;
    } else {
      _items.add(updated);
    }
    return updated;
  }

  @override
  Future<PlatformLanguage> publishLanguage(String code) async {
    _languageStatus = LanguageStatus.live;
    return _language(code);
  }

  @override
  Future<PlatformLanguage> setLanguageStatus(String code, String status) async {
    _languageStatus = LanguageStatus.normalize(status);
    return _language(code);
  }
}

/// zh-Hans fixture: one missing, one draft with Chinese text, one reviewed.
List<TranslationItem> zhFixture() => <TranslationItem>[
  const TranslationItem(
    entityType: 'CATEGORY',
    entityId: 'cat-eng',
    entityCode: 'ENG',
    field: 'label',
    defaultText: 'Engine',
    text: null,
    status: TranslationStatus.missing,
  ),
  const TranslationItem(
    entityType: 'ITEM',
    entityId: 'item-1',
    entityCode: 'ENG-OIL-01',
    field: 'label',
    defaultText: 'Engine Oil Condition',
    text: '发动机机油状况',
    status: TranslationStatus.draft,
  ),
  const TranslationItem(
    entityType: 'OPTION_SET',
    entityId: 'set-1',
    entityCode: 'CONDITION',
    field: 'name',
    defaultText: 'Condition',
    text: '状况',
    status: TranslationStatus.reviewed,
  ),
];

List<TranslationItem> approvedFixture() => <TranslationItem>[
  const TranslationItem(
    entityType: 'CATEGORY',
    entityId: 'cat-eng',
    entityCode: 'ENG',
    field: 'label',
    defaultText: 'Engine',
    text: '发动机',
    status: TranslationStatus.approved,
  ),
  const TranslationItem(
    entityType: 'ITEM',
    entityId: 'item-1',
    entityCode: 'ENG-OIL-01',
    field: 'label',
    defaultText: 'Engine Oil Condition',
    text: '发动机机油状况',
    status: TranslationStatus.approved,
  ),
];

class _TestLocaleNotifier extends LocaleController {
  _TestLocaleNotifier(this._initial);
  final Locale _initial;

  @override
  Locale build() => _initial;
}

Widget _buildTestApp({
  required FakeTranslationApi fake,
  required String code,
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [uiStringsProvider.overrideWithValue(locale.languageCode == 'ar' ? fakeArUiStrings() : fakeEnUiStrings()), 
      platformLocaleProvider.overrideWith(() => _TestLocaleNotifier(locale)),
      translationApiProvider.overrideWithValue(fake),
      platformLanguagesProvider.overrideWith(
        (ref) async => <PlatformLanguage>[
          const PlatformLanguage(
            code: 'en',
            nameEn: 'English',
            nameAr: 'الإنجليزية',
            nativeName: 'English',
            direction: 'ltr',
            active: true,
            isDefault: true,
            sortOrder: 1,
            status: 'LIVE',
          ),
          PlatformLanguage(
            code: code,
            nameEn: 'Chinese (Simplified)',
            nameAr: '',
            nativeName: '中文',
            direction: 'ltr',
            active: true,
            isDefault: false,
            sortOrder: 3,
            status: fake.languageStatus,
          ),
        ],
      ),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: <Locale>[const Locale('en'), const Locale('ar')],
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      home: TranslationQueueScreen(languageCode: code),
    ),
  );
}

void _setViewport(
  WidgetTester tester, {
  required double width,
  required double height,
}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());
}

PlatformPrimaryButton _publishButton(WidgetTester tester) =>
    tester.widget<PlatformPrimaryButton>(
      find.widgetWithText(PlatformPrimaryButton, 'Publish language'),
    );

/// The queue toolbar search field (the app header owns a second search
/// field, so an unscoped TextField finder is ambiguous).
Finder _toolbarSearch() => find.descendant(
  of: find.byType(PlatformToolbar),
  matching: find.byType(TextField),
);

void main() {
  group('TranslationApi models', () {
    test('status normalization is case-insensitive with safe fallbacks', () {
      expect(
        TranslationStatus.normalize('APPROVED'),
        TranslationStatus.approved,
      );
      expect(TranslationStatus.normalize('Missing'), TranslationStatus.missing);
      expect(TranslationStatus.normalize('bogus'), TranslationStatus.missing);
      expect(LanguageStatus.normalize('live'), LanguageStatus.live);
      expect(LanguageStatus.normalize('bogus'), LanguageStatus.draft);
    });

    test('backlog parses the nested language shape from the contract', () {
      final backlog = TranslationBacklog.fromJson(<String, dynamic>{
        'language': {'code': 'zh-Hans', 'status': 'DRAFT'},
        'totalRequired': 2,
        'approvedCount': 1,
        'coveragePercent': 50,
        'groups': [
          {
            'entityType': 'ITEM',
            'total': 2,
            'approved': 1,
            'items': [
              {
                'entityType': 'ITEM',
                'entityId': 'item-1',
                'entityCode': 'ENG-OIL-01',
                'field': 'label',
                'defaultText': 'Engine Oil Condition',
                'text': '发动机机油状况',
                'status': 'approved',
              },
              {
                'entityType': 'ITEM',
                'entityId': 'item-2',
                'entityCode': 'ENG-OIL-02',
                'field': 'label',
                'defaultText': 'Oil Level',
                'text': null,
                'status': 'MISSING',
              },
            ],
          },
        ],
      });
      expect(backlog.languageCode, 'zh-Hans');
      expect(backlog.languageStatus, LanguageStatus.draft);
      expect(backlog.totalRequired, 2);
      expect(backlog.coveragePercent, 50);
      expect(backlog.groups, hasLength(1));
      expect(backlog.allItems, hasLength(2));
      expect(backlog.allItems.first.text, '发动机机油状况');
      expect(backlog.allItems.first.isApproved, isTrue);
      expect(backlog.allItems.last.isMissing, isTrue);
      expect(backlog.isComplete, isFalse);
    });

    test('coverage parses the byEntity shape from the contract', () {
      final coverage = TranslationCoverage.fromJson(<String, dynamic>{
        'language': 'zh-Hans',
        'totalRequired': 4,
        'approvedCount': 4,
        'coveragePercent': 100,
        'byEntity': {
          'CATEGORY': {'total': 1, 'approved': 1},
          'ITEM': {'total': 3, 'approved': 3},
        },
      });
      expect(coverage.language, 'zh-Hans');
      expect(coverage.byEntity['ITEM']?.approved, 3);
    });
  });

  group('TranslationQueueScreen', () {
    testWidgets('renders backlog with summary, groups and rows', (
      tester,
    ) async {
      _setViewport(tester, width: 1280, height: 900);
      final fake = FakeTranslationApi(items: zhFixture());
      await tester.pumpWidget(_buildTestApp(fake: fake, code: 'zh-Hans'));
      await tester.pumpAndSettle();

      expect(find.text('Translation queue'), findsOneWidget);
      expect(find.text('中文 · Draft · 0%'), findsOneWidget);
      // Summary cards (labels also appear on row status chips).
      expect(find.text('Missing'), findsWidgets);
      expect(find.text('Draft'), findsWidgets);
      expect(find.text('Reviewed'), findsWidgets);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      // Dynamic group headers + rows.
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Items'), findsOneWidget);
      expect(find.text('Engine'), findsWidgets);
      expect(find.text('Engine Oil Condition'), findsOneWidget);
      expect(find.text('发动机机油状况'), findsOneWidget);
      // Publish gate: disabled with the blocked hint.
      expect(_publishButton(tester).onPressed, isNull);
      expect(
        find.text('Complete all required translations to publish.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('filters by entity type, search and missing-only', (
      tester,
    ) async {
      _setViewport(tester, width: 1280, height: 900);
      final fake = FakeTranslationApi(items: zhFixture());
      await tester.pumpWidget(_buildTestApp(fake: fake, code: 'zh-Hans'));
      await tester.pumpAndSettle();

      // Entity-type filter: show only ITEM rows.
      await tester.tap(find.text('All').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Items').last);
      await tester.pumpAndSettle();
      expect(find.text('Engine Oil Condition'), findsOneWidget);
      expect(find.text('Condition'), findsNothing);

      // Back to All, then search for Chinese text.
      await tester.tap(find.text('Items').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('All').last);
      await tester.pumpAndSettle();
      await tester.enterText(_toolbarSearch(), '发动');
      await tester.pumpAndSettle();
      expect(find.text('Engine Oil Condition'), findsOneWidget);
      expect(find.text('Condition'), findsNothing);

      // Missing-only shows just the untranslated row.
      await tester.enterText(_toolbarSearch(), '');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Missing only'));
      await tester.pumpAndSettle();
      expect(find.text('Engine'), findsWidgets);
      expect(find.text('Engine Oil Condition'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('edits a translation with next/previous navigation', (
      tester,
    ) async {
      _setViewport(tester, width: 1280, height: 900);
      final fake = FakeTranslationApi(items: zhFixture());
      await tester.pumpWidget(_buildTestApp(fake: fake, code: 'zh-Hans'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();
      expect(find.text('Edit translation'), findsOneWidget);
      expect(find.text('Engine'), findsWidgets);

      // Next moves through the filtered list without leaving the screen.
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Engine Oil Condition'), findsWidgets);

      // Save a new translation as Reviewed.
      await tester.enterText(find.byType(TextFormField), '发动机机油状况与液位');
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reviewed').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pumpAndSettle();
      final saved = await fake.fetchBacklog('zh-Hans');
      final item = saved.allItems.firstWhere(
        (entry) => entry.entityId == 'item-1',
      );
      expect(item.text, '发动机机油状况与液位');
      expect(item.status, TranslationStatus.reviewed);

      // Previous navigates back.
      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();
      expect(find.text('Engine'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('bulk approves selected translations', (tester) async {
      _setViewport(tester, width: 1280, height: 900);
      final fake = FakeTranslationApi(items: zhFixture());
      await tester.pumpWidget(_buildTestApp(fake: fake, code: 'zh-Hans'));
      await tester.pumpAndSettle();

      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsNWidgets(3));
      // Select the two rows that already have text.
      await tester.tap(checkboxes.at(1));
      await tester.pump();
      await tester.ensureVisible(checkboxes.at(2));
      await tester.pumpAndSettle();
      await tester.tap(checkboxes.at(2));
      await tester.pump();
      await tester.ensureVisible(find.text('Approve selected'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve selected'));
      await tester.pumpAndSettle();

      final backlog = await fake.fetchBacklog('zh-Hans');
      expect(backlog.approvedCount, 2);
      expect(backlog.isComplete, isFalse);
      // Still gated: the missing row blocks publishing.
      expect(_publishButton(tester).onPressed, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('publish is enabled at 100% and moves language to LIVE', (
      tester,
    ) async {
      _setViewport(tester, width: 1280, height: 900);
      final fake = FakeTranslationApi(
        items: approvedFixture(),
        languageStatus: LanguageStatus.review,
      );
      await tester.pumpWidget(_buildTestApp(fake: fake, code: 'zh-Hans'));
      await tester.pumpAndSettle();

      expect(find.text('中文 · In review · 100%'), findsOneWidget);
      expect(
        find.text('Complete all required translations to publish.'),
        findsNothing,
      );
      expect(_publishButton(tester).onPressed, isNotNull);

      await tester.tap(
        find.widgetWithText(PlatformPrimaryButton, 'Publish language'),
      );
      await tester.pumpAndSettle();
      // Confirm dialog (destructive/sensitive action confirmation).
      await tester.tap(find.widgetWithText(FilledButton, 'Publish language'));
      await tester.pumpAndSettle();

      expect(fake.languageStatus, LanguageStatus.live);
      expect(find.text('中文 · Live · 100%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('zh-Hans DRAFT to LIVE end to end', (tester) async {
      _setViewport(tester, width: 1280, height: 900);
      final fake = FakeTranslationApi(items: zhFixture());
      await tester.pumpWidget(_buildTestApp(fake: fake, code: 'zh-Hans'));
      await tester.pumpAndSettle();

      expect(find.text('中文 · Draft · 0%'), findsOneWidget);
      expect(_publishButton(tester).onPressed, isNull);

      // Bulk approve everything that already has Chinese text.
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.at(0));
      await tester.pump();
      await tester.tap(checkboxes.at(1));
      await tester.pump();
      await tester.ensureVisible(checkboxes.at(2));
      await tester.pumpAndSettle();
      await tester.tap(checkboxes.at(2));
      await tester.pump();
      await tester.ensureVisible(find.text('Approve selected'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve selected'));
      await tester.pumpAndSettle();
      expect((await fake.fetchBacklog('zh-Hans')).approvedCount, 2);
      expect(_publishButton(tester).onPressed, isNull);

      // Complete the missing row through the queue editor.
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '发动机');
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approved').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect((await fake.fetchBacklog('zh-Hans')).approvedCount, 3);
      expect(_publishButton(tester).onPressed, isNotNull);

      final publish = find.widgetWithText(
        PlatformPrimaryButton,
        'Publish language',
      );
      await tester.ensureVisible(publish);
      await tester.pumpAndSettle();
      await tester.tap(publish);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Publish language'));
      await tester.pumpAndSettle();

      expect(fake.languageStatus, LanguageStatus.live);
      expect(find.text('中文 · Live · 100%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('export copies missing translations with confirmation', (
      tester,
    ) async {
      _setViewport(tester, width: 1280, height: 900);
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard =
                (call.arguments as Map<String, dynamic>)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final fake = FakeTranslationApi(items: zhFixture());
      await tester.pumpWidget(_buildTestApp(fake: fake, code: 'zh-Hans'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();
      expect(clipboard, contains('cat-eng'));
      expect(clipboard, contains('"language": "zh-Hans"'));
      expect(find.text('Export: Done'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('compact and RTL render without overflow', (tester) async {
      _setViewport(tester, width: 360, height: 900);
      final fake = FakeTranslationApi(items: zhFixture());
      await tester.pumpWidget(
        _buildTestApp(fake: fake, code: 'zh-Hans', locale: const Locale('ar')),
      );
      await tester.pumpAndSettle();

      // Title is localized (Arabic here); data rows are locale-independent.
      expect(find.text('Engine Oil Condition'), findsOneWidget);
      expect(find.text('发动机机油状况'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('wide layout renders without overflow', (tester) async {
      _setViewport(tester, width: 1280, height: 800);
      final fake = FakeTranslationApi(items: zhFixture());
      await tester.pumpWidget(_buildTestApp(fake: fake, code: 'zh-Hans'));
      await tester.pumpAndSettle();

      expect(find.text('Translation queue'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

}
