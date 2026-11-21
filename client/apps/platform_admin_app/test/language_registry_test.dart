import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client/api_client.dart';
import 'package:auth/auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/components/platform_buttons.dart';
import 'package:platform_admin_app/src/features/languages/language_form_rules.dart';
import 'package:platform_admin_app/src/features/languages/language_workspace_screen.dart';
import 'package:platform_admin_app/src/features/languages/languages_screen.dart';
import 'package:platform_admin_app/src/platform_config_api.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:reference_data/reference_data.dart';

import 'reference_test_support.dart';

/// Add-language contract, local validation, dialog submit (409 + navigation)
/// and the retire action on the language workspace.
void main() {
  group('registry API contract', () {
    test('createLanguage posts the exact body to the languages path', () async {
      final adapter = _ScriptedAdapter(
        (_) => _json(const <String, dynamic>{
          'code': 'de',
          'nativeName': 'Deutsch',
          'direction': 'rtl',
          'active': true,
          'isDefault': false,
          'sortOrder': 4,
          'status': 'DRAFT',
        }, 201),
      );
      final api = _configApi(adapter);

      final created = await api.createLanguage(
        code: 'de',
        nativeName: 'Deutsch',
        direction: 'rtl',
      );

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/api/v1/platform/i18n/languages');
      expect(request.data, const <String, dynamic>{
        'code': 'de',
        'nativeName': 'Deutsch',
        'direction': 'rtl',
      });
      expect(created.code, 'de');
      expect(created.nativeName, 'Deutsch');
      expect(created.direction, 'rtl');
      expect(created.status, 'DRAFT');
    });

    test('retireLanguage DELETEs the language path', () async {
      final adapter = _ScriptedAdapter(
        (_) => _json(const <String, dynamic>{
          'code': 'de',
          'nativeName': 'Deutsch',
          'direction': 'ltr',
          'active': false,
          'isDefault': false,
          'sortOrder': 4,
          'status': 'RETIRED',
        }),
      );
      final api = _configApi(adapter);

      final retired = await api.retireLanguage('de');

      final request = adapter.requests.single;
      expect(request.method, 'DELETE');
      expect(request.path, '/api/v1/platform/i18n/languages/de');
      expect(retired.status, 'RETIRED');
      expect(retired.active, isFalse);
      expect(retired.isRetired, isTrue);
    });

    test('a live language surfaces the 409 problem code', () async {
      final adapter = _ScriptedAdapter(
        (_) => _json(const <String, dynamic>{
          'code': 'LANGUAGE_EXISTS',
          'messageKey': 'error.conflict',
          'detail': 'Language is already live',
          'status': 409,
        }, 409),
      );
      final api = _configApi(adapter);

      await expectLater(
        api.createLanguage(code: 'de', nativeName: 'Deutsch', direction: 'ltr'),
        throwsA(
          isA<ApiFailure>()
              .having((failure) => failure.code, 'code', 'LANGUAGE_EXISTS')
              .having((failure) => failure.statusCode, 'status', 409),
        ),
      );
    });
  });

  group('local language validation', () {
    final strings = loadReferenceStrings();

    test('accepts lowercase BCP-47 tags', () {
      expect(validateLanguageCode(strings, 'de'), isNull);
      expect(validateLanguageCode(strings, 'pt-br'), isNull);
      expect(validateLanguageCode(strings, 'zh-hant-tw'), isNull);
    });

    test('normalizes casing and trims before validating', () {
      expect(normalizeLanguageCode('  DE '), 'de');
      expect(validateLanguageCode(strings, ' DE '), isNull);
    });

    test('rejects empty, malformed and default codes', () {
      expect(
        validateLanguageCode(strings, ''),
        strings.tKey(PlatformAdminKeys.languagesAddErrorCodeRequired),
      );
      expect(
        validateLanguageCode(strings, 'd'),
        strings.tKey(PlatformAdminKeys.languagesAddErrorCodeInvalid),
      );
      expect(
        validateLanguageCode(strings, 'de_DE'),
        strings.tKey(PlatformAdminKeys.languagesAddErrorCodeInvalid),
      );
      expect(
        validateLanguageCode(strings, 'de--de'),
        strings.tKey(PlatformAdminKeys.languagesAddErrorCodeInvalid),
      );
      expect(
        validateLanguageCode(strings, 'de-DE'),
        isNull,
        reason: 'casing is normalized before validation; de-DE is valid',
      );
      expect(
        validateLanguageCode(strings, 'en'),
        strings.tKey(PlatformAdminKeys.languagesAddErrorCodeDefault),
      );
    });

    test('native name must not be blank', () {
      expect(
        validateLanguageNativeName(strings, '   '),
        strings.tKey(PlatformAdminKeys.languagesAddErrorNameRequired),
      );
      expect(validateLanguageNativeName(strings, 'Deutsch'), isNull);
    });
  });

  testWidgets('add language posts the dialog values and opens the workspace', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final api = _FakeConfigApi();
    await tester.pumpWidget(
      _app(
        api: api,
        router: GoRouter(
          initialLocation: '/settings/languages',
          routes: [
            GoRoute(
              path: '/settings/languages',
              builder: (context, state) => const LanguagesScreen(),
            ),
            GoRoute(
              path: '/settings/languages/:code',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: Text('workspace-${state.pathParameters['code']}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn-add-language')));
    await tester.pumpAndSettle();

    final codeField = find.byKey(const Key('add-language-code'));
    expect(codeField, findsOneWidget);
    // Uppercase input is normalized to the lowercase tag the server stores.
    await tester.enterText(codeField, 'DE');
    await tester.enterText(
      find.byKey(const Key('add-language-native-name')),
      'Deutsch',
    );
    expect(
      tester
          .widget<EditableText>(
            find.descendant(of: codeField, matching: find.byType(EditableText)),
          )
          .controller
          .text,
      'de',
    );

    await tester.tap(find.byKey(const Key('add-language-direction')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RTL').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-language-submit')));
    await tester.pumpAndSettle();

    expect(api.createCalls, hasLength(1));
    expect(api.createCalls.single.code, 'de');
    expect(api.createCalls.single.nativeName, 'Deutsch');
    expect(api.createCalls.single.direction, 'rtl');
    expect(find.text('workspace-de'), findsOneWidget);
    expect(
      find.text('Language ready. Add translations to complete setup.'),
      findsOneWidget,
    );
  });

  testWidgets('a 409 keeps the dialog open with the typed values', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final api = _FakeConfigApi(
      createFailure: const ApiFailure(
        code: 'LANGUAGE_EXISTS',
        messageKey: 'error.conflict',
        statusCode: 409,
      ),
    );
    await tester.pumpWidget(
      _app(
        api: api,
        router: GoRouter(
          initialLocation: '/settings/languages',
          routes: [
            GoRoute(
              path: '/settings/languages',
              builder: (context, state) => const LanguagesScreen(),
            ),
            GoRoute(
              path: '/settings/languages/:code',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: Text('workspace-${state.pathParameters['code']}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn-add-language')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('add-language-code')), 'de');
    await tester.enterText(
      find.byKey(const Key('add-language-native-name')),
      'Deutsch',
    );
    await tester.tap(find.byKey(const Key('add-language-submit')));
    await tester.pumpAndSettle();

    expect(api.createCalls, hasLength(1));
    expect(find.byKey(const Key('add-language-error')), findsOneWidget);
    expect(
      find.text(
        'This language is already live. Open it from the list to manage its translations.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('add-language-code')), findsOneWidget);
    expect(find.text('workspace-de'), findsNothing);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('add-language-native-name')),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      'Deutsch',
      reason: 'a rejected add must not discard the typed name',
    );
  });

  testWidgets('invalid input blocks the POST', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final api = _FakeConfigApi();
    await tester.pumpWidget(
      _app(
        api: api,
        router: GoRouter(
          initialLocation: '/settings/languages',
          routes: [
            GoRoute(
              path: '/settings/languages',
              builder: (context, state) => const LanguagesScreen(),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn-add-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-language-submit')));
    await tester.pumpAndSettle();

    expect(api.createCalls, isEmpty);
    expect(find.text('Enter a language code.'), findsOneWidget);
    expect(
      find.text('Enter the language name in its own script.'),
      findsOneWidget,
    );
  });

  testWidgets('registry-only languages appear with the awaiting-catalog note', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final api = _FakeConfigApi(
      languages: <PlatformLanguage>[_registryLanguage('de')],
    );
    await tester.pumpWidget(
      _app(
        api: api,
        router: GoRouter(
          initialLocation: '/settings/languages',
          routes: [
            GoRoute(
              path: '/settings/languages',
              builder: (context, state) => const LanguagesScreen(),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Registered, awaiting UI catalog'), findsOneWidget);
    expect(find.byKey(const ValueKey('language-card-de')), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.text('No UI message catalog file yet.'), findsOneWidget);
  });

  testWidgets('retire language confirms, DELETEs and returns to the list', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final api = _FakeConfigApi(
      languages: <PlatformLanguage>[_registryLanguage('de')],
    );
    await tester.pumpWidget(
      _app(
        api: api,
        router: GoRouter(
          initialLocation: '/settings/languages/de',
          routes: [
            GoRoute(
              path: '/settings/languages/de',
              builder: (context, state) =>
                  const LanguageWorkspaceScreen(languageCode: 'de'),
            ),
            GoRoute(
              path: '/settings/languages',
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('languages-list'))),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn-retire-language')), findsOneWidget);
    await tester.tap(find.byKey(const Key('btn-retire-language')));
    await tester.pumpAndSettle();

    expect(find.text('Retire this language?'), findsOneWidget);
    expect(
      find.text(
        'Translations and reports are kept. The language is hidden from selection and can be added again later.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.widgetWithText(PlatformDestructiveButton, 'Retire language'),
    );
    await tester.pumpAndSettle();

    expect(api.retireCalls, <String>['de']);
    expect(find.text('languages-list'), findsOneWidget);
    expect(find.text('Language retired.'), findsOneWidget);
  });

  testWidgets('the default language has no retire action', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final api = _FakeConfigApi(
      languages: <PlatformLanguage>[
        _registryLanguage('en', isDefault: true, status: 'LIVE'),
      ],
    );
    await tester.pumpWidget(
      _app(
        api: api,
        router: GoRouter(
          initialLocation: '/settings/languages/en',
          routes: [
            GoRoute(
              path: '/settings/languages/en',
              builder: (context, state) =>
                  const LanguageWorkspaceScreen(languageCode: 'en'),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn-retire-language')), findsNothing);
    expect(find.byKey(const Key('btn-manual-translations')), findsOneWidget);
  });
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

const _manifest = UiMessageManifest(
  defaultLanguage: 'en',
  namespaceVersions: <String, int>{'common': 1, 'platform_admin': 1},
  languages: <UiMessageLanguage>[
    UiMessageLanguage(
      code: 'en',
      direction: 'ltr',
      nativeName: 'English',
      path: 'platform_admin/en.json',
      totalKeys: 20,
      missingKeys: 0,
    ),
    UiMessageLanguage(
      code: 'es',
      direction: 'ltr',
      nativeName: 'Español',
      path: 'platform_admin/es.json',
      totalKeys: 20,
      missingKeys: 2,
    ),
  ],
);

PlatformLanguage _registryLanguage(
  String code, {
  bool isDefault = false,
  String status = 'DRAFT',
}) => PlatformLanguage(
  code: code,
  nativeName: code == 'de' ? 'Deutsch' : 'English',
  direction: 'ltr',
  active: status != 'RETIRED',
  isDefault: isDefault,
  sortOrder: isDefault ? 0 : 4,
  status: status,
);

LanguageReadiness _readiness(String code) => LanguageReadiness(
  language: code,
  status: 'DRAFT',
  nativeName: code == 'de' ? 'Deutsch' : 'English',
  direction: 'ltr',
  isDefault: code == 'en',
  uiMessagesPath: 'platform_admin/$code.json',
  readinessPercent: 40,
  uiMessages: const UiMessageCoverage(
    total: 20,
    approved: 8,
    missing: 12,
    changed: 0,
    path: 'platform_admin/de.json',
    generationStatus: 'IDLE',
  ),
  content: const <String, EntityReadiness>{},
  blockers: const <ReadinessBlocker>[],
);

Widget _app({required PlatformConfigApi api, required GoRouter router}) {
  return ProviderScope(
    overrides: [
      uiStringsProvider.overrideWithValue(loadReferenceStrings()),
      platformConfigApiProvider.overrideWithValue(api),
      platformUiManifestProvider.overrideWithValue(_manifest),
      platformLanguagesProvider.overrideWith((ref) => api.platformLanguages()),
      sessionStoreProvider.overrideWithValue(_MemorySessionStore()),
      statusesProvider('translation-status')
          .overrideWith((ref) async => const <ReferenceRecord>[]),
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
    ],
    child: MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      supportedLocales: const <Locale>[Locale('en')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    ),
  );
}

class _MemorySessionStore implements SessionStore {
  @override
  Future<void> save(Map<String, dynamic> session) async {}

  @override
  Future<Map<String, dynamic>?> read() async => null;

  @override
  Future<void> clear() async {}
}

/// In-memory registry so the screens never touch the network.
class _FakeConfigApi extends PlatformConfigApi {
  _FakeConfigApi({List<PlatformLanguage>? languages, this.createFailure})
    : _languages = <PlatformLanguage>[...?languages],
      super(
        ApiClient(
          config: const ApiConfig(
            baseUrl: 'http://localhost:8080',
            environment: 'test',
          ),
        ),
        const ApiEndpoints(baseUrl: 'http://localhost:8080'),
      );

  final ApiFailure? createFailure;
  final List<PlatformLanguage> _languages;
  final List<_CreateCall> createCalls = <_CreateCall>[];
  final List<String> retireCalls = <String>[];

  @override
  Future<List<PlatformLanguage>> platformLanguages() async =>
      List<PlatformLanguage>.unmodifiable(_languages);

  @override
  Future<TranslationCoverage> translationCoverage() async =>
      const TranslationCoverage(
        languages: <String>['en'],
        namespaces: <String, CoverageNamespace>{},
      );

  @override
  Future<LanguageReadiness> readiness(String code) async => _readiness(code);

  @override
  Future<PlatformLanguage> createLanguage({
    required String code,
    required String nativeName,
    required String direction,
  }) async {
    createCalls.add(
      _CreateCall(code: code, nativeName: nativeName, direction: direction),
    );
    if (createFailure != null) throw createFailure!;
    final created = PlatformLanguage(
      code: code,
      nativeName: nativeName,
      direction: direction,
      active: true,
      isDefault: false,
      sortOrder: _languages.length,
      status: 'DRAFT',
    );
    _languages.add(created);
    return created;
  }

  @override
  Future<PlatformLanguage> retireLanguage(String code) async {
    retireCalls.add(code);
    final index = _languages.indexWhere((language) => language.code == code);
    final retired = PlatformLanguage(
      code: code,
      nativeName: index == -1 ? code : _languages[index].nativeName,
      direction: 'ltr',
      active: false,
      isDefault: false,
      sortOrder: index == -1 ? 0 : _languages[index].sortOrder,
      status: 'RETIRED',
    );
    if (index != -1) _languages[index] = retired;
    return retired;
  }
}

class _CreateCall {
  const _CreateCall({
    required this.code,
    required this.nativeName,
    required this.direction,
  });

  final String code;
  final String nativeName;
  final String direction;
}

PlatformConfigApi _configApi(_ScriptedAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
  dio.httpClientAdapter = adapter;
  return PlatformConfigApi(
    ApiClient(
      config: const ApiConfig(baseUrl: 'http://localhost', environment: 'test'),
      dio: dio,
    ),
    const ApiEndpoints(baseUrl: 'http://localhost'),
  );
}

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.respond);

  final FutureOr<ResponseBody> Function(RequestOptions options) respond;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(
  body is String ? body : jsonEncode(body),
  status,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  },
);
