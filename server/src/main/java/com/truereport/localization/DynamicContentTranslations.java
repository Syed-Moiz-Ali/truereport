package com.truereport.localization;

import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/**
 * Reads and writes the dynamic content translation overlay.
 *
 * <p>English (the default language) is the single source column. Every other
 * language is stored as one {@code platform_translations} row per
 * entity/field/language. Nothing here is hardcoded to Arabic.</p>
 */
@Service
public class DynamicContentTranslations {

    public static final Map<String, List<String>> FIELDS = TranslationFieldRegistry.FIELDS;

    private static final Set<String> STATUSES =
            Set.of("DRAFT", "TRANSLATING", "REVIEWED", "APPROVED");

    private final JdbcTemplate jdbc;
    private final LanguageRepository languages;

    public DynamicContentTranslations(JdbcTemplate jdbc, LanguageRepository languages) {
        this.jdbc = jdbc;
        this.languages = languages;
    }

    /**
     * Returns field -> language -> text. The source/default language is always
     * present from the supplied source value; other languages come from the
     * overlay. Missing languages are simply absent.
     */
    public Map<String, Map<String, String>> view(String entityType, String entityId,
                                                 Map<String, String> sources) {
        String defaultCode = defaultCode();
        Map<String, Map<String, String>> result = new LinkedHashMap<>();
        sources.forEach((field, value) -> {
            Map<String, String> byLanguage = new LinkedHashMap<>();
            if (value != null && !value.isBlank()) {
                byLanguage.put(defaultCode, value);
            }
            result.put(field, byLanguage);
        });
        List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT field_name, lang, body FROM platform_translations
                WHERE entity_type = ? AND entity_id = ?
                ORDER BY field_name, lang
                """, entityType, entityId);
        for (Map<String, Object> row : rows) {
            String field = string(row.get("field_name"));
            if (!result.containsKey(field)) {
                continue;
            }
            String body = string(row.get("body"));
            if (!body.isBlank()) {
                result.get(field).put(string(row.get("lang")), body);
            }
        }
        return result;
    }

    public Map<String, Map<String, Map<String, String>>> viewMany(
            String entityType, Map<String, Map<String, String>> sourcesByEntity) {
        Map<String, Map<String, Map<String, String>>> overlays = new LinkedHashMap<>();
        List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT entity_id, field_name, lang, body FROM platform_translations
                WHERE entity_type = ?
                ORDER BY entity_id, field_name, lang
                """, entityType);
        for (Map<String, Object> row : rows) {
            String entityId = string(row.get("entity_id"));
            String field = string(row.get("field_name"));
            String body = string(row.get("body"));
            if (body.isBlank()) {
                continue;
            }
            overlays.computeIfAbsent(entityId, ignored -> new LinkedHashMap<>())
                    .computeIfAbsent(field, ignored -> new LinkedHashMap<>())
                    .put(string(row.get("lang")), body);
        }
        Map<String, Map<String, Map<String, String>>> result = new LinkedHashMap<>();
        String defaultCode = defaultCode();
        sourcesByEntity.forEach((entityId, sources) -> {
            Map<String, Map<String, String>> local = new LinkedHashMap<>();
            sources.forEach((field, value) -> {
                Map<String, String> byLanguage = new LinkedHashMap<>();
                if (value != null && !value.isBlank()) {
                    byLanguage.put(defaultCode, value);
                }
                Map<String, String> stored = overlays
                        .getOrDefault(entityId, Map.of())
                        .getOrDefault(field, Map.of());
                stored.forEach(byLanguage::put);
                local.put(field, byLanguage);
            });
            result.put(entityId, local);
        });
        return result;
    }

    /** Resolves one field/language value with default-language fallback. */
    public String resolve(String entityType, String entityId, String field,
                          String language, String sourceValue) {
        String defaultCode = defaultCode();
        String target = normalize(language);
        if (target.isBlank() || target.equals(defaultCode)) {
            return sourceValue == null ? "" : sourceValue;
        }
        String body = jdbc.query("""
                SELECT body FROM platform_translations
                WHERE entity_type = ? AND entity_id = ? AND field_name = ? AND lang = ?
                """, (rs, i) -> rs.getString(1), entityType, entityId, field, target)
                .stream().findFirst().orElse(null);
        if (body != null && !body.isBlank()) {
            return body;
        }
        return sourceValue == null ? "" : sourceValue;
    }

    /**
     * Stores non-source translations. Blank target text deletes the overlay row
     * so the field is reported as missing rather than saved empty.
     */
    public void saveOverlays(String entityType, String entityId,
                             Map<String, Map<String, String>> translations, String status) {
        if (translations == null || translations.isEmpty()) {
            return;
        }
        List<String> fields = TranslationFieldRegistry.fieldsFor(entityType);
        if (fields == null) {
            return;
        }
        String defaultCode = defaultCode();
        String normalizedStatus = normalizeStatus(status);
        for (Map.Entry<String, Map<String, String>> fieldEntry : translations.entrySet()) {
            String field = fieldEntry.getKey();
            if (!fields.contains(field) || fieldEntry.getValue() == null) {
                continue;
            }
            for (Map.Entry<String, String> languageEntry : fieldEntry.getValue().entrySet()) {
                String language = requireLanguage(languageEntry.getKey());
                if (language.equals(defaultCode)) {
                    continue;
                }
                String text = languageEntry.getValue();
                if (text == null || text.isBlank()) {
                    jdbc.update("""
                            DELETE FROM platform_translations
                            WHERE entity_type = ? AND entity_id = ? AND field_name = ? AND lang = ?
                            """, entityType, entityId, field, language);
                    continue;
                }
                upsert(entityType, entityId, field, language, text.trim(), normalizedStatus);
            }
        }
    }

    public void deleteAll(String entityType, String entityId) {
        jdbc.update("DELETE FROM platform_translations WHERE entity_type = ? AND entity_id = ?",
                entityType, entityId);
    }

    public void upsert(String entityType, String entityId, String field, String language,
                       String text, String status) {
        int updated = jdbc.update("""
                UPDATE platform_translations
                SET body = ?, status = ?, updated_at = CURRENT_TIMESTAMP
                WHERE entity_type = ? AND entity_id = ? AND field_name = ? AND lang = ?
                """, text, status, entityType, entityId, field, language);
        if (updated == 0) {
            jdbc.update("""
                    INSERT INTO platform_translations
                        (id, entity_type, entity_id, field_name, lang, body, status,
                         created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                    """, com.truereport.shared.uuid.UuidV7.generate().toString(),
                    entityType, entityId, field, language, text, status);
        }
    }

    public String defaultCode() {
        String code = languages.defaultCode();
        return code == null || code.isBlank() ? "en" : code;
    }

    public String requireLanguage(String code) {
        String normalized = normalize(code);
        if (normalized.isBlank()) {
            throw ApiException.validation("LANGUAGE_REQUIRED",
                    "Language code is required",
                    List.of(FieldIssue.of("language", "LANGUAGE_REQUIRED",
                            "error.validation.failed")));
        }
        if (languages.find(normalized).isEmpty()) {
            throw ApiException.validation("LANGUAGE_UNKNOWN",
                    "Unknown language code",
                    List.of(FieldIssue.of("language", "LANGUAGE_UNKNOWN",
                            "error.locale.invalid")));
        }
        return normalized;
    }

    public void requireEnglishSource(String field, String value) {
        if (value == null || value.isBlank()) {
            throw ApiException.validation("TRANSLATION_REQUIRED",
                    "Default-language source text (" + defaultCode() + ") is required",
                    List.of(FieldIssue.of(field + "." + defaultCode(),
                            "TRANSLATION_REQUIRED", "error.translation.required")));
        }
    }

    /**
     * Copies caller-provided field/language maps and folds legacy {@code *Ar}
     * request values into the {@code ar} overlay without overwriting explicit
     * translation entries. Never invents a fixed-language source.
     */
    public Map<String, Map<String, String>> mergeLegacy(
            Map<String, Map<String, String>> translations, Map<String, String> legacy) {
        Map<String, Map<String, String>> merged = new LinkedHashMap<>();
        if (translations != null) {
            translations.forEach((field, values) -> {
                if (field == null) {
                    return;
                }
                merged.put(field, values == null
                        ? new LinkedHashMap<>() : new LinkedHashMap<>(values));
            });
        }
        if (legacy != null) {
            legacy.forEach((field, text) -> {
                if (field == null || text == null || text.isBlank()) {
                    return;
                }
                merged.computeIfAbsent(field, ignored -> new LinkedHashMap<>())
                        .putIfAbsent("ar", text.trim());
            });
        }
        return merged;
    }

    public String source(Map<String, Map<String, String>> translations,
                         String field, String fallback) {
        if (translations != null) {
            Map<String, String> byLanguage = translations.get(field);
            if (byLanguage != null) {
                String value = byLanguage.get(defaultCode());
                if (value != null && !value.isBlank()) {
                    return value.trim();
                }
            }
        }
        return fallback == null ? "" : fallback.trim();
    }

    private String normalize(String code) {
        return code == null ? "" : code.trim().toLowerCase(Locale.ROOT);
    }

    private String normalizeStatus(String status) {
        String value = status == null || status.isBlank()
                ? "DRAFT" : status.trim().toUpperCase(Locale.ROOT);
        if (!STATUSES.contains(value)) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                    "TRANSLATION_STATUS_INVALID", "error.validation.failed",
                    "Unknown translation status");
        }
        return value;
    }

    private static String string(Object value) {
        return value == null ? "" : value.toString();
    }
}
