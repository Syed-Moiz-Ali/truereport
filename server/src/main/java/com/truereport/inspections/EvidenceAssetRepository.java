package com.truereport.inspections;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface EvidenceAssetRepository extends JpaRepository<EvidenceAsset, UUID> {
    Optional<EvidenceAsset> findByIdAndJobId(UUID id, UUID jobId);

    List<EvidenceAsset> findByJobIdAndDeletedAtIsNullOrderByCreatedAtAsc(UUID jobId);

    List<EvidenceAsset> findByJobIdAndInspectionItemIdAndUploadStatusAndDeletedAtIsNull(
            UUID jobId, UUID inspectionItemId, String uploadStatus);

    long countByJobIdAndInspectionItemIdAndUploadStatusAndDeletedAtIsNull(
            UUID jobId, UUID inspectionItemId, String uploadStatus);
}
