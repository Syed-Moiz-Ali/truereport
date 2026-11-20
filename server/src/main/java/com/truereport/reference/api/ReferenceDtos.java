package com.truereport.reference.api;

import java.util.List;
import java.util.Map;

public final class ReferenceDtos {

    private ReferenceDtos() {
    }

    public record ReferenceRecordDto(
            String code,
            String labelKey,
            String tone,
            String icon,
            int order,
            boolean selectable,
            List<String> visibleFor,
            List<String> allowedNext,
            int version,
            String status) {
    }

    public record TransitionDto(
            String fromCode,
            String toCode,
            String role,
            Map<String, Object> guard,
            int version) {
    }

    /**
     * Option-set values currently store literal labels. {@code labelKey} is
     * populated when the stored label resolves to an existing catalog key;
     * otherwise the literal text is returned through {@code label} as a
     * temporary bridge until Phase 2 migrates the option-set column to keys.
     */
    public record DropdownValueDto(
            String code,
            String labelKey,
            String label,
            int order,
            boolean selectable,
            String parentCode,
            int version) {
    }

    public record ImpactDto(int items, int jobs, int templates, int documents) {
    }
}
