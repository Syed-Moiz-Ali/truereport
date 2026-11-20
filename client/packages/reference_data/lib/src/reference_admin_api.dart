import 'package:api_client/api_client.dart';

import 'models.dart';

/// Write contract for the reference taxonomy.
///
/// A separate interface keeps the UI testable without a live HTTP client while
/// [ReferenceAdminApi] stays the only implementation that talks to the API.
abstract interface class ReferenceAdminActions {
  Future<ReferenceRecord> createStatus(String type, ReferenceWrite write);

  Future<ReferenceRecord> updateStatus(
    String type,
    String code,
    ReferenceWrite write,
  );

  Future<ReferenceRecord> publishStatus(String type, String code);

  Future<ReferenceRecord> retireStatus(String type, String code);

  Future<List<ReferenceRecord>> reorderStatuses(
    String type,
    List<({String code, int order})> entries,
  );

  Future<ReferenceRecord> createEnum(String enumCode, ReferenceWrite write);

  Future<ReferenceRecord> updateEnum(
    String enumCode,
    String code,
    ReferenceWrite write,
  );

  Future<ReferenceRecord> publishEnum(String enumCode, String code);

  Future<ReferenceRecord> retireEnum(String enumCode, String code);

  Future<List<ReferenceRecord>> reorderEnums(
    String enumCode,
    List<({String code, int order})> entries,
  );

  Future<List<ReferenceTransition>> replaceTransitions(
    String entity,
    List<ReferenceTransition> entries,
  );

  Future<ReferenceImpact> impact(String domain, String code);
}

/// Platform-only writer for the reference taxonomy.
///
/// Reads stay in [ReferenceRepository]; this class only performs the write
/// contract (create/update/publish/retire/reorder/transitions/impact).
class ReferenceAdminApi implements ReferenceAdminActions {
  const ReferenceAdminApi(this._api);

  static const String _base = '/api/v1/reference';

  final ApiClient _api;

  @override
  Future<ReferenceRecord> createStatus(
    String type,
    ReferenceWrite write,
  ) async {
    final data = await _api.postDynamic(
      '$_base/statuses/$type',
      body: write.toJson(),
    );
    return ReferenceRecord.fromJson(asMap(data));
  }

  @override
  Future<ReferenceRecord> updateStatus(
    String type,
    String code,
    ReferenceWrite write,
  ) async {
    final data = await _api.putDynamic(
      '$_base/statuses/$type/$code',
      body: write.toJson(),
    );
    return ReferenceRecord.fromJson(asMap(data));
  }

  @override
  Future<ReferenceRecord> publishStatus(String type, String code) async {
    final data = await _api.postDynamic('$_base/statuses/$type/$code/publish');
    return ReferenceRecord.fromJson(asMap(data));
  }

  @override
  Future<ReferenceRecord> retireStatus(String type, String code) async {
    final data = await _api.postDynamic('$_base/statuses/$type/$code/retire');
    return ReferenceRecord.fromJson(asMap(data));
  }

  @override
  Future<List<ReferenceRecord>> reorderStatuses(
    String type,
    List<({String code, int order})> entries,
  ) async {
    final data = await _api.putDynamic(
      '$_base/statuses/$type/reorder',
      body: <Map<String, Object?>>[
        for (final entry in entries)
          <String, Object?>{'code': entry.code, 'order': entry.order},
      ],
    );
    return parseRecords(data);
  }

  @override
  Future<ReferenceRecord> createEnum(String code, ReferenceWrite write) async {
    final data = await _api.postDynamic(
      '$_base/enums/$code',
      body: write.toJson(),
    );
    return ReferenceRecord.fromJson(asMap(data));
  }

  @override
  Future<ReferenceRecord> updateEnum(
    String enumCode,
    String code,
    ReferenceWrite write,
  ) async {
    final data = await _api.putDynamic(
      '$_base/enums/$enumCode/$code',
      body: write.toJson(),
    );
    return ReferenceRecord.fromJson(asMap(data));
  }

  @override
  Future<ReferenceRecord> publishEnum(String enumCode, String code) async {
    final data = await _api.postDynamic('$_base/enums/$enumCode/$code/publish');
    return ReferenceRecord.fromJson(asMap(data));
  }

  @override
  Future<ReferenceRecord> retireEnum(String enumCode, String code) async {
    final data = await _api.postDynamic('$_base/enums/$enumCode/$code/retire');
    return ReferenceRecord.fromJson(asMap(data));
  }

  @override
  Future<List<ReferenceRecord>> reorderEnums(
    String enumCode,
    List<({String code, int order})> entries,
  ) async {
    final data = await _api.putDynamic(
      '$_base/enums/$enumCode/reorder',
      body: <Map<String, Object?>>[
        for (final entry in entries)
          <String, Object?>{'code': entry.code, 'order': entry.order},
      ],
    );
    return parseRecords(data);
  }

  @override
  Future<List<ReferenceTransition>> replaceTransitions(
    String entity,
    List<ReferenceTransition> entries,
  ) async {
    final data = await _api.putDynamic(
      '$_base/transitions/$entity',
      body: <Map<String, Object?>>[for (final entry in entries) entry.toJson()],
    );
    return parseTransitions(data);
  }

  @override
  Future<ReferenceImpact> impact(String domain, String code) async {
    final data = await _api.getDynamic('$_base/$domain/$code/impact');
    return ReferenceImpact.fromJson(asMap(data));
  }
}
