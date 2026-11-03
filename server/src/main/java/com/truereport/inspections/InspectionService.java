package com.truereport.inspections;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.audit.AuditService;
import com.truereport.inspections.api.AssessmentDto;
import com.truereport.inspections.api.AssessmentRequest;
import com.truereport.inspections.api.ConsentRequest;
import com.truereport.inspections.api.CustomerUpdateRequest;
import com.truereport.inspections.api.EquipmentListDto;
import com.truereport.inspections.api.FinalizeResponse;
import com.truereport.inspections.api.InspectionChecklistDto;
import com.truereport.inspections.api.InspectionItemDto;
import com.truereport.inspections.api.ReviewDto;
import com.truereport.inspections.api.ReviewIssueDto;
import com.truereport.inspections.api.VehicleUpdateRequest;
import com.truereport.jobs.InspectionJob;
import com.truereport.jobs.InspectionJobRepository;
import com.truereport.jobs.WorkshopJobService;
import com.truereport.jobs.api.JobDto;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.security.CurrentUser;
import com.truereport.templates.WorkshopTemplateService;
import com.truereport.templates.api.TemplateItemViewDto;
import com.truereport.templates.api.TemplateVersionViewDto;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Service
public class InspectionService {

    private static final Set<String> RESULTS = Set.of(
            "NO_ISSUE_OBSERVED", "ATTENTION_RECOMMENDED", "DEFECT_FOUND",
            "NOT_CHECKED", "NOT_APPLICABLE", "COULD_NOT_VERIFY");
    private static final Set<String> SEVERITIES = Set.of(
            "MINOR", "MODERATE", "MAJOR", "SAFETY_CRITICAL");
    private static final Set<String> CONSENT_TYPES = Set.of(
            "PROCESSING", "PUBLIC_LINK", "WHATSAPP", "SMS", "EMAIL", "PDF_DOWNLOAD");
    private static final Set<String> CONSENT_STATUSES = Set.of("GRANTED", "REFUSED", "WITHDRAWN");
    private static final Set<String> NOTE_REQUIREMENTS = Set.of("NONE", "OPTIONAL", "REQUIRED");

    private final InspectionJobRepository jobs;
    private final InspectionItemSnapshotRepository snapshots;
    private final AssessmentRepository assessments;
    private final FindingRepository findings;
    private final InspectionFinalSnapshotRepository finalSnapshots;
    private final ConsentRecordRepository consents;
    private final InspectionStatusHistoryRepository statusHistory;
    private final WorkshopJobService jobService;
    private final WorkshopTemplateService templates;
    private final EvidenceService evidenceService;
    private final AuditService auditService;
    private final ObjectMapper objectMapper;

    public InspectionService(InspectionJobRepository jobs,
                             InspectionItemSnapshotRepository snapshots,
                             AssessmentRepository assessments,
                             FindingRepository findings,
                             InspectionFinalSnapshotRepository finalSnapshots,
                             ConsentRecordRepository consents,
                             InspectionStatusHistoryRepository statusHistory,
                             WorkshopJobService jobService,
                             WorkshopTemplateService templates,
                             EvidenceService evidenceService,
                             AuditService auditService,
                             ObjectMapper objectMapper) {
        this.jobs = jobs;
        this.snapshots = snapshots;
        this.assessments = assessments;
        this.findings = findings;
        this.finalSnapshots = finalSnapshots;
        this.consents = consents;
        this.statusHistory = statusHistory;
        this.jobService = jobService;
        this.templates = templates;
        this.evidenceService = evidenceService;
        this.auditService = auditService;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public InspectionChecklistDto start(CurrentUser caller, UUID jobId) {
        InspectionJob job = requireOwnJob(caller, jobId);
        if (job.getStatus().equals("FINALIZED") || job.getStatus().equals("CANCELLED")) {
            throw conflictFor(job);
        }
        if (!job.getStatus().equals("ASSIGNED") && !job.getStatus().equals("IN_PROGRESS")
                && !job.getStatus().equals("READY_TO_FINALIZE")) {
            throw new ApiException(HttpStatus.CONFLICT, "START_REQUIRED",
                    "error.inspection.startRequired", "The job must be assigned before starting");
        }
        if (snapshots.countByJobId(jobId) == 0) {
            TemplateVersionViewDto template = templates.pinnedVersion(
                    job.getWorkshopId(), job.getTemplateVersionId());
            if (template.items().isEmpty()) {
                throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "TEMPLATE_EMPTY",
                        "error.template.empty", "The pinned template has no items");
            }
            for (TemplateItemViewDto item : template.items()) {
                String itemJson = snapshotJson(item);
                snapshots.save(new InspectionItemSnapshot(job.getWorkshopId(), jobId,
                        item.masterItemVersionId(), item.sortOrder(), itemJson, hash(itemJson)));
            }
            if (job.getStatus().equals("ASSIGNED")) {
                String from = job.getStatus();
                job.start(now());
                jobs.save(job);
                history(job, from, job.getStatus(), caller.userId(), null);
                audit(caller, job, "INSPECTION_STARTED", Map.of("reference", job.getReference()));
            }
        }
        return checklist(caller, jobId);
    }

