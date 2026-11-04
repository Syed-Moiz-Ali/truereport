package com.truereport.delivery;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import jakarta.persistence.LockModeType;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface DeliveryRequestRepository extends JpaRepository<DeliveryRequestEntity, UUID> {

    Optional<DeliveryRequestEntity> findByWorkshopIdAndIdempotencyKeyHash(
            UUID workshopId, byte[] idempotencyKeyHash);

    List<DeliveryRequestEntity> findByWorkshopIdAndJobIdOrderByCreatedAtDesc(
            UUID workshopId, UUID jobId);

    List<DeliveryRequestEntity> findByJobIdOrderByCreatedAtDesc(UUID jobId);

    long countByWorkshopIdAndRecipientHashAndCreatedAtAfter(
            UUID workshopId, byte[] recipientHash, LocalDateTime after);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select r from DeliveryRequestEntity r where r.id = :id")
    Optional<DeliveryRequestEntity> findForUpdate(@Param("id") UUID id);

    @Query("""
            select r.id from DeliveryRequestEntity r
            where r.status in ('QUEUED', 'RETRY_PENDING')
              and (r.nextAttemptAt is null or r.nextAttemptAt <= :now)
            order by r.createdAt asc
            """)
    List<UUID> findDueIds(@Param("now") LocalDateTime now);
}
