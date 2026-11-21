package com.truereport;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Proves the V134 structural merge: reference taxonomy rows become option
 * set/value rows, existing catalogue values are merged (never duplicated) and
 * {@code reference_domain} is removed.
 */
class ReferenceTaxonomyMigrationTest {

    private static final String URL =
            "jdbc:h2:mem:reference_merge_test;MODE=MySQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1";

    @Test
    void referenceTaxonomyIsCopiedIntoOptionSetsAndTheTableIsDropped() throws Exception {
        Flyway.configure()
                .dataSource(URL, "sa", "")
                .locations("classpath:db/migration", "classpath:db/migration-h2")
                .target("133")
                .load()
                .migrate();

        String severitySetId = UUID.randomUUID().toString();
        String minorValueId = UUID.randomUUID().toString();
        try (Connection connection = DriverManager.getConnection(URL, "sa", "")) {
            try (PreparedStatement set = connection.prepareStatement("""
                    INSERT INTO platform_option_sets
                        (id, code, name, status, sort_order, created_at, updated_at, version)
                    VALUES (?, 'SEVERITY', 'Severity', 'ACTIVE', 5,
                            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                    """)) {
                set.setString(1, severitySetId);
                set.executeUpdate();
            }
            try (PreparedStatement value = connection.prepareStatement("""
                    INSERT INTO platform_option_values
                        (id, option_set_id, code, label, status, sort_order, metadata_json,
                         created_at, updated_at, version)
                    VALUES (?, ?, 'MINOR', 'Admin minor', 'ACTIVE', 3, NULL,
                            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                    """)) {
                value.setString(1, minorValueId);
                value.setString(2, severitySetId);
                value.executeUpdate();
            }
            insertReference(connection, "STATUS", "job-status", "DRAFT", "status.draft",
                    "neutral", 1, true, "[\"platform_admin\",\"workshop_admin\",\"technician\"]",
                    "[\"SCHEDULED\",\"CANCELLED\"]", "PUBLISHED");
            insertReference(connection, "STATUS", "job-status", "SCHEDULED", "statusScheduled",
                    "info", 2, true, "[\"platform_admin\",\"workshop_admin\",\"technician\"]",
                    "[]", "PUBLISHED");
            insertReference(connection, "ENUM", "severity", "MINOR", "minor",
                    "neutral", 3, true, "[\"technician\"]", "[]", "PUBLISHED");
            insertReference(connection, "ENUM", "severity", "MODERATE", "moderate",
                    "warning", 4, true, "[\"technician\"]", "[]", "PUBLISHED");
            insertReference(connection, "ENUM", "role", "TECHNICIAN", "role.technician",
                    "neutral", 1, true, "[\"technician\"]", "[]", "DRAFT");
            insertReference(connection, "ENUM", "result", "NOT_CHECKED", "notChecked",
                    "neutral", 1, true, "[\"technician\"]", "[]", "PUBLISHED");
        }

        Flyway latest = Flyway.configure()
                .dataSource(URL, "sa", "")
                .locations("classpath:db/migration", "classpath:db/migration-h2")
                .load();
        latest.migrate();
        assertThat(latest.info().current().getVersion().toString()).isEqualTo("135");

        try (Connection connection = DriverManager.getConnection(URL, "sa", "")) {
            assertThat(tableExists(connection, "reference_domain")).isFalse();

            assertSet(connection, "JOB_STATUS", "STATUS", "job-status");
            assertSet(connection, "SEVERITY", "CHECKLIST", "severity");
            assertSet(connection, "ROLE", "ENUM", "role");

            List<String> jobCodes = codes(connection, "job-status");
            assertThat(jobCodes).containsExactly("DRAFT", "SCHEDULED");
            List<String> severityCodes = codes(connection, "severity");
            assertThat(severityCodes).containsExactlyInAnyOrder("MINOR", "MODERATE");
            List<String> roleCodes = codes(connection, "role");
            assertThat(roleCodes).containsExactly("TECHNICIAN");

            assertSet(connection, "RESULT", "ENUM", "result");
            try (PreparedStatement query = connection.prepareStatement("""
                    SELECT v.code, v.label_key, v.metadata_json
                    FROM platform_option_values v
                    JOIN platform_option_sets s ON s.id = v.option_set_id
                    WHERE s.code = 'RESULT' AND v.code = 'NOT_CHECKED'
                    """)) {
                try (ResultSet result = query.executeQuery()) {
                    assertThat(result.next()).isTrue();
                    assertThat(result.getString("label_key")).isEqualTo("notChecked");
                    assertThat(result.getString("metadata_json"))
                            .contains("\"selectable\":false")
                            .contains("\"tone\":\"neutral\"")
                            .contains("\"legacyDomain\":\"result\"");
                }
            }

            // Existing catalogue value is merged, not duplicated; its label survives.
            try (PreparedStatement query = connection.prepareStatement("""
                    SELECT v.label, v.label_key, v.metadata_json, v.status
                    FROM platform_option_values v
                    JOIN platform_option_sets s ON s.id = v.option_set_id
                    WHERE s.code = 'SEVERITY' AND v.code = 'MINOR'
                    """)) {
                try (ResultSet result = query.executeQuery()) {
                    assertThat(result.next()).isTrue();
                    assertThat(result.getString("label")).isEqualTo("Admin minor");
                    assertThat(result.getString("label_key")).isEqualTo("minor");
                    assertThat(result.getString("metadata_json")).contains("\"tone\":\"neutral\"");
                    assertThat(result.getString("status")).isEqualTo("ACTIVE");
                }
            }

            // DRAFT reference state maps to option-set DRAFT.
            try (PreparedStatement query = connection.prepareStatement("""
                    SELECT v.status FROM platform_option_values v
                    JOIN platform_option_sets s ON s.id = v.option_set_id
                    WHERE s.domain_key = 'role' AND v.code = 'TECHNICIAN'
                    """)) {
                try (ResultSet result = query.executeQuery()) {
                    assertThat(result.next()).isTrue();
                    assertThat(result.getString(1)).isEqualTo("DRAFT");
                }
            }

            try (PreparedStatement query = connection.prepareStatement(
                    "SELECT COUNT(*) FROM platform_option_values v "
                            + "JOIN platform_option_sets s ON s.id = v.option_set_id "
                            + "WHERE s.domain_key IN ('job-status', 'severity', 'role')")) {
                try (ResultSet result = query.executeQuery()) {
                    result.next();
                    assertThat(result.getInt(1)).isEqualTo(5);
                }
            }
        }
    }

