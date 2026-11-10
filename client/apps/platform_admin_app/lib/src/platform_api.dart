import 'package:api_client/api_client.dart';
import 'package:uuid/uuid.dart';
import 'platform_models.dart';

abstract class PlatformAdminApi {
  Future<HierarchyResponse> hierarchy({String search = '', String status = ''});
  Future<HierarchyWorkshop> workshopDetail(String workshopId);
  Future<PlatformAccount> createUser({
    required String email,
    required String displayName,
    required String temporaryPassword,
    required String role,
    required String workshopId,
    String? bayAssignment,
    String? certifications,
  });
  Future<HierarchyWorkshop> registerWorkshop({
    required String name,
    required String location,
    required String contactEmail,
    required String initialTemplate,
    bool autoSyncMasterCatalog = true,
  });
  Future<PlatformAccount> disableUser(String userId, String reason);
  Future<PlatformAccount> reactivateUser(String userId, String reason);
}

class HttpPlatformAdminApi implements PlatformAdminApi {
  HttpPlatformAdminApi(this._api, this._endpoints);

  final ApiClient _api;
  final ApiEndpoints _endpoints;

  @override
  Future<HierarchyResponse> hierarchy({
    String search = '',
    String status = '',
  }) async {
    final data = await _api.getDynamic(
      _endpoints.hierarchy,
      query: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (status.trim().isNotEmpty) 'status': status.trim(),
      },
    );
    return HierarchyResponse.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<HierarchyWorkshop> workshopDetail(String workshopId) async {
    final data = await _api.getDynamic(
      _endpoints.workshopHierarchy(workshopId),
    );
    return HierarchyWorkshop.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<PlatformAccount> createUser({
    required String email,
    required String displayName,
    required String temporaryPassword,
    required String role,
    required String workshopId,
    String? bayAssignment,
    String? certifications,
  }) async {
    final data = await _api.postDynamic(
      _endpoints.platformUsers,
      headers: {'Idempotency-Key': const Uuid().v7()},
      body: {
        'email': email,
        'displayName': displayName,
        'temporaryPassword': temporaryPassword,
        'role': role,
        'workshopId': workshopId,
        'bayAssignment': ?bayAssignment,
        'certifications': ?certifications,
      },
    );
    return PlatformAccount.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<HierarchyWorkshop> registerWorkshop({
    required String name,
    required String location,
    required String contactEmail,
    required String initialTemplate,
    bool autoSyncMasterCatalog = true,
  }) async {
    final data = await _api.postDynamic(
      _endpoints.platformWorkshops,
      headers: {'Idempotency-Key': const Uuid().v7()},
      body: {
        'name': name,
        'location': location,
        'contactEmail': contactEmail,
        'initialTemplate': initialTemplate,
        'autoSyncMasterCatalog': autoSyncMasterCatalog,
      },
    );
    return HierarchyWorkshop.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<PlatformAccount> disableUser(String userId, String reason) async {
    final data = await _api.postDynamic(
      _endpoints.disableUser(userId),
      body: {'reason': reason},
    );
    return PlatformAccount.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<PlatformAccount> reactivateUser(String userId, String reason) async {
    final data = await _api.postDynamic(
      _endpoints.reactivateUser(userId),
      body: {'reason': reason},
    );
    return PlatformAccount.fromJson(data as Map<String, dynamic>);
  }
}
