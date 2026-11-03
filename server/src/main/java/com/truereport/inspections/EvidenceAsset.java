package com.truereport.inspections;

import com.truereport.shared.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "evidence_assets")
public class EvidenceAsset extends BaseEntity {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "workshop_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID workshopId;

    @Column(name = "job_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID jobId;

    @Column(name = "inspection_item_id", columnDefinition = "BINARY(16)")
    private UUID inspectionItemId;

    @Column(name = "assessment_id", columnDefinition = "BINARY(16)")
    private UUID assessmentId;

    @Column(name = "storage_key", nullable = false, length = 512)
    private String storageKey;

    @Column(name = "content_hash", columnDefinition = "BINARY(32)", nullable = false)
    private byte[] contentHash;

    @Column(name = "mime", nullable = false, length = 100)
    private String mime;

    @Column(name = "bytes", nullable = false)
    private long bytes;

    @Column(name = "width")
    private Integer width;

    @Column(name = "height")
    private Integer height;

    @Column(name = "captured_at")
    private LocalDateTime capturedAt;

    @Column(name = "uploaded_by", columnDefinition = "BINARY(16)", nullable = false)
    private UUID uploadedBy;

    @Column(name = "upload_status", nullable = false, length = 24)
    private String uploadStatus = "PENDING";

    @Column(name = "normalized_storage_key", length = 512)
    private String normalizedStorageKey;

    @Column(name = "normalized_hash", columnDefinition = "BINARY(32)")
    private byte[] normalizedHash;

    @Column(name = "normalized_bytes")
    private Long normalizedBytes;

    @Column(name = "normalized_mime", length = 100)
    private String normalizedMime;

    @Column(name = "upload_token_hash", columnDefinition = "BINARY(32)")
    private byte[] uploadTokenHash;

    @Column(name = "upload_token_expires_at")
    private LocalDateTime uploadTokenExpiresAt;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    @Column(name = "deleted_by", columnDefinition = "BINARY(16)")
    private UUID deletedBy;

    protected EvidenceAsset() {
    }

    public EvidenceAsset(UUID id, UUID workshopId, UUID jobId, UUID inspectionItemId,
                         UUID assessmentId, String storageKey, byte[] contentHash, String mime,
                         long bytes, LocalDateTime capturedAt, UUID uploadedBy) {
        this.id = id;
        this.workshopId = workshopId;
        this.jobId = jobId;
        this.inspectionItemId = inspectionItemId;
        this.assessmentId = assessmentId;
        this.storageKey = storageKey;
        this.contentHash = contentHash;
        this.mime = mime;
        this.bytes = bytes;
        this.capturedAt = capturedAt;
        this.uploadedBy = uploadedBy;
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

    public UUID getInspectionItemId() {
        return inspectionItemId;
    }

    public UUID getAssessmentId() {
        return assessmentId;
    }

    public String getStorageKey() {
        return storageKey;
    }

    public byte[] getContentHash() {
        return contentHash;
    }

    public String getMime() {
        return mime;
    }

    public long getBytes() {
        return bytes;
    }

    public Integer getWidth() {
        return width;
    }

    public Integer getHeight() {
        return height;
    }

    public LocalDateTime getCapturedAt() {
        return capturedAt;
    }

    public UUID getUploadedBy() {
        return uploadedBy;
    }

    public String getUploadStatus() {
        return uploadStatus;
    }

    public String getNormalizedStorageKey() {
        return normalizedStorageKey;
    }

    public byte[] getNormalizedHash() {
        return normalizedHash;
    }

    public Long getNormalizedBytes() {
        return normalizedBytes;
    }

    public String getNormalizedMime() {
        return normalizedMime;
    }

    public byte[] getUploadTokenHash() {
        return uploadTokenHash;
    }

    public LocalDateTime getUploadTokenExpiresAt() {
        return uploadTokenExpiresAt;
    }

    public LocalDateTime getDeletedAt() {
        return deletedAt;
    }

    public UUID getDeletedBy() {
        return deletedBy;
    }

    public void setAssessmentId(UUID assessmentId) {
        this.assessmentId = assessmentId;
    }

    public void setUploadToken(byte[] hash, LocalDateTime expiresAt) {
        this.uploadTokenHash = hash;
        this.uploadTokenExpiresAt = expiresAt;
    }

    public void markReceived() {
        this.uploadStatus = "RECEIVED";
        this.uploadTokenHash = null;
        this.uploadTokenExpiresAt = null;
    }

    public void markVerified(String normalizedKey, byte[] normalizedHash, long normalizedBytes,
                             String normalizedMime, Integer width, Integer height) {
        this.normalizedStorageKey = normalizedKey;
        this.normalizedHash = normalizedHash;
        this.normalizedBytes = normalizedBytes;
        this.normalizedMime = normalizedMime;
        this.width = width;
        this.height = height;
        this.uploadStatus = "VERIFIED";
        this.uploadTokenHash = null;
        this.uploadTokenExpiresAt = null;
    }

    public void markRejected() {
        this.uploadStatus = "REJECTED";
        this.uploadTokenHash = null;
        this.uploadTokenExpiresAt = null;
    }

    public void delete(UUID actor, LocalDateTime at) {
        this.deletedAt = at;
        this.deletedBy = actor;
    }
}
