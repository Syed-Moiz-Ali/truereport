package com.truereport.tenancy;

import com.truereport.shared.persistence.BaseEntity;
import com.truereport.shared.uuid.UuidV7;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "workshop_memberships")
public class WorkshopMembership extends BaseEntity {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "workshop_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID workshopId;

    @Column(name = "user_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "member_role", nullable = false, length = 32)
    private WorkshopRole role;

    @Column(name = "status", nullable = false, length = 32)
    private String status = "ACTIVE";

    @Column(name = "is_primary", nullable = false)
    private boolean primary;

    protected WorkshopMembership() {
    }

    public WorkshopMembership(UUID workshopId, UUID userId, WorkshopRole role, boolean primary) {
        this.workshopId = workshopId;
        this.userId = userId;
        this.role = role;
        this.primary = primary;
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

    public UUID getUserId() {
        return userId;
    }

    public WorkshopRole getRole() {
        return role;
    }

    public String getStatus() {
        return status;
    }

    public boolean isPrimary() {
        return primary;
    }

    public void setWorkshopId(UUID workshopId) {
        this.workshopId = workshopId;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public void setPrimary(boolean primary) {
        this.primary = primary;
    }
}
