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
  });

  final String id;
  final String name;
  final String? branchName;
  final String status;
  final int memberCount;
  final List<PlatformAccount> admins;
  final List<PlatformAccount> technicians;
  final List<PlatformAccount> pendingInvitations;

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
      admins: parse('admins'),
      technicians: parse('technicians'),
      pendingInvitations: parse('pendingInvitations'),
    );
  }
}

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

  factory PlatformAccount.fromJson(Map<String, dynamic> json) {
    return PlatformAccount(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      emailMasked: json['emailMasked'] as String? ?? '',
      role: json['role'] as String? ?? '',
      status: json['status'] as String? ?? '',
      workshopId: json['workshopId'] as String?,
      primary: json['primary'] as bool? ?? false,
      invitationExpiresAt: json['invitationExpiresAt'] as String?,
    );
  }
}

class Category {
  const Category({
    required this.id,
    required this.slug,
    required this.status,
    required this.sortOrder,
    required this.labelEn,
    required this.labelAr,
    required this.itemCount,
  });

  final String id;
  final String slug;
  final String status;
  final int sortOrder;
  final String labelEn;
  final String labelAr;
  final int itemCount;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    slug: json['slug'] as String,
    status: json['status'] as String,
    sortOrder: json['sortOrder'] as int? ?? 0,
    labelEn: json['labelEn'] as String? ?? '',
    labelAr: json['labelAr'] as String? ?? '',
    itemCount: json['itemCount'] as int? ?? 0,
  );
}

class ItemSummary {
  const ItemSummary({
    required this.id,
    required this.stableCode,
    required this.categoryId,
    required this.categoryLabelEn,
    required this.categoryLabelAr,
    required this.status,
    required this.currentVersion,
    required this.labelEn,
    required this.labelAr,
    required this.sampleData,
    required this.updatedAt,
  });

  final String id;
  final String stableCode;
  final String categoryId;
  final String categoryLabelEn;
  final String categoryLabelAr;
  final String status;
  final int? currentVersion;
  final String labelEn;
  final String labelAr;
  final bool sampleData;
  final String updatedAt;

  factory ItemSummary.fromJson(Map<String, dynamic> json) => ItemSummary(
    id: json['id'] as String,
    stableCode: json['stableCode'] as String,
    categoryId: json['categoryId'] as String,
    categoryLabelEn: json['categoryLabelEn'] as String? ?? '',
    categoryLabelAr: json['categoryLabelAr'] as String? ?? '',
    status: json['status'] as String? ?? 'DRAFT',
    currentVersion: json['currentVersion'] as int?,
    labelEn: json['labelEn'] as String? ?? '',
    labelAr: json['labelAr'] as String? ?? '',
    sampleData: json['sampleData'] as bool? ?? false,
    updatedAt: json['updatedAt'] as String? ?? '',
  );
}

class Translation {
  const Translation({
    required this.locale,
    required this.label,
    required this.instruction,
  });

  final String locale;
  final String label;
  final String instruction;

  factory Translation.fromJson(Map<String, dynamic> json) => Translation(
    locale: json['locale'] as String? ?? '',
    label: json['label'] as String? ?? '',
    instruction: json['instruction'] as String? ?? '',
  );
}

class ItemVersion {
  const ItemVersion({
    required this.id,
    required this.versionNo,
    required this.status,
    required this.resultOptions,
    required this.severityPolicy,
    required this.applicability,
    required this.reasonCodes,
    required this.noteRequirement,
    required this.evidenceRequirement,
    required this.minPhotos,
    required this.equipmentIds,
    required this.guideImageId,
    required this.publishedAt,
    required this.translations,
  });

  final String id;
  final int versionNo;
  final String status;
  final List<String> resultOptions;
  final String severityPolicy;
  final String applicability;
  final List<String> reasonCodes;
  final String noteRequirement;
  final String evidenceRequirement;
  final int minPhotos;
  final List<String> equipmentIds;
  final String? guideImageId;
  final String? publishedAt;
  final Map<String, Translation> translations;

