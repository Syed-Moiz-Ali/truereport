package com.truereport.jobs;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface JobAssignmentRepository extends JpaRepository<JobAssignment, UUID> {
    List<JobAssignment> findByJobIdOrderByAssignedAtDesc(UUID jobId);

    List<JobAssignment> findByJobIdAndUnassignedAtIsNull(UUID jobId);
}
