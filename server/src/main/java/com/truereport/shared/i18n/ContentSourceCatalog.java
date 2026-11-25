package com.truereport.shared.i18n;

import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * English source columns for the clean platform content tables, plus a hook for
 * modules that still keep labels outside those tables.
 */
@Component
public class ContentSourceCatalog {

    /** Pseudo scope for "every business content entity, excluding UI text". */
    public static final String CONTENT_SCOPE = "CONTENT";

    public record Source(String entityId, String text) {
    }

    private static final Map<String, String> PLATFORM_TABLES = Map.of(
            "CATEGORY", "platform_categories",
            "ITEM", "platform_item_versions",
            "OPTION_SET", "platform_option_sets",
            "OPTION_VALUE", "platform_option_values",
            "TEMPLATE", "platform_templates",
            "DOCUMENT_TYPE", "platform_document_types",
            "ISSUE_FIELD", "platform_issue_fields");

    private static final Map<String, Map<String, String>> PLATFORM_COLUMNS = Map.of(
            "CATEGORY", Map.of("name", "name"),
            "ITEM", Map.of("label", "label", "instruction", "instruction",
                    "standardSpec", "standard_spec"),
            "OPTION_SET", Map.of("name", "name"),
            "OPTION_VALUE", Map.of("label", "label"),
            "TEMPLATE", Map.of("name", "name", "description", "description"),
            "DOCUMENT_TYPE", Map.of("name", "name"),
            "ISSUE_FIELD", Map.of("label", "label"));

    private final JdbcTemplate jdbc;
    private final List<LegacyContentSource> legacySources;
    private final LanguageCatalog languages;
    private final Map<String, CachedCount> countCache = new java.util.concurrent.ConcurrentHashMap<>();

    /** Source counts change rarely; the desk polls the summary every few seconds. */
    private static final long COUNT_TTL_MS = 60_000;

    private record CachedCount(int value, long at) {
    }

    public ContentSourceCatalog(JdbcTemplate jdbc, List<LegacyContentSource> legacySources,
                                LanguageCatalog languages) {
        this.jdbc = jdbc;
        this.legacySources = legacySources;
        this.languages = languages;
    }

    public boolean isKnownEntityType(String entityType) {
        if (PLATFORM_TABLES.containsKey(entityType)) {
            return true;
        }
        return legacySources.stream().anyMatch(source -> source.entityTypes().contains(entityType));
    }

    public boolean exists(String entityType, String entityId) {
        if (entityType == null || entityId == null || entityId.isBlank()) {
            return false;
        }
        String table = PLATFORM_TABLES.get(entityType);
        if (table != null) {
            Integer count = jdbc.queryForObject(
                    "SELECT COUNT(*) FROM " + table + " WHERE id = ?", Integer.class, entityId);
            return count != null && count > 0;
        }
        return legacy(entityType)
                .map(source -> source.exists(entityType, entityId))
                .orElse(false);
    }

    /** English source text for a field, or {@code null} when the field has no source column. */
    public String source(String entityType, String entityId, String field, String sourceLang) {
        String table = PLATFORM_TABLES.get(entityType);
        if (table != null) {
            String column = PLATFORM_COLUMNS.getOrDefault(entityType, Map.of()).get(field);
            if (column == null) {
                return null;
            }
            try {
                return jdbc.queryForObject(
                        "SELECT " + column + " FROM " + table + " WHERE id = ?",
                        String.class, entityId);
            } catch (EmptyResultDataAccessException exception) {
                return null;
            }
        }
        return legacy(entityType)
                .map(source -> source.source(entityType, entityId, field, sourceLang))
                .orElse(null);
    }

    /** Writes the canonical source text (used by TO_CANONICAL jobs). */
    public boolean updateSource(String entityType, String entityId, String field, String text) {
        String table = PLATFORM_TABLES.get(entityType);
        if (table != null) {
            String column = PLATFORM_COLUMNS.getOrDefault(entityType, Map.of()).get(field);
            if (column == null) {
                return false;
            }
            return jdbc.update("UPDATE " + table + " SET " + column + " = ? WHERE id = ?",
                    text, entityId) > 0;
        }
        return legacy(entityType)
                .map(source -> source.updateSource(entityType, entityId, field, text,
                        languages.defaultLanguage()))
                .orElse(false);
    }

