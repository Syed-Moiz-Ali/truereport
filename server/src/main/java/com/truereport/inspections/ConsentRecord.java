package com.truereport.inspections;

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
@Table(name = "consent_records")
public class ConsentRecord {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "workshop_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID workshopId;

    @Column(name = "job_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID jobId;

    @Column(name = "consent_type", nullable = false, length = 40)
    private String consentType;

    @Column(name = "status", nullable = false, length = 24)
    private String status;

    @Column(name = "wording_version", nullable = false, length = 40)
    private String wordingVersion;

    @Column(name = "wording_hash", columnDefinition = "BINARY(32)", nullable = false)
    private byte[] wordingHash;

    @Column(name = "captured_by", columnDefinition = "BINARY(16)", nullable = false)
    private UUID capturedBy;

    @Column(name = "captured_at", nullable = false)
    private LocalDateTime capturedAt;

    @Column(name = "channel", nullable = false, length = 40)
    private String channel;

    @Column(name = "evidence_ref", length = 255)
    private String evidenceRef;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    protected ConsentRecord() {
    }

    public ConsentRecord(UUID workshopId, UUID jobId, String consentType, String status,
                         String wordingVersion, byte[] wordingHash, UUID capturedBy,
                         String channel, String evidenceRef) {
        this.workshopId = workshopId;
        this.jobId = jobId;
        this.consentType = consentType;
        this.status = status;
        this.wordingVersion = wordingVersion;
        this.wordingHash = wordingHash;
        this.capturedBy = capturedBy;
        this.capturedAt = LocalDateTime.now(ZoneOffset.UTC);
        this.channel = channel;
        this.evidenceRef = evidenceRef;
        this.createdAt = LocalDateTime.now(ZoneOffset.UTC);
    }

    @PrePersist
    void ensureId() {
        if (id == null) {
            id = UuidV7.generate();
        }
        if (capturedAt == null) {
            capturedAt = LocalDateTime.now(ZoneOffset.UTC);
        }
        if (createdAt == null) {
            createdAt = LocalDateTime.now(ZoneOffset.UTC);
        }
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

    public String getConsentType() {
        return consentType;
    }

    public String getStatus() {
        return status;
    }

    public String getWordingVersion() {
        return wordingVersion;
    }

    public byte[] getWordingHash() {
        return wordingHash;
    }

    public UUID getCapturedBy() {
        return capturedBy;
    }

    public LocalDateTime getCapturedAt() {
        return capturedAt;
    }

    public String getChannel() {
        return channel;
    }

    public String getEvidenceRef() {
        return evidenceRef;
    }
}
