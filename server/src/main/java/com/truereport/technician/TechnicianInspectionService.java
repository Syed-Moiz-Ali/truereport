package com.truereport.technician;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.shared.audit.FieldAuditService;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import com.truereport.shared.idempotency.IdempotencyService;
import com.truereport.shared.outbox.OutboxService;
import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.storage.ObjectStorage;
import com.truereport.shared.uuid.UuidV7;
import com.truereport.technician.TechnicianStore.AssessmentRow;
import com.truereport.technician.TechnicianStore.ChecklistRow;
import com.truereport.technician.TechnicianStore.ConflictRow;
import com.truereport.technician.TechnicianStore.EvidenceRow;
import com.truereport.technician.TechnicianStore.EvidenceRuleRow;
import com.truereport.technician.TechnicianStore.GradeBoundaryRow;
import com.truereport.technician.TechnicianStore.IssueFieldRow;
import com.truereport.technician.TechnicianStore.IssueValueRow;
import com.truereport.technician.TechnicianStore.ItemRow;
import com.truereport.technician.TechnicianStore.JobRow;
import com.truereport.technician.TechnicianStore.MeasureBandRow;
import com.truereport.technician.TechnicianStore.MeasurementRow;
import com.truereport.technician.TechnicianStore.OptionRow;
import com.truereport.technician.TechnicianStore.ScoreBandRow;
import com.truereport.technician.TechnicianStore.ScoringRuleRow;
import com.truereport.technician.TechnicianStore.SignatureRow;
import com.truereport.technician.TechnicianStore.TemplateRow;
import com.truereport.technician.api.TechnicianDtos.AssessmentDto;
import com.truereport.technician.api.TechnicianDtos.AssessmentRequest;
import com.truereport.technician.api.TechnicianDtos.BlockerDto;
import com.truereport.technician.api.TechnicianDtos.CategoryDto;
import com.truereport.technician.api.TechnicianDtos.ChecklistDto;
import com.truereport.technician.api.TechnicianDtos.ChecklistItemDto;
import com.truereport.technician.api.TechnicianDtos.CompleteDto;
import com.truereport.technician.api.TechnicianDtos.CompleteRequest;
import com.truereport.technician.api.TechnicianDtos.ConflictDto;
import com.truereport.technician.api.TechnicianDtos.EvidenceCompleteRequest;
import com.truereport.technician.api.TechnicianDtos.EvidenceDto;
import com.truereport.technician.api.TechnicianDtos.EvidenceInitRequest;
import com.truereport.technician.api.TechnicianDtos.EvidenceRuleDto;
import com.truereport.technician.api.TechnicianDtos.IssueFieldDto;
import com.truereport.technician.api.TechnicianDtos.IssueValueDto;
import com.truereport.technician.api.TechnicianDtos.JobPageDto;
import com.truereport.technician.api.TechnicianDtos.JobSummaryDto;
import com.truereport.technician.api.TechnicianDtos.MeasurementBandDto;
import com.truereport.technician.api.TechnicianDtos.MeasurementDto;
import com.truereport.technician.api.TechnicianDtos.OptionDto;
import com.truereport.technician.api.TechnicianDtos.PinnedDto;
import com.truereport.technician.api.TechnicianDtos.ProgressDto;
import com.truereport.technician.api.TechnicianDtos.ReviewDto;
import com.truereport.technician.api.TechnicianDtos.ScoreBandDto;
import com.truereport.technician.api.TechnicianDtos.SignatureDto;
import com.truereport.technician.api.TechnicianDtos.SignatureRequest;
import com.truereport.technician.api.TechnicianDtos.SummaryDto;
import com.truereport.technician.api.TechnicianDtos.SyncMutation;
import com.truereport.technician.api.TechnicianDtos.SyncRequest;
import com.truereport.technician.api.TechnicianDtos.SyncResult;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

@Service
public class TechnicianInspectionService {

    static final Set<String> CANONICAL_RESULTS = new LinkedHashSet<>(List.of(
            "NO_ISSUE_OBSERVED", "ATTENTION_RECOMMENDED", "DEFECT_FOUND", "NOT_CHECKED",
            "NOT_APPLICABLE", "COULD_NOT_VERIFY"));

    private static final Map<String, Integer> RESULT_RANK = Map.of(
            "NO_ISSUE_OBSERVED", 0,
            "NOT_APPLICABLE", 1,
            "NOT_CHECKED", 2,
            "COULD_NOT_VERIFY", 3,
            "ATTENTION_RECOMMENDED", 4,
            "DEFECT_FOUND", 5);

    private static final Set<String> JOB_STATUSES = Set.of(
            "DRAFT", "SCHEDULED", "ASSIGNED", "IN_PROGRESS", "PENDING_REVIEW",
            "APPROVED", "PUBLISHED", "REJECTED", "CANCELLED");
    private static final Set<String> EDITABLE_STATUSES = Set.of("ASSIGNED", "IN_PROGRESS");
    private static final Set<String> PHOTO_MIMES = Set.of(
            "image/jpeg", "image/heic", "image/heif", "image/webp");
    private static final Set<String> VIDEO_MIMES = Set.of(
            "video/mp4", "video/webm", "video/quicktime");
    private static final Set<String> DOCUMENT_MIMES = Set.of(
            "application/pdf", "image/jpeg", "image/png", "image/heic", "image/heif",
            "image/webp");
    private static final Set<String> SIGNATURE_METHODS = Set.of(
            "DRAWN", "TYPED", "PIN", "DEVICE");
    private static final List<String> GRADE_ORDER = List.of("A", "B", "C", "D");
    private static final long MAX_PHOTO_BYTES = 20L * 1024 * 1024;
    private static final long MAX_VIDEO_BYTES = 50L * 1024 * 1024;
    private static final long MAX_DOCUMENT_BYTES = 20L * 1024 * 1024;

    private final TechnicianStore store;
    private final FieldAuditService audit;
    private final OutboxService outbox;
    private final IdempotencyService idempotency;
    private final ObjectStorage storage;
    private final ObjectMapper objectMapper;

    public TechnicianInspectionService(TechnicianStore store, FieldAuditService audit,
                                       OutboxService outbox, IdempotencyService idempotency,
                                       ObjectStorage storage, ObjectMapper objectMapper) {
        this.store = store;
        this.audit = audit;
        this.outbox = outbox;
        this.idempotency = idempotency;
        this.storage = storage;
        this.objectMapper = objectMapper;
    }

    // ------------------------------------------------------------------ jobs

