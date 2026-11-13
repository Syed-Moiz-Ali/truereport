import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

Map<String, dynamic> manifestJson({
  int platformVersion = 12,
  int commonVersion = 7,
  bool withLanguageVersions = true,
}) => <String, dynamic>{
  'defaultLanguage': 'en',
  'namespaces': <String, dynamic>{
    'platform_admin': platformVersion,
    'common': commonVersion,
  },
  'languages': <dynamic>[
    <String, dynamic>{
      'code': 'en',
      'direction': 'ltr',
      if (withLanguageVersions)
        'versions': <String, dynamic>{
          'platform_admin': platformVersion,
          'common': commonVersion,
        },
    },
    <String, dynamic>{
      'code': 'ar',
      'direction': 'rtl',
      if (withLanguageVersions)
        'versions': <String, dynamic>{
          'platform_admin': platformVersion,
          'common': commonVersion,
        },
    },
  ],
};

Map<String, dynamic> bundleJson(
  String language, {
  int platformVersion = 12,
  int commonVersion = 7,
}) => <String, dynamic>{
  'language': language,
  'fallbackLanguage': 'en',
  'versions': <String, dynamic>{
    'platform_admin': platformVersion,
    'common': commonVersion,
  },
  'catalogs': <String, dynamic>{
    'platform_admin': <String, dynamic>{
      'nav.dashboard': language == 'ar' ? 'لوحة التحكم' : 'Dashboard',
      'button.save': language == 'ar' ? 'حفظ' : 'Save',
      'greeting.hello': 'Hello {name}',
    },
    'common': <String, dynamic>{
      'button.cancel': language == 'ar' ? 'إلغاء' : 'Cancel',
      'button.save': language == 'ar' ? 'حفظ عام' : 'Common Save',
    },
  },
  'missingKeys': <String, dynamic>{
    'platform_admin': <dynamic>[],
    'common': <dynamic>[],
  },
};

class FakeFetcher {
  FakeFetcher({this.manifest = const {}, this.bundles = const {}});

  Map<String, dynamic> manifest;
  Map<String, dynamic> bundles;
  final List<String> requestedBundles = <String>[];
  final Set<String> failingBundles = <String>{};
  bool failManifest = false;
  int activeFetches = 0;
  int maxConcurrentFetches = 0;

  Future<Map<String, dynamic>> call(
    String path,
    Map<String, String> query,
  ) async {
    activeFetches += 1;
    if (activeFetches > maxConcurrentFetches) {
      maxConcurrentFetches = activeFetches;
    }
    try {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      if (path == UiMessageApi.manifestPath) {
        if (failManifest) throw StateError('manifest failed');
        return manifest;
      }
      final lang = query['lang'] ?? '';
      requestedBundles.add(lang);
      if (failingBundles.contains(lang)) throw StateError('bundle $lang');
      final bundle = bundles[lang];
      if (bundle == null) throw StateError('no bundle for $lang');
      return Map<String, dynamic>.from(bundle as Map);
    } finally {
      activeFetches -= 1;
    }
  }
}

class CountingStore implements UiMessageStore {
  CountingStore([UiMessageStore? inner])
    : _inner = inner ?? InMemoryUiMessageStore();

  final UiMessageStore _inner;
  int writes = 0;
  final List<String> writtenKeys = <String>[];

  @override
  Future<String?> read(String key) => _inner.read(key);

  @override
  Future<void> write(String key, String value) async {
    writes += 1;
    writtenKeys.add(key);
    await _inner.write(key, value);
  }

  @override
  Future<void> remove(String key) => _inner.remove(key);
}

ProviderContainer makeContainer(FakeFetcher fetcher, UiMessageStore store) {
  return ProviderContainer(
    overrides: [
      uiMessageApiProvider.overrideWithValue(UiMessageApi(fetcher.call)),
      uiMessageStoreProvider.overrideWithValue(store),
    ],
  );
}

