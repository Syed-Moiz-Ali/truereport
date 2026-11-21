package com.truereport.reference;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.reference.ReferenceTaxonomy.DomainSeed;
import com.truereport.reference.ReferenceTaxonomy.SetSeed;
import com.truereport.reference.ReferenceTaxonomy.TransitionSeed;
import com.truereport.shared.uuid.UuidV7;
import com.truereport.uimessages.PlatformUiMessageCatalog;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.nio.ByteBuffer;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Idempotently seeds the backend-defined taxonomy into the option-set store.
 *
 * <p>Sets and values that are missing are inserted; existing rows are never
 * overwritten, so an admin edit to a label, tone or order survives a restart.
 * Transition seeding is unchanged.</p>
 */
@Service
public class ReferenceSeeder {

    private static final Logger log = LoggerFactory.getLogger(ReferenceSeeder.class);
    private static final List<String> CATALOG_NAMESPACES =
            List.of("common", "workshop_admin", "technician", "platform_admin");

    private final JdbcTemplate jdbc;
    private final PlatformUiMessageCatalog uiMessages;
    private final ObjectMapper objectMapper;

    public ReferenceSeeder(JdbcTemplate jdbc, PlatformUiMessageCatalog uiMessages,
                           ObjectMapper objectMapper) {
        this.jdbc = jdbc;
        this.uiMessages = uiMessages;
        this.objectMapper = objectMapper;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void seed() {
        int inserted = 0;
        for (SetSeed row : ReferenceTaxonomy.SETS) {
            inserted += upsertSet(row);
        }
        for (DomainSeed row : ReferenceTaxonomy.DOMAINS) {
            inserted += ensureValue(row);
        }
        for (TransitionSeed row : ReferenceTaxonomy.TRANSITIONS) {
            inserted += upsertTransition(row);
        }
        if (inserted > 0) {
            log.info("Seeded {} reference taxonomy row(s)", inserted);
        }
    }

    private int upsertSet(SetSeed row) {
        String id = findSetId(row.code());
        if (id == null) {
            jdbc.update("""
                    INSERT INTO platform_option_sets
                        (id, code, name, status, sort_order, set_kind, domain_key,
                         code_locked, created_at, updated_at, version)
                    VALUES (?, ?, ?, 'ACTIVE', ?, ?, ?, ?, CURRENT_TIMESTAMP,
                            CURRENT_TIMESTAMP, 0)
                    """, UuidV7.generate().toString(), row.code(),
                    row.name(), row.sortOrder(), row.kind(), row.domainKey(),
                    row.codeLocked());
            return 1;
        }
        // Repair rows created before the structural merge without touching an
        // admin-edited name, status or order.
        jdbc.update("""
                UPDATE platform_option_sets
                SET set_kind = ?, domain_key = ?, code_locked = ?,
                    updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE id = ? AND (domain_key IS NULL OR domain_key = '')
                """, row.kind(), row.domainKey(), row.codeLocked(), id);
        return 0;
    }

    private int ensureValue(DomainSeed row) {
        SetSeed set = ReferenceTaxonomy.setForDomain(row.domainKey());
        if (set == null) {
            log.warn("No option set defined for reference domain {}", row.domainKey());
            return 0;
        }
        String setId = findSetId(set.code());
        if (setId == null) {
            log.warn("Option set {} was not seeded", set.code());
            return 0;
        }
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_option_values
                WHERE option_set_id = ? AND code = ?
                """, Integer.class, setId, row.code());
        if (count != null && count > 0) {
            return 0;
        }
        jdbc.update("""
                INSERT INTO platform_option_values
                    (id, option_set_id, code, label, label_key, status, sort_order,
                     metadata_json, created_at, updated_at, version)
                VALUES (?, ?, ?, ?, ?, 'ACTIVE', ?, ?, CURRENT_TIMESTAMP,
                        CURRENT_TIMESTAMP, 0)
                """, UuidV7.generate().toString(), setId, row.code(),
                label(row.labelKey(), row.code()), row.labelKey(), row.order(),
                metadata(row));
        return 1;
    }

    private int upsertTransition(TransitionSeed row) {
        int updated = jdbc.update("""
                UPDATE status_transition
                SET guard_json = '{}', version = version + 1
                WHERE entity = ? AND from_code = ? AND to_code = ? AND role = ?
                """, row.entity(), row.fromCode(), row.toCode(), row.role());
        if (updated > 0) {
            return 0;
        }
        jdbc.update("""
                INSERT INTO status_transition
                    (id, entity, from_code, to_code, role, guard_json, version)
                VALUES (?, ?, ?, ?, ?, '{}', 0)
                """, idBytes(UuidV7.generate()), row.entity(), row.fromCode(),
                row.toCode(), row.role());
        return 1;
    }

    private String metadata(DomainSeed row) {
        Map<String, Object> metadata = new LinkedHashMap<>();
        metadata.put("tone", row.tone());
        metadata.put("icon", row.icon());
        metadata.put("selectable", row.selectable());
        metadata.put("visibleFor", row.visibleFor());
        metadata.put("allowedNext", ReferenceTaxonomy.allowedNext(row.domainKey(), row.code()));
        metadata.put("legacyDomain", row.domainKey());
        try {
            return objectMapper.writeValueAsString(metadata);
        } catch (Exception exception) {
            throw new IllegalStateException("Cannot serialize reference metadata", exception);
        }
    }

    private String label(String labelKey, String code) {
        if (labelKey != null && !labelKey.isBlank()) {
            for (String namespace : CATALOG_NAMESPACES) {
                String value = uiMessages.namespace(namespace, "en").values().get(labelKey);
                if (value != null && !value.isBlank()) {
                    return value;
                }
            }
        }
        return humanize(code);
    }

    private String findSetId(String code) {
        return jdbc.query("SELECT id FROM platform_option_sets WHERE code = ?",
                (rs, index) -> rs.getString(1), code).stream().findFirst().orElse(null);
    }

    private static String humanize(String code) {
        String[] parts = code.toLowerCase(java.util.Locale.ROOT).split("[_-]+");
        StringBuilder label = new StringBuilder();
        for (String part : parts) {
            if (part.isBlank()) {
                continue;
            }
            if (!label.isEmpty()) {
                label.append(' ');
            }
            label.append(Character.toUpperCase(part.charAt(0))).append(part.substring(1));
        }
        return label.isEmpty() ? code : label.toString();
    }

    static byte[] idBytes(UUID id) {
        return ByteBuffer.allocate(16)
                .putLong(id.getMostSignificantBits())
                .putLong(id.getLeastSignificantBits())
                .array();
    }
}
