package com.truereport.inspections;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface InspectionFinalSnapshotRepository extends JpaRepository<InspectionFinalSnapshot, UUID> {
    Optional<InspectionFinalSnapshot> findByJobId(UUID jobId);
}
