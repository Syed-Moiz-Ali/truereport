package com.truereport.shared.i18n;

import com.truereport.shared.jdbc.JdbcTime;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Repository
public class TranslationJobStore {

    public static final String TO_CANONICAL = "TO_CANONICAL";
    public static final String FROM_CANONICAL = "FROM_CANONICAL";

    public record JobRow(String id, String entityType, String entityId, String field, String lang,
                         String direction, String state, int attempts, String error,
                         LocalDateTime nextAttemptAt, LocalDateTime createdAt) {
    }

    private final JdbcTemplate jdbc;

    public TranslationJobStore(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /**
     * Insert a pending job, or reset a finished one. Pending/running jobs are
     * left alone so repeated updates do not duplicate work.
     */
    public void enqueue(String entityType, String entityId, String field, String lang,
                        String direction) {
        enqueueIfPending(entityType, entityId, field, lang, direction);
    }

    /**
     * Same contract as {@link #enqueue}, but reports whether this call actually
     * left a job waiting for the worker (inserted, or restarted a finished one).
     * A concurrent insert on the unique key is treated as "someone else did it".
     */
    public boolean enqueueIfPending(String entityType, String entityId, String field, String lang,
                                    String direction) {
        JobRow existing = find(entityType, entityId, field, lang, direction).orElse(null);
        if (existing == null) {
            try {
                jdbc.update("""
                        INSERT INTO content_translation_job
                            (id, entity_type, entity_id, field_name, lang, direction, state,
                             attempts, error, next_attempt_at, created_at, updated_at)
                        VALUES (?, ?, ?, ?, ?, ?, 'PENDING', 0, NULL, NULL,
                                CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                        """, com.truereport.shared.uuid.UuidV7.generate().toString(),
                        entityType, entityId, field, lang, direction);
                return true;
            } catch (DuplicateKeyException exception) {
                return false;
            }
        }
        if ("DONE".equals(existing.state()) || "FAILED".equals(existing.state())) {
            jdbc.update("""
                    UPDATE content_translation_job
                    SET state = 'PENDING', attempts = 0, error = NULL,
                        next_attempt_at = NULL, updated_at = CURRENT_TIMESTAMP
                    WHERE id = ?
                    """, existing.id());
            return true;
        }
        return false;
    }

    public Optional<JobRow> find(String entityType, String entityId, String field, String lang,
                                 String direction) {
        return jdbc.query("""
                SELECT id, entity_type, entity_id, field_name, lang, direction, state,
                       attempts, error, next_attempt_at, created_at
                FROM content_translation_job
                WHERE entity_type = ? AND entity_id = ? AND field_name = ? AND lang = ?
                  AND direction = ?
                """, MAPPER, entityType, entityId, field, lang, direction).stream().findFirst();
    }

    public List<JobRow> forEntity(String entityType, String entityId) {
        return jdbc.query("""
                SELECT id, entity_type, entity_id, field_name, lang, direction, state,
                       attempts, error, next_attempt_at, created_at
                FROM content_translation_job
                WHERE entity_type = ? AND entity_id = ?
                ORDER BY created_at, id
                """, MAPPER, entityType, entityId);
    }

    public List<JobRow> due(int limit, boolean skipLocked) {
        String suffix = skipLocked ? " FOR UPDATE SKIP LOCKED" : " FOR UPDATE";
        return jdbc.query("""
                SELECT id, entity_type, entity_id, field_name, lang, direction, state,
                       attempts, error, next_attempt_at, created_at
                FROM content_translation_job
                WHERE state = 'PENDING'
                  AND (next_attempt_at IS NULL OR next_attempt_at <= CURRENT_TIMESTAMP)
                ORDER BY created_at, id
                LIMIT %d%s
                """.formatted(limit, suffix), MAPPER);
    }

    public void markRunning(String id) {
        jdbc.update("""
                UPDATE content_translation_job
                SET state = 'RUNNING', attempts = attempts + 1, updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """, id);
    }

    public void markDone(String id) {
        jdbc.update("""
                UPDATE content_translation_job
                SET state = 'DONE', error = NULL, next_attempt_at = NULL,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """, id);
    }

    public void markPending(String id, LocalDateTime nextAttemptAt) {
        jdbc.update("""
                UPDATE content_translation_job
                SET state = 'PENDING', next_attempt_at = ?, updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """, nextAttemptAt, id);
    }

    /** A crashed worker leaves RUNNING jobs; return them to PENDING after the timeout. */
    public int recoverStale(int staleTimeoutSeconds) {
        LocalDateTime cutoff = LocalDateTime.now().minusSeconds(Math.max(1, staleTimeoutSeconds));
        return jdbc.update("""
                UPDATE content_translation_job
                SET state = 'PENDING', next_attempt_at = NULL, updated_at = CURRENT_TIMESTAMP,
                    error = 'Recovered after a stale RUNNING lease'
                WHERE state = 'RUNNING' AND updated_at < ?
                """, cutoff);
    }

    public void markFailed(String id, String error) {        jdbc.update("""
                UPDATE content_translation_job
                SET state = 'FAILED', error = ?, next_attempt_at = NULL,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """, error == null ? null : error.substring(0, Math.min(500, error.length())), id);
    }

    public void deleteAll(String entityType, String entityId) {
        jdbc.update("""
                DELETE FROM content_translation_job WHERE entity_type = ? AND entity_id = ?
                """, entityType, entityId);
    }

    public boolean hasPending(String entityType, String entityId, String direction) {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM content_translation_job
                WHERE entity_type = ? AND entity_id = ? AND direction = ?
                  AND state IN ('PENDING', 'RUNNING')
                """, Integer.class, entityType, entityId, direction);
        return count != null && count > 0;
    }

    public List<String> pendingEntityIds(String entityType, String direction,
                                         java.util.Collection<String> entityIds) {
        if (entityIds == null || entityIds.isEmpty()) {
            return List.of();
        }
        List<Object> args = new java.util.ArrayList<>();
        args.add(entityType);
        args.add(direction);
        args.addAll(entityIds);
        String placeholders = String.join(",",
                java.util.Collections.nCopies(entityIds.size(), "?"));
        return jdbc.query("""
                SELECT DISTINCT entity_id FROM content_translation_job
                WHERE entity_type = ? AND direction = ? AND state IN ('PENDING', 'RUNNING')
                  AND entity_id IN (%s)
                """.formatted(placeholders), (rs, i) -> rs.getString(1), args.toArray());
    }

    public int count(String state) {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM content_translation_job WHERE state = ?
                """, Integer.class, state);
        return count == null ? 0 : count;
    }

