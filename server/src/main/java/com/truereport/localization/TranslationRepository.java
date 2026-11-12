package com.truereport.localization;

import com.truereport.shared.uuid.UuidV7;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Overlay translations for dynamic languages. One row per
 * (entity_type, entity_id, field, language); the base EN/AR columns stay the
 * source of truth for English and Arabic.
 */
@Repository
public class TranslationRepository {

    public record Overlay(String text, String status) {
    }

    private final JdbcTemplate jdbc;

    public TranslationRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Map<String, Overlay> overlays(String entityType, String entityId, String field) {
        List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT lang, body, status FROM platform_translations
                WHERE entity_type = ? AND entity_id = ? AND field_name = ?
                """, entityType, entityId, field);
        Map<String, Overlay> result = new HashMap<>();
        for (Map<String, Object> row : rows) {
            result.put((String) row.get("lang"),
                    new Overlay((String) row.get("body"), (String) row.get("status")));
        }
        return result;
    }

    public Map<String, Map<String, Overlay>> overlaysForLanguage(String language) {
        List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT entity_type, entity_id, field_name, body, status
                FROM platform_translations WHERE lang = ?
                """, language);
        Map<String, Map<String, Overlay>> result = new HashMap<>();
        for (Map<String, Object> row : rows) {
            String key = row.get("entity_type") + "|" + row.get("entity_id") + "|" + row.get("field_name");
            result.computeIfAbsent(key, ignored -> new HashMap<>());
            result.get(key).put(language,
                    new Overlay((String) row.get("body"), (String) row.get("status")));
        }
        return result;
    }

    public Overlay find(String entityType, String entityId, String field, String language) {
        List<Overlay> rows = jdbc.query("""
                SELECT body, status FROM platform_translations
                WHERE entity_type = ? AND entity_id = ? AND field_name = ? AND lang = ?
                """, (rs, i) -> new Overlay(rs.getString("body"), rs.getString("status")),
                entityType, entityId, field, language);
        return rows.stream().findFirst().orElse(null);
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
                    """, UuidV7.generate().toString(), entityType, entityId, field, language,
                    text, status);
        }
    }

    public int countApproved(String language) {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_translations WHERE lang = ? AND status = 'APPROVED'
                """, Integer.class, language);
        return count == null ? 0 : count;
    }
}
