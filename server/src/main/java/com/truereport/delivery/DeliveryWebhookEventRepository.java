package com.truereport.delivery;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface DeliveryWebhookEventRepository extends JpaRepository<DeliveryWebhookEvent, UUID> {
    Optional<DeliveryWebhookEvent> findByProviderAndEventId(String provider, String eventId);
}
