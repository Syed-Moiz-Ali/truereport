import 'dart:io';
import 'dart:ui' as ui;

import 'package:api_client/api_client.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:crypto/crypto.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/features/languages/languages_screen.dart';
import 'package:platform_admin_app/src/features/languages/ui_message_review_screen.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/platform_theme.dart';

import '../support/ui_message_fixtures.dart';

final _baseUrl =
    Platform.environment['LIVE_BASE_URL'] ?? 'http://localhost:8080';
final _email = Platform.environment['LIVE_E2E_EMAIL'];
final _password = Platform.environment['LIVE_E2E_PASSWORD'];
final _runLive = Platform.environment['LIVE_E2E'] == '1';
final _evidenceDir =
    Platform.environment['EVIDENCE_DIR'] ??
    '../../../docs/evidence/platform_admin_languages';

GlobalKey? _shotKey;
Size? _shotViewport;

class _Evidence {
  const _Evidence(this.filename, this.sha256, this.width, this.height);

  final String filename;
  final String sha256;
  final int width;
  final int height;
}

class _TestUiMessageController extends UiMessageController {
  _TestUiMessageController(this.manifest, this.activeLanguage);

  final UiMessageManifest manifest;
  final String activeLanguage;

  @override
  UiMessageState build() => UiMessageState(
    manifest: manifest,
    activeLanguage: activeLanguage,
    defaultLanguage: 'en',
    ready: true,
    revision: 1,
  );
}

Future<void> _loadMaterialIcons() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final candidates = <File>[
    File('build/unit_test_assets/fonts/MaterialIcons-Regular.otf'),
    if (flutterRoot != null)
      File(
        '$flutterRoot/bin/cache/artifacts/material_fonts/'
        'materialicons-regular.otf',
      ),
  ];
  File? fontFile;
  for (final candidate in candidates) {
    if (candidate.existsSync()) {
      fontFile = candidate;
      break;
    }
  }
  if (fontFile == null) {
    throw StateError(
      'MaterialIcons font not found. Expected '
      'build/unit_test_assets/fonts/MaterialIcons-Regular.otf.',
    );
  }

  final bytes = await fontFile.readAsBytes();
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}

Future<void> _loadRealFonts() async {
  final fontDir = Directory('../../packages/design_system/assets/fonts');
  if (!fontDir.existsSync()) return;

  final families = <String, FontLoader>{};
  await for (final entity in fontDir.list()) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (!name.endsWith('.ttf') && !name.endsWith('.otf')) continue;

    String? family;
    if (name.startsWith('PlusJakartaSans')) {
      family = TrFonts.latin;
    } else if (name.startsWith('NotoSansArabic')) {
      family = TrFonts.arabicDefault;
    } else if (name.startsWith('IBMPlexSansArabic')) {
      family = TrFonts.arabicAlternative;
    } else if (name.startsWith('NotoSansSC')) {
      family = TrFonts.cjkFallback;
    } else if (name.startsWith('NotoSansTelugu')) {
      family = TrFonts.teluguFallback;
    } else if (name.startsWith('NotoSans-')) {
      family = TrFonts.cyrillicFallback;
    }

    if (family != null) {
      final loader = families.putIfAbsent(family, () => FontLoader(family!));
      loader.addFont(entity.readAsBytes().then((b) => ByteData.sublistView(b)));
    }
  }

  for (final loader in families.values) {
    await loader.load();
  }
}

void _clearStaleEvidence() {
  final dir = Directory(_evidenceDir);
  if (!dir.existsSync()) return;
  for (final entity in dir.listSync()) {
    if (entity is File && entity.path.endsWith('.png')) {
      entity.deleteSync();
    }
  }
}

