import 'package:api_client/api_client.dart';
import 'package:admin_app/src/models.dart';
import 'package:dio/dio.dart';

abstract class AdminApi {
  Future<HierarchyResponse> hierarchy({String search = '', String status = ''});

  Future<HierarchyWorkshop> workshopDetail(String workshopId);

  Future<PlatformAccount> createUser({
    required String email,
    required String displayName,
    required String temporaryPassword,
    required String role,
    required String workshopId,
  });

  Future<Map<String, dynamic>> invite({
    required String email,
    required String displayName,
    required String role,
    required String workshopId,
  });

  Future<PlatformAccount> disableUser(String userId, String reason);

  Future<PlatformAccount> reactivateUser(String userId, String reason);

  Future<PlatformAccount> transferUser(
    String userId,
    String workshopId,
    String reason,
  );

  Future<List<AuditEvent>> auditEvents();

  Future<List<Category>> categories();

  Future<Category> createCategory(String slug, String labelEn, String labelAr);

  Future<Category> updateCategory(
    String id,
    String slug,
    String labelEn,
    String labelAr,
    int sortOrder,
    String status,
  );

  Future<Category> retireCategory(String id);

  Future<List<ItemSummary>> items({
    String search = '',
    String categoryId = '',
    String status = '',
  });

  Future<ItemDetail> itemDetail(String id);

  Future<ItemDetail> createItem(NewItem item);

  Future<ItemDetail> createDraft(String itemId);

  Future<ItemVersion> updateTranslation(
    String itemId,
    String versionId,
    String locale,
    String label,
    String instruction,
  );

  Future<ItemVersion> updateRules(
    String itemId,
    String versionId,
    ItemRules rules,
  );

  Future<ItemVersion> publish(String itemId, String versionId);

  Future<ItemSummary> retireItem(String itemId);

  Future<List<Reason>> reasons();

  Future<Reason> createReason(String code, String labelEn, String labelAr);

  Future<List<Equipment>> equipment();

  Future<Equipment> createEquipment(
    String code,
    String labelEn,
    String labelAr,
  );

  Future<List<Dropdown>> dropdowns();

  Future<Dropdown> createDropdown(String code, String labelEn, String labelAr);

  Future<DropdownValue> addDropdownValue(
    String dropdownId,
    String code,
    String labelEn,
    String labelAr,
  );

  Future<List<GuideImage>> guideImages();

  Future<GuideImage> uploadGuideImage({
    required List<int> bytes,
    required String filename,
    required String altEn,
    required String altAr,
    String? licenceNote,
  });

  Future<List<int>> guideImageBytes(String id);

  Future<GuideImage> retireGuideImage(String id);

  Future<List<StaffMember>> staff();

  Future<List<WorkshopJob>> jobs({String search = '', String status = ''});

  Future<WorkshopJob> createJob({
    required String templateVersionId,
    required String customerName,
    String? customerPhone,
    String? customerEmail,
    required String vehicleMake,
    required String vehicleModel,
    int? vehicleYear,
    String? vehicleVin,
    String? vehiclePlate,
    required String scope,
    String? scheduledAt,
  });

  Future<WorkshopJob> assignJob(
    String jobId,
    String technicianId,
    String? reason,
  );

  Future<WorkshopJob> cancelJob(String jobId, String reason);

  Future<List<Category>> workshopCategories();

  Future<List<PublishedItem>> publishedItems({
    String search = '',
    String categoryId = '',
  });

  Future<List<TemplateSummary>> templates();

  Future<TemplateDetail> templateDetail(String id);

  Future<TemplateDetail> createTemplate({
    required String name,
    String? description,
    required String serviceType,
    String? vehicleType,
  });

  Future<TemplateDetail> saveTemplateDraft({
    required String id,
    required String name,
    String? description,
    required String serviceType,
    String? vehicleType,
    required List<TemplateItemDraft> items,
  });

  Future<TemplateDetail> createTemplateDraft(String id);

  Future<TemplateDetail> publishTemplate(String id);

  Future<ReportAdmin> report(String jobId);

  Future<ReportAdmin> retryReport(String jobId);

