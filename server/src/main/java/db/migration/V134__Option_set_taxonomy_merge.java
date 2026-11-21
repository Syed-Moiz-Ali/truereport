package db.migration;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

/**
 * Structural merge: the reference taxonomy becomes one physical store
 * ({@code platform_option_sets} + {@code platform_option_values}).
 *
 * <p>Adds the set metadata columns, seeds the backend-defined STATUS/ENUM sets
 * (plus the locked catalogue {@code SEVERITY}, {@code UNIT} and {@code YES_NO}
 * sets), copies every {@code reference_domain} row into the matching set/value
 * and finally drops {@code reference_domain}. The copy is idempotent: an
 * existing value keeps its human label, while the reference label key, tone,
 * icon, visibility and order are merged onto it.</p>
 *
 * <p>SEVERITY and UNIT are declared {@code set_kind='CHECKLIST'} with
 * {@code code_locked=1}: issue fields reference those sets as option/unit sets,
 * so they must remain catalogue sets in the master-data API even though their
 * codes are backend-owned. That is the documented exception to the otherwise
 * STATUS/ENUM kind mapping.</p>
 */
public class V134__Option_set_taxonomy_merge extends BaseJavaMigration {

    private static final String SETS = "platform_option_sets";
    private static final String VALUES = "platform_option_values";
    private static final String REFERENCE = "reference_domain";
    private static final String DOMAIN_INDEX = "uq_platform_option_set_domain";

    private record SetSeed(String code, String name, String kind, String domainKey,
                           boolean codeLocked, int sortOrder) {
    }

    /**
     * Backend-defined sets created by the merge. Catalogue checklist sets are
     * owned by {@code DefaultChecklistSeeder} and are intentionally not created
     * here.
     */
    private static final List<SetSeed> SET_SEEDS = List.of(
            new SetSeed("JOB_STATUS", "Job Status", "STATUS", "job-status", true, 101),
            new SetSeed("REVIEW_STATUS", "Review Status", "STATUS", "review-status", true, 102),
            new SetSeed("PUBLICATION_STATUS", "Publication Status", "STATUS", "publication-status", true, 103),
            new SetSeed("DOCUMENT_STATUS", "Document Status", "STATUS", "document-status", true, 104),
            new SetSeed("SYNC_STATUS", "Sync Status", "STATUS", "sync-status", true, 105),
            new SetSeed("EVIDENCE_STATUS", "Evidence Status", "STATUS", "evidence-status", true, 106),
            new SetSeed("TEMPLATE_STATUS", "Template Status", "STATUS", "template-status", true, 107),
            new SetSeed("WORKSHOP_STATUS", "Workshop Status", "STATUS", "workshop-status", true, 108),
            new SetSeed("CHECKLIST_STATUS", "Checklist Status", "STATUS", "checklist-status", true, 109),
            new SetSeed("HEALTH_STATUS", "Health Status", "STATUS", "health-status", true, 110),
            new SetSeed("PLATFORM_CHIP_STATUS", "Platform Chip Status", "STATUS", "platform-chip-status", true, 111),
            new SetSeed("DELIVERY_STATUS", "Delivery Status", "STATUS", "delivery-status", true, 112),
            new SetSeed("CONSENT_STATUS", "Consent Status", "STATUS", "consent-status", true, 113),
            new SetSeed("TRANSLATION_STATUS", "Translation Status", "STATUS", "translation-status", true, 114),
            new SetSeed("DOCUMENT_TYPE_STATUS", "Document Type Status", "STATUS", "document-type-status", true, 115),
            new SetSeed("ROLE", "Role", "ENUM", "role", true, 201),
            new SetSeed("RESULT", "Result", "ENUM", "result", true, 202),
            new SetSeed("GRADE", "Grade", "ENUM", "grade", true, 203),
            new SetSeed("INPUT_TYPE", "Input Type", "ENUM", "input-type", true, 204),
            new SetSeed("EVIDENCE_TYPE", "Evidence Type", "ENUM", "evidence-type", true, 205),
            new SetSeed("CONTENT_TYPE", "Content Type", "ENUM", "content-type", true, 206),
            new SetSeed("MEASUREMENT_DIRECTION", "Measurement Direction", "ENUM",
                    "measurement-direction", true, 207),
            // Existing catalogue sets that must stay referenced by issue fields.
            new SetSeed("SEVERITY", "Severity", "CHECKLIST", "severity", true, 5),
            new SetSeed("UNIT", "Unit", "CHECKLIST", "measurement-unit", true, 9),
            new SetSeed("YES_NO", "Yes / No", "CHECKLIST", "yes-no", true, 10));

