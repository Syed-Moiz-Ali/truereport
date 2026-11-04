package com.truereport.delivery;

import com.truereport.shared.uuid.UuidV7;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.UUID;

@Entity
@Table(name = "delivery_webhook_events")
public class DeliveryWebhookEvent {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "provider", nullable = false, length = 60)
    private String provider;

    @Column(name = "event_id", nullable = false, length = 160)
    private String eventId;

    @Column(name = "payload_hash", columnDefinition = "BINARY(32)", nullable = false)
    private byte[] payloadHash;

    @Column(name = "delivery_request_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID deliveryRequestId;

    @Column(name = "status", nullable = false, length = 24)
    private String status;

    @Column(name = "received_at", nullable = false)
    private LocalDateTime receivedAt;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    protected DeliveryWebhookEvent() {
    }

    public DeliveryWebhookEvent(String provider, String eventId, byte[] payloadHash,
                                UUID deliveryRequestId, String status) {
        this.provider = provider;
        this.eventId = eventId;
        this.payloadHash = payloadHash;
        this.deliveryRequestId = deliveryRequestId;
        this.status = status;
        this.receivedAt = LocalDateTime.now(ZoneOffset.UTC);
        this.createdAt = this.receivedAt;
    }

    @PrePersist
    void ensureId() {
        if (id == null) {
            id = UuidV7.generate();
        }
    }

    public UUID getId() {
        return id;
    }

    public String getProvider() {
        return provider;
    }

    public String getEventId() {
        return eventId;
    }

    public byte[] getPayloadHash() {
        return payloadHash;
    }

    public UUID getDeliveryRequestId() {
        return deliveryRequestId;
    }

    public String getStatus() {
        return status;
    }

    public LocalDateTime getReceivedAt() {
        return receivedAt;
    }
}
