package com.truereport.jobs;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.identity.User;
import com.truereport.identity.UserRepository;
import com.truereport.jobs.PlatformJobStore.AssignmentRow;
import com.truereport.jobs.PlatformJobStore.DocumentRow;
import com.truereport.jobs.PlatformJobStore.GradeBoundaryRow;
import com.truereport.jobs.PlatformJobStore.JobRow;
import com.truereport.jobs.PlatformJobStore.LinkRow;
import com.truereport.jobs.PlatformJobStore.NotificationRow;
import com.truereport.jobs.PlatformJobStore.ReportVersionRow;
import com.truereport.jobs.PlatformJobStore.ResultRow;
import com.truereport.jobs.PlatformJobStore.ScoringRuleRow;
import com.truereport.jobs.PlatformJobStore.TemplateItemRow;
import com.truereport.jobs.PlatformJobStore.TemplateVersionRow;
import com.truereport.jobs.api.WorkshopJobDtos.ApproveJobRequest;
import com.truereport.jobs.api.WorkshopJobDtos.AssignTechnicianRequest;
import com.truereport.jobs.api.WorkshopJobDtos.AssignmentDto;
import com.truereport.jobs.api.WorkshopJobDtos.AvailableTemplateDto;
import com.truereport.jobs.api.WorkshopJobDtos.CancelJobRequest;
import com.truereport.jobs.api.WorkshopJobDtos.ChecklistItemDto;
import com.truereport.jobs.api.WorkshopJobDtos.CreateJobRequest;
import com.truereport.jobs.api.WorkshopJobDtos.JobDto;
import com.truereport.jobs.api.WorkshopJobDtos.JobPageDto;
import com.truereport.jobs.api.WorkshopJobDtos.JobStatusCountsDto;
import com.truereport.jobs.api.WorkshopJobDtos.NotificationDto;
import com.truereport.jobs.api.WorkshopJobDtos.PublishChecklistDto;
import com.truereport.jobs.api.WorkshopJobDtos.PublishJobRequest;
import com.truereport.jobs.api.WorkshopJobDtos.PublicLinkDto;
import com.truereport.jobs.api.WorkshopJobDtos.RejectJobRequest;
import com.truereport.jobs.api.WorkshopJobDtos.ReportDocumentDto;
import com.truereport.jobs.api.WorkshopJobDtos.ReviewDto;
import com.truereport.jobs.api.WorkshopJobDtos.ReviewFindingDto;
import com.truereport.jobs.api.WorkshopJobDtos.TemplateItemDto;
import com.truereport.jobs.api.WorkshopJobDtos.TemplateVersionDetailDto;
import com.truereport.jobs.api.WorkshopJobDtos.UpdateJobRequest;
import com.truereport.shared.audit.FieldAuditService;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import com.truereport.shared.idempotency.IdempotencyService;
import com.truereport.shared.outbox.OutboxService;
import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.uuid.UuidV7;
import com.truereport.tenancy.WorkshopMembership;
import com.truereport.tenancy.WorkshopMembershipRepository;
import com.truereport.tenancy.WorkshopRole;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Supplier;

@Service
public class WorkshopJobAdminService {

    private static final Set<String> STATUSES = Set.of(
            "DRAFT", "SCHEDULED", "ASSIGNED", "IN_PROGRESS", "PENDING_REVIEW",
            "APPROVED", "PUBLISHED", "REJECTED", "CANCELLED");
    private static final Set<String> EDITABLE_STATUSES = Set.of(
            "DRAFT", "SCHEDULED", "ASSIGNED", "IN_PROGRESS");
    private static final Set<String> ASSIGNABLE_STATUSES = Set.of(
            "DRAFT", "SCHEDULED", "ASSIGNED", "IN_PROGRESS");
    private static final Set<String> LANGUAGES = Set.of("en", "ar");
    private static final List<String> GRADE_ORDER = List.of("A", "B", "C", "D");

    private final PlatformJobStore store;
    private final WorkshopMembershipRepository memberships;
    private final UserRepository users;
    private final FieldAuditService audit;
    private final OutboxService outbox;
    private final IdempotencyService idempotency;
    private final PlatformJobDocumentService documents;
    private final PlatformJobTokenService tokens;
    private final PlatformQrService qr;
    private final ObjectMapper objectMapper;
    private final String publicBaseUrl;

    public WorkshopJobAdminService(PlatformJobStore store,
                                      WorkshopMembershipRepository memberships,
                                      UserRepository users,
                                      FieldAuditService audit,
                                      OutboxService outbox,
                                      IdempotencyService idempotency,
                                      PlatformJobDocumentService documents,
                                      PlatformJobTokenService tokens,
                                      PlatformQrService qr,
                                      ObjectMapper objectMapper,
                                      @Value("${truereport.report.public-base-url:http://localhost:8080}")
                                      String publicBaseUrl) {
        this.store = store;
        this.memberships = memberships;
        this.users = users;
        this.audit = audit;
        this.outbox = outbox;
        this.idempotency = idempotency;
        this.documents = documents;
        this.tokens = tokens;
        this.qr = qr;
        this.objectMapper = objectMapper;
        this.publicBaseUrl = publicBaseUrl.endsWith("/")
                ? publicBaseUrl.substring(0, publicBaseUrl.length() - 1) : publicBaseUrl;
    }

    // ------------------------------------------------------------- templates

    @Transactional(readOnly = true)
    public List<AvailableTemplateDto> availableTemplates(CurrentUser caller) {
        requireWorkshop(caller);
        return store.availableTemplates().stream()
                .map(row -> new AvailableTemplateDto(row.versionId(), row.templateId(), row.code(),
                        row.nameEn(), row.nameAr(), row.versionNo(),
                        store.templateItemCount(row.versionId())))
                .toList();
    }

    @Transactional(readOnly = true)
    public TemplateVersionDetailDto templateVersion(CurrentUser caller, String versionId) {
        requireWorkshop(caller);
        TemplateVersionRow version = store.templateVersion(versionId)
                .orElseThrow(() -> notFound("TEMPLATE_NOT_FOUND", "error.template.notFound",
                        "Template not found"));
        List<TemplateItemDto> items = store.templateItems(versionId).stream()
                .map(this::templateItemDto)
                .toList();
        return new TemplateVersionDetailDto(version.versionId(), version.templateId(),
                version.code(), version.nameEn(), version.nameAr(), version.versionNo(),
                version.status(), items);
    }

    // ------------------------------------------------------------------ jobs