    private static final Map<String, SetSeed> BY_DOMAIN = byDomain();

    @Override
    public void migrate(Context context) throws Exception {
        Connection connection = context.getConnection();
        addColumnIfMissing(connection, SETS, "set_kind",
                "VARCHAR(16) NOT NULL DEFAULT 'CHECKLIST'");
        addColumnIfMissing(connection, SETS, "domain_key", "VARCHAR(48) NULL");
        addColumnIfMissing(connection, SETS, "code_locked",
                "TINYINT(1) NOT NULL DEFAULT 0");

        seedSets(connection);
        createDomainIndexIfMissing(connection);
        if (tableExists(connection, REFERENCE)) {
            copyReferenceRows(connection);
            dropTable(connection, REFERENCE);
        }
    }

    // ----------------------------------------------------------------- sets

    private void seedSets(Connection connection) throws SQLException {
        for (SetSeed seed : SET_SEEDS) {
            String id = findSetIdByCode(connection, seed.code());
            if (id == null) {
                try (PreparedStatement insert = connection.prepareStatement("""
                        INSERT INTO platform_option_sets
                            (id, code, name, status, sort_order, created_at, updated_at, version,
                             set_kind, domain_key, code_locked)
                        VALUES (?, ?, ?, 'ACTIVE', ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0,
                                ?, ?, ?)
                        """)) {
                    insert.setString(1, UUID.randomUUID().toString());
                    insert.setString(2, seed.code());
                    insert.setString(3, seed.name());
                    insert.setInt(4, seed.sortOrder());
                    insert.setString(5, seed.kind());
                    insert.setString(6, seed.domainKey());
                    insert.setBoolean(7, seed.codeLocked());
                    insert.executeUpdate();
                }
            } else {
                // Existing catalogue sets keep their name/status/order; only the
                // backend-owned classification is applied.
                try (PreparedStatement update = connection.prepareStatement("""
                        UPDATE platform_option_sets
                        SET set_kind = ?, domain_key = ?, code_locked = ?,
                            updated_at = CURRENT_TIMESTAMP, version = version + 1
                        WHERE id = ?
                        """)) {
                    update.setString(1, seed.kind());
                    update.setString(2, seed.domainKey());
                    update.setBoolean(3, seed.codeLocked());
                    update.setString(4, id);
                    update.executeUpdate();
                }
            }
        }
    }

    // ---------------------------------------------------------------- copy