  factory ItemVersion.fromJson(Map<String, dynamic> json) {
    final translationsJson =
        json['translations'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return ItemVersion(
      id: json['id'] as String,
      versionNo: json['versionNo'] as int,
      status: json['status'] as String,
      resultOptions: _strings(json['resultOptions']),
      severityPolicy: json['severityPolicy'] as String? ?? '{}',
      applicability: json['applicability'] as String? ?? '{}',
      reasonCodes: _strings(json['reasonCodes']),
      noteRequirement: json['noteRequirement'] as String? ?? 'OPTIONAL',
      evidenceRequirement: json['evidenceRequirement'] as String? ?? 'NONE',
      minPhotos: json['minPhotos'] as int? ?? 0,
      equipmentIds: _strings(json['equipmentIds']),
      guideImageId: json['guideImageId'] as String?,
      publishedAt: json['publishedAt'] as String?,
      translations: translationsJson.map(
        (key, value) =>
            MapEntry(key, Translation.fromJson(value as Map<String, dynamic>)),
      ),
    );
  }

  Translation translation(String locale) =>
      translations[locale] ??
      Translation(locale: locale, label: '', instruction: '');
}

class ItemDetail {
  const ItemDetail({required this.item, required this.versions});

  final ItemSummary item;
  final List<ItemVersion> versions;

  factory ItemDetail.fromJson(Map<String, dynamic> json) => ItemDetail(
    item: ItemSummary.fromJson(json['item'] as Map<String, dynamic>),
    versions: (json['versions'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => ItemVersion.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );

  ItemVersion? get draft {
    for (final version in versions) {
      if (version.status == 'DRAFT') {
        return version;
      }
    }
    return null;
  }
}

class Reason {
  const Reason({
    required this.id,
    required this.code,
    required this.status,
    required this.sortOrder,
    required this.labelEn,
    required this.labelAr,
  });

  final String id;
  final String code;
  final String status;
  final int sortOrder;
  final String labelEn;
  final String labelAr;

  factory Reason.fromJson(Map<String, dynamic> json) => Reason(
    id: json['id'] as String,
    code: json['code'] as String,
    status: json['status'] as String? ?? 'ACTIVE',
    sortOrder: json['sortOrder'] as int? ?? 0,
    labelEn: json['labelEn'] as String? ?? '',
    labelAr: json['labelAr'] as String? ?? '',
  );
}

class Equipment {
  const Equipment({
    required this.id,
    required this.code,
    required this.status,
    required this.sortOrder,
    required this.labelEn,
    required this.labelAr,
  });

  final String id;
  final String code;
  final String status;
  final int sortOrder;
  final String labelEn;
  final String labelAr;

  factory Equipment.fromJson(Map<String, dynamic> json) => Equipment(
    id: json['id'] as String,
    code: json['code'] as String,
    status: json['status'] as String? ?? 'ACTIVE',
    sortOrder: json['sortOrder'] as int? ?? 0,
    labelEn: json['labelEn'] as String? ?? '',
    labelAr: json['labelAr'] as String? ?? '',
  );
}

class Dropdown {
  const Dropdown({
    required this.id,
    required this.code,
    required this.status,
    required this.sortOrder,
    required this.labelEn,
    required this.labelAr,
    required this.values,
  });

  final String id;
  final String code;
  final String status;
  final int sortOrder;
  final String labelEn;
  final String labelAr;
  final List<DropdownValue> values;

  factory Dropdown.fromJson(Map<String, dynamic> json) => Dropdown(
    id: json['id'] as String,
    code: json['code'] as String,
    status: json['status'] as String? ?? 'ACTIVE',
    sortOrder: json['sortOrder'] as int? ?? 0,
    labelEn: json['labelEn'] as String? ?? '',
    labelAr: json['labelAr'] as String? ?? '',
    values: (json['values'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => DropdownValue.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );
}

class DropdownValue {
  const DropdownValue({
    required this.id,
    required this.code,
    required this.status,
    required this.sortOrder,
    required this.labelEn,
    required this.labelAr,
  });

  final String id;
  final String code;
  final String status;
  final int sortOrder;
  final String labelEn;
  final String labelAr;

  factory DropdownValue.fromJson(Map<String, dynamic> json) => DropdownValue(
    id: json['id'] as String,
    code: json['code'] as String,
    status: json['status'] as String? ?? 'ACTIVE',
    sortOrder: json['sortOrder'] as int? ?? 0,
    labelEn: json['labelEn'] as String? ?? '',
    labelAr: json['labelAr'] as String? ?? '',
  );
}

class GuideImage {
  const GuideImage({
    required this.id,
    required this.status,
    required this.mime,
    required this.bytes,
    required this.licenceNote,
    required this.altEn,
    required this.altAr,
    required this.contentUrl,
  });

  final String id;
  final String status;
  final String mime;
  final int bytes;
  final String? licenceNote;
  final String altEn;
  final String altAr;
  final String contentUrl;

  factory GuideImage.fromJson(Map<String, dynamic> json) => GuideImage(
    id: json['id'] as String,
    status: json['status'] as String? ?? 'ACTIVE',
    mime: json['mime'] as String? ?? '',
    bytes: json['bytes'] as int? ?? 0,
    licenceNote: json['licenceNote'] as String?,
    altEn: json['altEn'] as String? ?? '',
    altAr: json['altAr'] as String? ?? '',
    contentUrl: json['contentUrl'] as String? ?? '',
  );
}

class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.action,
    required this.actorRole,
    required this.entityType,
    required this.occurredAt,
    required this.reasonCode,
    required this.metadataJson,
  });

  final String id;
  final String action;
  final String? actorRole;
  final String? entityType;
  final String occurredAt;
  final String? reasonCode;
  final String? metadataJson;

  factory AuditEvent.fromJson(Map<String, dynamic> json) => AuditEvent(
    id: json['id'] as String,
    action: json['action'] as String,
    actorRole: json['actorRole'] as String?,
    entityType: json['entityType'] as String?,
    occurredAt: json['occurredAt'] as String? ?? '',
    reasonCode: json['reasonCode'] as String?,
    metadataJson: json['metadataJson'] as String?,
  );
}

List<String> _strings(dynamic value) => (value as List<dynamic>? ?? <dynamic>[])
    .map((item) => item.toString())
    .toList(growable: false);

class StaffMember {
  const StaffMember({
    required this.userId,
    required this.displayName,
    required this.emailMasked,
    required this.role,
    required this.status,
  });

