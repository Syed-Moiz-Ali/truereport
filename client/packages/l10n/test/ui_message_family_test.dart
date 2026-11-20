import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

UiMessageLanguage _language(String code) => UiMessageLanguage(
  code: code,
  direction: 'ltr',
  nativeName: switch (code) {
    'es' => 'Español',
    'en' => 'English',
    _ => code,
  },
);

UiMessageManifest _manifest(List<UiMessageLanguage> languages) =>
    UiMessageManifest(
      defaultLanguage: 'en',
      namespaceVersions: const <String, int>{'common': 1, 'workshop_admin': 1},
      languages: languages,
    );

class _FakeController extends UiMessageController {
  _FakeController(this._languages) : super(UiMessageClients.workshopAdmin);

  final List<UiMessageLanguage> _languages;

  @override
  UiMessageState build() => UiMessageState(
    manifest: _manifest(_languages),
    activeLanguage: 'en',
    defaultLanguage: 'en',
    ready: true,
    revision: 1,
  );

  @override
  Future<bool> useLanguage(String code) async {
    state = state.copyWith(activeLanguage: code, revision: state.revision + 1);
    return true;
  }
}

Widget _harness({
  required List<UiMessageLanguage> languages,
  ValueChanged<String>? onChanged,
}) {
  return ProviderScope(
    overrides: [
      languageSelectionProvider(UiMessageClients.workshopAdmin)
          .overrideWith(() => _FakeController(languages)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: BackendLanguageSelector(
          client: UiMessageClients.workshopAdmin,
          onChanged: onChanged,
        ),
      ),
    ),
  );
}

void main() {
  group('BackendLanguageSelector', () {
    testWidgets('renders one option per manifest language', (tester) async {
      await tester.pumpWidget(
        _harness(languages: [_language('en'), _language('es')]),
      );
      expect(find.byKey(const Key('backend-language-en')), findsOneWidget);
      expect(find.byKey(const Key('backend-language-es')), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
    });

    testWidgets('is hidden when only one language is advertised', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(languages: [_language('en')]));
      expect(find.byKey(const Key('backend-language-en')), findsNothing);
      expect(find.text('English'), findsNothing);
    });

    testWidgets('one tap switches the language without a save button', (
      tester,
    ) async {
      String? switched;
      await tester.pumpWidget(
        _harness(
          languages: [_language('en'), _language('es')],
          onChanged: (code) => switched = code,
        ),
      );
      await tester.tap(find.byKey(const Key('backend-language-es')));
      await tester.pumpAndSettle();
      expect(switched, 'es');
    });

    testWidgets('every option keeps a 44px touch target', (tester) async {
      await tester.pumpWidget(
        _harness(languages: [_language('en'), _language('es')]),
      );
      for (final key in const ['backend-language-en', 'backend-language-es']) {
        final size = tester.getSize(find.byKey(Key(key)));
        expect(size.height, greaterThanOrEqualTo(44));
        expect(size.width, greaterThanOrEqualTo(44));
      }
    });
  });

  group('client-keyed selection', () {
    test('each client resolves its own binding', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final workshop = languageSelectionProvider(
        UiMessageClients.workshopAdmin,
      );
      final technician = languageSelectionProvider(UiMessageClients.technician);
      expect(workshop, isNot(technician));
      expect(
        container.read(
          languageSelectionProvider(UiMessageClients.platformAdmin),
        ),
        container.read(uiMessageControllerProvider),
      );
    });
  });

  group('UiMessageApi', () {
    test('builds client-scoped manifest and bundle paths', () async {
      final requested = <String>[];
      final api = UiMessageApi.forClient(UiMessageClients.technician, (
        path,
        query,
      ) async {
        requested.add(query.isEmpty ? path : '$path?${query['lang']}');
        if (path.endsWith('/manifest')) {
          return <String, dynamic>{
            'defaultLanguage': 'en',
            'languages': <dynamic>[
              <String, dynamic>{'code': 'en', 'direction': 'ltr'},
            ],
          };
        }
        return <String, dynamic>{
          'language': 'en',
          'catalogs': <String, dynamic>{
            'technician': <String, dynamic>{'jobsTab': 'Jobs'},
          },
          'messages': <String, dynamic>{'jobsTab': 'Jobs'},
        };
      });

      final manifest = await api.manifest();
      final bundle = await api.bundle('en');
      expect(manifest.defaultLanguage, 'en');
      expect(bundle.messages['jobsTab'], 'Jobs');
      expect(requested, <String>[
        '/api/v1/i18n/ui-messages/technician/manifest',
        '/api/v1/i18n/ui-messages/technician/bundle?en',
      ]);
    });

    test('rejects unknown clients', () {
      expect(
        () => UiMessageApi.forClient('nope', (path, query) async => const {}),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('UiMessageBundle', () {
    test('keeps catalogs and builds a flat merged messages map', () {
      final bundle = UiMessageBundle.fromJson(<String, dynamic>{
        'language': 'es',
        'fallbackLanguage': 'en',
        'client': 'workshop_admin',
        'namespaces': <dynamic>['common', 'workshop_admin'],
        'catalogs': <String, dynamic>{
          'common': <String, dynamic>{'button.save': 'Guardar'},
          'workshop_admin': <String, dynamic>{
            'jobsTab': 'Trabajos',
            'button.save': 'Guardar todo',
          },
        },
      });
      expect(bundle.catalogs['workshop_admin']?['jobsTab'], 'Trabajos');
      expect(bundle.messages['jobsTab'], 'Trabajos');
      // Client namespace wins over common for a shared key.
      expect(bundle.messages['button.save'], 'Guardar todo');
    });

    test('is tolerant of scalar and malformed values', () {
      final bundle = UiMessageBundle.fromJson(<String, dynamic>{
        'language': 'en',
        'catalogs': <String, dynamic>{
          'common': <String, dynamic>{
            'count': 3,
            'enabled': true,
            'nested': <String, dynamic>{'x': 'y'},
            'nullValue': null,
          },
        },
      });
      expect(bundle.messages['count'], '3');
      expect(bundle.messages['enabled'], 'true');
      expect(bundle.messages.containsKey('nested'), isFalse);
      expect(bundle.messages.containsKey('nullValue'), isFalse);
    });

    test('accepts the legacy flat catalog shape', () {
      final bundle = UiMessageBundle.fromJson(<String, dynamic>{
        'language': 'en',
        'namespaces': <dynamic>['platform_admin'],
        'catalog': <String, dynamic>{'nav.dashboard': 'Dashboard'},
      });
      expect(bundle.catalogs['platform_admin']?['nav.dashboard'], 'Dashboard');
      expect(bundle.messages['nav.dashboard'], 'Dashboard');
    });
  });
}