  Future<ReportLinkResult> activateReportLink(String jobId);

  Future<ReportLinkResult> revokeReportLink(
    String jobId,
    String reasonCode,
    String? note,
  );

  Future<ReportLinkResult> setPdfDownload(String jobId, bool enabled);

  Future<List<int>> reportPdf(String jobId);

  Future<List<TemplateVersionOption>> templateVersionOptions();

  Future<TemplateVersionView> templateVersion(String id, String versionId);

  Future<TemplateDetail> retireTemplate(String id);
}

class TemplateItemDraft {
  const TemplateItemDraft({
    required this.masterItemVersionId,
    required this.sortOrder,
  });

  final String masterItemVersionId;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
    'masterItemVersionId': masterItemVersionId,
    'sortOrder': sortOrder,
  };
}

class NewItem {
  const NewItem({
    required this.stableCode,
    required this.categoryId,
    required this.labelEn,
    required this.labelAr,
    required this.instructionEn,
    required this.instructionAr,
    required this.resultOptions,
    required this.reasonCodes,
    required this.equipmentIds,
    required this.noteRequirement,
    required this.evidenceRequirement,
    required this.minPhotos,
    required this.sampleData,
    this.severityPolicy = '{}',
    this.applicability = '{}',
    this.guideImageId,
  });

  final String stableCode;
  final String categoryId;
  final String labelEn;
  final String labelAr;
  final String instructionEn;
  final String instructionAr;
  final List<String> resultOptions;
  final List<String> reasonCodes;
  final List<String> equipmentIds;
  final String noteRequirement;
  final String evidenceRequirement;
  final int minPhotos;
  final bool sampleData;
  final String severityPolicy;
  final String applicability;
  final String? guideImageId;

  Map<String, dynamic> toJson() => {
    'stableCode': stableCode,
    'categoryId': categoryId,
    'labelEn': labelEn,
    'labelAr': labelAr,
    'instructionEn': instructionEn,
    'instructionAr': instructionAr,
    'sampleData': sampleData,
    'resultOptions': resultOptions,
    'severityPolicy': severityPolicy,
    'applicability': applicability,
    'reasonCodes': reasonCodes,
    'noteRequirement': noteRequirement,
    'evidenceRequirement': evidenceRequirement,
    'minPhotos': minPhotos,
    'equipmentIds': equipmentIds,
    'guideImageId': guideImageId,
  };
}

class ItemRules {
  const ItemRules({
    required this.resultOptions,
    required this.reasonCodes,
    required this.equipmentIds,
    required this.noteRequirement,
    required this.evidenceRequirement,
    required this.minPhotos,
    this.severityPolicy = '{}',
    this.applicability = '{}',
    this.guideImageId,
  });

  final List<String> resultOptions;
  final List<String> reasonCodes;
  final List<String> equipmentIds;
  final String noteRequirement;
  final String evidenceRequirement;
  final int minPhotos;
  final String severityPolicy;
  final String applicability;
  final String? guideImageId;

  Map<String, dynamic> toJson() => {
    'resultOptions': resultOptions,
    'severityPolicy': severityPolicy,
    'applicability': applicability,
    'reasonCodes': reasonCodes,
    'noteRequirement': noteRequirement,
    'evidenceRequirement': evidenceRequirement,
    'minPhotos': minPhotos,
    'equipmentIds': equipmentIds,
    'guideImageId': guideImageId,
  };
}