Widget _app(
  Widget home,
  ApiClient client,
  ApiEndpoints endpoints, {
  Locale locale = const Locale('en'),
  Size surfaceSize = const Size(1280, 800),
  UiMessageStrings? strings,
  UiMessageManifest? manifest,
  String? activeLanguage,
}) {
  final shotKey = GlobalKey();
  _shotKey = shotKey;
  _shotViewport = surfaceSize;
  final effectiveManifest =
      manifest ??
      const UiMessageManifest(
        defaultLanguage: 'en',
        namespaceVersions: {'platform_admin': 1, 'common': 1},
        languages: [
          UiMessageLanguage(
            code: 'en',
            direction: 'ltr',
            nativeName: 'English',
          ),
          UiMessageLanguage(
            code: 'ar',
            direction: 'rtl',
            nativeName: 'العربية',
          ),
        ],
      );
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(client),
      apiEndpointsProvider.overrideWithValue(endpoints),
      uiStringsProvider.overrideWithValue(
        strings ??
            (locale.languageCode == 'ar'
                ? fakeArUiStrings()
                : fakeEnUiStrings()),
      ),
      uiMessageControllerProvider.overrideWith(
        () => _TestUiMessageController(
          effectiveManifest,
          activeLanguage ?? locale.languageCode,
        ),
      ),
    ],
    child: RepaintBoundary(
      key: shotKey,
      child: MediaQuery(
        data: MediaQueryData(size: surfaceSize),
        child: MaterialApp(
          locale: locale,
          supportedLocales: <Locale>[
            const Locale('en'),
            const Locale('ar'),
            locale,
          ],
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            fontFamily: locale.languageCode == 'ar'
                ? TrFonts.arabicDefault
                : TrFonts.latin,
            fontFamilyFallback: const [
              TrFonts.cjkFallback,
              TrFonts.teluguFallback,
              TrFonts.cyrillicFallback,
            ],
            scaffoldBackgroundColor: PtTheme.canvas,
          ),
          home: home,
        ),
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
  client.clientName = 'platform_admin';
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
  Size viewport = const Size(1280, 800),
  UiMessageStrings? strings,
  UiMessageManifest? manifest,
  String? activeLanguage,
}) async {
  await tester.binding.setSurfaceSize(viewport);
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  await tester.pumpWidget(
    _app(
      home,
      client,
      endpoints,
      locale: locale,
      surfaceSize: viewport,
      strings: strings,
      manifest: manifest,
      activeLanguage: activeLanguage,
    ),
  );
  await _flush(tester);
}