  final String userId;
  final String displayName;
  final String emailMasked;
  final String role;
  final String status;

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
    userId: json['userId'] as String,
    displayName: json['displayName'] as String? ?? '',
    emailMasked: json['emailMasked'] as String? ?? '',
    role: json['role'] as String? ?? '',
    status: json['status'] as String? ?? '',
  );
}

class WorkshopJob {
  const WorkshopJob({
    required this.id,
    required this.reference,
    required this.status,
    required this.templateVersionId,
    required this.templateName,
    required this.templateVersionNo,
    required this.assignedTechnicianId,
    required this.assignedTechnicianName,
    required this.scheduledAt,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleYear,
    required this.vehicleVin,
    required this.vehiclePlate,
    required this.scope,
  });

  final String id;
  final String reference;
  final String status;
  final String templateVersionId;
  final String templateName;
  final int? templateVersionNo;
  final String? assignedTechnicianId;
  final String? assignedTechnicianName;
  final String scheduledAt;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String vehicleMake;
  final String vehicleModel;
  final int? vehicleYear;
  final String? vehicleVin;
  final String? vehiclePlate;
  final String scope;

  factory WorkshopJob.fromJson(Map<String, dynamic> json) => WorkshopJob(
    id: json['id'] as String,
    reference: json['reference'] as String? ?? '',
    status: json['status'] as String? ?? 'DRAFT',
    templateVersionId: json['templateVersionId'] as String? ?? '',
    templateName: json['templateName'] as String? ?? '',
    templateVersionNo: json['templateVersionNo'] as int?,
    assignedTechnicianId: json['assignedTechnicianId'] as String?,
    assignedTechnicianName: json['assignedTechnicianName'] as String?,
    scheduledAt: json['scheduledAt'] as String? ?? '',
    customerName: json['customerName'] as String? ?? '',
    customerPhone: json['customerPhone'] as String?,
    customerEmail: json['customerEmail'] as String?,
    vehicleMake: json['vehicleMake'] as String? ?? '',
    vehicleModel: json['vehicleModel'] as String? ?? '',
    vehicleYear: json['vehicleYear'] as int?,
    vehicleVin: json['vehicleVin'] as String?,
    vehiclePlate: json['vehiclePlate'] as String?,
    scope: json['scope'] as String? ?? '',
  );
}

class TemplateSummary {
  const TemplateSummary({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.vehicleType,
    required this.status,
    required this.currentVersion,
    required this.itemCount,
  });