    private void insertReference(Connection connection, String domainType, String domainKey,
                                 String code, String labelKey, String tone, int sortOrder,
                                 boolean selectable, String visibleFor, String allowedNext,
                                 String status) throws Exception {
        try (PreparedStatement insert = connection.prepareStatement("""
                INSERT INTO reference_domain
                    (id, domain_type, domain_key, code, label_key, tone, icon, sort_order,
                     selectable, visible_for_json, allowed_next_json, status, version,
                     created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, 'circle', ?, ?, ?, ?, ?, 0,
                        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """)) {
            insert.setBytes(1, uuidBytes());
            insert.setString(2, domainType);
            insert.setString(3, domainKey);
            insert.setString(4, code);
            insert.setString(5, labelKey);
            insert.setString(6, tone);
            insert.setInt(7, sortOrder);
            insert.setBoolean(8, selectable);
            insert.setString(9, visibleFor);
            insert.setString(10, allowedNext);
            insert.setString(11, status);
            insert.executeUpdate();
        }
    }

    private void assertSet(Connection connection, String code, String kind, String domainKey)
            throws Exception {
        try (PreparedStatement query = connection.prepareStatement("""
                SELECT set_kind, domain_key, code_locked FROM platform_option_sets WHERE code = ?
                """)) {
            query.setString(1, code);
            try (ResultSet result = query.executeQuery()) {
                assertThat(result.next()).as("set %s", code).isTrue();
                assertThat(result.getString("set_kind")).isEqualTo(kind);
                assertThat(result.getString("domain_key")).isEqualTo(domainKey);
                assertThat(result.getBoolean("code_locked")).isTrue();
            }
        }
    }

    private List<String> codes(Connection connection, String domainKey) throws Exception {
        List<String> codes = new ArrayList<>();
        try (PreparedStatement query = connection.prepareStatement("""
                SELECT v.code FROM platform_option_values v
                JOIN platform_option_sets s ON s.id = v.option_set_id
                WHERE s.domain_key = ?
                ORDER BY v.sort_order, v.code
                """)) {
            query.setString(1, domainKey);
            try (ResultSet result = query.executeQuery()) {
                while (result.next()) {
                    codes.add(result.getString(1));
                }
            }
        }
        return codes;
    }

    private boolean tableExists(Connection connection, String table) throws Exception {
        try (Statement statement = connection.createStatement();
             ResultSet result = statement.executeQuery(
                     "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE LOWER(TABLE_NAME) = '"
                             + table + "'")) {
            result.next();
            return result.getInt(1) > 0;
        }
    }

    private static byte[] uuidBytes() {
        UUID uuid = UUID.randomUUID();
        byte[] bytes = new byte[16];
        long most = uuid.getMostSignificantBits();
        long least = uuid.getLeastSignificantBits();
        for (int index = 0; index < 8; index++) {
            bytes[index] = (byte) (most >>> (56 - index * 8));
            bytes[8 + index] = (byte) (least >>> (56 - index * 8));
        }
        return bytes;
    }
}
