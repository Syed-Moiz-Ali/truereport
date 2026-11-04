package com.truereport;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers(disabledWithoutDocker = true)
class MySqlMigrationIT {

    @Container
    static final MySQLContainer<?> MYSQL = new MySQLContainer<>("mysql:8.4.13")
            .withDatabaseName("truereport")
            .withUsername("truereport")
            .withPassword("truereport")
            .withCommand("--log-bin-trust-function-creators=1");

    @Test
    void migrationsRunOnMySql84AndAreIncremental() throws Exception {
        Flyway v1 = Flyway.configure()
                .dataSource(MYSQL.getJdbcUrl(), MYSQL.getUsername(), MYSQL.getPassword())
                .locations("classpath:db/migration", "classpath:db/migration-mysql")
                .target("1")
                .load();
        v1.migrate();
        assertThat(v1.info().current().getVersion().toString()).isEqualTo("1");
        assertThat(tableExists("workshops")).isTrue();
        assertThat(tableExists("audit_events")).isFalse();

        Flyway latest = Flyway.configure()
                .dataSource(MYSQL.getJdbcUrl(), MYSQL.getUsername(), MYSQL.getPassword())
                .locations("classpath:db/migration", "classpath:db/migration-mysql")
                .load();
        latest.migrate();
        assertThat(latest.info().current().getVersion().toString()).isEqualTo("13");
        assertThat(tableExists("audit_events")).isTrue();
        assertThat(tableExists("invitations")).isTrue();
        assertThat(tableExists("master_inspection_items")).isTrue();
        assertThat(tableExists("workshop_templates")).isTrue();
        assertThat(tableExists("inspection_jobs")).isTrue();
        assertThat(tableExists("inspection_item_snapshots")).isTrue();
        assertThat(tableExists("assessments")).isTrue();
        assertThat(tableExists("inspection_final_snapshots")).isTrue();
        assertThat(tableExists("evidence_assets")).isTrue();
        assertThat(tableExists("reports")).isTrue();
        assertThat(tableExists("report_versions")).isTrue();
        assertThat(tableExists("report_generation_jobs")).isTrue();
        assertThat(tableExists("report_artifacts")).isTrue();
        assertThat(tableExists("public_share_links")).isTrue();
        assertThat(triggerExists("trg_reports_no_update")).isTrue();
        assertThat(triggerExists("trg_report_versions_no_update")).isTrue();
        assertThat(triggerExists("trg_public_share_link_no_token_change")).isTrue();

        try (Connection connection = DriverManager.getConnection(
                MYSQL.getJdbcUrl(), MYSQL.getUsername(), MYSQL.getPassword());
             Statement statement = connection.createStatement()) {
            statement.execute("SET FOREIGN_KEY_CHECKS=0");
            statement.execute("INSERT INTO reports (id,workshop_id,job_id,created_at,updated_at,version) "
                    + "VALUES (UUID_TO_BIN('" + UUID.randomUUID() + "'),UUID_TO_BIN('"
                    + UUID.randomUUID() + "'),UUID_TO_BIN('" + UUID.randomUUID()
                    + "'),NOW(6),NOW(6),0)");
            statement.execute("INSERT INTO report_versions (id,report_id,workshop_id,version_no,"
                    + "report_number,final_snapshot_hash,snapshot_json,snapshot_hash,finalized_at,"
                    + "created_at,updated_at,version) SELECT UUID_TO_BIN('" + UUID.randomUUID()
                    + "'),id,workshop_id,1,'REPORT-TRIGGER',UNHEX(SHA2('final',256)),'{}',"
                    + "UNHEX(SHA2('snapshot',256)),NOW(6),NOW(6),NOW(6),0 FROM reports LIMIT 1");
            try {
                statement.execute("UPDATE report_versions SET snapshot_json='{\"changed\":true}' LIMIT 1");
                throw new AssertionError("report_versions update was not rejected");
            } catch (java.sql.SQLException exception) {
                assertThat(exception.getMessage()).contains("immutable");
            }
            try {
                statement.execute("UPDATE reports SET version=version+1 LIMIT 1");
                throw new AssertionError("reports update was not rejected");
            } catch (java.sql.SQLException exception) {
                assertThat(exception.getMessage()).contains("immutable");
            }
            statement.execute("SET FOREIGN_KEY_CHECKS=1");
        }
    }

    private boolean triggerExists(String trigger) throws Exception {
        try (Connection connection = DriverManager.getConnection(
                MYSQL.getJdbcUrl(), MYSQL.getUsername(), MYSQL.getPassword());
             Statement statement = connection.createStatement();
             ResultSet result = statement.executeQuery(
                     "SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema = 'truereport' "
                             + "AND trigger_name = '" + trigger + "'")) {
            result.next();
            return result.getInt(1) > 0;
        }
    }

    private boolean tableExists(String table) throws Exception {
        try (Connection connection = DriverManager.getConnection(
                MYSQL.getJdbcUrl(), MYSQL.getUsername(), MYSQL.getPassword());
             Statement statement = connection.createStatement();
             ResultSet result = statement.executeQuery(
                     "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'truereport' AND table_name = '" + table + "'")) {
            result.next();
            return result.getInt(1) > 0;
        }
    }
}
