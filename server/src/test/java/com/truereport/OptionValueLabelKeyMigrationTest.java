package com.truereport;

import db.migration.V128__Option_value_label_keys;
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

class OptionValueLabelKeyMigrationTest {

    private static final String URL =
            "jdbc:h2:mem:option_label_keys;MODE=MySQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1";
    private static final String KEY_PATTERN =
            "^[a-z][A-Za-z0-9]*(\\.[a-z][A-Za-z0-9]*)+$";

    @Test
    void backfillIsDeterministicPreservesCustomKeysAndIsRepeatable() throws Exception {
        migrate("127");

        String issueSetId = insertSet("ISSUE_TYPE");
        String locationSetId = insertSet("LOCATION");
        String wornId = insertValue(issueSetId, "WORN");
        String frontLeftId = insertValue(locationSetId, "FRONT_LEFT");

        migrate(null);

        try (Connection connection = DriverManager.getConnection(URL, "sa", "")) {
            assertThat(labelKey(connection, wornId)).isEqualTo("option.issueType.worn");
            assertThat(labelKey(connection, frontLeftId)).isEqualTo("option.location.frontLeft");

            // Running the backfill again (or after a partial deploy) must not rewrite keys.
            V128__Option_value_label_keys.backfill(connection);
            assertThat(labelKey(connection, wornId)).isEqualTo("option.issueType.worn");
            assertThat(labelKey(connection, frontLeftId)).isEqualTo("option.location.frontLeft");

            String customId = insertValue(issueSetId, "CUSTOM");
            setLabelKey(connection, customId, "custom.issue.custom");
            V128__Option_value_label_keys.backfill(connection);
            assertThat(labelKey(connection, customId)).isEqualTo("custom.issue.custom");

            List<String> keys = allLabelKeys(connection);
            assertThat(keys).isNotEmpty();
            assertThat(keys).allMatch(key -> key.matches(KEY_PATTERN));
        }
    }

    private void migrate(String target) {
        var configuration = Flyway.configure()
                .dataSource(URL, "sa", "")
                .locations("classpath:db/migration", "classpath:db/migration-h2");
        if (target != null) {
            configuration.target(target);
        }
        configuration.load().migrate();
    }

    private String insertSet(String code) throws Exception {
        String id = UUID.randomUUID().toString();
        try (Connection connection = DriverManager.getConnection(URL, "sa", "");
             PreparedStatement insert = connection.prepareStatement("""
                     INSERT INTO platform_option_sets
                         (id, code, name, status, sort_order, created_at, updated_at, version)
                     VALUES (?, ?, ?, 'ACTIVE', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                     """)) {
            insert.setString(1, id);
            insert.setString(2, code);
            insert.setString(3, code + " set");
            insert.executeUpdate();
        }
        return id;
    }

    private String insertValue(String optionSetId, String code) throws Exception {
        String id = UUID.randomUUID().toString();
        try (Connection connection = DriverManager.getConnection(URL, "sa", "");
             PreparedStatement insert = connection.prepareStatement("""
                     INSERT INTO platform_option_values
                         (id, option_set_id, code, label, status, sort_order, metadata_json,
                          created_at, updated_at, version)
                     VALUES (?, ?, ?, ?, 'ACTIVE', 1, NULL, CURRENT_TIMESTAMP,
                             CURRENT_TIMESTAMP, 0)
                     """)) {
            insert.setString(1, id);
            insert.setString(2, optionSetId);
            insert.setString(3, code);
            insert.setString(4, code);
            insert.executeUpdate();
        }
        return id;
    }

    private void setLabelKey(Connection connection, String id, String labelKey) throws Exception {
        try (PreparedStatement update = connection.prepareStatement(
                "UPDATE platform_option_values SET label_key = ? WHERE id = ?")) {
            update.setString(1, labelKey);
            update.setString(2, id);
            update.executeUpdate();
        }
    }

    private String labelKey(Connection connection, String id) throws Exception {
        try (PreparedStatement select = connection.prepareStatement(
                "SELECT label_key FROM platform_option_values WHERE id = ?")) {
            select.setString(1, id);
            try (ResultSet result = select.executeQuery()) {
                assertThat(result.next()).isTrue();
                return result.getString(1);
            }
        }
    }

    private List<String> allLabelKeys(Connection connection) throws Exception {
        List<String> keys = new ArrayList<>();
        try (Statement statement = connection.createStatement();
             ResultSet result = statement.executeQuery("""
                     SELECT label_key FROM platform_option_values ORDER BY id
                     """)) {
            while (result.next()) {
                keys.add(result.getString(1));
            }
        }
        return keys;
    }
}
