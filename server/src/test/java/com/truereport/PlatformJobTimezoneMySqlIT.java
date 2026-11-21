package com.truereport;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.jobs.PlatformJobStore;
import com.truereport.jobs.PlatformJobStore.JobRow;
import com.truereport.shared.security.PiiCipher;
import com.truereport.shared.uuid.UuidV7;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.LocalDateTime;
import java.util.TimeZone;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * MySQL regression for wall-clock reads. Connector/J builds a
 * {@link java.sql.Timestamp} from the session zone; reading DATETIME through
 * {@code getObject(..., LocalDateTime.class)} keeps the stored wall time.
 *
 * <p>Skipped automatically when Docker is unavailable; the H2
 * {@code WallClockTimezoneIT} covers the same mapper under a forced
 * Asia/Calcutta JVM zone.</p>
 */
@Testcontainers(disabledWithoutDocker = true)
class PlatformJobTimezoneMySqlIT {

    private static final String KEY = "YWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWE=";

    @Container
    static final MySQLContainer<?> MYSQL = new MySQLContainer<>("mysql:8.4.13")
            .withDatabaseName("truereport")
            .withUsername("truereport")
            .withPassword("truereport");

    @Test
    void storeReadsStoredWallClockWithoutJvmShift() {
        Flyway.configure()
                .dataSource(MYSQL.getJdbcUrl(), MYSQL.getUsername(), MYSQL.getPassword())
                .locations("classpath:db/migration", "classpath:db/migration-mysql")
                .load()
                .migrate();

        DriverManagerDataSource dataSource = new DriverManagerDataSource(
                MYSQL.getJdbcUrl(), MYSQL.getUsername(), MYSQL.getPassword());
        JdbcTemplate jdbc = new JdbcTemplate(dataSource);
        PlatformJobStore store = new PlatformJobStore(jdbc,
                new PiiCipher("", "v1", KEY), new ObjectMapper());

        String workshopId = "01a1fe3b-4f49-7909-9764-f4ca326d881d";
        String templateId = UuidV7.generate().toString();
        String templateVersionId = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_templates
                    (id, code, name, status, current_published_version_id,
                     created_at, updated_at, version)
                VALUES (?, ?, 'TZ template', 'ACTIVE', NULL, CURRENT_TIMESTAMP,
                        CURRENT_TIMESTAMP, 0)
                """, templateId, "TZ-" + UUID.randomUUID());
        jdbc.update("""
                INSERT INTO platform_template_versions
                    (id, template_id, version_no, status, published_at, published_by,
                     created_at, updated_at)
                VALUES (?, ?, 1, 'PUBLISHED', CURRENT_TIMESTAMP, NULL,
                        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, templateVersionId, templateId);

        LocalDateTime scheduled = LocalDateTime.parse("2026-11-21T12:00:00");
        LocalDateTime started = LocalDateTime.parse("2026-11-21T12:05:30");
        LocalDateTime completed = LocalDateTime.parse("2026-11-21T13:45:10");
        LocalDateTime published = LocalDateTime.parse("2026-11-21T14:00:00");
        LocalDateTime created = LocalDateTime.parse("2026-11-20T08:15:30");

        JobRow job = new JobRow(
                null, workshopId, "TZ-" + UUID.randomUUID().toString().substring(0, 8),
                "PUBLISHED", "APPROVED", "PUBLISHED", templateVersionId, null,
                "Wall Clock", "+971500000000", null, "1HGCM82633A004352",
                "Toyota", "Corolla", 2022, "TZ-12345", 12000, "KM", "AUTOMATIC",
                "PETROL", "en", scheduled, null, null, null, null, null, null,
                null, null, 100, "A", false, null, true, true, workshopId,
                null, null, 0);
        String jobId = store.insertJob(job);
        jdbc.update("""
                UPDATE platform_jobs
                SET started_at = ?, completed_at = ?, published_at = ?, created_at = ?
                WHERE id = ?
                """, started, completed, published, created, jobId);

        TimeZone original = TimeZone.getDefault();
        try {
            TimeZone.setDefault(TimeZone.getTimeZone("Asia/Calcutta"));
            JobRow read = store.findJob(workshopId, jobId).orElseThrow();
            assertThat(read.scheduledAt()).isEqualTo(scheduled);
            assertThat(read.startedAt()).isEqualTo(started);
            assertThat(read.completedAt()).isEqualTo(completed);
            assertThat(read.publishedAt()).isEqualTo(published);
            assertThat(read.createdAt()).isEqualTo(created);
        } finally {
            TimeZone.setDefault(original);
        }
    }
}