    @Transactional(readOnly = true)
    public JobPageDto listJobs(CurrentUser caller, int page, int size, String status,
                               String search, String from, String to) {
        String workshopId = requireWorkshop(caller);
        String filter = validateStatus(status);
        int safePage = Math.max(0, page);
        int safeSize = Math.min(100, Math.max(1, size));
        LocalDateTime fromDate = parseDate(from, true);
        LocalDateTime toDate = parseDate(to, false);
        List<JobRow> rows = store.listJobs(workshopId, filter, search, fromDate, toDate,
                safePage * safeSize, safeSize);
        long total = store.countJobs(workshopId, filter, search, fromDate, toDate);
        int totalPages = safeSize == 0 ? 0 : (int) Math.ceil((double) total / safeSize);
        return new JobPageDto(rows.stream().map(this::jobDto).toList(), safePage, safeSize,
                total, totalPages);
    }

    @Transactional(readOnly = true)
    public JobStatusCountsDto counts(CurrentUser caller) {
        String workshopId = requireWorkshop(caller);
        Map<String, Long> counts = new LinkedHashMap<>();
        for (String status : store.statuses(workshopId)) {
            counts.merge(status, 1L, Long::sum);
        }
        long total = counts.values().stream().mapToLong(Long::longValue).sum();
        return new JobStatusCountsDto(
                counts.getOrDefault("DRAFT", 0L),
                counts.getOrDefault("SCHEDULED", 0L),
                counts.getOrDefault("ASSIGNED", 0L),
                counts.getOrDefault("IN_PROGRESS", 0L),
                counts.getOrDefault("PENDING_REVIEW", 0L),
                counts.getOrDefault("APPROVED", 0L),
                counts.getOrDefault("PUBLISHED", 0L),
                counts.getOrDefault("REJECTED", 0L),
                counts.getOrDefault("CANCELLED", 0L),
                total);
    }

    @Transactional(readOnly = true)
    public JobDto job(CurrentUser caller, String jobId) {
        String workshopId = requireWorkshop(caller);
        return jobDto(store.findJob(workshopId, jobId)
                .orElseThrow(() -> notFound("JOB_NOT_FOUND", "error.job.notFound",
                        "Job not found")));
    }

    @Transactional
    public JobDto create(CurrentUser caller, CreateJobRequest request, String idempotencyKey) {
        String workshopId = requireWorkshop(caller);
        String endpoint = "POST /api/v1/workshop/jobs";
        String actorId = caller.userId().toString();
        Optional<JobDto> replay = replay(actorId, endpoint, idempotencyKey, JobDto.class);
        if (replay.isPresent()) {
            return replay.get();
        }
        if (request == null) {
            throw ApiException.validation("JOB_VALIDATION_FAILED", "Job validation failed",
                    List.of(field("request", "REQUEST_REQUIRED")));
        }
        List<FieldIssue> issues = validateVehicle(request.customerName(), request.customerPhone(),
                request.customerEmail(), request.vehicleVin(), request.vehicleMake(),
                request.vehicleModel(), request.vehicleYear(), request.vehiclePlate(),
                request.odometerValue(), request.odometerUnit(), request.transmission(),
                request.fuelType(), request.preferredLanguage());
        if (issues.size() > 0) {
            throw ApiException.validation("JOB_VALIDATION_FAILED", "Job validation failed", issues);
        }
        TemplateVersionRow template = requirePublishedTemplate(request.templateVersionId());
        String technicianId = trimToNull(request.assignedTechnicianId());
        if (technicianId != null) {
            requireActiveTechnician(workshopId, technicianId);
        }
        LocalDateTime scheduledAt = parseDateTime(request.scheduledAt());
        boolean consent = Boolean.TRUE.equals(request.consentGranted());
        String status = technicianId != null ? "ASSIGNED"
                : (scheduledAt != null ? "SCHEDULED" : "DRAFT");
        String reference = reference(workshopId);
        String jobId = store.insertJob(new JobRow(
                null, workshopId, reference, status, "NOT_SUBMITTED", "UNPUBLISHED",
                template.versionId(), technicianId, request.customerName().trim(),
                request.customerPhone().trim(), trimToNull(request.customerEmail()),
                request.vehicleVin().trim().toUpperCase(Locale.ROOT),
                request.vehicleMake().trim(), request.vehicleModel().trim(),
                request.vehicleYear(), request.vehiclePlate().trim().toUpperCase(Locale.ROOT),
                request.odometerValue(), request.odometerUnit().trim().toUpperCase(Locale.ROOT),
                request.transmission().trim().toUpperCase(Locale.ROOT),
                request.fuelType().trim().toUpperCase(Locale.ROOT),
                normalizeLanguage(request.preferredLanguage()), scheduledAt, null, null, null,
                null, null, null, null, null, null, null, false, null, consent, false,
                actorId, null, null, 0));
        if (technicianId != null) {
            store.insertAssignment(jobId, technicianId, actorId, "Created with assignment");
            notify(workshopId, technicianId, "JOB_ASSIGNED", Map.of(
                    "jobId", jobId, "reference", reference));
        }
        store.insertHistory(jobId, null, status, actorId, "Job created");
        JobRow created = store.findJob(workshopId, jobId).orElseThrow();
        audit.record(caller, "JOB_CREATED", "JOB", jobId, null,
                Map.of("reference", reference, "status", status,
                        "templateVersionId", template.versionId()), null, null);
        outbox.publish("JOB", jobId, "JOB_CREATED", Map.of(
                "jobId", jobId, "workshopId", workshopId, "reference", reference,
                "templateVersionId", template.versionId()));
        JobDto dto = jobDto(created);
        storeIdempotent(actorId, endpoint, idempotencyKey, 201, dto);
        return dto;
    }

