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
@Table(name = "master_inspection_items")
public class MasterInspectionItem extends BaseEntity {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "stable_code", nullable = false, length = 60)
    private String stableCode;

    @Column(name = "category_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID categoryId;

    @Column(name = "status", nullable = false, length = 32)
    private String status = "DRAFT";

    @Column(name = "current_published_version_id", columnDefinition = "BINARY(16)")
    private UUID currentPublishedVersionId;

    @Column(name = "sample_data", nullable = false)
    private boolean sampleData;

    protected MasterInspectionItem() {
    }

    public MasterInspectionItem(String stableCode, UUID categoryId, boolean sampleData) {
        this.stableCode = stableCode;
        this.categoryId = categoryId;
        this.sampleData = sampleData;
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

    public String getStableCode() {
        return stableCode;
    }

    public UUID getCategoryId() {
        return categoryId;
    }

    public String getStatus() {
        return status;
    }

    public UUID getCurrentPublishedVersionId() {
        return currentPublishedVersionId;
    }

    public boolean isSampleData() {
        return sampleData;
    }

    public void setCategoryId(UUID categoryId) {
        this.categoryId = categoryId;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public void setCurrentPublishedVersionId(UUID currentPublishedVersionId) {
        this.currentPublishedVersionId = currentPublishedVersionId;
    }
}
