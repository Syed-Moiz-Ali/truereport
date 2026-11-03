package com.truereport.inspections;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface InspectionItemSnapshotRepository extends JpaRepository<InspectionItemSnapshot, UUID> {
    List<InspectionItemSnapshot> findByJobIdOrderBySortOrderAsc(UUID jobId);

    Optional<InspectionItemSnapshot> findByIdAndJobId(UUID id, UUID jobId);

    long countByJobId(UUID jobId);
}
