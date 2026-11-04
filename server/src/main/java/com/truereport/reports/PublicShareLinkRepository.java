package com.truereport.reports;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PublicShareLinkRepository extends JpaRepository<PublicShareLink, UUID> {
    Optional<PublicShareLink> findByTokenHash(byte[] tokenHash);

    Optional<PublicShareLink> findFirstByReportVersionIdOrderByCreatedAtDesc(UUID reportVersionId);

    long countByReportVersionIdAndStatus(UUID reportVersionId, String status);

    List<PublicShareLink> findByReportVersionIdAndStatusOrderByCreatedAtDesc(
            UUID reportVersionId, String status);
}
