package com.truereport.shared.audit;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.uuid.UuidV7;
import com.truereport.shared.web.RequestIdFilter;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.MDC;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

/**
 * Append-only, field-level audit trail for the rebuilt platform configuration.
 */
@Service
public class FieldAuditService {

    private final JdbcTemplate jdbc;
    private final ObjectMapper objectMapper;

    public FieldAuditService(JdbcTemplate jdbc, ObjectMapper objectMapper) {
        this.jdbc = jdbc;
        this.objectMapper = objectMapper;
    }

    public void record(CurrentUser actor, String action, String entityType, String entityId,
                       Object before, Object after, String reason, HttpServletRequest request) {
        jdbc.update("""
                INSERT INTO platform_audit_events
                    (id, actor_user_id, actor_role, action_code, entity_type, entity_id, reason,
                     before_json, after_json, trace_id, ip_address, occurred_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
                """,
                UuidV7.generate().toString(),
                actor == null || actor.userId() == null ? null : actor.userId().toString(),
                actor == null ? null : actor.role(),
                action,
                entityType,
                entityId,
                trim(reason, 255),
                toJson(before),
                toJson(after),
                MDC.get(RequestIdFilter.MDC_KEY),
                request == null ? null : trim(request.getRemoteAddr(), 64));
    }

    public List<Map<String, Object>> recent(String entityType, String entityId, int limit) {
        String sql = entityType == null || entityType.isBlank()
                ? "SELECT * FROM platform_audit_events ORDER BY occurred_at DESC"
                : "SELECT * FROM platform_audit_events WHERE entity_type = ? ORDER BY occurred_at DESC";
        List<Map<String, Object>> rows = entityType == null || entityType.isBlank()
                ? jdbc.queryForList(sql)
                : jdbc.queryForList(sql, entityType);
        return rows.stream().limit(Math.max(1, limit)).toList();
    }

    private String toJson(Object value) {
        if (value == null) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException ex) {
            return String.valueOf(value);
        }
    }

    private static String trim(String value, int max) {
        if (value == null) {
            return null;
        }
        return value.length() <= max ? value : value.substring(0, max);
    }
}
