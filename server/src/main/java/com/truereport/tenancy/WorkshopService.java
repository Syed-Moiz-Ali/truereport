package com.truereport.tenancy;

import com.truereport.shared.error.ApiException;
import com.truereport.shared.security.CurrentUser;
import com.truereport.tenancy.api.WorkshopDto;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class WorkshopService {

    private final WorkshopRepository workshops;
    private final WorkshopMembershipRepository memberships;

    public WorkshopService(WorkshopRepository workshops,
                           WorkshopMembershipRepository memberships) {
        this.workshops = workshops;
        this.memberships = memberships;
    }

    @Transactional(readOnly = true)
    public WorkshopDto getWorkshop(UUID workshopId, CurrentUser caller) {
        if (caller.isTechnician()) {
            throw ApiException.notFound();
        }
        if (!caller.isPlatformAdmin()
                && (caller.workshopId() == null || !caller.workshopId().equals(workshopId))) {
            // Neutral not-found so a Workshop Admin cannot probe another tenant.
            throw ApiException.notFound();
        }
        Workshop workshop = workshops.findById(workshopId).orElseThrow(ApiException::notFound);
        return toDto(workshop);
    }

    @Transactional(readOnly = true)
    public List<WorkshopDto> listForPlatform(CurrentUser caller) {
        if (!caller.isPlatformAdmin()) {
            throw ApiException.forbidden();
        }
        return workshops.findAllByOrderByNameAsc().stream().map(this::toDto).toList();
    }

    private WorkshopDto toDto(Workshop workshop) {
        long count = memberships.countByWorkshopIdAndStatus(workshop.getId(), "ACTIVE");
        return new WorkshopDto(workshop.getId(), workshop.getName(), workshop.getStatus(), count);
    }
}
