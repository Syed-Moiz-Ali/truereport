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
@Table(name = "localized_content")
public class LocalizedContent extends BaseEntity {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "entity_type", nullable = false, length = 40)
    private String entityType;

    @Column(name = "entity_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID entityId;

    @Column(name = "locale", nullable = false, length = 16)
    private String locale;

    @Column(name = "field_key", nullable = false, length = 60)
    private String fieldKey;

    @Column(name = "text_value", columnDefinition = "TEXT", nullable = false)
    private String textValue;

    protected LocalizedContent() {
    }

    public LocalizedContent(String entityType, UUID entityId, String locale, String fieldKey, String textValue) {
        this.entityType = entityType;
        this.entityId = entityId;
        this.locale = locale;
        this.fieldKey = fieldKey;
        this.textValue = textValue;
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

    public String getEntityType() {
        return entityType;
    }

    public UUID getEntityId() {
        return entityId;
    }

    public String getLocale() {
        return locale;
    }

    public String getFieldKey() {
        return fieldKey;
    }

    public String getTextValue() {
        return textValue;
    }

    public void setTextValue(String textValue) {
        this.textValue = textValue;
    }
}
