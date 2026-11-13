package db.migration;

import com.truereport.shared.uuid.UuidV7;
import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * Replaces the fixed English/Arabic content columns with one neutral source
 * column per field plus overlay rows in {@code platform_translations}.
 *
 * <p>Existing Arabic values are backfilled into the translation overlay before
 * the legacy columns are dropped, so no content is lost. The English column
 * becomes the source column. No language-specific column remains.</p>
 */
public class V120__Dynamic_language_content extends BaseJavaMigration {

    private record Mapping(String entityType, String table, String field,
                           String sourceColumn, String legacyColumn) {
    }

    private static final List<Mapping> MAPPINGS = List.of(
            new Mapping("CATEGORY", "platform_categories", "name", "name_en", "name_ar"),
            new Mapping("ITEM", "platform_item_versions", "label", "label_en", "label_ar"),
            new Mapping("ITEM", "platform_item_versions", "instruction", "instruction_en", "instruction_ar"),
            new Mapping("ITEM", "platform_item_versions", "standardSpec", "standard_spec_en",
                    "standard_spec_ar"),
            new Mapping("OPTION_SET", "platform_option_sets", "name", "name_en", "name_ar"),
            new Mapping("OPTION_VALUE", "platform_option_values", "label", "label_en", "label_ar"),
            new Mapping("TEMPLATE", "platform_templates", "name", "name_en", "name_ar"),
            new Mapping("TEMPLATE", "platform_templates", "description", "description_en", "description_ar"),
            new Mapping("DOCUMENT_TYPE", "platform_document_types", "name", "name_en", "name_ar"),
            new Mapping("ISSUE_FIELD", "platform_issue_fields", "label", "label_en", "label_ar"),
            new Mapping("MEASUREMENT_BAND", "platform_measurement_bands", "label", "label_en", "label_ar"),
            new Mapping("GRADE_BOUNDARY", "platform_grade_boundaries", "label", "label_en", "label_ar"),
            new Mapping("SCORE_BAND", "platform_score_bands", "criteria", "criteria_en", "criteria_ar"),
            new Mapping("SCORING_RULE", "platform_scoring_rules", "name", "name_en", "name_ar"),
            new Mapping("GUIDE_IMAGE", "platform_guide_images", "alt", "alt_en", "alt_ar")
    );

    private record Rename(String table, String from, String to) {
    }

    private record Drop(String table, String column) {
    }

    private static final List<Rename> RENAMES = List.of(
            new Rename("platform_categories", "name_en", "name"),
            new Rename("platform_item_versions", "label_en", "label"),
            new Rename("platform_item_versions", "instruction_en", "instruction"),
            new Rename("platform_item_versions", "standard_spec_en", "standard_spec"),
            new Rename("platform_option_sets", "name_en", "name"),
            new Rename("platform_option_values", "label_en", "label"),
            new Rename("platform_templates", "name_en", "name"),
            new Rename("platform_templates", "description_en", "description"),
            new Rename("platform_document_types", "name_en", "name"),
            new Rename("platform_issue_fields", "label_en", "label"),
            new Rename("platform_measurement_bands", "label_en", "label"),
            new Rename("platform_grade_boundaries", "label_en", "label"),
            new Rename("platform_score_bands", "criteria_en", "criteria"),
            new Rename("platform_scoring_rules", "name_en", "name"),
            new Rename("platform_guide_images", "alt_en", "alt")
    );

    private static final List<Drop> DROPS = List.of(
            new Drop("platform_categories", "name_ar"),
            new Drop("platform_item_versions", "label_ar"),
            new Drop("platform_item_versions", "instruction_ar"),
            new Drop("platform_item_versions", "standard_spec_ar"),
            new Drop("platform_option_sets", "name_ar"),
            new Drop("platform_option_values", "label_ar"),
            new Drop("platform_templates", "name_ar"),
            new Drop("platform_templates", "description_ar"),
            new Drop("platform_document_types", "name_ar"),
            new Drop("platform_issue_fields", "label_ar"),
            new Drop("platform_measurement_bands", "label_ar"),
            new Drop("platform_grade_boundaries", "label_ar"),
            new Drop("platform_score_bands", "criteria_ar"),
            new Drop("platform_scoring_rules", "name_ar"),
            new Drop("platform_guide_images", "alt_ar"),
            new Drop("platform_languages", "name_en"),
            new Drop("platform_languages", "name_ar")
    );

    @Override
    public void migrate(Context context) throws Exception {
        Connection connection = context.getConnection();
        for (Mapping mapping : MAPPINGS) {
            backfillArabic(connection, mapping);
        }
        for (Rename rename : RENAMES) {
            renameColumn(connection, rename);
        }
        for (Drop drop : DROPS) {
            dropColumn(connection, drop);
        }
        createGenerationJobsTable(connection);
    }

