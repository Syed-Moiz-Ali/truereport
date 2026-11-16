import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/features/languages/translation_queue_screen.dart';
import 'package:platform_admin_app/src/platform_config_models.dart'
    hide TranslationCoverage;
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/platform_translations.dart';

import 'support/ui_message_fixtures.dart';

class FakeTranslationApi extends TranslationApi {
  FakeTranslationApi({List<TranslationItem>? items})
    : _items = List<TranslationItem>.of(items ?? const <TranslationItem>[]),
      super(
        ApiClient(
          config: const ApiConfig(baseUrl: '', environment: 'test'),
        ),
        const ApiEndpoints(baseUrl: ''),
      );

  final List<TranslationItem> _items;
  final List<TranslationItem> upserts = [];

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
      languageStatus: LanguageStatus.live,
      totalRequired: total,
      approvedCount: approved,
      coveragePercent: total == 0 ? 100 : approved / total * 100,
      groups: groups,
    );
  }

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
    upserts.add(updated);
    if (index >= 0) {
      _items[index] = updated;
    } else {
      _items.add(updated);
    }
    return updated;
  }
}

List<TranslationItem> zhFixture() => <TranslationItem>[
  const TranslationItem(
    entityType: 'CATEGORY',
    entityId: 'cat-eng',
    entityCode: 'ENG',
    field: 'name',
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
    text: '发动机油状况',
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
    overrides: [
      uiStringsProvider.overrideWithValue(fakeEnUiStrings()),
      platformLocaleProvider.overrideWith(() => _TestLocaleNotifier(locale)),
      translationApiProvider.overrideWithValue(fake),
      platformLanguagesProvider.overrideWith(
        (ref) async => <PlatformLanguage>[
          const PlatformLanguage(
            code: 'en',
            nativeName: 'English',
            direction: 'ltr',
            active: true,
            isDefault: true,
            sortOrder: 1,
            status: 'LIVE',
          ),
          PlatformLanguage(
            code: code,
            nativeName: code,
            direction: 'ltr',
            active: true,
            isDefault: false,
            sortOrder: 3,
            status: 'LIVE',
          ),
        ],
      ),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: TranslationQueueScreen(languageCode: code),
    ),
  );
}

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
        'language': {'code': 'zh-Hans', 'status': 'LIVE'},
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
                'text': '发动机油状况',
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
      expect(backlog.totalRequired, 2);
      expect(backlog.approvedCount, 1);
      expect(backlog.isComplete, isFalse);
      expect(backlog.groups.single.items.last.isMissing, isTrue);
    });
  });

  testWidgets('queue lists dynamic content and has no publish action', (
    tester,
  ) async {
    final fake = FakeTranslationApi(items: zhFixture());
    await tester.pumpWidget(_buildTestApp(fake: fake, code: 'zh-Hans'));
    await tester.pumpAndSettle();

    expect(find.text('Engine'), findsOneWidget);
    expect(find.text('Engine Oil Condition'), findsOneWidget);
    expect(find.text('Publish language'), findsNothing);
  });

  testWidgets('editor saves a manual dynamic translation', (tester) async {
    final fake = FakeTranslationApi(items: zhFixture());
    await tester.pumpWidget(_buildTestApp(fake: fake, code: 'zh-Hans'));
    await tester.pumpAndSettle();

    final edit = find.byIcon(Icons.edit_outlined).first;
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();

    final field = find.byType(TextField).last;
    await tester.enterText(field, '引擎');
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    expect(fake.upserts, isNotEmpty);
    expect(fake.upserts.last.text, '引擎');
  });
}