    private void copyReferenceRows(Connection connection) throws SQLException {
        List<ReferenceRow> rows = new ArrayList<>();
        try (Statement statement = connection.createStatement();
             ResultSet result = statement.executeQuery("""
                     SELECT domain_type, domain_key, code, label_key, tone, icon, sort_order,
                            selectable, visible_for_json, allowed_next_json, status
                     FROM reference_domain
                     ORDER BY domain_key, sort_order, code
                     """)) {
            while (result.next()) {
                rows.add(new ReferenceRow(
                        result.getString("domain_type"), result.getString("domain_key"),
                        result.getString("code"), result.getString("label_key"),
                        result.getString("tone"), result.getString("icon"),
                        result.getInt("sort_order"), result.getBoolean("selectable"),
                        result.getString("visible_for_json"),
                        result.getString("allowed_next_json"), result.getString("status")));
            }
        }
        for (ReferenceRow row : rows) {
            SetSeed seed = BY_DOMAIN.get(row.domainKey());
            String setCode = seed == null ? defaultSetCode(row.domainKey()) : seed.code();
            String setId = findSetIdByCode(connection, setCode);
            if (setId == null) {
                // A reference domain with no static definition still becomes a set.
                setId = insertSet(connection, setCode, humanize(setCode), row.domainType(),
                        row.domainKey());
            }
            String mappedStatus = mapStatus(row.status());
            String metadata = metadataJson(row);
            String existingId = findValueId(connection, setId, row.code());
            if (existingId == null) {
                try (PreparedStatement insert = connection.prepareStatement("""
                        INSERT INTO platform_option_values
                            (id, option_set_id, code, label, label_key, status, sort_order,
                             metadata_json, created_at, updated_at, version)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                        """)) {
                    insert.setString(1, UUID.randomUUID().toString());
                    insert.setString(2, setId);
                    insert.setString(3, row.code());
                    insert.setString(4, humanize(row.code()));
                    insert.setString(5, row.labelKey());
                    insert.setString(6, mappedStatus);
                    insert.setInt(7, row.sortOrder());
                    insert.setString(8, metadata);
                    insert.executeUpdate();
                }
            } else {
                // Keep the existing human label; merge the reference taxonomy
                // fields the reference API and clients depend on.
                try (PreparedStatement update = connection.prepareStatement("""
                        UPDATE platform_option_values
                        SET label_key = ?, status = ?, sort_order = ?, metadata_json = ?,
                            updated_at = CURRENT_TIMESTAMP, version = version + 1
                        WHERE id = ?
                        """)) {
                    update.setString(1, row.labelKey());
                    update.setString(2, mappedStatus);
                    update.setInt(3, row.sortOrder());
                    update.setString(4, metadata);
                    update.setString(5, existingId);
                    update.executeUpdate();
                }
            }
        }
    }

    private String insertSet(Connection connection, String code, String name, String domainType,
                             String domainKey) throws SQLException {
        String id = UUID.randomUUID().toString();
        String kind = "STATUS".equalsIgnoreCase(domainType) ? "STATUS" : "ENUM";
        try (PreparedStatement insert = connection.prepareStatement("""
                INSERT INTO platform_option_sets
                    (id, code, name, status, sort_order, created_at, updated_at, version,
                     set_kind, domain_key, code_locked)
                VALUES (?, ?, ?, 'ACTIVE', 900, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0,
                        ?, ?, 1)
                """)) {
            insert.setString(1, id);
            insert.setString(2, code);
            insert.setString(3, name);
            insert.setString(4, kind);
            insert.setString(5, domainKey);
            insert.executeUpdate();
        }
        return id;
    }

    // -------------------------------------------------------------- helpers

    private record ReferenceRow(String domainType, String domainKey, String code,
                                String labelKey, String tone, String icon, int sortOrder,
                                boolean selectable, String visibleForJson,
                                String allowedNextJson, String status) {
    }

    private String findSetIdByCode(Connection connection, String code) throws SQLException {
        try (PreparedStatement query = connection.prepareStatement(
                "SELECT id FROM platform_option_sets WHERE code = ?")) {
            query.setString(1, code);
            try (ResultSet result = query.executeQuery()) {
                return result.next() ? result.getString(1) : null;
            }
        }
    }

    private String findValueId(Connection connection, String setId, String code)
            throws SQLException {
        try (PreparedStatement query = connection.prepareStatement(
                "SELECT id FROM platform_option_values WHERE option_set_id = ? AND code = ?")) {
            query.setString(1, setId);
            query.setString(2, code);
            try (ResultSet result = query.executeQuery()) {
                return result.next() ? result.getString(1) : null;
            }
        }
    }

    private static String mapStatus(String status) {
        if (status == null) {
            return "ACTIVE";
        }
        return switch (status) {
            case "PUBLISHED" -> "ACTIVE";
            case "DRAFT" -> "DRAFT";
            case "RETIRED" -> "RETIRED";
            default -> "ACTIVE";
        };
    }

