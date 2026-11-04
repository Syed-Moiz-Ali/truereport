package com.truereport.reports;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface ReportRepository extends JpaRepository<Report, UUID> {
    Optional<Report> findByJobId(UUID jobId);

    Optional<Report> findByJobIdAndWorkshopId(UUID jobId, UUID workshopId);
}