    @Transactional(readOnly = true)
    public InspectionChecklistDto checklist(CurrentUser caller, UUID jobId) {
        InspectionJob job = requireOwnJob(caller, jobId);
        List<InspectionItemSnapshot> items = snapshots.findByJobIdOrderBySortOrderAsc(jobId);
        List<Assessment> saved = assessments.findByJobId(jobId);
        Map<UUID, Assessment> assessmentByItem = new LinkedHashMap<>();
        for (Assessment assessment : saved) {
            assessmentByItem.put(assessment.getInspectionItemId(), assessment);
        }
        List<InspectionItemDto> dtos = items.stream()
                .map(item -> itemDto(item, assessmentByItem.get(item.getId())))
                .toList();
        return new InspectionChecklistDto(jobService.dto(job), dtos,
                (int) dtos.stream().filter(item -> item.assessment() != null).count(), dtos.size());
    }

    @Transactional(readOnly = true)
    public EquipmentListDto equipment(CurrentUser caller, UUID jobId) {
        requireOwnJob(caller, jobId);
        Set<UUID> ids = new LinkedHashSet<>();
        for (InspectionItemSnapshot item : snapshots.findByJobIdOrderBySortOrderAsc(jobId)) {
            for (String value : strings(parse(item.getItemJson()), "equipmentIds")) {
                if (!value.isBlank()) {
                    ids.add(UUID.fromString(value));
                }
            }
        }
        return new EquipmentListDto(new ArrayList<>(ids));
    }

    @Transactional
    public JobDto updateCustomer(CurrentUser caller, UUID jobId, CustomerUpdateRequest request) {
        InspectionJob job = requireMutableJob(caller, jobId);
        job.updateCustomer(request.customerName().trim(), trimToNull(request.customerPhone()),
                trimToNull(request.customerEmail()));
        jobs.save(job);
        audit(caller, job, "INSPECTION_CUSTOMER_UPDATED", Map.of("reference", job.getReference()));
        return jobService.dto(job);
    }

