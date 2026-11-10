import 'package:platform_admin_app/src/platform_api.dart';
import 'package:platform_admin_app/src/platform_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';

class FakePlatformAdminApi implements PlatformAdminApi {
  List<HierarchyWorkshop> workshops = sampleWorkshops;

  @override
  Future<HierarchyResponse> hierarchy({
    String search = '',
    String status = '',
  }) async {
    return HierarchyResponse(
      workshops: workshops,
      totalWorkshops: workshops.length,
      totalAccounts: 23,
    );
  }

  @override
  Future<HierarchyWorkshop> workshopDetail(String workshopId) async {
    return workshops.firstWhere((w) => w.id == workshopId);
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
    final account = PlatformAccount(
      userId: 'user-${DateTime.now().millisecondsSinceEpoch}',
      displayName: displayName,
      email: email,
      emailMasked: email,
      role: role,
      status: 'ACTIVE',
      workshopId: workshopId,
      primary: false,
      invitationExpiresAt: null,
      bayAssignment: bayAssignment,
      certifications: certifications,
    );
    return account;
  }

  @override
  Future<HierarchyWorkshop> registerWorkshop({
    required String name,
    required String location,
    required String contactEmail,
    required String initialTemplate,
    bool autoSyncMasterCatalog = true,
  }) async {
    final workshop = HierarchyWorkshop(
      id: 'workshop-${workshops.length + 1}',
      name: name,
      branchName: location,
      status: 'ACTIVE',
      memberCount: 1,
      bayCount: 6,
      assignedCapacityPercent: 0,
      contactEmail: contactEmail,
      initialTemplate: initialTemplate,
      autoSyncMasterCatalog: autoSyncMasterCatalog,
      admins: [],
      technicians: [],
      pendingInvitations: [],
    );
    workshops = [...workshops, workshop];
    return workshop;
  }

  @override
  Future<PlatformAccount> disableUser(String userId, String reason) async {
    return PlatformAccount(
      userId: userId,
      displayName: 'Disabled',
      email: '',
      emailMasked: '',
      role: 'TECHNICIAN',
      status: 'DISABLED',
      workshopId: null,
      primary: false,
      invitationExpiresAt: null,
    );
  }

  @override
  Future<PlatformAccount> reactivateUser(String userId, String reason) async {
    return PlatformAccount(
      userId: userId,
      displayName: 'Reactivated',
      email: '',
      emailMasked: '',
      role: 'TECHNICIAN',
      status: 'ACTIVE',
      workshopId: null,
      primary: false,
      invitationExpiresAt: null,
    );
  }
}
