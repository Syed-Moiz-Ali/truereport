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
@Table(name = "template_items")
public class TemplateItem extends BaseEntity {

    @Id
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID id;

    @Column(name = "template_version_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID templateVersionId;

    @Column(name = "workshop_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID workshopId;

    @Column(name = "master_item_version_id", columnDefinition = "BINARY(16)", nullable = false)
    private UUID masterItemVersionId;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder;

    @Column(name = "included", nullable = false)
    private boolean included;

    @Column(name = "overrides_json", columnDefinition = "TEXT")
    private String overridesJson;

    @Column(name = "effective_rules_json", columnDefinition = "TEXT", nullable = false)
    private String effectiveRulesJson;

    protected TemplateItem() {
    }

    public TemplateItem(UUID templateVersionId, UUID workshopId, UUID masterItemVersionId,
                        int sortOrder, boolean included, String overridesJson,
                        String effectiveRulesJson) {
        this.templateVersionId = templateVersionId;
        this.workshopId = workshopId;
        this.masterItemVersionId = masterItemVersionId;
        this.sortOrder = sortOrder;
        this.included = included;
        this.overridesJson = overridesJson;
        this.effectiveRulesJson = effectiveRulesJson;
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

    public UUID getTemplateVersionId() {
        return templateVersionId;
    }

    public UUID getWorkshopId() {
        return workshopId;
    }

    public UUID getMasterItemVersionId() {
        return masterItemVersionId;
    }

    public int getSortOrder() {
        return sortOrder;
    }

    public boolean isIncluded() {
        return included;
    }

    public String getOverridesJson() {
        return overridesJson;
    }

    public String getEffectiveRulesJson() {
        return effectiveRulesJson;
    }
}
