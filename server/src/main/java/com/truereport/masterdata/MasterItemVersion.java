package com.truereport.masterdata;

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
@Table(name = "master_item_versions")
public class MasterItemVersion extends BaseEntity {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "item_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID itemId;

    @Column(name = "version_no", nullable = false)
    private int versionNo;

    @Column(name = "status", nullable = false, length = 32)
    private String status = "DRAFT";

    @Column(name = "result_options_json", columnDefinition = "TEXT")
    private String resultOptionsJson;

    @Column(name = "severity_policy_json", columnDefinition = "TEXT")
    private String severityPolicyJson;

    @Column(name = "applicability_json", columnDefinition = "TEXT")
    private String applicabilityJson;

    @Column(name = "reason_codes_json", columnDefinition = "TEXT")
    private String reasonCodesJson;

    @Column(name = "note_requirement", nullable = false, length = 32)
    private String noteRequirement = "OPTIONAL";

    @Column(name = "evidence_requirement", nullable = false, length = 32)
    private String evidenceRequirement = "NONE";

    @Column(name = "min_photos", nullable = false)
    private int minPhotos;

    @Column(name = "equipment_ids_json", columnDefinition = "TEXT")
    private String equipmentIdsJson;

    @Column(name = "guide_image_id", columnDefinition = "BINARY(16)")
    private UUID guideImageId;

    @Column(name = "published_at")
    private LocalDateTime publishedAt;

    @Column(name = "published_by", columnDefinition = "BINARY(16)")
    private UUID publishedBy;

    protected MasterItemVersion() {
    }

    public MasterItemVersion(UUID itemId, int versionNo) {
        this.itemId = itemId;
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

    public UUID getItemId() {
        return itemId;
    }

    public int getVersionNo() {
        return versionNo;
    }

    public String getStatus() {
        return status;
    }

    public String getResultOptionsJson() {
        return resultOptionsJson;
    }

    public String getSeverityPolicyJson() {
        return severityPolicyJson;
    }

    public String getApplicabilityJson() {
        return applicabilityJson;
    }

    public String getReasonCodesJson() {
        return reasonCodesJson;
    }

    public String getNoteRequirement() {
        return noteRequirement;
    }

    public String getEvidenceRequirement() {
        return evidenceRequirement;
    }

    public int getMinPhotos() {
        return minPhotos;
    }

    public String getEquipmentIdsJson() {
        return equipmentIdsJson;
    }

    public UUID getGuideImageId() {
        return guideImageId;
    }

    public LocalDateTime getPublishedAt() {
        return publishedAt;
    }

    public UUID getPublishedBy() {
        return publishedBy;
    }

    public void setResultOptionsJson(String value) {
        this.resultOptionsJson = value;
    }

    public void setSeverityPolicyJson(String value) {
        this.severityPolicyJson = value;
    }

    public void setApplicabilityJson(String value) {
        this.applicabilityJson = value;
    }

    public void setReasonCodesJson(String value) {
        this.reasonCodesJson = value;
    }

    public void setNoteRequirement(String value) {
        this.noteRequirement = value;
    }

    public void setEvidenceRequirement(String value) {
        this.evidenceRequirement = value;
    }

    public void setMinPhotos(int value) {
        this.minPhotos = value;
    }

    public void setEquipmentIdsJson(String value) {
        this.equipmentIdsJson = value;
    }

    public void setGuideImageId(UUID value) {
        this.guideImageId = value;
    }

    public void publish(UUID actor, LocalDateTime at) {
        this.status = "PUBLISHED";
        this.publishedBy = actor;
        this.publishedAt = at;
    }
}
