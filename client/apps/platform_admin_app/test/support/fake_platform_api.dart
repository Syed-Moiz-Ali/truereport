import 'package:platform_admin_app/src/platform_api.dart';
import 'package:platform_admin_app/src/platform_models.dart';

const _sampleWorkshops = <HierarchyWorkshop>[
  HierarchyWorkshop(
    id: 'workshop-1',
    name: 'Workshop A',
    branchName: 'EMEA Industrial Hub',
    status: 'ACTIVE',
    memberCount: 14,
    bayCount: 8,
    assignedCapacityPercent: 88,
    admins: [],
    technicians: _sampleStaff,
    pendingInvitations: [],
  ),
  HierarchyWorkshop(
    id: 'workshop-2',
    name: 'Workshop B',
    branchName: 'Dubai North Station',
    status: 'STANDBY',
    memberCount: 9,
    bayCount: 4,
    assignedCapacityPercent: 45,
    admins: [],
    technicians: [],
    pendingInvitations: [],
  ),
  HierarchyWorkshop(
    id: 'workshop-3',
    name: 'Workshop C',
    branchName: 'Central Depot Hub',
    status: 'DEPOT HUB',
    memberCount: 0,
    bayCount: 12,
    assignedCapacityPercent: 15,
    admins: [],
    technicians: [],
    pendingInvitations: [],
  ),
];

const _sampleStaff = <PlatformAccount>[
  PlatformAccount(
    userId: 'staff-1',
    displayName: 'David Miller',
    email: 'david.miller@workshop-a.local',
    emailMasked: 'd***@workshop-a.local',
    role: 'Lead Inspector',
    status: 'ACTIVE',
    workshopId: 'workshop-1',
    primary: true,
    invitationExpiresAt: null,
    bayAssignment: 'Bay 01-04',
    certifications: 'Level 3 Master',
  ),
  PlatformAccount(
    userId: 'staff-2',
    displayName: 'Marcus Vance',
    email: 'marcus.vance@workshop-a.local',
    emailMasked: 'm***@workshop-a.local',
    role: 'Diagnostic Tech',
    status: 'ACTIVE',
    workshopId: 'workshop-1',
    primary: false,
    invitationExpiresAt: null,
    bayAssignment: 'Diagnostics Bay',
    certifications: 'CAN Bus / EV High-V',
  ),
  PlatformAccount(
    userId: 'staff-3',
    displayName: 'Sarah Jenkins',
    email: 'sarah.jenkins@workshop-a.local',
    emailMasked: 's***@workshop-a.local',
    role: 'Shop Floor Supervisor',
    status: 'ACTIVE',
    workshopId: 'workshop-1',
    primary: false,
    invitationExpiresAt: null,
    bayAssignment: 'Floor Command',
    certifications: 'Lead Quality Certified',
  ),
  PlatformAccount(
    userId: 'staff-4',
    displayName: 'Elena Rostova',
    email: 'elena.rostova@workshop-a.local',
    emailMasked: 'e***@workshop-a.local',
    role: 'Optics & Sensor Calibration',
    status: 'ACTIVE',
    workshopId: 'workshop-1',
    primary: false,
    invitationExpiresAt: null,
    bayAssignment: 'ADAS Align',
    certifications: 'Bosch / Hella ADAS',
  ),
];

class FakePlatformAdminApi implements PlatformAdminApi {
  List<HierarchyWorkshop> workshops = _sampleWorkshops;

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
