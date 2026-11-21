import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:platform_admin_app/src/features/localization/translation_issue_dialog.dart';
import 'package:platform_admin_app/src/features/localization/translation_review_models.dart';
import 'package:platform_admin_app/src/features/localization/translation_review_providers.dart';
import 'package:platform_admin_app/src/platform_config_api.dart';
import 'package:platform_admin_app/src/platform_providers.dart';

/// The review actions hit the documented endpoints, and the 409 dialog lists
/// the backend's issue rows instead of a generic failure.
void main() {
  group('review actions', () {
    late _FakeReviewApi api;
    late ProviderContainer container;

    setUp(() {
      api = _FakeReviewApi();
      container = ProviderContainer(
        overrides: [platformConfigApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);
    });

    test('approve posts APPROVE for the row identity', () async {
      await container.read(translationReviewActionsProvider).approve(_item);

      expect(api.calls.single.action, 'APPROVE');
      expect(api.calls.single.lang, 'es');
      expect(api.calls.single.field, 'labelEn');
      expect(api.calls.single.body, isNull);
      expect(api.calls.single.note, isNull);
    });

    test('edit posts EDIT with the trimmed body', () async {
      await container
          .read(translationReviewActionsProvider)
          .edit(_item, '  Freno desgastado  ');

      expect(api.calls.single.action, 'EDIT');
      expect(api.calls.single.body, 'Freno desgastado');
    });

    test('reject posts REJECT with the note', () async {
      await container
          .read(translationReviewActionsProvider)
          .reject(_item, 'Wrong tone');

      expect(api.calls.single.action, 'REJECT');
      expect(api.calls.single.note, 'Wrong tone');
    });

    test(
      'the summary is re-fetched from the server after a decision',
      () async {
        await container.read(translationReviewSummaryProvider('es').future);
        expect(api.summaryCalls, 1);

        await container.read(translationReviewActionsProvider).approve(_item);
        await container.read(translationReviewSummaryProvider('es').future);

        expect(
          api.summaryCalls,
          2,
          reason:
              'the decision must reconcile with the server, not a local list',
        );
      },
    );
  });

  test('TranslationIssue parses the ProblemDetails errors array', () {
    final issues = TranslationIssue.from(_failure);

    expect(issues, hasLength(1));
    expect(issues.single.entityType, 'ITEM');
    expect(issues.single.entityId, 'item-1');
    expect(issues.single.field, 'labelEn');
    expect(issues.single.lang, 'es');
    expect(issues.single.reason, 'Machine translation needs review');
  });

  testWidgets('the 409 dialog lists entity, field, language and reason', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [uiStringsProvider.overrideWithValue(_strings())],
        child: MaterialApp(
          supportedLocales: const <Locale>[Locale('en')],
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          builder: (context, child) => UiStringsScope(
            strings: UiStrings.fromRemoteEnglish(),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const Key('open-issues'),
                  onPressed: () =>
                      showTranslationIssuesDialog(context, _failure),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-issues')));
    await tester.pumpAndSettle();

    expect(find.textContaining('ITEM · item-1 · labelEn · es'), findsOneWidget);
    expect(find.text('Machine translation needs review'), findsOneWidget);
    expect(
      find.byKey(const Key('translation-issues-open-review')),
      findsOneWidget,
    );

    // The queue link needs a GoRouter; assert the affordance and close instead.
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Close'), findsNothing);
  });
}

const TranslationReviewItem _item = TranslationReviewItem(
  entityType: 'ITEM',
  entityId: 'item-1',
  field: 'labelEn',
  lang: 'es',
  body: 'Pastillas desgastadas',
  origin: 'MACHINE',
  status: 'PENDING_REVIEW',
  provider: 'stub-mt',
  sourceText: 'Worn brake pads',
  safetyCritical: true,
  reviewNote: '',
);

const ApiFailure _failure = ApiFailure(
  code: 'TRANSLATION_REVIEW_REQUIRED',
  messageKey: 'error.translation.reviewRequired',
  statusCode: 409,
  errors: <Map<String, dynamic>>[
    <String, dynamic>{
      'entityType': 'ITEM',
      'entityId': 'item-1',
      'field': 'labelEn',
      'lang': 'es',
      'reason': 'Machine translation needs review',
    },
  ],
);

UiMessageStrings _strings() => const UiMessageStrings(
  catalogs: <String, Map<String, Map<String, String>>>{
    'en': <String, Map<String, String>>{
      'common': <String, String>{'button.close': 'Close'},
      'platform_admin': <String, String>{
        'page.translationReview.blocked.title': 'Translation review required',
        'page.translationReview.blocked.body': 'These safety-critical translations must be reviewed before publishing.',
        'page.translationReview.blocked.open': 'Open review queue',
        'page.translationReview.issue.more': 'and {count} more',
      },
    },
  },
  activeLanguage: 'en',
  defaultLanguage: 'en',
);

class _FakeReviewApi extends PlatformConfigApi {
  _FakeReviewApi()
    : super(
        ApiClient(
          config: const ApiConfig(
            baseUrl: 'http://localhost',
            environment: 'test',
          ),
        ),
        const ApiEndpoints(baseUrl: 'http://localhost'),
      );

  final List<
    ({String action, String? body, String? note, String lang, String field})
  >
  calls = [];
  int summaryCalls = 0;

  @override
  Future<List<TranslationReviewItem>> contentReview({
    required String lang,
    String? state,
    int page = 0,
    int size = 50,
  }) async => const <TranslationReviewItem>[_item];

  @override
  Future<TranslationReviewSummary> contentReviewSummary(String lang) async {
    summaryCalls += 1;
    return const TranslationReviewSummary(
      lang: 'es',
      states: <String, int>{'PENDING_REVIEW': 3, 'REVIEWED': 1, 'STALE': 0},
      safetyCriticalPendingReview: 1,
      safetyCriticalBlocked: 1,
    );
  }

  @override
  Future<TranslationReviewItem> reviewContent({
    required String entityType,
    required String entityId,
    required String field,
    required String lang,
    required String action,
    String? body,
    String? note,
  }) async {
    calls.add((
      action: action,
      body: body,
      note: note,
      lang: lang,
      field: field,
    ));
    return _item;
  }
}
