package com.truereport.localization;

import com.truereport.shared.audit.FieldAuditService;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.security.CurrentUser;
import com.truereport.tenancy.Workshop;
import com.truereport.tenancy.WorkshopMembershipRepository;
import com.truereport.tenancy.WorkshopRepository;
import com.truereport.localization.api.WorkshopDtos.WorkshopDto;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.UUID;

/**
 * Platform Admin workshop CRUD. Reuses the {@link WorkshopDto} shape served by
 * the existing workshop endpoints and records every mutation in the platform
 * audit trail.
 */
@Service
public class PlatformWorkshopService {

    public record WorkshopUpdateRequest(String name, String location, String branchName,
                                        String contactEmail, String timezone) {
    }

    public record WorkshopReasonRequest(String reason) {
    }

    private final WorkshopRepository workshops;
    private final WorkshopMembershipRepository memberships;
    private final FieldAuditService audit;

    public PlatformWorkshopService(WorkshopRepository workshops,
                                   WorkshopMembershipRepository memberships,
                                   FieldAuditService audit) {
        this.workshops = workshops;
        this.memberships = memberships;
        this.audit = audit;
    }

    @Transactional
    public WorkshopDto update(CurrentUser actor, UUID workshopId, WorkshopUpdateRequest request,
                              HttpServletRequest http) {
        Workshop workshop = workshops.findById(workshopId).orElseThrow(ApiException::notFound);
        String before = workshop.getName() + "|" + workshop.getStatus();
        boolean changed = false;
        if (request != null) {
            if (request.name() != null && !request.name().isBlank()) {
                workshop.setName(request.name().trim());
                changed = true;
            }
            String branch = request.branchName() != null ? request.branchName() : request.location();
            if (branch != null && !branch.isBlank()) {
                workshop.setBranchName(branch.trim());
                changed = true;
            }
            if (request.timezone() != null && !request.timezone().isBlank()) {
                // Timezone is accepted for forward compatibility; contactEmail has no
                // backing column and is accepted without persistence.
                changed = true;
            }
            if (request.contactEmail() != null && !request.contactEmail().isBlank()) {
                changed = true;
            }
        }
        if (changed) {
            workshops.save(workshop);
        }
        audit.record(actor, "WORKSHOP_UPDATED", "WORKSHOP", workshopId.toString(),
                Map.of("before", before),
                Map.of("name", workshop.getName(), "status", workshop.getStatus()), null, http);
        return toDto(workshop);
    }

    @Transactional
    public WorkshopDto deactivate(CurrentUser actor, UUID workshopId,
                                  WorkshopReasonRequest request, HttpServletRequest http) {
        Workshop workshop = workshops.findById(workshopId).orElseThrow(ApiException::notFound);
        workshop.setStatus("DISABLED");
        workshops.save(workshop);
        String reason = request == null ? null : request.reason();
        audit.record(actor, "WORKSHOP_DEACTIVATED", "WORKSHOP", workshopId.toString(),
                Map.of("status", "ACTIVE"), Map.of("status", "DISABLED"), reason, http);
        return toDto(workshop);
    }

    @Transactional
    public WorkshopDto reactivate(CurrentUser actor, UUID workshopId,
                                  WorkshopReasonRequest request, HttpServletRequest http) {
        Workshop workshop = workshops.findById(workshopId).orElseThrow(ApiException::notFound);
        workshop.setStatus("ACTIVE");
        workshops.save(workshop);
        String reason = request == null ? null : request.reason();
        audit.record(actor, "WORKSHOP_REACTIVATED", "WORKSHOP", workshopId.toString(),
                Map.of("status", "DISABLED"), Map.of("status", "ACTIVE"), reason, http);
        return toDto(workshop);
    }

    private WorkshopDto toDto(Workshop workshop) {
        long count = memberships.countByWorkshopIdAndStatus(workshop.getId(), "ACTIVE");
        return new WorkshopDto(workshop.getId(), workshop.getName(), workshop.getStatus(), count);
    }
}
