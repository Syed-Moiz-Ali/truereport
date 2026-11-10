import 'package:flutter/foundation.dart';

@immutable
class HierarchyResponse {
  const HierarchyResponse({
    required this.workshops,
    required this.totalWorkshops,
    required this.totalAccounts,
  });

  final List<HierarchyWorkshop> workshops;
  final int totalWorkshops;
  final int totalAccounts;

  factory HierarchyResponse.fromJson(Map<String, dynamic> json) {
    return HierarchyResponse(
      workshops: (json['workshops'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (item) => HierarchyWorkshop.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      totalWorkshops: json['totalWorkshops'] as int? ?? 0,
      totalAccounts: json['totalAccounts'] as int? ?? 0,
    );
  }
}

@immutable
class HierarchyWorkshop {
  const HierarchyWorkshop({
    required this.id,
    required this.name,
    required this.branchName,
    required this.status,
    required this.memberCount,
    required this.admins,
    required this.technicians,
    required this.pendingInvitations,
    this.bayCount = 8,
    this.assignedCapacityPercent = 88,
    this.contactEmail,
    this.initialTemplate,
    this.autoSyncMasterCatalog = true,
  });

  final String id;
  final String name;
  final String? branchName;
  final String status;
  final int memberCount;
  final int bayCount;
  final int assignedCapacityPercent;
  final List<PlatformAccount> admins;
  final List<PlatformAccount> technicians;
  final List<PlatformAccount> pendingInvitations;
  final String? contactEmail;
  final String? initialTemplate;
  final bool autoSyncMasterCatalog;

  List<PlatformAccount> get allAccounts => [
    ...admins,
    ...technicians,
    ...pendingInvitations,
  ];

  factory HierarchyWorkshop.fromJson(Map<String, dynamic> json) {
    List<PlatformAccount> parse(String key) =>
        (json[key] as List<dynamic>? ?? <dynamic>[])
            .map(
              (item) => PlatformAccount.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false);
    return HierarchyWorkshop(
      id: json['id'] as String,
      name: json['name'] as String,
      branchName: json['branchName'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      memberCount: json['memberCount'] as int? ?? 0,
      bayCount: json['bayCount'] as int? ?? 8,
      assignedCapacityPercent: json['assignedCapacityPercent'] as int? ?? 88,
      admins: parse('admins'),
      technicians: parse('technicians'),
      pendingInvitations: parse('pendingInvitations'),
      contactEmail: json['contactEmail'] as String?,
      initialTemplate: json['initialTemplate'] as String?,
      autoSyncMasterCatalog: json['autoSyncMasterCatalog'] as bool? ?? true,
    );
  }
}

@immutable
class PlatformAccount {
  const PlatformAccount({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.emailMasked,
    required this.role,
    required this.status,
    required this.workshopId,
    required this.primary,
    required this.invitationExpiresAt,
    this.bayAssignment,
    this.certifications,
    this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String email;
  final String emailMasked;
  final String role;
  final String status;
  final String? workshopId;
  final bool primary;
  final String? invitationExpiresAt;
  final String? bayAssignment;
  final String? certifications;
  final String? avatarUrl;

  factory PlatformAccount.fromJson(Map<String, dynamic> json) {
    return PlatformAccount(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      emailMasked: json['emailMasked'] as String? ?? '',
      role: json['role'] as String? ?? 'TECHNICIAN',
      status: json['status'] as String? ?? 'ACTIVE',
      workshopId: json['workshopId'] as String?,
      primary: json['primary'] as bool? ?? false,
      invitationExpiresAt: json['invitationExpiresAt'] as String?,
      bayAssignment: json['bayAssignment'] as String?,
      certifications: json['certifications'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

@immutable
class MasterInspectionItem {
  const MasterInspectionItem({
    required this.id,
    required this.code,
    String? name,
    String? title,
    required this.description,
    required this.category,
    required this.requirementLevel,
    required this.tags,
    this.requiresPhoto = false,
    this.requiresDualSignoff = false,
    this.telemetryLinked = false,
    this.translations = const {},
  }) : name = name ?? title ?? '';

  final String id;
  final String code;
  final String name;
  String get title => name;
  final String description;
  final String category;
  final String requirementLevel; // 'Mandatory', 'Standard', 'High Voltage Cert', 'Structural'
  final List<String> tags;
  final bool requiresPhoto;
  final bool requiresDualSignoff;
  final bool telemetryLinked;
  final Map<String, String> translations;

  factory MasterInspectionItem.fromJson(Map<String, dynamic> json) {
    return MasterInspectionItem(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['title'] as String? ?? json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      requirementLevel: json['requirementLevel'] as String? ?? 'Standard',
      tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
      requiresPhoto: json['requiresPhoto'] as bool? ?? false,
      requiresDualSignoff: json['requiresDualSignoff'] as bool? ?? false,
      telemetryLinked: json['telemetryLinked'] as bool? ?? false,
      translations: (json['translations'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, v.toString()),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'title': name,
    'description': description,
    'category': category,
    'requirementLevel': requirementLevel,
    'tags': tags,
    'requiresPhoto': requiresPhoto,
    'requiresDualSignoff': requiresDualSignoff,
    'telemetryLinked': telemetryLinked,
    'translations': translations,
  };
}

const sampleMasterInspectionItems = <MasterInspectionItem>[
  MasterInspectionItem(
    id: 'item-1',
    code: 'CHK-BRK-001',
    name: 'Brake Pad Thickness & Disc Runout',
    description: 'Micrometer disc thickness variance check and rotor',
    category: 'Brakes & Calipers',
    requirementLevel: 'Mandatory',
    tags: ['Laser Caliper Supported', 'Mandatory Photo'],
    requiresPhoto: true,
  ),
  MasterInspectionItem(
    id: 'item-2',
    code: 'CHK-PWR-014',
    name: 'Engine Oil Level & Viscosity Grade',
    description: 'Spectrometric optical degradation check and…',
    category: 'Powertrain',
    requirementLevel: 'Standard',
    tags: ['OBD Telemetry Live', 'Fluid Spec Match'],
    telemetryLinked: true,
  ),
  MasterInspectionItem(
    id: 'item-3',
    code: 'CHK-TIR-004',
    name: 'Tread Depth All Axles',
    description: 'Inner, center, and outer circumferential groove…',
    category: 'Tires & Axles',
    requirementLevel: 'Mandatory',
    tags: ['Digital Depth Gauge', 'Mandatory Photo'],
    requiresPhoto: true,
  ),
  MasterInspectionItem(
    id: 'item-4',
    code: 'CHK-EV-082',
    name: 'High-Voltage Battery Insulation',
    description: '1000V DC megohmmeter chassis isolation…',
    category: 'Powertrain',
    requirementLevel: 'High Voltage Cert',
    tags: ['Safety Gate Interlock', 'Dual Tech Signoff'],
    requiresDualSignoff: true,
  ),
  MasterInspectionItem(
    id: 'item-5',
    code: 'CHK-CHS-019',
    name: 'Chassis Subframe Torque & Bushing Play',
    description: 'Hydraulic pry bar elastomeric tear scan and…',
    category: 'Chassis Integrity',
    requirementLevel: 'Structural',
    tags: ['Acoustic Play Sensor', 'Mandatory Photo'],
    requiresPhoto: true,
  ),
];
