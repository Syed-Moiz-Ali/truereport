package com.truereport.jobs;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface InspectionJobRepository extends JpaRepository<InspectionJob, UUID> {
    List<InspectionJob> findByWorkshopIdOrderByCreatedAtDesc(UUID workshopId);

    Optional<InspectionJob> findByIdAndWorkshopId(UUID id, UUID workshopId);

    List<InspectionJob> findByWorkshopIdAndAssignedTechnicianIdOrderByScheduledAtAsc(
            UUID workshopId, UUID technicianId);

    List<InspectionJob> findByWorkshopIdAndCreatedByOrderByCreatedAtDesc(UUID workshopId, UUID createdBy);

    boolean existsByWorkshopIdAndReference(UUID workshopId, String reference);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select j from InspectionJob j where j.id = :id and j.workshopId = :workshopId")
    Optional<InspectionJob> findForUpdateByIdAndWorkshopId(@Param("id") UUID id,
                                                           @Param("workshopId") UUID workshopId);
}
