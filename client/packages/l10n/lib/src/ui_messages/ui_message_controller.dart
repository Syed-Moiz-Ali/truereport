import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui_message_api.dart';
import 'ui_message_cache.dart';
import 'ui_message_key.dart';
import 'ui_message_manifest.dart';

/// Persistence for the selected language and downloaded catalogs.
///
/// Defaults to in-memory; apps may override it with a durable store.
final uiMessageStoreProvider = Provider<UiMessageStore>((ref) {
  return InMemoryUiMessageStore();
});

/// The HTTP transport used to fetch manifest/bundle payloads.
///
/// Apps override this once with a fetcher backed by their `ApiClient`.
final uiMessageFetcherProvider = Provider<UiMessageFetcher>((ref) {
  throw UnsupportedError(
    'uiMessageFetcherProvider must be overridden with a real fetcher',
  );
});

/// One API bound to a client: `/api/v1/i18n/ui-messages/{client}/...`.
final uiMessageApiProvider = Provider.family<UiMessageApi, String>((
  ref,
  client,
) {
  return UiMessageApi.forClient(client, ref.watch(uiMessageFetcherProvider));
});

final uiMessageCacheProvider = Provider<UiMessageCache>((ref) {
  return UiMessageCache(ref.watch(uiMessageStoreProvider));
});

/// THE language selection provider. Keyed by client so every app shares the
/// same implementation and only the client name differs.
final languageSelectionProvider =
    NotifierProvider.family<UiMessageController, UiMessageState, String>(
      UiMessageController.new,
    );

/// Platform Admin's binding of the shared provider.
final uiMessageControllerProvider = languageSelectionProvider(
  UiMessageClients.platformAdmin,
);

/// Flat, English-filled messages for the active language of [client].
///
/// ARB-backed apps feed this into `setRemoteEnglish` so generated getters keep
/// working while the text stays backend-owned.
final uiMessageMessagesProvider = Provider.family<Map<String, String>, String>((
  ref,
  client,
) {
  final selection = ref.watch(languageSelectionProvider(client));
  if (!selection.ready) return const <String, String>{};
  return ref.read(languageSelectionProvider(client).notifier).mergedMessages();
});

class UiMessageState {
  const UiMessageState({
    this.manifest,
    this.activeLanguage = 'en',
    this.defaultLanguage = 'en',
    this.ready = false,
    this.booting = false,
    this.refreshing = false,
    this.bootError,
    this.revision = 0,
  });

  final UiMessageManifest? manifest;
  final String activeLanguage;
  final String defaultLanguage;
  final bool ready;
  final bool booting;
  final bool refreshing;
  final Object? bootError;
  final int revision;

  bool get hasCache => manifest != null;

  UiMessageState copyWith({
    UiMessageManifest? manifest,
    String? activeLanguage,
    String? defaultLanguage,
    bool? ready,
    bool? booting,
    bool? refreshing,
    Object? bootError,
    bool clearBootError = false,
    int? revision,
  }) {
    return UiMessageState(
      manifest: manifest ?? this.manifest,
      activeLanguage: activeLanguage ?? this.activeLanguage,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      ready: ready ?? this.ready,
      booting: booting ?? this.booting,
      refreshing: refreshing ?? this.refreshing,
      bootError: clearBootError ? null : bootError ?? this.bootError,
      revision: revision ?? this.revision,
    );
  }
}

class UiMessageController extends Notifier<UiMessageState> {
  UiMessageController(this.client);

  static const int downloadConcurrency = 3;

  /// One of `UiMessageClients.all`.
  final String client;

  bool _bootstrapStarted = false;
  bool _bootInFlight = false;

  @override
  UiMessageState build() => const UiMessageState();

  UiMessageCache get _cache => ref.read(uiMessageCacheProvider);

  UiMessageApi get _api => ref.read(uiMessageApiProvider(client));

  /// Client namespace first, then shared `common`: a bare key prefers the
  /// client-specific value.
  List<String> get _namespaces =>
      UiMessageClients.namespacesFor(client).reversed.toList(growable: false);

