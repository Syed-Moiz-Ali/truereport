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
@Table(name = "findings")
public class Finding {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "workshop_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID workshopId;

    @Column(name = "job_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID jobId;

    @Column(name = "assessment_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID assessmentId;

    @Column(name = "severity_code", nullable = false, length = 40)
    private String severityCode;

    @Column(name = "description", columnDefinition = "TEXT", nullable = false)
    private String description;

    @Column(name = "recommendation", columnDefinition = "TEXT")
    private String recommendation;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    protected Finding() {
    }

    public Finding(UUID workshopId, UUID jobId, UUID assessmentId, String severityCode,
                   String description, String recommendation) {
        this.workshopId = workshopId;
        this.jobId = jobId;
        this.assessmentId = assessmentId;
        this.severityCode = severityCode;
        this.description = description;
        this.recommendation = recommendation;
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

    public UUID getAssessmentId() {
        return assessmentId;
    }

    public String getSeverityCode() {
        return severityCode;
    }

    public String getDescription() {
        return description;
    }

    public String getRecommendation() {
        return recommendation;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}
