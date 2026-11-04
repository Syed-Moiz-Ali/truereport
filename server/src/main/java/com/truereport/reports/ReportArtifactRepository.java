package com.truereport.reports;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface ReportArtifactRepository extends JpaRepository<ReportArtifact, UUID> {
    Optional<ReportArtifact> findByReportVersionIdAndKind(UUID reportVersionId, String kind);
}
