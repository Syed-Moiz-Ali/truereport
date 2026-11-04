package com.truereport.delivery;

import com.truereport.shared.persistence.BaseEntity;
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
@Table(name = "delivery_attempts")
public class DeliveryAttempt extends BaseEntity {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "delivery_request_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID deliveryRequestId;

    @Column(name = "attempt_no", nullable = false)
    private int attemptNo;

    @Column(name = "provider", nullable = false, length = 60)
    private String provider;

    @Column(name = "status", nullable = false, length = 24)
    private String status;

    @Column(name = "provider_message_id", length = 255)
    private String providerMessageId;

    @Column(name = "error_code", length = 80)
    private String errorCode;

    @Column(name = "error_message", length = 500)
    private String errorMessage;

    @Column(name = "sent_at")
    private LocalDateTime sentAt;

    @Column(name = "delivered_at")
    private LocalDateTime deliveredAt;

    protected DeliveryAttempt() {
    }

    public DeliveryAttempt(UUID deliveryRequestId, int attemptNo, String provider) {
        this.deliveryRequestId = deliveryRequestId;
        this.attemptNo = attemptNo;
        this.provider = provider;
        this.status = "QUEUED";
    }

    @PrePersist
    void ensureId() {
        if (id == null) {
            id = UuidV7.generate();
        }
    }

    public void sent(String providerMessageId) {
        this.status = "SENT";
        this.providerMessageId = providerMessageId;
        this.sentAt = LocalDateTime.now(ZoneOffset.UTC);
    }

    public void delivered() {
        this.status = "DELIVERED";
        this.deliveredAt = LocalDateTime.now(ZoneOffset.UTC);
    }

    public void failed(String errorCode, String errorMessage) {
        this.status = "FAILED";
        this.errorCode = errorCode == null ? "PROVIDER_FAILED" : errorCode;
        this.errorMessage = errorMessage == null || errorMessage.isBlank()
                ? null : errorMessage.replaceAll("[\\r\\n\\t]+", " ").trim();
        if (this.errorMessage != null && this.errorMessage.length() > 500) {
            this.errorMessage = this.errorMessage.substring(0, 500);
        }
    }

    public void retryPending() {
        this.status = "RETRY_PENDING";
    }

    public void deadLetter() {
        this.status = "DEAD_LETTER";
    }

    public UUID getId() {
        return id;
    }

    public UUID getDeliveryRequestId() {
        return deliveryRequestId;
    }

    public int getAttemptNo() {
        return attemptNo;
    }

    public String getProvider() {
        return provider;
    }

    public String getStatus() {
        return status;
    }

    public String getProviderMessageId() {
        return providerMessageId;
    }

    public String getErrorCode() {
        return errorCode;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public LocalDateTime getSentAt() {
        return sentAt;
    }

    public LocalDateTime getDeliveredAt() {
        return deliveredAt;
    }
}
