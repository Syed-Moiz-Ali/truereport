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
@Table(name = "inspection_final_snapshots")
public class InspectionFinalSnapshot {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "workshop_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID workshopId;

    @Column(name = "job_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID jobId;

    @Column(name = "snapshot_json", columnDefinition = "TEXT", nullable = false)
    private String snapshotJson;

    @Column(name = "snapshot_hash", columnDefinition = "BINARY(32)", nullable = false)
    private byte[] snapshotHash;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    protected InspectionFinalSnapshot() {
    }

    public InspectionFinalSnapshot(UUID workshopId, UUID jobId, String snapshotJson,
                                   byte[] snapshotHash) {
        this.workshopId = workshopId;
        this.jobId = jobId;
        this.snapshotJson = snapshotJson;
        this.snapshotHash = snapshotHash;
        this.createdAt = LocalDateTime.now(ZoneOffset.UTC);
    }

    @PrePersist
    void ensureId() {
        if (id == null) {
            id = UuidV7.generate();
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

    public String getSnapshotJson() {
        return snapshotJson;
    }

    public byte[] getSnapshotHash() {
        return snapshotHash;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}
