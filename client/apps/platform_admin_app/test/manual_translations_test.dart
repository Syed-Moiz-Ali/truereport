import 'package:api_client/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/features/languages/manual_translation_models.dart';
import 'package:platform_admin_app/src/platform_config_api.dart';

/// Manual translation units: the page/DTO parsing and the exact request the
/// screen sends. No network: the API client is recorded through a subclass.
void main() {
  group('ManualTranslationPage', () {
    test('parses totals, source text and null translations from the units '
        'contract', () {
      final page = ManualTranslationPage.fromJson(_unitsResponse);

      expect(page.lang, 'es');
      expect(page.total, 394);
      expect(page.page, 2);
      expect(page.size, 25);
      expect(page.items, hasLength(2));

      final translated = page.items.first;
      expect(translated.key, 'CATEGORY/cat-1/name');
      expect(translated.sourceText, 'Suspension, Steering & Underbody');
      expect(translated.text, 'Suspensión, dirección y bajo cuerpo');
      expect(translated.status, 'PENDING_REVIEW');
      expect(translated.origin, 'MACHINE');
      expect(translated.hasTranslation, isTrue);
      expect(translated.isMissing, isFalse);
      expect(translated.safetyCritical, isFalse);

      final missing = page.items.last;
      expect(missing.key, 'ITEM/item-1/label');
      expect(missing.text, isNull);
      expect(missing.status, isNull);
      expect(missing.origin, isNull);
      expect(missing.isMissing, isTrue);
      expect(missing.safetyCritical, isTrue);
    });

    test('treats blank text as missing and accepts the write `body` field', () {
      final blank = ManualTranslationUnit.fromJson(<String, dynamic>{
        'entityType': 'ITEM',
        'entityId': 'item-2',
        'field': 'instruction',
        'sourceText': 'Replace the pad',
        'text': '   ',
        'status': 'DRAFT',
      });
      expect(blank.text, isNull);
      expect(blank.isMissing, isTrue);

      final written = ManualTranslationUnit.fromJson(<String, dynamic>{
        'body': 'Sustituya la pastilla',
        'origin': 'AUTHORED',
        'status': 'DRAFT',
      });
      expect(written.trimmedText, 'Sustituya la pastilla');
      expect(written.origin, 'AUTHORED');
      expect(written.hasTranslation, isTrue);
    });

    test('keeps the request identity when the write response omits it', () {
      const fallback = ManualTranslationUnit(
        entityType: 'CATEGORY',
        entityId: 'cat-1',
        field: 'name',
        sourceText: 'Suspension',
      );
      final written = ManualTranslationUnit.fromJson(<String, dynamic>{
        'body': 'Suspensión',
        'status': 'DRAFT',
      }).withIdentity(fallback);

      expect(written.entityType, 'CATEGORY');
      expect(written.entityId, 'cat-1');
      expect(written.field, 'name');
      expect(written.sourceText, 'Suspension');
      expect(written.trimmedText, 'Suspensión');
    });

    test('restores the saved text when the write response omits it', () {
      const fallback = ManualTranslationUnit(
        entityType: 'CATEGORY',
        entityId: 'cat-1',
        field: 'name',
        sourceText: 'Suspension',
      );
      final minimal = ManualTranslationUnit.fromJson(<String, dynamic>{
        'status': 'DRAFT',
      }).withIdentity(fallback);
      expect(minimal.isMissing, isTrue);

      final restored = minimal.copyWith(text: 'Suspensión');
      expect(restored.trimmedText, 'Suspensión');
      expect(restored.hasTranslation, isTrue);
      expect(restored.status, 'DRAFT');
    });

    test('summary derives translated from the server totals only', () {
      final summary = ManualTranslationSummary.fromPages(
        all: ManualTranslationPage.fromJson(<String, dynamic>{
          'lang': 'es',
          'total': 394,
          'page': 0,
          'size': 1,
          'items': const <dynamic>[],
        }),
        missing: ManualTranslationPage.fromJson(<String, dynamic>{
          'lang': 'es',
          'total': 17,
          'page': 0,
          'size': 1,
          'items': const <dynamic>[],
        }),
      );

      expect(summary.total, 394);
      expect(summary.missing, 17);
      expect(summary.translated, 377);
    });
  });

  group('PlatformConfigApi content units', () {
    late _RecordingApiClient client;
    late PlatformConfigApi api;

    setUp(() {
      client = _RecordingApiClient();
      api = PlatformConfigApi(
        client,
        const ApiEndpoints(baseUrl: 'http://localhost:8080'),
      );
    });

    test(
      'builds the units query exactly and never derives totals from items',
      () async {
        final page = await api.contentUnits(
          lang: 'es',
          entityType: 'CATEGORY',
          filter: ManualTranslationFilter.missing,
          query: '  brake  ',
          page: 2,
          size: 25,
        );

        final call = client.calls.single;
        expect(call.method, 'GET');
        expect(call.path, '/api/v1/platform/i18n/content/units');
        expect(call.query, <String, dynamic>{
          'lang': 'es',
          'entityType': 'CATEGORY',
          'filter': 'missing',
          'query': 'brake',
          'page': '2',
          'size': '25',
        });
        expect(page.total, 394);
        expect(page.items, hasLength(2));
      },
    );

    test('omits empty filters and query from the units request', () async {
      await api.contentUnits(lang: 'es', query: '   ');

      expect(client.calls.single.query, <String, dynamic>{
        'lang': 'es',
        'filter': 'all',
        'page': '0',
        'size': '50',
      });
    });

    test(
      'writes the translation with lang in the query and body in the body',
      () async {
        final saved = await api.writeContentTranslation(
          entityType: 'CATEGORY',
          entityId: 'cat-1',
          field: 'name',
          lang: 'es',
          text: '  Suspensión  ',
        );

        final call = client.calls.single;
        expect(call.method, 'PUT');
        expect(call.path, '/api/v1/platform/i18n/content/CATEGORY/cat-1/name');
        expect(call.query, <String, dynamic>{'lang': 'es'});
        expect(call.body, <String, dynamic>{'body': 'Suspensión'});
        expect(saved.trimmedText, 'Suspensión');
        expect(saved.origin, 'AUTHORED');
        expect(saved.status, 'DRAFT');
      },
    );
  });
}

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient()
    : super(
        config: const ApiConfig(
          baseUrl: 'http://localhost:8080',
          environment: 'test',
        ),
      );

  final List<_Call> calls = [];

  @override
  Future<dynamic> getDynamic(String path, {Map<String, dynamic>? query}) async {
    calls.add(_Call('GET', path, query, null));
    return _unitsResponse;
  }

  @override
  Future<dynamic> putDynamic(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    calls.add(_Call('PUT', path, query, body));
    return <String, dynamic>{
      'entityType': 'CATEGORY',
      'entityId': 'cat-1',
      'field': 'name',
      'body': 'Suspensión',
      'status': 'DRAFT',
      'origin': 'AUTHORED',
      'sourceText': 'Suspension',
      'safetyCritical': false,
    };
  }
}

class _Call {
  const _Call(this.method, this.path, this.query, this.body);

  final String method;
  final String path;
  final Map<String, dynamic>? query;
  final Object? body;
}

const Map<String, dynamic> _unitsResponse = <String, dynamic>{
  'lang': 'es',
  'total': 394,
  'page': 2,
  'size': 25,
  'items': <dynamic>[
    <String, dynamic>{
      'entityType': 'CATEGORY',
      'entityId': 'cat-1',
      'field': 'name',
      'sourceText': 'Suspension, Steering & Underbody',
      'text': 'Suspensión, dirección y bajo cuerpo',
      'status': 'PENDING_REVIEW',
      'origin': 'MACHINE',
      'safetyCritical': false,
    },
    <String, dynamic>{
      'entityType': 'ITEM',
      'entityId': 'item-1',
      'field': 'label',
      'sourceText': 'Brake pad',
      'text': null,
      'status': null,
      'origin': null,
      'safetyCritical': true,
    },
  ],
};
