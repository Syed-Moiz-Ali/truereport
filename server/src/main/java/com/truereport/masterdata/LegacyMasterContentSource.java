package com.truereport.masterdata;

import com.truereport.shared.i18n.ContentSourceCatalog;
import com.truereport.shared.i18n.LegacyContentSource;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Legacy catalog labels ({@code master_reasons}, {@code equipment},
 * {@code master_dropdowns}, {@code master_dropdown_values}) keep their English
 * text in {@code localized_content}. This adapter exposes that source to the
 * generic translation engine without a module cycle.
 */
@Component
public class LegacyMasterContentSource implements LegacyContentSource {

    private static final Set<String> ENTITY_TYPES =
            Set.of("REASON", "EQUIPMENT", "DROPDOWN", "DROPDOWN_VALUE");

    private final LocalizedContentRepository localized;
    private final MasterReasonRepository reasons;
    private final EquipmentRepository equipment;
    private final MasterDropdownRepository dropdowns;
    private final MasterDropdownValueRepository dropdownValues;

    public LegacyMasterContentSource(LocalizedContentRepository localized,
                                     MasterReasonRepository reasons,
                                     EquipmentRepository equipment,
                                     MasterDropdownRepository dropdowns,
                                     MasterDropdownValueRepository dropdownValues) {
        this.localized = localized;
        this.reasons = reasons;
        this.equipment = equipment;
        this.dropdowns = dropdowns;
        this.dropdownValues = dropdownValues;
    }

    @Override
    public Set<String> entityTypes() {
        return ENTITY_TYPES;
    }

    @Override
    public boolean exists(String entityType, String entityId) {
        UUID id;
        try {
            id = UUID.fromString(entityId);
        } catch (IllegalArgumentException exception) {
            return false;
        }
        return switch (entityType) {
            case "REASON" -> reasons.existsById(id);
            case "EQUIPMENT" -> equipment.existsById(id);
            case "DROPDOWN" -> dropdowns.existsById(id);
            case "DROPDOWN_VALUE" -> dropdownValues.existsById(id);
            default -> false;
        };
    }

    @Override
    public String source(String entityType, String entityId, String field, String sourceLang) {
        if (!"label".equals(field)) {
            return null;
        }
        try {
            return localized.findByEntityTypeAndEntityIdAndLocaleAndFieldKey(
                            entityType, UUID.fromString(entityId), sourceLang, field)
                    .map(LocalizedContent::getTextValue).orElse(null);
        } catch (IllegalArgumentException exception) {
            return null;
        }
    }

    @Override
    public List<ContentSourceCatalog.Source> sources(String entityType, String field,
                                                     String sourceLang) {
        if (!"label".equals(field)) {
            return List.of();
        }
        List<ContentSourceCatalog.Source> result = new ArrayList<>();
        for (LocalizedContent row : localized.findByEntityTypeAndLocaleAndFieldKey(
                entityType, sourceLang, field)) {
            if (row.getTextValue() != null && !row.getTextValue().isBlank()) {
                result.add(new ContentSourceCatalog.Source(
                        row.getEntityId().toString(), row.getTextValue()));
            }
        }
        return result;
    }

    @Override
    public boolean updateSource(String entityType, String entityId, String field, String text,
                                String sourceLang) {
        if (!"label".equals(field)) {
            return false;
        }
        try {
            UUID id = UUID.fromString(entityId);
            LocalizedContent row = localized
                    .findByEntityTypeAndEntityIdAndLocaleAndFieldKey(
                            entityType, id, sourceLang, field)
                    .orElseGet(() -> new LocalizedContent(entityType, id, sourceLang, field, ""));
            row.setTextValue(text == null ? "" : text);
            localized.save(row);
            return true;
        } catch (IllegalArgumentException exception) {
            return false;
        }
    }
}
