package com.truereport.jobs;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.audit.AuditService;
import com.truereport.identity.User;
import com.truereport.identity.UserRepository;
import com.truereport.jobs.api.AssignJobRequest;
import com.truereport.jobs.api.CancelJobRequest;
import com.truereport.jobs.api.JobAssignmentDto;
import com.truereport.jobs.api.JobCreateRequest;
import com.truereport.jobs.api.JobDto;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.uuid.UuidV7;
import com.truereport.templates.TemplateVersionInfo;
import com.truereport.templates.WorkshopTemplateService;
import com.truereport.tenancy.WorkshopMembership;
import com.truereport.tenancy.WorkshopMembershipRepository;
import com.truereport.tenancy.WorkshopRole;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Service
public class WorkshopJobService {

    private static final Set<String> STATUSES = Set.of(
            "DRAFT", "SCHEDULED", "ASSIGNED", "IN_PROGRESS",
            "READY_TO_FINALIZE", "FINALIZED", "CANCELLED");

    private final InspectionJobRepository jobs;
    private final JobAssignmentRepository assignments;
    private final WorkshopMembershipRepository memberships;
    private final UserRepository users;
    private final WorkshopTemplateService templates;
    private final AuditService auditService;
    private final ObjectMapper objectMapper;

    public WorkshopJobService(InspectionJobRepository jobs,
                              JobAssignmentRepository assignments,
                              WorkshopMembershipRepository memberships,
                              UserRepository users,
                              WorkshopTemplateService templates,
                              AuditService auditService,
                              ObjectMapper objectMapper) {
        this.jobs = jobs;
        this.assignments = assignments;
        this.memberships = memberships;
        this.users = users;
        this.templates = templates;
        this.auditService = auditService;
        this.objectMapper = objectMapper;
    }

