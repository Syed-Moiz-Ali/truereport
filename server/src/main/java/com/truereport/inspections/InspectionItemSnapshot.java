package com.truereport.inspections;

import com.truereport.shared.persistence.BaseEntity;
import com.truereport.shared.uuid.UuidV7;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "inspection_item_snapshots")
public class InspectionItemSnapshot extends BaseEntity {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "workshop_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID workshopId;

    @Column(name = "job_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID jobId;

    @Column(name = "master_item_version_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID masterItemVersionId;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder;

    @Column(name = "item_json", columnDefinition = "TEXT", nullable = false)
    private String itemJson;

    @Column(name = "snapshot_hash", columnDefinition = "BINARY(32)", nullable = false)
    private byte[] snapshotHash;

    protected InspectionItemSnapshot() {
    }

    public InspectionItemSnapshot(UUID workshopId, UUID jobId, UUID masterItemVersionId,
                                  int sortOrder, String itemJson, byte[] snapshotHash) {
        this.workshopId = workshopId;
        this.jobId = jobId;
        this.masterItemVersionId = masterItemVersionId;
        this.sortOrder = sortOrder;
        this.itemJson = itemJson;
        this.snapshotHash = snapshotHash;
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

    public UUID getJobId() {
        return jobId;
    }

    public UUID getMasterItemVersionId() {
        return masterItemVersionId;
    }

    public int getSortOrder() {
        return sortOrder;
    }

    public String getItemJson() {
        return itemJson;
    }

    public byte[] getSnapshotHash() {
        return snapshotHash;
    }
}
