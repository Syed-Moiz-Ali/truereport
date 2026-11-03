class TechnicianJob {
  const TechnicianJob({
    required this.id,
    required this.reference,
    required this.status,
    required this.version,
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
    required this.vehicleType,
    required this.odometerValue,
    required this.odometerUnit,
    required this.scope,
    required this.startedAt,
    required this.readyAt,
    required this.finalizedAt,
  });

  final String id;
  final String reference;
  final String status;
  final int version;
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
  final String? vehicleType;
  final int? odometerValue;
  final String? odometerUnit;
  final String scope;
  final String startedAt;
  final String readyAt;
  final String finalizedAt;

  factory TechnicianJob.fromJson(Map<String, dynamic> json) => TechnicianJob(
    id: json['id'] as String,
    reference: json['reference'] as String? ?? '',
    status: json['status'] as String? ?? 'DRAFT',
    version: json['version'] as int? ?? 0,
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
    vehicleType: json['vehicleType'] as String?,
    odometerValue: json['odometerValue'] as int?,
    odometerUnit: json['odometerUnit'] as String?,
    scope: json['scope'] as String? ?? '',
    startedAt: json['startedAt'] as String? ?? '',
    readyAt: json['readyAt'] as String? ?? '',
    finalizedAt: json['finalizedAt'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'reference': reference,
    'status': status,
    'version': version,
    'templateVersionId': templateVersionId,
    'templateName': templateName,
    'templateVersionNo': templateVersionNo,
    'assignedTechnicianId': assignedTechnicianId,
    'assignedTechnicianName': assignedTechnicianName,
    'scheduledAt': scheduledAt,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'customerEmail': customerEmail,
    'vehicleMake': vehicleMake,
    'vehicleModel': vehicleModel,
    'vehicleYear': vehicleYear,
    'vehicleVin': vehicleVin,
    'vehiclePlate': vehiclePlate,
    'vehicleType': vehicleType,
    'odometerValue': odometerValue,
    'odometerUnit': odometerUnit,
    'scope': scope,
    'startedAt': startedAt,
    'readyAt': readyAt,
    'finalizedAt': finalizedAt,
  };
}

class InspectionAssessment {
  const InspectionAssessment({
    required this.id,
    required this.resultCode,
    required this.severityCode,
    required this.note,
    required this.noteLanguage,
    required this.reasonCode,
    required this.reasonText,
    required this.clientRevision,
    required this.serverRevision,
    required this.version,
  });

  final String id;
  final String resultCode;
  final String? severityCode;
  final String? note;
  final String? noteLanguage;
  final String? reasonCode;
  final String? reasonText;
  final int clientRevision;
  final int serverRevision;
  final int version;

  factory InspectionAssessment.fromJson(Map<String, dynamic> json) =>
      InspectionAssessment(
        id: json['id'] as String,
        resultCode: json['resultCode'] as String? ?? '',
        severityCode: json['severityCode'] as String?,
        note: json['note'] as String?,
        noteLanguage: json['noteLanguage'] as String?,
        reasonCode: json['reasonCode'] as String?,
        reasonText: json['reasonText'] as String?,
        clientRevision: json['clientRevision'] as int? ?? 0,
        serverRevision: json['serverRevision'] as int? ?? 0,
        version: json['version'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'resultCode': resultCode,
    'severityCode': severityCode,
    'note': note,
    'noteLanguage': noteLanguage,
    'reasonCode': reasonCode,
    'reasonText': reasonText,
    'clientRevision': clientRevision,
    'serverRevision': serverRevision,
    'version': version,
  };
}

class InspectionItem {
  const InspectionItem({
    required this.inspectionItemId,
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
    required this.applicability,
    required this.reasonCodes,
    required this.noteRequirement,
    required this.evidenceRequirement,
    required this.minPhotos,
    required this.equipmentIds,
    required this.guideImageId,
    required this.sampleData,
    required this.assessment,
    this.syncState,
  });

  final String inspectionItemId;
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
  final String applicability;
  final List<String> reasonCodes;
  final String noteRequirement;
  final String evidenceRequirement;
  final int minPhotos;
  final List<String> equipmentIds;
  final String? guideImageId;
  final bool sampleData;
  final InspectionAssessment? assessment;
  final String? syncState;

  factory InspectionItem.fromJson(Map<String, dynamic> json) => InspectionItem(
    inspectionItemId: json['inspectionItemId'] as String,
    masterItemVersionId: json['masterItemVersionId'] as String? ?? '',
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
    applicability: json['applicability'] as String? ?? '{}',
    reasonCodes: _strings(json['reasonCodes']),
    noteRequirement: json['noteRequirement'] as String? ?? 'NONE',
    evidenceRequirement: json['evidenceRequirement'] as String? ?? 'NONE',
    minPhotos: json['minPhotos'] as int? ?? 0,
    equipmentIds: _strings(json['equipmentIds']),
    guideImageId: json['guideImageId'] as String?,
    sampleData: json['sampleData'] as bool? ?? false,
    assessment: json['assessment'] == null
        ? null
        : InspectionAssessment.fromJson(
            json['assessment'] as Map<String, dynamic>,
          ),
    syncState: json['syncState'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'inspectionItemId': inspectionItemId,
    'masterItemVersionId': masterItemVersionId,
    'sortOrder': sortOrder,
    'stableCode': stableCode,
    'categoryLabelEn': categoryLabelEn,
    'categoryLabelAr': categoryLabelAr,
    'labelEn': labelEn,
    'labelAr': labelAr,
    'instructionEn': instructionEn,
    'instructionAr': instructionAr,
    'versionNo': versionNo,
    'resultOptions': resultOptions,
    'severityPolicy': severityPolicy,
    'applicability': applicability,
    'reasonCodes': reasonCodes,
    'noteRequirement': noteRequirement,
    'evidenceRequirement': evidenceRequirement,
    'minPhotos': minPhotos,
    'equipmentIds': equipmentIds,
    'guideImageId': guideImageId,
    'sampleData': sampleData,
    'assessment': assessment?.toJson(),
    'syncState': syncState,
  };
}

class InspectionChecklist {
  const InspectionChecklist({
    required this.job,
    required this.items,
    required this.completed,
    required this.total,
  });

  final TechnicianJob job;
  final List<InspectionItem> items;
  final int completed;
  final int total;

  factory InspectionChecklist.fromJson(Map<String, dynamic> json) =>
      InspectionChecklist(
        job: TechnicianJob.fromJson(json['job'] as Map<String, dynamic>),
        items: (json['items'] as List<dynamic>? ?? <dynamic>[])
            .map(
              (item) => InspectionItem.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
        completed: json['completed'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'job': job.toJson(),
    'items': items.map((item) => item.toJson()).toList(),
    'completed': completed,
    'total': total,
  };
}

class ReviewIssue {
  const ReviewIssue({
    required this.code,
    required this.inspectionItemId,
    required this.label,
    required this.detail,
  });

  final String code;
  final String? inspectionItemId;
  final String? label;
  final String? detail;

  factory ReviewIssue.fromJson(Map<String, dynamic> json) => ReviewIssue(
    code: json['code'] as String? ?? '',
    inspectionItemId: json['inspectionItemId'] as String?,
    label: json['label'] as String?,
    detail: json['detail'] as String?,
  );
}

class ReviewResult {
  const ReviewResult({
    required this.ready,
    required this.completed,
    required this.total,
    required this.blocking,
    required this.warnings,
  });

  final bool ready;
  final int completed;
  final int total;
  final List<ReviewIssue> blocking;
  final List<ReviewIssue> warnings;

  factory ReviewResult.fromJson(Map<String, dynamic> json) => ReviewResult(
    ready: json['ready'] as bool? ?? false,
    completed: json['completed'] as int? ?? 0,
    total: json['total'] as int? ?? 0,
    blocking: (json['blocking'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => ReviewIssue.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
    warnings: (json['warnings'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => ReviewIssue.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );
}

class FinalizeResult {
  const FinalizeResult({
    required this.jobId,
    required this.status,
    required this.finalizedAt,
    required this.snapshotHash,
    required this.itemCount,
    required this.warnings,
  });

  final String jobId;
  final String status;
  final String finalizedAt;
  final String snapshotHash;
  final int itemCount;
  final List<String> warnings;

  factory FinalizeResult.fromJson(Map<String, dynamic> json) => FinalizeResult(
    jobId: json['jobId'] as String? ?? '',
    status: json['status'] as String? ?? '',
    finalizedAt: json['finalizedAt'] as String? ?? '',
    snapshotHash: json['snapshotHash'] as String? ?? '',
    itemCount: json['itemCount'] as int? ?? 0,
    warnings: _strings(json['warnings']),
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
        versionId: json['versionId'] as String? ?? '',
        templateId: json['templateId'] as String? ?? '',
        templateName: json['templateName'] as String? ?? '',
        versionNo: json['versionNo'] as int? ?? 0,
        serviceType: json['serviceType'] as String? ?? '',
        vehicleType: json['vehicleType'] as String?,
      );
}

class InspectionEvidence {
  const InspectionEvidence({
    required this.id,
    required this.inspectionItemId,
    required this.mime,
    required this.bytes,
    required this.capturedAt,
    required this.status,
    required this.sha256,
  });

  final String id;
  final String inspectionItemId;
  final String mime;
  final int bytes;
  final String capturedAt;
  final String status;
  final String sha256;

  factory InspectionEvidence.fromJson(Map<String, dynamic> json) =>
      InspectionEvidence(
        id: json['id'] as String? ?? '',
        inspectionItemId: json['inspectionItemId'] as String? ?? '',
        mime: json['mime'] as String? ?? '',
        bytes: json['bytes'] as int? ?? 0,
        capturedAt: json['capturedAt'] as String? ?? '',
        status: json['status'] as String? ?? '',
        sha256: json['sha256'] as String? ?? '',
      );
}

class EvidenceInitResult {
  const EvidenceInitResult({
    required this.evidenceId,
    required this.status,
    required this.uploadUrl,
    required this.uploadToken,
    required this.expiresAt,
  });

  final String evidenceId;
  final String status;
  final String? uploadUrl;
  final String? uploadToken;
  final String expiresAt;

  factory EvidenceInitResult.fromJson(Map<String, dynamic> json) =>
      EvidenceInitResult(
        evidenceId: json['evidenceId'] as String? ?? '',
        status: json['status'] as String? ?? '',
        uploadUrl: json['uploadUrl'] as String?,
        uploadToken: json['uploadToken'] as String?,
        expiresAt: json['expiresAt'] as String? ?? '',
      );
}

List<String> _strings(dynamic value) => (value as List<dynamic>? ?? <dynamic>[])
    .map((item) => item.toString())
    .toList(growable: false);