  Future<void> bootstrap() async {
    if (_bootInFlight) return;
    if (_bootstrapStarted && state.ready) {
      await refresh();
      return;
    }
    _bootInFlight = true;
    _bootstrapStarted = true;
    state = state.copyWith(booting: true, clearBootError: true);
    try {
      await _cache.restore();
      final preferred = await _cache.restoreSelectedLanguage();
      final restored = _cache.manifest;
      if (restored != null && !_cache.isEmpty) {
        final active = _resolveActive(
          restored,
          preferred ?? state.activeLanguage,
        );
        state = state.copyWith(
          manifest: restored,
          activeLanguage: active,
          defaultLanguage: restored.defaultLanguage,
          ready: _cache.hasCatalog(active),
          booting: false,
          revision: state.revision + 1,
        );
      }
      try {
        final manifest = await _api.manifest();
        await _cache.saveManifest(manifest);
        await _syncLanguages(manifest, onlyStale: true);
        final active = _resolveActive(
          manifest,
          preferred ?? state.activeLanguage,
        );
        final usable = _usableLanguage(manifest, active);
        if (usable == null) {
          throw StateError('No usable UI message catalog');
        }
        state = state.copyWith(
          manifest: manifest,
          activeLanguage: usable,
          defaultLanguage: manifest.defaultLanguage,
          ready: true,
          booting: false,
          clearBootError: true,
          revision: state.revision + 1,
        );
      } catch (error) {
        final fallback = _usableLanguage(restored, state.activeLanguage);
        if (restored != null && fallback != null) {
          state = state.copyWith(
            manifest: restored,
            activeLanguage: fallback,
            ready: true,
            booting: false,
            bootError: error,
            revision: state.revision + 1,
          );
        } else {
          state = state.copyWith(
            booting: false,
            ready: false,
            bootError: error,
          );
        }
      }
    } finally {
      _bootInFlight = false;
    }
  }

  Future<void> refresh() async {
    final manifest = state.manifest;
    if (!state.ready || manifest == null || state.refreshing) return;
    state = state.copyWith(refreshing: true);
    try {
      final fresh = await _api.manifest();
      await _cache.saveManifest(fresh);
      await _syncLanguages(fresh, onlyStale: true);
      final active = _resolveActive(fresh, state.activeLanguage);
      final usable = _usableLanguage(fresh, active) ?? state.activeLanguage;
      state = state.copyWith(
        manifest: fresh,
        activeLanguage: usable,
        defaultLanguage: fresh.defaultLanguage,
        refreshing: false,
        revision: state.revision + 1,
      );
    } catch (_) {
      state = state.copyWith(refreshing: false);
    }
  }

  Future<bool> useLanguage(String code) async {
    final manifest = state.manifest;
    if (manifest != null && manifest.languageFor(code) == null) {
      _warnMissing('language "$code" is not in the manifest');
      return _activateFallback(manifest);
    }
    if (_cache.hasCatalog(code)) {
      state = state.copyWith(
        activeLanguage: code,
        revision: state.revision + 1,
      );
      await _cache.saveSelectedLanguage(code);
      if (manifest != null) {
        final expected = manifest.expectedVersions(code);
        if (expected.isEmpty || !_cache.isFresh(code, expected)) {
          unawaited(_downloadOne(manifest, code));
        }
      }
      return true;
    }
    if (manifest == null) return false;
    final downloaded = await _downloadOne(manifest, code);
    if (downloaded) {
      state = state.copyWith(
        activeLanguage: code,
        revision: state.revision + 1,
      );
      await _cache.saveSelectedLanguage(code);
      return true;
    }
    _warnMissing('language "$code" failed to load');
    return _activateFallback(manifest);
  }

  @visibleForTesting
  String resolveByString(String key) {
    final resolved = _resolve(key, state.activeLanguage);
    if (resolved != null) return resolved;
    if (state.activeLanguage != state.defaultLanguage) {
      final fallback = _resolve(key, state.defaultLanguage);
      if (fallback != null) return fallback;
    }
    _warnMissing('key "$key"');
    return key;
  }