  final String id;
  final String name;
  final String serviceType;
  final String? vehicleType;
  final String status;
  final int? currentVersion;
  final int itemCount;

  factory TemplateSummary.fromJson(Map<String, dynamic> json) =>
      TemplateSummary(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        serviceType: json['serviceType'] as String? ?? '',
        vehicleType: json['vehicleType'] as String?,
        status: json['status'] as String? ?? 'DRAFT',
        currentVersion: json['currentVersion'] as int?,
        itemCount: json['itemCount'] as int? ?? 0,
      );
}

class TemplateVersionSummary {
  const TemplateVersionSummary({
    required this.id,
    required this.versionNo,
    required this.status,
    required this.publishedAt,
    required this.itemCount,
  });

  final String id;
  final int versionNo;
  final String status;
  final String publishedAt;
  final int itemCount;

  factory TemplateVersionSummary.fromJson(Map<String, dynamic> json) =>
      TemplateVersionSummary(
        id: json['id'] as String,
        versionNo: json['versionNo'] as int? ?? 0,
        status: json['status'] as String? ?? 'DRAFT',
        publishedAt: json['publishedAt'] as String? ?? '',
        itemCount: json['itemCount'] as int? ?? 0,
      );
}

class TemplateItemView {
  const TemplateItemView({
    required this.masterItemVersionId,
    required this.sortOrder,
    required this.stableCode,
    required this.categoryLabelEn,
    required this.categoryLabelAr,
    required this.labelEn,
    required this.labelAr,
    required this.instructionEn,
    required this.instructionAr,
    required this.versionNo,
    required this.resultOptions,
    required this.severityPolicy,
    required this.reasonCodes,
    required this.noteRequirement,
    required this.evidenceRequirement,
    required this.minPhotos,
    required this.equipmentIds,
    required this.guideImageId,
    required this.sampleData,
  });

  final String masterItemVersionId;
  final int sortOrder;
  final String stableCode;
  final String categoryLabelEn;
  final String categoryLabelAr;
  final String labelEn;
  final String labelAr;
  final String instructionEn;
  final String instructionAr;
  final int versionNo;
  final List<String> resultOptions;
  final String severityPolicy;
  final List<String> reasonCodes;
  final String noteRequirement;
  final String evidenceRequirement;
  final int minPhotos;
  final List<String> equipmentIds;
  final String? guideImageId;
  final bool sampleData;

  factory TemplateItemView.fromJson(Map<String, dynamic> json) =>
      TemplateItemView(
        masterItemVersionId: json['masterItemVersionId'] as String,
        sortOrder: json['sortOrder'] as int? ?? 0,
        stableCode: json['stableCode'] as String? ?? '',
        categoryLabelEn: json['categoryLabelEn'] as String? ?? '',
        categoryLabelAr: json['categoryLabelAr'] as String? ?? '',
        labelEn: json['labelEn'] as String? ?? '',
        labelAr: json['labelAr'] as String? ?? '',
        instructionEn: json['instructionEn'] as String? ?? '',
        instructionAr: json['instructionAr'] as String? ?? '',
        versionNo: json['versionNo'] as int? ?? 0,
        resultOptions: _strings(json['resultOptions']),
        severityPolicy: json['severityPolicy'] as String? ?? '{}',
        reasonCodes: _strings(json['reasonCodes']),
        noteRequirement: json['noteRequirement'] as String? ?? 'NONE',
        evidenceRequirement: json['evidenceRequirement'] as String? ?? 'NONE',
        minPhotos: json['minPhotos'] as int? ?? 0,
        equipmentIds: _strings(json['equipmentIds']),
        guideImageId: json['guideImageId'] as String?,
        sampleData: json['sampleData'] as bool? ?? false,
      );
}

class TemplateVersionView {
  const TemplateVersionView({
    required this.id,
    required this.versionNo,
    required this.status,
    required this.publishedAt,
    required this.items,
  });

