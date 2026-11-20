package com.truereport.reference;

import com.truereport.reference.ReferenceTaxonomy.DomainSeed;
import com.truereport.reference.ReferenceTaxonomy.TransitionSeed;
import com.truereport.shared.uuid.UuidV7;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.nio.ByteBuffer;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Idempotently seeds the platform taxonomy. Existing rows are updated so a
 * changed label key/tone/visibility ships without a new migration; missing rows
 * (for example a new enum constant) are inserted on startup.
 */
@Service
public class ReferenceSeeder {

    private static final Logger log = LoggerFactory.getLogger(ReferenceSeeder.class);

    private final JdbcTemplate jdbc;

    public ReferenceSeeder(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void seed() {
        int inserted = 0;
        for (DomainSeed row : ReferenceTaxonomy.DOMAINS) {
            inserted += upsertDomain(row);
        }
        for (TransitionSeed row : ReferenceTaxonomy.TRANSITIONS) {
            inserted += upsertTransition(row);
        }
        if (inserted > 0) {
            log.info("Seeded {} reference taxonomy row(s)", inserted);
        }
    }

    private int upsertDomain(DomainSeed row) {
        LocalDateTime now = LocalDateTime.now();
        int updated = jdbc.update("""
                UPDATE reference_domain
                SET domain_type = ?, label_key = ?, tone = ?, icon = ?, sort_order = ?,
                    selectable = ?, visible_for_json = ?, allowed_next_json = ?,
                    status = 'PUBLISHED', updated_at = CURRENT_TIMESTAMP,
                    version = version + 1
                WHERE domain_key = ? AND code = ?
                """, row.domainType(), row.labelKey(), row.tone(), row.icon(), row.order(),
                row.selectable(), jsonArray(row.visibleFor()),
                jsonArray(ReferenceTaxonomy.allowedNext(row.domainKey(), row.code())),
                row.domainKey(), row.code());
        if (updated > 0) {
            return 0;
        }
        jdbc.update("""
                INSERT INTO reference_domain
                    (id, domain_type, domain_key, code, label_key, tone, icon, sort_order,
                     selectable, visible_for_json, allowed_next_json, status, version,
                     created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'PUBLISHED', 0, ?, ?)
                """, idBytes(UuidV7.generate()), row.domainType(), row.domainKey(), row.code(),
                row.labelKey(), row.tone(), row.icon(), row.order(), row.selectable(),
                jsonArray(row.visibleFor()),
                jsonArray(ReferenceTaxonomy.allowedNext(row.domainKey(), row.code())), now, now);
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

    private static String jsonArray(java.util.List<String> values) {
        StringBuilder json = new StringBuilder("[");
        for (int i = 0; i < values.size(); i++) {
            if (i > 0) {
                json.append(',');
            }
            json.append('"').append(values.get(i).replace("\"", "\\\"")).append('"');
        }
        return json.append(']').toString();
    }

    static byte[] idBytes(UUID id) {
        return ByteBuffer.allocate(16)
                .putLong(id.getMostSignificantBits())
                .putLong(id.getLeastSignificantBits())
                .array();
    }
}
