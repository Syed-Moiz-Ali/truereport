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
@Table(name = "delivery_requests")
public class DeliveryRequestEntity extends BaseEntity {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "workshop_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID workshopId;

    @Column(name = "job_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID jobId;

    @Column(name = "report_version_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID reportVersionId;

    @Column(name = "channel", nullable = false, length = 20)
    private String channel;

    @Column(name = "recipient_masked", nullable = false, length = 160)
    private String recipientMasked;

    @Column(name = "recipient_hash", columnDefinition = "BINARY(32)", nullable = false)
    private byte[] recipientHash;

    @Column(name = "language", nullable = false, length = 8)
    private String language;

    @Column(name = "status", nullable = false, length = 24)
    private String status;

    @Column(name = "request_hash", columnDefinition = "BINARY(32)", nullable = false)
    private byte[] requestHash;

    @Column(name = "idempotency_key_hash", columnDefinition = "BINARY(32)", nullable = false)
    private byte[] idempotencyKeyHash;

    @Column(name = "consent_type", nullable = false, length = 40)
    private String consentType;

    @Column(name = "requested_by", columnDefinition = "BINARY(16)", nullable = false)
    private UUID requestedBy;

    @Column(name = "public_share_link_id", columnDefinition = "BINARY(16)")
    private UUID publicShareLinkId;

    @Column(name = "pdf_attached", nullable = false)
    private boolean pdfAttached;

    @Column(name = "attempts", nullable = false)
    private int attempts;

    @Column(name = "max_attempts", nullable = false)
    private int maxAttempts;

    @Column(name = "next_attempt_at")
    private LocalDateTime nextAttemptAt;

    @Column(name = "last_error_code", length = 80)
    private String lastErrorCode;

    @Column(name = "last_error_message", length = 500)
    private String lastErrorMessage;

    protected DeliveryRequestEntity() {
    }

    public DeliveryRequestEntity(UUID workshopId, UUID jobId, UUID reportVersionId,
                                 String channel, String recipientMasked, byte[] recipientHash,
                                 String language, byte[] requestHash, byte[] idempotencyKeyHash,
                                 String consentType, UUID requestedBy, int maxAttempts) {
        this.workshopId = workshopId;
        this.jobId = jobId;
        this.reportVersionId = reportVersionId;
        this.channel = channel;
        this.recipientMasked = recipientMasked;
        this.recipientHash = recipientHash;
        this.language = language;
        this.status = "QUEUED";
        this.requestHash = requestHash;
        this.idempotencyKeyHash = idempotencyKeyHash;
        this.consentType = consentType;
        this.requestedBy = requestedBy;
        this.maxAttempts = maxAttempts;
        this.nextAttemptAt = now();
    }

    @PrePersist
    void ensureId() {
        if (id == null) {
            id = UuidV7.generate();
        }
    }

    public void markSending() {
        status = "QUEUED";
        lastErrorCode = null;
        lastErrorMessage = null;
    }

    public void markSent(UUID linkId, boolean pdfAttached) {
        this.status = "SENT";
        this.publicShareLinkId = linkId;
        this.pdfAttached = pdfAttached;
        this.attempts++;
        this.lastErrorCode = null;
        this.lastErrorMessage = null;
    }

    public void setPublicShareLinkId(UUID publicShareLinkId) {
        this.publicShareLinkId = publicShareLinkId;
    }

    public void markDelivered() {
        this.status = "DELIVERED";
    }

    public void markRetry(String errorCode, String errorMessage, int maxAttempts, long baseSeconds) {
        this.attempts++;
        this.lastErrorCode = redact(errorCode, 80);
        this.lastErrorMessage = redact(errorMessage, 500);
        if (this.attempts >= maxAttempts) {
            this.status = "DEAD_LETTER";
            this.nextAttemptAt = null;
        } else {
            this.status = "RETRY_PENDING";
            long delay = Math.min(3600, baseSeconds * (1L << Math.max(0, this.attempts - 1)));
            this.nextAttemptAt = now().plusSeconds(delay);
        }
    }

    public void retryNow() {
        this.status = "QUEUED";
        this.attempts = 0;
        this.nextAttemptAt = now();
        this.lastErrorCode = null;
        this.lastErrorMessage = null;
    }

    public void markFailed() {
        this.status = "FAILED";
    }

    private String redact(String value, int max) {
        if (value == null || value.isBlank()) {
            return null;
        }
        String cleaned = value.replaceAll("[\\r\\n\\t]+", " ").trim();
        return cleaned.length() > max ? cleaned.substring(0, max) : cleaned;
    }

    private LocalDateTime now() {
        return LocalDateTime.now(ZoneOffset.UTC);
    }

    public UUID getId() {
        return id;
    }

    public UUID getWorkshopId() {
        return workshopId;
    }

    public UUID getJobId() {
        return jobId;
    }

    public UUID getReportVersionId() {
        return reportVersionId;
    }

    public String getChannel() {
        return channel;
    }

    public String getRecipientMasked() {
        return recipientMasked;
    }

    public byte[] getRecipientHash() {
        return recipientHash;
    }

    public String getLanguage() {
        return language;
    }

    public String getStatus() {
        return status;
    }

    public byte[] getRequestHash() {
        return requestHash;
    }

    public byte[] getIdempotencyKeyHash() {
        return idempotencyKeyHash;
    }

    public String getConsentType() {
        return consentType;
    }

    public UUID getRequestedBy() {
        return requestedBy;
    }

    public UUID getPublicShareLinkId() {
        return publicShareLinkId;
    }

    public boolean isPdfAttached() {
        return pdfAttached;
    }

    public int getAttempts() {
        return attempts;
    }

    public int getMaxAttempts() {
        return maxAttempts;
    }

    public LocalDateTime getNextAttemptAt() {
        return nextAttemptAt;
    }

    public String getLastErrorCode() {
        return lastErrorCode;
    }

    public String getLastErrorMessage() {
        return lastErrorMessage;
    }
}