    /**
     * One query for the job state of many entity/field/lang pairs, keyed by
     * {@code entityId|field|lang}. Missing keys mean "no job row".
     */
    public Map<String, String> statesFor(String entityType, String field,
                                         Collection<String> entityIds, Collection<String> langs,
                                         String direction) {
        Map<String, String> result = new LinkedHashMap<>();
        if (entityIds == null || entityIds.isEmpty() || langs == null || langs.isEmpty()) {
            return result;
        }
        List<Object> args = new ArrayList<>();
        args.add(entityType);
        args.add(field);
        args.add(direction);
        String idPlaceholders = String.join(",",
                java.util.Collections.nCopies(entityIds.size(), "?"));
        args.addAll(entityIds);
        String langPlaceholders = String.join(",",
                java.util.Collections.nCopies(langs.size(), "?"));
        args.addAll(langs);
        jdbc.query("""
                SELECT entity_id, lang, state
                FROM content_translation_job
                WHERE entity_type = ? AND field_name = ? AND direction = ?
                  AND entity_id IN (%s) AND lang IN (%s)
                """.formatted(idPlaceholders, langPlaceholders),
                (rs, i) -> {
                    result.put(rs.getString("entity_id") + "|" + rs.getString("lang"),
                            rs.getString("state"));
                    return null;
                }, args.toArray());
        return result;
    }

    private static final RowMapper<JobRow> MAPPER = (rs, i) -> new JobRow(
            rs.getString("id"), rs.getString("entity_type"), rs.getString("entity_id"),
            rs.getString("field_name"), rs.getString("lang"), rs.getString("direction"),
            rs.getString("state"), rs.getInt("attempts"), rs.getString("error"),
            JdbcTime.localDateTime(rs, "next_attempt_at"),
            JdbcTime.localDateTime(rs, "created_at"));
}
