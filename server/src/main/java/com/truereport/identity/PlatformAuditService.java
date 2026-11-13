package com.truereport.identity;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.identity.api.AuditEventDto;
import com.truereport.identity.api.AuditEventPageDto;
import jakarta.persistence.EntityManager;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Service
public class PlatformAuditService {

    private static final int MAX_FETCH = 5000;

    private final JdbcTemplate jdbc;
    private final ObjectMapper objectMapper;
    private final EntityManager entityManager;

    public PlatformAuditService(JdbcTemplate jdbc, ObjectMapper objectMapper,
                                EntityManager entityManager) {
        this.jdbc = jdbc;
        this.objectMapper = objectMapper;
        this.entityManager = entityManager;
    }

    public List<AuditEventDto> query(String action, String entityType, String actor,
                                     String dateFrom, String dateTo, String search,
                                     String sort) {
        entityManager.flush();
        List<AuditEventDto> merged = new ArrayList<>();
        merged.addAll(platformEvents());
        merged.addAll(legacyEvents());
        List<AuditEventDto> filtered = merged.stream()
                .filter(event -> matches(event, action, entityType, actor,
                        dateFrom, dateTo, search))
                .sorted(comparator(sort))
                .limit(MAX_FETCH)
                .toList();
        return filtered;
    }

    public AuditEventPageDto page(String action, String entityType, String actor,
                                  String dateFrom, String dateTo, String search,
                                  String sort, int page, int size) {
        int safeSize = Math.max(1, Math.min(size, 200));
        int safePage = Math.max(0, page);
        List<AuditEventDto> all = query(action, entityType, actor, dateFrom,
                dateTo, search, sort);
        int from = Math.min(all.size(), safePage * safeSize);
        int to = Math.min(all.size(), from + safeSize);
        return new AuditEventPageDto(all.subList(from, to), all.size(), safePage,
                safeSize);
    }

    public byte[] export(String format, String action, String entityType,
                         String actor, String dateFrom, String dateTo,
                         String search, String sort) {
        List<AuditEventDto> events = query(action, entityType, actor, dateFrom,
                dateTo, search, sort);
        if ("json".equalsIgnoreCase(format)) {
            try {
                return objectMapper.writeValueAsBytes(events);
            } catch (Exception error) {
                throw new IllegalStateException("Cannot export audit events", error);
            }
        }
        StringBuilder csv = new StringBuilder(
                "id,action,entityType,entityId,actorRole,occurredAt,reasonCode,metadataJson\n");
        for (AuditEventDto event : events) {
            csv.append(csv(event.id()))
                    .append(',').append(csv(event.action()))
                    .append(',').append(csv(event.entityType()))
                    .append(',').append(csv(event.entityId()))
                    .append(',').append(csv(event.actorRole()))
                    .append(',').append(csv(event.occurredAt()))
                    .append(',').append(csv(event.reasonCode()))
                    .append(',').append(csv(event.metadataJson()))
                    .append('\n');
        }
        return csv.toString().getBytes(java.nio.charset.StandardCharsets.UTF_8);
    }

    private List<AuditEventDto> platformEvents() {
        return jdbc.query("""
                SELECT id, actor_user_id, actor_role, action_code, entity_type,
                       entity_id, occurred_at, reason, after_json
                FROM platform_audit_events
                ORDER BY occurred_at DESC
                LIMIT %d
                """.formatted(MAX_FETCH), (rs, i) -> new AuditEventDto(
                parseUuid(rs.getString("id")),
                null,
                parseUuid(rs.getString("actor_user_id")),
                rs.getString("actor_role"),
                rs.getString("action_code"),
                rs.getString("entity_type"),
                parseUuid(rs.getString("entity_id")),
                time(rs.getObject("occurred_at", LocalDateTime.class)),
                rs.getString("reason"),
                rs.getString("after_json")));
    }