    @Transactional
    public JobDto update(CurrentUser caller, String jobId, UpdateJobRequest request) {
        String workshopId = requireWorkshop(caller);
        JobRow job = requireJob(workshopId, jobId);
        if (!EDITABLE_STATUSES.contains(job.status())) {
            throw new ApiException(HttpStatus.CONFLICT, "JOB_NOT_EDITABLE",
                    "error.job.statusInvalid",
                    "Customer and vehicle details can only be edited before finalization");
        }
        if (request == null) {
            throw ApiException.validation("JOB_VALIDATION_FAILED", "Job validation failed",
                    List.of(field("request", "REQUEST_REQUIRED")));
        }
        checkVersion(job, request.version());
        List<FieldIssue> issues = validateVehicle(request.customerName(), request.customerPhone(),
                request.customerEmail(), request.vehicleVin(), request.vehicleMake(),
                request.vehicleModel(), request.vehicleYear(), request.vehiclePlate(),
                request.odometerValue(), request.odometerUnit(), request.transmission(),
                request.fuelType(), request.preferredLanguage());
        if (issues.size() > 0) {
            throw ApiException.validation("JOB_VALIDATION_FAILED", "Job validation failed", issues);
        }
        int updated = store.updateCustomerVehicle(job, request.customerName().trim(),
                request.customerPhone().trim(), trimToNull(request.customerEmail()),
                request.vehicleVin().trim().toUpperCase(Locale.ROOT),
                request.vehicleMake().trim(), request.vehicleModel().trim(),
                request.vehicleYear(), request.vehiclePlate().trim().toUpperCase(Locale.ROOT),
                request.odometerValue(), request.odometerUnit().trim().toUpperCase(Locale.ROOT),
                request.transmission().trim().toUpperCase(Locale.ROOT),
                request.fuelType().trim().toUpperCase(Locale.ROOT),
                normalizeLanguage(request.preferredLanguage()), job.version());
        if (updated == 0) {
            throw ApiException.versionConflict("The job was modified by someone else");
        }
        JobRow updatedRow = requireJob(workshopId, jobId);
        audit.record(caller, "JOB_UPDATED", "JOB", jobId, job, updatedRow, null, null);
        outbox.publish("JOB", jobId, "JOB_UPDATED", Map.of("jobId", jobId));
        return jobDto(updatedRow);
    }

    @Transactional
    public JobDto assign(CurrentUser caller, String jobId, AssignTechnicianRequest request) {
        String workshopId = requireWorkshop(caller);
        JobRow job = requireJob(workshopId, jobId);
        if (!ASSIGNABLE_STATUSES.contains(job.status())) {
            throw new ApiException(HttpStatus.CONFLICT, "JOB_NOT_ASSIGNABLE",
                    "error.job.statusInvalid", "Job cannot be assigned in its current state");
        }
        if (request == null || isBlank(request.technicianId())) {
            throw ApiException.validation("ASSIGNMENT_INVALID", "Assignment is invalid",
                    List.of(field("technicianId", "REQUIRED")));
        }
        checkVersion(job, request.version());
        String technicianId = requireActiveTechnician(workshopId, request.technicianId());
        if (technicianId.equals(job.assignedTechnicianId())) {
            throw ApiException.conflict("JOB_ALREADY_ASSIGNED",
                    "Job is already assigned to this technician");
        }
        String reason = trimToNull(request.reason());
        store.closeAssignments(jobId, reason);
        store.insertAssignment(jobId, technicianId, caller.userId().toString(), reason);
        String nextStatus = "IN_PROGRESS".equals(job.status()) ? "IN_PROGRESS" : "ASSIGNED";
        int updated = store.assign(jobId, job.version(), technicianId, nextStatus);
        if (updated == 0) {
            throw ApiException.versionConflict("The job was modified by someone else");
        }
        store.insertHistory(jobId, job.status(), nextStatus, caller.userId().toString(), reason);
        audit.record(caller, "JOB_ASSIGNED", "JOB", jobId,
                Map.of("technicianId", String.valueOf(job.assignedTechnicianId())),
                Map.of("technicianId", technicianId), reason, null);
        outbox.publish("JOB", jobId, "JOB_ASSIGNED", Map.of(
                "jobId", jobId, "technicianId", technicianId));
        notify(workshopId, technicianId, "JOB_ASSIGNED",
                Map.of("jobId", jobId, "reference", job.reference()));
        return jobDto(requireJob(workshopId, jobId));
    }

    @Transactional
    public JobDto cancel(CurrentUser caller, String jobId, CancelJobRequest request) {
        String workshopId = requireWorkshop(caller);
        JobRow job = requireJob(workshopId, jobId);
        if (job.status().equals("CANCELLED")) {
            throw ApiException.conflict("JOB_ALREADY_CANCELLED", "Job is already cancelled");
        }
        if (job.status().equals("PUBLISHED") || job.status().equals("APPROVED")
                || job.status().equals("REJECTED")) {
            throw new ApiException(HttpStatus.CONFLICT, "JOB_NOT_CANCELLABLE",
                    "error.job.statusInvalid", "Job cannot be cancelled in its current state");
        }
        if (request == null || isBlank(request.reason())) {
            throw ApiException.validation("CANCEL_REASON_REQUIRED", "Cancellation reason is required",
                    List.of(field("reason", "REQUIRED")));
        }
        checkVersion(job, request.version());
        String reason = request.reason().trim();
        int updated = store.cancel(jobId, job.version(), caller.userId().toString(), reason);
        if (updated == 0) {
            throw ApiException.versionConflict("The job was modified by someone else");
        }
        store.insertHistory(jobId, job.status(), "CANCELLED", caller.userId().toString(), reason);
        audit.record(caller, "JOB_CANCELLED", "JOB", jobId,
                Map.of("status", job.status()), Map.of("status", "CANCELLED"), reason, null);
        outbox.publish("JOB", jobId, "JOB_CANCELLED", Map.of("jobId", jobId, "reason", reason));
        return jobDto(requireJob(workshopId, jobId));
    }

    @Transactional(readOnly = true)
    public List<AssignmentDto> assignments(CurrentUser caller, String jobId) {
        String workshopId = requireWorkshop(caller);
        requireJob(workshopId, jobId);
        return store.assignments(jobId).stream().map(this::assignmentDto).toList();
    }

    // ---------------------------------------------------------- review/approve

    @Transactional(readOnly = true)
    public ReviewDto review(CurrentUser caller, String jobId) {
        String workshopId = requireWorkshop(caller);
        JobRow job = requireJob(workshopId, jobId);
        List<TemplateItemRow> items = store.templateItems(job.templateVersionId());
        Map<String, ResultRow> results = resultsByItem(jobId);
        List<ReviewFindingDto> findings = new ArrayList<>();
        for (TemplateItemRow item : items) {
            ResultRow result = results.get(item.itemVersionId());
            findings.add(new ReviewFindingDto(item.itemVersionId(), item.stableCode(),
                    item.labelEn(), item.labelAr(),
                    result == null ? null : result.resultCode(),
                    result == null ? null : result.score(),
                    result == null ? 0 : result.evidencePhotoCount(),
                    result == null ? 0 : result.evidenceVideoCount(),
                    result != null && result.signaturePresent(),
                    result == null || result.completedAt() == null ? null
                            : result.completedAt().toString(),
                    result == null ? null : result.issueValuesJson()));
        }
        ScoreResult score = computeScore(job);
        return new ReviewDto(job.id(), job.status(), results.size(), items.size(),
                score.score(), score.grade(), score.capReason(), findings);
    }

