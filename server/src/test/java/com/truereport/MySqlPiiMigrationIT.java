package com.truereport;

import com.truereport.shared.security.PiiCrypto;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.Base64;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers(disabledWithoutDocker = true)
class MySqlPiiMigrationIT {

    @Container
    static final MySQLContainer<?> MYSQL = new MySQLContainer<>("mysql:8.4.13")
            .withDatabaseName("truereport")
            .withUsername("truereport")
            .withPassword("truereport")
            .withCommand("--log-bin-trust-function-creators=1");

    @Test
    void existingPiiIsEncryptedAndTriggersRemain() throws Exception {
        Flyway.configure()
                .dataSource(MYSQL.getJdbcUrl(), MYSQL.getUsername(), MYSQL.getPassword())
                .locations("classpath:db/migration", "classpath:db/migration-mysql")
                .target("14").load().migrate();

        String key = key();
        UUID jobId = UUID.randomUUID();
        UUID snapshotId = UUID.randomUUID();
        try (Connection connection = DriverManager.getConnection(
                MYSQL.getJdbcUrl(), MYSQL.getUsername(), MYSQL.getPassword());
             Statement statement = connection.createStatement()) {
            statement.execute("SET FOREIGN_KEY_CHECKS=0");
            statement.execute("INSERT INTO inspection_jobs (id,workshop_id,reference,status,"
                    + "template_version_id,created_by,customer_name,customer_phone,customer_email,"
                    + "vehicle_make,vehicle_model,vehicle_year,vehicle_vin,vehicle_plate,scope,"
                    + "created_at,updated_at,version) VALUES (UUID_TO_BIN('" + jobId + "'),"
                    + "UUID_TO_BIN('" + UUID.randomUUID() + "'),'MIG-1','FINALIZED',"
                    + "UUID_TO_BIN('" + UUID.randomUUID() + "'),UUID_TO_BIN('" + UUID.randomUUID()
                    + "'),'Migration Customer','+971500009900','migration@example.test',"
                    + "'Toyota','Camry',2022,'JTDBR32E720099900','MIG-9900','Migration',"
                    + "NOW(6),NOW(6),0)");
            statement.execute("INSERT INTO inspection_final_snapshots (id,workshop_id,job_id,"
                    + "snapshot_json,snapshot_hash,created_at) VALUES (UUID_TO_BIN('" + snapshotId
                    + "'),UUID_TO_BIN('" + UUID.randomUUID() + "'),UUID_TO_BIN('" + jobId
                    + "'),'{\"customerName\":\"Migration Customer\"}',UNHEX(SHA2('hash',256)),NOW(6))");
            statement.execute("SET FOREIGN_KEY_CHECKS=1");
        }

        System.setProperty("APP_PII_KEYS", "v1:" + key);
        System.setProperty("APP_PII_ACTIVE_KEY_ID", "v1");
        try {
            Flyway.configure()
                    .dataSource(MYSQL.getJdbcUrl(), MYSQL.getUsername(), MYSQL.getPassword())
                    .locations("classpath:db/migration", "classpath:db/migration-mysql")
                    .load().migrate();
        } finally {
            System.clearProperty("APP_PII_KEYS");
            System.clearProperty("APP_PII_ACTIVE_KEY_ID");
        }

        PiiCrypto crypto = new PiiCrypto("v1", Map.of("v1", key));
        try (Connection connection = DriverManager.getConnection(
                MYSQL.getJdbcUrl(), MYSQL.getUsername(), MYSQL.getPassword());
             Statement statement = connection.createStatement()) {
            try (ResultSet row = statement.executeQuery("SELECT customer_name, customer_phone, "
                    + "vehicle_vin FROM inspection_jobs WHERE id=UUID_TO_BIN('" + jobId + "')")) {
                assertThat(row.next()).isTrue();
                assertThat(row.getString(1)).startsWith("v1:").doesNotContain("Migration Customer");
                assertThat(crypto.decrypt(row.getString(1))).isEqualTo("Migration Customer");
                assertThat(crypto.decrypt(row.getString(2))).isEqualTo("+971500009900");
                assertThat(crypto.decrypt(row.getString(3))).isEqualTo("JTDBR32E720099900");
            }
            try (ResultSet row = statement.executeQuery(
                    "SELECT snapshot_json FROM inspection_final_snapshots WHERE id=UUID_TO_BIN('"
                            + snapshotId + "')")) {
                assertThat(row.next()).isTrue();
                assertThat(row.getString(1)).startsWith("v1:");
                assertThat(crypto.decrypt(row.getString(1))).contains("Migration Customer");
            }
            try {
                statement.execute("UPDATE inspection_jobs SET customer_name='changed' WHERE id=UUID_TO_BIN('"
                        + jobId + "')");
                throw new AssertionError("finalized job update was not rejected");
            } catch (java.sql.SQLException exception) {
                assertThat(exception.getMessage()).contains("immutable");
            }
        }
    }

    private String key() {
        byte[] bytes = new byte[32];
        new SecureRandom().nextBytes(bytes);
        return Base64.getEncoder().encodeToString(bytes);
    }
}