Future<_Evidence> _shot(WidgetTester tester, String name, Size viewport) async {
  late _Evidence evidence;
  await tester.runAsync(() async {
    final context = _shotKey?.currentContext;
    final boundary = context?.findRenderObject();
    expect(boundary, isA<RenderRepaintBoundary>());
    final image = await (boundary! as RenderRepaintBoundary).toImage(
      pixelRatio: 1,
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(bytes, isNotNull);
    final png = bytes!.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, viewport.width.round());
    expect(frame.image.height, viewport.height.round());
    expect(_shotViewport, viewport);

    final dir = Directory(_evidenceDir)..createSync(recursive: true);
    final file = File('${dir.path}/$name.png');
    for (var attempt = 0; attempt < 6; attempt++) {
      try {
        await file.writeAsBytes(png, flush: true);
        break;
      } on FileSystemException {
        if (attempt == 5) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }
    final digest = sha256.convert(await file.readAsBytes()).toString();
    evidence = _Evidence(name, digest, frame.image.width, frame.image.height);
  });
  return evidence;
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

List<String> _generatedUiMessagePaths(String code) {
  final configured = Platform.environment['LIVE_UI_MESSAGES_DIR'];
  return [
    if (configured != null) '$configured/platform_admin/$code.json',
    'generated_ui_messages/platform_admin/$code.json',
    '../../../server/src/main/resources/i18n/platform_admin/$code.json',
  ];
}

Map<String, Map<String, String>> _catalogsFromBundle(
  Map<String, dynamic> bundle,
) {
  final catalogs = bundle['catalogs'] as Map<String, dynamic>;
  return catalogs.map(
    (namespace, values) => MapEntry(
      namespace,
      (values as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as String),
      ),
    ),
  );
}

String? _translation(Map<String, dynamic> row, String field, String language) {
  final translations = row['translations'];
  if (translations is! Map) return null;
  final fieldMap = translations[field];
  if (fieldMap is! Map) return null;
  final value = fieldMap[language];
  return value is String ? value : null;
}

Future<List<Map<String, dynamic>>> _listRows(
  WidgetTester tester,
  ApiClient client,
  String path, {
  Map<String, dynamic>? query,
}) async {
  final value = await _live(
    tester,
    () => client.getDynamic(path, query: query),
  );
  return (value as List<dynamic>).cast<Map<String, dynamic>>();
}

Future<String?> _issueFieldTranslation(
  WidgetTester tester,
  ApiClient client,
  String code,
  String fieldId,
) async {
  final items = await _listRows(
    tester,
    client,
    '/api/v1/platform/master/items',
  );
  for (final item in items) {
    final itemId = item['id'] as String;
    final detail = await _get(
      tester,
      client,
      '/api/v1/platform/master/items/$itemId',
    );
    final versions = (detail['versions'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    for (final version in versions) {
      final versionId = version['id'] as String;
      final fields = await _listRows(
        tester,
        client,
        '/api/v1/platform/master/items/$itemId/versions/$versionId/issue-fields',
      );
      for (final field in fields) {
        if (field['id'] == fieldId) {
          return _translation(field, 'label', code);
        }
      }
    }
  }
  return null;
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

  setUpAll(() async {
    HttpOverrides.global = null;
    await _loadMaterialIcons();
    await _loadRealFonts();
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
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
    _clearStaleEvidence();
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.binding.setSurfaceSize(null);
    });

    final client = await _live(tester, _login);
    final endpoints = ApiEndpoints(baseUrl: _baseUrl);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final code = 'e2e${(stamp % 100000).toString().padLeft(5, '0')}';
    addTearDown(() async {
      try {
        await client.deleteDynamic('/api/v1/platform/i18n/languages/$code');
      } catch (_) {
        // Best effort: the language may already be removed by the test.
      }
      for (final path in _generatedUiMessagePaths(code)) {
        final file = File(path);
        if (file.existsSync()) {
          try {
            file.deleteSync();
          } catch (_) {
            // Best effort file cleanup.
          }
        }
      }
    });

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
    const titleKey = 'platform_admin.page.languages.title';
    final editedEntry = entries.firstWhere(
      (entry) => entry['key'] == titleKey,
      orElse: () => entries.first,
    );
    final editedKey = editedEntry['key'] as String;
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

    try {
      await _post(
        tester,
        client,
        '/api/v1/platform/seed/default-checklist',
        body: const <String, dynamic>{},
      );
    } catch (_) {
      // The shared local database may already be seeded.
    }

    const contentTypes = [
      'CATEGORY',
      'ITEM',
      'OPTION_SET',
      'OPTION_VALUE',
      'TEMPLATE',
      'DOCUMENT_TYPE',
      'ISSUE_FIELD',
    ];
    final generatedContent = await _post(
      tester,
      client,
      '/api/v1/platform/i18n/languages/$code/content/generate',
      body: {'force': true, 'entityTypes': contentTypes},
    );
    var contentStatus = generatedContent as Map<String, dynamic>;
    for (var attempt = 0; attempt < 60; attempt++) {
      if (contentStatus['jobStatus'] != 'RUNNING' &&
          contentStatus['jobStatus'] != 'QUEUED') {
        break;
      }
      await _live(
        tester,
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
      contentStatus = await _get(
        tester,
        client,
        '/api/v1/platform/i18n/languages/$code/content/generation',
      );
    }
    expect(contentStatus['jobStatus'], 'COMPLETED');
    expect(contentStatus['failedKeys'] as List<dynamic>, isEmpty);

    final generatedBacklog = await _get(
      tester,
      client,
      '/api/v1/platform/i18n/languages/$code/backlog',
    );
    final generatedGroups = (generatedBacklog['groups'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(
      generatedGroups.map((group) => group['entityType']).toSet(),
      contentTypes.toSet(),
    );
    final editedByType = <String, Map<String, dynamic>>{};
    for (final group in generatedGroups) {
      final type = group['entityType'] as String;
      final items = (group['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(items, isNotEmpty, reason: '$type should contain content');
      final generatedTexts = items
          .map((item) => (item['text'] as String?)?.trim())
          .toList();
      expect(
        generatedTexts.every((text) => text != null && text.isNotEmpty),
        isTrue,
        reason: '$type translations should be generated',
      );
      expect(
        generatedTexts.any((text) => text!.startsWith('[$code] ')),
        isTrue,
        reason: '$type should include a stub translation',
      );
      final first = items.first;
      final editedContent = '[stub] edited $stamp $type';
      await _put(
        tester,
        client,
        '/api/v1/platform/i18n/translations',
        body: {
          'entityType': type,
          'entityId': first['entityId'],
          'field': first['field'],
          'language': code,
          'text': editedContent,
          'status': 'APPROVED',
        },
      );
      editedByType[type] = {...first, 'editedText': editedContent};
    }

    for (final group in generatedGroups) {
      final type = group['entityType'] as String;
      final edited = editedByType[type]!;
      for (final item
          in (group['items'] as List<dynamic>).cast<Map<String, dynamic>>()) {
        if (item['entityId'] == edited['entityId'] &&
            item['field'] == edited['field']) {
          continue;
        }
        final text = (item['text'] as String?)?.trim();
        await _put(
          tester,
          client,
          '/api/v1/platform/i18n/translations',
          body: {
            'entityType': type,
            'entityId': item['entityId'],
            'field': item['field'],
            'language': code,
            'text': text == null || text.isEmpty ? '[stub] $stamp' : text,
            'status': 'APPROVED',
          },
        );
      }
    }

    final coverage = await _get(
      tester,
      client,
      '/api/v1/platform/i18n/coverage',
      query: {'language': code},
    );
    expect(coverage['approvedCount'], coverage['totalRequired']);

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

    final enBundle = await _get(
      tester,
      client,
      '/api/v1/i18n/ui-messages/bundle',
      query: {'lang': 'en', 'namespaces': 'platform_admin,common'},
    );
    final liveStrings = UiMessageStrings(
      catalogs: {
        code: _catalogsFromBundle(bundle),
        'en': _catalogsFromBundle(enBundle),
      },
      activeLanguage: code,
      defaultLanguage: 'en',
    );
    expect(liveStrings.resolveQualifiedKey(editedKey), editedText);

    final categories = await _listRows(
      tester,
      client,
      '/api/v1/platform/master/categories',
    );
    final category = categories.firstWhere(
      (row) => row['id'] == editedByType['CATEGORY']!['entityId'],
    );
    expect(
      _translation(category, 'name', code),
      editedByType['CATEGORY']!['editedText'],
    );

    final items = await _listRows(
      tester,
      client,
      '/api/v1/platform/master/items',
    );
    final itemEntityId = editedByType['ITEM']!['entityId'];
    Map<String, dynamic>? itemVersion;
    Map<String, dynamic>? itemRow;
    for (final row in items) {
      if (row['id'] == itemEntityId) {
        itemRow = row;
      }
      final detail = await _get(
        tester,
        client,
        '/api/v1/platform/master/items/${row['id']}',
      );
      for (final version
          in (detail['versions'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>()) {
        if (version['id'] == itemEntityId) {
          itemVersion = version;
          break;
        }
      }
      if (itemVersion != null) break;
    }
    expect(
      itemVersion != null || itemRow != null,
      isTrue,
      reason: 'item translation target $itemEntityId should be visible',
    );
    expect(
      _translation(
        itemVersion ?? itemRow!,
        editedByType['ITEM']!['field'] as String,
        code,
      ),
      editedByType['ITEM']!['editedText'],
    );

    final optionSets = await _listRows(
      tester,
      client,
      '/api/v1/platform/master/option-sets',
    );
    final optionSetId = editedByType['OPTION_SET']!['entityId'];
    final optionValueId = editedByType['OPTION_VALUE']!['entityId'];
    final optionSet = optionSets.firstWhere((row) => row['id'] == optionSetId);
    expect(
      _translation(optionSet, 'name', code),
      editedByType['OPTION_SET']!['editedText'],
    );
    final optionValue = optionSets
        .expand(
          (row) => (row['values'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>(),
        )
        .firstWhere((row) => row['id'] == optionValueId);
    expect(
      _translation(optionValue, 'label', code),
      editedByType['OPTION_VALUE']!['editedText'],
    );

    final templates = await _listRows(
      tester,
      client,
      '/api/v1/platform/master/templates',
    );
    final template = templates.firstWhere(
      (row) => row['id'] == editedByType['TEMPLATE']!['entityId'],
    );
    expect(
      _translation(
        template,
        editedByType['TEMPLATE']!['field'] as String,
        code,
      ),
      editedByType['TEMPLATE']!['editedText'],
    );

    final documentTypes = await _listRows(
      tester,
      client,
      '/api/v1/platform/document-types',
    );
    final documentType = documentTypes.firstWhere(
      (row) => row['id'] == editedByType['DOCUMENT_TYPE']!['entityId'],
    );
    expect(
      _translation(documentType, 'name', code),
      editedByType['DOCUMENT_TYPE']!['editedText'],
    );

    expect(
      await _issueFieldTranslation(
        tester,
        client,
        code,
        editedByType['ISSUE_FIELD']!['entityId'] as String,
      ),
      editedByType['ISSUE_FIELD']!['editedText'],
    );

    // No translated text is stored in the language metadata row.
    expect(language.containsKey('uiMessagesHash'), isFalse);

    final liveManifest = UiMessageManifest.fromJson(manifest);
    final liveEnStrings = UiMessageStrings(
      catalogs: {'en': _catalogsFromBundle(enBundle)},
      activeLanguage: 'en',
      defaultLanguage: 'en',
    );
    final arBundle = await _get(
      tester,
      client,
      '/api/v1/i18n/ui-messages/bundle',
      query: {'lang': 'ar', 'namespaces': 'platform_admin,common'},
    );
    final arStrings = UiMessageStrings(
      catalogs: {
        'ar': _catalogsFromBundle(arBundle),
        'en': _catalogsFromBundle(enBundle),
      },
      activeLanguage: 'ar',
      defaultLanguage: 'en',
    );

    final evidence = <_Evidence>[];
    for (final viewport in const [
      Size(1440, 900),
      Size(1280, 800),
      Size(768, 1024),
      Size(360, 800),
    ]) {
      await _pump(
        tester,
        const LanguagesScreen(),
        client,
        endpoints,
        viewport: viewport,
        strings: liveEnStrings,
        manifest: liveManifest,
        activeLanguage: 'en',
      );
      evidence.add(
        await _shot(tester, 'languages_${viewport.width.toInt()}', viewport),
      );
    }

    const evidenceViewport = Size(1280, 800);
    await _pump(
      tester,
      const LanguagesScreen(),
      client,
      endpoints,
      locale: const Locale('ar'),
      viewport: evidenceViewport,
      strings: arStrings,
      manifest: liveManifest,
      activeLanguage: 'ar',
    );
    final arElement = tester.element(find.byType(LanguagesScreen));
    final arContainer = ProviderScope.containerOf(arElement, listen: false);
    expect(arContainer.read(uiMessageControllerProvider).activeLanguage, 'ar');
    expect(Localizations.localeOf(arElement).languageCode, 'ar');
    expect(Directionality.of(arElement), TextDirection.rtl);
    expect(find.text('العربية (AR)'), findsOneWidget);
    evidence.add(await _shot(tester, 'languages_ar_rtl', evidenceViewport));

    await _pump(
      tester,
      const LanguagesScreen(),
      client,
      endpoints,
      viewport: evidenceViewport,
      strings: liveStrings,
      manifest: liveManifest,
      activeLanguage: code,
    );
    expect(find.text(editedText), findsWidgets);
    expect(find.text('Language registry'), findsNothing);
    evidence.add(
      await _shot(tester, 'languages_${code}_switched', evidenceViewport),
    );

    await _pump(
      tester,
      UiMessageReviewScreen(languageCode: code),
      client,
      endpoints,
      viewport: evidenceViewport,
      manifest: liveManifest,
      activeLanguage: code,
    );
    evidence.add(
      await _shot(tester, 'generated_language_review_$code', evidenceViewport),
    );

    expect(evidence, hasLength(7));
    expect(
      evidence.map((item) => item.sha256).toSet(),
      hasLength(evidence.length),
      reason: 'each evidence capture must have a distinct SHA-256 hash',
    );

    await client.deleteDynamic('/api/v1/platform/i18n/languages/$code');
    for (final path in _generatedUiMessagePaths(code)) {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
      expect(file.existsSync(), isFalse, reason: 'residual file $path');
    }
    final remainingLanguages = await _listRows(
      tester,
      client,
      '/api/v1/platform/i18n/languages',
    );
    expect(remainingLanguages.map((row) => row['code']).toSet(), {'en', 'ar'});
    await _pump(
      tester,
      const LanguagesScreen(),
      client,
      endpoints,
      viewport: evidenceViewport,
    );
    expect(find.text(code), findsNothing);
  }, timeout: const Timeout(Duration(minutes: 8)));
}
