package com.truereport.masterdata;

import com.truereport.shared.persistence.BaseEntity;
import com.truereport.shared.uuid.UuidV7;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "guide_images")
public class GuideImage extends BaseEntity {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

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

    @Column(name = "status", nullable = false, length = 32)
    private String status = "ACTIVE";

    @Column(name = "licence_note", length = 255)
    private String licenceNote;

    @Column(name = "uploaded_by", columnDefinition = "BINARY(16)", nullable = false)
    private UUID uploadedBy;

    protected GuideImage() {
    }

    public GuideImage(String storageKey, byte[] contentHash, String mime, long bytes,
                      Integer width, Integer height, String licenceNote, UUID uploadedBy) {
        this.storageKey = storageKey;
        this.contentHash = contentHash;
        this.mime = mime;
        this.bytes = bytes;
        this.width = width;
        this.height = height;
        this.licenceNote = licenceNote;
        this.uploadedBy = uploadedBy;
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

    public String getStatus() {
        return status;
    }

    public String getLicenceNote() {
        return licenceNote;
    }

    public UUID getUploadedBy() {
        return uploadedBy;
    }

    public void retire() {
        this.status = "RETIRED";
    }
}