  final String id;
  final int versionNo;
  final String status;
  final String publishedAt;
  final List<TemplateItemView> items;

  factory TemplateVersionView.fromJson(Map<String, dynamic> json) =>
      TemplateVersionView(
        id: json['id'] as String,
        versionNo: json['versionNo'] as int? ?? 0,
        status: json['status'] as String? ?? '',
        publishedAt: json['publishedAt'] as String? ?? '',
        items: (json['items'] as List<dynamic>? ?? <dynamic>[])
            .map(
              (item) => TemplateItemView.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
      );
}

class TemplateDetail {
  const TemplateDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.serviceType,
    required this.vehicleType,
    required this.status,
    required this.currentPublishedVersionId,
    required this.versions,
    required this.draft,
  });

  final String id;
  final String name;
  final String? description;
  final String serviceType;
  final String? vehicleType;
  final String status;
  final String? currentPublishedVersionId;
  final List<TemplateVersionSummary> versions;
  final TemplateVersionView? draft;

  factory TemplateDetail.fromJson(Map<String, dynamic> json) => TemplateDetail(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    description: json['description'] as String?,
    serviceType: json['serviceType'] as String? ?? '',
    vehicleType: json['vehicleType'] as String?,
    status: json['status'] as String? ?? 'DRAFT',
    currentPublishedVersionId: json['currentPublishedVersionId'] as String?,
    versions: (json['versions'] as List<dynamic>? ?? <dynamic>[])
        .map(
          (item) =>
              TemplateVersionSummary.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false),
    draft: json['draft'] == null
        ? null
        : TemplateVersionView.fromJson(json['draft'] as Map<String, dynamic>),
  );
}

class TemplateVersionOption {
  const TemplateVersionOption({
    required this.versionId,
    required this.templateId,
    required this.templateName,
    required this.versionNo,
    required this.serviceType,
    required this.vehicleType,
  });

  final String versionId;
  final String templateId;
  final String templateName;
  final int versionNo;
  final String serviceType;
  final String? vehicleType;

  factory TemplateVersionOption.fromJson(Map<String, dynamic> json) =>
      TemplateVersionOption(
        versionId: json['versionId'] as String,
        templateId: json['templateId'] as String? ?? '',
        templateName: json['templateName'] as String? ?? '',
        versionNo: json['versionNo'] as int? ?? 0,
        serviceType: json['serviceType'] as String? ?? '',
        vehicleType: json['vehicleType'] as String?,
      );
}

class PublishedItem {
  const PublishedItem({
    required this.itemId,
    required this.versionId,
    required this.stableCode,
    required this.categoryId,
    required this.categoryLabelEn,
    required this.categoryLabelAr,
    required this.labelEn,
    required this.labelAr,
    required this.sampleData,
    required this.version,
  });

  final String itemId;
  final String versionId;
  final String stableCode;
  final String categoryId;
  final String categoryLabelEn;
  final String categoryLabelAr;
  final String labelEn;
  final String labelAr;
  final bool sampleData;
  final ItemVersion version;

  factory PublishedItem.fromJson(Map<String, dynamic> json) => PublishedItem(
    itemId: json['itemId'] as String,
    versionId: json['versionId'] as String,
    stableCode: json['stableCode'] as String? ?? '',
    categoryId: json['categoryId'] as String? ?? '',
    categoryLabelEn: json['categoryLabelEn'] as String? ?? '',
    categoryLabelAr: json['categoryLabelAr'] as String? ?? '',
    labelEn: json['labelEn'] as String? ?? '',
    labelAr: json['labelAr'] as String? ?? '',
    sampleData: json['sampleData'] as bool? ?? false,
    version: ItemVersion.fromJson(json['version'] as Map<String, dynamic>),
  );
}
