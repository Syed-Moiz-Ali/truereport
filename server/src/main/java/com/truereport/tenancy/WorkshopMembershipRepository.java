package com.truereport.tenancy;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface WorkshopMembershipRepository extends JpaRepository<WorkshopMembership, UUID> {
    Optional<WorkshopMembership> findFirstByUserIdAndStatusAndPrimaryTrue(UUID userId, String status);

    List<WorkshopMembership> findByUserIdAndStatus(UUID userId, String status);

    List<WorkshopMembership> findByWorkshopIdAndStatusOrderByRoleAsc(UUID workshopId, String status);

    List<WorkshopMembership> findByWorkshopIdOrderByRoleAsc(UUID workshopId);

    Optional<WorkshopMembership> findByWorkshopIdAndUserId(UUID workshopId, UUID userId);

    long countByWorkshopIdAndRoleAndStatus(UUID workshopId, WorkshopRole role, String status);

    long countByWorkshopIdAndStatus(UUID workshopId, String status);
}
