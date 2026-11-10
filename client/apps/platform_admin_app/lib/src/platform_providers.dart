import 'dart:ui';
import 'package:auth/auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'platform_api.dart';
import 'platform_models.dart';

final platformApiProvider = Provider<PlatformAdminApi>((ref) {
  return HttpPlatformAdminApi(
    ref.watch(apiClientProvider),
    ref.watch(apiEndpointsProvider),
  );
});

class SelectedWorkshopNotifier extends Notifier<String> {
  @override
  String build() => 'workshop-1';

  void select(String id) => state = id;
}

final selectedWorkshopIdProvider =
    NotifierProvider<SelectedWorkshopNotifier, String>(
      SelectedWorkshopNotifier.new,
    );

class StaffSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final staffSearchQueryProvider =
    NotifierProvider<StaffSearchNotifier, String>(
      StaffSearchNotifier.new,
    );

class StaffFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setFilter(String filter) => state = filter;
}

final staffRoleFilterProvider =
    NotifierProvider<StaffFilterNotifier, String>(
      StaffFilterNotifier.new,
    );

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('en');

  void setLocale(Locale locale) => state = locale;
  void toggleLocale() {
    state = state.languageCode == 'en' ? const Locale('ar') : const Locale('en');
  }
}

final platformLocaleProvider =
    NotifierProvider<LocaleNotifier, Locale>(
      LocaleNotifier.new,
    );

class AddStaffPanelNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void open() => state = true;
  void close() => state = false;
  void toggle() => state = !state;
}

final addStaffPanelOpenProvider =
    NotifierProvider<AddStaffPanelNotifier, bool>(
      AddStaffPanelNotifier.new,
    );

class MasterCategoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All Categories';

  void setCategory(String category) => state = category;
}

final masterCategoryFilterProvider =
    NotifierProvider<MasterCategoryFilterNotifier, String>(
      MasterCategoryFilterNotifier.new,
    );

class MasterItemSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final masterItemSearchQueryProvider =
    NotifierProvider<MasterItemSearchNotifier, String>(
      MasterItemSearchNotifier.new,
    );

class MasterItemsListNotifier extends Notifier<List<MasterInspectionItem>> {
  @override
  List<MasterInspectionItem> build() => sampleMasterInspectionItems;

  void addItem(MasterInspectionItem item) {
    state = [...state, item];
  }

  void updateItem(MasterInspectionItem item) {
    state = state.map((i) => i.id == item.id ? item : i).toList();
  }

  void deleteItem(String id) {
    state = state.where((i) => i.id != id).toList();
  }
}

final masterItemsListProvider =
    NotifierProvider<MasterItemsListNotifier, List<MasterInspectionItem>>(
      MasterItemsListNotifier.new,
    );

/// Default sample data matching Figma Screen 1: "1. Global Hierarchy & Staff Tree"
const sampleWorkshopAStaff = [
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

const sampleWorkshops = [
  HierarchyWorkshop(
    id: 'workshop-1',
    name: 'Workshop A',
    branchName: 'EMEA Industrial Hub',
    status: 'ACTIVE',
    memberCount: 14,
    bayCount: 8,
    assignedCapacityPercent: 88,
    admins: [],
    technicians: sampleWorkshopAStaff,
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

class LocalWorkshopsNotifier extends Notifier<List<HierarchyWorkshop>> {
  @override
  List<HierarchyWorkshop> build() => sampleWorkshops;

  void addWorkshop(HierarchyWorkshop workshop) {
    state = [...state, workshop];
  }
}

final localWorkshopsProvider =
    NotifierProvider<LocalWorkshopsNotifier, List<HierarchyWorkshop>>(
      LocalWorkshopsNotifier.new,
    );

final hierarchyStateProvider =
    FutureProvider.autoDispose<HierarchyResponse>((ref) async {
  final api = ref.watch(platformApiProvider);
  try {
    return await api.hierarchy();
  } catch (_) {
    final localWorkshops = ref.watch(localWorkshopsProvider);
    final totalAccounts = localWorkshops.fold<int>(
      0,
      (sum, w) => sum + w.allAccounts.length + w.memberCount,
    );
    return HierarchyResponse(
      workshops: localWorkshops,
      totalWorkshops: localWorkshops.length,
      totalAccounts: totalAccounts > 0 ? totalAccounts : 23,
    );
  }
});