    private static String metadataJson(ReferenceRow row) {
        StringBuilder json = new StringBuilder("{");
        json.append("\"tone\":").append(jsonString(row.tone() == null ? "neutral" : row.tone()));
        json.append(",\"icon\":").append(jsonString(row.icon() == null ? "circle" : row.icon()));
        json.append(",\"selectable\":").append(row.selectable());
        json.append(",\"visibleFor\":").append(row.visibleForJson());
        json.append(",\"allowedNext\":").append(row.allowedNextJson());
        json.append(",\"legacyDomain\":").append(jsonString(row.domainKey()));
        return json.append('}').toString();
    }

    private static String jsonString(String value) {
        if (value == null) {
            return "null";
        }
        StringBuilder escaped = new StringBuilder("\"");
        for (int index = 0; index < value.length(); index++) {
            char character = value.charAt(index);
            switch (character) {
                case '"' -> escaped.append("\\\"");
                case '\\' -> escaped.append("\\\\");
                case '\n' -> escaped.append("\\n");
                case '\r' -> escaped.append("\\r");
                case '\t' -> escaped.append("\\t");
                default -> escaped.append(character);
            }
        }
        return escaped.append('"').toString();
    }

    private static String defaultSetCode(String domainKey) {
        if (domainKey == null) {
            return "UNKNOWN_DOMAIN";
        }
        return domainKey.replace('-', '_').toUpperCase(Locale.ROOT);
    }

    private static String humanize(String code) {
        String[] parts = code.toLowerCase(Locale.ROOT).split("[_-]+");
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

    private static Map<String, SetSeed> byDomain() {
        Map<String, SetSeed> result = new LinkedHashMap<>();
        for (SetSeed seed : SET_SEEDS) {
            result.put(seed.domainKey(), seed);
        }
        return Map.copyOf(result);
    }

    private void addColumnIfMissing(Connection connection, String table, String column,
                                    String definition) throws SQLException {
        if (columnExists(connection, table, column)) {
            return;
        }
        try (Statement statement = connection.createStatement()) {
            statement.execute("ALTER TABLE " + table + " ADD COLUMN " + column + " "
                    + definition);
        } catch (SQLException exception) {
            if (!columnExists(connection, table, column)) {
                throw exception;
            }
        }
    }

    private void createDomainIndexIfMissing(Connection connection) throws SQLException {
        // Duplicate non-null domain keys must not exist; system sets are backend-owned.
        try (Statement statement = connection.createStatement()) {
            statement.execute("CREATE UNIQUE INDEX " + DOMAIN_INDEX
                    + " ON platform_option_sets (domain_key)");
        } catch (SQLException exception) {
            if (!indexExists(connection)) {
                throw exception;
            }
        }
    }

    private boolean indexExists(Connection connection) throws SQLException {
        DatabaseMetaData metadata = connection.getMetaData();
        for (String table : List.of(SETS, SETS.toUpperCase(Locale.ROOT))) {
            try (ResultSet result = metadata.getIndexInfo(
                    connection.getCatalog(), null, table, false, false)) {
                while (result.next()) {
                    String name = result.getString("INDEX_NAME");
                    if (name != null && name.equalsIgnoreCase(DOMAIN_INDEX)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    private boolean columnExists(Connection connection, String table, String column)
            throws SQLException {
        DatabaseMetaData metadata = connection.getMetaData();
        for (String candidateTable : List.of(table, table.toUpperCase(Locale.ROOT))) {
            for (String candidateColumn : List.of(column, column.toUpperCase(Locale.ROOT))) {
                try (ResultSet result = metadata.getColumns(connection.getCatalog(), null,
                        candidateTable, candidateColumn)) {
                    if (result.next()) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    private boolean tableExists(Connection connection, String table) throws SQLException {
        DatabaseMetaData metadata = connection.getMetaData();
        for (String candidate : List.of(table, table.toUpperCase(Locale.ROOT))) {
            try (ResultSet result = metadata.getTables(connection.getCatalog(), null,
                    candidate, new String[]{"TABLE"})) {
                if (result.next()) {
                    return true;
                }
            }
        }
        return false;
    }

    private void dropTable(Connection connection, String table) throws SQLException {
        try (Statement statement = connection.createStatement()) {
            statement.execute("DROP TABLE " + table);
        }
    }
}
