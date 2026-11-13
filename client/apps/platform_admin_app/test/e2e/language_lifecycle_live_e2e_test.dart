import 'dart:io';
import 'dart:ui' as ui;

import 'package:api_client/api_client.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/features/languages/languages_screen.dart';
import 'package:platform_admin_app/src/features/languages/ui_message_review_screen.dart';
import 'package:platform_admin_app/src/platform_providers.dart';

import '../support/ui_message_fixtures.dart';

final _baseUrl =
    Platform.environment['LIVE_BASE_URL'] ?? 'http://localhost:8080';
final _email = Platform.environment['LIVE_E2E_EMAIL'];
final _password = Platform.environment['LIVE_E2E_PASSWORD'];
final _runLive = Platform.environment['LIVE_E2E'] == '1';

GlobalKey? _shotKey;

Widget _app(
  Widget home,
  ApiClient client,
  ApiEndpoints endpoints, {
  Locale locale = const Locale('en'),
}) {
  final shotKey = GlobalKey();
  _shotKey = shotKey;
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(client),
      apiEndpointsProvider.overrideWithValue(endpoints),
      uiStringsProvider.overrideWithValue(
        locale.languageCode == 'ar' ? fakeArUiStrings() : fakeEnUiStrings(),
      ),
    ],
    child: RepaintBoundary(
      key: shotKey,
      child: MaterialApp(
        locale: locale,
        supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      ),
    ),
  );
}

Future<ApiClient> _login() async {
  final client = ApiClient(
    config: ApiConfig(baseUrl: _baseUrl, environment: 'dev'),
  );
  final response = await client.postDynamic(
    '/api/v1/auth/login',
    body: <String, dynamic>{'email': _email, 'password': _password},
  );
  client.accessToken =
      (response as Map<String, dynamic>)['accessToken'] as String;
  client.acceptLanguage = 'en';
  return client;
}

Future<void> _flush(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
  });
  await tester.pumpAndSettle();
}

Future<T> _live<T>(WidgetTester tester, Future<T> Function() action) async {
  final result = await tester.runAsync(action);
  return result as T;
}

Future<void> _pump(
  WidgetTester tester,
  Widget home,
  ApiClient client,
  ApiEndpoints endpoints, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  await tester.pumpWidget(_app(home, client, endpoints, locale: locale));
  await _flush(tester);
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final context = _shotKey?.currentContext;
    final boundary = context?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    final dir = Directory(
      Platform.environment['EVIDENCE_DIR'] ??
          '../../../docs/evidence/platform_admin_languages',
    )..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes.buffer.asUint8List());
  });
}

Future<Map<String, dynamic>> _get(
  WidgetTester tester,
  ApiClient client,
  String path, {
  Map<String, dynamic>? query,
}) async {
  final value = await _live(
    tester,
    () => client.getDynamic(path, query: query),
  );
  return value is Map<String, dynamic>
      ? value
      : Map<String, dynamic>.from(value as Map);
}

Future<dynamic> _post(
  WidgetTester tester,
  ApiClient client,
  String path, {
  Object? body,
}) {
  return _live(tester, () => client.postDynamic(path, body: body));
}

Future<dynamic> _put(
  WidgetTester tester,
  ApiClient client,
  String path, {
  Object? body,
}) {
  return _live(tester, () => client.putDynamic(path, body: body));
}

bool _fileExists(String code) {
  final configured = Platform.environment['LIVE_UI_MESSAGES_DIR'];
  final candidates = <String>[
    if (configured != null) '$configured/platform_admin/$code.json',
    '../../../server/src/main/resources/i18n/platform_admin/$code.json',
    '../../server/src/main/resources/i18n/platform_admin/$code.json',
  ];
  for (final path in candidates) {
    if (File(path).existsSync()) return true;
  }
  return false;
}

