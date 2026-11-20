package com.truereport.reference.api;

import java.util.List;
import java.util.Map;

public final class ReferenceWriteDtos {

    private ReferenceWriteDtos() {
    }

    public record ReferenceWriteRequest(
            String code,
            String labelKey,
            String tone,
            String icon,
            Integer order,
            Boolean selectable,
            List<String> visibleFor,
            List<String> allowedNext) {
    }

    public record ReorderEntry(String code, Integer order) {
    }

    public record TransitionEntry(
            String fromCode,
            String toCode,
            String role,
            Map<String, Object> guard) {
    }
}
