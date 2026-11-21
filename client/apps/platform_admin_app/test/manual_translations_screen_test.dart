import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/components/platform_buttons.dart';
import 'package:platform_admin_app/src/components/platform_chips.dart';
import 'package:platform_admin_app/src/features/languages/manual_translation_models.dart';
import 'package:platform_admin_app/src/features/languages/manual_translation_providers.dart';
import 'package:platform_admin_app/src/features/languages/manual_translations_screen.dart';
import 'package:platform_admin_app/src/platform_config_api.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/reference_status_lookup.dart';
import 'package:reference_data/reference_data.dart';

import 'reference_test_support.dart';

/// The screen's save path: an empty/unchanged row is not saveable, a save
/// writes the expected identity and body, updates the row locally, and shows
/// the success snackbar.
void main() {
  testWidgets('manual translation save writes and updates the row', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final api = _FakeConfigApi();
    const query = ManualTranslationQuery(lang: 'es');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          uiStringsProvider.overrideWithValue(loadReferenceStrings()),
          platformConfigApiProvider.overrideWithValue(api),
          platformLanguagesProvider.overrideWith(
            (ref) async => const <PlatformLanguage>[
              PlatformLanguage(
                code: 'es',
                nativeName: 'Español',
                direction: 'ltr',
                active: true,
                isDefault: false,
                sortOrder: 1,
                status: 'LIVE',
              ),
            ],
          ),
          enumsProvider(contentTypeEnum).overrideWith(
            (ref) async => const <ReferenceRecord>[
              ReferenceRecord(
                code: 'ITEM',
                labelKey: 'languageWorkspace.tab.checklistItems',
              ),
            ],
          ),
          statusesProvider('workshop')
              .overrideWith((ref) async => const <ReferenceRecord>[]),
          statusesProvider('checklist')
              .overrideWith((ref) async => const <ReferenceRecord>[]),
          statusesProvider('health')
              .overrideWith((ref) async => const <ReferenceRecord>[]),
          statusesProvider('document')
              .overrideWith((ref) async => const <ReferenceRecord>[]),
          statusesProvider('chip')
              .overrideWith((ref) async => const <ReferenceRecord>[]),
          manualTranslationSummaryProvider('es').overrideWith(
            (ref) async => const ManualTranslationSummary(total: 1, missing: 1),
          ),
          manualTranslationsPageProvider(query).overrideWith(
            (ref) async => const ManualTranslationPage(
              lang: 'es',
              total: 1,
              page: 0,
              size: 50,
              items: <ManualTranslationUnit>[
                ManualTranslationUnit(
                  entityType: 'ITEM',
                  entityId: 'item-1',
                  field: 'label',
                  sourceText: 'Brake pad',
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(
          supportedLocales: [Locale('en')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: ManualTranslationsScreen(languageCode: 'es'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byKey(
      const ValueKey('manual-translation-ITEM/item-1/label'),
    );
    expect(field, findsOneWidget);
    expect(find.text('Brake pad'), findsOneWidget);

    PlatformSecondaryButton saveButton() =>
        tester.widget(find.widgetWithText(PlatformSecondaryButton, 'Save'));

    expect(saveButton().onPressed, isNull, reason: 'empty row is not saveable');

    await tester.enterText(field, 'Pastilla de freno');
    await tester.pump();
    expect(saveButton().onPressed, isNotNull);

    String fieldText() => tester
        .widget<EditableText>(
          find.descendant(of: field, matching: find.byType(EditableText)),
        )
        .controller
        .text;

    // Unsaved text survives moving between the All and Missing filters.
    await tester.tap(find.widgetWithText(PlatformFilterChip, 'Missing'));
    await tester.pumpAndSettle();
    expect(fieldText(), 'Pastilla de freno');
    await tester.tap(find.widgetWithText(PlatformFilterChip, 'All'));
    await tester.pumpAndSettle();
    expect(fieldText(), 'Pastilla de freno');

    await tester.tap(find.widgetWithText(PlatformSecondaryButton, 'Save'));
    await tester.pumpAndSettle();

    expect(api.calls, hasLength(1));
    expect(api.calls.single.entityType, 'ITEM');
    expect(api.calls.single.entityId, 'item-1');
    expect(api.calls.single.field, 'label');
    expect(api.calls.single.lang, 'es');
    expect(api.calls.single.text, 'Pastilla de freno');
    expect(find.text('Translation saved.'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    expect(
      saveButton().onPressed,
      isNull,
      reason: 'a saved row is unchanged until edited again',
    );
  });

  testWidgets('save failure keeps the text and shows the ApiFailure message', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final api = _FakeConfigApi(
      failure: const ApiFailure(
        code: 'VALIDATION_FAILED',
        messageKey: 'error.validation',
        statusCode: 422,
      ),
    );
    const query = ManualTranslationQuery(lang: 'es');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          uiStringsProvider.overrideWithValue(loadReferenceStrings()),
          platformConfigApiProvider.overrideWithValue(api),
          platformLanguagesProvider.overrideWith(
            (ref) async => const <PlatformLanguage>[
              PlatformLanguage(
                code: 'es',
                nativeName: 'Español',
                direction: 'ltr',
                active: true,
                isDefault: false,
                sortOrder: 1,
                status: 'LIVE',
              ),
            ],
          ),
          statusesProvider('workshop')
              .overrideWith((ref) async => const <ReferenceRecord>[]),
          statusesProvider('checklist')
              .overrideWith((ref) async => const <ReferenceRecord>[]),
          statusesProvider('health')
              .overrideWith((ref) async => const <ReferenceRecord>[]),
          statusesProvider('document')
              .overrideWith((ref) async => const <ReferenceRecord>[]),
          statusesProvider('chip')
              .overrideWith((ref) async => const <ReferenceRecord>[]),
          manualTranslationSummaryProvider('es').overrideWith(
            (ref) async => const ManualTranslationSummary(total: 1, missing: 1),
          ),
          manualTranslationsPageProvider(query).overrideWith(
            (ref) async => const ManualTranslationPage(
              lang: 'es',
              total: 1,
              page: 0,
              size: 50,
              items: <ManualTranslationUnit>[
                ManualTranslationUnit(
                  entityType: 'ITEM',
                  entityId: 'item-1',
                  field: 'label',
                  sourceText: 'Brake pad',
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(
          supportedLocales: [Locale('en')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: ManualTranslationsScreen(languageCode: 'es'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byKey(
      const ValueKey('manual-translation-ITEM/item-1/label'),
    );
    await tester.enterText(field, 'Pastilla de freno');
    await tester.pump();
    await tester.tap(find.widgetWithText(PlatformSecondaryButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('error.validation'), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(of: field, matching: find.byType(EditableText)),
          )
          .controller
          .text,
      'Pastilla de freno',
      reason: 'a failed save must not discard the typed translation',
    );
  });
}

class _FakeConfigApi extends PlatformConfigApi {
  _FakeConfigApi({this.failure})
    : super(
        ApiClient(
          config: const ApiConfig(
            baseUrl: 'http://localhost:8080',
            environment: 'test',
          ),
        ),
        const ApiEndpoints(baseUrl: 'http://localhost:8080'),
      );

  final ApiFailure? failure;
  final List<_Write> calls = [];

  @override
  Future<ManualTranslationPage> contentUnits({
    required String lang,
    String? entityType,
    String filter = ManualTranslationFilter.all,
    String query = '',
    int page = 0,
    int size = 50,
  }) async {
    // The filter/page is a view over the same missing row in this test.
    return const ManualTranslationPage(
      lang: 'es',
      total: 1,
      page: 0,
      size: 50,
      items: <ManualTranslationUnit>[
        ManualTranslationUnit(
          entityType: 'ITEM',
          entityId: 'item-1',
          field: 'label',
          sourceText: 'Brake pad',
        ),
      ],
    );
  }

  @override
  Future<ManualTranslationUnit> writeContentTranslation({
    required String entityType,
    required String entityId,
    required String field,
    required String lang,
    required String text,
  }) async {
    calls.add(
      _Write(
        entityType: entityType,
        entityId: entityId,
        field: field,
        lang: lang,
        text: text,
      ),
    );
    if (failure != null) throw failure!;
    return ManualTranslationUnit(
      entityType: entityType,
      entityId: entityId,
      field: field,
      sourceText: 'Brake pad',
      text: text,
      status: 'DRAFT',
      origin: 'AUTHORED',
    );
  }
}

class _Write {
  const _Write({
    required this.entityType,
    required this.entityId,
    required this.field,
    required this.lang,
    required this.text,
  });

  final String entityType;
  final String entityId;
  final String field;
  final String lang;
  final String text;
}
