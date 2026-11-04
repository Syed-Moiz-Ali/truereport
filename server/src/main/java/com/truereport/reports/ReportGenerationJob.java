package com.truereport.reports;

import com.truereport.shared.persistence.BaseEntity;
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
@Table(name = "report_generation_jobs")
public class ReportGenerationJob extends BaseEntity {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "report_version_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID reportVersionId;

    @Column(name = "status", nullable = false, length = 24)
    private String status = "QUEUED";

    @Column(name = "attempts", nullable = false)
    private int attempts;

    @Column(name = "last_error", length = 1000)
    private String lastError;

    @Column(name = "available_at", nullable = false)
    private LocalDateTime availableAt;

    protected ReportGenerationJob() {
    }

    public ReportGenerationJob(UUID reportVersionId) {
        this.reportVersionId = reportVersionId;
        this.availableAt = LocalDateTime.now(ZoneOffset.UTC).minusSeconds(1);
    }

    @PrePersist
    void ensureId() {
        if (id == null) {
            id = UuidV7.generate();
        }
    }

    public void markGenerating() {
        status = "GENERATING";
        attempts++;
        lastError = null;
    }

    public void markReady() {
        status = "READY";
        lastError = null;
    }

    public void markFailed(String error) {
        status = "FAILED";
        lastError = redact(error);
        availableAt = LocalDateTime.now(ZoneOffset.UTC).plusSeconds(Math.min(60, 5L * Math.max(1, attempts)));
    }

    public void retry() {
        status = "QUEUED";
        lastError = null;
        availableAt = LocalDateTime.now(ZoneOffset.UTC).minusSeconds(1);
    }

    private String redact(String error) {
        if (error == null || error.isBlank()) {
            return "Report generation failed";
        }
        String value = error.replaceAll("[\\r\\n\\t]+", " ").trim();
        return value.length() > 900 ? value.substring(0, 900) : value;
    }

    public UUID getId() {
        return id;
    }

    public UUID getReportVersionId() {
        return reportVersionId;
    }

    public String getStatus() {
        return status;
    }

    public int getAttempts() {
        return attempts;
    }

    public String getLastError() {
        return lastError;
    }

    public LocalDateTime getAvailableAt() {
        return availableAt;
    }
}
