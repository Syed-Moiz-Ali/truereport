package com.truereport;

import com.truereport.shared.uuid.UuidBinaryConverter;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class PlatformContentMigrationTest {

    private static final UuidBinaryConverter BIN = new UuidBinaryConverter();

    @Test
    void legacyMasterContentIsMigratedIntoCleanPlatformTables() throws Exception {
        String url = "jdbc:h2:mem:migration_content;MODE=MySQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1";
        Flyway.configure()
                .dataSource(url, "sa", "")
                .locations("classpath:db/migration", "classpath:db/migration-h2")
                .target("100")
                .load()
                .migrate();

        UUID categoryId = UUID.randomUUID();
        UUID itemId = UUID.randomUUID();
        UUID versionId = UUID.randomUUID();
        UUID guideImageId = UUID.randomUUID();
        Timestamp now = Timestamp.valueOf(LocalDateTime.now());

        try (Connection connection = DriverManager.getConnection(url, "sa", "");
             PreparedStatement category = connection.prepareStatement("""
                     INSERT INTO master_categories
                         (id, slug, status, sort_order, created_at, updated_at, version)
                     VALUES (?, ?, 'ACTIVE', 1, ?, ?, 0)
                     """);
             PreparedStatement item = connection.prepareStatement("""
                     INSERT INTO master_inspection_items
                         (id, stable_code, category_id, status, current_published_version_id,
                          sample_data, created_at, updated_at, version)
                     VALUES (?, ?, ?, 'PUBLISHED', ?, FALSE, ?, ?, 0)
                     """);
             PreparedStatement version = connection.prepareStatement("""
                     INSERT INTO master_item_versions
                         (id, item_id, version_no, status, result_options_json, severity_policy_json,
                          applicability_json, reason_codes_json, note_requirement, evidence_requirement,
                          min_photos, equipment_ids_json, guide_image_id, published_at, published_by,
                          created_at, updated_at, version)
                     VALUES (?, ?, 1, 'PUBLISHED', '["NO_ISSUE_OBSERVED"]', '{}', '{}', '[]',
                             'OPTIONAL', 'NONE', 0, '[]', ?, ?, NULL, ?, ?, 0)
                     """);
             PreparedStatement text = connection.prepareStatement("""
                     INSERT INTO localized_content
                         (id, entity_type, entity_id, locale, field_key, text_value,
                          created_at, updated_at, version)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0)
                     """);
             PreparedStatement weight = connection.prepareStatement("""
                     INSERT INTO platform_category_config
                         (category_id, weight_percentage, created_at, updated_at, version)
                     VALUES (?, 25, ?, ?, 0)
                     """);
             PreparedStatement metadata = connection.prepareStatement("""
                     INSERT INTO platform_item_metadata
                         (item_id, measurement_unit, sensor_tool, standard_spec_en, standard_spec_ar,
                          safety_critical, multi_point, max_tyre_age_years, allow_free_text_note,
                          sort_order, guide_image_id, created_at, updated_at, version)
                     VALUES (?, 'MM', 'Gauge', 'Above 3 mm', 'أعلى من 3 مم', TRUE, FALSE, NULL,
                             FALSE, 7, ?, ?, ?, 0)
                     """);
             PreparedStatement guide = connection.prepareStatement("""
                     INSERT INTO guide_images
                         (id, storage_key, content_hash, mime, bytes, width, height, status,
                          licence_note, uploaded_by, created_at, updated_at, version)
                     VALUES (?, 'guide/legacy.png', ?, 'image/png', 10, NULL, NULL, 'ACTIVE',
                             NULL, ?, ?, ?, 0)
                     """);
             PreparedStatement band = connection.prepareStatement("""
                     INSERT INTO platform_score_bands
                         (id, item_version_id, result_code, min_score, max_score, default_score,
                          criteria_en, criteria_ar, sort_order, created_at, updated_at)
                     VALUES (?, ?, 'NO_ISSUE_OBSERVED', 85, 100, 100, 'Pass', 'نجاح', 1, ?, ?)
                     """)) {
            category.setBytes(1, BIN.convertToDatabaseColumn(categoryId));
            category.setString(2, "CAT-LEGACY");
            category.setTimestamp(3, now);
            category.setTimestamp(4, now);
            category.executeUpdate();

            item.setBytes(1, BIN.convertToDatabaseColumn(itemId));
            item.setString(2, "LEGACY-ITEM-01");
            item.setBytes(3, BIN.convertToDatabaseColumn(categoryId));
            item.setBytes(4, BIN.convertToDatabaseColumn(versionId));
            item.setTimestamp(5, now);
            item.setTimestamp(6, now);
            item.executeUpdate();

            version.setBytes(1, BIN.convertToDatabaseColumn(versionId));
            version.setBytes(2, BIN.convertToDatabaseColumn(itemId));
            version.setBytes(3, BIN.convertToDatabaseColumn(guideImageId));
            version.setTimestamp(4, now);
            version.setTimestamp(5, now);
            version.setTimestamp(6, now);
            version.executeUpdate();

            insertText(text, "CATEGORY", categoryId, "en", "label", "Legacy category", now);
            insertText(text, "CATEGORY", categoryId, "ar", "label", "تصنيف قديم", now);
            insertText(text, "ITEM_VERSION", versionId, "en", "label", "Legacy item", now);
            insertText(text, "ITEM_VERSION", versionId, "ar", "label", "عنصر قديم", now);
            insertText(text, "ITEM_VERSION", versionId, "en", "instruction", "Legacy instruction", now);
            insertText(text, "ITEM_VERSION", versionId, "ar", "instruction", "تعليمات قديمة", now);
            insertText(text, "GUIDE_IMAGE", guideImageId, "en", "alt_text", "Guide", now);
            insertText(text, "GUIDE_IMAGE", guideImageId, "ar", "alt_text", "دليل", now);

            weight.setString(1, categoryId.toString());
            weight.setTimestamp(2, now);
            weight.setTimestamp(3, now);
            weight.executeUpdate();

            metadata.setString(1, itemId.toString());
            metadata.setString(2, guideImageId.toString());
            metadata.setTimestamp(3, now);
            metadata.setTimestamp(4, now);
            metadata.executeUpdate();

            guide.setBytes(1, BIN.convertToDatabaseColumn(guideImageId));
            guide.setBytes(2, new byte[32]);
            guide.setBytes(3, BIN.convertToDatabaseColumn(UUID.randomUUID()));
            guide.setTimestamp(4, now);
            guide.setTimestamp(5, now);
            guide.executeUpdate();

            band.setString(1, UUID.randomUUID().toString());
            band.setString(2, versionId.toString());
            band.setTimestamp(3, now);
            band.setTimestamp(4, now);
            band.executeUpdate();
        }

        Flyway.configure()
                .dataSource(url, "sa", "")
                .locations("classpath:db/migration", "classpath:db/migration-h2")
                .load()
                .migrate();

        try (Connection connection = DriverManager.getConnection(url, "sa", "");
             Statement statement = connection.createStatement()) {
            try (ResultSet rs = statement.executeQuery(
                    "SELECT code, name, weight_percentage FROM platform_categories")) {
                assertThat(rs.next()).isTrue();
                assertThat(rs.getString("code")).isEqualTo("CAT-LEGACY");
                assertThat(rs.getString("name")).isEqualTo("Legacy category");
                assertThat(rs.getBigDecimal("weight_percentage")).isEqualByComparingTo("25");
            }
            try (ResultSet rs = statement.executeQuery("""
                    SELECT i.stable_code, v.label, v.measurement_unit, v.safety_critical,
                           i.sort_order, v.guide_image_id
                    FROM platform_items i
                    JOIN platform_item_versions v ON v.item_id = i.id
                    """)) {
                assertThat(rs.next()).isTrue();
                assertThat(rs.getString("stable_code")).isEqualTo("LEGACY-ITEM-01");
                assertThat(rs.getString("label")).isEqualTo("Legacy item");
                assertThat(rs.getString("measurement_unit")).isEqualTo("MM");
                assertThat(rs.getBoolean("safety_critical")).isTrue();
                assertThat(rs.getInt("sort_order")).isEqualTo(7);
                assertThat(rs.getString("guide_image_id")).isEqualTo(guideImageId.toString());
            }
            try (ResultSet rs = statement.executeQuery(
                    "SELECT lang, body FROM platform_translations WHERE entity_type = 'CATEGORY'"
                            + " AND entity_id = '" + categoryId + "' AND field_name = 'name'")) {
                assertThat(rs.next()).isTrue();
                assertThat(rs.getString("lang")).isEqualTo("ar");
                assertThat(rs.getString("body")).isNotBlank();
            }
            try (ResultSet rs = statement.executeQuery(
                    "SELECT COUNT(*) FROM platform_score_bands WHERE item_version_id = '"
                            + versionId + "'")) {
                rs.next();
                assertThat(rs.getInt(1)).isEqualTo(1);
            }
            try (ResultSet rs = statement.executeQuery(
                    "SELECT COUNT(*) FROM platform_guide_images WHERE id = '" + guideImageId + "'")) {
                rs.next();
                assertThat(rs.getInt(1)).isEqualTo(1);
            }
            try (ResultSet rs = statement.executeQuery(
                    "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES "
                            + "WHERE LOWER(TABLE_NAME) IN ('platform_category_config', 'platform_item_metadata')")) {
                rs.next();
                assertThat(rs.getInt(1)).isZero();
            }
        }
    }

    private void insertText(PreparedStatement statement, String entityType, UUID entityId,
                            String locale, String field, String value, Timestamp now) throws Exception {
        statement.setBytes(1, BIN.convertToDatabaseColumn(UUID.randomUUID()));
        statement.setString(2, entityType);
        statement.setBytes(3, BIN.convertToDatabaseColumn(entityId));
        statement.setString(4, locale);
        statement.setString(5, field);
        statement.setString(6, value);
        statement.setTimestamp(7, now);
        statement.setTimestamp(8, now);
        statement.executeUpdate();
    }
}
