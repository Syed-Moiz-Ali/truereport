package com.truereport.audit;

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
@Table(name = "audit_events")
public class AuditEvent {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "workshop_id", columnDefinition = "BINARY(16)")
    private UUID workshopId;

    @Column(name = "actor_user_id", columnDefinition = "BINARY(16)")
    private UUID actorUserId;

    @Column(name = "actor_role", length = 32)
    private String actorRole;

    @Column(name = "action", nullable = false, length = 80)
    private String action;

    @Column(name = "entity_type", length = 80)
    private String entityType;

    @Column(name = "entity_id", columnDefinition = "BINARY(16)")
    private UUID entityId;

    @Column(name = "occurred_at", nullable = false)
    private LocalDateTime occurredAt;

    @Column(name = "request_id", length = 64)
    private String requestId;

    @Column(name = "reason_code", length = 64)
    private String reasonCode;

    @Column(name = "metadata_json", columnDefinition = "TEXT")
    private String metadataJson;

    protected AuditEvent() {
    }

    public AuditEvent(UUID workshopId, UUID actorUserId, String actorRole, String action,
                      String entityType, UUID entityId, String requestId, String reasonCode,
                      String metadataJson) {
        this.workshopId = workshopId;
        this.actorUserId = actorUserId;
        this.actorRole = actorRole;
        this.action = action;
        this.entityType = entityType;
        this.entityId = entityId;
        this.requestId = requestId;
        this.reasonCode = reasonCode;
        this.metadataJson = metadataJson;
        this.occurredAt = LocalDateTime.now(ZoneOffset.UTC);
    }

    @PrePersist
    void ensureId() {
        if (id == null) {
            id = UuidV7.generate();
        }
        if (occurredAt == null) {
            occurredAt = LocalDateTime.now(ZoneOffset.UTC);
        }
    }

    public UUID getId() {
        return id;
    }

    public UUID getWorkshopId() {
        return workshopId;
    }

    public UUID getActorUserId() {
        return actorUserId;
    }

    public String getActorRole() {
        return actorRole;
    }

    public String getAction() {
        return action;
    }

    public String getEntityType() {
        return entityType;
    }

    public UUID getEntityId() {
        return entityId;
    }

    public String getReasonCode() {
        return reasonCode;
    }

    public String getMetadataJson() {
        return metadataJson;
    }

    public LocalDateTime getOccurredAt() {
        return occurredAt;
    }
}
