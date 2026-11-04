package com.truereport.jobs;

import com.truereport.shared.persistence.BaseEntity;
import com.truereport.shared.security.PiiStringConverter;
import com.truereport.shared.uuid.UuidV7;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "inspection_jobs")
public class InspectionJob extends BaseEntity {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "workshop_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID workshopId;

    @Column(name = "reference", nullable = false, length = 40)
    private String reference;

    @Column(name = "status", nullable = false, length = 32)
    private String status = "DRAFT";

    @Column(name = "template_version_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID templateVersionId;

    @Column(name = "assigned_technician_id", columnDefinition = "BINARY(16)")
    private UUID assignedTechnicianId;

    @Column(name = "created_by", columnDefinition = "BINARY(16)", nullable = false)
    private UUID createdBy;

    @Column(name = "scheduled_at")
    private LocalDateTime scheduledAt;

    @Column(name = "cancelled_at")
    private LocalDateTime cancelledAt;

    @Column(name = "cancel_reason", length = 255)
    private String cancelReason;

    @Convert(converter = PiiStringConverter.class)
    @Column(name = "customer_name", nullable = false, length = 512)
    private String customerName;

    @Convert(converter = PiiStringConverter.class)
    @Column(name = "customer_phone", length = 512)
    private String customerPhone;

    @Convert(converter = PiiStringConverter.class)
    @Column(name = "customer_email", length = 512)
    private String customerEmail;

    @Column(name = "vehicle_make", nullable = false, length = 100)
    private String vehicleMake;

    @Column(name = "vehicle_model", nullable = false, length = 100)
    private String vehicleModel;

    @Column(name = "vehicle_year")
    private Integer vehicleYear;

    @Convert(converter = PiiStringConverter.class)
    @Column(name = "vehicle_vin", length = 512)
    private String vehicleVin;

    @Convert(converter = PiiStringConverter.class)
    @Column(name = "vehicle_plate", length = 512)
    private String vehiclePlate;

    @Column(name = "scope", nullable = false, length = 500)
    private String scope;

    @Column(name = "vehicle_type", length = 60)
    private String vehicleType;

    @Column(name = "odometer_value")
    private Integer odometerValue;

    @Column(name = "odometer_unit", length = 8)
    private String odometerUnit;

    @Column(name = "started_at")
    private LocalDateTime startedAt;

    @Column(name = "ready_at")
    private LocalDateTime readyAt;

    @Column(name = "finalized_at")
    private LocalDateTime finalizedAt;

    @Column(name = "finalized_by", columnDefinition = "BINARY(16)")
    private UUID finalizedBy;

    @Column(name = "finalization_key_hash", columnDefinition = "BINARY(32)")
    private byte[] finalizationKeyHash;

    protected InspectionJob() {
    }

    public InspectionJob(UUID workshopId, String reference, UUID templateVersionId, UUID createdBy,
                         String customerName, String customerPhone, String customerEmail,
                         String vehicleMake, String vehicleModel, Integer vehicleYear,
                         String vehicleVin, String vehiclePlate, String scope,
                         LocalDateTime scheduledAt) {
        this.workshopId = workshopId;
        this.reference = reference;
        this.templateVersionId = templateVersionId;
        this.createdBy = createdBy;
        this.customerName = customerName;
        this.customerPhone = customerPhone;
        this.customerEmail = customerEmail;
        this.vehicleMake = vehicleMake;
        this.vehicleModel = vehicleModel;
        this.vehicleYear = vehicleYear;
        this.vehicleVin = vehicleVin;
        this.vehiclePlate = vehiclePlate;
        this.scope = scope;
        this.scheduledAt = scheduledAt;
        this.status = scheduledAt == null ? "DRAFT" : "SCHEDULED";
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

    public String getReference() {
        return reference;
    }

    public String getStatus() {
        return status;
    }

    public UUID getTemplateVersionId() {
        return templateVersionId;
    }

    public UUID getAssignedTechnicianId() {
        return assignedTechnicianId;
    }

    public UUID getCreatedBy() {
        return createdBy;
    }

    public LocalDateTime getScheduledAt() {
        return scheduledAt;
    }

    public LocalDateTime getCancelledAt() {
        return cancelledAt;
    }

    public String getCancelReason() {
        return cancelReason;
    }

    public String getCustomerName() {
        return customerName;
    }

    public String getCustomerPhone() {
        return customerPhone;
    }

    public String getCustomerEmail() {
        return customerEmail;
    }

    public String getVehicleMake() {
        return vehicleMake;
    }

    public String getVehicleModel() {
        return vehicleModel;
    }

    public Integer getVehicleYear() {
        return vehicleYear;
    }

    public String getVehicleVin() {
        return vehicleVin;
    }

    public String getVehiclePlate() {
        return vehiclePlate;
    }

    public String getScope() {
        return scope;
    }

    public void assign(UUID technicianId) {
        this.assignedTechnicianId = technicianId;
        if (!status.equals("FINALIZED") && !status.equals("CANCELLED")) {
            this.status = "ASSIGNED";
        }
    }

    public void cancel(LocalDateTime at, String reason) {
        this.status = "CANCELLED";
        this.cancelledAt = at;
        this.cancelReason = reason;
    }

    public String getVehicleType() {
        return vehicleType;
    }

    public Integer getOdometerValue() {
        return odometerValue;
    }

    public String getOdometerUnit() {
        return odometerUnit;
    }

    public LocalDateTime getStartedAt() {
        return startedAt;
    }

    public LocalDateTime getReadyAt() {
        return readyAt;
    }

    public LocalDateTime getFinalizedAt() {
        return finalizedAt;
    }

    public UUID getFinalizedBy() {
        return finalizedBy;
    }

    public byte[] getFinalizationKeyHash() {
        return finalizationKeyHash;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public void setAssignedTechnicianId(UUID assignedTechnicianId) {
        this.assignedTechnicianId = assignedTechnicianId;
    }

    public void setVehicleType(String vehicleType) {
        this.vehicleType = vehicleType;
    }

    public void updateCustomer(String name, String phone, String email) {
        this.customerName = name;
        this.customerPhone = phone;
        this.customerEmail = email;
    }

    public void updateVehicle(String make, String model, Integer year, String vin, String plate,
                              Integer odometerValue, String odometerUnit) {
        this.vehicleMake = make;
        this.vehicleModel = model;
        this.vehicleYear = year;
        this.vehicleVin = vin;
        this.vehiclePlate = plate;
        this.odometerValue = odometerValue;
        this.odometerUnit = odometerUnit;
    }

    public void start(LocalDateTime at) {
        this.status = "IN_PROGRESS";
        this.startedAt = at;
    }

    public void markReady(LocalDateTime at) {
        this.status = "READY_TO_FINALIZE";
        this.readyAt = at;
    }

    public void finalizeInspection(UUID actor, LocalDateTime at, byte[] keyHash) {
        this.status = "FINALIZED";
        this.finalizedBy = actor;
        this.finalizedAt = at;
        this.finalizationKeyHash = keyHash;
    }
}
