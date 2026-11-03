package com.truereport.inspections;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface FindingRepository extends JpaRepository<Finding, UUID> {
    Optional<Finding> findByJobId(UUID jobId);
}
