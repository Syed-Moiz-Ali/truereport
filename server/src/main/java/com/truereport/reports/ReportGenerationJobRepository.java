package com.truereport.reports;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import jakarta.persistence.LockModeType;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ReportGenerationJobRepository extends JpaRepository<ReportGenerationJob, UUID> {

    Optional<ReportGenerationJob> findByReportVersionId(UUID reportVersionId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select j from ReportGenerationJob j where j.id = :id")
    Optional<ReportGenerationJob> findForUpdate(@Param("id") UUID id);

    @Query("""
            select j.id from ReportGenerationJob j
            where j.status in ('QUEUED', 'FAILED') and j.availableAt <= :now
            order by j.createdAt asc
            """)
    List<UUID> findDueIds(@Param("now") LocalDateTime now);
}
