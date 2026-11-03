package com.truereport.templates;

import com.truereport.shared.persistence.BaseEntity;
import com.truereport.shared.uuid.UuidV7;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "template_versions")
public class TemplateVersion extends BaseEntity {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "template_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID templateId;

    @Column(name = "workshop_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID workshopId;

    @Column(name = "version_no", nullable = false)
    private int versionNo;

    @Column(name = "status", nullable = false, length = 32)
    private String status = "DRAFT";

    @Column(name = "published_at")
    private LocalDateTime publishedAt;

    @Column(name = "published_by", columnDefinition = "BINARY(16)")
    private UUID publishedBy;

    protected TemplateVersion() {
    }

    public TemplateVersion(UUID templateId, UUID workshopId, int versionNo) {
        this.templateId = templateId;
        this.workshopId = workshopId;
        this.versionNo = versionNo;
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

    public UUID getTemplateId() {
        return templateId;
    }

    public UUID getWorkshopId() {
        return workshopId;
    }

    public int getVersionNo() {
        return versionNo;
    }

    public String getStatus() {
        return status;
    }

    public LocalDateTime getPublishedAt() {
        return publishedAt;
    }

    public UUID getPublishedBy() {
        return publishedBy;
    }

    public void publish(UUID actor, LocalDateTime at) {
        this.status = "PUBLISHED";
        this.publishedBy = actor;
        this.publishedAt = at;
    }

    public void retire() {
        this.status = "RETIRED";
    }
}
