package com.truereport.inspections;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface InspectionStatusHistoryRepository extends JpaRepository<InspectionStatusHistory, UUID> {
    List<InspectionStatusHistory> findByJobIdOrderByOccurredAtAsc(UUID jobId);
}