    public List<Source> sources(String entityType, String field, String sourceLang) {
        String table = PLATFORM_TABLES.get(entityType);
        if (table != null) {
            String column = PLATFORM_COLUMNS.getOrDefault(entityType, Map.of()).get(field);
            if (column == null) {
                return List.of();
            }
            // Option sets/values owned by the backend (statuses, enums, SEVERITY,
            // UNIT, YES_NO) are UI-catalog labels, not dynamic content: admins
            // never author them here, so they must not enter units/coverage or
            // the backfill queue. Catalogue sets stay translatable.
            if ("OPTION_SET".equals(entityType)) {
                return jdbc.query("""
                        SELECT id, %s AS source_text FROM platform_option_sets
                        WHERE code_locked = FALSE
                          AND %s IS NOT NULL AND %s <> ''
                        ORDER BY id
                        """.formatted(column, column, column),
                        (rs, i) -> new Source(rs.getString("id"),
                                rs.getString("source_text")));
            }
            if ("OPTION_VALUE".equals(entityType)) {
                return jdbc.query("""
                        SELECT v.id, v.%s AS source_text
                        FROM platform_option_values v
                        JOIN platform_option_sets s ON s.id = v.option_set_id
                        WHERE s.code_locked = FALSE
                          AND v.%s IS NOT NULL AND v.%s <> ''
                        ORDER BY v.id
                        """.formatted(column, column, column),
                        (rs, i) -> new Source(rs.getString("id"),
                                rs.getString("source_text")));
            }
            return jdbc.query("""
                    SELECT id, %s AS source_text FROM %s
                    WHERE %s IS NOT NULL AND %s <> ''
                    ORDER BY id
                    """.formatted(column, table, column, column),
                    (rs, i) -> new Source(rs.getString("id"), rs.getString("source_text")));
        }
        return legacy(entityType)
                .map(source -> source.sources(entityType, field, sourceLang))
                .orElseGet(List::of);
    }

    private Optional<LegacyContentSource> legacy(String entityType) {
        return legacySources.stream()
                .filter(source -> source.entityTypes().contains(entityType))
                .findFirst();
    }

    /** See {@link LegacyContentSource#lenientMachineGuards(String)}. */
    public boolean lenientMachineGuards(String entityType) {
        return legacy(entityType)
                .map(source -> source.lenientMachineGuards(entityType))
                .orElse(false);
    }

    /**
     * Source values in scope, when the owning module can count them cheaply.
     * Zero means "unknown", not "nothing" — callers must not render it as zero.
     */
    public int targetCount(String entityType) {
        if (entityType == null || entityType.isBlank()) {
            return 0;
        }
        CachedCount cached = countCache.get(entityType);
        long now = System.currentTimeMillis();
        if (cached != null && now - cached.at() < COUNT_TTL_MS) {
            return cached.value();
        }
        int value = computeTargetCount(entityType);
        countCache.put(entityType, new CachedCount(value, now));
        return value;
    }

    private int computeTargetCount(String entityType) {
        if (CONTENT_SCOPE.equals(entityType)) {
            int total = 0;
            for (Map.Entry<String, Map<String, String>> entry : PLATFORM_COLUMNS.entrySet()) {
                for (String field : entry.getValue().keySet()) {
                    total += platformCount(entry.getKey(), field);
                }
            }
            for (LegacyContentSource source : legacySources) {
                if (!source.partOfContentScope()) {
                    continue;
                }
                for (String type : source.entityTypes()) {
                    total += source.targetCount(type);
                }
            }
            return total;
        }
        int platform = 0;
        Map<String, String> fields = PLATFORM_COLUMNS.getOrDefault(entityType, Map.of());
        for (String field : fields.keySet()) {
            platform += platformCount(entityType, field);
        }
        if (platform > 0) {
            return platform;
        }
        return legacy(entityType)
                .map(source -> source.targetCount(entityType))
                .orElse(0);
    }

    /** Mirrors {@link #sources} so a count and the backfill agree. */
    private int platformCount(String entityType, String field) {
        String table = PLATFORM_TABLES.get(entityType);
        String column = PLATFORM_COLUMNS.getOrDefault(entityType, Map.of()).get(field);
        if (table == null || column == null) {
            return 0;
        }
        if ("OPTION_SET".equals(entityType)) {
            return count("""
                    SELECT COUNT(*) FROM platform_option_sets
                    WHERE code_locked = FALSE AND %s IS NOT NULL AND %s <> ''
                    """.formatted(column, column));
        }
        if ("OPTION_VALUE".equals(entityType)) {
            return count("""
                    SELECT COUNT(*) FROM platform_option_values v
                    JOIN platform_option_sets s ON s.id = v.option_set_id
                    WHERE s.code_locked = FALSE
                      AND v.%s IS NOT NULL AND v.%s <> ''
                    """.formatted(column, column));
        }
        return count("""
                SELECT COUNT(*) FROM %s WHERE %s IS NOT NULL AND %s <> ''
                """.formatted(table, column, column));
    }

    private int count(String sql) {
        Integer value = jdbc.queryForObject(sql, Integer.class);
        return value == null ? 0 : value;
    }

    public static String canonicalEntityType(String value) {
        return value == null ? "" : value.trim().toUpperCase(Locale.ROOT);
    }

    public static Optional<String> canonicalEntityId(String entityType, String value) {
        if (entityType != null && "UI_MESSAGE".equals(canonicalEntityType(entityType))) {
            return value == null || value.isBlank()
                    ? Optional.empty() : Optional.of(value.trim());
        }
        return canonicalEntityId(value);
    }

    static Optional<String> canonicalEntityId(String value) {
        if (value == null || value.isBlank()) {
            return Optional.empty();
        }
        try {
            return Optional.of(UUID.fromString(value.trim()).toString());
        } catch (IllegalArgumentException exception) {
            return Optional.empty();
        }
    }
}
