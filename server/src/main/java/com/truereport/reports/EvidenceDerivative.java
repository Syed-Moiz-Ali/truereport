package com.truereport.reports;

import com.truereport.shared.persistence.BaseEntity;
import com.truereport.shared.uuid.UuidV7;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "evidence_derivatives")
public class EvidenceDerivative extends BaseEntity {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "workshop_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID workshopId;

    @Column(name = "report_version_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID reportVersionId;

    @Column(name = "evidence_asset_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID evidenceAssetId;

    @Column(name = "purpose", nullable = false, length = 24)
    private String purpose;

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

    protected EvidenceDerivative() {
    }

    public EvidenceDerivative(UUID workshopId, UUID reportVersionId, UUID evidenceAssetId,
                              String purpose, String storageKey, byte[] contentHash,
                              String mime, long bytes, Integer width, Integer height) {
        this.workshopId = workshopId;
        this.reportVersionId = reportVersionId;
        this.evidenceAssetId = evidenceAssetId;
        this.purpose = purpose;
        this.storageKey = storageKey;
        this.contentHash = contentHash;
        this.mime = mime;
        this.bytes = bytes;
        this.width = width;
        this.height = height;
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

    public UUID getWorkshopId() {
        return workshopId;
    }

    public UUID getReportVersionId() {
        return reportVersionId;
    }

    public UUID getEvidenceAssetId() {
        return evidenceAssetId;
    }

    public String getPurpose() {
        return purpose;
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
}