    @Transactional(readOnly = true)
    public JobPageDto listJobs(CurrentUser caller, int page, int size, String status) {
        String workshopId = requireWorkshop(caller);
        String filter = status == null ? "" : status.trim().toUpperCase(Locale.ROOT);
        if (!filter.isEmpty() && !JOB_STATUSES.contains(filter)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "INVALID_FILTER",
                    "error.status.invalid", "Invalid job status filter");
        }
        int safePage = Math.max(0, page);
        int safeSize = Math.min(100, Math.max(1, size));
        List<JobRow> rows = store.listJobs(workshopId, caller.userId().toString(), filter,
                safePage * safeSize, safeSize);
        long total = store.countJobs(workshopId, caller.userId().toString(), filter);
        int totalPages = (int) Math.ceil((double) total / safeSize);
        return new JobPageDto(rows.stream().map(this::jobSummary).toList(), safePage, safeSize,
                total, totalPages);
    }

    @Transactional(readOnly = true)
    public JobSummaryDto job(CurrentUser caller, String jobId) {
        return jobSummary(requireJob(caller, jobId));
    }

    @Transactional
    public ChecklistDto checklist(CurrentUser caller, String jobId) {
        JobRow job = requireJob(caller, jobId);
        List<ItemRow> items = store.items(job.templateVersionId());
        Map<String, AssessmentRow> assessments = assessmentsByItem(job.id());
        List<CategoryDto> categories = categories(items);
        String snapshotJson = snapshotJson(job.templateVersionId(), categories, items);
        String hash = sha256(snapshotJson);
        Optional<ChecklistRow> stored = store.checklist(job.id());
        if (stored.isEmpty()) {
            store.insertChecklist(job.id(), job.templateVersionId(), snapshotJson, hash);
        } else if (!stored.get().snapshotHash().equals(hash)) {
            throw new ApiException(HttpStatus.CONFLICT, "CHECKLIST_SNAPSHOT_MISMATCH",
                    "error.technician.checklistChanged",
                    "The pinned checklist configuration no longer matches the stored snapshot");
        }
        String snapshotHash = stored.map(ChecklistRow::snapshotHash).orElse(hash);
        TemplateRow template = store.template(job.templateVersionId()).orElse(null);
        List<ChecklistItemDto> checklistItems = new ArrayList<>();
        for (ItemRow item : items) {
            checklistItems.add(checklistItem(item, assessments.get(item.itemCode())));
        }
        int completed = (int) assessments.values().stream()
                .filter(value -> value.resultCode() != null)
                .count();
        return new ChecklistDto(jobSummary(job), new PinnedDto(job.templateVersionId(),
                template == null ? null : template.versionNo(), snapshotHash), categories,
                checklistItems, new ProgressDto(completed, items.size()),
                (long) job.version());
    }

    // ----------------------------------------------------------- assessments

    @Transactional
    public AssessmentDto saveAssessment(CurrentUser caller, String jobId, String itemCode,
                                        AssessmentRequest request, String idempotencyKey) {
        JobRow job = requireJob(caller, jobId);
        requireEditable(job);
        ItemRow item = requireItem(job, itemCode);
        String endpoint = "PUT /api/v1/technician/jobs/" + jobId + "/items/" + itemCode;
        Optional<AssessmentDto> replay = replay(caller.userId().toString(), endpoint,
                idempotencyKey, AssessmentDto.class);
        if (replay.isPresent()) {
            return replay.get();
        }
        ItemConfig config = config(item);
        Validation validation = validate(job, item, config, request);

        AssessmentRow existing = store.assessment(jobId, itemCode).orElse(null);
        int expectedVersion = existing == null ? 0 : existing.version();
        Integer baseVersion = request.baseVersion();
        if (baseVersion != null && baseVersion != expectedVersion) {
            String serverJson = existing == null ? null : json(assessmentDto(job, existing, config));
            String clientJson = json(request);
            store.insertConflict(jobId, itemCode, request.clientRevision(),
                    existing == null ? 0L : existing.serverRevision(), serverJson, clientJson);
            throw conflict(itemCode, existing);
        }

        store.startJob(jobId);
        String assessmentId;
        if (existing == null) {
            assessmentId = store.insertAssessment(jobId, item.itemVersionId(), itemCode,
                    validation.resultCode(), request.severityCode(),
                    validation.suggestedResultCode(), validation.suggestedScore(),
                    validation.score(), trimToNull(request.notesEn()),
                    trimToNull(request.notesAr()), trimToNull(request.reasonCode()),
                    request.clientRevision(), caller.userId().toString());
        } else {
            assessmentId = existing.id();
            store.updateAssessment(assessmentId, validation.resultCode(), request.severityCode(),
                    validation.suggestedResultCode(), validation.suggestedScore(),
                    validation.score(), trimToNull(request.notesEn()),
                    trimToNull(request.notesAr()), trimToNull(request.reasonCode()),
                    request.clientRevision(), caller.userId().toString());
        }
        store.deleteIssueValues(assessmentId);
        int sort = 0;
        for (IssueValueDto value : safeList(request.issueValues())) {
            store.insertIssueValue(assessmentId, value.fieldCode(), value.valueIndex(),
                    value.optionValueCode(), value.numericValue(), value.unitCode(),
                    value.textValue(), sort++);
        }
        store.deleteMeasurements(assessmentId);
        for (MeasurementWithBand measurement : validation.measurements()) {
            store.insertMeasurement(assessmentId, measurement.fieldCode(), measurement.valueIndex(),
                    measurement.numericValue(), measurement.unitCode(), measurement.bandId(),
                    measurement.resultCode(), measurement.score());
        }
        store.resolveConflicts(jobId, itemCode);
        AssessmentRow saved = store.assessment(jobId, itemCode).orElseThrow();
        AssessmentDto dto = assessmentDto(job, saved, config);
        idempotency.store(caller.userId().toString(), endpoint, idempotencyKey, 200, dto);
        return dto;
    }

    @Transactional
    public SyncResult sync(CurrentUser caller, String jobId, SyncRequest request) {
        JobRow job = requireJob(caller, jobId);
        requireEditable(job);
        List<AssessmentDto> applied = new ArrayList<>();
        List<ConflictDto> conflicts = new ArrayList<>();
        if (request != null && request.mutations() != null) {
            for (SyncMutation mutation : request.mutations()) {
                if (mutation == null || isBlank(mutation.itemCode())) {
                    continue;
                }
                AssessmentRequest assessment = new AssessmentRequest(mutation.baseVersion(),
                        mutation.clientRevision(), mutation.resultCode(), mutation.score(),
                        mutation.severityCode(), mutation.notesEn(), mutation.notesAr(),
                        mutation.reasonCode(), mutation.issueValues(), mutation.measurements());
                try {
                    applied.add(saveAssessment(caller, jobId, mutation.itemCode(), assessment,
                            mutation.idempotencyKey()));
                } catch (ApiException exception) {
                    if (exception.status() == HttpStatus.CONFLICT
                            && "SYNC_CONFLICT".equals(exception.code())) {
                        ConflictRow row = store.conflicts(jobId, true).stream()
                                .filter(value -> value.itemCode().equals(mutation.itemCode()))
                                .reduce((first, second) -> second)
                                .orElse(null);
                        conflicts.add(row == null
                                ? new ConflictDto(mutation.itemCode(), mutation.clientRevision(),
                                        null, null, json(assessment))
                                : new ConflictDto(row.itemCode(), row.clientRevision(),
                                        row.serverRevision(), row.serverPayloadJson(),
                                        row.clientPayloadJson()));
                    } else {
                        throw exception;
                    }
                }
            }
        }
        return new SyncResult(applied, conflicts, store.jobVersion(jobId));
    }

    @Transactional(readOnly = true)
    public SummaryDto summary(CurrentUser caller, String jobId) {
        JobRow job = requireJob(caller, jobId);
        List<ItemRow> items = store.items(job.templateVersionId());
        Map<String, AssessmentRow> assessments = assessmentsByItem(job.id());
        List<BlockerDto> blockers = new ArrayList<>();
        List<BlockerDto> warnings = new ArrayList<>();
        int assessed = 0;
        for (ItemRow item : items) {
            AssessmentRow assessment = assessments.get(item.itemCode());
            if (assessment == null) {
                blockers.add(new BlockerDto("ITEM_NOT_ASSESSED", item.itemCode(),
                        "The item has not been assessed", "لم يتم تقييم العنصر"));
                continue;
            }
            assessed++;
            blockers.addAll(evidenceBlockers(job, item, config(item), assessment));
        }
        if (!job.signaturePresent()) {
            blockers.add(new BlockerDto("SIGNATURE_MISSING", null,
                    "Technician signature is missing", "توقيع الفني مفقود"));
        }
        List<ConflictRow> conflictRows = store.conflicts(job.id(), true);
        for (ConflictRow conflict : conflictRows) {
            blockers.add(new BlockerDto("SYNC_CONFLICT", conflict.itemCode(),
                    "The item has an unresolved sync conflict",
                    "يوجد تعارض مزامنة غير محلول لهذا العنصر"));
        }
        ScoreResult score = computeScore(items, assessments);
        if (score.capApplied()) {
            warnings.add(new BlockerDto("SAFETY_CAP_APPLIED", null,
                    String.valueOf(score.capReason()), String.valueOf(score.capReason())));
        }
        return new SummaryDto(job.id(), job.status(), assessed, items.size(), score.score(),
                score.grade(), score.capApplied(), score.capReason(), blockers, warnings,
                conflictRows.stream().map(this::conflictDto).toList());
    }

    @Transactional(readOnly = true)
    public ReviewDto review(CurrentUser caller, String jobId) {
        JobRow job = requireJob(caller, jobId);
        List<ItemRow> items = store.items(job.templateVersionId());
        Map<String, AssessmentRow> assessments = assessmentsByItem(job.id());
        List<AssessmentDto> findings = new ArrayList<>();
        List<BlockerDto> blockers = new ArrayList<>();
        for (ItemRow item : items) {
            AssessmentRow assessment = assessments.get(item.itemCode());
            if (assessment == null) {
                blockers.add(new BlockerDto("ITEM_NOT_ASSESSED", item.itemCode(),
                        "The item has not been assessed", "لم يتم تقييم العنصر"));
                continue;
            }
            ItemConfig config = config(item);
            findings.add(assessmentDto(job, assessment, config));
            blockers.addAll(evidenceBlockers(job, item, config, assessment));
        }
        if (!job.signaturePresent()) {
            blockers.add(new BlockerDto("SIGNATURE_MISSING", null,
                    "Technician signature is missing", "توقيع الفني مفقود"));
        }
        List<ConflictRow> conflictRows = store.conflicts(job.id(), true);
        for (ConflictRow conflict : conflictRows) {
            blockers.add(new BlockerDto("SYNC_CONFLICT", conflict.itemCode(),
                    "The item has an unresolved sync conflict",
                    "يوجد تعارض مزامنة غير محلول لهذا العنصر"));
        }
        return new ReviewDto(job.id(), job.status(), blockers, List.of(), findings,
                conflictRows.stream().map(this::conflictDto).toList());
    }

    // ------------------------------------------------------------- signature

    @Transactional
    public SignatureDto signature(CurrentUser caller, String jobId, SignatureRequest request) {
        JobRow job = requireJob(caller, jobId);
        requireEditable(job);
        List<FieldIssue> issues = new ArrayList<>();
        if (request == null || isBlank(request.signerName())) {
            issues.add(issue("signerName", "REQUIRED", "error.technician.signatureInvalid"));
        }
        if (request == null || isBlank(request.deviceId())) {
            issues.add(issue("deviceId", "REQUIRED", "error.technician.signatureInvalid"));
        }
        if (request == null || isBlank(request.signatureBase64())) {
            issues.add(issue("signatureBase64", "REQUIRED", "error.technician.signatureInvalid"));
        }
        if (!issues.isEmpty()) {
            throw ApiException.validation("SIGNATURE_INVALID", "Signature is invalid", issues);
        }
        byte[] bytes;
        try {
            bytes = Base64.getDecoder().decode(request.signatureBase64());
        } catch (IllegalArgumentException exception) {
            throw ApiException.validation("SIGNATURE_INVALID", "Signature is invalid",
                    List.of(issue("signatureBase64", "BASE64_INVALID",
                            "error.technician.signatureInvalid")));
        }
        String method = isBlank(request.method()) ? "DRAWN"
                : request.method().trim().toUpperCase(Locale.ROOT);
        if (!SIGNATURE_METHODS.contains(method)) {
            throw ApiException.validation("SIGNATURE_INVALID", "Signature is invalid",
                    List.of(issue("method", "METHOD_INVALID",
                            "error.technician.signatureInvalid")));
        }
        String hash = sha256(bytes);
        String storageKey = "platform-signatures/" + jobId + "/" + hash + ".png";
        storage.put(storageKey, bytes, "image/png");
        LocalDateTime signedAt = LocalDateTime.now(ZoneOffset.UTC);
        store.upsertSignature(jobId, caller.userId().toString(), request.signerName().trim(),
                signedAt, request.deviceId().trim(), method, storageKey, hash);
        store.updateSignaturePresent(jobId);
        audit.record(caller, "JOB_SIGNED", "JOB", jobId, null,
                Map.of("signatureHash", hash, "method", method), null, null);
        return new SignatureDto(jobId, request.signerName().trim(), signedAt.toString(),
                request.deviceId().trim(), method, hash);
    }

    // -------------------------------------------------------------- complete

    @Transactional
    public CompleteDto complete(CurrentUser caller, String jobId, CompleteRequest request,
                                String idempotencyKey) {
        JobRow job = requireJob(caller, jobId);
        String endpoint = "POST /api/v1/technician/jobs/" + jobId + "/complete";
        Optional<CompleteDto> replay = replay(caller.userId().toString(), endpoint,
                idempotencyKey, CompleteDto.class);
        if (replay.isPresent()) {
            return replay.get();
        }
        if (!EDITABLE_STATUSES.contains(job.status())) {
            throw notEditable();
        }
        List<ItemRow> items = store.items(job.templateVersionId());
        Map<String, AssessmentRow> assessments = assessmentsByItem(job.id());
        List<BlockerDto> blockers = new ArrayList<>();
        for (ItemRow item : items) {
            AssessmentRow assessment = assessments.get(item.itemCode());
            if (assessment == null) {
                blockers.add(new BlockerDto("ITEM_NOT_ASSESSED", item.itemCode(),
                        "The item has not been assessed", "لم يتم تقييم العنصر"));
                continue;
            }
            blockers.addAll(evidenceBlockers(job, item, config(item), assessment));
        }
        if (!job.signaturePresent()) {
            blockers.add(new BlockerDto("SIGNATURE_MISSING", null,
                    "Technician signature is missing", "توقيع الفني مفقود"));
        }
        for (ConflictRow conflict : store.conflicts(job.id(), true)) {
            blockers.add(new BlockerDto("SYNC_CONFLICT", conflict.itemCode(),
                    "The item has an unresolved sync conflict",
                    "يوجد تعارض مزامنة غير محلول لهذا العنصر"));
        }
        ScoreResult score = computeScore(items, assessments);
        if (score.score() == null || score.grade() == null) {
            blockers.add(new BlockerDto("SCORE_NOT_COMPUTABLE", null,
                    "The inspection score is not computable", "لا يمكن احتساب نتيجة الفحص"));
        }
        if (!blockers.isEmpty()) {
            List<FieldIssue> issues = blockers.stream()
                    .map(value -> new FieldIssue(
                            value.itemCode() == null ? value.code() : value.itemCode(),
                            value.code(), "error.technician.completionBlocked",
                            value.messageEn(), value.messageAr(), null))
                    .toList();
            throw ApiException.validation("COMPLETION_BLOCKED", "Completion is blocked", issues);
        }

        LocalDateTime completedAt = LocalDateTime.now(ZoneOffset.UTC);
        store.deleteResults(jobId);
        for (ItemRow item : items) {
            AssessmentRow assessment = assessments.get(item.itemCode());
            ItemConfig config = config(item);
            int photos = store.evidenceCount(jobId, item.itemCode(), "PHOTO");
            int videos = store.evidenceCount(jobId, item.itemCode(), "VIDEO");
            int documents = store.evidenceCount(jobId, item.itemCode(), "DOCUMENT");
            store.insertResult(jobId, item.itemVersionId(), item.itemCode(), assessment.id(),
                    assessment.resultCode(), assessment.score(), assessment.suggestedScore(),
                    photos, videos, documents, job.signaturePresent(),
                    json(issueValues(assessment.id())));
            audit.record(caller, "JOB_RESULT_PROJECTED", "JOB", jobId, null,
                    Map.of("itemCode", item.itemCode(), "resultCode", assessment.resultCode()),
                    null, null);
        }
        Long clientRevision = request == null ? job.lastClientRevision() : request.clientRevision();
        store.completeJob(jobId, score.score(), score.grade(), score.capApplied(),
                score.capReason(), clientRevision);
        store.insertHistory(jobId, job.status(), "PENDING_REVIEW", caller.userId().toString(),
                "Inspection completed");
        audit.record(caller, "JOB_COMPLETED", "JOB", jobId,
                Map.of("status", job.status()),
                Map.of("status", "PENDING_REVIEW", "score", score.score(),
                        "grade", score.grade()), null, null);
        outbox.publish("JOB", jobId, "JOB_COMPLETED", Map.of(
                "jobId", jobId, "workshopId", job.workshopId(), "score", score.score(),
                "grade", score.grade()));
        store.insertNotification(job.workshopId(), job.createdBy(), "JOB_COMPLETED",
                json(Map.of("jobId", jobId, "reference", job.reference())));
        CompleteDto dto = new CompleteDto(jobId, "PENDING_REVIEW", completedAt.toString(),
                score.score(), score.grade(), score.capApplied(), List.of());
        idempotency.store(caller.userId().toString(), endpoint, idempotencyKey, 200, dto);
        return dto;
    }

    // -------------------------------------------------------------- evidence

    @Transactional
    public EvidenceDto initEvidence(CurrentUser caller, String jobId, String itemCode,
                                    EvidenceInitRequest request) {
        JobRow job = requireJob(caller, jobId);
        requireEditable(job);
        ItemRow item = requireItem(job, itemCode);
        String type = request == null || isBlank(request.type()) ? ""
                : request.type().trim().toUpperCase(Locale.ROOT);
        List<FieldIssue> issues = new ArrayList<>();
        if (!Set.of("PHOTO", "VIDEO", "DOCUMENT").contains(type)) {
            issues.add(issue("type", "EVIDENCE_TYPE_INVALID", "error.technician.evidenceInvalid"));
        }
        String mime = request == null || isBlank(request.mime()) ? ""
                : request.mime().trim().toLowerCase(Locale.ROOT);
        Set<String> allowedMimes = switch (type) {
            case "PHOTO" -> PHOTO_MIMES;
            case "VIDEO" -> VIDEO_MIMES;
            case "DOCUMENT" -> DOCUMENT_MIMES;
            default -> Set.of();
        };
        if (!allowedMimes.contains(mime)) {
            issues.add(issue("mime", "MIME_NOT_ALLOWED", "error.technician.evidenceInvalid"));
        }
        long bytes = request == null || request.bytes() == null ? -1 : request.bytes();
        long maxBytes = switch (type) {
            case "VIDEO" -> MAX_VIDEO_BYTES;
            case "DOCUMENT" -> MAX_DOCUMENT_BYTES;
            default -> MAX_PHOTO_BYTES;
        };
        if (bytes <= 0 || bytes > maxBytes) {
            issues.add(issue("bytes", "BYTES_INVALID", "error.technician.evidenceInvalid"));
        }
        String sha = request == null || isBlank(request.sha256()) ? ""
                : request.sha256().trim().toLowerCase(Locale.ROOT);
        if (!sha.matches("[0-9a-f]{64}")) {
            issues.add(issue("sha256", "SHA_INVALID", "error.technician.evidenceInvalid"));
        }
        String source = request == null || isBlank(request.captureSource()) ? ""
                : request.captureSource().trim().toUpperCase(Locale.ROOT);
        if ("PHOTO".equals(type) || "VIDEO".equals(type)) {
            if (!"CAMERA".equals(source)) {
                issues.add(issue("captureSource", "CAMERA_REQUIRED",
                        "error.technician.cameraRequired"));
            }
        } else if (!Set.of("CAMERA", "FILE", "SCANNER", "IMPORT").contains(source)) {
            issues.add(issue("captureSource", "SOURCE_INVALID",
                    "error.technician.evidenceInvalid"));
        }
        LocalDateTime capturedAt = parseDateTime(request == null ? null : request.capturedAt());
        if (capturedAt == null) {
            issues.add(issue("capturedAt", "CAPTURED_AT_REQUIRED",
                    "error.technician.evidenceInvalid"));
        } else if (job.createdAt() != null
                && (capturedAt.isBefore(job.createdAt().minusHours(24))
                || capturedAt.isAfter(LocalDateTime.now(ZoneOffset.UTC).plusMinutes(10)))) {
            issues.add(issue("capturedAt", "CAPTURED_AT_OUT_OF_WINDOW",
                    "error.technician.capturedAtWindow"));
        }
        if ("PHOTO".equals(type)) {
            Integer width = request.width();
            Integer height = request.height();
            if (width == null || height == null || width < 640 || height < 480) {
                issues.add(issue("width", "RESOLUTION_TOO_LOW",
                        "error.technician.evidenceInvalid"));
            }
        }
        if ("VIDEO".equals(type)) {
            Long duration = request.durationMs();
            if (duration == null || duration < 15_000 || duration > 30_000) {
                issues.add(issue("durationMs", "DURATION_INVALID",
                        "error.technician.videoDuration"));
            }
        }
        if (!issues.isEmpty()) {
            throw ApiException.validation("EVIDENCE_INVALID", "Evidence is invalid", issues);
        }
        String existingSha = store.evidence(jobId, itemCode).stream()
                .map(EvidenceRow::sha256).filter(sha::equals).findFirst().orElse(null);
        if (existingSha != null || store.duplicateSha(sha)) {
            throw new ApiException(HttpStatus.CONFLICT, "DUPLICATE_EVIDENCE",
                    "error.technician.evidenceDuplicate",
                    "The evidence file was already uploaded");
        }
        String id = UuidV7.generate().toString();
        String storageKey = "platform-evidence/" + jobId + "/" + id;
        String assessmentId = store.assessment(jobId, itemCode)
                .map(AssessmentRow::id).orElse(null);
        store.insertEvidence(id, jobId, item.itemVersionId(), itemCode, assessmentId, type,
                storageKey, mime, bytes, sha, capturedAt, source,
                trimToNull(request.deviceId()), request.width(), request.height(),
                request.durationMs(), trimToNull(request.captionEn()),
                trimToNull(request.captionAr()), caller.userId().toString());
        EvidenceRow row = store.evidence(jobId, itemCode, id).orElseThrow();
        return evidenceDto(row);
    }

    @Transactional
    public EvidenceDto uploadEvidence(CurrentUser caller, String jobId, String itemCode,
                                      String evidenceId, byte[] content) {
        requireJob(caller, jobId);
        EvidenceRow evidence = store.evidence(jobId, itemCode, evidenceId)
                .orElseThrow(() -> evidenceNotFound());
        if (!"PENDING".equals(evidence.status())) {
            throw new ApiException(HttpStatus.CONFLICT, "EVIDENCE_NOT_UPLOADABLE",
                    "error.technician.evidenceInvalid",
                    "Evidence is not awaiting an upload");
        }
        byte[] bytes = content == null ? new byte[0] : content;
        if (bytes.length != evidence.bytes()) {
            throw ApiException.validation("EVIDENCE_SIZE_MISMATCH", "Evidence size mismatch",
                    List.of(issue("content", "SIZE_MISMATCH",
                            "error.technician.evidenceInvalid")));
        }
        if (!sha256(bytes).equals(evidence.sha256())) {
            throw ApiException.validation("EVIDENCE_HASH_MISMATCH", "Evidence hash mismatch",
                    List.of(issue("content", "HASH_MISMATCH",
                            "error.technician.evidenceInvalid")));
        }
        storage.put(evidence.storageKey(), bytes, evidence.mime());
        store.markEvidenceUploaded(evidenceId);
        return evidenceDto(store.evidence(jobId, itemCode, evidenceId).orElseThrow());
    }

    @Transactional
    public EvidenceDto completeEvidence(CurrentUser caller, String jobId, String itemCode,
                                        String evidenceId, EvidenceCompleteRequest request) {
        requireJob(caller, jobId);
        EvidenceRow evidence = store.evidence(jobId, itemCode, evidenceId)
                .orElseThrow(() -> evidenceNotFound());
        if (!Set.of("UPLOADED", "VERIFIED").contains(evidence.status())) {
            throw new ApiException(HttpStatus.CONFLICT, "EVIDENCE_NOT_COMPLETABLE",
                    "error.technician.evidenceInvalid",
                    "Evidence must be uploaded before it can be completed");
        }
        String captionEn = request == null || isBlank(request.captionEn())
                ? evidence.captionEn() : request.captionEn().trim();
        String captionAr = request == null || isBlank(request.captionAr())
                ? evidence.captionAr() : request.captionAr().trim();
        String posterKey = evidence.posterKey();
        if (request != null && !isBlank(request.posterBase64())) {
            byte[] poster;
            try {
                poster = Base64.getDecoder().decode(request.posterBase64());
            } catch (IllegalArgumentException exception) {
                throw ApiException.validation("EVIDENCE_INVALID", "Evidence is invalid",
                        List.of(issue("posterBase64", "BASE64_INVALID",
                                "error.technician.evidenceInvalid")));
            }
            posterKey = "platform-evidence/" + jobId + "/" + evidenceId + "/poster";
            storage.put(posterKey, poster, "image/png");
            store.insertDerivative(evidenceId, "POSTER", posterKey, "image/png",
                    poster.length, sha256(poster));
        }
        store.completeEvidence(evidenceId, captionEn, captionAr, posterKey);
        return evidenceDto(store.evidence(jobId, itemCode, evidenceId).orElseThrow());
    }

    @Transactional(readOnly = true)
    public List<EvidenceDto> listEvidence(CurrentUser caller, String jobId, String itemCode) {
        requireJob(caller, jobId);
        return store.evidence(jobId, itemCode).stream().map(this::evidenceDto).toList();
    }

    @Transactional(readOnly = true)
    public EvidenceContent evidenceContent(CurrentUser caller, String jobId, String itemCode,
                                           String evidenceId) {
        requireJob(caller, jobId);
        EvidenceRow evidence = store.evidence(jobId, itemCode, evidenceId)
                .orElseThrow(() -> evidenceNotFound());
        if (evidence.storageKey() == null
                || !Set.of("UPLOADED", "VERIFIED").contains(evidence.status())) {
            throw evidenceNotFound();
        }
        return new EvidenceContent(storage.get(evidence.storageKey()), evidence.mime());
    }

    @Transactional
    public void deleteEvidence(CurrentUser caller, String jobId, String itemCode,
                               String evidenceId) {
        requireJob(caller, jobId);
        EvidenceRow evidence = store.evidence(jobId, itemCode, evidenceId)
                .orElseThrow(() -> evidenceNotFound());
        store.softDeleteEvidence(evidence.id(), caller.userId().toString());
        audit.record(caller, "JOB_EVIDENCE_DELETED", "JOB", jobId,
                Map.of("evidenceId", evidenceId, "type", evidence.type()), null, null, null);
    }

    // ------------------------------------------------------------- internals

    public record EvidenceContent(byte[] bytes, String mime) {
    }

    private record ItemConfig(ItemRow item, List<ScoreBandRow> scoreBands,
                              List<EvidenceRuleRow> evidenceRules,
                              List<IssueFieldDef> issueFields,
                              List<MeasureBandRow> measurementBands) {
    }

    private record IssueFieldDef(IssueFieldRow row, List<OptionRow> options,
                                 List<String> unitCodes) {
    }

    private record MeasurementWithBand(String fieldCode, String valueIndex,
                                       BigDecimal numericValue, String unitCode, String bandId,
                                       String resultCode, Integer score) {
    }

    private record Validation(String resultCode, String suggestedResultCode, Integer suggestedScore,
                              Integer score, List<MeasurementWithBand> measurements) {
    }

    private record ScoreResult(Integer score, String grade, boolean capApplied, String capReason) {
    }

    private record Requirements(int photos, int videos, int notes, String requiredType) {
    }

    private String requireWorkshop(CurrentUser caller) {
        if (caller == null || !caller.isTechnician() || caller.workshopId() == null) {
            throw ApiException.forbidden();
        }
        return caller.workshopId().toString();
    }

    private JobRow requireJob(CurrentUser caller, String jobId) {
        String workshopId = requireWorkshop(caller);
        return store.findJob(workshopId, caller.userId().toString(), jobId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "JOB_NOT_FOUND",
                        "error.job.notFound", "Job not found"));
    }

    private ItemRow requireItem(JobRow job, String itemCode) {
        return store.itemByCode(job.templateVersionId(), itemCode)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "ITEM_NOT_FOUND",
                        "error.technician.itemNotFound", "Item not found"));
    }

    private void requireEditable(JobRow job) {
        if (!EDITABLE_STATUSES.contains(job.status())) {
            throw notEditable();
        }
    }

    private static ApiException notEditable() {
        return new ApiException(HttpStatus.CONFLICT, "JOB_NOT_EDITABLE",
                "error.job.statusInvalid",
                "The job cannot be changed in its current state");
    }

    private static ApiException evidenceNotFound() {
        return new ApiException(HttpStatus.NOT_FOUND, "EVIDENCE_NOT_FOUND",
                "error.technician.evidenceNotFound", "Evidence not found");
    }

    private Map<String, AssessmentRow> assessmentsByItem(String jobId) {
        Map<String, AssessmentRow> result = new LinkedHashMap<>();
        for (AssessmentRow row : store.assessments(jobId)) {
            result.put(row.itemCode(), row);
        }
        return result;
    }

    private ItemConfig config(ItemRow item) {
        List<IssueFieldDef> fields = new ArrayList<>();
        for (IssueFieldRow field : store.issueFields(item.itemVersionId())) {
            fields.add(new IssueFieldDef(field,
                    store.options(field.id(), field.optionSetId()),
                    store.unitCodes(field.unitSetId())));
        }
        return new ItemConfig(item, store.scoreBands(item.itemVersionId()),
                store.evidenceRules(item.itemVersionId()), fields,
                store.measurementBands(item.itemVersionId()));
    }

    private List<CategoryDto> categories(List<ItemRow> items) {
        Map<String, CategoryDto> categories = new LinkedHashMap<>();
        for (ItemRow item : items) {
            categories.computeIfAbsent(item.categoryCode(), code -> new CategoryDto(
                    code, item.categoryNameEn(), item.categoryNameAr(), iconCode(code),
                    item.categorySortOrder()));
        }
        return categories.values().stream()
                .sorted(Comparator.comparingInt(CategoryDto::sortOrder)
                        .thenComparing(CategoryDto::code))
                .toList();
    }

    private static String iconCode(String categoryCode) {
        if (categoryCode == null) {
            return null;
        }
        return categoryCode.trim().toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9]+", "-")
                .replaceAll("^-+|-+$", "");
    }

    private ChecklistItemDto checklistItem(ItemRow item, AssessmentRow assessment) {
        ItemConfig config = config(item);
        List<String> resultOptions = resultOptions(item.resultOptionsJson());
        List<ScoreBandDto> scoreBands = config.scoreBands().stream()
                .map(band -> new ScoreBandDto(band.resultCode(), band.minScore(),
                        band.maxScore(), band.defaultScore(), band.criteriaEn(),
                        band.criteriaAr()))
                .toList();
        List<EvidenceRuleDto> evidenceRules = config.evidenceRules().stream()
                .map(rule -> new EvidenceRuleDto(rule.resultCode(), rule.minPhotos(),
                        rule.minVideos(), rule.minNotesChars(), rule.requiredEvidenceType()))
                .toList();
        List<IssueFieldDto> issueFields = config.issueFields().stream()
                .map(this::issueFieldDto).toList();
        List<MeasurementBandDto> bands = config.measurementBands().stream()
                .map(band -> new MeasurementBandDto(band.fieldCode(), band.unitCode(),
                        band.direction(), band.minValue(), band.maxValue(), band.resultCode(),
                        band.defaultScore(), band.labelEn(), band.labelAr()))
                .toList();
        List<String> multiPointIndexes = multiPointIndexes(item, config, assessment);
        return new ChecklistItemDto(item.itemCode(), item.itemVersionId(), item.categoryCode(),
                item.itemSortOrder(), item.labelEn(), item.labelAr(), item.instructionEn(),
                item.instructionAr(), item.standardSpecEn(), item.standardSpecAr(),
                item.measurementUnit(), item.sensorTool(), item.safetyCritical(),
                item.multiPoint(), multiPointIndexes, item.allowFreeTextNote(),
                item.noteRequirement(), resultOptions, scoreBands, evidenceRules, issueFields,
                bands, assessment == null ? null : assessmentDtoForItem(item, assessment, config));
    }

    private IssueFieldDto issueFieldDto(IssueFieldDef definition) {
        IssueFieldRow row = definition.row();
        List<OptionDto> options = definition.options().stream()
                .map(option -> new OptionDto(option.code(), option.labelEn(), option.labelAr(),
                        option.sortOrder()))
                .toList();
        return new IssueFieldDto(row.fieldCode(), row.labelEn(), row.labelAr(), row.inputType(),
                row.optionSetCode(), options, options.stream().map(OptionDto::code).toList(),
                row.required(), stringList(row.requiredForStatusesJson()), row.minValue(),
                row.maxValue(), row.decimalPlaces(), row.unitSetCode(), row.dependsOnFieldCode(),
                row.dependsOnValueCode(), row.allowMultiple(), row.allowFreeText(), row.sortOrder());
    }

    private List<String> multiPointIndexes(ItemRow item, ItemConfig config,
                                           AssessmentRow assessment) {
        if (!item.multiPoint()) {
            return List.of();
        }
        LinkedHashSet<String> indexes = new LinkedHashSet<>(List.of("FL", "FR", "RL", "RR"));
        if (assessment != null) {
            for (MeasurementRow measurement : store.measurements(assessment.id())) {
                if (measurement.valueIndex() != null && !measurement.valueIndex().isBlank()) {
                    indexes.add(measurement.valueIndex());
                }
            }
        }
        return new ArrayList<>(indexes);
    }

    private AssessmentDto assessmentDtoForItem(ItemRow item, AssessmentRow assessment,
                                               ItemConfig config) {
        return new AssessmentDto(assessment.id(), assessment.itemCode(),
                assessment.itemVersionId(), assessment.resultCode(), assessment.severityCode(),
                assessment.score(), assessment.suggestedResultCode(), assessment.suggestedScore(),
                assessment.suggestedResultCode(), assessment.state(), assessment.clientRevision(),
                assessment.serverRevision(), assessment.notesEn(), assessment.notesAr(),
                assessment.reasonCode(), assessment.version(),
                issueValues(assessment.id()),
                store.measurements(assessment.id()).stream().map(this::measurementDto).toList(),
                store.evidence(assessment.jobId(), item.itemCode()).stream()
                        .map(this::evidenceDto).toList());
    }

    private AssessmentDto assessmentDto(JobRow job, AssessmentRow assessment, ItemConfig config) {
        return assessmentDtoForItem(config.item(), assessment, config);
    }

    private List<IssueValueDto> issueValues(String assessmentId) {
        return store.issueValues(assessmentId).stream().map(this::issueValueDto).toList();
    }

    private IssueValueDto issueValueDto(IssueValueRow row) {
        return new IssueValueDto(row.fieldCode(), row.valueIndex(), row.optionValueCode(),
                row.numericValue(), row.unitCode(), row.textValue());
    }

    private MeasurementDto measurementDto(MeasurementRow row) {
        return new MeasurementDto(row.fieldCode(), row.valueIndex(), row.numericValue(),
                row.unitCode());
    }

    private EvidenceDto evidenceDto(EvidenceRow row) {
        return new EvidenceDto(row.id(), row.jobId(), row.itemCode(), row.type(), row.status(),
                row.mime(), row.bytes(), row.sha256(),
                row.capturedAt() == null ? null : row.capturedAt().toString(),
                row.captureSource(), row.deviceId(), row.width(), row.height(), row.durationMs(),
                row.captionEn(), row.captionAr(), row.posterKey() != null, row.qualityStatus(),
                "/api/v1/technician/jobs/" + row.jobId() + "/items/" + row.itemCode()
                        + "/evidence/" + row.id() + "/content",
                row.createdAt() == null ? null : row.createdAt().toString());
    }

    private ConflictDto conflictDto(ConflictRow row) {
        return new ConflictDto(row.itemCode(), row.clientRevision(), row.serverRevision(),
                row.serverPayloadJson(), row.clientPayloadJson());
    }

    private JobSummaryDto jobSummary(JobRow job) {
        TemplateRow template = store.template(job.templateVersionId()).orElse(null);
        List<ItemRow> items = store.items(job.templateVersionId());
        Map<String, AssessmentRow> assessments = assessmentsByItem(job.id());
        int completed = (int) assessments.values().stream()
                .filter(value -> value.resultCode() != null).count();
        return new JobSummaryDto(job.id(), job.reference(), job.status(), job.reviewStatus(),
                job.templateVersionId(),
                template == null ? null : template.nameEn(),
                template == null ? null : template.nameAr(),
                template == null ? null : template.versionNo(),
                job.assignedTechnicianId(), job.customerName(), job.customerPhone(),
                job.customerEmail(), job.vehicleVin(), job.vehicleMake(), job.vehicleModel(),
                job.vehicleYear(), job.vehiclePlate(), job.odometerValue(), job.odometerUnit(),
                job.transmission(), job.fuelType(), job.vehicleType(), job.preferredLanguage(),
                str(job.scheduledAt()), str(job.startedAt()), job.assessmentState(), completed,
                items.size(), job.version());
    }

    private Validation validate(JobRow job, ItemRow item, ItemConfig config,
                                AssessmentRequest request) {
        if (request == null) {
            throw ApiException.validation("ITEM_VALIDATION_FAILED", "Item validation failed",
                    List.of(issue("request", "REQUEST_REQUIRED", "error.technician.validation")));
        }
        List<FieldIssue> issues = new ArrayList<>();
        List<String> allowedResults = resultOptions(item.resultOptionsJson());
        String result = trimToNull(request.resultCode());
        if (result == null) {
            issues.add(issue("resultCode", "RESULT_REQUIRED", "error.technician.resultRequired"));
        } else if (!allowedResults.contains(result)) {
            issues.add(issue("resultCode", "RESULT_NOT_ALLOWED",
                    "error.technician.resultNotAllowed"));
        }

        List<MeasurementWithBand> measurements = new ArrayList<>();
        String suggestedResult = result;
        Integer suggestedScore = null;
        Integer score = request.score();

        if (!config.measurementBands().isEmpty()) {
            List<MeasurementDto> submitted = safeList(request.measurements());
            int required = item.multiPoint() ? 2 : 1;
            if (submitted.size() < required) {
                issues.add(issue("measurements", "MEASUREMENT_REQUIRED",
                        "error.technician.measurementRequired"));
            }
            String worstResult = null;
            Integer worstScore = null;
            for (MeasurementDto measurement : submitted) {
                if (measurement == null || isBlank(measurement.fieldCode())
                        || measurement.numericValue() == null) {
                    issues.add(issue("measurements", "MEASUREMENT_INVALID",
                            "error.technician.measurementRequired"));
                    continue;
                }
                MeasureBandRow band = bandFor(config.measurementBands(), measurement);
                if (band == null) {
                    issues.add(issue("measurements", "MEASUREMENT_BAND_MISMATCH",
                            "error.technician.measurementBandMismatch"));
                    continue;
                }
                measurements.add(new MeasurementWithBand(measurement.fieldCode(),
                        measurement.valueIndex(), measurement.numericValue(),
                        measurement.unitCode() == null ? band.unitCode() : measurement.unitCode(),
                        band.id(), band.resultCode(), band.defaultScore()));
                if (worstResult == null
                        || rank(band.resultCode()) > rank(worstResult)) {
                    worstResult = band.resultCode();
                }
                if (worstScore == null || band.defaultScore() < worstScore) {
                    worstScore = band.defaultScore();
                }
            }
            if (worstResult != null) {
                suggestedResult = worstResult;
                suggestedScore = worstScore;
                if (result != null && !result.equals(worstResult)) {
                    issues.add(issue("resultCode", "MEASUREMENT_BAND_MISMATCH",
                            "error.technician.measurementBandMismatch"));
                }
            }
        }

        ScoreBandRow scoreBand = scoreBand(config.scoreBands(), result);
        if (scoreBand != null) {
            suggestedScore = scoreBand.defaultScore();
            if (score != null && (score < scoreBand.minScore() || score > scoreBand.maxScore())) {
                issues.add(issue("score", "SCORE_OUT_OF_BAND",
                        "error.technician.scoreOutOfBand"));
            }
            if (score == null) {
                score = scoreBand.defaultScore();
            }
        } else if (suggestedScore != null && score == null) {
            score = suggestedScore;
        } else if (score != null && (score < 0 || score > 100)) {
            issues.add(issue("score", "SCORE_OUT_OF_BAND", "error.technician.scoreOutOfBand"));
        }

        validateIssueValues(item, config, request, result, issues);

        if ((!isBlank(request.notesEn()) || !isBlank(request.notesAr()))
                && !item.allowFreeTextNote()) {
            issues.add(issue("notes", "NOTES_NOT_ALLOWED", "error.technician.notesNotAllowed"));
        }

        Requirements requirements = requirements(config, result);
        int photos = store.evidenceCount(job.id(), item.itemCode(), "PHOTO");
        int videos = store.evidenceCount(job.id(), item.itemCode(), "VIDEO");
        int documents = store.evidenceCount(job.id(), item.itemCode(), "DOCUMENT");
        if (photos < requirements.photos() || videos < requirements.videos()) {
            issues.add(issue("evidence", "EVIDENCE_RULE_NOT_MET",
                    "error.technician.evidenceRuleNotMet"));
        }
        if (requirements.requiredType() != null
                && countByType(requirements.requiredType(), photos, videos, documents) == 0) {
            issues.add(issue("evidence", "EVIDENCE_TYPE_REQUIRED",
                    "error.technician.evidenceRuleNotMet"));
        }
        int noteLength = noteLength(request.notesEn()) + noteLength(request.notesAr());
        if (requirements.notes() > 0 && noteLength < requirements.notes()) {
            issues.add(issue("notes", "NOTES_MIN_LENGTH", "error.technician.notesMinLength"));
        }

        if (!issues.isEmpty()) {
            boolean evidenceOnly = issues.stream().allMatch(value ->
                    "EVIDENCE_RULE_NOT_MET".equals(value.code())
                            || "EVIDENCE_TYPE_REQUIRED".equals(value.code())
                            || "NOTES_MIN_LENGTH".equals(value.code()));
            String code = evidenceOnly ? "EVIDENCE_RULE_NOT_MET" : "ITEM_VALIDATION_FAILED";
            throw ApiException.validation(code, "Item validation failed", issues);
        }
        return new Validation(result, suggestedResult, suggestedScore, score, measurements);
    }

    private void validateIssueValues(ItemRow item, ItemConfig config, AssessmentRequest request,
                                     String result, List<FieldIssue> issues) {
        Map<String, IssueFieldDef> fields = new LinkedHashMap<>();
        for (IssueFieldDef definition : config.issueFields()) {
            fields.put(definition.row().fieldCode(), definition);
        }
        Map<String, List<IssueValueDto>> provided = new LinkedHashMap<>();
        for (IssueValueDto value : safeList(request.issueValues())) {
            if (value == null || isBlank(value.fieldCode())) {
                issues.add(issue("issueValues", "FIELD_CODE_REQUIRED",
                        "error.technician.issueFieldUnknown"));
                continue;
            }
            if (!fields.containsKey(value.fieldCode())) {
                issues.add(issue(value.fieldCode(), "ISSUE_FIELD_UNKNOWN",
                        "error.technician.issueFieldUnknown"));
                continue;
            }
            provided.computeIfAbsent(value.fieldCode(), code -> new ArrayList<>()).add(value);
        }
        for (IssueFieldDef definition : config.issueFields()) {
            IssueFieldRow field = definition.row();
            List<IssueValueDto> values = provided.getOrDefault(field.fieldCode(), List.of());
            boolean required = field.required()
                    || stringList(field.requiredForStatusesJson()).contains(result);
            if (required && values.isEmpty()) {
                issues.add(issue(field.fieldCode(), "REQUIRED", "error.technician.requiredField"));
                continue;
            }
            if (values.isEmpty()) {
                continue;
            }
            if (!field.allowMultiple() && values.size() > 1) {
                issues.add(issue(field.fieldCode(), "MULTIPLE_NOT_ALLOWED",
                        "error.technician.validation"));
            }
            if (field.dependsOnFieldCode() != null && !dependencySatisfied(field, provided)) {
                issues.add(issue(field.fieldCode(), "DEPENDENCY_UNSATISFIED",
                        "error.technician.dependencyUnsatisfied"));
            }
            for (IssueValueDto value : values) {
                validateIssueValue(field, definition, value, issues);
            }
        }
    }

    private void validateIssueValue(IssueFieldRow field, IssueFieldDef definition,
                                    IssueValueDto value, List<FieldIssue> issues) {
        String inputType = field.inputType();
        switch (inputType) {
            case "SELECT", "MULTI_SELECT", "BOOLEAN" -> {
                String option = value.optionValueCode();
                if (isBlank(option)) {
                    issues.add(issue(field.fieldCode(), "OPTION_REQUIRED",
                            "error.technician.requiredField"));
                    return;
                }
                boolean allowed = "BOOLEAN".equals(inputType)
                        ? Set.of("YES", "NO").contains(option)
                        : definition.options().stream()
                                .anyMatch(candidate -> candidate.code().equals(option));
                if (!allowed) {
                    issues.add(issue(field.fieldCode(), "OPTION_NOT_ALLOWED",
                            "error.technician.optionNotAllowed"));
                }
            }
            case "NUMBER" -> {
                if (value.numericValue() == null) {
                    issues.add(issue(field.fieldCode(), "NUMBER_REQUIRED",
                            "error.technician.requiredField"));
                    return;
                }
                BigDecimal number = value.numericValue();
                if (field.minValue() != null && number.compareTo(field.minValue()) < 0) {
                    issues.add(issue(field.fieldCode(), "NUMBER_MIN",
                            "error.technician.numberRange"));
                }
                if (field.maxValue() != null && number.compareTo(field.maxValue()) > 0) {
                    issues.add(issue(field.fieldCode(), "NUMBER_MAX",
                            "error.technician.numberRange"));
                }
                if (number.scale() > field.decimalPlaces()) {
                    issues.add(issue(field.fieldCode(), "DECIMAL_PLACES",
                            "error.technician.decimalPlaces"));
                }
                if (!definition.unitCodes().isEmpty() && !isBlank(value.unitCode())
                        && !definition.unitCodes().contains(value.unitCode())) {
                    issues.add(issue(field.fieldCode(), "UNIT_INVALID",
                            "error.technician.unitInvalid"));
                }
            }
            case "TEXT" -> {
                if (!field.allowFreeText()) {
                    issues.add(issue(field.fieldCode(), "FREE_TEXT_NOT_ALLOWED",
                            "error.technician.freeTextNotAllowed"));
                } else if (isBlank(value.textValue())) {
                    issues.add(issue(field.fieldCode(), "TEXT_REQUIRED",
                            "error.technician.requiredField"));
                }
            }
            default -> issues.add(issue(field.fieldCode(), "INPUT_TYPE_INVALID",
                    "error.technician.validation"));
        }
        if (!isBlank(value.textValue()) && !field.allowFreeText()) {
            issues.add(issue(field.fieldCode(), "FREE_TEXT_NOT_ALLOWED",
                    "error.technician.freeTextNotAllowed"));
        }
    }

    private boolean dependencySatisfied(IssueFieldRow field,
                                        Map<String, List<IssueValueDto>> provided) {
        List<IssueValueDto> dependencies = provided.getOrDefault(
                field.dependsOnFieldCode(), List.of());
        return dependencies.stream().anyMatch(value -> field.dependsOnValueCode() == null
                || field.dependsOnValueCode().equals(value.optionValueCode()));
    }

    private List<BlockerDto> evidenceBlockers(JobRow job, ItemRow item, ItemConfig config,
                                              AssessmentRow assessment) {
        List<BlockerDto> blockers = new ArrayList<>();
        Requirements requirements = requirements(config, assessment.resultCode());
        int photos = store.evidenceCount(job.id(), item.itemCode(), "PHOTO");
        int videos = store.evidenceCount(job.id(), item.itemCode(), "VIDEO");
        int documents = store.evidenceCount(job.id(), item.itemCode(), "DOCUMENT");
        if (photos < requirements.photos() || videos < requirements.videos()) {
            blockers.add(new BlockerDto("EVIDENCE_RULE_NOT_MET", item.itemCode(),
                    "Photo/video evidence is incomplete",
                    "أدلة الصور والفيديو غير مكتملة"));
        }
        if (requirements.requiredType() != null
                && countByType(requirements.requiredType(), photos, videos, documents) == 0) {
            blockers.add(new BlockerDto("EVIDENCE_TYPE_REQUIRED", item.itemCode(),
                    "The required document evidence is missing",
                    "دليل المستند المطلوب مفقود"));
        }
        int noteLength = noteLength(assessment.notesEn()) + noteLength(assessment.notesAr());
        if (requirements.notes() > 0 && noteLength < requirements.notes()) {
            blockers.add(new BlockerDto("NOTES_MIN_LENGTH", item.itemCode(),
                    "The note is shorter than the configured minimum",
                    "الملاحظة أقصر من الحد الأدنى المهيأ"));
        }
        return blockers;
    }

    private Requirements requirements(ItemConfig config, String result) {
        int photos = "DEFECT_FOUND".equals(result) ? 2 : 1;
        int videos = 1;
        int notes = 0;
        String requiredType = null;
        for (EvidenceRuleRow rule : config.evidenceRules()) {
            if (rule.resultCode().equals(result)) {
                photos = Math.max(photos, rule.minPhotos());
                videos = Math.max(videos, rule.minVideos());
                notes = rule.minNotesChars();
                requiredType = rule.requiredEvidenceType();
            }
        }
        return new Requirements(photos, videos, notes, requiredType);
    }

    private static int countByType(String type, int photos, int videos, int documents) {
        return switch (type) {
            case "PHOTO" -> photos;
            case "VIDEO" -> videos;
            case "DOCUMENT" -> documents;
            default -> 0;
        };
    }

    private static MeasureBandRow bandFor(List<MeasureBandRow> bands, MeasurementDto measurement) {
        for (MeasureBandRow band : bands) {
            if (!band.fieldCode().equals(measurement.fieldCode())) {
                continue;
            }
            BigDecimal value = measurement.numericValue();
            if (value.compareTo(band.minValue()) >= 0 && value.compareTo(band.maxValue()) <= 0) {
                return band;
            }
        }
        return null;
    }

    private static ScoreBandRow scoreBand(List<ScoreBandRow> bands, String result) {
        if (result == null) {
            return null;
        }
        return bands.stream().filter(band -> band.resultCode().equals(result))
                .findFirst().orElse(null);
    }

    private ScoreResult computeScore(List<ItemRow> items, Map<String, AssessmentRow> assessments) {
        if (items.isEmpty()) {
            return new ScoreResult(null, null, false, null);
        }
        Map<String, List<Integer>> categoryScores = new LinkedHashMap<>();
        Map<String, BigDecimal> categoryWeights = new LinkedHashMap<>();
        List<String> safetyFailures = new ArrayList<>();
        for (ItemRow item : items) {
            AssessmentRow assessment = assessments.get(item.itemCode());
            if (assessment == null || assessment.score() == null) {
                return new ScoreResult(null, null, false, null);
            }
            categoryScores.computeIfAbsent(item.categoryId(), key -> new ArrayList<>())
                    .add(assessment.score());
            categoryWeights.putIfAbsent(item.categoryId(), store.categoryWeight(item.categoryId()));
            if (item.safetyCritical() && "DEFECT_FOUND".equals(assessment.resultCode())) {
                safetyFailures.add(item.itemCode());
            }
        }
        BigDecimal weightTotal = categoryWeights.values().stream()
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        double overall = 0;
        for (Map.Entry<String, List<Integer>> entry : categoryScores.entrySet()) {
            double average = entry.getValue().stream().mapToInt(Integer::intValue).average()
                    .orElse(0);
            double weight = weightTotal.signum() == 0
                    ? 1.0 / categoryScores.size()
                    : categoryWeights.get(entry.getKey()).doubleValue()
                            / weightTotal.doubleValue();
            overall += average * weight;
        }
        int score = (int) Math.round(overall);
        String grade = gradeFor(score);
        boolean capApplied = false;
        String capReason = null;
        if (!safetyFailures.isEmpty()) {
            capApplied = true;
            capReason = "Safety-critical item failed: " + String.join(", ", safetyFailures);
            Optional<ScoringRuleRow> rule = store.activeScoringRule();
            if (rule.isPresent() && rule.get().hardFailCapEnabled()) {
                String capGrade = rule.get().hardFailCapGrade();
                if (capGrade != null && grade != null
                        && gradeRank(grade) < gradeRank(capGrade)) {
                    grade = capGrade;
                }
            }
        }
        return new ScoreResult(score, grade, capApplied, capReason);
    }

    private String gradeFor(int score) {
        Optional<ScoringRuleRow> rule = store.activeScoringRule();
        if (rule.isEmpty()) {
            return null;
        }
        return store.gradeBoundaries(rule.get().id()).stream()
                .filter(boundary -> score >= boundary.minScore() && score <= boundary.maxScore())
                .min(Comparator.comparingInt(GradeBoundaryRow::sortOrder))
                .map(GradeBoundaryRow::gradeCode)
                .orElse(null);
    }

    private static int gradeRank(String grade) {
        int index = GRADE_ORDER.indexOf(grade);
        return index < 0 ? GRADE_ORDER.size() : index;
    }

    private static int rank(String result) {
        return RESULT_RANK.getOrDefault(result, 0);
    }

    private List<String> resultOptions(String json) {
        List<String> values = stringList(json);
        return values.isEmpty() ? new ArrayList<>(CANONICAL_RESULTS) : values;
    }

    private List<String> stringList(String json) {
        if (isBlank(json)) {
            return List.of();
        }
        try {
            JsonNode node = objectMapper.readTree(json);
            if (!node.isArray()) {
                return List.of();
            }
            List<String> values = new ArrayList<>();
            for (JsonNode element : node) {
                if (element.isTextual() && !element.asText().isBlank()) {
                    values.add(element.asText());
                }
            }
            return values;
        } catch (JsonProcessingException exception) {
            return List.of();
        }
    }

    private String snapshotJson(String templateVersionId, List<CategoryDto> categories,
                                List<ItemRow> items) {
        Map<String, Object> snapshot = new LinkedHashMap<>();
        snapshot.put("templateVersionId", templateVersionId);
        snapshot.put("categories", categories.stream().map(category -> {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("code", category.code());
            map.put("nameEn", category.nameEn());
            map.put("nameAr", category.nameAr());
            map.put("iconCode", category.iconCode());
            map.put("sortOrder", category.sortOrder());
            return map;
        }).toList());
        snapshot.put("items", items.stream().map(item -> {
            ChecklistItemDto schema = checklistItem(item, null);
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("itemCode", schema.itemCode());
            map.put("itemVersionId", schema.itemVersionId());
            map.put("categoryCode", schema.categoryCode());
            map.put("labelEn", schema.labelEn());
            map.put("labelAr", schema.labelAr());
            map.put("multiPoint", schema.multiPoint());
            map.put("safetyCritical", schema.safetyCritical());
            map.put("resultOptions", schema.resultOptions());
            map.put("scoreBands", schema.scoreBands());
            map.put("evidenceRules", schema.evidenceRules());
            map.put("issueFields", schema.issueFields());
            map.put("measurementBands", schema.measurementBands());
            return map;
        }).toList());
        return json(snapshot);
    }

    private ApiException conflict(String itemCode, AssessmentRow existing) {
        String message = existing == null
                ? "The item was modified by another request"
                : "The item was modified by another request; server revision "
                        + existing.serverRevision() + " is current";
        return new ApiException(HttpStatus.CONFLICT, "SYNC_CONFLICT",
                "error.technician.syncConflict", message,
                List.of(issue(itemCode, "SYNC_CONFLICT", "error.technician.syncConflict")));
    }

    private static FieldIssue issue(String field, String code, String messageKey) {
        return new FieldIssue(field, code, messageKey, null, null, null);
    }

    private static <T> List<T> safeList(List<T> values) {
        return values == null ? List.of() : values;
    }

    private static int noteLength(String value) {
        return value == null ? 0 : value.trim().length();
    }

    private static String str(LocalDateTime value) {
        return value == null ? null : value.toString();
    }

    private static String trimToNull(String value) {
        return isBlank(value) ? null : value.trim();
    }

    private static boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private static LocalDateTime parseDateTime(String value) {
        if (isBlank(value)) {
            return null;
        }
        try {
            return LocalDateTime.parse(value.trim());
        } catch (DateTimeParseException exception) {
            try {
                return OffsetDateTime.parse(value.trim()).toLocalDateTime();
            } catch (DateTimeParseException nested) {
                return null;
            }
        }
    }

    private String json(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Unable to serialize payload", exception);
        }
    }

    private static String sha256(String value) {
        return sha256(value.getBytes(StandardCharsets.UTF_8));
    }

    private static String sha256(byte[] value) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }

    private <T> Optional<T> replay(String actorId, String endpoint, String key, Class<T> type) {
        return idempotency.find(actorId, endpoint, key).map(stored -> {
            try {
                return objectMapper.readValue(stored.json(), type);
            } catch (JsonProcessingException exception) {
                throw new IllegalStateException("Unable to read idempotent response", exception);
            }
        });
    }
}
