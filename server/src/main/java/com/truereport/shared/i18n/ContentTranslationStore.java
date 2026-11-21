package com.truereport.shared.i18n;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * JDBC access to {@code content_translation} and {@code translatable_field}.
 */
@Repository
public class ContentTranslationStore {

    public record RegistryField(String entityType, String field, int maxLength,
                                String protectPatterns, boolean safetyCritical, boolean enabled) {
    }

    public record TranslationRow(String entityId, String field, String lang, String body,
                                 String origin, String status, String sourceLang,
                                 String sourceHash, String provider) {
    }

    public record ReviewRow(String entityType, String entityId, String field, String lang,
                            String body, String origin, String status, String provider,
                            String sourceHash, String reviewNote) {
    }

    public record StateCount(String state, int count) {
    }

    private final JdbcTemplate jdbc;

    public ContentTranslationStore(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Optional<RegistryField> field(String entityType, String field) {
        return jdbc.query("""
                SELECT entity_type, field_name, max_length, protect_patterns,
                       safety_critical, enabled
                FROM translatable_field
                WHERE entity_type = ? AND field_name = ? AND enabled = TRUE
                """, REGISTRY_MAPPER, entityType, field).stream().findFirst();
    }

    public List<RegistryField> fields(String entityType) {
        if (entityType == null) {
            return jdbc.query("""
                    SELECT entity_type, field_name, max_length, protect_patterns,
                           safety_critical, enabled
                    FROM translatable_field
                    WHERE enabled = TRUE
                    ORDER BY entity_type, field_name
                    """, REGISTRY_MAPPER);
        }
        return jdbc.query("""
                SELECT entity_type, field_name, max_length, protect_patterns,
                       safety_critical, enabled
                FROM translatable_field
                WHERE enabled = TRUE AND entity_type = ?
                ORDER BY entity_type, field_name
                """, REGISTRY_MAPPER, entityType);
    }

    /**
     * Languages that actually have at least one row, regardless of origin or
     * review status. One cheap {@code DISTINCT} scan; the caller intersects it
     * with the manifest.
     */
    public List<String> distinctLanguages() {
        return jdbc.queryForList("SELECT DISTINCT lang FROM content_translation",
                String.class);
    }

    public Optional<TranslationRow> find(String entityType, String entityId, String field,
                                         String lang) {
        return jdbc.query("""
                SELECT entity_id, field_name, lang, body, origin, status, source_lang,
                       source_hash, provider
                FROM content_translation
                WHERE entity_type = ? AND entity_id = ? AND field_name = ? AND lang = ?
                """, ROW_MAPPER, entityType, entityId, field, lang).stream().findFirst();
    }

    /**
     * One query for a whole list response: all requested ids/fields for the
     * requested languages.
     */
    public List<TranslationRow> findMany(String entityType, Collection<String> entityIds,
                                         Collection<String> fields, Collection<String> langs) {
        if (entityIds.isEmpty() || fields.isEmpty() || langs.isEmpty()) {
            return List.of();
        }
        List<Object> args = new ArrayList<>();
        args.add(entityType);
        String idPlaceholders = placeholders(entityIds.size());
        args.addAll(entityIds);
        String fieldPlaceholders = placeholders(fields.size());
        args.addAll(fields);
        String langPlaceholders = placeholders(langs.size());
        args.addAll(langs);
        return jdbc.query("""
                SELECT entity_id, field_name, lang, body, origin, status, source_lang,
                       source_hash, provider
                FROM content_translation
                WHERE entity_type = ?
                  AND entity_id IN (%s)
                  AND field_name IN (%s)
                  AND lang IN (%s)
                """.formatted(idPlaceholders, fieldPlaceholders, langPlaceholders),
                ROW_MAPPER, args.toArray());
    }

    public Map<String, TranslationRow> findManyForLang(String entityType,
                                                       Collection<String> entityIds,
                                                       String field, List<String> langs) {
        Map<String, TranslationRow> result = new LinkedHashMap<>();
        for (TranslationRow row : findMany(entityType, entityIds, List.of(field), langs)) {
            result.merge(row.entityId() + "|" + row.lang(), row, (left, right) -> left);
        }
        return result;
    }

    public List<ReviewRow> reviewQueue(String lang, String state, String entityType,
                                       int limit, int offset) {
        List<Object> args = new ArrayList<>();
        StringBuilder sql = new StringBuilder("""
                SELECT entity_type, entity_id, field_name, lang, body, origin, status,
                       provider, source_hash, review_note
                FROM content_translation
                WHERE lang = ? AND status = ?
                """);
        args.add(lang);
        args.add(state);
        if (entityType != null) {
            sql.append(" AND entity_type = ?");
            args.add(entityType);
        }
        sql.append(" ORDER BY updated_at, entity_type, entity_id, field_name LIMIT ? OFFSET ?");
        args.add(limit);
        args.add(offset);
        return jdbc.query(sql.toString(), REVIEW_MAPPER, args.toArray());
    }

    public int countReview(String lang, String state, String entityType) {
        List<Object> args = new ArrayList<>();
        StringBuilder sql = new StringBuilder("""
                SELECT COUNT(*) FROM content_translation WHERE lang = ? AND status = ?
                """);
        args.add(lang);
        args.add(state);
        if (entityType != null) {
            sql.append(" AND entity_type = ?");
            args.add(entityType);
        }
        Integer count = jdbc.queryForObject(sql.toString(), Integer.class, args.toArray());
        return count == null ? 0 : count;
    }

    public List<StateCount> summary(String lang) {
        List<Object> args = new ArrayList<>();
        StringBuilder sql = new StringBuilder("""
                SELECT status, COUNT(*) AS total FROM content_translation WHERE 1 = 1
                """);
        if (lang != null) {
            sql.append(" AND lang = ?");
            args.add(lang);
        }
        sql.append(" GROUP BY status ORDER BY status");
        return jdbc.query(sql.toString(), (rs, i) ->
                new StateCount(rs.getString("status"), rs.getInt("total")), args.toArray());
    }

    public int countByStatus(String lang, String state) {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM content_translation WHERE lang = ? AND status = ?
                """, Integer.class, lang, state);
        return count == null ? 0 : count;
    }

    public int countByStatusSafety(String lang, String state, boolean safetyCritical) {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM content_translation t
                JOIN translatable_field f
                  ON f.entity_type = t.entity_type AND f.field_name = t.field_name
                WHERE t.lang = ? AND t.status = ? AND f.safety_critical = ?
                """, Integer.class, lang, state, safetyCritical);
        return count == null ? 0 : count;
    }

