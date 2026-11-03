package com.truereport;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

import static org.assertj.core.api.Assertions.assertThat;

class FlywayMigrationTest {

    @Test
    void migratesFromEmptyAndThenIncrementally() throws Exception {
        String url = "jdbc:h2:mem:migration_test;MODE=MySQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1";

        Flyway baseline = Flyway.configure()
                .dataSource(url, "sa", "")
                .locations("classpath:db/migration")
                .target("1")
                .load();
        baseline.migrate();

        assertThat(baseline.info().current().getVersion().toString()).isEqualTo("1");
        assertThat(tableExists(url, "workshops")).isTrue();
        assertThat(tableExists(url, "audit_events")).isFalse();

        Flyway latest = Flyway.configure()
                .dataSource(url, "sa", "")
                .locations("classpath:db/migration")
                .load();
        latest.migrate();

        assertThat(latest.info().current().getVersion().toString()).isEqualTo("9");
        assertThat(tableExists(url, "audit_events")).isTrue();
        assertThat(tableExists(url, "invitations")).isTrue();
        assertThat(tableExists(url, "master_inspection_items")).isTrue();
        assertThat(tableExists(url, "workshop_templates")).isTrue();
        assertThat(tableExists(url, "inspection_jobs")).isTrue();
        assertThat(tableExists(url, "inspection_item_snapshots")).isTrue();
        assertThat(tableExists(url, "assessments")).isTrue();
        assertThat(tableExists(url, "inspection_final_snapshots")).isTrue();
        assertThat(tableExists(url, "evidence_assets")).isTrue();
    }

    private boolean tableExists(String url, String table) throws Exception {
        try (Connection connection = DriverManager.getConnection(url, "sa", "");
             Statement statement = connection.createStatement();
             ResultSet result = statement.executeQuery(
                     "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE LOWER(TABLE_NAME) = '" + table + "'")) {
            result.next();
            return result.getInt(1) > 0;
        }
    }
}
