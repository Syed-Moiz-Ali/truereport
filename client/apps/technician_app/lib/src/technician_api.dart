import 'package:api_client/api_client.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/models.dart';
import 'package:uuid/uuid.dart';

abstract class TechnicianApi {
  Future<List<TechnicianJob>> jobs();

  Future<TechnicianJob> job(String id);

  Future<List<TemplateVersionOption>> templateVersions();

  Future<TechnicianJob> createWalkIn({
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
  });

  Future<InspectionChecklist> start(String jobId);

  Future<InspectionChecklist> checklist(String jobId);

  Future<TechnicianJob> updateCustomer(
    String jobId, {
    required String customerName,
    String? customerPhone,
    String? customerEmail,
  });

  Future<TechnicianJob> updateVehicle(
    String jobId, {
    required String vehicleMake,
    required String vehicleModel,
    int? vehicleYear,
    String? vehicleVin,
    String? vehiclePlate,
    int? odometerValue,
    String? odometerUnit,
  });

  Future<void> recordConsent(
    String jobId, {
    required String consentType,
    required String status,
    required String wordingVersion,
    required String channel,
    String? evidenceRef,
  });

  Future<List<EquipmentItem>> equipment(String jobId);

  Future<InspectionItem> assess(
    String jobId,
    String itemId, {
    required int baseVersion,
    required int clientRevision,
    required String resultCode,
    String? severityCode,
    String? note,
    String? noteLanguage,
    String? reasonCode,
    String? reasonText,
  });

  Future<ReviewResult> review(String jobId);

  Future<InspectionChecklist> ready(String jobId);

  Future<FinalizeResult> finalize(String jobId, String idempotencyKey);

  Future<EvidenceInitResult> initEvidence(
    String jobId,
    String itemId, {
    required String evidenceId,
    required String mime,
    required int bytes,
    required String sha256,
    String? capturedAt,
  });

  Future<void> uploadEvidence(
    String uploadUrl,
    String uploadToken,
    List<int> bytes,
  );

  Future<InspectionEvidence> completeEvidence(
    String jobId,
    String itemId,
    String evidenceId,
    String sha256,
  );

  Future<List<InspectionEvidence>> evidence(String jobId, String itemId);

  Future<List<int>> guideImage(String jobId, String itemId);

  Future<TechnicianReportStatus> reportStatus(String jobId);

  Future<List<TechnicianDelivery>> deliveries(String jobId);

  // ------------------------------------------------- clean technician API
  Future<JobSummaryPage> technicianJobs({
    int page = 0,
    int size = 20,
    String? status,
  });

  Future<JobSummary> technicianJob(String id);

  Future<Checklist> cleanChecklist(String jobId);

  Future<Assessment> saveAssessment(
    String jobId,
    String itemCode,
    AssessmentRequest request, {
    String? idempotencyKey,
  });

  Future<Summary> summary(String jobId);

  Future<Review> cleanReview(String jobId);

  Future<Signature> submitSignature(
    String jobId,
    SignatureRequest request, {
    String? idempotencyKey,
  });

  Future<CompleteResult> completeJob(
    String jobId,
    CompleteRequest request, {
    String? idempotencyKey,
  });

  Future<SyncResult> sync(String jobId, SyncRequest request);

  Future<Evidence> cleanInitEvidence(
    String jobId,
    String itemCode,
    EvidenceInitRequest request, {
    String? idempotencyKey,
  });

  Future<Evidence> uploadEvidenceContent(
    String jobId,
    String itemCode,
    String evidenceId,
    List<int> bytes, {
    required String contentType,
  });

  Future<Evidence> cleanCompleteEvidence(
    String jobId,
    String itemCode,
    String evidenceId,
    EvidenceCompleteRequest request,
  );

  Future<List<Evidence>> evidenceList(String jobId, String itemCode);

  Future<List<int>> evidenceContent(
    String jobId,
    String itemCode,
    String evidenceId,
  );

  Future<void> deleteEvidence(String jobId, String itemCode, String evidenceId);
}

class HttpTechnicianApi implements TechnicianApi {
  HttpTechnicianApi(this._api, this._endpoints);

  final ApiClient _api;
  final ApiEndpoints _endpoints;