    @Transactional(readOnly = true)
    public List<JobDto> list(CurrentUser caller, String search, String status) {
        UUID workshopId = requireWorkshopAdmin(caller);
        String query = search == null ? "" : search.trim().toLowerCase();
        String filter = validateStatus(status);
        return jobs.findByWorkshopIdOrderByCreatedAtDesc(workshopId).stream()
                .filter(job -> filter.isEmpty() || job.getStatus().equals(filter))
                .filter(job -> matches(job, query))
                .map(this::dto)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<JobDto> technicianJobs(CurrentUser caller) {
        if (!caller.isTechnician() || caller.workshopId() == null) {
            throw ApiException.notFound();
        }
        Set<InspectionJob> result = new LinkedHashSet<>(
                jobs.findByWorkshopIdAndAssignedTechnicianIdOrderByScheduledAtAsc(
                        caller.workshopId(), caller.userId()));
        result.addAll(jobs.findByWorkshopIdAndCreatedByOrderByCreatedAtDesc(
                caller.workshopId(), caller.userId()));
        return result.stream().map(this::dto).toList();
    }

    @Transactional(readOnly = true)
    public JobDto technicianJob(CurrentUser caller, UUID jobId) {
        if (!caller.isTechnician() || caller.workshopId() == null) {
            throw ApiException.notFound();
        }
        InspectionJob job = jobs.findByIdAndWorkshopId(jobId, caller.workshopId())
                .orElseThrow(ApiException::notFound);
        if (!caller.userId().equals(job.getAssignedTechnicianId())
                && !caller.userId().equals(job.getCreatedBy())) {
            throw ApiException.notFound();
        }
        return dto(job);
    }

    @Transactional
    public JobDto create(CurrentUser caller, JobCreateRequest request) {
        UUID workshopId = requireWorkshopAdmin(caller);
        TemplateVersionInfo template = templates.requirePublishedVersionInfo(
                workshopId, request.templateVersionId());
        LocalDateTime scheduledAt;
        try {
            scheduledAt = request.scheduledAt() == null || request.scheduledAt().isBlank()
                    ? null
                    : LocalDateTime.parse(request.scheduledAt());
        } catch (DateTimeParseException exception) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEDULE_INVALID",
                    "error.job.scheduleInvalid", "Scheduled time is invalid");
        }
        InspectionJob job = jobs.save(new InspectionJob(
                workshopId, reference(workshopId), request.templateVersionId(), caller.userId(),
                request.customerName().trim(), trimToNull(request.customerPhone()),
                trimToNull(request.customerEmail()), request.vehicleMake().trim(),
                request.vehicleModel().trim(), request.vehicleYear(), trimToNull(request.vehicleVin()),
                trimToNull(request.vehiclePlate()), request.scope().trim(), scheduledAt));
        job.setVehicleType(template.vehicleType());
        jobs.save(job);
        audit(caller, workshopId, "JOB_CREATED", job.getId(),
                Map.of("reference", job.getReference(), "status", job.getStatus()));
        return dto(job);
    }

    @Transactional
    public JobDto createWalkIn(CurrentUser caller, JobCreateRequest request) {
        if (!caller.isTechnician() || caller.workshopId() == null) {
            throw ApiException.notFound();
        }
        TemplateVersionInfo template = templates.requirePublishedVersionInfo(
                caller.workshopId(), request.templateVersionId());
        InspectionJob job = jobs.save(new InspectionJob(
                caller.workshopId(), reference(caller.workshopId()), request.templateVersionId(),
                caller.userId(), request.customerName().trim(), trimToNull(request.customerPhone()),
                trimToNull(request.customerEmail()), request.vehicleMake().trim(),
                request.vehicleModel().trim(), request.vehicleYear(), trimToNull(request.vehicleVin()),
                trimToNull(request.vehiclePlate()), request.scope().trim(), null));
        job.setVehicleType(template.vehicleType());
        job.assign(caller.userId());
        jobs.save(job);
        assignments.save(new JobAssignment(caller.workshopId(), job.getId(), caller.userId(),
                caller.userId(), "Technician walk-in"));
        audit(caller, caller.workshopId(), "JOB_CREATED", job.getId(),
                Map.of("reference", job.getReference(), "status", job.getStatus(), "walkIn", "true"));
        return dto(job);
    }

    @Transactional
    public JobDto assign(CurrentUser caller, UUID jobId, AssignJobRequest request) {
        UUID workshopId = requireWorkshopAdmin(caller);
        InspectionJob job = requireJob(workshopId, jobId);
        if (job.getStatus().equals("FINALIZED") || job.getStatus().equals("CANCELLED")) {
            throw ApiException.conflict("JOB_NOT_ASSIGNABLE", "Job cannot be assigned in its current state");
        }
        WorkshopMembership membership = memberships.findByWorkshopIdAndUserId(workshopId, request.technicianId())
                .filter(value -> value.getStatus().equals("ACTIVE"))
                .filter(value -> value.getRole() == WorkshopRole.TECHNICIAN)
                .orElseThrow(() -> new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                        "TECHNICIAN_NOT_FOUND", "error.technician.notFound", "Technician is not active in this workshop"));
        UUID previous = job.getAssignedTechnicianId();
        if (request.technicianId().equals(previous)) {
            throw ApiException.conflict("JOB_ALREADY_ASSIGNED", "Job is already assigned to this technician");
        }
        LocalDateTime now = now();
        for (JobAssignment active : assignments.findByJobIdAndUnassignedAtIsNull(jobId)) {
            active.unassign(now, request.reason());
            assignments.save(active);
        }
        assignments.save(new JobAssignment(workshopId, jobId, membership.getUserId(),
                caller.userId(), trimToNull(request.reason())));
        job.assign(membership.getUserId());
        jobs.save(job);
        audit(caller, workshopId, previous == null ? "JOB_ASSIGNED" : "JOB_REASSIGNED", jobId,
                Map.of("technicianId", membership.getUserId().toString(),
                        "reference", job.getReference()));
        return dto(job);
    }

    @Transactional
    public JobDto cancel(CurrentUser caller, UUID jobId, CancelJobRequest request) {
        UUID workshopId = requireWorkshopAdmin(caller);
        InspectionJob job = requireJob(workshopId, jobId);
        if (job.getStatus().equals("FINALIZED")) {
            throw ApiException.conflict("ALREADY_FINALIZED", "Finalized jobs are immutable");
        }
        if (job.getStatus().equals("CANCELLED")) {
            throw ApiException.conflict("ALREADY_CANCELLED", "Job is already cancelled");
        }
        job.cancel(now(), request.reason().trim());
        jobs.save(job);
        audit(caller, workshopId, "JOB_CANCELLED", jobId,
                Map.of("reference", job.getReference(), "reason", request.reason().trim()));
        return dto(job);
    }

    @Transactional(readOnly = true)
    public List<JobAssignmentDto> assignmentHistory(CurrentUser caller, UUID jobId) {
        UUID workshopId = requireWorkshopAdmin(caller);
        requireJob(workshopId, jobId);
        return assignments.findByJobIdOrderByAssignedAtDesc(jobId).stream()
                .map(value -> new JobAssignmentDto(value.getId(), value.getTechnicianId(),
                        value.getAssignedBy(), value.getAssignedAt().toString(),
                        value.getUnassignedAt() == null ? "" : value.getUnassignedAt().toString(),
                        value.getReason()))
                .toList();
    }

    private InspectionJob requireJob(UUID workshopId, UUID jobId) {
        return jobs.findByIdAndWorkshopId(jobId, workshopId).orElseThrow(ApiException::notFound);
    }

    private UUID requireWorkshopAdmin(CurrentUser caller) {
        if (!caller.isWorkshopAdmin() || caller.workshopId() == null) {
            throw ApiException.notFound();
        }
        return caller.workshopId();
    }

    private String validateStatus(String status) {
        String value = status == null ? "" : status.trim().toUpperCase();
        if (!value.isEmpty() && !STATUSES.contains(value)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "INVALID_FILTER",
                    "error.filter.invalid", "Invalid job status filter");
        }
        return value;
    }

    private boolean matches(InspectionJob job, String query) {
        return query.isEmpty()
                || contains(job.getReference(), query)
                || contains(job.getCustomerName(), query)
                || contains(job.getCustomerPhone(), query)
                || contains(job.getCustomerEmail(), query)
                || contains(job.getVehicleMake(), query)
                || contains(job.getVehicleModel(), query)
                || contains(job.getVehicleVin(), query)
                || contains(job.getVehiclePlate(), query);
    }

    private String reference(UUID workshopId) {
        for (int attempt = 0; attempt < 20; attempt++) {
            String candidate = "JOB-" + UuidV7.generate().toString()
                    .replace("-", "").substring(24, 32).toUpperCase();
            if (!jobs.existsByWorkshopIdAndReference(workshopId, candidate)) {
                return candidate;
            }
        }
        throw new IllegalStateException("Unable to allocate a unique job reference");
    }

    public JobDto dto(InspectionJob job) {
        String technicianName = job.getAssignedTechnicianId() == null ? null
                : users.findById(job.getAssignedTechnicianId())
                        .map(User::getDisplayName).orElse(null);
        TemplateVersionInfo template = null;
        try {
            template = templates.versionInfo(job.getWorkshopId(), job.getTemplateVersionId());
        } catch (ApiException ignored) {
            // The job remains readable even if its template version is later retired.
        }
        return new JobDto(job.getId(), job.getReference(), job.getStatus(), job.getVersion(),
                job.getTemplateVersionId(), template == null ? "" : template.templateName(),
                template == null ? null : template.versionNo(),
                job.getAssignedTechnicianId(), technicianName,
                job.getScheduledAt() == null ? "" : job.getScheduledAt().toString(),
                job.getCustomerName(), job.getCustomerPhone(), job.getCustomerEmail(),
                job.getVehicleMake(), job.getVehicleModel(), job.getVehicleYear(),
                job.getVehicleVin(), job.getVehiclePlate(), job.getVehicleType(),
                job.getOdometerValue(), job.getOdometerUnit(), job.getScope(),
                job.getStartedAt() == null ? "" : job.getStartedAt().toString(),
                job.getReadyAt() == null ? "" : job.getReadyAt().toString(),
                job.getFinalizedAt() == null ? "" : job.getFinalizedAt().toString(),
                job.getCreatedAt() == null ? "" : job.getCreatedAt().toString(),
                job.getUpdatedAt() == null ? "" : job.getUpdatedAt().toString());
    }

    private boolean contains(String value, String query) {
        return value != null && value.toLowerCase().contains(query);
    }

    private String trimToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private LocalDateTime now() {
        return LocalDateTime.now(ZoneOffset.UTC);
    }

    private void audit(CurrentUser actor, UUID workshopId, String action, UUID entityId,
                       Map<String, String> metadata) {
        auditService.record(workshopId, actor.userId(), actor.role(), action, "JOB", entityId,
                null, json(metadata));
    }

    private String json(Map<String, String> metadata) {
        try {
            return objectMapper.writeValueAsString(metadata);
        } catch (JsonProcessingException exception) {
            return "{}";
        }
    }
}
