package com.truereport.masterdata;

import com.truereport.shared.persistence.BaseEntity;
import com.truereport.shared.uuid.UuidV7;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "master_dropdown_values")
public class MasterDropdownValue extends BaseEntity {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "dropdown_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID dropdownId;

    @Column(name = "code", nullable = false, length = 60)
    private String code;

    @Column(name = "status", nullable = false, length = 32)
    private String status = "ACTIVE";

    @Column(name = "sort_order", nullable = false)
    private int sortOrder;

    protected MasterDropdownValue() {
    }

    public MasterDropdownValue(UUID dropdownId, String code, int sortOrder) {
        this.dropdownId = dropdownId;
        this.code = code;
        this.sortOrder = sortOrder;
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

    public UUID getDropdownId() {
        return dropdownId;
    }

    public String getCode() {
        return code;
    }

    public String getStatus() {
        return status;
    }

    public int getSortOrder() {
        return sortOrder;
    }
}
