package com.truereport.reports;

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
@Table(name = "report_versions")
public class ReportVersion extends BaseEntity {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "report_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID reportId;

    @Column(name = "workshop_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID workshopId;

    @Column(name = "version_no", nullable = false)
    private int versionNo;

    @Column(name = "report_number", nullable = false, length = 60)
    private String reportNumber;

    @Column(name = "final_snapshot_hash", columnDefinition = "BINARY(32)", nullable = false)
    private byte[] finalSnapshotHash;

    @Column(name = "snapshot_json", columnDefinition = "TEXT", nullable = false)
    private String snapshotJson;

    @Column(name = "snapshot_hash", columnDefinition = "BINARY(32)", nullable = false)
    private byte[] snapshotHash;

    @Column(name = "finalized_at", nullable = false)
    private LocalDateTime finalizedAt;

    protected ReportVersion() {
    }

    public ReportVersion(UUID reportId, UUID workshopId, int versionNo, String reportNumber,
                         byte[] finalSnapshotHash, String snapshotJson, byte[] snapshotHash,
                         LocalDateTime finalizedAt) {
        this.reportId = reportId;
        this.workshopId = workshopId;
        this.versionNo = versionNo;
        this.reportNumber = reportNumber;
        this.finalSnapshotHash = finalSnapshotHash;
        this.snapshotJson = snapshotJson;
        this.snapshotHash = snapshotHash;
        this.finalizedAt = finalizedAt;
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

    public UUID getReportId() {
        return reportId;
    }

    public UUID getWorkshopId() {
        return workshopId;
    }

    public int getVersionNo() {
        return versionNo;
    }

    public String getReportNumber() {
        return reportNumber;
    }

    public byte[] getFinalSnapshotHash() {
        return finalSnapshotHash;
    }

    public String getSnapshotJson() {
        return snapshotJson;
    }

    public byte[] getSnapshotHash() {
        return snapshotHash;
    }

    public LocalDateTime getFinalizedAt() {
        return finalizedAt;
    }
}