class HttpAdminApi implements AdminApi {
  HttpAdminApi(this._api, this._endpoints);

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
        if (status.isNotEmpty) 'status': status,
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
  }) async {
    final data = await _api.postDynamic(
      _endpoints.platformUsers,
      body: {
        'email': email,
        'displayName': displayName,
        'temporaryPassword': temporaryPassword,
        'role': role,
        'workshopId': workshopId,
      },
    );
    return PlatformAccount.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> invite({
    required String email,
    required String displayName,
    required String role,
    required String workshopId,
  }) async {
    final data = await _api.postDynamic(
      _endpoints.platformInvitations,
      body: {
        'email': email,
        'displayName': displayName,
        'role': role,
        'workshopId': workshopId,
      },
    );
    return Map<String, dynamic>.from(data as Map);
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

  @override
  Future<PlatformAccount> transferUser(
    String userId,
    String workshopId,
    String reason,
  ) async {
    final data = await _api.postDynamic(
      _endpoints.transferUser(userId),
      body: {'workshopId': workshopId, 'reason': reason},
    );
    return PlatformAccount.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<AuditEvent>> auditEvents() async {
    final data = await _api.getDynamic(_endpoints.auditEvents);
    return (data as List<dynamic>)
        .map((item) => AuditEvent.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<List<Category>> categories() async {
    final data = await _api.getDynamic(_endpoints.categories);
    return (data as List<dynamic>)
        .map((item) => Category.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<Category> createCategory(
    String slug,
    String labelEn,
    String labelAr,
  ) async {
    final data = await _api.postDynamic(
      _endpoints.categories,
      body: {
        'slug': slug,
        'labelEn': labelEn,
        'labelAr': labelAr,
        'sortOrder': 0,
      },
    );
    return Category.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Category> updateCategory(
    String id,
    String slug,
    String labelEn,
    String labelAr,
    int sortOrder,
    String status,
  ) async {
    final data = await _api.putDynamic(
      _endpoints.category(id),
      body: {
        'slug': slug,
        'labelEn': labelEn,
        'labelAr': labelAr,
        'sortOrder': sortOrder,
        'status': status,
      },
    );
    return Category.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Category> retireCategory(String id) async {
    final data = await _api.postDynamic(_endpoints.retireCategory(id));
    return Category.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<ItemSummary>> items({
    String search = '',
    String categoryId = '',
    String status = '',
  }) async {
    final data = await _api.getDynamic(
      _endpoints.items,
      query: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (categoryId.isNotEmpty) 'categoryId': categoryId,
        if (status.isNotEmpty) 'status': status,
      },
    );
    return (data as List<dynamic>)
        .map((item) => ItemSummary.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<ItemDetail> itemDetail(String id) async {
    final data = await _api.getDynamic(_endpoints.item(id));
    return ItemDetail.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<ItemDetail> createItem(NewItem item) async {
    final data = await _api.postDynamic(_endpoints.items, body: item.toJson());
    return ItemDetail.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<ItemDetail> createDraft(String itemId) async {
    final data = await _api.postDynamic(_endpoints.itemVersions(itemId));
    return ItemDetail.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<ItemVersion> updateTranslation(
    String itemId,
    String versionId,
    String locale,
    String label,
    String instruction,
  ) async {
    final data = await _api.putDynamic(
      _endpoints.itemVersionTranslation(itemId, versionId, locale),
      body: {'label': label, 'instruction': instruction},
    );
    return ItemVersion.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<ItemVersion> updateRules(
    String itemId,
    String versionId,
    ItemRules rules,
  ) async {
    final data = await _api.putDynamic(
      _endpoints.itemVersionRules(itemId, versionId),
      body: rules.toJson(),
    );
    return ItemVersion.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<ItemVersion> publish(String itemId, String versionId) async {
    final data = await _api.postDynamic(
      _endpoints.publishItemVersion(itemId, versionId),
    );
    return ItemVersion.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<ItemSummary> retireItem(String itemId) async {
    final data = await _api.postDynamic(_endpoints.retireItem(itemId));
    return ItemSummary.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<Reason>> reasons() async {
    final data = await _api.getDynamic(_endpoints.reasons);
    return (data as List<dynamic>)
        .map((item) => Reason.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<Reason> createReason(
    String code,
    String labelEn,
    String labelAr,
  ) async {
    final data = await _api.postDynamic(
      _endpoints.reasons,
      body: {
        'code': code,
        'labelEn': labelEn,
        'labelAr': labelAr,
        'sortOrder': 0,
      },
    );
    return Reason.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<Equipment>> equipment() async {
    final data = await _api.getDynamic(_endpoints.equipment);
    return (data as List<dynamic>)
        .map((item) => Equipment.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<Equipment> createEquipment(
    String code,
    String labelEn,
    String labelAr,
  ) async {
    final data = await _api.postDynamic(
      _endpoints.equipment,
      body: {
        'code': code,
        'labelEn': labelEn,
        'labelAr': labelAr,
        'sortOrder': 0,
      },
    );
    return Equipment.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<Dropdown>> dropdowns() async {
    final data = await _api.getDynamic(_endpoints.dropdowns);
    return (data as List<dynamic>)
        .map((item) => Dropdown.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<Dropdown> createDropdown(
    String code,
    String labelEn,
    String labelAr,
  ) async {
    final data = await _api.postDynamic(
      _endpoints.dropdowns,
      body: {
        'code': code,
        'labelEn': labelEn,
        'labelAr': labelAr,
        'sortOrder': 0,
      },
    );
    return Dropdown.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<DropdownValue> addDropdownValue(
    String dropdownId,
    String code,
    String labelEn,
    String labelAr,
  ) async {
    final data = await _api.postDynamic(
      _endpoints.dropdownValues(dropdownId),
      body: {
        'code': code,
        'labelEn': labelEn,
        'labelAr': labelAr,
        'sortOrder': 0,
      },
    );
    return DropdownValue.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<GuideImage>> guideImages() async {
    final data = await _api.getDynamic(_endpoints.guideImages);
    return (data as List<dynamic>)
        .map((item) => GuideImage.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<GuideImage> uploadGuideImage({
    required List<int> bytes,
    required String filename,
    required String altEn,
    required String altAr,
    String? licenceNote,
  }) async {
    final form = FormData();
    form.files.add(
      MapEntry('file', MultipartFile.fromBytes(bytes, filename: filename)),
    );
    form.fields.add(MapEntry('altEn', altEn));
    form.fields.add(MapEntry('altAr', altAr));
    if (licenceNote != null && licenceNote.isNotEmpty) {
      form.fields.add(MapEntry('licenceNote', licenceNote));
    }
    final data = await _api.postForm(_endpoints.guideImages, form);
    return GuideImage.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<int>> guideImageBytes(String id) =>
      _api.getBytes(_endpoints.guideImageContent(id));

  @override
  Future<GuideImage> retireGuideImage(String id) async {
    final data = await _api.postDynamic(_endpoints.retireGuideImage(id));
    return GuideImage.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<StaffMember>> staff() async {
    final data = await _api.getDynamic(_endpoints.workshopStaff);
    return (data as List<dynamic>)
        .map((item) => StaffMember.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<List<WorkshopJob>> jobs({
    String search = '',
    String status = '',
  }) async {
    final data = await _api.getDynamic(
      _endpoints.workshopJobs,
      query: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (status.isNotEmpty) 'status': status,
      },
    );
    return (data as List<dynamic>)
        .map((item) => WorkshopJob.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<WorkshopJob> createJob({
    required String templateVersionId,
    required String customerName,
    String? customerPhone,
    String? customerEmail,
    required String vehicleMake,
    required String vehicleModel,
    int? vehicleYear,
    String? vehicleVin,
    String? vehiclePlate,
    required String scope,
    String? scheduledAt,
  }) async {
    final data = await _api.postDynamic(
      _endpoints.workshopJobs,
      body: {
        'templateVersionId': templateVersionId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
        'vehicleMake': vehicleMake,
        'vehicleModel': vehicleModel,
        'vehicleYear': vehicleYear,
        'vehicleVin': vehicleVin,
        'vehiclePlate': vehiclePlate,
        'scope': scope,
        'scheduledAt': scheduledAt,
      },
    );
    return WorkshopJob.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<WorkshopJob> assignJob(
    String jobId,
    String technicianId,
    String? reason,
  ) async {
    final data = await _api.postDynamic(
      _endpoints.assignWorkshopJob(jobId),
      body: {'technicianId': technicianId, 'reason': reason},
    );
    return WorkshopJob.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<WorkshopJob> cancelJob(String jobId, String reason) async {
    final data = await _api.postDynamic(
      _endpoints.cancelWorkshopJob(jobId),
      body: {'reason': reason},
    );
    return WorkshopJob.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<Category>> workshopCategories() async {
    final data = await _api.getDynamic(_endpoints.workshopMasterCategories);
    return (data as List<dynamic>)
        .map((item) => Category.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<List<PublishedItem>> publishedItems({
    String search = '',
    String categoryId = '',
  }) async {
    final data = await _api.getDynamic(
      _endpoints.workshopMasterItems,
      query: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (categoryId.isNotEmpty) 'categoryId': categoryId,
      },
    );
    return (data as List<dynamic>)
        .map((item) => PublishedItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<List<TemplateSummary>> templates() async {
    final data = await _api.getDynamic(_endpoints.workshopTemplates);
    return (data as List<dynamic>)
        .map((item) => TemplateSummary.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<TemplateDetail> templateDetail(String id) async {
    final data = await _api.getDynamic(_endpoints.workshopTemplate(id));
    return TemplateDetail.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<TemplateDetail> createTemplate({
    required String name,
    String? description,
    required String serviceType,
    String? vehicleType,
  }) async {
    final data = await _api.postDynamic(
      _endpoints.workshopTemplates,
      body: {
        'name': name,
        'description': description,
        'serviceType': serviceType,
        'vehicleType': vehicleType,
      },
    );
    return TemplateDetail.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<TemplateDetail> saveTemplateDraft({
    required String id,
    required String name,
    String? description,
    required String serviceType,
    String? vehicleType,
    required List<TemplateItemDraft> items,
  }) async {
    final data = await _api.putDynamic(
      _endpoints.workshopTemplateDraft(id),
      body: {
        'name': name,
        'description': description,
        'serviceType': serviceType,
        'vehicleType': vehicleType,
        'items': items.map((item) => item.toJson()).toList(),
      },
    );
    return TemplateDetail.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<TemplateDetail> createTemplateDraft(String id) async {
    final data = await _api.postDynamic(_endpoints.workshopTemplateDraft(id));
    return TemplateDetail.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<TemplateDetail> publishTemplate(String id) async {
    final data = await _api.postDynamic(_endpoints.publishWorkshopTemplate(id));
    return TemplateDetail.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<ReportAdmin> report(String jobId) async {
    final data = await _api.getDynamic(_endpoints.workshopReport(jobId));
    return ReportAdmin.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<ReportAdmin> retryReport(String jobId) async {
    final data = await _api.postDynamic(
      _endpoints.workshopReportRetry(jobId),
    );
    return ReportAdmin.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<ReportLinkResult> activateReportLink(String jobId) async {
    final data = await _api.postDynamic(
      _endpoints.workshopReportLink(jobId),
      body: const <String, dynamic>{},
    );
    return ReportLinkResult.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<ReportLinkResult> revokeReportLink(
    String jobId,
    String reasonCode,
    String? note,
  ) async {
    final data = await _api.postDynamic(
      _endpoints.workshopReportLinkRevoke(jobId),
      body: {'reasonCode': reasonCode, 'note': note},
    );
    return ReportLinkResult.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<ReportLinkResult> setPdfDownload(String jobId, bool enabled) async {
    final data = await _api.putDynamic(
      _endpoints.workshopReportPdfSetting(jobId),
      body: {'enabled': enabled},
    );
    return ReportLinkResult.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<int>> reportPdf(String jobId) {
    return _api.getBytes(_endpoints.workshopReportPdf(jobId));
  }

  @override
  Future<List<TemplateVersionOption>> templateVersionOptions() async {
    final data = await _api.getDynamic(_endpoints.workshopTemplateVersions);
    return (data as List<dynamic>)
        .map(
          (item) =>
              TemplateVersionOption.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Future<TemplateVersionView> templateVersion(
    String id,
    String versionId,
  ) async {
    final data = await _api.getDynamic(
      _endpoints.workshopTemplateVersion(id, versionId),
    );
    return TemplateVersionView.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<TemplateDetail> retireTemplate(String id) async {
    final data = await _api.postDynamic(_endpoints.retireWorkshopTemplate(id));
    return TemplateDetail.fromJson(data as Map<String, dynamic>);
  }
}