void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized();
  if (!_runLive) {
    test(
      'platform admin language lifecycle live e2e (skipped)',
      () {},
      skip: true,
    );
    return;
  }

  setUpAll(() {
    HttpOverrides.global = null;
  });

  testWidgets('add language -> generate -> review -> approve -> publish', (
    tester,
  ) async {
    if (_email == null ||
        _email!.isEmpty ||
        _password == null ||
        _password!.isEmpty) {
      fail('LIVE_E2E=1 requires LIVE_E2E_EMAIL and LIVE_E2E_PASSWORD.');
    }
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final client = await _live(tester, _login);
    final endpoints = ApiEndpoints(baseUrl: _baseUrl);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final code = 'e2e${(stamp % 100000).toString().padLeft(5, '0')}';

    final created = await _post(
      tester,
      client,
      '/api/v1/platform/i18n/languages',
      body: {
        'code': code,
        'nameEn': 'E2E Language $stamp',
        'nameAr': 'لغة اختبار $stamp',
        'nativeName': 'E2E $stamp',
        'direction': 'ltr',
      },
    );
    expect((created as Map<String, dynamic>)['code'], code);

    final generation = await _post(
      tester,
      client,
      '/api/v1/platform/i18n/languages/$code/ui-messages/generate',
      body: {'force': true, 'reviewStatus': 'TRANSLATING'},
    );
    expect((generation as Map<String, dynamic>)['jobStatus'], isNot('FAILED'));

    late Map<String, dynamic> status;
    for (var attempt = 0; attempt < 60; attempt++) {
      status = await _get(
        tester,
        client,
        '/api/v1/platform/i18n/languages/$code/ui-messages/generation',
      );
      if (status['jobStatus'] != 'RUNNING' && status['jobStatus'] != 'QUEUED') {
        break;
      }
      await _live(
        tester,
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
    }
    expect(status['jobStatus'], 'COMPLETED');
    expect(status['failedKeys'], isEmpty);

    final languages = await _live(
      tester,
      () => client.getDynamic('/api/v1/platform/i18n/languages'),
    );
    final language = (languages as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere((row) => row['code'] == code);
    expect(language['uiMessagesPath'], 'platform_admin/$code.json');
    expect(
      _fileExists(code),
      isTrue,
      reason: 'generated JSON file should exist on disk',
    );

    // Publish must be blocked before the review is approved.
    Object? publishFailure;
    try {
      await _post(
        tester,
        client,
        '/api/v1/platform/i18n/languages/$code/publish',
      );
    } catch (error) {
      publishFailure = error;
    }
    while (true) {
      final pending = tester.takeException();
      if (pending == null) break;
      publishFailure ??= pending;
    }
    expect(publishFailure, isA<AppFailure>());
    expect((publishFailure as AppFailure).statusCode, 422);

    final review = await _get(
      tester,
      client,
      '/api/v1/platform/i18n/languages/$code/ui-messages/review',
    );
    final entries = (review['entries'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(entries, isNotEmpty);
    final editedKey = entries.first['key'] as String;
    final editedText = '[stub] edited $stamp';

    await _put(
      tester,
      client,
      '/api/v1/platform/i18n/languages/$code/ui-messages/review',
      body: {
        'translations': {editedKey: editedText},
      },
    );

    final approved = await _post(
      tester,
      client,
      '/api/v1/platform/i18n/languages/$code/ui-messages/approve',
    );
    expect((approved as Map<String, dynamic>)['status'], 'REVIEW');

    // Master content also needs approved translations for a new language.
    final backlog = await _get(
      tester,
      client,
      '/api/v1/platform/i18n/languages/$code/backlog',
    );
    for (final group
        in (backlog['groups'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      for (final item
          in (group['items'] as List<dynamic>).cast<Map<String, dynamic>>()) {
        final text = (item['defaultText'] as String?)?.trim();
        await _put(
          tester,
          client,
          '/api/v1/platform/i18n/translations',
          body: {
            'entityType': item['entityType'],
            'entityId': item['entityId'],
            'field': item['field'],
            'language': code,
            'text': text == null || text.isEmpty ? '[stub] $stamp' : text,
            'status': 'APPROVED',
          },
        );
      }
    }

    final published = await _post(
      tester,
      client,
      '/api/v1/platform/i18n/languages/$code/publish',
    );
    expect((published as Map<String, dynamic>)['status'], 'LIVE');

    final manifest = await _get(
      tester,
      client,
      '/api/v1/i18n/ui-messages/manifest',
    );
    final manifestCodes = (manifest['languages'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((row) => row['code'])
        .toList();
    expect(manifestCodes, contains(code));

    final bundle = await _get(
      tester,
      client,
      '/api/v1/i18n/ui-messages/bundle',
      query: {'lang': code, 'namespaces': 'platform_admin,common'},
    );
    final catalog = (bundle['catalogs'] as Map<String, dynamic>);
    final parts = editedKey.split('.');
    final namespace = parts.first;
    final messageKey = parts.sublist(1).join('.');
    final resolved = (catalog[namespace] as Map<String, dynamic>?)?[messageKey];
    expect(resolved, editedText);

    // No translated text is stored in the language metadata row.
    expect(language.containsKey('uiMessagesHash'), isFalse);

    for (final size in const [
      Size(1280, 900),
      Size(1440, 900),
      Size(768, 1024),
      Size(360, 900),
    ]) {
      tester.view.physicalSize = size;
      await _pump(tester, const LanguagesScreen(), client, endpoints);
      await _shot(tester, 'languages_${size.width.toInt()}');
    }

    tester.view.physicalSize = const Size(1280, 900);
    await _pump(
      tester,
      const LanguagesScreen(),
      client,
      endpoints,
      locale: const Locale('ar'),
    );
    await _shot(tester, 'languages_ar_rtl');

    tester.view.physicalSize = const Size(1280, 900);
    await _pump(
      tester,
      UiMessageReviewScreen(languageCode: code),
      client,
      endpoints,
    );
    await _shot(tester, 'generated_language_review_$code');
  }, timeout: const Timeout(Duration(minutes: 8)));
}
