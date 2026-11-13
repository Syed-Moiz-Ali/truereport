package com.truereport.localization;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Single source of truth for translatable dynamic-content fields.
 *
 * <p>English is stored in the neutral source column. Every other language is
 * stored in {@code platform_translations}. Backlog, readiness, generation and
 * publish gates all read this registry so the field lists cannot drift.</p>
 */
public final class TranslationFieldRegistry {

    private TranslationFieldRegistry() {
    }

    public static final List<String> GROUP_ORDER = List.of(
            "CATEGORY", "ITEM", "OPTION_SET", "OPTION_VALUE", "TEMPLATE",
            "DOCUMENT_TYPE", "ISSUE_FIELD");

    public static final Map<String, List<String>> FIELDS;

    static {
        Map<String, List<String>> fields = new LinkedHashMap<>();
        fields.put("CATEGORY", List.of("name"));
        fields.put("ITEM", List.of("label", "instruction", "standardSpec"));
        fields.put("OPTION_SET", List.of("name"));
        fields.put("OPTION_VALUE", List.of("label"));
        fields.put("TEMPLATE", List.of("name", "description"));
        fields.put("DOCUMENT_TYPE", List.of("name"));
        fields.put("ISSUE_FIELD", List.of("label"));
        FIELDS = java.util.Collections.unmodifiableMap(fields);
    }

    public static List<String> fieldsFor(String entityType) {
        return FIELDS.getOrDefault(entityType, List.of());
    }

    public static boolean contains(String entityType, String field) {
        return fieldsFor(entityType).contains(field);
    }
}
