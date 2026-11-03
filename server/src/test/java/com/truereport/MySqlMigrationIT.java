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

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers(disabledWithoutDocker = true)
class MySqlMigrationIT {

    @Container
    static final MySQLContainer<?> MYSQL = new MySQLContainer<>("mysql:8.4.13")
            .withDatabaseName("truereport")
            .withUsername("truereport")
            .withPassword("truereport");

    @Test
    void migrationsRunOnMySql84AndAreIncremental() throws Exception {
        Flyway v1 = Flyway.configure()
                .dataSource(MYSQL.getJdbcUrl(), MYSQL.getUsername(), MYSQL.getPassword())
                .locations("classpath:db/migration")
                .target("1")
                .load();
        v1.migrate();
        assertThat(v1.info().current().getVersion().toString()).isEqualTo("1");
        assertThat(tableExists("workshops")).isTrue();
        assertThat(tableExists("audit_events")).isFalse();

        Flyway latest = Flyway.configure()
                .dataSource(MYSQL.getJdbcUrl(), MYSQL.getUsername(), MYSQL.getPassword())
                .locations("classpath:db/migration")
                .load();
        latest.migrate();
        assertThat(latest.info().current().getVersion().toString()).isEqualTo("4");
        assertThat(tableExists("audit_events")).isTrue();
        assertThat(tableExists("invitations")).isTrue();
        assertThat(tableExists("master_inspection_items")).isTrue();
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