    public void markReview(String entityType, String entityId, String field, String lang,
                           String status, String reviewedBy, String note) {
        jdbc.update("""
                UPDATE content_translation
                SET status = ?, reviewed_by = ?, reviewed_at = CURRENT_TIMESTAMP,
                    review_note = ?, updated_at = CURRENT_TIMESTAMP
                WHERE entity_type = ? AND entity_id = ? AND field_name = ? AND lang = ?
                """, status, reviewedBy, note, entityType, entityId, field, lang);
    }

    public void edit(String entityType, String entityId, String field, String lang,
                     String body, String sourceHash, String reviewedBy, String note) {
        jdbc.update("""
                UPDATE content_translation
                SET body = ?, origin = 'AUTHORED', status = 'REVIEWED', source_hash = ?,
                    provider = NULL, reviewed_by = ?, reviewed_at = CURRENT_TIMESTAMP,
                    review_note = ?, updated_at = CURRENT_TIMESTAMP
                WHERE entity_type = ? AND entity_id = ? AND field_name = ? AND lang = ?
                """, body, sourceHash, reviewedBy, note, entityType, entityId, field, lang);
    }

    public void markCanonicalStale(String entityType, String entityId, String field,
                                   String canonicalLang) {
        jdbc.update("""
                UPDATE content_translation
                SET status = 'STALE', updated_at = CURRENT_TIMESTAMP
                WHERE entity_type = ? AND entity_id = ? AND field_name = ? AND lang = ?
                  AND status <> 'STALE'
                """, entityType, entityId, field, canonicalLang);
    }

    public int markMachineStale(String entityType, String entityId, String field,
                                String excludeLang) {        return jdbc.update("""
                UPDATE content_translation
                SET status = 'STALE', updated_at = CURRENT_TIMESTAMP
                WHERE entity_type = ? AND entity_id = ? AND field_name = ?
                  AND origin = 'MACHINE' AND lang <> ? AND status <> 'STALE'
                """, entityType, entityId, field, excludeLang);
    }

