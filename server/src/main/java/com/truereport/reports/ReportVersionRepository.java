package com.truereport.reports;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface ReportVersionRepository extends JpaRepository<ReportVersion, UUID> {
    Optional<ReportVersion> findByReportIdAndVersionNo(UUID reportId, int versionNo);

    Optional<ReportVersion> findFirstByReportIdOrderByVersionNoDesc(UUID reportId);
}