  @visibleForTesting
  String resolveArgsByString(String key, Map<String, Object?> args) {
    var value = resolveByString(key);
    args.forEach((name, arg) {
      value = value.replaceAll('{$name}', '${arg ?? ''}');
    });
    return value;
  }

  String tKey(UiMessageKey key) {
    final resolved = _resolveKey(key, state.activeLanguage);
    if (resolved != null) return resolved;
    if (state.activeLanguage != state.defaultLanguage) {
      final fallback = _resolveKey(key, state.defaultLanguage);
      if (fallback != null) return fallback;
    }
    _warnMissing('key "${key.qualified}"');
    return key.qualified;
  }

  String tArgsKey(UiMessageKey key, Map<String, Object?> args) {
    var value = tKey(key);
    args.forEach((name, arg) {
      value = value.replaceAll('{$name}', '${arg ?? ''}');
    });
    return value;
  }

  String directionFor(String code) {
    final language = state.manifest?.languageFor(code);
    return language?.direction ?? 'ltr';
  }

  UiMessageStrings strings() => UiMessageStrings(
    catalogs: _snapshotCatalogs(),
    activeLanguage: state.activeLanguage,
    defaultLanguage: state.defaultLanguage,
  );

  /// Flat messages for the active language, English-filled per key.
  ///
  /// Keys from `common` are applied first so the client namespace wins on a
  /// collision, matching the backend's `messages` contract.
  Map<String, String> mergedMessages() {
    final active = state.activeLanguage;
    final fallback = state.defaultLanguage;
    final namespaces = UiMessageClients.namespacesFor(client);
    final merged = <String, String>{};
    for (final language in <String>[fallback, active]) {
      for (final namespace in namespaces) {
        final snapshot = _cache.snapshot(language)[namespace];
        if (snapshot == null) continue;
        merged.addAll(snapshot);
      }
    }
    // Keep values that only exist in non-standard namespaces.
    for (final language in <String>[fallback, active]) {
      for (final entry in _cache.snapshot(language).entries) {
        if (namespaces.contains(entry.key)) continue;
        merged.addAll(entry.value);
      }
    }
    return merged;
  }

  Map<String, Map<String, Map<String, String>>> _snapshotCatalogs() {
    final result = <String, Map<String, Map<String, String>>>{};
    for (final language in _cache.cachedLanguages) {
      final namespaces = _cache.snapshot(language);
      if (namespaces.isNotEmpty) result[language] = namespaces;
    }
    return result;
  }

  String? _resolve(String key, String language) {
    final namespaced = _splitKey(key);
    if (namespaced != null) {
      return _cache.lookup(language, namespaced.$1, namespaced.$2);
    }
    for (final namespace in _namespaces) {
      final value = _cache.lookup(language, namespace, key);
      if (value != null) return value;
    }
    return null;
  }

  String? _resolveKey(UiMessageKey key, String language) {
    return _cache.lookup(language, key.namespace, key.key);
  }

  (String, String)? _splitKey(String key) {
    final dot = key.indexOf('.');
    if (dot <= 0) return null;
    final head = key.substring(0, dot);
    if (UiMessageClients.isKnown(head) || head == 'common') {
      return (head, key.substring(dot + 1));
    }
    return null;
  }

  String _resolveActive(UiMessageManifest? manifest, String current) {
    if (manifest == null) return current;
    if (manifest.languageFor(current) != null) return current;
    return manifest.defaultLanguage;
  }

  String? _usableLanguage(UiMessageManifest? manifest, String preferred) {
    if (_cache.hasCatalog(preferred)) return preferred;
    final fallback = manifest?.defaultLanguage ?? state.defaultLanguage;
    if (_cache.hasCatalog(fallback)) return fallback;
    return null;
  }

  bool _activateFallback(UiMessageManifest manifest) {
    final fallback = manifest.defaultLanguage;
    if (_cache.hasCatalog(fallback)) {
      state = state.copyWith(
        activeLanguage: fallback,
        revision: state.revision + 1,
      );
      return false;
    }
    return false;
  }

