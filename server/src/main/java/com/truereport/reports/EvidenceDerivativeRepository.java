package com.truereport.reports;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface EvidenceDerivativeRepository extends JpaRepository<EvidenceDerivative, UUID> {
    Optional<EvidenceDerivative> findByEvidenceAssetIdAndPurpose(UUID evidenceAssetId, String purpose);

    List<EvidenceDerivative> findByReportVersionIdOrderByCreatedAtAsc(UUID reportVersionId);

    Optional<EvidenceDerivative> findByIdAndReportVersionId(UUID id, UUID reportVersionId);
}
