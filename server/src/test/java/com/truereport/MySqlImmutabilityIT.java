package com.truereport;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers(disabledWithoutDocker = true)
class MySqlImmutabilityIT {

    @Container
    static final MySQLContainer<?> MYSQL = new MySQLContainer<>("mysql:8.4.13")
            .withDatabaseName("truereport")
            .withUsername("truereport")
            .withPassword("truereport")
            .withCommand("--log-bin-trust-function-creators=1");

    @Test
    void directSqlCannotChangeFinalizedOrPublishedRows() throws Exception {
        Flyway.configure()
                .dataSource(MYSQL.getJdbcUrl(), MYSQL.getUsername(), MYSQL.getPassword())
                .locations("classpath:db/migration", "classpath:db/migration-mysql")
                .load().migrate();

        UUID jobId = UUID.randomUUID();
        UUID snapshotId = UUID.randomUUID();
        UUID assessmentId = UUID.randomUUID();
        UUID findingId = UUID.randomUUID();
        UUID masterVersionId = UUID.randomUUID();
        UUID templateVersionId = UUID.randomUUID();
        try (Connection connection = DriverManager.getConnection(
                MYSQL.getJdbcUrl(), MYSQL.getUsername(), MYSQL.getPassword());
             Statement statement = connection.createStatement()) {
            statement.execute("SET FOREIGN_KEY_CHECKS=0");
            statement.execute("INSERT INTO inspection_jobs (id,workshop_id,reference,status,"
                    + "template_version_id,created_by,customer_name,vehicle_make,vehicle_model,scope,"
                    + "created_at,updated_at,version) VALUES (UUID_TO_BIN('" + jobId + "'),"
                    + "UUID_TO_BIN('" + UUID.randomUUID() + "'),'IMM-1','FINALIZED',"
                    + "UUID_TO_BIN('" + UUID.randomUUID() + "'),UUID_TO_BIN('" + UUID.randomUUID()
                    + "'),'Immutable Customer','Toyota','Camry','Test',NOW(6),NOW(6),0)");
            statement.execute("INSERT INTO inspection_item_snapshots (id,workshop_id,job_id,"
                    + "master_item_version_id,sort_order,item_json,snapshot_hash,created_at,updated_at,version)"
                    + " VALUES (UUID_TO_BIN('" + UUID.randomUUID() + "'),UUID_TO_BIN('"
                    + UUID.randomUUID() + "'),UUID_TO_BIN('" + jobId + "'),UUID_TO_BIN('"
                    + UUID.randomUUID() + "'),0,'{}',UNHEX(SHA2('snapshot',256)),NOW(6),NOW(6),0)");
            statement.execute("INSERT INTO assessments (id,workshop_id,job_id,inspection_item_id,"
                    + "technician_id,result_code,client_revision,server_revision,base_version,"
                    + "created_at,updated_at,version) VALUES (UUID_TO_BIN('" + assessmentId
                    + "'),UUID_TO_BIN('" + UUID.randomUUID() + "'),UUID_TO_BIN('" + jobId
                    + "'),UUID_TO_BIN('" + UUID.randomUUID() + "'),UUID_TO_BIN('"
                    + UUID.randomUUID() + "'),'NO_ISSUE_OBSERVED',1,1,0,NOW(6),NOW(6),0)");
            statement.execute("INSERT INTO findings (id,workshop_id,job_id,assessment_id,severity_code,"
                    + "description,created_at) VALUES (UUID_TO_BIN('" + findingId
                    + "'),UUID_TO_BIN('" + UUID.randomUUID() + "'),UUID_TO_BIN('" + jobId
                    + "'),UUID_TO_BIN('" + assessmentId + "'),'MINOR','finding',NOW(6))");
            statement.execute("INSERT INTO inspection_final_snapshots (id,workshop_id,job_id,"
                    + "snapshot_json,snapshot_hash,created_at) VALUES (UUID_TO_BIN('" + snapshotId
                    + "'),UUID_TO_BIN('" + UUID.randomUUID() + "'),UUID_TO_BIN('" + jobId
                    + "'),'{}',UNHEX(SHA2('hash',256)),NOW(6))");
            statement.execute("INSERT INTO evidence_assets (id,workshop_id,job_id,storage_key,"
                    + "content_hash,mime,bytes,uploaded_by,upload_status,created_at,updated_at,version)"
                    + " VALUES (UUID_TO_BIN('" + UUID.randomUUID() + "'),UUID_TO_BIN('"
                    + UUID.randomUUID() + "'),UUID_TO_BIN('" + jobId + "'),'evidence/a.jpg',"
                    + "UNHEX(SHA2('evidence',256)),'image/jpeg',1,UUID_TO_BIN('"
                    + UUID.randomUUID() + "'),'VERIFIED',NOW(6),NOW(6),0)");
            statement.execute("INSERT INTO master_item_versions (id,item_id,version_no,status,"
                    + "note_requirement,evidence_requirement,min_photos,created_at,updated_at,version)"
                    + " VALUES (UUID_TO_BIN('" + masterVersionId + "'),UUID_TO_BIN('"
                    + UUID.randomUUID() + "'),1,'PUBLISHED','OPTIONAL','NONE',0,NOW(6),NOW(6),0)");
            statement.execute("INSERT INTO template_versions (id,template_id,workshop_id,version_no,"
                    + "status,created_at,updated_at,version) VALUES (UUID_TO_BIN('" + templateVersionId
                    + "'),UUID_TO_BIN('" + UUID.randomUUID() + "'),UUID_TO_BIN('"
                    + UUID.randomUUID() + "'),1,'PUBLISHED',NOW(6),NOW(6),0)");
            statement.execute("SET FOREIGN_KEY_CHECKS=1");

            assertRejected(statement, "UPDATE inspection_jobs SET customer_name='changed' WHERE id=UUID_TO_BIN('" + jobId + "')");
            assertRejected(statement, "UPDATE assessments SET note_text='changed' WHERE id=UUID_TO_BIN('" + assessmentId + "')");
            assertRejected(statement, "UPDATE findings SET description='changed' WHERE id=UUID_TO_BIN('" + findingId + "')");
            assertRejected(statement, "UPDATE inspection_item_snapshots SET item_json='{}' WHERE job_id=UUID_TO_BIN('" + jobId + "')");
            assertRejected(statement, "UPDATE inspection_final_snapshots SET snapshot_json='{}' WHERE id=UUID_TO_BIN('" + snapshotId + "')");
            assertRejected(statement, "UPDATE evidence_assets SET storage_key='evidence/b.jpg' WHERE job_id=UUID_TO_BIN('" + jobId + "')");
            assertRejected(statement, "UPDATE master_item_versions SET status='DRAFT' WHERE id=UUID_TO_BIN('" + masterVersionId + "')");
            assertRejected(statement, "UPDATE template_versions SET status='DRAFT' WHERE id=UUID_TO_BIN('" + templateVersionId + "')");
        }
    }

    private void assertRejected(Statement statement, String sql) throws Exception {
        try {
            statement.execute(sql);
            throw new AssertionError("SQL was not rejected: " + sql);
        } catch (SQLException exception) {
            assertThat(exception.getMessage().toLowerCase()).contains("immutable");
        }
    }
}