  Future<void> _syncLanguages(
    UiMessageManifest manifest, {
    required bool onlyStale,
  }) async {
    final codes = manifest.codes;
    for (var i = 0; i < codes.length; i += downloadConcurrency) {
      final end = (i + downloadConcurrency).clamp(0, codes.length);
      final chunk = codes.sublist(i, end);
      await Future.wait(
        chunk.map((code) async {
          if (onlyStale) {
            final expected = manifest.expectedVersions(code);
            if (expected.isNotEmpty && _cache.isFresh(code, expected)) {
              return;
            }
          }
          await _downloadOne(manifest, code);
        }),
      );
    }
  }

  Future<bool> _downloadOne(UiMessageManifest manifest, String code) async {
    try {
      final bundle = await _api.bundle(code);
      await _cache.storeBundle(bundle);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _warnMissing(String details) {
    assert(() {
      debugPrint('[UiMessages] missing $details');
      return true;
    }());
  }
}

class UiMessageStrings {
  const UiMessageStrings({
    required this.catalogs,
    required this.activeLanguage,
    required this.defaultLanguage,
  });

  final Map<String, Map<String, Map<String, String>>> catalogs;
  final String activeLanguage;
  final String defaultLanguage;

  String tKey(UiMessageKey key) {
    final resolved = _resolveKey(key, activeLanguage);
    if (resolved != null) return resolved;
    if (activeLanguage != defaultLanguage) {
      final fallback = _resolveKey(key, defaultLanguage);
      if (fallback != null) return fallback;
    }
    return key.qualified;
  }

  String tArgsKey(UiMessageKey key, Map<String, Object?> args) {
    var value = tKey(key);
    args.forEach((name, arg) {
      value = value.replaceAll('{$name}', '${arg ?? ''}');
    });
    return value;
  }

  /// Resolves a runtime-qualified key such as `platform_admin.some.key`.
  ///
  /// Returns null when the key is malformed or absent from every catalog.
  String? resolveQualifiedKey(String qualified) {
    final dot = qualified.indexOf('.');
    if (dot <= 0 || dot == qualified.length - 1) return null;
    final namespace = qualified.substring(0, dot);
    final key = qualified.substring(dot + 1);
    return catalogs[activeLanguage]?[namespace]?[key] ??
        catalogs[defaultLanguage]?[namespace]?[key];
  }

  /// Resolves a flat backend key (for example a reference `labelKey`) through
  /// the active catalog, then the default catalog. Returns null when absent.
  String? resolveFlatKey(String key) {
    if (key.isEmpty) return null;
    for (final language in <String>[activeLanguage, defaultLanguage]) {
      final namespaces = catalogs[language];
      if (namespaces == null) continue;
      for (final catalog in namespaces.values) {
        final value = catalog[key];
        if (value != null && value.isNotEmpty) return value;
      }
    }
    return null;
  }

  /// Chooses the English message when a legacy bilingual pair is supplied.
  ///
  /// Arabic is no longer a supported locale, so the English side always wins;
  /// the signature is kept so existing call sites keep compiling.
  String pickBilingual({required String en, required String ar}) {
    if (en.isNotEmpty) return en;
    return ar;
  }

  String? _resolveKey(UiMessageKey key, String language) {
    return catalogs[language]?[key.namespace]?[key.key];
  }
}

Locale localeForLanguage(String code) {
  final parts = code
      .replaceAll('_', '-')
      .split('-')
      .where((p) => p.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return const Locale('en');
  final language = parts[0].toLowerCase();
  if (parts.length == 1) return Locale(language);
  if (parts.length == 2 && parts[1].length == 4) {
    final script =
        parts[1][0].toUpperCase() + parts[1].substring(1).toLowerCase();
    return Locale.fromSubtags(languageCode: language, scriptCode: script);
  }
  if (parts.length == 2) {
    return Locale.fromSubtags(
      languageCode: language,
      countryCode: parts[1].toUpperCase(),
    );
  }
  return Locale(language);
}
