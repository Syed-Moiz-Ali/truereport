package com.truereport.inspections;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface AssessmentRepository extends JpaRepository<Assessment, UUID> {
    List<Assessment> findByJobId(UUID jobId);

    Optional<Assessment> findByJobIdAndInspectionItemId(UUID jobId, UUID inspectionItemId);
}
