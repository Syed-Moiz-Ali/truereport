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
@Table(name = "report_artifacts")
public class ReportArtifact extends BaseEntity {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "report_version_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID reportVersionId;

    @Column(name = "kind", nullable = false, length = 20)
    private String kind;

    @Column(name = "storage_key", nullable = false, length = 512)
    private String storageKey;

    @Column(name = "content_hash", columnDefinition = "BINARY(32)", nullable = false)
    private byte[] contentHash;

    @Column(name = "bytes", nullable = false)
    private long bytes;

    @Column(name = "mime", nullable = false, length = 100)
    private String mime;

    protected ReportArtifact() {
    }

    public ReportArtifact(UUID reportVersionId, String kind, String storageKey,
                          byte[] contentHash, long bytes, String mime) {
        this.reportVersionId = reportVersionId;
        this.kind = kind;
        this.storageKey = storageKey;
        this.contentHash = contentHash;
        this.bytes = bytes;
        this.mime = mime;
    }

    @PrePersist
    void ensureId() {
        if (id == null) {
            id = UuidV7.generate();
        }
    }

    public void replace(String storageKey, byte[] contentHash, long bytes, String mime) {
        this.storageKey = storageKey;
        this.contentHash = contentHash;
        this.bytes = bytes;
        this.mime = mime;
    }

    public UUID getId() {
        return id;
    }

    public UUID getReportVersionId() {
        return reportVersionId;
    }

    public String getKind() {
        return kind;
    }

    public String getStorageKey() {
        return storageKey;
    }

    public byte[] getContentHash() {
        return contentHash;
    }

    public long getBytes() {
        return bytes;
    }

    public String getMime() {
        return mime;
    }
}
