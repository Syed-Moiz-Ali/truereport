package com.truereport.tenancy;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface InvitationRepository extends JpaRepository<Invitation, UUID> {
    Optional<Invitation> findByTokenHash(byte[] tokenHash);

    List<Invitation> findByWorkshopIdAndStatus(UUID workshopId, InvitationStatus status);

    List<Invitation> findByStatus(InvitationStatus status);
}
