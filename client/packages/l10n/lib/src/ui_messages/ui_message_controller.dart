import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui_message_api.dart';
import 'ui_message_cache.dart';
import 'ui_message_key.dart';
import 'ui_message_manifest.dart';

final uiMessageStoreProvider = Provider<UiMessageStore>((ref) {
  return InMemoryUiMessageStore();
});

final uiMessageCacheProvider = Provider<UiMessageCache>((ref) {
  return UiMessageCache(ref.watch(uiMessageStoreProvider));
});

final uiMessageApiProvider = Provider<UiMessageApi>((ref) {
  throw UnsupportedError(
    'uiMessageApiProvider must be overridden with a real UiMessageApi',
  );
});

final uiMessageControllerProvider =
    NotifierProvider<UiMessageController, UiMessageState>(
      UiMessageController.new,
    );

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
  static const int downloadConcurrency = 3;

  bool _bootstrapStarted = false;

  @override
  UiMessageState build() => const UiMessageState();

  UiMessageCache get _cache => ref.read(uiMessageCacheProvider);

  UiMessageApi get _api => ref.read(uiMessageApiProvider);

  Future<void> bootstrap() async {
    if (_bootstrapStarted) {
      await refresh();
      return;
    }
    _bootstrapStarted = true;
    state = state.copyWith(booting: true, clearBootError: true);
    await _cache.restore();
    final restored = _cache.manifest;
    if (restored != null && !_cache.isEmpty) {
      final active = _resolveActive(restored, state.activeLanguage);
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
      final active = _resolveActive(manifest, state.activeLanguage);
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
        state = state.copyWith(booting: false, ready: false, bootError: error);
      }
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
    for (final namespace in UiMessageApi.namespaces) {
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
    if (head == 'platform_admin' || head == 'common') {
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