    private void backfillArabic(Connection connection, Mapping mapping) throws Exception {
        Set<String> columns = columns(connection, mapping.table());
        if (!columns.contains(mapping.legacyColumn().toLowerCase(Locale.ROOT))) {
            return;
        }
        String select = "SELECT id, " + mapping.legacyColumn() + " FROM " + mapping.table()
                + " WHERE " + mapping.legacyColumn() + " IS NOT NULL AND TRIM("
                + mapping.legacyColumn() + ") <> ''";
        String exists = "SELECT COUNT(*) FROM platform_translations WHERE entity_type = ?"
                + " AND entity_id = ? AND field_name = ? AND lang = 'ar'";
        String insert = "INSERT INTO platform_translations"
                + " (id, entity_type, entity_id, field_name, lang, body, status,"
                + " created_at, updated_at) VALUES (?,?,?,?,'ar',?,'APPROVED',"
                + " CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)";
        try (Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(select);
             PreparedStatement existsPs = connection.prepareStatement(exists);
             PreparedStatement insertPs = connection.prepareStatement(insert)) {
            while (rs.next()) {
                String entityId = rs.getString("id");
                String body = rs.getString(mapping.legacyColumn());
                if (entityId == null || body == null || body.isBlank()) {
                    continue;
                }
                existsPs.setString(1, mapping.entityType());
                existsPs.setString(2, entityId);
                existsPs.setString(3, mapping.field());
                try (ResultSet found = existsPs.executeQuery()) {
                    found.next();
                    if (found.getInt(1) > 0) {
                        continue;
                    }
                }
                insertPs.setString(1, UuidV7.generate().toString());
                insertPs.setString(2, mapping.entityType());
                insertPs.setString(3, entityId);
                insertPs.setString(4, mapping.field());
                insertPs.setString(5, body);
                insertPs.executeUpdate();
            }
        }
    }

    private void renameColumn(Connection connection, Rename rename) throws Exception {
        Set<String> columns = columns(connection, rename.table());
        boolean hasFrom = columns.contains(rename.from().toLowerCase(Locale.ROOT));
        boolean hasTo = columns.contains(rename.to().toLowerCase(Locale.ROOT));
        if (hasFrom && !hasTo) {
            execute(connection, "ALTER TABLE " + rename.table() + " RENAME COLUMN "
                    + rename.from() + " TO " + rename.to());
        }
    }

    private void dropColumn(Connection connection, Drop drop) throws Exception {
        Set<String> columns = columns(connection, drop.table());
        if (columns.contains(drop.column().toLowerCase(Locale.ROOT))) {
            execute(connection, "ALTER TABLE " + drop.table() + " DROP COLUMN " + drop.column());
        }
    }

    private void createGenerationJobsTable(Connection connection) throws Exception {
        execute(connection, """
                CREATE TABLE platform_content_generation_jobs (
                    id VARCHAR(36) NOT NULL,
                    language_code VARCHAR(20) NOT NULL,
                    entity_types_json TEXT NULL,
                    status VARCHAR(20) NOT NULL,
                    total_keys INT NOT NULL DEFAULT 0,
                    translated_keys INT NOT NULL DEFAULT 0,
                    failed_keys_json TEXT NULL,
                    error_code VARCHAR(80) NULL,
                    error_message TEXT NULL,
                    requested_by VARCHAR(36) NULL,
                    created_at DATETIME(6) NOT NULL,
                    updated_at DATETIME(6) NOT NULL,
                    CONSTRAINT pk_content_generation_jobs PRIMARY KEY (id),
                    CONSTRAINT ck_content_generation_status CHECK (
                        status IN ('QUEUED', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELLED')
                    )
                )
                """);
        execute(connection, "CREATE INDEX ix_content_generation_language"
                + " ON platform_content_generation_jobs (language_code, created_at)");
        execute(connection, "CREATE INDEX ix_content_generation_status"
                + " ON platform_content_generation_jobs (status)");
    }

    private Set<String> columns(Connection connection, String table) throws SQLException {
        Set<String> columns = new HashSet<>();
        try (Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery("SELECT * FROM " + table + " WHERE 1=0")) {
            ResultSetMetaData meta = rs.getMetaData();
            for (int i = 1; i <= meta.getColumnCount(); i++) {
                columns.add(meta.getColumnLabel(i).toLowerCase(Locale.ROOT));
            }
        }
        return columns;
    }

    private void execute(Connection connection, String sql) throws SQLException {
        try (Statement statement = connection.createStatement()) {
            statement.execute(sql);
        }
    }

    @SuppressWarnings("unused")
    private static List<String> empty() {
        return new ArrayList<>();
    }
}
