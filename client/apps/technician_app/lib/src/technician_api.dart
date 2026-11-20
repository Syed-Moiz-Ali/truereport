import 'package:api_client/api_client.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:uuid/uuid.dart';

abstract class TechnicianApi {
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
    void Function(int sent, int total)? onSendProgress,
    RequestCancellation? cancellation,
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
    void Function(int sent, int total)? onSendProgress,
    RequestCancellation? cancellation,
  }) async {
    final data = await _api.putBytesWithHeaders(
      _endpoints.technicianCleanEvidenceContent(jobId, itemCode, evidenceId),
      bytes: bytes,
      contentType: contentType,
      onSendProgress: onSendProgress,
      cancellation: cancellation,
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
