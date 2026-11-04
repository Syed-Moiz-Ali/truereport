package com.truereport.reports;

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
@Table(name = "public_share_links")
public class PublicShareLink extends BaseEntity {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "workshop_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID workshopId;

    @Column(name = "report_version_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID reportVersionId;

    @Column(name = "token_hash", columnDefinition = "BINARY(32)")
    private byte[] tokenHash;

    @Column(name = "status", nullable = false, length = 24)
    private String status = "PENDING_CONSENT";

    @Column(name = "pdf_download_enabled", nullable = false)
    private boolean pdfDownloadEnabled;

    @Column(name = "activated_at")
    private LocalDateTime activatedAt;

    @Column(name = "revoked_at")
    private LocalDateTime revokedAt;

    @Column(name = "revoked_by", columnDefinition = "BINARY(16)")
    private UUID revokedBy;

    @Column(name = "revocation_reason_code", length = 60)
    private String revocationReasonCode;

    @Column(name = "revocation_note", length = 500)
    private String revocationNote;

    protected PublicShareLink() {
    }

    public PublicShareLink(UUID workshopId, UUID reportVersionId) {
        this.workshopId = workshopId;
        this.reportVersionId = reportVersionId;
    }

    @PrePersist
    void ensureId() {
        if (id == null) {
            id = UuidV7.generate();
        }
    }

    public void activate(byte[] tokenHash, LocalDateTime at) {
        if (status.equals("REVOKED")) {
            throw new IllegalStateException("Revoked links cannot be reactivated");
        }
        if (status.equals("ACTIVE")) {
            throw new IllegalStateException("Link is already active");
        }
        this.tokenHash = tokenHash;
        this.status = "ACTIVE";
        this.activatedAt = at;
    }

    public void revoke(UUID actor, String reasonCode, String note, LocalDateTime at) {
        this.status = "REVOKED";
        this.revokedAt = at;
        this.revokedBy = actor;
        this.revocationReasonCode = reasonCode;
        this.revocationNote = note;
    }

    public void setPdfDownloadEnabled(boolean enabled) {
        this.pdfDownloadEnabled = enabled;
    }

    public UUID getId() {
        return id;
    }

    public UUID getWorkshopId() {
        return workshopId;
    }

    public UUID getReportVersionId() {
        return reportVersionId;
    }

    public byte[] getTokenHash() {
        return tokenHash;
    }

    public String getStatus() {
        return status;
    }

    public boolean isPdfDownloadEnabled() {
        return pdfDownloadEnabled;
    }

    public LocalDateTime getActivatedAt() {
        return activatedAt;
    }

    public LocalDateTime getRevokedAt() {
        return revokedAt;
    }

    public UUID getRevokedBy() {
        return revokedBy;
    }

    public String getRevocationReasonCode() {
        return revocationReasonCode;
    }

    public String getRevocationNote() {
        return revocationNote;
    }

    public static LocalDateTime now() {
        return LocalDateTime.now(ZoneOffset.UTC);
    }
}
