package com.truereport.delivery;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface DeliveryAttemptRepository extends JpaRepository<DeliveryAttempt, UUID> {
    List<DeliveryAttempt> findByDeliveryRequestIdOrderByAttemptNoAsc(UUID deliveryRequestId);

    Optional<DeliveryAttempt> findByProviderMessageId(String providerMessageId);

    long countByDeliveryRequestId(UUID deliveryRequestId);
}
