package com.truereport;

import com.truereport.jobs.PlatformJobStore;
import com.truereport.jobs.PlatformJobStore.JobRow;
import com.truereport.jobs.PlatformJobTokenService;
import com.truereport.shared.uuid.UuidV7;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.UUID;

/**
 * Builds minimal published platform jobs, report versions and public links for
 * delivery/report integration tests.
 */
final class PlatformJobFixtures {

    record Fixture(String jobId, String reportVersionId, String linkId, String token) {
    }

    private PlatformJobFixtures() {
    }

    static Fixture publishedJob(JdbcTemplate jdbc, PlatformJobStore store,
                                PlatformJobTokenService tokens, UUID workshopId, UUID createdBy,
                                String phone, String email, String language, boolean consent,
                                String status, String snapshotJson) {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        String templateVersionId = templateVersion(jdbc, suffix);

        JobRow job = new JobRow(
                null, workshopId.toString(), "DEL-" + suffix, status, "APPROVED",
                "PUBLISHED".equals(status) ? "PUBLISHED" : "UNPUBLISHED",
                templateVersionId, null, "Delivery Customer", phone, email,
                "1HGCM82633A004352", "Toyota", "Corolla", 2020, "DEL-" + suffix,
                12000, "KM", "AUTOMATIC", "PETROL", language,
                null, null, null, null, null, null, null, null, null,
                88, "B", false, null, consent, true, createdBy.toString(),
                null, null, 0);
        String jobId = store.insertJob(job);
        String reportVersionId = store.insertReportVersion(jobId, 1, snapshotJson,
                "0f".repeat(32), createdBy.toString());
        String token = tokens.newToken();
        String linkId = store.insertLink(jobId, reportVersionId, tokens.hash(token),
                tokens.encrypt(token), true);
        return new Fixture(jobId, reportVersionId, linkId, token);
    }

    static String templateVersion(JdbcTemplate jdbc) {
        return templateVersion(jdbc, UUID.randomUUID().toString().substring(0, 8));
    }

    private static String templateVersion(JdbcTemplate jdbc, String suffix) {
        String templateId = UuidV7.generate().toString();
        String templateVersionId = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_templates
                    (id, code, name, status, current_published_version_id,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, 'ACTIVE', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, templateId, "DEL-TPL-" + suffix, "Delivery Template " + suffix);
        jdbc.update("""
                INSERT INTO platform_template_versions
                    (id, template_id, version_no, status, published_at, published_by,
                     created_at, updated_at)
                VALUES (?, ?, 1, 'PUBLISHED', CURRENT_TIMESTAMP, NULL,
                        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, templateVersionId, templateId);
        return templateVersionId;
    }

    static String snapshot(String language) {
        return """
                {
                  "reportNumber":"TR-DEL-1",
                  "reportVersion":1,
                  "finalizedAt":"2026-11-20T10:00:00",
                  "publishedAt":"2026-11-20T10:00:00",
                  "vehicle":{"make":"Toyota","model":"Corolla","year":2022,
                             "vinMasked":"****3456","odometerValue":12000,"odometerUnit":"KM"},
                  "inspection":{"scope":"Inspection","templateVersionNo":1,
                                "dateTime":"2026-11-20T10:00:00"},
                  "workshop":{"name":"Workshop A","branch":""},
                  "technician":{"displayName":"Technician A"},
                  "coverage":{"total":1,"applicable":1,"completed":1,
                              "notApplicable":0,"notChecked":0,"couldNotVerify":0},
                  "keyFindings":[],
                  "categories":[],
                  "notChecked":[],
                  "limitations":[],
                  "disclaimer":"",
                  "verificationHash":"hash",
                  "language":"%s"
                }
                """.formatted(language);
    }
}
