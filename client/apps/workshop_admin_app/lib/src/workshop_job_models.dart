/// Workshop job API models.
///
/// All parsing is defensive: missing keys, nulls and numeric/string drift are
/// normalised so an older or partially populated server cannot crash a screen.
library;

String _string(dynamic value, {String fallback = ''}) =>
    value == null ? fallback : value.toString();

String? _stringOrNull(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int _int(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _intOrNull(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}

double? _doubleOrNull(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

bool _bool(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return fallback;
}

List<dynamic> _list(dynamic value) =>
    value is List<dynamic> ? value : const <dynamic>[];

Map<String, dynamic> _map(dynamic value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

class AvailableTemplate {
  const AvailableTemplate({
    required this.versionId,
    required this.templateId,
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.versionNo,
    required this.itemCount,
  });

  final String versionId;
  final String templateId;
  final String code;
  final String nameEn;
  final String nameAr;
  final int versionNo;
  final int itemCount;

  factory AvailableTemplate.fromJson(Map<String, dynamic> json) =>
      AvailableTemplate(
        versionId: _string(json['versionId']),
        templateId: _string(json['templateId']),
        code: _string(json['code']),
        nameEn: _string(json['nameEn']),
        nameAr: _string(json['nameAr']),
        versionNo: _int(json['versionNo']),
        itemCount: _int(json['itemCount']),
      );
}

class JobTemplateItem {
  const JobTemplateItem({
    required this.itemVersionId,
    required this.stableCode,
    required this.labelEn,
    required this.labelAr,
    required this.categoryId,
    required this.categoryNameEn,
    required this.categoryNameAr,
    required this.safetyCritical,
    required this.measurementUnit,
    required this.sortOrder,
  });

  final String itemVersionId;
  final String stableCode;
  final String labelEn;
  final String labelAr;
  final String categoryId;
  final String categoryNameEn;
  final String categoryNameAr;
  final bool safetyCritical;
  final String? measurementUnit;
  final int sortOrder;

  factory JobTemplateItem.fromJson(Map<String, dynamic> json) =>
      JobTemplateItem(
        itemVersionId: _string(json['itemVersionId']),
        stableCode: _string(json['stableCode']),
        labelEn: _string(json['labelEn']),
        labelAr: _string(json['labelAr']),
        categoryId: _string(json['categoryId']),
        categoryNameEn: _string(json['categoryNameEn']),
        categoryNameAr: _string(json['categoryNameAr']),
        safetyCritical: _bool(json['safetyCritical']),
        measurementUnit: _stringOrNull(json['measurementUnit']),
        sortOrder: _int(json['sortOrder']),
      );
}

class JobTemplateDetail {
  const JobTemplateDetail({
    required this.versionId,
    required this.templateId,
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.versionNo,
    required this.status,
    required this.items,
  });

  final String versionId;
  final String templateId;
  final String code;
  final String nameEn;
  final String nameAr;
  final int versionNo;
  final String status;
  final List<JobTemplateItem> items;

  factory JobTemplateDetail.fromJson(Map<String, dynamic> json) =>
      JobTemplateDetail(
        versionId: _string(json['versionId']),
        templateId: _string(json['templateId']),
        code: _string(json['code']),
        nameEn: _string(json['nameEn']),
        nameAr: _string(json['nameAr']),
        versionNo: _int(json['versionNo']),
        status: _string(json['status']),
        items: _list(json['items'])
            .whereType<Map<String, dynamic>>()
            .map(JobTemplateItem.fromJson)
            .toList(growable: false),
      );
}

class CleanJob {
  const CleanJob({
    required this.id,
    required this.reference,
    required this.status,
    required this.reviewStatus,
    required this.publicationStatus,
    required this.templateVersionId,
    required this.templateNameEn,
    required this.templateNameAr,
    required this.templateVersionNo,
    required this.assignedTechnicianId,
    required this.assignedTechnicianName,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.vehicleVin,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleYear,
    required this.vehiclePlate,
    required this.odometerValue,
    required this.odometerUnit,
    required this.transmission,
    required this.fuelType,
    required this.preferredLanguage,
    required this.scheduledAt,
    required this.startedAt,
    required this.completedAt,
    required this.approvedAt,
    required this.publishedAt,
    required this.cancelledAt,
    required this.approvedBy,
    required this.cancelledBy,
    required this.cancelReason,
    required this.score,
    required this.gradeCode,
    required this.safetyCapApplied,
    required this.safetyCapReason,
    required this.consentGranted,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  final String id;
  final String reference;
  final String status;
  final String reviewStatus;
  final String publicationStatus;
  final String templateVersionId;
  final String templateNameEn;
  final String templateNameAr;
  final int? templateVersionNo;
  final String? assignedTechnicianId;
  final String? assignedTechnicianName;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? vehicleVin;
  final String vehicleMake;
  final String vehicleModel;
  final int? vehicleYear;
  final String? vehiclePlate;
  final int? odometerValue;
  final String? odometerUnit;
  final String? transmission;
  final String? fuelType;
  final String? preferredLanguage;
  final String? scheduledAt;
  final String? startedAt;
  final String? completedAt;
  final String? approvedAt;
  final String? publishedAt;
  final String? cancelledAt;
  final String? approvedBy;
  final String? cancelledBy;
  final String? cancelReason;
  final int? score;
  final String? gradeCode;
  final bool safetyCapApplied;
  final String? safetyCapReason;
  final bool consentGranted;
  final String? createdAt;
  final String? updatedAt;
  final int? version;

  CleanJob copyWith({
    String? id,
    String? reference,
    String? status,
    String? reviewStatus,
    String? publicationStatus,
    String? templateVersionId,
    String? templateNameEn,
    String? templateNameAr,
    int? templateVersionNo,
    String? assignedTechnicianId,
    String? assignedTechnicianName,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? vehicleVin,
    String? vehicleMake,
    String? vehicleModel,
    int? vehicleYear,
    String? vehiclePlate,
    int? odometerValue,
    String? odometerUnit,
    String? transmission,
    String? fuelType,
    String? preferredLanguage,
    String? scheduledAt,
    String? startedAt,
    String? completedAt,
    String? approvedAt,
    String? publishedAt,
    String? cancelledAt,
    String? approvedBy,
    String? cancelledBy,
    String? cancelReason,
    int? score,
    String? gradeCode,
    bool? safetyCapApplied,
    String? safetyCapReason,
    bool? consentGranted,
    String? createdAt,
    String? updatedAt,
    int? version,
  }) => CleanJob(
    id: id ?? this.id,
    reference: reference ?? this.reference,
    status: status ?? this.status,
    reviewStatus: reviewStatus ?? this.reviewStatus,
    publicationStatus: publicationStatus ?? this.publicationStatus,
    templateVersionId: templateVersionId ?? this.templateVersionId,
    templateNameEn: templateNameEn ?? this.templateNameEn,
    templateNameAr: templateNameAr ?? this.templateNameAr,
    templateVersionNo: templateVersionNo ?? this.templateVersionNo,
    assignedTechnicianId:
        assignedTechnicianId ?? this.assignedTechnicianId,
    assignedTechnicianName:
        assignedTechnicianName ?? this.assignedTechnicianName,
    customerName: customerName ?? this.customerName,
    customerPhone: customerPhone ?? this.customerPhone,
    customerEmail: customerEmail ?? this.customerEmail,
    vehicleVin: vehicleVin ?? this.vehicleVin,
    vehicleMake: vehicleMake ?? this.vehicleMake,
    vehicleModel: vehicleModel ?? this.vehicleModel,
    vehicleYear: vehicleYear ?? this.vehicleYear,
    vehiclePlate: vehiclePlate ?? this.vehiclePlate,
    odometerValue: odometerValue ?? this.odometerValue,
    odometerUnit: odometerUnit ?? this.odometerUnit,
    transmission: transmission ?? this.transmission,
    fuelType: fuelType ?? this.fuelType,
    preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt ?? this.completedAt,
    approvedAt: approvedAt ?? this.approvedAt,
    publishedAt: publishedAt ?? this.publishedAt,
    cancelledAt: cancelledAt ?? this.cancelledAt,
    approvedBy: approvedBy ?? this.approvedBy,
    cancelledBy: cancelledBy ?? this.cancelledBy,
    cancelReason: cancelReason ?? this.cancelReason,
    score: score ?? this.score,
    gradeCode: gradeCode ?? this.gradeCode,
    safetyCapApplied: safetyCapApplied ?? this.safetyCapApplied,
    safetyCapReason: safetyCapReason ?? this.safetyCapReason,
    consentGranted: consentGranted ?? this.consentGranted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
  );

  factory CleanJob.fromJson(Map<String, dynamic> json) => CleanJob(
    id: _string(json['id']),
    reference: _string(json['reference']),
    status: _string(json['status']),
    reviewStatus: _string(json['reviewStatus']),
    publicationStatus: _string(json['publicationStatus']),
    templateVersionId: _string(json['templateVersionId']),
    templateNameEn: _string(json['templateNameEn']),
    templateNameAr: _string(json['templateNameAr']),
    templateVersionNo: _intOrNull(json['templateVersionNo']),
    assignedTechnicianId: _stringOrNull(json['assignedTechnicianId']),
    assignedTechnicianName: _stringOrNull(json['assignedTechnicianName']),
    customerName: _string(json['customerName']),
    customerPhone: _stringOrNull(json['customerPhone']),
    customerEmail: _stringOrNull(json['customerEmail']),
    vehicleVin: _stringOrNull(json['vehicleVin']),
    vehicleMake: _string(json['vehicleMake']),
    vehicleModel: _string(json['vehicleModel']),
    vehicleYear: _intOrNull(json['vehicleYear']),
    vehiclePlate: _stringOrNull(json['vehiclePlate']),
    odometerValue: _intOrNull(json['odometerValue']),
    odometerUnit: _stringOrNull(json['odometerUnit']),
    transmission: _stringOrNull(json['transmission']),
    fuelType: _stringOrNull(json['fuelType']),
    preferredLanguage: _stringOrNull(json['preferredLanguage']),
    scheduledAt: _stringOrNull(json['scheduledAt']),
    startedAt: _stringOrNull(json['startedAt']),
    completedAt: _stringOrNull(json['completedAt']),
    approvedAt: _stringOrNull(json['approvedAt']),
    publishedAt: _stringOrNull(json['publishedAt']),
    cancelledAt: _stringOrNull(json['cancelledAt']),
    approvedBy: _stringOrNull(json['approvedBy']),
    cancelledBy: _stringOrNull(json['cancelledBy']),
    cancelReason: _stringOrNull(json['cancelReason']),
    score: _intOrNull(json['score']),
    gradeCode: _stringOrNull(json['gradeCode']),
    safetyCapApplied: _bool(json['safetyCapApplied']),
    safetyCapReason: _stringOrNull(json['safetyCapReason']),
    consentGranted: _bool(json['consentGranted']),
    createdAt: _stringOrNull(json['createdAt']),
    updatedAt: _stringOrNull(json['updatedAt']),
    version: _intOrNull(json['version']),
  );
}

class JobPage {
  const JobPage({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
    required this.totalPages,
  });

  final List<CleanJob> items;
  final int page;
  final int size;
  final int total;
  final int totalPages;

  factory JobPage.fromJson(Map<String, dynamic> json) => JobPage(
    items: _list(json['items'])
        .whereType<Map<String, dynamic>>()
        .map(CleanJob.fromJson)
        .toList(growable: false),
    page: _int(json['page']),
    size: _int(json['size']),
    total: _int(json['total']),
    totalPages: _int(json['totalPages']),
  );
}

class CleanJobCounts {
  const CleanJobCounts({
    required this.draft,
    required this.scheduled,
    required this.assigned,
    required this.inProgress,
    required this.pendingReview,
    required this.approved,
    required this.published,
    required this.rejected,
    required this.cancelled,
    required this.total,
  });

  final int draft;
  final int scheduled;
  final int assigned;
  final int inProgress;
  final int pendingReview;
  final int approved;
  final int published;
  final int rejected;
  final int cancelled;
  final int total;

  factory CleanJobCounts.fromJson(Map<String, dynamic> json) =>
      CleanJobCounts(
        draft: _int(json['draft']),
        scheduled: _int(json['scheduled']),
        assigned: _int(json['assigned']),
        inProgress: _int(json['inProgress']),
        pendingReview: _int(json['pendingReview']),
        approved: _int(json['approved']),
        published: _int(json['published']),
        rejected: _int(json['rejected']),
        cancelled: _int(json['cancelled']),
        total: _int(json['total']),
      );
}

class JobAssignment {
  const JobAssignment({
    required this.id,
    required this.technicianId,
    required this.assignedBy,
    required this.assignedAt,
    required this.unassignedAt,
    required this.reason,
  });

  final String id;
  final String technicianId;
  final String? assignedBy;
  final String? assignedAt;
  final String? unassignedAt;
  final String? reason;

  factory JobAssignment.fromJson(Map<String, dynamic> json) => JobAssignment(
    id: _string(json['id']),
    technicianId: _string(json['technicianId']),
    assignedBy: _stringOrNull(json['assignedBy']),
    assignedAt: _stringOrNull(json['assignedAt']),
    unassignedAt: _stringOrNull(json['unassignedAt']),
    reason: _stringOrNull(json['reason']),
  );
}

class ReviewFinding {
  const ReviewFinding({
    required this.itemVersionId,
    required this.stableCode,
    required this.labelEn,
    required this.labelAr,
    required this.resultCode,
    required this.score,
    required this.evidencePhotos,
    required this.evidenceVideos,
    required this.signaturePresent,
    required this.completedAt,
    required this.issueValues,
  });

  final String itemVersionId;
  final String stableCode;
  final String labelEn;
  final String labelAr;
  final String? resultCode;
  final int? score;
  final List<dynamic> evidencePhotos;
  final List<dynamic> evidenceVideos;
  final bool signaturePresent;
  final String? completedAt;
  final Map<String, dynamic> issueValues;

  factory ReviewFinding.fromJson(Map<String, dynamic> json) => ReviewFinding(
    itemVersionId: _string(json['itemVersionId']),
    stableCode: _string(json['stableCode']),
    labelEn: _string(json['labelEn']),
    labelAr: _string(json['labelAr']),
    resultCode: _stringOrNull(json['resultCode']),
    score: _intOrNull(json['score']),
    evidencePhotos: _list(json['evidencePhotos']),
    evidenceVideos: _list(json['evidenceVideos']),
    signaturePresent: _bool(json['signaturePresent']),
    completedAt: _stringOrNull(json['completedAt']),
    issueValues: _map(json['issueValues']),
  );
}

class JobReview {
  const JobReview({
    required this.jobId,
    required this.status,
    required this.itemsAssessed,
    required this.itemsTotal,
    required this.scorePreview,
    required this.gradePreview,
    required this.safetyCapPreview,
    required this.findings,
  });

  final String jobId;
  final String status;
  final int itemsAssessed;
  final int itemsTotal;
  final double? scorePreview;
  final String? gradePreview;
  final String? safetyCapPreview;
  final List<ReviewFinding> findings;

  factory JobReview.fromJson(Map<String, dynamic> json) => JobReview(
    jobId: _string(json['jobId']),
    status: _string(json['status']),
    itemsAssessed: _int(json['itemsAssessed']),
    itemsTotal: _int(json['itemsTotal']),
    scorePreview: _doubleOrNull(json['scorePreview']),
    gradePreview: _stringOrNull(json['gradePreview']),
    safetyCapPreview: _stringOrNull(json['safetyCapPreview']),
    findings: _list(json['findings'])
        .whereType<Map<String, dynamic>>()
        .map(ReviewFinding.fromJson)
        .toList(growable: false),
  );
}

class ChecklistEntry {
  const ChecklistEntry({
    required this.code,
    required this.passed,
    required this.messageEn,
    required this.messageAr,
  });

  final String code;
  final bool passed;
  final String messageEn;
  final String messageAr;

  factory ChecklistEntry.fromJson(Map<String, dynamic> json) => ChecklistEntry(
    code: _string(json['code']),
    passed: _bool(json['passed']),
    messageEn: _string(json['messageEn']),
    messageAr: _string(json['messageAr']),
  );
}

class PublishChecklist {
  const PublishChecklist({
    required this.jobId,
    required this.ready,
    required this.items,
    required this.itemsAssessed,
    required this.itemsTotal,
    required this.score,
    required this.gradeCode,
    required this.safetyCapApplied,
    required this.safetyCapReason,
    required this.consentGranted,
    required this.signaturePresent,
    required this.documentsReady,
  });

  final String jobId;
  final bool ready;
  final List<ChecklistEntry> items;
  final int itemsAssessed;
  final int itemsTotal;
  final double? score;
  final String? gradeCode;
  final bool safetyCapApplied;
  final String? safetyCapReason;
  final bool consentGranted;
  final bool signaturePresent;
  final bool documentsReady;

  factory PublishChecklist.fromJson(Map<String, dynamic> json) =>
      PublishChecklist(
        jobId: _string(json['jobId']),
        ready: _bool(json['ready']),
        items: _list(json['items'])
            .whereType<Map<String, dynamic>>()
            .map(ChecklistEntry.fromJson)
            .toList(growable: false),
        itemsAssessed: _int(json['itemsAssessed']),
        itemsTotal: _int(json['itemsTotal']),
        score: _doubleOrNull(json['score']),
        gradeCode: _stringOrNull(json['gradeCode']),
        safetyCapApplied: _bool(json['safetyCapApplied']),
        safetyCapReason: _stringOrNull(json['safetyCapReason']),
        consentGranted: _bool(json['consentGranted']),
        signaturePresent: _bool(json['signaturePresent']),
        documentsReady: _bool(json['documentsReady']),
      );
}

class PublicLink {
  const PublicLink({
    required this.jobId,
    required this.status,
    required this.publicUrl,
    required this.token,
    required this.qrUrl,
    required this.pdfDownloadEnabled,
    required this.activatedAt,
    required this.revokedAt,
    required this.revocationReason,
  });

  final String jobId;
  final String status;
  final String? publicUrl;
  final String? token;
  final String? qrUrl;
  final bool pdfDownloadEnabled;
  final String? activatedAt;
  final String? revokedAt;
  final String? revocationReason;

  PublicLink copyWith({
    String? jobId,
    String? status,
    String? publicUrl,
    String? token,
    String? qrUrl,
    bool? pdfDownloadEnabled,
    String? activatedAt,
    String? revokedAt,
    String? revocationReason,
  }) => PublicLink(
    jobId: jobId ?? this.jobId,
    status: status ?? this.status,
    publicUrl: publicUrl ?? this.publicUrl,
    token: token ?? this.token,
    qrUrl: qrUrl ?? this.qrUrl,
    pdfDownloadEnabled: pdfDownloadEnabled ?? this.pdfDownloadEnabled,
    activatedAt: activatedAt ?? this.activatedAt,
    revokedAt: revokedAt ?? this.revokedAt,
    revocationReason: revocationReason ?? this.revocationReason,
  );

  factory PublicLink.fromJson(Map<String, dynamic> json) => PublicLink(
    jobId: _string(json['jobId']),
    status: _string(json['status']),
    publicUrl: _stringOrNull(json['publicUrl']),
    token: _stringOrNull(json['token']),
    qrUrl: _stringOrNull(json['qrUrl']),
    pdfDownloadEnabled: _bool(json['pdfDownloadEnabled']),
    activatedAt: _stringOrNull(json['activatedAt']),
    revokedAt: _stringOrNull(json['revokedAt']),
    revocationReason: _stringOrNull(json['revocationReason']),
  );
}

class JobDocument {
  const JobDocument({
    required this.id,
    required this.documentTypeCode,
    required this.nameEn,
    required this.nameAr,
    required this.language,
    required this.status,
    required this.bytes,
    required this.generatedAt,
    required this.error,
    required this.downloadUrl,
  });

  final String id;
  final String documentTypeCode;
  final String nameEn;
  final String nameAr;
  final String language;
  final String status;
  final int bytes;
  final String? generatedAt;
  final String? error;
  final String? downloadUrl;

  factory JobDocument.fromJson(Map<String, dynamic> json) => JobDocument(
    id: _string(json['id']),
    documentTypeCode: _string(json['documentTypeCode']),
    nameEn: _string(json['nameEn']),
    nameAr: _string(json['nameAr']),
    language: _string(json['language']),
    status: _string(json['status']),
    bytes: _int(json['bytes']),
    generatedAt: _stringOrNull(json['generatedAt']),
    error: _stringOrNull(json['error']),
    downloadUrl: _stringOrNull(json['downloadUrl']),
  );
}

class WorkshopNotification {
  const WorkshopNotification({
    required this.id,
    required this.type,
    required this.payloadJson,
    required this.readAt,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String? payloadJson;
  final String? readAt;
  final String? createdAt;

  bool get isRead => readAt != null && readAt!.isNotEmpty;

  factory WorkshopNotification.fromJson(Map<String, dynamic> json) =>
      WorkshopNotification(
        id: _string(json['id']),
        type: _string(json['type']),
        payloadJson: _stringOrNull(json['payloadJson']),
        readAt: _stringOrNull(json['readAt']),
        createdAt: _stringOrNull(json['createdAt']),
      );
}

/// Request body for `POST /workshop/jobs`.
class NewCleanJob {
  const NewCleanJob({
    required this.templateVersionId,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    this.vehicleVin,
    required this.vehicleMake,
    required this.vehicleModel,
    this.vehicleYear,
    this.vehiclePlate,
    this.odometerValue,
    this.odometerUnit,
    this.transmission,
    this.fuelType,
    this.preferredLanguage,
    this.scheduledAt,
    this.assignedTechnicianId,
  });

  final String templateVersionId;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String? vehicleVin;
  final String vehicleMake;
  final String vehicleModel;
  final int? vehicleYear;
  final String? vehiclePlate;
  final int? odometerValue;
  final String? odometerUnit;
  final String? transmission;
  final String? fuelType;
  final String? preferredLanguage;
  final String? scheduledAt;
  final String? assignedTechnicianId;

  Map<String, dynamic> toJson() => {
    'templateVersionId': templateVersionId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'customerEmail': customerEmail,
    'vehicleVin': vehicleVin,
    'vehicleMake': vehicleMake,
    'vehicleModel': vehicleModel,
    'vehicleYear': vehicleYear,
    'vehiclePlate': vehiclePlate,
    'odometerValue': odometerValue,
    'odometerUnit': odometerUnit,
    'transmission': transmission,
    'fuelType': fuelType,
    'preferredLanguage': preferredLanguage,
    'scheduledAt': scheduledAt,
    'assignedTechnicianId': assignedTechnicianId,
  };
}

/// Request body for `PUT /workshop/jobs/{id}`.
class UpdateCleanJob {
  const UpdateCleanJob({
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    this.vehicleVin,
    required this.vehicleMake,
    required this.vehicleModel,
    this.vehicleYear,
    this.vehiclePlate,
    this.odometerValue,
    this.odometerUnit,
    this.transmission,
    this.fuelType,
    this.preferredLanguage,
    this.version,
  });

  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String? vehicleVin;
  final String vehicleMake;
  final String vehicleModel;
  final int? vehicleYear;
  final String? vehiclePlate;
  final int? odometerValue;
  final String? odometerUnit;
  final String? transmission;
  final String? fuelType;
  final String? preferredLanguage;
  final int? version;

  Map<String, dynamic> toJson() => {
    'customerName': customerName,
    'customerPhone': customerPhone,
    'customerEmail': customerEmail,
    'vehicleVin': vehicleVin,
    'vehicleMake': vehicleMake,
    'vehicleModel': vehicleModel,
    'vehicleYear': vehicleYear,
    'vehiclePlate': vehiclePlate,
    'odometerValue': odometerValue,
    'odometerUnit': odometerUnit,
    'transmission': transmission,
    'fuelType': fuelType,
    'preferredLanguage': preferredLanguage,
    'version': version,
  };
}
