package com.truereport.jobs;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.identity.User;
import com.truereport.identity.UserRepository;
import com.truereport.jobs.PlatformJobStore.AssignmentRow;
import com.truereport.jobs.PlatformJobStore.ActivityRow;
import com.truereport.jobs.PlatformJobStore.AssignedCountRow;
import com.truereport.jobs.PlatformJobStore.CustomerJobRow;
import com.truereport.jobs.PlatformJobStore.DailyCountRow;
import com.truereport.jobs.PlatformJobStore.DocumentRow;
import com.truereport.jobs.PlatformJobStore.GradeBoundaryRow;
import com.truereport.jobs.PlatformJobStore.JobRow;
import com.truereport.jobs.PlatformJobStore.LinkRow;
import com.truereport.jobs.PlatformJobStore.NotificationRow;
import com.truereport.jobs.PlatformJobStore.QualityRow;
import com.truereport.jobs.PlatformJobStore.ReportCountsRow;
import com.truereport.jobs.PlatformJobStore.ReportItemRow;
import com.truereport.jobs.PlatformJobStore.ReportVersionRow;
import com.truereport.jobs.PlatformJobStore.ResultRow;
import com.truereport.jobs.PlatformJobStore.ScoringRuleRow;
import com.truereport.jobs.PlatformJobStore.TemplateItemRow;
import com.truereport.jobs.PlatformJobStore.TemplateVersionRow;
import com.truereport.jobs.PlatformJobStore.TurnaroundRow;
import com.truereport.jobs.api.WorkshopDashboardDtos.ActivityDto;
import com.truereport.jobs.api.WorkshopDashboardDtos.CustomerLoadDto;
import com.truereport.jobs.api.WorkshopDashboardDtos.CustomerSummaryDto;
import com.truereport.jobs.api.WorkshopDashboardDtos.DailyFlowDto;
import com.truereport.jobs.api.WorkshopDashboardDtos.QualityDto;
import com.truereport.jobs.api.WorkshopDashboardDtos.ReportSummaryDto;
import com.truereport.jobs.api.WorkshopDashboardDtos.StaffLoadDto;
import com.truereport.jobs.api.WorkshopDashboardDtos.StaffSummaryDto;
import com.truereport.jobs.api.WorkshopDashboardDtos.TurnaroundDto;
import com.truereport.jobs.api.WorkshopDashboardDtos.WorkshopDashboardDto;
import com.truereport.jobs.api.WorkshopJobDtos.AllowedActionDto;
import com.truereport.jobs.api.WorkshopJobDtos.ApproveJobRequest;
import com.truereport.jobs.api.WorkshopJobDtos.AssignTechnicianRequest;
import com.truereport.jobs.api.WorkshopJobDtos.AssignmentDto;
import com.truereport.jobs.api.WorkshopJobDtos.AvailableTemplateDto;
import com.truereport.jobs.api.WorkshopJobDtos.CancelJobRequest;
import com.truereport.jobs.api.WorkshopJobDtos.ChecklistItemDto;
import com.truereport.shared.text.CustomerNames;
import com.truereport.jobs.api.WorkshopJobDtos.CreateJobRequest;
import com.truereport.jobs.api.WorkshopJobDtos.JobConsentRequest;
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
import com.truereport.reference.ReferenceRepository;
import com.truereport.reference.ReferenceRepository.TransitionRow;
import com.truereport.shared.audit.FieldAuditService;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import com.truereport.shared.idempotency.IdempotencyService;
import com.truereport.shared.outbox.OutboxService;
import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.time.WallClockTimes;
import com.truereport.shared.uuid.UuidV7;
import com.truereport.tenancy.Workshop;
import com.truereport.tenancy.WorkshopMembership;
import com.truereport.tenancy.WorkshopMembershipRepository;
import com.truereport.tenancy.WorkshopRepository;
import com.truereport.tenancy.WorkshopRole;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
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
    private static final List<String> GRADE_ORDER = List.of("A", "B", "C", "D");

    private static final List<String> ACTION_ORDER = List.of(
            "ASSIGN", "CONSENT", "APPROVE", "REJECT", "PUBLISH",
            "UNPUBLISH", "ROTATE_TOKEN", "REVOKE", "CANCEL");

    private static final Map<String, AllowedActionDto> ACTION_DEFINITIONS = Map.ofEntries(
            Map.entry("ASSIGN", new AllowedActionDto("ASSIGN", "jobsAssignTechnician",
                    "neutral", false, false)),
            Map.entry("CONSENT", new AllowedActionDto("CONSENT", "consentPublicLink",
                    "info", false, false)),
            Map.entry("APPROVE", new AllowedActionDto("APPROVE", "jobsApprove",
                    "success", false, false)),
            Map.entry("REJECT", new AllowedActionDto("REJECT", "jobsReject",
                    "danger", true, false)),
            Map.entry("PUBLISH", new AllowedActionDto("PUBLISH", "jobsPublishNow",
                    "success", false, true)),
            Map.entry("UNPUBLISH", new AllowedActionDto("UNPUBLISH", "jobsUnpublish",
                    "warning", true, false)),
            Map.entry("ROTATE_TOKEN", new AllowedActionDto("ROTATE_TOKEN", "jobsRotateToken",
                    "info", false, false)),
            Map.entry("REVOKE", new AllowedActionDto("REVOKE", "jobsRevoke",
                    "danger", true, false)),
            Map.entry("CANCEL", new AllowedActionDto("CANCEL", "cancelJob",
                    "danger", true, false)));

    private final PlatformJobStore store;
    private final WorkshopMembershipRepository memberships;
    private final WorkshopRepository workshops;
    private final UserRepository users;
    private final FieldAuditService audit;
    private final OutboxService outbox;
    private final IdempotencyService idempotency;
    private final PlatformJobDocumentService documents;
    private final CleanEvidencePublicationService publicEvidence;
    private final PlatformJobTokenService tokens;
    private final ReferenceRepository reference;
    private final PlatformQrService qr;
    private final ObjectMapper objectMapper;
    private final String publicBaseUrl;
    private final com.truereport.shared.i18n.TranslationReviewGate reviewGate;
    private final com.truereport.shared.i18n.LanguageCatalog languageCatalog;
    private final com.truereport.shared.i18n.ContentTranslationService contentTranslations;

    public WorkshopJobAdminService(PlatformJobStore store,
                                      WorkshopMembershipRepository memberships,
                                      WorkshopRepository workshops,
                                      UserRepository users,
                                      FieldAuditService audit,
                                      OutboxService outbox,
                                      IdempotencyService idempotency,
                                      PlatformJobDocumentService documents,
                                      CleanEvidencePublicationService publicEvidence,
                                      PlatformJobTokenService tokens,
                                      PlatformQrService qr,
                                      ReferenceRepository reference,
                                      ObjectMapper objectMapper,
                                      com.truereport.shared.i18n.TranslationReviewGate reviewGate,
                                      com.truereport.shared.i18n.LanguageCatalog languageCatalog,
                                      com.truereport.shared.i18n.ContentTranslationService contentTranslations,
                                      @Value("${truereport.report.public-base-url:http://localhost:8080}")
                                      String publicBaseUrl) {
        this.store = store;
        this.memberships = memberships;
        this.workshops = workshops;
        this.users = users;
        this.audit = audit;
        this.outbox = outbox;
        this.idempotency = idempotency;
        this.documents = documents;
        this.publicEvidence = publicEvidence;
        this.tokens = tokens;
        this.qr = qr;
        this.reference = reference;
        this.objectMapper = objectMapper;
        this.reviewGate = reviewGate;
        this.languageCatalog = languageCatalog;
        this.contentTranslations = contentTranslations;
        this.publicBaseUrl = publicBaseUrl.endsWith("/")
                ? publicBaseUrl.substring(0, publicBaseUrl.length() - 1) : publicBaseUrl;
    }

    // ------------------------------------------------------------- templates

    @Transactional(readOnly = true)
    public List<AvailableTemplateDto> availableTemplates(CurrentUser caller) {
        String workshopId = requireWorkshop(caller);
        return store.availableTemplates(workshopId).stream()
                .map(row -> new AvailableTemplateDto(row.versionId(), row.templateId(), row.code(),
                        row.nameEn(), row.nameAr(), row.versionNo(),
                        store.templateItemCount(row.versionId(), workshopId)))
                .toList();
    }

    @Transactional(readOnly = true)
    public TemplateVersionDetailDto templateVersion(CurrentUser caller, String versionId) {
        String workshopId = requireWorkshop(caller);
        TemplateVersionRow version = store.templateVersion(versionId, workshopId)
                .orElseThrow(() -> notFound("TEMPLATE_NOT_FOUND", "error.template.notFound",
                        "Template not found"));
        List<TemplateItemDto> items = store.templateItems(versionId, workshopId).stream()
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
        return new JobPageDto(rows.stream().map(row -> jobDto(row, caller)).toList(),
                safePage, safeSize, total, totalPages);
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
    public WorkshopDashboardDto dashboard(CurrentUser caller, int days) {
        String workshopId = requireWorkshop(caller);
        int window = Math.min(90, Math.max(1, days));
        LocalDate today = LocalDate.now(WallClockTimes.DUBAI);
        LocalDate fromDay = today.minusDays(window - 1L);
        LocalDateTime from = fromDay.atStartOfDay();

        Map<LocalDate, long[]> byDay = new LinkedHashMap<>();
        for (int index = 0; index < window; index++) {
            byDay.put(fromDay.plusDays(index), new long[2]);
        }
        for (DailyCountRow row : store.createdPerDay(workshopId, from)) {
            long[] cell = byDay.get(row.date());
            if (cell != null) {
                cell[0] = row.count();
            }
        }
        for (DailyCountRow row : store.publishedPerDay(workshopId, from)) {
            long[] cell = byDay.get(row.date());
            if (cell != null) {
                cell[1] = row.count();
            }
        }
        List<DailyFlowDto> trend = new ArrayList<>(window);
        for (Map.Entry<LocalDate, long[]> entry : byDay.entrySet()) {
            trend.add(new DailyFlowDto(entry.getKey().toString(),
                    entry.getValue()[0], entry.getValue()[1]));
        }
        DailyFlowDto todayFlow = trend.isEmpty()
                ? new DailyFlowDto(today.toString(), 0, 0)
                : trend.get(trend.size() - 1);

        long totalMinutes = 0;
        int turnarounds = 0;
        for (TurnaroundRow row : store.completedJobs(workshopId, from)) {
            if (row.startedAt() == null || row.completedAt() == null
                    || row.completedAt().isBefore(row.startedAt())) {
                continue;
            }
            totalMinutes += Math.max(0,
                    Duration.between(row.startedAt(), row.completedAt()).toMinutes());
            turnarounds++;
        }
        Long averageMinutes = turnarounds == 0
                ? null
                : Math.round((double) totalMinutes / turnarounds);

        QualityRow qualityRow = store.quality(workshopId, from);
        QualityDto quality = new QualityDto(
                qualityRow.averageScore() == null
                        ? null
                        : (int) Math.round(qualityRow.averageScore()),
                qualityRow.scoredJobs());

        List<WorkshopMembership> activeStaff =
                memberships.findByWorkshopIdAndStatusOrderByRoleAsc(
                        UUID.fromString(workshopId), "ACTIVE");
        int technicians = (int) activeStaff.stream()
                .filter(member -> member.getRole() == WorkshopRole.TECHNICIAN)
                .count();
        List<AssignedCountRow> openRows = new ArrayList<>(store.openJobsByTechnician(workshopId));
        openRows.sort(Comparator.comparingLong(AssignedCountRow::count).reversed());
        Map<String, Long> completedByTechnician = new LinkedHashMap<>();
        for (AssignedCountRow row : store.completedByTechnician(workshopId, from)) {
            completedByTechnician.put(row.technicianId(), row.count());
        }
        List<StaffLoadDto> topStaff = new ArrayList<>();
        for (AssignedCountRow row : openRows) {
            if (topStaff.size() >= 5) {
                break;
            }
            topStaff.add(new StaffLoadDto(row.technicianId(), displayName(row.technicianId()),
                    row.count(), completedByTechnician.getOrDefault(row.technicianId(), 0L)));
        }
        StaffSummaryDto staff = new StaffSummaryDto(technicians, openRows.size(), topStaff);

        Map<String, Long> byCustomer = new LinkedHashMap<>();
        for (CustomerJobRow row : store.customerJobs(workshopId, from)) {
            String name = row.customerName() == null ? "" : row.customerName().trim();
            if (!name.isEmpty()) {
                byCustomer.merge(name, 1L, Long::sum);
            }
        }
        int served = byCustomer.size();
        int repeat = (int) byCustomer.values().stream().filter(count -> count > 1).count();
        List<CustomerLoadDto> topCustomers = byCustomer.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                .limit(5)
                .map(entry -> new CustomerLoadDto(entry.getKey(), entry.getValue()))
                .toList();
        CustomerSummaryDto customers = new CustomerSummaryDto(served, repeat, topCustomers);

        ReportCountsRow reportCounts = store.reportCounts(workshopId, from);
        ReportSummaryDto reports = new ReportSummaryDto(
                reportCounts.versions(), reportCounts.published(),
                reportCounts.documents(), reportCounts.readyDocuments(),
                reportCounts.failedDocuments(), reportCounts.exportBytes(),
                reportCounts.activeLinks(), reportCounts.revokedLinks());

        List<ActivityDto> activity = store.recentActivity(workshopId, 8).stream()
                .map(row -> new ActivityDto(row.jobId(), str(row.occurredAt()),
                        displayName(row.actorId()), row.fromStatus(), row.toStatus(),
                        row.reference()))
                .toList();

        return new WorkshopDashboardDto(window, WallClockTimes.dubaiNow().toString(),
                todayFlow, trend, new TurnaroundDto(averageMinutes, turnarounds),
                quality, staff, customers, reports, activity);
    }

    @Transactional(readOnly = true)
    public JobDto job(CurrentUser caller, String jobId) {
        String workshopId = requireWorkshop(caller);
        return jobDto(store.findJob(workshopId, jobId)
                .orElseThrow(() -> notFound("JOB_NOT_FOUND", "error.job.notFound",
                        "Job not found")), caller);
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
        TemplateVersionRow template = requirePublishedTemplate(workshopId,
                request.templateVersionId());
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
        JobDto dto = jobDto(created, caller);
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
        return jobDto(updatedRow, caller);
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
        return jobDto(requireJob(workshopId, jobId), caller);
    }

    @Transactional
    public JobDto updateConsent(CurrentUser caller, String jobId, JobConsentRequest request) {
        String workshopId = requireWorkshop(caller);
        JobRow job = requireJob(workshopId, jobId);
        if ("PUBLISHED".equals(job.status()) || "CANCELLED".equals(job.status())) {
            throw new ApiException(HttpStatus.CONFLICT, "JOB_CONSENT_NOT_EDITABLE",
                    "error.job.statusInvalid",
                    "Consent cannot be changed for a published or cancelled job");
        }
        if (request == null || request.consentGranted() == null) {
            throw ApiException.validation("CONSENT_INVALID", "Consent is invalid",
                    List.of(field("consentGranted", "REQUIRED")));
        }
        boolean granted = request.consentGranted();
        int updated = store.setConsent(jobId, job.version(), granted);
        if (updated == 0) {
            throw ApiException.versionConflict("The job was modified by someone else");
        }
        String reason = trimToNull(request.reason());
        store.insertHistory(jobId, job.status(), job.status(), caller.userId().toString(),
                "Consent " + (granted ? "granted" : "withdrawn"));
        audit.record(caller, "JOB_CONSENT_UPDATED", "JOB", jobId,
                Map.of("consentGranted", job.consentGranted()),
                Map.of("consentGranted", granted), reason, null);
        return jobDto(requireJob(workshopId, jobId), caller);
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
        return jobDto(requireJob(workshopId, jobId), caller);
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
        List<TemplateItemRow> items = store.templateItems(job.templateVersionId(), job.workshopId());
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
                score.score(), score.grade(), score.capReason(), findings,
                allowedActions(job, caller));
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
                true, allowedActions(job, caller));
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
                            item.messageEn(), item.messageEn()))
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
        JobDto dto = jobDto(requireJob(workshopId, jobId), caller);
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
        return jobDto(requireJob(workshopId, jobId), caller);
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
            if (request != null && request.pdfDownloadEnabled() != null
                    && request.pdfDownloadEnabled() != active.pdfDownloadEnabled()) {
                store.setPdfDownload(active.id(), request.pdfDownloadEnabled());
                active = store.activeLink(jobId).orElse(active);
            }
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
        // Report language follows the job. The gate is wired here so a localized
        // render enforces reviewed safety-critical copy; document generation
        // writes one row per type in that same language.
        String reportLanguage = reportLanguage(job);
        if (!reportLanguage.equals(languageCatalog.defaultLanguage())) {
            reviewGate.assertJobPublish(store.reportItems(job.id()).stream()
                    .map(ReportItemRow::itemVersionId)
                    .filter(id -> id != null && !id.isBlank())
                    .toList(), reportLanguage);
        }
        ReportVersionRow version = store.latestReportVersion(jobId)
                .orElseThrow(() -> new ApiException(HttpStatus.CONFLICT,
                        "REPORT_VERSION_MISSING", "error.job.publishState",
                        "The approved report version is missing"));
        // The report is the product's output: enable PDF download on first
        // publish unless the caller explicitly turns it off. Re-publishing an
        // already-published job keeps its current value unless the caller sends
        // an explicit flag.
        boolean pdfDownload = request == null || request.pdfDownloadEnabled() == null
                || request.pdfDownloadEnabled();
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
        publicEvidence.prepare(jobId);
        documents.generateForVersion(job, version.id());
        PublicLinkDto dto = linkDto(job, store.activeLink(jobId).orElseThrow(), true);
        storeIdempotent(actorId, endpoint, idempotencyKey, 200, dto);
        return dto;
    }

    private String reportLanguage(JobRow job) {
        String preferred = languageCatalog.normalize(job.preferredLanguage());
        return languageCatalog.isSupported(preferred)
                ? preferred : languageCatalog.defaultLanguage();
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

    private TemplateVersionRow requirePublishedTemplate(String workshopId, String versionId) {
        if (isBlank(versionId)) {
            throw ApiException.validation("TEMPLATE_REQUIRED", "Template is required",
                    List.of(field("templateVersionId", "REQUIRED")));
        }
        TemplateVersionRow template = store.templateVersion(versionId, workshopId)
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
        if (!languageCatalog.isSupported(language)) {
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
        List<TemplateItemRow> items = store.templateItems(job.templateVersionId(), job.workshopId());
        Map<String, ResultRow> results = resultsByItem(job.id());
        int assessed = 0;
        boolean evidenceOk = true;
        for (TemplateItemRow item : items) {
            ResultRow result = results.get(item.itemVersionId());
            if (result != null) {
                assessed++;
                if (!evidenceSatisfied(job, item, result)) {
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
                        "All configured items are assessed"),
                checklist("EVIDENCE_RULES_MET", evidenceOk,
                        "Every finding meets the photo/video evidence rules"),
                checklist("SIGNATURE_PRESENT", signature,
                        "Technician signature is present"),
                checklist("SCORE_COMPUTED", score.score() != null && score.grade() != null,
                        "Score and grade are computed"),
                checklist("SAFETY_CAP_EXPLAINED", capOk,
                        "Safety cap explanation is provided when required"),
                checklist("CONSENT_GRANTED", consent,
                        "Public-link consent is granted"),
                checklist("APPROVER_NOT_TECHNICIAN", approverOk,
                        "Approver is a Workshop Admin and not the technician"),
                checklist("DOCUMENTS_QUEUED", true,
                        "EN and AR documents will be generated after publish"));
        boolean ready = checklist.stream().allMatch(ChecklistItemDto::passed);
        return new Evaluation(checklist, ready, assessed, items.size(), score);
    }

    private boolean evidenceSatisfied(JobRow job, TemplateItemRow item, ResultRow result) {
        String code = result.resultCode();
        int defaultPhotos = "DEFECT_FOUND".equals(code) ? 2 : 1;
        int defaultVideos = 1;
        var rule = store.evidenceRule(job.templateVersionId(), item.itemVersionId(), code,
                job.workshopId());
        int requiredPhotos = rule.map(value -> Math.max(defaultPhotos, value.minPhotos()))
                .orElse(defaultPhotos);
        int requiredVideos = rule.map(value -> Math.max(defaultVideos, value.minVideos()))
                .orElse(defaultVideos);
        return result.evidencePhotoCount() >= requiredPhotos
                && result.evidenceVideoCount() >= requiredVideos;
    }

    private ScoreResult computeScore(JobRow job) {
        List<TemplateItemRow> items = store.templateItems(job.templateVersionId(), job.workshopId());
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
            return defaultGrade(score);
        }
        return store.gradeBoundaries(rule.get().id()).stream()
                .filter(boundary -> score >= boundary.minScore() && score <= boundary.maxScore())
                .min(Comparator.comparingInt(GradeBoundaryRow::sortOrder))
                .map(GradeBoundaryRow::gradeCode)
                .orElseGet(() -> defaultGrade(score));
    }

    /** Approved default thresholds used when no scoring rule is configured. */
    private String defaultGrade(int score) {
        if (score >= 90) {
            return "A";
        }
        if (score >= 80) {
            return "B";
        }
        return score >= 65 ? "C" : "D";
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

    private ChecklistItemDto checklist(String code, boolean passed, String en) {
        return new ChecklistItemDto(code, passed, en);
    }

    private List<AllowedActionDto> allowedActions(JobRow job, CurrentUser caller) {
        if (caller == null || !caller.isWorkshopAdmin()) {
            return List.of();
        }
        LinkedHashSet<String> codes = new LinkedHashSet<>();
        for (TransitionRow transition : reference.findTransitions("job")) {
            if (!job.status().equals(transition.fromCode())
                    || !"WORKSHOP_ADMIN".equals(transition.role())) {
                continue;
            }
            String action = switch (transition.toCode()) {
                case "APPROVED" -> "APPROVE";
                case "REJECTED" -> "REJECT";
                case "PUBLISHED" -> "PUBLISH";
                case "CANCELLED" -> "CANCEL";
                case "SCHEDULED", "ASSIGNED" -> "ASSIGN";
                default -> null;
            };
            if (action != null) {
                codes.add(action);
            }
        }
        if (ASSIGNABLE_STATUSES.contains(job.status())) {
            codes.add("ASSIGN");
        }
        if (!"PUBLISHED".equals(job.status()) && !"CANCELLED".equals(job.status())) {
            codes.add("CONSENT");
        }
        if ("PUBLISHED".equals(job.status())) {
            codes.add("UNPUBLISH");
            codes.add("ROTATE_TOKEN");
            codes.add("REVOKE");
        }
        List<AllowedActionDto> actions = new ArrayList<>();
        for (String code : ACTION_ORDER) {
            if (codes.contains(code)) {
                actions.add(ACTION_DEFINITIONS.get(code));
            }
        }
        return List.copyOf(actions);
    }

    private JobDto jobDto(JobRow job, CurrentUser caller) {
        TemplateVersionRow template = store.templateVersion(job.templateVersionId(),
                job.workshopId()).orElse(null);
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
                str(job.updatedAt()), job.version(), allowedActions(job, caller));
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

    /**
     * Build the normalized {@code ReportSnapshot} shape that
     * {@code ReportViewMapper.publicPage} deserializes. The previous version
     * stored a job/findings summary, which produced an empty or failing public
     * report. Only allowlisted display data is stored; VIN is masked and customer
     * contact fields are not written.
     */
    private String snapshot(JobRow job, Evaluation evaluation, ScoreResult score) {
        String language = reportLanguage(job);
        List<ReportItemRow> rows = store.reportItems(job.id());
        Map<String, List<ReportItemRow>> grouped = new LinkedHashMap<>();
        for (ReportItemRow row : rows) {
            grouped.computeIfAbsent(row.categoryEn(), ignored -> new ArrayList<>()).add(row);
        }
        List<Map<String, Object>> categories = new ArrayList<>();
        List<Map<String, Object>> keyFindings = new ArrayList<>();
        for (Map.Entry<String, List<ReportItemRow>> entry : grouped.entrySet()) {
            List<Map<String, Object>> items = new ArrayList<>();
            for (ReportItemRow row : entry.getValue()) {
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("stableCode", row.itemCode());
                item.put("labelEn", row.labelEn());
                item.put("label", contentTranslations.resolve("ITEM", row.itemVersionId(),
                        "label", language, row.labelEn()));
                item.put("instructionEn", row.instructionEn());
                item.put("instruction", contentTranslations.resolve("ITEM", row.itemVersionId(),
                        "instruction", language, row.instructionEn()));
                item.put("standardSpec", contentTranslations.resolve("ITEM",
                        row.itemVersionId(), "standardSpec", language, row.standardSpecEn()));
                item.put("resultCode", row.resultCode());
                item.put("severityCode", row.severityCode());
                item.put("note", row.notesEn() == null ? "" : row.notesEn());
                item.put("noteLanguage", "en");
                item.put("reasonCode", row.reasonCode() == null ? "" : row.reasonCode());
                item.put("reasonText", row.reasonCode() == null ? "" : row.reasonCode());
                item.put("evidenceIds", store.reportEvidenceIds(job.id(), row.itemCode()));
                item.put("measurements", store.reportMeasurements(job.id(), row.itemCode())
                        .stream().map(measurement -> {
                            Map<String, Object> value = new LinkedHashMap<>();
                            value.put("fieldCode", measurement.fieldCode());
                            value.put("valueIndex", measurement.valueIndex());
                            value.put("numericValue", measurement.numericValue());
                            value.put("unitCode", measurement.unitCode());
                            value.put("resultCode", measurement.resultCode());
                            value.put("score", measurement.score());
                            return value;
                        }).toList());
                items.add(item);
                if ("DEFECT_FOUND".equals(row.resultCode())
                        || "ATTENTION_RECOMMENDED".equals(row.resultCode())) {
                    keyFindings.add(item);
                }
            }
            Map<String, Object> category = new LinkedHashMap<>();
            category.put("labelEn", entry.getKey());
            ReportItemRow first = entry.getValue().get(0);
            category.put("label", contentTranslations.resolve("CATEGORY", first.categoryId(),
                    "name", language, entry.getKey()));
            category.put("items", items);
            categories.add(category);
        }
        keyFindings.sort(Comparator.comparingInt(item ->
                severityRank((String) item.get("severityCode"))));

        Map<String, Object> vehicle = new LinkedHashMap<>();
        vehicle.put("make", job.vehicleMake());
        vehicle.put("model", job.vehicleModel());
        vehicle.put("year", job.vehicleYear());
        vehicle.put("vinMasked", maskVin(job.vehicleVin()));
        vehicle.put("odometerValue", job.odometerValue());
        vehicle.put("odometerUnit", job.odometerUnit());
        vehicle.put("vehicleType", null);
        vehicle.put("transmission", job.transmission());
        vehicle.put("fuelType", job.fuelType());

        Map<String, Object> inspection = new LinkedHashMap<>();
        inspection.put("scope", "Inspection");
        inspection.put("templateVersionNo", store.templateVersion(job.templateVersionId(),
                        job.workshopId())
                .map(TemplateVersionRow::versionNo).orElse(null));
        inspection.put("dateTime", str(job.completedAt()));

        String workshopName = null;
        String workshopBranch = null;
        try {
            Workshop workshop = workshops.findById(UUID.fromString(job.workshopId())).orElse(null);
            if (workshop != null) {
                workshopName = workshop.getName();
                workshopBranch = workshop.getBranchName();
            }
        } catch (IllegalArgumentException ignored) {
            // Legacy/non-UUID workshop id: leave the display fields blank.
        }

        Map<String, Object> workshopMap = new LinkedHashMap<>();
        workshopMap.put("name", workshopName);
        workshopMap.put("branch", workshopBranch);

        Map<String, Object> technician = new LinkedHashMap<>();
        technician.put("displayName", displayName(job.assignedTechnicianId()));

        Map<String, Object> coverage = new LinkedHashMap<>();
        coverage.put("total", rows.size());
        coverage.put("applicable", rows.size());
        coverage.put("completed", rows.size());
        coverage.put("notApplicable", 0);
        coverage.put("notChecked", 0);
        coverage.put("couldNotVerify", 0);

        Map<String, Object> summary = summary(job, evaluation);

        Map<String, Object> snapshot = new LinkedHashMap<>();
        snapshot.put("reportNumber", job.reference());
        snapshot.put("reportVersion", 1);
        snapshot.put("finalizedAt", str(job.completedAt()));
        snapshot.put("publishedAt", "");
        snapshot.put("vehicle", vehicle);
        snapshot.put("inspection", inspection);
        snapshot.put("workshop", workshopMap);
        snapshot.put("technician", technician);
        snapshot.put("customerName", CustomerNames.mask(job.customerName()));
        snapshot.put("coverage", coverage);
        snapshot.put("summary", summary);
        snapshot.put("score", score.score());
        snapshot.put("gradeCode", score.grade());
        snapshot.put("safetyCapApplied", score.capApplied());
        snapshot.put("safetyCapReason", score.capReason());
        snapshot.put("keyFindings", keyFindings);
        snapshot.put("categories", categories);
        snapshot.put("notChecked", List.of());
        snapshot.put("limitations", List.of());
        snapshot.put("disclaimer", "");
        snapshot.put("verificationHash",
                sha256(job.id() + "|" + job.reference() + "|" + score.score()));
        snapshot.put("language", language);
        return json(snapshot);
    }

    private static int severityRank(String severity) {
        return switch (severity == null ? "" : severity) {
            case "SAFETY_CRITICAL" -> 0;
            case "MAJOR" -> 1;
            case "MODERATE" -> 2;
            case "MINOR" -> 3;
            default -> 4;
        };
    }

    /**
     * Headline report figures, computed from the same item/result data the
     * score engine uses, so the report and the review endpoint cannot drift.
     */
    private Map<String, Object> summary(JobRow job, Evaluation evaluation) {
        List<TemplateItemRow> items = store.templateItems(job.templateVersionId(), job.workshopId());
        Map<String, ResultRow> results = resultsByItem(job.id());
        int findingsCount = 0;
        int safetyCriticalCount = 0;
        int passedCount = 0;
        for (TemplateItemRow item : items) {
            ResultRow result = results.get(item.itemVersionId());
            if (result == null) {
                continue;
            }
            String code = result.resultCode();
            if ("NO_ISSUE_OBSERVED".equals(code)) {
                passedCount++;
            }
            if ("DEFECT_FOUND".equals(code) || "ATTENTION_RECOMMENDED".equals(code)) {
                findingsCount++;
            }
            if (item.safetyCritical() && "DEFECT_FOUND".equals(code)) {
                safetyCriticalCount++;
            }
        }
        double coveragePercent = evaluation.total() == 0 ? 0.0
                : Math.round(evaluation.assessed() * 1000.0 / evaluation.total()) / 10.0;
        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("findingsCount", findingsCount);
        summary.put("safetyCriticalCount", safetyCriticalCount);
        summary.put("passedCount", passedCount);
        summary.put("coveragePercent", coveragePercent);
        return summary;
    }

    private static String maskVin(String vin) {
        if (vin == null || vin.isBlank()) {
            return "";
        }
        String clean = vin.trim();
        return clean.length() <= 4 ? "****" : "****" + clean.substring(clean.length() - 4);
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
            return WallClockTimes.parse(value);
        } catch (DateTimeParseException exception) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEDULE_INVALID",
                    "error.job.scheduleInvalid", "Scheduled time is invalid");
        }
    }

    private String normalizeLanguage(String value) {
        return isBlank(value) ? languageCatalog.defaultLanguage()
                : languageCatalog.normalize(value);
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