    private List<AuditEventDto> legacyEvents() {
        return jdbc.query("""
                SELECT id, workshop_id, actor_user_id, actor_role, action,
                       entity_type, entity_id, occurred_at, reason_code,
                       metadata_json
                FROM audit_events
                ORDER BY occurred_at DESC
                LIMIT %d
                """.formatted(MAX_FETCH), (rs, i) -> new AuditEventDto(
                rs.getObject("id", UUID.class),
                rs.getObject("workshop_id", UUID.class),
                rs.getObject("actor_user_id", UUID.class),
                rs.getString("actor_role"),
                rs.getString("action"),
                rs.getString("entity_type"),
                rs.getObject("entity_id", UUID.class),
                time(rs.getObject("occurred_at", LocalDateTime.class)),
                rs.getString("reason_code"),
                rs.getString("metadata_json")));
    }

    private boolean matches(AuditEventDto event, String action, String entityType,
                            String actor, String dateFrom, String dateTo,
                            String search) {
        if (action != null && !action.isBlank()
                && !equalsIgnoreCase(event.action(), action)) {
            return false;
        }
        if (entityType != null && !entityType.isBlank()
                && !equalsIgnoreCase(event.entityType(), entityType)) {
            return false;
        }
        if (actor != null && !actor.isBlank()) {
            String needle = actor.trim().toLowerCase(Locale.ROOT);
            String actorId = event.actorUserId() == null
                    ? "" : event.actorUserId().toString().toLowerCase(Locale.ROOT);
            String role = event.actorRole() == null
                    ? "" : event.actorRole().toLowerCase(Locale.ROOT);
            if (!actorId.contains(needle) && !role.contains(needle)) {
                return false;
            }
        }
        String occurredAt = event.occurredAt() == null ? "" : event.occurredAt();
        if (dateFrom != null && !dateFrom.isBlank()
                && occurredAt.compareTo(dateFrom.trim()) < 0) {
            return false;
        }
        if (dateTo != null && !dateTo.isBlank()) {
            String end = dateTo.trim();
            if (end.length() == 10) {
                end = end + "T23:59:59.999999";
            }
            if (occurredAt.compareTo(end) > 0) {
                return false;
            }
        }
        if (search != null && !search.isBlank()) {
            String needle = search.trim().toLowerCase(Locale.ROOT);
            return contains(event.action(), needle)
                    || contains(event.entityType(), needle)
                    || contains(event.entityId() == null ? null
                            : event.entityId().toString(), needle)
                    || contains(event.actorRole(), needle)
                    || contains(event.reasonCode(), needle)
                    || contains(event.metadataJson(), needle);
        }
        return true;
    }

    private static Comparator<AuditEventDto> comparator(String sort) {
        String requested = sort == null || sort.isBlank()
                ? "occurredAt,desc" : sort.trim();
        String[] parts = requested.split(",");
        String field = parts[0].trim();
        boolean ascending = parts.length > 1
                && "asc".equalsIgnoreCase(parts[1].trim());
        Comparator<AuditEventDto> comparator = switch (field) {
            case "action" -> Comparator.comparing(
                    event -> nullToEmpty(event.action()), String.CASE_INSENSITIVE_ORDER);
            case "entityType" -> Comparator.comparing(
                    event -> nullToEmpty(event.entityType()), String.CASE_INSENSITIVE_ORDER);
            case "actor" -> Comparator.comparing(
                    event -> nullToEmpty(event.actorRole()), String.CASE_INSENSITIVE_ORDER);
            default -> Comparator.comparing(
                    event -> nullToEmpty(event.occurredAt()));
        };
        return ascending ? comparator : comparator.reversed();
    }

    private static boolean equalsIgnoreCase(String value, String expected) {
        return value != null && value.equalsIgnoreCase(expected.trim());
    }

    private static boolean contains(String value, String needle) {
        return value != null && value.toLowerCase(Locale.ROOT).contains(needle);
    }

    private static String nullToEmpty(String value) {
        return value == null ? "" : value;
    }

    private static String time(LocalDateTime value) {
        return value == null ? null : value.toString();
    }

    private static UUID parseUuid(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return UUID.fromString(value);
        } catch (IllegalArgumentException error) {
            return null;
        }
    }

    private static String csv(Object value) {
        if (value == null) {
            return "";
        }
        String text = value.toString();
        if (text.contains(",") || text.contains("\"")
                || text.contains("\n") || text.contains("\r")) {
            return "\"" + text.replace("\"", "\"\"") + "\"";
        }
        return text;
    }
}
