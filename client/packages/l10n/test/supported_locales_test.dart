import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

UiMessageLanguage _language(String code) => UiMessageLanguage(
  code: code,
  direction: 'ltr',
  nativeName: switch (code) {
    'en' => 'English',
    'es' => 'Español',
    'fr' => 'Français',
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
}

void main() {
  group('supportedLocalesFor', () {
    test('every advertised language becomes a supported locale', () {
      final locales = supportedLocalesFor(
        _manifest([_language('en'), _language('es'), _language('fr')]),
        const Locale('en'),
      );

      expect(locales.map((locale) => locale.languageCode), <String>[
        'en',
        'es',
        'fr',
      ]);
    });

    test('the active locale is always included', () {
      final locales = supportedLocalesFor(
        _manifest([_language('en'), _language('es')]),
        const Locale('de'),
      );

      expect(
        locales.map((locale) => locale.languageCode),
        containsAll(<String>['en', 'es', 'de']),
      );
    });

    test('an empty manifest falls back to English', () {
      final locales = supportedLocalesFor(null, const Locale('en'));

      expect(locales, <Locale>[const Locale('en')]);
    });
  });

  group('supportedLocalesProvider', () {
    test('reads the manifest from the client-keyed fake provider', () {
      final container = ProviderContainer(
        overrides: [
          languageSelectionProvider(UiMessageClients.workshopAdmin)
              .overrideWith(
                () => _FakeController([
                  _language('en'),
                  _language('es'),
                  _language('fr'),
                ]),
              ),
        ],
      );
      addTearDown(container.dispose);

      final locales = container.read(
        supportedLocalesProvider(UiMessageClients.workshopAdmin),
      );

      expect(locales.map((locale) => locale.languageCode), <String>[
        'en',
        'es',
        'fr',
      ]);
    });

    test('a client with no manifest keeps English supported', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final locales = container.read(
        supportedLocalesProvider(UiMessageClients.technician),
      );

      expect(locales, <Locale>[const Locale('en')]);
    });
  });
}