    public List<TranslationRow> findForField(String entityType, String entityId, String field) {
        return jdbc.query("""
                SELECT entity_id, field_name, lang, body, origin, status, source_lang,
                       source_hash, provider
                FROM content_translation
                WHERE entity_type = ? AND entity_id = ? AND field_name = ?
                ORDER BY lang
                """, ROW_MAPPER, entityType, entityId, field);
    }

    public List<String> machinePendingIds(String entityType, String lang,
                                          java.util.Collection<String> entityIds) {
        if (entityIds == null || entityIds.isEmpty()) {
            return List.of();
        }
        List<Object> args = new ArrayList<>();
        args.add(entityType);
        args.add(lang);
        args.addAll(entityIds);
        String placeholders = placeholders(entityIds.size());
        return jdbc.query("""
                SELECT DISTINCT entity_id FROM content_translation
                WHERE entity_type = ? AND lang = ? AND origin = 'MACHINE'
                  AND status = 'PENDING_REVIEW' AND entity_id IN (%s)
                """.formatted(placeholders), (rs, i) -> rs.getString(1), args.toArray());
    }

    public void updateStatus(String entityType, String entityId, String field, String lang,
                             String status) {
        jdbc.update("""
                UPDATE content_translation
                SET status = ?, updated_at = CURRENT_TIMESTAMP
                WHERE entity_type = ? AND entity_id = ? AND field_name = ? AND lang = ?
                  AND status <> ?
                """, status, entityType, entityId, field, lang, status);
    }

    public void deleteAll(String entityType, String entityId) {
        jdbc.update("""
                DELETE FROM content_translation WHERE entity_type = ? AND entity_id = ?
                """, entityType, entityId);
    }

    public void upsert(String entityType, String entityId, String field, String lang,
                       String body, String origin, String status, String sourceLang,
                       String sourceHash, String provider, String reviewedBy) {
        int updated = jdbc.update("""
                UPDATE content_translation
                SET body = ?, origin = ?, status = ?, source_lang = ?, source_hash = ?,
                    provider = ?, reviewed_by = ?, reviewed_at = CURRENT_TIMESTAMP,
                    updated_at = CURRENT_TIMESTAMP
                WHERE entity_type = ? AND entity_id = ? AND field_name = ? AND lang = ?
                """, body, origin, status, sourceLang, sourceHash, provider, reviewedBy,
                entityType, entityId, field, lang);
        if (updated == 0) {
            jdbc.update("""
                    INSERT INTO content_translation
                        (id, entity_type, entity_id, field_name, lang, body, origin, status,
                         source_lang, source_hash, provider, reviewed_by, reviewed_at,
                         created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP,
                            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                    """, com.truereport.shared.uuid.UuidV7.generate().toString(),
                    entityType, entityId, field, lang, body, origin, status, sourceLang,
                    sourceHash, provider, reviewedBy);
        }
    }

    public int delete(String entityType, String entityId, String field, String lang) {
        return jdbc.update("""
                DELETE FROM content_translation
                WHERE entity_type = ? AND entity_id = ? AND field_name = ? AND lang = ?
                """, entityType, entityId, field, lang);
    }

    private static String placeholders(int count) {
        return String.join(",", java.util.Collections.nCopies(count, "?"));
    }

    private static final RowMapper<RegistryField> REGISTRY_MAPPER = (rs, i) ->
            new RegistryField(rs.getString("entity_type"), rs.getString("field_name"),
                    rs.getInt("max_length"), rs.getString("protect_patterns"),
                    rs.getBoolean("safety_critical"), rs.getBoolean("enabled"));

    private static final RowMapper<TranslationRow> ROW_MAPPER = (rs, i) ->
            new TranslationRow(rs.getString("entity_id"), rs.getString("field_name"),
                    rs.getString("lang"), rs.getString("body"), rs.getString("origin"),
                    rs.getString("status"), rs.getString("source_lang"),
                    rs.getString("source_hash"), rs.getString("provider"));

    private static final RowMapper<ReviewRow> REVIEW_MAPPER = (rs, i) ->
            new ReviewRow(rs.getString("entity_type"), rs.getString("entity_id"),
                    rs.getString("field_name"), rs.getString("lang"), rs.getString("body"),
                    rs.getString("origin"), rs.getString("status"), rs.getString("provider"),
                    rs.getString("source_hash"), rs.getString("review_note"));
}