    @Transactional(readOnly = true)
    public PublishChecklistDto checklist(CurrentUser caller, String jobId) {
        String workshopId = requireWorkshop(caller);
        JobRow job = requireJob(workshopId, jobId);
        Evaluation evaluation = evaluate(caller, job, job.safetyCapReason());
        return new PublishChecklistDto(job.id(), evaluation.ready(), evaluation.items(),
                evaluation.assessed(), evaluation.total(), evaluation.score().score(),
                evaluation.score().grade(), evaluation.score().capApplied(),
                evaluation.score().capReason(), job.consentGranted(), job.signaturePresent(),
                true);
    }

    @Transactional
    public JobDto approve(CurrentUser caller, String jobId, ApproveJobRequest request,
                          String idempotencyKey) {
        String workshopId = requireWorkshop(caller);
        String endpoint = "POST /api/v1/workshop/jobs/" + jobId + "/approve";
        String actorId = caller.userId().toString();
        Optional<JobDto> replay = replay(actorId, endpoint, idempotencyKey, JobDto.class);
        if (replay.isPresent()) {
            return replay.get();
        }
        JobRow job = requireJob(workshopId, jobId);
        if (!"PENDING_REVIEW".equals(job.status())) {
            throw new ApiException(HttpStatus.CONFLICT, "JOB_NOT_PENDING_REVIEW",
                    "error.job.statusInvalid", "Only a pending-review job can be approved");
        }
        if (actorId.equals(job.assignedTechnicianId())) {
            throw new ApiException(HttpStatus.CONFLICT, "APPROVER_IS_TECHNICIAN",
                    "error.job.approverIsTechnician",
                    "The approver must not be the assigned technician");
        }
        checkVersion(job, request == null ? null : request.version());
        String requestedCapReason = request == null ? null : trimToNull(request.safetyCapReason());
        Evaluation evaluation = evaluate(caller, job, requestedCapReason);
        if (!evaluation.ready()) {
            List<FieldIssue> issues = evaluation.items().stream()
                    .filter(item -> !item.passed())
                    .map(item -> new FieldIssue(item.code(), item.code(), item.code(),
                            item.messageEn(), item.messageAr(), item.messageEn()))
                    .toList();
            throw ApiException.validation("APPROVAL_CHECKLIST_INCOMPLETE",
                    "Approval checklist is not complete", issues);
        }
        ScoreResult score = evaluation.score();
        if (score.capApplied() && requestedCapReason != null) {
            score = new ScoreResult(score.score(), score.grade(), true, requestedCapReason);
        }
        String snapshotJson = snapshot(job, evaluation, score);
        String snapshotHash = sha256(snapshotJson);
        int reportVersionNo = store.nextReportVersionNo(jobId);
        store.insertReportVersion(jobId, reportVersionNo, snapshotJson, snapshotHash, actorId);
        int updated = store.approve(jobId, job.version(), actorId, score.score(), score.grade(),
                score.capApplied(), score.capReason());
        if (updated == 0) {
            throw ApiException.versionConflict("The job was modified by someone else");
        }
        store.insertApproval(jobId, actorId, "APPROVED",
                request == null ? null : trimToNull(request.reason()));
        store.insertHistory(jobId, job.status(), "APPROVED", actorId,
                request == null ? null : trimToNull(request.reason()));
        audit.record(caller, "JOB_APPROVED", "JOB", jobId,
                Map.of("status", job.status(), "score", String.valueOf(job.score())),
                Map.of("status", "APPROVED", "score", score.score(),
                        "grade", String.valueOf(score.grade())), null, null);
        outbox.publish("JOB", jobId, "JOB_APPROVED", Map.of(
                "jobId", jobId, "score", score.score(), "grade", String.valueOf(score.grade()),
                "reportVersionNo", reportVersionNo));
        notify(workshopId, job.createdBy(), "JOB_APPROVED",
                Map.of("jobId", jobId, "reference", job.reference()));
        JobDto dto = jobDto(requireJob(workshopId, jobId));
        storeIdempotent(actorId, endpoint, idempotencyKey, 200, dto);
        return dto;
    }

    @Transactional
    public JobDto reject(CurrentUser caller, String jobId, RejectJobRequest request) {
        String workshopId = requireWorkshop(caller);
        JobRow job = requireJob(workshopId, jobId);
        if (!"PENDING_REVIEW".equals(job.status())) {
            throw new ApiException(HttpStatus.CONFLICT, "JOB_NOT_PENDING_REVIEW",
                    "error.job.statusInvalid", "Only a pending-review job can be rejected");
        }
        if (request == null || isBlank(request.reason())) {
            throw ApiException.validation("REJECT_REASON_REQUIRED", "Rejection reason is required",
                    List.of(field("reason", "REQUIRED")));
        }
        checkVersion(job, request.version());
        String reason = request.reason().trim();
        int updated = store.reject(jobId, job.version(), caller.userId().toString());
        if (updated == 0) {
            throw ApiException.versionConflict("The job was modified by someone else");
        }
        store.insertApproval(jobId, caller.userId().toString(), "REJECTED", reason);
        store.insertHistory(jobId, job.status(), "REJECTED", caller.userId().toString(), reason);
        audit.record(caller, "JOB_REJECTED", "JOB", jobId,
                Map.of("status", job.status()), Map.of("status", "REJECTED"), reason, null);
        outbox.publish("JOB", jobId, "JOB_REJECTED", Map.of("jobId", jobId, "reason", reason));
        notify(workshopId, job.createdBy(), "JOB_REJECTED",
                Map.of("jobId", jobId, "reference", job.reference()));
        return jobDto(requireJob(workshopId, jobId));
    }

    // -------------------------------------------------------------- publish

