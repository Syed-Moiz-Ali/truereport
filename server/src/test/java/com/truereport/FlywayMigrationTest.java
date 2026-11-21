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
                .locations("classpath:db/migration", "classpath:db/migration-h2")
                .target("1")
                .load();
        baseline.migrate();

        assertThat(baseline.info().current().getVersion().toString()).isEqualTo("1");
        assertThat(tableExists(url, "workshops")).isTrue();
        assertThat(tableExists(url, "audit_events")).isFalse();

        Flyway latest = Flyway.configure()
                .dataSource(url, "sa", "")
                .locations("classpath:db/migration", "classpath:db/migration-h2")
                .load();
        latest.migrate();

        assertThat(latest.info().current().getVersion().toString()).isEqualTo("139");
        assertThat(tableExists(url, "audit_events")).isTrue();
        assertThat(tableExists(url, "invitations")).isTrue();
        assertThat(tableExists(url, "account_idempotency_keys")).isTrue();
        assertThat(tableExists(url, "master_inspection_items")).isTrue();
        assertThat(tableExists(url, "workshop_templates")).isTrue();
        assertThat(tableExists(url, "inspection_jobs")).isTrue();
        assertThat(tableExists(url, "inspection_item_snapshots")).isTrue();
        assertThat(tableExists(url, "assessments")).isTrue();
        assertThat(tableExists(url, "inspection_final_snapshots")).isTrue();
        assertThat(tableExists(url, "evidence_assets")).isTrue();
        assertThat(tableExists(url, "platform_languages")).isTrue();
        assertThat(tableExists(url, "platform_categories")).isTrue();
        assertThat(tableExists(url, "platform_items")).isTrue();
        assertThat(tableExists(url, "platform_item_versions")).isTrue();
        assertThat(tableExists(url, "platform_guide_images")).isTrue();
        assertThat(tableExists(url, "platform_template_versions")).isTrue();
        assertThat(tableExists(url, "platform_template_categories")).isTrue();
        assertThat(tableExists(url, "platform_scoring_rules")).isTrue();
        assertThat(tableExists(url, "platform_document_types")).isTrue();
        assertThat(tableExists(url, "platform_outbox_events")).isTrue();
        assertThat(tableExists(url, "platform_jobs")).isTrue();
        assertThat(tableExists(url, "platform_job_assignments")).isTrue();
        assertThat(tableExists(url, "platform_job_results")).isTrue();
        assertThat(tableExists(url, "platform_job_approvals")).isTrue();
        assertThat(tableExists(url, "reference_domain")).isFalse();
        assertThat(tableExists(url, "status_transition")).isTrue();
        assertThat(columnExists(url, "platform_option_sets", "set_kind")).isTrue();
        assertThat(columnExists(url, "platform_option_sets", "domain_key")).isTrue();
        assertThat(columnExists(url, "platform_option_sets", "code_locked")).isTrue();
        assertThat(tableExists(url, "platform_public_links")).isTrue();
        assertThat(tableExists(url, "content_translation")).isTrue();
        assertThat(tableExists(url, "translatable_field")).isTrue();
        assertThat(tableExists(url, "translation_glossary")).isTrue();
        assertThat(columnExists(url, "content_translation", "review_note")).isTrue();
        assertThat(tableExists(url, "platform_report_documents")).isTrue();
        assertThat(tableExists(url, "platform_notifications")).isTrue();
        assertThat(tableExists(url, "platform_job_checklists")).isTrue();
        assertThat(tableExists(url, "platform_assessments")).isTrue();
        assertThat(tableExists(url, "platform_assessment_issue_values")).isTrue();
        assertThat(tableExists(url, "platform_assessment_measurements")).isTrue();
        assertThat(tableExists(url, "platform_evidence_assets")).isTrue();
        assertThat(tableExists(url, "platform_evidence_derivatives")).isTrue();
        assertThat(tableExists(url, "platform_job_signatures")).isTrue();
        assertThat(tableExists(url, "platform_sync_conflicts")).isTrue();
        assertThat(tableExists(url, "platform_translations")).isTrue();
        assertThat(tableExists(url, "platform_ui_messages")).isFalse();
        assertThat(tableExists(url, "platform_ui_message_versions")).isFalse();
        assertThat(tableExists(url, "platform_ui_message_language_versions")).isFalse();
        assertThat(tableExists(url, "platform_settings")).isFalse();
        assertThat(tableExists(url, "platform_ui_message_generation_jobs")).isFalse();
        assertThat(tableExists(url, "platform_content_generation_jobs")).isFalse();
        assertThat(columnExists(url, "platform_languages", "ui_messages_path")).isFalse();
        assertThat(columnExists(url, "platform_languages", "ui_messages_hash")).isFalse();
        assertThat(columnExists(url, "platform_languages", "ui_messages_reviewed_at")).isFalse();
        assertThat(columnExists(url, "platform_languages", "name_en")).isFalse();
        assertThat(columnExists(url, "platform_languages", "name_ar")).isFalse();
        assertThat(columnExists(url, "platform_categories", "name")).isTrue();
        assertThat(columnExists(url, "platform_categories", "name_en")).isFalse();
        assertThat(columnExists(url, "platform_categories", "name_ar")).isFalse();
        assertThat(columnExists(url, "platform_item_versions", "label")).isTrue();
        assertThat(columnExists(url, "platform_item_versions", "label_en")).isFalse();
        assertThat(columnExists(url, "platform_item_versions", "label_ar")).isFalse();
        assertThat(columnExists(url, "platform_templates", "name")).isTrue();
        assertThat(columnExists(url, "platform_templates", "description")).isTrue();
        assertThat(columnExists(url, "platform_templates", "name_en")).isFalse();
        assertThat(columnExists(url, "platform_templates", "name_ar")).isFalse();
        assertThat(columnExists(url, "platform_option_sets", "name")).isTrue();
        assertThat(columnExists(url, "platform_option_sets", "name_ar")).isFalse();
        assertThat(columnExists(url, "platform_option_values", "label")).isTrue();
        assertThat(columnExists(url, "platform_option_values", "label_ar")).isFalse();
        assertThat(columnExists(url, "platform_option_values", "label_key")).isTrue();
        assertThat(columnExists(url, "platform_document_types", "name")).isTrue();
        assertThat(columnExists(url, "platform_document_types", "name_ar")).isFalse();
        assertThat(columnExists(url, "platform_issue_fields", "label")).isTrue();
        assertThat(columnExists(url, "platform_issue_fields", "label_ar")).isFalse();
    }

    private boolean columnExists(String url, String table, String column) throws Exception {
        try (Connection connection = DriverManager.getConnection(url, "sa", "");
             ResultSet result = connection.getMetaData().getColumns(
                     null, null, table, column)) {
            return result.next();
        }
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
