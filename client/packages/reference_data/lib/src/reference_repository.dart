import 'package:api_client/api_client.dart';

import 'models.dart';
import 'reference_store.dart';

const String _statusesPath = '/api/v1/reference/statuses';
const String _enumsPath = '/api/v1/reference/enums';
const String _transitionsPath = '/api/v1/reference/transitions';
const String _dropdownsPath = '/api/v1/reference/dropdowns';

class _CacheEntry<T> {
  const _CacheEntry(this.value, this.etag);

  final T value;
  final String? etag;
}

/// ETag-aware reference-data client with in-memory and persistent caches.
///
/// The repository returns keys (`labelKey`) and tone tokens only; it never
/// resolves or stores English text.
class ReferenceRepository {
  ReferenceRepository(this._api, {ReferenceStore? store})
    : _store = store ?? InMemoryReferenceStore();

  final ApiClient _api;
  final ReferenceStore _store;
  final Map<String, _CacheEntry<dynamic>> _memory =
      <String, _CacheEntry<dynamic>>{};

  Future<List<ReferenceRecord>> statuses(
    String statusType, {
    bool includeDraft = false,
  }) {
    return _cached<List<ReferenceRecord>>(
      'statuses:$statusType:${includeDraft ? 'draft' : 'live'}',
      '$_statusesPath/$statusType',
      parseRecords,
      query: includeDraft
          ? const <String, dynamic>{'includeDraft': 'true'}
          : null,
    );
  }

  Future<List<ReferenceRecord>> enums(
    String enumCode, {
    bool includeDraft = false,
  }) {
    return _cached<List<ReferenceRecord>>(
      'enums:$enumCode:${includeDraft ? 'draft' : 'live'}',
      '$_enumsPath/$enumCode',
      parseRecords,
      query: includeDraft
          ? const <String, dynamic>{'includeDraft': 'true'}
          : null,
    );
  }

  Future<List<ReferenceValue>> dropdown(String setCode) {
    return _cached<List<ReferenceValue>>(
      'dropdowns:$setCode',
      '$_dropdownsPath/$setCode',
      parseValues,
    );
  }

  Future<StatusTransitions> transitions(String entity) {
    return _cached<StatusTransitions>(
      'transitions:$entity',
      '$_transitionsPath/$entity',
      (data) => StatusTransitions.fromJson(data, entity: entity),
    );
  }

  Future<List<ReferenceTransition>> transitionRules(String entity) {
    return _cached<List<ReferenceTransition>>(
      'transitionRules:$entity',
      '$_transitionsPath/$entity',
      parseTransitions,
    );
  }

  Future<T> _cached<T>(
    String key,
    String path,
    T Function(Object? data) parse, {
    Map<String, dynamic>? query,
  }) async {
    final cached = _memory[key];
    try {
      final response = await _api.getConditional(
        path,
        query: query,
        etag: cached?.etag,
      );
      if (response.notModified && cached != null) {
        return cached.value as T;
      }
      final value = parse(response.data);
      _memory[key] = _CacheEntry<T>(value, response.etag);
      await _store.write(key, encodeCacheEntry(response.etag, response.data));
      return value;
    } on Object {
      if (cached != null) return cached.value as T;
      final raw = await _store.read(key);
      if (raw != null) {
        final decoded = decodeCacheEntry(raw);
        if (decoded != null) {
          final value = parse(decoded.data);
          _memory[key] = _CacheEntry<T>(value, decoded.etag);
          return value;
        }
      }
      rethrow;
    }
  }
}