    @Transactional
    public PublicLinkDto publish(CurrentUser caller, String jobId, PublishJobRequest request,
                                 String idempotencyKey) {
        String workshopId = requireWorkshop(caller);
        String endpoint = "POST /api/v1/workshop/jobs/" + jobId + "/publish";
        String actorId = caller.userId().toString();
        Optional<PublicLinkDto> replay = replay(actorId, endpoint, idempotencyKey,
                PublicLinkDto.class);
        if (replay.isPresent()) {
            return replay.get();
        }
        JobRow job = requireJob(workshopId, jobId);
        if ("PUBLISHED".equals(job.status())) {
            LinkRow active = store.activeLink(jobId).orElseThrow(
                    () -> new ApiException(HttpStatus.CONFLICT, "JOB_ALREADY_PUBLISHED",
                            "error.job.statusInvalid", "Job is already published"));
            return linkDto(job, active, true);
        }
        if (!"APPROVED".equals(job.status())) {
            throw new ApiException(HttpStatus.CONFLICT, "JOB_NOT_APPROVED",
                    "error.job.publishState", "Only an approved job can be published");
        }
        if (!job.consentGranted()) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "CONSENT_REQUIRED",
                    "error.job.consentRequired",
                    "Public-link consent must be granted before publishing");
        }
        ReportVersionRow version = store.latestReportVersion(jobId)
                .orElseThrow(() -> new ApiException(HttpStatus.CONFLICT,
                        "REPORT_VERSION_MISSING", "error.job.publishState",
                        "The approved report version is missing"));
        boolean pdfDownload = request != null && Boolean.TRUE.equals(request.pdfDownloadEnabled());
        String token = tokens.newToken();
        store.insertLink(jobId, version.id(), tokens.hash(token), tokens.encrypt(token),
                pdfDownload);
        int updated = store.publish(jobId, job.version());
        if (updated == 0) {
            throw ApiException.versionConflict("The job was modified by someone else");
        }
        store.insertHistory(jobId, job.status(), "PUBLISHED", actorId, null);
        audit.record(caller, "JOB_PUBLISHED", "JOB", jobId,
                Map.of("status", job.status()),
                Map.of("status", "PUBLISHED", "reportVersionId", version.id()), null, null);
        outbox.publish("JOB", jobId, "JOB_PUBLISHED", Map.of(
                "jobId", jobId, "reportVersionId", version.id()));
        notify(workshopId, job.createdBy(), "JOB_PUBLISHED",
                Map.of("jobId", jobId, "reference", job.reference()));
        documents.generateForVersion(job, version.id());
        PublicLinkDto dto = linkDto(job, store.activeLink(jobId).orElseThrow(), true);
        storeIdempotent(actorId, endpoint, idempotencyKey, 200, dto);
        return dto;
    }

    @Transactional
    public PublicLinkDto unpublish(CurrentUser caller, String jobId, String reason) {
        String workshopId = requireWorkshop(caller);
        JobRow job = requireJob(workshopId, jobId);
        if (!"PUBLISHED".equals(job.status())) {
            throw new ApiException(HttpStatus.CONFLICT, "JOB_NOT_PUBLISHED",
                    "error.job.publishState", "Job is not published");
        }
        String value = requireReason(reason);
        LinkRow link = store.activeLink(jobId).orElse(null);
        if (link != null) {
            store.revokeLink(link.id(), value);
        }
        int updated = store.updatePublication(jobId, job.version(), "UNPUBLISHED", "APPROVED");
        if (updated == 0) {
            throw ApiException.versionConflict("The job was modified by someone else");
        }
        store.insertHistory(jobId, job.status(), "APPROVED", caller.userId().toString(),
                "Unpublished: " + value);
        audit.record(caller, "JOB_UNPUBLISHED", "JOB", jobId,
                Map.of("publicationStatus", job.publicationStatus()),
                Map.of("publicationStatus", "UNPUBLISHED"), value, null);
        outbox.publish("JOB", jobId, "JOB_UNPUBLISHED", Map.of("jobId", jobId, "reason", value));
        return linkDto(requireJob(workshopId, jobId), store.latestLink(jobId).orElse(null), false);
    }

    @Transactional
    public PublicLinkDto revoke(CurrentUser caller, String jobId, String reason) {
        String workshopId = requireWorkshop(caller);
        JobRow job = requireJob(workshopId, jobId);
        if (!"PUBLISHED".equals(job.status())) {
            throw new ApiException(HttpStatus.CONFLICT, "JOB_NOT_PUBLISHED",
                    "error.job.publishState", "Job is not published");
        }
        String value = requireReason(reason);
        LinkRow link = store.activeLink(jobId).orElseThrow(
                () -> new ApiException(HttpStatus.CONFLICT, "LINK_NOT_ACTIVE",
                        "error.job.linkNotActive", "The public link is not active"));
        store.revokeLink(link.id(), value);
        int updated = store.updatePublication(jobId, job.version(), "REVOKED", "PUBLISHED");
        if (updated == 0) {
            throw ApiException.versionConflict("The job was modified by someone else");
        }
        store.insertHistory(jobId, job.status(), "PUBLISHED", caller.userId().toString(),
                "Revoked: " + value);
        audit.record(caller, "PUBLIC_LINK_REVOKED", "JOB", jobId,
                Map.of("publicationStatus", job.publicationStatus()),
                Map.of("publicationStatus", "REVOKED"), value, null);
        outbox.publish("JOB", jobId, "PUBLIC_LINK_REVOKED", Map.of("jobId", jobId, "reason", value));
        return linkDto(requireJob(workshopId, jobId), store.latestLink(jobId).orElse(null), false);
    }

    @Transactional
    public PublicLinkDto rotateToken(CurrentUser caller, String jobId) {
        String workshopId = requireWorkshop(caller);
        JobRow job = requireJob(workshopId, jobId);
        if (!"PUBLISHED".equals(job.status())) {
            throw new ApiException(HttpStatus.CONFLICT, "JOB_NOT_PUBLISHED",
                    "error.job.publishState", "Job is not published");
        }
        LinkRow link = store.activeLink(jobId).orElseThrow(
                () -> new ApiException(HttpStatus.CONFLICT, "LINK_NOT_ACTIVE",
                        "error.job.linkNotActive", "The public link is not active"));
        String token = tokens.newToken();
        store.rotateLink(link.id(), tokens.hash(token), tokens.encrypt(token));
        audit.record(caller, "PUBLIC_LINK_ROTATED", "JOB", jobId, null, null, null, null);
        outbox.publish("JOB", jobId, "PUBLIC_LINK_ROTATED", Map.of("jobId", jobId));
        return linkDto(job, store.activeLink(jobId).orElseThrow(), true);
    }

    @Transactional(readOnly = true)
    public PublicLinkDto publicLink(CurrentUser caller, String jobId) {
        String workshopId = requireWorkshop(caller);
        JobRow job = requireJob(workshopId, jobId);
        LinkRow link = store.latestLink(jobId).orElse(null);
        return linkDto(job, link, link != null && "ACTIVE".equals(link.status()));
    }

    @Transactional(readOnly = true)
    public byte[] qr(CurrentUser caller, String jobId) {
        String workshopId = requireWorkshop(caller);
        JobRow job = requireJob(workshopId, jobId);
        LinkRow link = store.activeLink(jobId).orElseThrow(
                () -> new ApiException(HttpStatus.CONFLICT, "LINK_NOT_ACTIVE",
                        "error.job.linkNotActive", "The public link is not active"));
        String token = tokens.decrypt(link.tokenEncrypted());
        if (token == null) {
            throw new ApiException(HttpStatus.CONFLICT, "LINK_NOT_ACTIVE",
                    "error.job.linkNotActive", "The public link token is unavailable");
        }
        return qr.png(publicUrl(token), 360);
    }

    // ------------------------------------------------------------ documents

    @Transactional(readOnly = true)
    public List<ReportDocumentDto> documents(CurrentUser caller, String jobId) {
        String workshopId = requireWorkshop(caller);
        requireJob(workshopId, jobId);
        return store.latestReportVersion(jobId)
                .map(version -> store.documents(version.id()).stream()
                        .map(row -> documentDto(jobId, row)).toList())
                .orElseGet(List::of);
    }

    @Transactional
    public List<ReportDocumentDto> retryDocument(CurrentUser caller, String jobId, String type) {
        String workshopId = requireWorkshop(caller);
        JobRow job = requireJob(workshopId, jobId);
        ReportVersionRow version = store.latestReportVersion(jobId).orElseThrow(
                () -> new ApiException(HttpStatus.NOT_FOUND, "REPORT_VERSION_MISSING",
                        "error.job.documentNotFound", "The report has not been approved yet"));
        List<DocumentRow> rows = documents.retry(job, version.id(), type);
        audit.record(caller, "REPORT_DOCUMENT_RETRIED", "JOB", jobId, null,
                Map.of("documentType", type, "documents", rows.size()), null, null);
        return rows.stream().map(row -> documentDto(jobId, row)).toList();
    }

    @Transactional(readOnly = true)
    public DocumentContent documentContent(CurrentUser caller, String jobId, String documentId) {
        String workshopId = requireWorkshop(caller);
        JobRow job = requireJob(workshopId, jobId);
        DocumentRow row = store.document(documentId).orElseThrow(
                () -> new ApiException(HttpStatus.NOT_FOUND, "DOCUMENT_NOT_FOUND",
                        "error.job.documentNotFound", "Document not found"));
        ReportVersionRow version = store.latestReportVersion(jobId).orElseThrow(
                () -> new ApiException(HttpStatus.NOT_FOUND, "REPORT_VERSION_MISSING",
                        "error.job.documentNotFound", "The report has not been approved yet"));
        if (!version.id().equals(row.reportVersionId())) {
            throw new ApiException(HttpStatus.NOT_FOUND, "DOCUMENT_NOT_FOUND",
                    "error.job.documentNotFound", "Document not found");
        }
        String filename = row.documentTypeCode() + "-" + row.language() + ".pdf";
        return new DocumentContent(documents.content(row), filename);
    }

    // -------------------------------------------------------- notifications

    @Transactional(readOnly = true)
    public List<NotificationDto> notifications(CurrentUser caller, boolean unreadOnly) {
        String workshopId = requireWorkshop(caller);
        return store.notifications(workshopId, caller.userId().toString(), unreadOnly).stream()
                .map(this::notificationDto)
                .toList();
    }

    @Transactional
    public NotificationDto markNotificationRead(CurrentUser caller, String notificationId) {
        String workshopId = requireWorkshop(caller);
        NotificationRow row = store.notification(workshopId, caller.userId().toString(),
                        notificationId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                        "NOTIFICATION_NOT_FOUND", "error.notification.notFound",
                        "Notification not found"));
        store.markNotificationRead(notificationId);
        return notificationDto(store.notification(workshopId, caller.userId().toString(),
                notificationId).orElse(row));
    }

    // -------------------------------------------------------------- helpers

    public record DocumentContent(byte[] bytes, String filename) {
    }

    private record ScoreResult(Integer score, String grade, boolean capApplied, String capReason) {
    }

    private record Evaluation(List<ChecklistItemDto> items, boolean ready, int assessed, int total,
                              ScoreResult score) {
    }

    private String requireWorkshop(CurrentUser caller) {
        if (!caller.isWorkshopAdmin() || caller.workshopId() == null) {
            throw ApiException.forbidden();
        }
        return caller.workshopId().toString();
    }

    private JobRow requireJob(String workshopId, String jobId) {
        return store.findJob(workshopId, jobId)
                .orElseThrow(() -> notFound("JOB_NOT_FOUND", "error.job.notFound", "Job not found"));
    }

    private TemplateVersionRow requirePublishedTemplate(String versionId) {
        if (isBlank(versionId)) {
            throw ApiException.validation("TEMPLATE_REQUIRED", "Template is required",
                    List.of(field("templateVersionId", "REQUIRED")));
        }
        TemplateVersionRow template = store.templateVersion(versionId)
                .orElseThrow(() -> notFound("TEMPLATE_NOT_FOUND", "error.template.notFound",
                        "Template not found"));
        if (!"PUBLISHED".equals(template.status())) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "TEMPLATE_NOT_PUBLISHED",
                    "error.job.templateNotPublished", "The template must be published");
        }
        return template;
    }

    private String requireActiveTechnician(String workshopId, String technicianId) {
        UUID userId;
        try {
            userId = UUID.fromString(technicianId);
        } catch (IllegalArgumentException exception) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "TECHNICIAN_NOT_FOUND",
                    "error.job.technicianNotActive", "Technician is not active in this workshop");
        }
        WorkshopMembership membership = memberships.findByWorkshopIdAndUserId(
                        UUID.fromString(workshopId), userId)
                .filter(value -> "ACTIVE".equals(value.getStatus()))
                .filter(value -> value.getRole() == WorkshopRole.TECHNICIAN)
                .orElseThrow(() -> new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                        "TECHNICIAN_NOT_FOUND", "error.job.technicianNotActive",
                        "Technician is not active in this workshop"));
        return membership.getUserId().toString();
    }

    private List<FieldIssue> validateVehicle(String customerName, String customerPhone,
                                             String customerEmail, String vin, String make,
                                             String model, Integer year, String plate,
                                             Integer odometer, String odometerUnit,
                                             String transmission, String fuel,
                                             String preferredLanguage) {
        List<FieldIssue> issues = new ArrayList<>();
        required(issues, "customerName", customerName);
        required(issues, "customerPhone", customerPhone);
        if (!isBlank(customerEmail) && !customerEmail.contains("@")) {
            issues.add(field("customerEmail", "EMAIL_INVALID"));
        }
        required(issues, "vehicleVin", vin);
        if (!isBlank(vin) && !vin.trim().matches("[A-HJ-NPR-Z0-9]{17}")) {
            issues.add(field("vehicleVin", "VIN_INVALID"));
        }
        required(issues, "vehicleMake", make);
        required(issues, "vehicleModel", model);
        if (year == null || year < 1900 || year > 2100) {
            issues.add(field("vehicleYear", "YEAR_INVALID"));
        }
        required(issues, "vehiclePlate", plate);
        if (odometer == null || odometer < 0) {
            issues.add(field("odometerValue", "ODOMETER_INVALID"));
        }
        required(issues, "odometerUnit", odometerUnit);
        required(issues, "transmission", transmission);
        required(issues, "fuelType", fuel);
        String language = normalizeLanguage(preferredLanguage);
        if (!LANGUAGES.contains(language)) {
            issues.add(field("preferredLanguage", "LANGUAGE_INVALID"));
        }
        return issues;
    }

    private static void required(List<FieldIssue> issues, String field, String value) {
        if (isBlank(value)) {
            issues.add(field(field, "REQUIRED"));
        }
    }

    private static FieldIssue field(String field, String code) {
        return FieldIssue.of(field, code, "error.field.invalid");
    }

    private Evaluation evaluate(CurrentUser caller, JobRow job, String safetyCapReason) {
        List<TemplateItemRow> items = store.templateItems(job.templateVersionId());
        Map<String, ResultRow> results = resultsByItem(job.id());
        int assessed = 0;
        boolean evidenceOk = true;
        for (TemplateItemRow item : items) {
            ResultRow result = results.get(item.itemVersionId());
            if (result != null) {
                assessed++;
                if (!evidenceSatisfied(item, result)) {
                    evidenceOk = false;
                }
            }
        }
        boolean allAssessed = !items.isEmpty() && assessed == items.size();
        ScoreResult score = computeScore(job, items, results);
        boolean signature = job.signaturePresent();
        boolean consent = job.consentGranted();
        boolean approverOk = caller.userId().toString().equals(job.assignedTechnicianId()) == false;
        boolean capOk = !score.capApplied() || !isBlank(safetyCapReason);
        List<ChecklistItemDto> checklist = List.of(
                checklist("ALL_ITEMS_ASSESSED", allAssessed,
                        "All configured items are assessed",
                        "تم تقييم جميع العناصر المهيأة"),
                checklist("EVIDENCE_RULES_MET", evidenceOk,
                        "Every finding meets the photo/video evidence rules",
                        "كل نتيجة تحقق قواعد أدلة الصور والفيديو"),
                checklist("SIGNATURE_PRESENT", signature,
                        "Technician signature is present",
                        "توقيع الفني موجود"),
                checklist("SCORE_COMPUTED", score.score() != null && score.grade() != null,
                        "Score and grade are computed",
                        "تم احتساب النتيجة والدرجة"),
                checklist("SAFETY_CAP_EXPLAINED", capOk,
                        "Safety cap explanation is provided when required",
                        "تم تقديم تفسير حد السلامة عند الحاجة"),
                checklist("CONSENT_GRANTED", consent,
                        "Public-link consent is granted",
                        "تم منح الموافقة على الرابط العام"),
                checklist("APPROVER_NOT_TECHNICIAN", approverOk,
                        "Approver is a Workshop Admin and not the technician",
                        "المعتمد مدير ورشة وليس الفني"),
                checklist("DOCUMENTS_QUEUED", true,
                        "EN and AR documents will be generated after publish",
                        "سيتم إنشاء مستندات الإنجليزية والعربية بعد النشر"));
        boolean ready = checklist.stream().allMatch(ChecklistItemDto::passed);
        return new Evaluation(checklist, ready, assessed, items.size(), score);
    }

    private boolean evidenceSatisfied(TemplateItemRow item, ResultRow result) {
        String code = result.resultCode();
        int defaultPhotos = "DEFECT_FOUND".equals(code) ? 2 : 1;
        int defaultVideos = 1;
        var rule = store.evidenceRule(item.itemVersionId(), code);
        int requiredPhotos = rule.map(value -> Math.max(defaultPhotos, value.minPhotos()))
                .orElse(defaultPhotos);
        int requiredVideos = rule.map(value -> Math.max(defaultVideos, value.minVideos()))
                .orElse(defaultVideos);
        return result.evidencePhotoCount() >= requiredPhotos
                && result.evidenceVideoCount() >= requiredVideos;
    }

    private ScoreResult computeScore(JobRow job) {
        List<TemplateItemRow> items = store.templateItems(job.templateVersionId());
        return computeScore(job, items, resultsByItem(job.id()));
    }

    private ScoreResult computeScore(JobRow job, List<TemplateItemRow> items,
                                     Map<String, ResultRow> results) {
        if (items.isEmpty()) {
            return new ScoreResult(null, null, false, null);
        }
        Map<String, List<Integer>> categoryScores = new LinkedHashMap<>();
        Map<String, java.math.BigDecimal> categoryWeights = new LinkedHashMap<>();
        List<String> safetyFailures = new ArrayList<>();
        boolean safetyFail = false;
        for (TemplateItemRow item : items) {
            ResultRow result = results.get(item.itemVersionId());
            if (result == null || result.score() == null) {
                return new ScoreResult(null, null, false, null);
            }
            categoryScores.computeIfAbsent(item.categoryId(), ignored -> new ArrayList<>())
                    .add(result.score());
            categoryWeights.putIfAbsent(item.categoryId(), store.categoryWeight(item.categoryId()));
            if (item.safetyCritical() && "DEFECT_FOUND".equals(result.resultCode())) {
                safetyFail = true;
                safetyFailures.add(item.stableCode());
            }
        }
        java.math.BigDecimal weightTotal = categoryWeights.values().stream()
                .reduce(java.math.BigDecimal.ZERO, java.math.BigDecimal::add);
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
        Optional<ScoringRuleRow> rule = store.activeScoringRule();
        boolean capApplied = false;
        String capReason = null;
        if (safetyFail) {
            capApplied = true;
            capReason = "Safety-critical item failed: " + String.join(", ", safetyFailures);
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

    private Map<String, ResultRow> resultsByItem(String jobId) {
        Map<String, ResultRow> result = new LinkedHashMap<>();
        for (ResultRow row : store.results(jobId)) {
            result.put(row.itemVersionId(), row);
        }
        return result;
    }

    private ChecklistItemDto checklist(String code, boolean passed, String en, String ar) {
        return new ChecklistItemDto(code, passed, en, ar);
    }

    private JobDto jobDto(JobRow job) {
        TemplateVersionRow template = store.templateVersion(job.templateVersionId()).orElse(null);
        String technicianName = displayName(job.assignedTechnicianId());
        return new JobDto(job.id(), job.reference(), job.status(), job.reviewStatus(),
                job.publicationStatus(), job.templateVersionId(),
                template == null ? null : template.nameEn(),
                template == null ? null : template.nameAr(),
                template == null ? null : template.versionNo(),
                job.assignedTechnicianId(), technicianName, job.customerName(),
                job.customerPhone(), job.customerEmail(), job.vehicleVin(), job.vehicleMake(),
                job.vehicleModel(), job.vehicleYear(), job.vehiclePlate(), job.odometerValue(),
                job.odometerUnit(), job.transmission(), job.fuelType(), job.preferredLanguage(),
                str(job.scheduledAt()), str(job.startedAt()), str(job.completedAt()),
                str(job.approvedAt()), str(job.publishedAt()), str(job.cancelledAt()),
                job.approvedBy(), job.cancelledBy(), job.cancelReason(), job.score(),
                job.gradeCode(), job.safetyCapApplied(), job.safetyCapReason(),
                job.consentGranted(), job.signaturePresent(), str(job.createdAt()),
                str(job.updatedAt()), job.version());
    }

    private TemplateItemDto templateItemDto(TemplateItemRow item) {
        return new TemplateItemDto(item.itemVersionId(), item.stableCode(), item.labelEn(),
                item.labelAr(), item.categoryId(), item.categoryNameEn(), item.categoryNameAr(),
                item.safetyCritical(), item.measurementUnit(), item.sortOrder());
    }

    private AssignmentDto assignmentDto(AssignmentRow row) {
        return new AssignmentDto(row.id(), row.technicianId(),
                displayName(row.technicianId()), row.assignedBy(), str(row.assignedAt()),
                str(row.unassignedAt()), row.reason());
    }

    private PublicLinkDto linkDto(JobRow job, LinkRow link, boolean includeToken) {
        if (link == null) {
            return new PublicLinkDto(job.id(), "PENDING", null, null, qrPath(job.id()), false,
                    null, null, null);
        }
        String token = includeToken ? tokens.decrypt(link.tokenEncrypted()) : null;
        return new PublicLinkDto(job.id(), link.status(),
                token == null ? null : publicUrl(token), token, qrPath(job.id()),
                link.pdfDownloadEnabled(), str(link.activatedAt()), str(link.revokedAt()),
                link.revocationReason());
    }

    private ReportDocumentDto documentDto(String jobId, DocumentRow row) {
        return new ReportDocumentDto(row.id(), row.documentTypeCode(), row.nameEn(), row.nameAr(),
                row.language(), row.status(), row.bytes(), str(row.generatedAt()), row.error(),
                "/api/v1/workshop/jobs/" + jobId + "/documents/" + row.id() + "/content");
    }

    private NotificationDto notificationDto(NotificationRow row) {
        return new NotificationDto(row.id(), row.type(), row.payloadJson(), str(row.readAt()),
                str(row.createdAt()));
    }

    private String publicUrl(String token) {
        return publicBaseUrl + "/r/" + token;
    }

    private String qrPath(String jobId) {
        return "/api/v1/workshop/jobs/" + jobId + "/qr";
    }

    private String snapshot(JobRow job, Evaluation evaluation, ScoreResult score) {
        Map<String, Object> snapshot = new LinkedHashMap<>();
        snapshot.put("jobId", job.id());
        snapshot.put("reference", job.reference());
        snapshot.put("workshopId", job.workshopId());
        snapshot.put("templateVersionId", job.templateVersionId());
        snapshot.put("customerName", job.customerName());
        snapshot.put("vehicleVin", job.vehicleVin());
        snapshot.put("vehicleMake", job.vehicleMake());
        snapshot.put("vehicleModel", job.vehicleModel());
        snapshot.put("vehicleYear", job.vehicleYear());
        snapshot.put("preferredLanguage", job.preferredLanguage());
        snapshot.put("score", score.score());
        snapshot.put("gradeCode", score.grade());
        snapshot.put("safetyCapApplied", score.capApplied());
        snapshot.put("safetyCapReason", score.capReason());
        snapshot.put("itemsAssessed", evaluation.assessed());
        snapshot.put("itemsTotal", evaluation.total());
        snapshot.put("findings", store.results(job.id()).stream().map(result -> Map.of(
                "itemVersionId", result.itemVersionId(),
                "resultCode", result.resultCode(),
                "score", result.score() == null ? 0 : result.score())).toList());
        snapshot.put("createdAt", LocalDateTime.now(ZoneOffset.UTC).toString());
        return json(snapshot);
    }

    private void notify(String workshopId, String userId, String type, Map<String, ?> payload) {
        if (userId == null) {
            return;
        }
        store.insertNotification(workshopId, userId, type, json(payload));
    }

    private String displayName(String userId) {
        if (isBlank(userId)) {
            return null;
        }
        try {
            return users.findById(UUID.fromString(userId)).map(User::getDisplayName).orElse(null);
        } catch (IllegalArgumentException exception) {
            return null;
        }
    }

    private void checkVersion(JobRow job, Integer version) {
        if (version != null && version != job.version()) {
            throw ApiException.versionConflict("The job was modified by someone else");
        }
    }

    private static String requireReason(String reason) {
        if (isBlank(reason)) {
            throw ApiException.validation("REASON_REQUIRED", "A reason is required",
                    List.of(field("reason", "REQUIRED")));
        }
        return reason.trim();
    }

    private String validateStatus(String status) {
        String value = status == null ? "" : status.trim().toUpperCase(Locale.ROOT);
        if (!value.isEmpty() && !STATUSES.contains(value)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "INVALID_FILTER",
                    "error.status.invalid", "Invalid job status filter");
        }
        return value;
    }

    private String reference(String workshopId) {
        for (int attempt = 0; attempt < 20; attempt++) {
            String candidate = "JOB-" + UuidV7.generate().toString()
                    .replace("-", "").substring(24, 32).toUpperCase(Locale.ROOT);
            if (!store.referenceExists(workshopId, candidate)) {
                return candidate;
            }
        }
        throw new IllegalStateException("Unable to allocate a unique job reference");
    }

    private static LocalDateTime parseDate(String value, boolean startOfDay) {
        if (isBlank(value)) {
            return null;
        }
        try {
            if (value.trim().length() == 10) {
                LocalDate date = LocalDate.parse(value.trim());
                return startOfDay ? date.atStartOfDay() : date.atTime(23, 59, 59);
            }
            return parseDateTime(value);
        } catch (DateTimeParseException exception) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "DATE_INVALID",
                    "error.badRequest", "Invalid date filter");
        }
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
                throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEDULE_INVALID",
                        "error.job.scheduleInvalid", "Scheduled time is invalid");
            }
        }
    }

    private static String normalizeLanguage(String value) {
        return isBlank(value) ? "en" : value.trim().toLowerCase(Locale.ROOT);
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

    private static ApiException notFound(String code, String messageKey, String message) {
        return new ApiException(HttpStatus.NOT_FOUND, code, messageKey, message);
    }

    private String json(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Unable to serialize payload", exception);
        }
    }

    private static String sha256(String value) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8)));
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

    private void storeIdempotent(String actorId, String endpoint, String key, int status,
                                 Object response) {
        idempotency.store(actorId, endpoint, key, status, response);
    }
}
