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
@Table(name = "assessments")
public class Assessment extends BaseEntity {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "workshop_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID workshopId;

    @Column(name = "job_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID jobId;

    @Column(name = "inspection_item_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID inspectionItemId;

    @Column(name = "technician_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID technicianId;

    @Column(name = "result_code", nullable = false, length = 40)
    private String resultCode;

    @Column(name = "severity_code", length = 40)
    private String severityCode;

    @Column(name = "note_text", columnDefinition = "TEXT")
    private String noteText;

    @Column(name = "note_language", length = 16)
    private String noteLanguage;

    @Column(name = "reason_code", length = 60)
    private String reasonCode;

    @Column(name = "reason_text", columnDefinition = "TEXT")
    private String reasonText;

    @Column(name = "client_revision", nullable = false)
    private long clientRevision;

    @Column(name = "server_revision", nullable = false)
    private long serverRevision;

    @Column(name = "base_version", nullable = false)
    private int baseVersion;

    protected Assessment() {
    }

    public Assessment(UUID workshopId, UUID jobId, UUID inspectionItemId, UUID technicianId,
                      String resultCode, String severityCode, String noteText, String noteLanguage,
                      String reasonCode, String reasonText, long clientRevision, int baseVersion) {
        this.workshopId = workshopId;
        this.jobId = jobId;
        this.inspectionItemId = inspectionItemId;
        this.technicianId = technicianId;
        this.resultCode = resultCode;
        this.severityCode = severityCode;
        this.noteText = noteText;
        this.noteLanguage = noteLanguage;
        this.reasonCode = reasonCode;
        this.reasonText = reasonText;
        this.clientRevision = clientRevision;
        this.serverRevision = 1;
        this.baseVersion = baseVersion;
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

    public UUID getInspectionItemId() {
        return inspectionItemId;
    }

    public UUID getTechnicianId() {
        return technicianId;
    }

    public String getResultCode() {
        return resultCode;
    }

    public String getSeverityCode() {
        return severityCode;
    }

    public String getNoteText() {
        return noteText;
    }

    public String getNoteLanguage() {
        return noteLanguage;
    }

    public String getReasonCode() {
        return reasonCode;
    }

    public String getReasonText() {
        return reasonText;
    }

    public long getClientRevision() {
        return clientRevision;
    }

    public long getServerRevision() {
        return serverRevision;
    }

    public int getBaseVersion() {
        return baseVersion;
    }

    public void update(String resultCode, String severityCode, String noteText, String noteLanguage,
                       String reasonCode, String reasonText, long clientRevision, int baseVersion) {
        this.resultCode = resultCode;
        this.severityCode = severityCode;
        this.noteText = noteText;
        this.noteLanguage = noteLanguage;
        this.reasonCode = reasonCode;
        this.reasonText = reasonText;
        this.clientRevision = clientRevision;
        this.baseVersion = baseVersion;
        this.serverRevision++;
    }
}