    @Transactional
    public JobDto updateVehicle(CurrentUser caller, UUID jobId, VehicleUpdateRequest request) {
        InspectionJob job = requireMutableJob(caller, jobId);
        String unit = request.odometerUnit() == null ? null : request.odometerUnit().trim().toUpperCase();
        if (unit != null && !unit.isEmpty() && !unit.equals("KM") && !unit.equals("MI")) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "ODOMETER_UNIT_INVALID",
                    "error.odometer.unit", "Odometer unit must be KM or MI");
        }
        job.updateVehicle(request.vehicleMake().trim(), request.vehicleModel().trim(),
                request.vehicleYear(), trimToNull(request.vehicleVin()), trimToNull(request.vehiclePlate()),
                request.odometerValue(), unit);
        jobs.save(job);
        audit(caller, job, "INSPECTION_VEHICLE_UPDATED", Map.of("reference", job.getReference()));
        return jobService.dto(job);
    }

    @Transactional
    public void recordConsent(CurrentUser caller, UUID jobId, ConsentRequest request) {
        InspectionJob job = requireOwnJob(caller, jobId);
        if (job.getStatus().equals("FINALIZED")) {
            throw conflictFor(job);
        }
        if (!CONSENT_TYPES.contains(request.consentType())) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "CONSENT_TYPE_INVALID",
                    "error.consent.type", "Unsupported consent type");
        }
        if (!CONSENT_STATUSES.contains(request.status())) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "CONSENT_STATUS_INVALID",
                    "error.consent.status", "Unsupported consent status");
        }
        consents.save(new ConsentRecord(job.getWorkshopId(), jobId, request.consentType(),
                request.status(), request.wordingVersion(), hash(request.wordingVersion()),
                caller.userId(), request.channel(), trimToNull(request.evidenceRef())));
        audit(caller, job, "INSPECTION_CONSENT_RECORDED",
                Map.of("consentType", request.consentType(), "status", request.status()));
    }

    @Transactional
    public InspectionItemDto assess(CurrentUser caller, UUID jobId, UUID itemId,
                                    AssessmentRequest request) {
        InspectionJob job = requireMutableJob(caller, jobId);
        if (!job.getStatus().equals("IN_PROGRESS") && !job.getStatus().equals("READY_TO_FINALIZE")) {
            throw new ApiException(HttpStatus.CONFLICT, "START_REQUIRED",
                    "error.inspection.startRequired", "Start the inspection before recording answers");
        }
        InspectionItemSnapshot item = snapshots.findByIdAndJobId(itemId, jobId)
                .orElseThrow(ApiException::notFound);
        JsonNode rules = parse(item.getItemJson());
        validateAssessment(job, rules, request);

        Assessment existing = assessments.findByJobIdAndInspectionItemId(jobId, itemId).orElse(null);
        int currentVersion = existing == null ? 0 : existing.getVersion();
        if (request.baseVersion() != currentVersion) {
            throw new ApiException(HttpStatus.CONFLICT, "VERSION_CONFLICT",
                    "error.version.conflict", "The assessment changed on the server");
        }
        String note = request.note();
        Assessment assessment;
        if (existing == null) {
            assessment = new Assessment(job.getWorkshopId(), jobId, itemId, caller.userId(),
                    request.resultCode(), trimToNull(request.severityCode()), note,
                    language(request.noteLanguage(), note), trimToNull(request.reasonCode()),
                    request.reasonText(), request.clientRevision(), request.baseVersion());
        } else {
            assessment = existing;
            assessment.update(request.resultCode(), trimToNull(request.severityCode()), note,
                    language(request.noteLanguage(), note), trimToNull(request.reasonCode()),
                    request.reasonText(), request.clientRevision(), request.baseVersion());
        }
        assessments.save(assessment);
        audit(caller, job, "INSPECTION_ITEM_ASSESSED",
                Map.of("inspectionItemId", itemId.toString(), "result", request.resultCode()));
        return itemDto(item, assessment);
    }

    @Transactional(readOnly = true)
    public ReviewDto review(CurrentUser caller, UUID jobId) {
        requireOwnJob(caller, jobId);
        return buildReview(jobId);
    }

    @Transactional
    public InspectionChecklistDto markReady(CurrentUser caller, UUID jobId) {
        InspectionJob job = requireOwnJob(caller, jobId);
        if (!job.getStatus().equals("IN_PROGRESS") && !job.getStatus().equals("READY_TO_FINALIZE")) {
            throw new ApiException(HttpStatus.CONFLICT, "START_REQUIRED",
                    "error.inspection.startRequired", "Start the inspection before review");
        }
        ReviewDto review = buildReview(jobId);
        if (!review.ready()) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "INSPECTION_INCOMPLETE",
                    "error.inspection.incomplete", "The inspection has blocking items");
        }
        if (!job.getStatus().equals("READY_TO_FINALIZE")) {
            String from = job.getStatus();
            job.markReady(now());
            jobs.save(job);
            history(job, from, job.getStatus(), caller.userId(), null);
            audit(caller, job, "INSPECTION_READY", Map.of("reference", job.getReference()));
        }
        return checklist(caller, jobId);
    }

    @Transactional
    public FinalizeResponse finalizeInspection(CurrentUser caller, UUID jobId, String idempotencyKey) {
        if (idempotencyKey == null || idempotencyKey.isBlank()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "IDEMPOTENCY_KEY_REQUIRED",
                    "error.idempotency.required", "Idempotency-Key is required");
        }
        InspectionJob job = jobs.findForUpdateByIdAndWorkshopId(jobId, caller.workshopId())
                .orElseThrow(ApiException::notFound);
        requireOwner(caller, job);
        byte[] keyHash = hash(idempotencyKey);
        if (job.getStatus().equals("FINALIZED")) {
            if (MessageDigest.isEqual(job.getFinalizationKeyHash(), keyHash)) {
                return finalizeResponse(job);
            }
            throw new ApiException(HttpStatus.CONFLICT, "ALREADY_FINALIZED",
                    "error.finalized", "The inspection is already finalized");
        }
        if (!job.getStatus().equals("READY_TO_FINALIZE")) {
            throw new ApiException(HttpStatus.CONFLICT, "READY_REQUIRED",
                    "error.inspection.readyRequired", "The inspection must be ready before finalization");
        }
        ReviewDto review = buildReview(jobId);
        if (!review.ready()) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "INSPECTION_INCOMPLETE",
                    "error.inspection.incomplete", "The inspection has blocking items");
        }
        String snapshotJson = finalSnapshotJson(job);
        byte[] snapshotHash = hash(snapshotJson);
        finalSnapshots.save(new InspectionFinalSnapshot(job.getWorkshopId(), jobId,
                snapshotJson, snapshotHash));
        for (Assessment assessment : assessments.findByJobId(jobId)) {
            if (assessment.getResultCode().equals("DEFECT_FOUND")
                    || assessment.getResultCode().equals("ATTENTION_RECOMMENDED")) {
                findings.save(new Finding(job.getWorkshopId(), jobId, assessment.getId(),
                        assessment.getSeverityCode(), assessment.getNoteText() == null
                        ? "Finding" : assessment.getNoteText(), assessment.getReasonText()));
            }
        }
        String from = job.getStatus();
        job.finalizeInspection(caller.userId(), now(), keyHash);
        jobs.save(job);
        history(job, from, job.getStatus(), caller.userId(), null);
        audit(caller, job, "INSPECTION_FINALIZED",
                Map.of("reference", job.getReference(), "snapshotHash", hex(snapshotHash)));
        return finalizeResponse(job);
    }

    private ReviewDto buildReview(UUID jobId) {
        List<InspectionItemSnapshot> items = snapshots.findByJobIdOrderBySortOrderAsc(jobId);
        List<Assessment> saved = assessments.findByJobId(jobId);
        Map<UUID, Assessment> byItem = new LinkedHashMap<>();
        for (Assessment assessment : saved) {
            byItem.put(assessment.getInspectionItemId(), assessment);
        }
        List<ReviewIssueDto> blocking = new ArrayList<>();
        List<ReviewIssueDto> warnings = new ArrayList<>();
        int completed = 0;
        for (InspectionItemSnapshot item : items) {
            JsonNode rules = parse(item.getItemJson());
            String label = text(rules, "labelEn");
            Assessment assessment = byItem.get(item.getId());
            if (assessment == null) {
                blocking.add(new ReviewIssueDto("ITEM_UNANSWERED", item.getId(), label, null));
                continue;
            }
            completed++;
            String result = assessment.getResultCode();
            if ((result.equals("NOT_CHECKED") || result.equals("COULD_NOT_VERIFY"))
                    && blank(assessment.getReasonCode()) && blank(assessment.getReasonText())) {
                blocking.add(new ReviewIssueDto("REASON_REQUIRED", item.getId(), label, result));
            }
            if ((result.equals("DEFECT_FOUND") || result.equals("ATTENTION_RECOMMENDED"))
                    && blank(assessment.getSeverityCode())) {
                blocking.add(new ReviewIssueDto("SEVERITY_REQUIRED", item.getId(), label, result));
            }
            if (text(rules, "noteRequirement").equals("REQUIRED") && blank(assessment.getNoteText())) {
                blocking.add(new ReviewIssueDto("NOTE_REQUIRED", item.getId(), label, result));
            }
            int requiredEvidence = evidenceService.requiredCount(rules);
            long verifiedEvidence = evidenceService.verifiedCount(jobId, item.getId());
            if (verifiedEvidence < requiredEvidence) {
                blocking.add(new ReviewIssueDto("EVIDENCE_REQUIRED", item.getId(), label,
                        "Required evidence: " + requiredEvidence + ", verified: " + verifiedEvidence));
            }
        }
        return new ReviewDto(blocking.isEmpty(), completed, items.size(), blocking, warnings);
    }

    private String finalSnapshotJson(InspectionJob job) {
        Map<String, Object> root = new LinkedHashMap<>();
        root.put("jobId", job.getId().toString());
        root.put("workshopId", job.getWorkshopId().toString());
        root.put("reference", job.getReference());
        root.put("templateVersionId", job.getTemplateVersionId().toString());
        root.put("status", "FINALIZED");
        root.put("finalizedAt", now().toString());
        root.put("customerName", job.getCustomerName());
        root.put("customerPhone", job.getCustomerPhone());
        root.put("customerEmail", job.getCustomerEmail());
        root.put("vehicleMake", job.getVehicleMake());
        root.put("vehicleModel", job.getVehicleModel());
        root.put("vehicleYear", job.getVehicleYear());
        root.put("vehicleVin", job.getVehicleVin());
        root.put("vehiclePlate", job.getVehiclePlate());
        root.put("odometerValue", job.getOdometerValue());
        root.put("odometerUnit", job.getOdometerUnit());
        root.put("scope", job.getScope());
        List<Map<String, Object>> itemList = new ArrayList<>();
        Map<UUID, Assessment> byItem = new LinkedHashMap<>();
        for (Assessment assessment : assessments.findByJobId(job.getId())) {
            byItem.put(assessment.getInspectionItemId(), assessment);
        }
        for (InspectionItemSnapshot item : snapshots.findByJobIdOrderBySortOrderAsc(job.getId())) {
            Assessment assessment = byItem.get(item.getId());
            Map<String, Object> entry = new LinkedHashMap<>();
            entry.put("inspectionItemId", item.getId().toString());
            entry.put("masterItemVersionId", item.getMasterItemVersionId().toString());
            entry.put("sortOrder", item.getSortOrder());
            entry.put("item", parse(item.getItemJson()));
            if (assessment != null) {
                entry.put("assessment", Map.of(
                        "resultCode", assessment.getResultCode(),
                        "severityCode", assessment.getSeverityCode() == null ? "" : assessment.getSeverityCode(),
                        "note", assessment.getNoteText() == null ? "" : assessment.getNoteText(),
                        "noteLanguage", assessment.getNoteLanguage() == null ? "und" : assessment.getNoteLanguage(),
                        "reasonCode", assessment.getReasonCode() == null ? "" : assessment.getReasonCode(),
                        "reasonText", assessment.getReasonText() == null ? "" : assessment.getReasonText()));
            }
            List<Map<String, Object>> evidence = new ArrayList<>();
            for (EvidenceAsset asset : evidenceService.verified(job.getId(), item.getId())) {
                evidence.add(Map.of(
                        "evidenceId", asset.getId().toString(),
                        "sourceSha256", hex(asset.getContentHash()),
                        "normalizedSha256", hex(asset.getNormalizedHash()),
                        "mime", asset.getMime(),
                        "bytes", asset.getBytes(),
                        "capturedAt", asset.getCapturedAt() == null ? "" : asset.getCapturedAt().toString()));
            }
            entry.put("evidence", evidence);
            itemList.add(entry);
        }
        root.put("items", itemList);
        root.put("evidenceState", itemList.stream()
                .anyMatch(item -> !((List<?>) item.get("evidence")).isEmpty())
                ? "VERIFIED" : "NOT_REQUIRED");
        return json(root);
    }

    private FinalizeResponse finalizeResponse(InspectionJob job) {
        InspectionFinalSnapshot snapshot = finalSnapshots.findByJobId(job.getId())
                .orElseThrow(() -> new IllegalStateException("Finalized job has no snapshot"));
        ReviewDto review = buildReview(job.getId());
        return new FinalizeResponse(job.getId().toString(), job.getStatus(),
                job.getFinalizedAt() == null ? "" : job.getFinalizedAt().toString(),
                hex(snapshot.getSnapshotHash()), snapshots.findByJobIdOrderBySortOrderAsc(job.getId()).size(),
                review.warnings().stream().map(ReviewIssueDto::code).distinct().toList());
    }

    private void validateAssessment(InspectionJob job, JsonNode rules, AssessmentRequest request) {
        if (!RESULTS.contains(request.resultCode())) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "RESULT_INVALID",
                    "error.result.invalid", "Result is not allowed");
        }
        if (!strings(rules, "resultOptions").contains(request.resultCode())) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "RESULT_NOT_ALLOWED",
                    "error.result.notAllowed", "Result is not allowed for this item");
        }
        if (request.severityCode() != null && !request.severityCode().isBlank()
                && !SEVERITIES.contains(request.severityCode())) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SEVERITY_INVALID",
                    "error.severity.invalid", "Severity is not valid");
        }
        boolean defect = request.resultCode().equals("DEFECT_FOUND")
                || request.resultCode().equals("ATTENTION_RECOMMENDED");
        if (defect && blank(request.severityCode())) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SEVERITY_REQUIRED",
                    "error.severity.required", "Severity is required for this result");
        }
        boolean reasonRequired = request.resultCode().equals("NOT_CHECKED")
                || request.resultCode().equals("COULD_NOT_VERIFY");
        if (reasonRequired && blank(request.reasonCode()) && blank(request.reasonText())) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "REASON_REQUIRED",
                    "error.reason.required", "A reason is required for this result");
        }
        if (!blank(request.reasonCode()) && !strings(rules, "reasonCodes").isEmpty()
                && !strings(rules, "reasonCodes").contains(request.reasonCode())) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "REASON_INVALID",
                    "error.reason.invalid", "Reason is not allowed for this item");
        }
        if (text(rules, "noteRequirement").equals("REQUIRED") && blank(request.note())) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "NOTE_REQUIRED",
                    "error.note.required", "A note is required for this item");
        }
        if (!applicabilityAllows(job, rules, request.resultCode())) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "ITEM_NOT_APPLICABLE",
                    "error.item.notApplicable", "This item is not applicable to the vehicle type");
        }
        if (!NOTE_REQUIREMENTS.contains(text(rules, "noteRequirement"))) {
            throw new IllegalStateException("Invalid note requirement in pinned item");
        }
    }

    private boolean applicabilityAllows(InspectionJob job, JsonNode rules, String result) {
        String raw = text(rules, "applicability");
        if (raw.isBlank()) {
            return true;
        }
        JsonNode applicability = parse(raw);
        List<String> vehicleTypes = strings(applicability, "vehicleTypes");
        if (vehicleTypes.isEmpty() || job.getVehicleType() == null) {
            return true;
        }
        return vehicleTypes.contains(job.getVehicleType())
                || result.equals("NOT_APPLICABLE") || result.equals("NOT_CHECKED");
    }

    private InspectionItemDto itemDto(InspectionItemSnapshot item, Assessment assessment) {
        JsonNode rules = parse(item.getItemJson());
        return new InspectionItemDto(item.getId(), item.getMasterItemVersionId(), item.getSortOrder(),
                text(rules, "stableCode"),
                text(rules, "categoryLabelEn"), text(rules, "categoryLabelAr"),
                text(rules, "labelEn"), text(rules, "labelAr"),
                text(rules, "instructionEn"), text(rules, "instructionAr"),
                rules.path("versionNo").asInt(0), strings(rules, "resultOptions"),
                text(rules, "severityPolicy"), text(rules, "applicability"),
                strings(rules, "reasonCodes"), text(rules, "noteRequirement"),
                text(rules, "evidenceRequirement"), rules.path("minPhotos").asInt(0),
                strings(rules, "equipmentIds"),
                text(rules, "guideImageId").isBlank() ? null : UUID.fromString(text(rules, "guideImageId")),
                rules.path("sampleData").asBoolean(false),
                assessment == null ? null : new AssessmentDto(assessment.getId(),
                        assessment.getResultCode(), assessment.getSeverityCode(),
                        assessment.getNoteText(), assessment.getNoteLanguage(),
                        assessment.getReasonCode(), assessment.getReasonText(),
                        assessment.getClientRevision(), assessment.getServerRevision(),
                        assessment.getVersion()));
    }

    private String snapshotJson(TemplateItemViewDto item) {
        Map<String, Object> snapshot = new LinkedHashMap<>();
        snapshot.put("stableCode", item.stableCode());
        snapshot.put("categoryLabelEn", item.categoryLabelEn());
        snapshot.put("categoryLabelAr", item.categoryLabelAr());
        snapshot.put("labelEn", item.labelEn());
        snapshot.put("labelAr", item.labelAr());
        snapshot.put("instructionEn", item.instructionEn());
        snapshot.put("instructionAr", item.instructionAr());
        snapshot.put("versionNo", item.versionNo());
        snapshot.put("resultOptions", item.resultOptions());
        snapshot.put("severityPolicy", item.severityPolicy());
        snapshot.put("applicability", item.applicability());
        snapshot.put("reasonCodes", item.reasonCodes());
        snapshot.put("noteRequirement", item.noteRequirement());
        snapshot.put("evidenceRequirement", item.evidenceRequirement());
        snapshot.put("minPhotos", item.minPhotos());
        snapshot.put("equipmentIds", item.equipmentIds());
        snapshot.put("guideImageId", item.guideImageId() == null ? "" : item.guideImageId().toString());
        snapshot.put("sampleData", item.sampleData());
        return json(snapshot);
    }

    private InspectionJob requireOwnJob(CurrentUser caller, UUID jobId) {
        if (!caller.isTechnician() || caller.workshopId() == null) {
            throw ApiException.notFound();
        }
        InspectionJob job = jobs.findByIdAndWorkshopId(jobId, caller.workshopId())
                .orElseThrow(ApiException::notFound);
        requireOwner(caller, job);
        return job;
    }

    private InspectionJob requireMutableJob(CurrentUser caller, UUID jobId) {
        InspectionJob job = requireOwnJob(caller, jobId);
        if (job.getStatus().equals("FINALIZED")) {
            throw conflictFor(job);
        }
        if (job.getStatus().equals("CANCELLED")) {
            throw conflictFor(job);
        }
        return job;
    }

    private void requireOwner(CurrentUser caller, InspectionJob job) {
        if (!caller.userId().equals(job.getAssignedTechnicianId())
                && !caller.userId().equals(job.getCreatedBy())) {
            throw new ApiException(HttpStatus.CONFLICT, "JOB_REASSIGNED",
                    "error.job.reassigned", "The job was reassigned");
        }
        if (!job.getStatus().equals("CANCELLED") && !job.getStatus().equals("FINALIZED")
                && !caller.userId().equals(job.getAssignedTechnicianId())) {
            throw new ApiException(HttpStatus.CONFLICT, "JOB_REASSIGNED",
                    "error.job.reassigned", "The job was reassigned");
        }
    }

    private ApiException conflictFor(InspectionJob job) {
        if (job.getStatus().equals("FINALIZED")) {
            return new ApiException(HttpStatus.CONFLICT, "ALREADY_FINALIZED",
                    "error.finalized", "The inspection is finalized");
        }
        return new ApiException(HttpStatus.CONFLICT, "JOB_CANCELLED",
                "error.job.cancelled", "The job is cancelled");
    }

    private void history(InspectionJob job, String from, String to, UUID actor, String reason) {
        statusHistory.save(new InspectionStatusHistory(job.getWorkshopId(), job.getId(),
                from, to, actor, reason));
    }

    private void audit(CurrentUser actor, InspectionJob job, String action, Map<String, String> metadata) {
        auditService.record(job.getWorkshopId(), actor.userId(), actor.role(), action,
                "INSPECTION", job.getId(), null, json(metadata));
    }

    private String language(String requested, String note) {
        if (requested != null && !requested.isBlank() && requested.length() <= 16) {
            return requested;
        }
        if (note == null || note.isBlank()) {
            return "und";
        }
        int first = note.codePointAt(0);
        if (first >= 0x0600 && first <= 0x06FF) {
            return "ar";
        }
        if (first >= 0x0400 && first <= 0x04FF) {
            return "ru";
        }
        if (first >= 0x4E00 && first <= 0x9FFF) {
            return "zh-Hans";
        }
        return "en";
    }

    private JsonNode parse(String value) {
        try {
            return objectMapper.readTree(value == null || value.isBlank() ? "{}" : value);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Invalid pinned item JSON", exception);
        }
    }

    private String text(JsonNode node, String field) {
        return node.path(field).asText("");
    }

    private List<String> strings(JsonNode node, String field) {
        List<String> result = new ArrayList<>();
        JsonNode array = node.path(field);
        if (array.isArray()) {
            array.forEach(value -> result.add(value.asText()));
        }
        return result;
    }

    private String json(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Unable to serialize inspection", exception);
        }
    }

    private byte[] hash(String value) {
        try {
            return MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 unavailable", exception);
        }
    }

    private String hex(byte[] value) {
        if (value == null) {
            return "";
        }
        StringBuilder builder = new StringBuilder(value.length * 2);
        for (byte b : value) {
            builder.append(String.format("%02x", b));
        }
        return builder.toString();
    }

    private boolean blank(String value) {
        return value == null || value.isBlank();
    }

    private String trimToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private LocalDateTime now() {
        return LocalDateTime.now(ZoneOffset.UTC);
    }
}
