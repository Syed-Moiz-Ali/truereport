package com.truereport.shared.i18n;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

/**
 * Entity/field pairs resolved by API DTO reads. Every pair must exist in
 * {@code translatable_field}; the registry-guard test enforces it.
 */
public final class LocalizedFields {

    private static final Map<String, Set<String>> FIELDS;

    static {
        Map<String, Set<String>> fields = new LinkedHashMap<>();
        fields.put("CATEGORY", Set.of("name", "description"));
        fields.put("ITEM", Set.of("label", "instruction", "standardSpec"));
        fields.put("OPTION_SET", Set.of("name"));
        fields.put("OPTION_VALUE", Set.of("label"));
        fields.put("REASON", Set.of("label"));
        fields.put("EQUIPMENT", Set.of("label"));
        fields.put("DROPDOWN", Set.of("label"));
        fields.put("DROPDOWN_VALUE", Set.of("label"));
        fields.put("DOCUMENT_TYPE", Set.of("name"));
        FIELDS = Map.copyOf(fields);
    }

    private LocalizedFields() {
    }

    public static Map<String, Set<String>> all() {
        return FIELDS;
    }
}
