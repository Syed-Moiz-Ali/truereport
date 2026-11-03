package com.truereport.jobs;

import com.truereport.shared.uuid.UuidV7;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "job_assignments")
public class JobAssignment {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "workshop_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID workshopId;

    @Column(name = "job_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID jobId;

    @Column(name = "technician_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID technicianId;

    @Column(name = "assigned_by", columnDefinition = "BINARY(16)", nullable = false)
    private UUID assignedBy;

    @Column(name = "assigned_at", nullable = false)
    private LocalDateTime assignedAt;

    @Column(name = "unassigned_at")
    private LocalDateTime unassignedAt;

    @Column(name = "reason", length = 255)
    private String reason;

    protected JobAssignment() {
    }

    public JobAssignment(UUID workshopId, UUID jobId, UUID technicianId, UUID assignedBy,
                         String reason) {
        this.workshopId = workshopId;
        this.jobId = jobId;
        this.technicianId = technicianId;
        this.assignedBy = assignedBy;
        this.assignedAt = LocalDateTime.now(java.time.ZoneOffset.UTC);
        this.reason = reason;
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

    public UUID getTechnicianId() {
        return technicianId;
    }

    public UUID getAssignedBy() {
        return assignedBy;
    }

    public LocalDateTime getAssignedAt() {
        return assignedAt;
    }

    public LocalDateTime getUnassignedAt() {
        return unassignedAt;
    }

    public String getReason() {
        return reason;
    }

    public void unassign(LocalDateTime at, String reason) {
        this.unassignedAt = at;
        this.reason = reason;
    }
}
