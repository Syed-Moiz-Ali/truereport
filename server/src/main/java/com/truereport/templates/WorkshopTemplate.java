package com.truereport.templates;

import com.truereport.shared.persistence.BaseEntity;
import com.truereport.shared.uuid.UuidV7;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "workshop_templates")
public class WorkshopTemplate extends BaseEntity {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "workshop_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID workshopId;

    @Column(name = "name", nullable = false, length = 200)
    private String name;

    @Column(name = "description", length = 1000)
    private String description;

    @Column(name = "service_type", nullable = false, length = 60)
    private String serviceType;

    @Column(name = "vehicle_type", length = 60)
    private String vehicleType;

    @Column(name = "status", nullable = false, length = 32)
    private String status = "DRAFT";

    @Column(name = "current_published_version_id", columnDefinition = "BINARY(16)")
    private UUID currentPublishedVersionId;

    @Column(name = "created_by", columnDefinition = "BINARY(16)", nullable = false)
    private UUID createdBy;

    protected WorkshopTemplate() {
    }

    public WorkshopTemplate(UUID workshopId, String name, String description,
                            String serviceType, String vehicleType, UUID createdBy) {
        this.workshopId = workshopId;
        this.name = name;
        this.description = description;
        this.serviceType = serviceType;
        this.vehicleType = vehicleType;
        this.createdBy = createdBy;
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

    public String getName() {
        return name;
    }

    public String getDescription() {
        return description;
    }

    public String getServiceType() {
        return serviceType;
    }

    public String getVehicleType() {
        return vehicleType;
    }

    public String getStatus() {
        return status;
    }

    public UUID getCurrentPublishedVersionId() {
        return currentPublishedVersionId;
    }

    public UUID getCreatedBy() {
        return createdBy;
    }

    public void setName(String name) {
        this.name = name;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public void setServiceType(String serviceType) {
        this.serviceType = serviceType;
    }

    public void setVehicleType(String vehicleType) {
        this.vehicleType = vehicleType;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public void setCurrentPublishedVersionId(UUID value) {
        this.currentPublishedVersionId = value;
    }
}