  @override
  Future<List<TechnicianJob>> jobs() async {
    final data = await _api.getDynamic(_endpoints.technicianJobs);
    return (data as List<dynamic>)
        .map((item) => TechnicianJob.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<TechnicianJob> job(String id) async {
    final data = await _api.getDynamic(_endpoints.technicianJob(id));
    return TechnicianJob.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<TemplateVersionOption>> templateVersions() async {
    final data = await _api.getDynamic(_endpoints.technicianTemplateVersions);
    return (data as List<dynamic>)
        .map(
          (item) =>
              TemplateVersionOption.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Future<TechnicianJob> createWalkIn({
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
  }) async {
    final data = await _api.postDynamic(
      _endpoints.technicianJobs,
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
      },
    );
    return TechnicianJob.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<InspectionChecklist> start(String jobId) async {
    final data = await _api.postDynamic(_endpoints.technicianStart(jobId));
    return InspectionChecklist.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<InspectionChecklist> checklist(String jobId) async {
    final data = await _api.getDynamic(_endpoints.technicianChecklist(jobId));
    return InspectionChecklist.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<TechnicianJob> updateCustomer(
    String jobId, {
    required String customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    final data = await _api.putDynamic(
      _endpoints.technicianCustomer(jobId),
      body: {
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
      },
    );
    return TechnicianJob.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<TechnicianJob> updateVehicle(
    String jobId, {
    required String vehicleMake,
    required String vehicleModel,
    int? vehicleYear,
    String? vehicleVin,
    String? vehiclePlate,
    int? odometerValue,
    String? odometerUnit,
  }) async {
    final data = await _api.putDynamic(
      _endpoints.technicianVehicle(jobId),
      body: {
        'vehicleMake': vehicleMake,
        'vehicleModel': vehicleModel,
        'vehicleYear': vehicleYear,
        'vehicleVin': vehicleVin,
        'vehiclePlate': vehiclePlate,
        'odometerValue': odometerValue,
        'odometerUnit': odometerUnit,
      },
    );
    return TechnicianJob.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> recordConsent(
    String jobId, {
    required String consentType,
    required String status,
    required String wordingVersion,
    required String channel,
    String? evidenceRef,
  }) async {
    await _api.postDynamic(
      _endpoints.technicianConsent(jobId),
      body: {
        'consentType': consentType,
        'status': status,
        'wordingVersion': wordingVersion,
        'channel': channel,
        'evidenceRef': evidenceRef,
      },
    );
  }

  @override
  Future<List<EquipmentItem>> equipment(String jobId) async {
    final data = await _api.getDynamic(_endpoints.technicianEquipment(jobId));
    final map = data as Map<String, dynamic>;
    final items = (map['items'] as List<dynamic>?) ?? <dynamic>[];
    if (items.isNotEmpty) {
      return items
          .map((value) => EquipmentItem.fromJson(value as Map<String, dynamic>))
          .toList(growable: false);
    }
    final ids = (map['equipmentIds'] as List<dynamic>?) ?? <dynamic>[];
    return ids
        .map(
          (value) => EquipmentItem(
            equipmentId: value.toString(),
            code: '',
            labelEn: '',
            labelAr: '',
            status: '',
            sortOrder: 0,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<InspectionItem> assess(
    String jobId,
    String itemId, {
    required int baseVersion,
    required int clientRevision,
    required String resultCode,
    String? severityCode,
    String? note,
    String? noteLanguage,
    String? reasonCode,
    String? reasonText,
  }) async {
    final data = await _api.putDynamic(
      _endpoints.technicianAssessment(jobId, itemId),
      body: {
        'baseVersion': baseVersion,
        'clientRevision': clientRevision,
        'resultCode': resultCode,
        'severityCode': severityCode,
        'note': note,
        'noteLanguage': noteLanguage,
        'reasonCode': reasonCode,
        'reasonText': reasonText,
      },
    );
    return InspectionItem.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<ReviewResult> review(String jobId) async {
    final data = await _api.getDynamic(_endpoints.technicianReview(jobId));
    return ReviewResult.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<InspectionChecklist> ready(String jobId) async {
    final data = await _api.postDynamic(_endpoints.technicianReady(jobId));
    return InspectionChecklist.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<FinalizeResult> finalize(String jobId, String idempotencyKey) async {
    final data = await _api.postDynamic(
      _endpoints.technicianFinalize(jobId),
      headers: {'Idempotency-Key': idempotencyKey},
    );
    return FinalizeResult.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<EvidenceInitResult> initEvidence(
    String jobId,
    String itemId, {
    required String evidenceId,
    required String mime,
    required int bytes,
    required String sha256,
    String? capturedAt,
  }) async {
    final data = await _api.postDynamic(
      _endpoints.technicianEvidenceInit(jobId, itemId),
      body: {
        'evidenceId': evidenceId,
        'mime': mime,
        'bytes': bytes,
        'sha256': sha256,
        'capturedAt': capturedAt,
      },
    );
    return EvidenceInitResult.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> uploadEvidence(
    String uploadUrl,
    String uploadToken,
    List<int> bytes,
  ) async {
    await _api.putBytes(
      uploadUrl,
      bytes: bytes,
      contentType: 'application/octet-stream',
    );
  }

  @override
  Future<InspectionEvidence> completeEvidence(
    String jobId,
    String itemId,
    String evidenceId,
    String sha256,
  ) async {
    final data = await _api.postDynamic(
      _endpoints.technicianEvidenceComplete(jobId, itemId, evidenceId),
      body: {'sha256': sha256},
    );
    return InspectionEvidence.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<InspectionEvidence>> evidence(String jobId, String itemId) async {
    final data = await _api.getDynamic(
      _endpoints.technicianEvidence(jobId, itemId),
    );
    return (data as List<dynamic>)
        .map(
          (item) => InspectionEvidence.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Future<List<int>> guideImage(String jobId, String itemId) {
    return _api.getBytes(_endpoints.technicianGuideImage(jobId, itemId));
  }

  @override
  Future<TechnicianReportStatus> reportStatus(String jobId) async {
    final data = await _api.getDynamic(_endpoints.technicianReport(jobId));
    return TechnicianReportStatus.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<TechnicianDelivery>> deliveries(String jobId) async {
    final data = await _api.getDynamic(
      _endpoints.technicianJobDeliveries(jobId),
    );
    return (data as List<dynamic>)
        .map(
          (item) => TechnicianDelivery.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Future<JobSummaryPage> technicianJobs({
    int page = 0,
    int size = 20,
    String? status,
  }) async {
    final data = await _api.getDynamic(
      _endpoints.technicianCleanJobs,
      query: {
        'page': page,
        'size': size,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return JobSummaryPage.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<JobSummary> technicianJob(String id) async {
    final data = await _api.getDynamic(_endpoints.technicianCleanJob(id));
    return JobSummary.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Checklist> cleanChecklist(String jobId) async {
    final data = await _api.getDynamic(
      _endpoints.technicianCleanChecklist(jobId),
    );
    return Checklist.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Assessment> saveAssessment(
    String jobId,
    String itemCode,
    AssessmentRequest request, {
    String? idempotencyKey,
  }) async {
    final data = await _api.putDynamic(
      _endpoints.technicianCleanItem(jobId, itemCode),
      body: request.toJson(),
      headers: _idempotencyHeaders(idempotencyKey),
    );
    return Assessment.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Summary> summary(String jobId) async {
    final data = await _api.getDynamic(
      _endpoints.technicianCleanSummary(jobId),
    );
    return Summary.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Review> cleanReview(String jobId) async {
    final data = await _api.getDynamic(_endpoints.technicianCleanReview(jobId));
    return Review.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Signature> submitSignature(
    String jobId,
    SignatureRequest request, {
    String? idempotencyKey,
  }) async {
    final data = await _api.postDynamic(
      _endpoints.technicianCleanSignature(jobId),
      body: request.toJson(),
      headers: _idempotencyHeaders(idempotencyKey),
    );
    return Signature.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<CompleteResult> completeJob(
    String jobId,
    CompleteRequest request, {
    String? idempotencyKey,
  }) async {
    final data = await _api.postDynamic(
      _endpoints.technicianCleanComplete(jobId),
      body: request.toJson(),
      headers: _idempotencyHeaders(idempotencyKey),
    );
    return CompleteResult.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<SyncResult> sync(String jobId, SyncRequest request) async {
    final data = await _api.postDynamic(
      _endpoints.technicianCleanSync(jobId),
      body: request.toJson(),
    );
    return SyncResult.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Evidence> cleanInitEvidence(
    String jobId,
    String itemCode,
    EvidenceInitRequest request, {
    String? idempotencyKey,
  }) async {
    final data = await _api.postDynamic(
      _endpoints.technicianCleanEvidenceInit(jobId, itemCode),
      body: request.toJson(),
      headers: _idempotencyHeaders(idempotencyKey),
    );
    return Evidence.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Evidence> uploadEvidenceContent(
    String jobId,
    String itemCode,
    String evidenceId,
    List<int> bytes, {
    required String contentType,
  }) async {
    final data = await _api.putBytesWithHeaders(
      _endpoints.technicianCleanEvidenceContent(jobId, itemCode, evidenceId),
      bytes: bytes,
      contentType: contentType,
    );
    return Evidence.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Evidence> cleanCompleteEvidence(
    String jobId,
    String itemCode,
    String evidenceId,
    EvidenceCompleteRequest request,
  ) async {
    final data = await _api.postDynamic(
      _endpoints.technicianCleanEvidenceComplete(jobId, itemCode, evidenceId),
      body: request.toJson(),
    );
    return Evidence.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<Evidence>> evidenceList(String jobId, String itemCode) async {
    final data = await _api.getDynamic(
      _endpoints.technicianCleanEvidenceList(jobId, itemCode),
    );
    return (data as List<dynamic>)
        .map((item) => Evidence.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<List<int>> evidenceContent(
    String jobId,
    String itemCode,
    String evidenceId,
  ) {
    return _api.getBytes(
      _endpoints.technicianCleanEvidenceContent(jobId, itemCode, evidenceId),
    );
  }

  @override
  Future<void> deleteEvidence(
    String jobId,
    String itemCode,
    String evidenceId,
  ) async {
    await _api.deleteDynamic(
      _endpoints.technicianCleanEvidence(jobId, itemCode, evidenceId),
    );
  }

  Map<String, String>? _idempotencyHeaders(String? idempotencyKey) {
    final key = idempotencyKey ?? const Uuid().v7();
    if (key.isEmpty) {
      return null;
    }
    return {'Idempotency-Key': key};
  }
}