void main() {
  group('manifest contract', () {
    test('parses exact backend shape', () {
      final manifest = UiMessageManifest.fromJson(manifestJson());
      expect(manifest.defaultLanguage, 'en');
      expect(manifest.namespaceVersions, {'platform_admin': 12, 'common': 7});
      expect(manifest.codes, ['en', 'ar']);
      expect(manifest.languageFor('ar')!.isRtl, isTrue);
      expect(manifest.languageFor('en')!.isRtl, isFalse);
    });

    test('parses per-language versions', () {
      final manifest = UiMessageManifest.fromJson(manifestJson());
      expect(manifest.languageFor('en')!.versions, {
        'platform_admin': 12,
        'common': 7,
      });
      expect(manifest.languageFor('ar')!.hasVersions, isTrue);
      expect(manifest.expectedVersions('en'), {
        'platform_admin': 12,
        'common': 7,
      });
    });

    test('parses language display metadata with fallbacks', () {
      final manifest = UiMessageManifest.fromJson(<String, dynamic>{
        'defaultLanguage': 'en',
        'namespaces': {'platform_admin': 1, 'common': 1},
        'languages': [
          {
            'code': 'en',
            'direction': 'ltr',
            'nativeName': 'English',
            'nameEn': 'English',
          },
          {
            'code': 'zh-hans',
            'direction': 'ltr',
            'nativeName': '中文',
            'nameEn': 'Chinese',
          },
          {'code': 'xx', 'direction': 'ltr'},
        ],
      });
      expect(manifest.languageFor('en')!.displayName, 'English');
      expect(manifest.languageFor('zh-hans')!.displayName, '中文');
      expect(manifest.languageFor('xx')!.displayName, 'xx');
      expect(
        const UiMessageLanguage(
          code: 'yy',
          direction: 'ltr',
          nameEn: 'Yyy',
        ).displayName,
        'Yyy',
      );
    });

    test('tolerates legacy flat shape', () {
      final manifest = UiMessageManifest.fromJson(<String, dynamic>{
        'catalogVersion': 9,
        'defaultLanguage': 'en',
        'namespaces': ['platform_admin', 'common'],
        'languages': [
          {'code': 'en', 'direction': 'ltr', 'coverage': 100},
        ],
      });
      expect(manifest.namespaceVersions['platform_admin'], 0);
      expect(manifest.languageFor('en')!.version, 9);
    });

    test('old shape without versions is stale', () {
      final manifest = UiMessageManifest.fromJson(
        manifestJson(withLanguageVersions: false),
      );
      expect(manifest.languageFor('en')!.hasVersions, isFalse);
      expect(manifest.expectedVersions('en'), isEmpty);
    });

    test('round-trips through json', () {
      final manifest = UiMessageManifest.fromJson(manifestJson());
      final again = UiMessageManifest.fromJson(manifest.toJson());
      expect(again.codes, manifest.codes);
      expect(again.namespaceVersions, manifest.namespaceVersions);
      expect(again.expectedVersions('en'), manifest.expectedVersions('en'));
    });
  });

  group('bundle contract', () {
    test('parses exact backend shape', () {
      final bundle = UiMessageBundle.fromJson(bundleJson('en'));
      expect(bundle.language, 'en');
      expect(bundle.fallbackLanguage, 'en');
      expect(bundle.versions, {'platform_admin': 12, 'common': 7});
      expect(bundle.lookup('platform_admin', 'nav.dashboard'), 'Dashboard');
      expect(bundle.missingKeys['platform_admin'], isEmpty);
    });

    test('tolerates legacy flat catalog shape', () {
      final bundle = UiMessageBundle.fromJson(<String, dynamic>{
        'language': 'en',
        'fallbackLanguage': 'en',
        'version': 4,
        'namespaces': ['platform_admin'],
        'catalog': {'nav.dashboard': 'Dashboard'},
        'missingKeys': <dynamic>[],
      });
      expect(bundle.lookup('platform_admin', 'nav.dashboard'), 'Dashboard');
      expect(bundle.versions['platform_admin'], 4);
    });

    test('rejects empty catalogs', () {
      expect(
        () => UiMessageBundle.fromJson(<String, dynamic>{
          'language': 'en',
          'fallbackLanguage': 'en',
          'versions': {'platform_admin': 1},
          'catalogs': <String, dynamic>{},
        }),
        throwsFormatException,
      );
    });
  });

  group('bootstrap', () {
    test('first launch downloads every language and renders', () async {
      final fetcher = FakeFetcher(
        manifest: manifestJson(),
        bundles: {'en': bundleJson('en'), 'ar': bundleJson('ar')},
      );
      final container = makeContainer(fetcher, InMemoryUiMessageStore());
      addTearDown(container.dispose);
      await container.read(uiMessageControllerProvider.notifier).bootstrap();
      final state = container.read(uiMessageControllerProvider);
      expect(state.ready, isTrue);
      final controller = container.read(uiMessageControllerProvider.notifier);
      expect(
        controller.tKey(const UiMessageKey('platform_admin', 'nav.dashboard')),
        'Dashboard',
      );
      expect(fetcher.requestedBundles.toSet(), {'en', 'ar'});
    });

    test('one language failure never blocks the others', () async {
      final fetcher = FakeFetcher(
        manifest: manifestJson(platformVersion: 1, commonVersion: 1),
        bundles: {'en': bundleJson('en', platformVersion: 1, commonVersion: 1)},
      );
      fetcher.failingBundles.add('ar');
      final container = makeContainer(fetcher, InMemoryUiMessageStore());
      addTearDown(container.dispose);
      await container.read(uiMessageControllerProvider.notifier).bootstrap();
      final state = container.read(uiMessageControllerProvider);
      expect(state.ready, isTrue);
      expect(state.activeLanguage, 'en');
    });

    test('manifest failure without cache surfaces retry state', () async {
      final fetcher = FakeFetcher(manifest: manifestJson(), bundles: {});
      fetcher.failManifest = true;
      final container = makeContainer(fetcher, InMemoryUiMessageStore());
      addTearDown(container.dispose);
      await container.read(uiMessageControllerProvider.notifier).bootstrap();
      final state = container.read(uiMessageControllerProvider);
      expect(state.ready, isFalse);
      expect(state.bootError, isNotNull);
    });

    test('later launch renders cache immediately and skips fresh', () async {
      final store = InMemoryUiMessageStore();
      final first = FakeFetcher(
        manifest: manifestJson(),
        bundles: {'en': bundleJson('en'), 'ar': bundleJson('ar')},
      );
      final firstContainer = makeContainer(first, store);
      addTearDown(firstContainer.dispose);
      await firstContainer
          .read(uiMessageControllerProvider.notifier)
          .bootstrap();
      expect(firstContainer.read(uiMessageControllerProvider).ready, isTrue);

      final second = FakeFetcher(
        manifest: manifestJson(),
        bundles: {'en': bundleJson('en'), 'ar': bundleJson('ar')},
      );
      final secondContainer = makeContainer(second, store);
      addTearDown(secondContainer.dispose);
      await secondContainer
          .read(uiMessageControllerProvider.notifier)
          .bootstrap();
      expect(secondContainer.read(uiMessageControllerProvider).ready, isTrue);
      expect(second.requestedBundles, isEmpty);
      expect(second.maxConcurrentFetches, lessThanOrEqualTo(1));
    });

    test('namespace version bump refetches every language once', () async {
      final store = InMemoryUiMessageStore();
      final first = FakeFetcher(
        manifest: manifestJson(),
        bundles: {'en': bundleJson('en'), 'ar': bundleJson('ar')},
      );
      final firstContainer = makeContainer(first, store);
      addTearDown(firstContainer.dispose);
      await firstContainer
          .read(uiMessageControllerProvider.notifier)
          .bootstrap();

      final updated = manifestJson(platformVersion: 13);
      final second = FakeFetcher(
        manifest: updated,
        bundles: {
          'en': bundleJson('en', platformVersion: 13),
          'ar': bundleJson('ar', platformVersion: 13),
        },
      );
      final secondContainer = makeContainer(second, store);
      addTearDown(secondContainer.dispose);
      await secondContainer
          .read(uiMessageControllerProvider.notifier)
          .bootstrap();
      expect(second.requestedBundles.toSet(), {'en', 'ar'});
    });

    test('old shape without versions is treated as stale', () async {
      final store = InMemoryUiMessageStore();
      final first = FakeFetcher(
        manifest: manifestJson(),
        bundles: {'en': bundleJson('en'), 'ar': bundleJson('ar')},
      );
      final firstContainer = makeContainer(first, store);
      addTearDown(firstContainer.dispose);
      await firstContainer
          .read(uiMessageControllerProvider.notifier)
          .bootstrap();

      final second = FakeFetcher(
        manifest: manifestJson(withLanguageVersions: false),
        bundles: {'en': bundleJson('en'), 'ar': bundleJson('ar')},
      );
      final secondContainer = makeContainer(second, store);
      addTearDown(secondContainer.dispose);
      await secondContainer
          .read(uiMessageControllerProvider.notifier)
          .bootstrap();
      expect(second.requestedBundles.toSet(), {'en', 'ar'});
    });

    test('invalid cached json keeps previous behavior and refetches', () async {
      final store = InMemoryUiMessageStore();
      await store.write(
        UiMessageCache.manifestKey,
        '{"defaultLanguage": "en", "namespaces": {"platform_admin": 1, "common": 1}, "languages": [{"code": "en", "direction": "ltr", "versions": {"platform_admin": 1, "common": 1}}]}',
      );
      await store.write(UiMessageCache.bundleKey('en'), 'not-json');
      final fetcher = FakeFetcher(
        manifest: manifestJson(platformVersion: 1, commonVersion: 1),
        bundles: {
          'en': bundleJson('en', platformVersion: 1, commonVersion: 1),
          'ar': bundleJson('ar', platformVersion: 1, commonVersion: 1),
        },
      );
      final container = makeContainer(fetcher, store);
      addTearDown(container.dispose);
      await container.read(uiMessageControllerProvider.notifier).bootstrap();
      final state = container.read(uiMessageControllerProvider);
      expect(state.ready, isTrue);
      expect(fetcher.requestedBundles, contains('en'));
    });
  });

  group('atomic cache', () {
    test('store performs a single write per language', () async {
      final store = CountingStore();
      final cache = UiMessageCache(store);
      await cache.storeBundle(UiMessageBundle.fromJson(bundleJson('en')));
      expect(store.writes, 1);
      expect(store.writtenKeys, [UiMessageCache.bundleKey('en')]);
      final raw = await store.read(UiMessageCache.bundleKey('en'));
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      expect(decoded.keys.toSet(), {
        'language',
        'versions',
        'catalog',
        'missingKeys',
      });
    });

    test('single-write payload restores', () async {
      final store = InMemoryUiMessageStore();
      final cache = UiMessageCache(store);
      await cache.saveManifest(UiMessageManifest.fromJson(manifestJson()));
      await cache.storeBundle(UiMessageBundle.fromJson(bundleJson('en')));
      final fresh = UiMessageCache(store);
      await fresh.restore();
      expect(fresh.hasCatalog('en'), isTrue);
      expect(
        fresh.lookup('en', 'platform_admin', 'nav.dashboard'),
        'Dashboard',
      );
      expect(fresh.isFresh('en', {'platform_admin': 12, 'common': 7}), isTrue);
    });

    test(
      'malformed payload is rejected and keeps previous valid cache',
      () async {
        final store = InMemoryUiMessageStore();
        final cache = UiMessageCache(store);
        await cache.saveManifest(UiMessageManifest.fromJson(manifestJson()));
        await cache.storeBundle(UiMessageBundle.fromJson(bundleJson('en')));
        expect(cache.hasCatalog('en'), isTrue);

        await store.write(UiMessageCache.bundleKey('en'), 'not-json');
        await cache.restore();
        expect(cache.hasCatalog('en'), isTrue);
        expect(
          cache.lookup('en', 'platform_admin', 'nav.dashboard'),
          'Dashboard',
        );
      },
    );

    test('partial payload with missing fields is rejected', () async {
      final store = InMemoryUiMessageStore();
      final cache = UiMessageCache(store);
      await cache.saveManifest(UiMessageManifest.fromJson(manifestJson()));
      await store.write(
        UiMessageCache.bundleKey('en'),
        jsonEncode(<String, dynamic>{
          'language': 'en',
          'versions': {'platform_admin': 12, 'common': 7},
        }),
      );
      await cache.restore();
      expect(cache.hasCatalog('en'), isFalse);
    });

    test('version catalog key mismatch is rejected', () async {
      final store = InMemoryUiMessageStore();
      final cache = UiMessageCache(store);
      await cache.saveManifest(UiMessageManifest.fromJson(manifestJson()));
      await store.write(
        UiMessageCache.bundleKey('en'),
        jsonEncode(<String, dynamic>{
          'language': 'en',
          'versions': {'platform_admin': 12},
          'catalog': {
            'platform_admin': {'nav.dashboard': 'Dashboard'},
            'common': {'button.cancel': 'Cancel'},
          },
          'missingKeys': {'platform_admin': <String>[], 'common': <String>[]},
        }),
      );
      await cache.restore();
      expect(cache.hasCatalog('en'), isFalse);
    });

    test('type mismatch in versions is rejected', () async {
      final store = InMemoryUiMessageStore();
      final cache = UiMessageCache(store);
      await cache.saveManifest(UiMessageManifest.fromJson(manifestJson()));
      await store.write(
        UiMessageCache.bundleKey('en'),
        jsonEncode(<String, dynamic>{
          'language': 'en',
          'versions': {'platform_admin': 'twelve', 'common': 7},
          'catalog': {
            'platform_admin': {'nav.dashboard': 'Dashboard'},
            'common': {'button.cancel': 'Cancel'},
          },
          'missingKeys': {'platform_admin': <String>[], 'common': <String>[]},
        }),
      );
      await cache.restore();
      expect(cache.hasCatalog('en'), isFalse);
    });
  });

  group('lookup fallback', () {
    test('bare key prefers platform_admin then common', () async {
      final fetcher = FakeFetcher(
        manifest: manifestJson(),
        bundles: {'en': bundleJson('en'), 'ar': bundleJson('ar')},
      );
      final container = makeContainer(fetcher, InMemoryUiMessageStore());
      addTearDown(container.dispose);
      final controller = container.read(uiMessageControllerProvider.notifier);
      await controller.bootstrap();
      expect(controller.resolveByString('button.save'), 'Save');
      expect(controller.resolveByString('button.cancel'), 'Cancel');
      expect(controller.resolveByString('platform_admin.button.save'), 'Save');
      expect(controller.resolveByString('common.button.cancel'), 'Cancel');
    });

    test('selected falls back to default then key', () async {
      final bundles = {'en': bundleJson('en'), 'ar': bundleJson('ar')};
      (bundles['ar']!['catalogs'] as Map<String, dynamic>).remove(
        'platform_admin',
      );
      final fetcher = FakeFetcher(manifest: manifestJson(), bundles: bundles);
      final container = makeContainer(fetcher, InMemoryUiMessageStore());
      addTearDown(container.dispose);
      final controller = container.read(uiMessageControllerProvider.notifier);
      await controller.bootstrap();
      await controller.useLanguage('ar');
      expect(controller.resolveByString('nav.dashboard'), 'Dashboard');
      expect(controller.resolveByString('totally.unknown'), 'totally.unknown');
    });

    test('tArgs replaces placeholders', () async {
      final fetcher = FakeFetcher(
        manifest: manifestJson(),
        bundles: {'en': bundleJson('en'), 'ar': bundleJson('ar')},
      );
      final container = makeContainer(fetcher, InMemoryUiMessageStore());
      addTearDown(container.dispose);
      final controller = container.read(uiMessageControllerProvider.notifier);
      await controller.bootstrap();
      expect(
        controller.resolveArgsByString('greeting.hello', {'name': 'Sara'}),
        'Hello Sara',
      );
    });
  });

  group('typed keys', () {
    test('UiMessageKey value object', () {
      const key = UiMessageKey('platform_admin', 'nav.dashboard');
      expect(key.qualified, 'platform_admin.nav.dashboard');
      expect(key, const UiMessageKey('platform_admin', 'nav.dashboard'));
      expect(
        const UiMessageKey.common('button.retry'),
        const UiMessageKey('common', 'button.retry'),
      );
      expect(
        const UiMessageKey.platformAdmin('header.title'),
        const UiMessageKey('platform_admin', 'header.title'),
      );
      expect(key.toString(), 'platform_admin.nav.dashboard');
    });

    test('controller resolves typed keys with fallback', () async {
      final fetcher = FakeFetcher(
        manifest: manifestJson(),
        bundles: {'en': bundleJson('en'), 'ar': bundleJson('ar')},
      );
      final container = makeContainer(fetcher, InMemoryUiMessageStore());
      addTearDown(container.dispose);
      final controller = container.read(uiMessageControllerProvider.notifier);
      await controller.bootstrap();
      expect(
        controller.tKey(const UiMessageKey('platform_admin', 'nav.dashboard')),
        'Dashboard',
      );
      expect(
        controller.tArgsKey(
          const UiMessageKey('platform_admin', 'greeting.hello'),
          {'name': 'Sara'},
        ),
        'Hello Sara',
      );
      expect(
        controller.tKey(const UiMessageKey('platform_admin', 'nope.missing')),
        'platform_admin.nope.missing',
      );
    });

    test('UiMessageStrings resolves typed keys with fallback', () {
      const strings = UiMessageStrings(
        catalogs: {
          'en': {
            'platform_admin': {'nav.dashboard': 'Dashboard'},
          },
        },
        activeLanguage: 'ar',
        defaultLanguage: 'en',
      );
      expect(
        strings.tKey(const UiMessageKey('platform_admin', 'nav.dashboard')),
        'Dashboard',
      );
      expect(
        strings.tKey(const UiMessageKey('common', 'nope.missing')),
        'common.nope.missing',
      );
    });
  });

  group('typed-key enforcement', () {
    test('raw t()/tArgs() are not part of the app-facing API', () {
      final source = File('lib/src/ui_messages/ui_message_controller.dart')
          .readAsStringSync();
      expect(
        RegExp(r'^\s*String t\(', multiLine: true).hasMatch(source),
        isFalse,
        reason: 'public String t(String) must stay removed',
      );
      expect(
        RegExp(r'^\s*String tArgs\(', multiLine: true).hasMatch(source),
        isFalse,
        reason: 'public String tArgs(String, ...) must stay removed',
      );
      expect(source, contains('resolveByString'));
      expect(source, contains('@visibleForTesting'));
    });
  });

  group('language change', () {
    test('uses cached catalog without network', () async {
      final store = InMemoryUiMessageStore();
      final first = FakeFetcher(
        manifest: manifestJson(),
        bundles: {'en': bundleJson('en'), 'ar': bundleJson('ar')},
      );
      final firstContainer = makeContainer(first, store);
      addTearDown(firstContainer.dispose);
      await firstContainer
          .read(uiMessageControllerProvider.notifier)
          .bootstrap();

      final second = FakeFetcher(manifest: manifestJson(), bundles: {});
      second.failManifest = true;
      final secondContainer = makeContainer(second, store);
      addTearDown(secondContainer.dispose);
      final controller = secondContainer.read(
        uiMessageControllerProvider.notifier,
      );
      await controller.bootstrap();
      final switched = await controller.useLanguage('ar');
      expect(switched, isTrue);
      expect(controller.resolveByString('button.save'), 'حفظ');
      expect(second.requestedBundles, isEmpty);
    });

    test('downloads only the missing language then switches', () async {
      final fetcher = FakeFetcher(
        manifest: manifestJson(),
        bundles: {'en': bundleJson('en'), 'ar': bundleJson('ar')},
      );
      final container = makeContainer(fetcher, InMemoryUiMessageStore());
      addTearDown(container.dispose);
      final controller = container.read(uiMessageControllerProvider.notifier);
      await controller.bootstrap();
      fetcher.requestedBundles.clear();
      await container.read(uiMessageCacheProvider).evictLanguage('ar');
      final switched = await controller.useLanguage('ar');
      expect(switched, isTrue);
      expect(fetcher.requestedBundles, ['ar']);
      expect(controller.resolveByString('nav.dashboard'), 'لوحة التحكم');
    });

    test('failed switch falls back to default', () async {
      final fetcher = FakeFetcher(
        manifest: manifestJson(),
        bundles: {'en': bundleJson('en')},
      );
      fetcher.failingBundles.add('ar');
      final container = makeContainer(fetcher, InMemoryUiMessageStore());
      addTearDown(container.dispose);
      final controller = container.read(uiMessageControllerProvider.notifier);
      await controller.bootstrap();
      final switched = await controller.useLanguage('ar');
      expect(switched, isFalse);
      expect(container.read(uiMessageControllerProvider).activeLanguage, 'en');
    });

    test('localeForLanguage parses script and region codes', () {
      expect(localeForLanguage('en').languageCode, 'en');
      final hans = localeForLanguage('zh-Hans');
      expect(hans.languageCode, 'zh');
      expect(hans.scriptCode, 'Hans');
      final regional = localeForLanguage('pt-BR');
      expect(regional.languageCode, 'pt');
      expect(regional.countryCode, 'BR');
    });

    test('localeForLanguage canonicalizes backend lowercase codes', () {
      final lowerScript = localeForLanguage('zh-hans');
      expect(lowerScript.languageCode, 'zh');
      expect(lowerScript.scriptCode, 'Hans');
      final underscored = localeForLanguage('zh_Hans');
      expect(underscored.languageCode, 'zh');
      expect(underscored.scriptCode, 'Hans');
      final lowerRegion = localeForLanguage('pt-br');
      expect(lowerRegion.languageCode, 'pt');
      expect(lowerRegion.countryCode, 'BR');
      expect(localeForLanguage('zh-hans'), localeForLanguage('zh-Hans'));
    });
  });
}
