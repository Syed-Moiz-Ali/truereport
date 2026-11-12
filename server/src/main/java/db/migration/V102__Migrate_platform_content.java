package db.migration;

import com.truereport.shared.uuid.UuidBinaryConverter;
import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Migrates legacy master content into the clean platform_* tables.
 * Runs only when the clean parent tables are empty. No-op on a fresh database.
 */
public class V102__Migrate_platform_content extends BaseJavaMigration {

    private static final UuidBinaryConverter BIN = new UuidBinaryConverter();

    @Override
    public void migrate(Context context) throws Exception {
        Connection connection = context.getConnection();
        if (count(connection, "platform_categories") > 0 || count(connection, "platform_items") > 0) {
            return;
        }
        Map<String, String> categoryText = localized(connection, "CATEGORY");
        Map<String, String> versionText = localized(connection, "ITEM_VERSION");
        Map<String, String> guideText = localized(connection, "GUIDE_IMAGE");
        Map<String, BigDecimal> weights = categoryWeights(connection);
        Map<String, ItemMetadata> metadata = itemMetadata(connection);

        migrateCategories(connection, categoryText, weights);
        migrateGuideImages(connection, guideText);
        migrateItems(connection, versionText, metadata);
        cleanOrphans(connection);
    }

    private void migrateCategories(Connection connection, Map<String, String> text,
                                   Map<String, BigDecimal> weights) throws Exception {
        String sql = "SELECT id, slug, status, sort_order, created_at, updated_at, version "
                + "FROM master_categories";
        String insert = "INSERT INTO platform_categories "
                + "(id, code, name_en, name_ar, weight_percentage, status, sort_order, "
                + "created_at, updated_at, version) VALUES (?,?,?,?,?,?,?,?,?,?)";
        try (Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(sql);
             PreparedStatement ps = connection.prepareStatement(insert)) {
            while (rs.next()) {
                String id = uuid(rs.getBytes("id"));
                String code = rs.getString("slug");
                ps.setString(1, id);
                ps.setString(2, code);
                ps.setString(3, text.getOrDefault(key(id, "en", "label"), code));
                ps.setString(4, text.getOrDefault(key(id, "ar", "label"), code));
                ps.setBigDecimal(5, weights.getOrDefault(id, BigDecimal.ZERO));
                ps.setString(6, rs.getString("status"));
                ps.setInt(7, rs.getInt("sort_order"));
                setTime(ps, 8, rs.getTimestamp("created_at"));
                setTime(ps, 9, rs.getTimestamp("updated_at"));
                ps.setInt(10, rs.getInt("version"));
                ps.addBatch();
            }
            ps.executeBatch();
        }
    }

    private void migrateItems(Connection connection, Map<String, String> text,
                              Map<String, ItemMetadata> metadata) throws Exception {
        String itemSql = "SELECT id, stable_code, category_id, status, current_published_version_id, "
                + "sample_data, created_at, updated_at, version FROM master_inspection_items";
        String itemInsert = "INSERT INTO platform_items "
                + "(id, stable_code, category_id, status, current_published_version_id, sample_data, "
                + "sort_order, created_at, updated_at, version) VALUES (?,?,?,?,NULL,?,?,?,?,?)";
        try (Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(itemSql);
             PreparedStatement ps = connection.prepareStatement(itemInsert)) {
            while (rs.next()) {
                String id = uuid(rs.getBytes("id"));
                ItemMetadata meta = metadata.getOrDefault(id, ItemMetadata.EMPTY);
                ps.setString(1, id);
                ps.setString(2, rs.getString("stable_code"));
                ps.setString(3, uuid(rs.getBytes("category_id")));
                ps.setString(4, rs.getString("status"));
                ps.setBoolean(5, rs.getBoolean("sample_data"));
                ps.setInt(6, meta.sortOrder);
                setTime(ps, 7, rs.getTimestamp("created_at"));
                setTime(ps, 8, rs.getTimestamp("updated_at"));
                ps.setInt(9, rs.getInt("version"));
                ps.addBatch();
            }
            ps.executeBatch();
        }
        migrateVersions(connection, text, metadata);
        updateCurrentVersions(connection);
    }

    private void updateCurrentVersions(Connection connection) throws Exception {
        String select = "SELECT id, current_published_version_id FROM master_inspection_items "
                + "WHERE current_published_version_id IS NOT NULL";
        String update = "UPDATE platform_items SET current_published_version_id = ? WHERE id = ?";
        try (Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(select);
             PreparedStatement ps = connection.prepareStatement(update)) {
            while (rs.next()) {
                ps.setString(1, uuid(rs.getBytes("current_published_version_id")));
                ps.setString(2, uuid(rs.getBytes("id")));
                ps.addBatch();
            }
            ps.executeBatch();
        }
    }

    private void migrateVersions(Connection connection, Map<String, String> text,
                                 Map<String, ItemMetadata> metadata) throws Exception {
        String sql = "SELECT id, item_id, version_no, status, result_options_json, "
                + "severity_policy_json, applicability_json, reason_codes_json, note_requirement, "
                + "evidence_requirement, min_photos, equipment_ids_json, guide_image_id, published_at, "
                + "published_by, created_at, updated_at, version FROM master_item_versions";
        String insert = "INSERT INTO platform_item_versions "
                + "(id, item_id, version_no, status, label_en, label_ar, instruction_en, "
                + "instruction_ar, measurement_unit, sensor_tool, standard_spec_en, standard_spec_ar, "
                + "safety_critical, multi_point, max_tyre_age_years, allow_free_text_note, "
                + "result_options_json, severity_policy_json, applicability_json, reason_codes_json, "
                + "note_requirement, evidence_requirement, min_photos, equipment_ids_json, "
                + "guide_image_id, published_at, published_by, created_at, updated_at, version) "
                + "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
        try (Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(sql);
             PreparedStatement ps = connection.prepareStatement(insert)) {
            while (rs.next()) {
                String versionId = uuid(rs.getBytes("id"));
                String itemId = uuid(rs.getBytes("item_id"));
                ItemMetadata meta = metadata.getOrDefault(itemId, ItemMetadata.EMPTY);
                String labelEn = text.getOrDefault(key(versionId, "en", "label"), "");
                String labelAr = text.getOrDefault(key(versionId, "ar", "label"), "");
                ps.setString(1, versionId);
                ps.setString(2, itemId);
                ps.setInt(3, rs.getInt("version_no"));
                ps.setString(4, rs.getString("status"));
                ps.setString(5, labelEn.isBlank() ? "" : labelEn);
                ps.setString(6, labelAr.isBlank() ? "" : labelAr);
                ps.setString(7, text.getOrDefault(key(versionId, "en", "instruction"), ""));
                ps.setString(8, text.getOrDefault(key(versionId, "ar", "instruction"), ""));
                ps.setString(9, meta.measurementUnit);
                ps.setString(10, meta.sensorTool);
                ps.setString(11, meta.standardSpecEn);
                ps.setString(12, meta.standardSpecAr);
                ps.setBoolean(13, meta.safetyCritical);
                ps.setBoolean(14, meta.multiPoint);
                setNullableInt(ps, 15, meta.maxTyreAgeYears);
                ps.setBoolean(16, meta.allowFreeTextNote);
                ps.setString(17, rs.getString("result_options_json"));
                ps.setString(18, rs.getString("severity_policy_json"));
                ps.setString(19, rs.getString("applicability_json"));
                ps.setString(20, rs.getString("reason_codes_json"));
                ps.setString(21, rs.getString("note_requirement"));
                ps.setString(22, rs.getString("evidence_requirement"));
                ps.setInt(23, rs.getInt("min_photos"));
                ps.setString(24, rs.getString("equipment_ids_json"));
                ps.setString(25, uuid(rs.getBytes("guide_image_id")));
                setTime(ps, 26, rs.getTimestamp("published_at"));
                ps.setString(27, uuid(rs.getBytes("published_by")));
                setTime(ps, 28, rs.getTimestamp("created_at"));
                setTime(ps, 29, rs.getTimestamp("updated_at"));
                ps.setInt(30, rs.getInt("version"));
                ps.addBatch();
            }
            ps.executeBatch();
        }
    }

    private void migrateGuideImages(Connection connection, Map<String, String> text) throws Exception {
        String sql = "SELECT id, storage_key, content_hash, mime, bytes, status, licence_note, "
                + "uploaded_by, created_at, updated_at, version FROM guide_images";
        String insert = "INSERT INTO platform_guide_images "
                + "(id, storage_key, content_hash, mime, bytes, status, licence_note, alt_en, alt_ar, "
                + "uploaded_by, created_at, updated_at, version) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)";
        try (Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(sql);
             PreparedStatement ps = connection.prepareStatement(insert)) {
            while (rs.next()) {
                String id = uuid(rs.getBytes("id"));
                ps.setString(1, id);
                ps.setString(2, rs.getString("storage_key"));
                ps.setBytes(3, rs.getBytes("content_hash"));
                ps.setString(4, rs.getString("mime"));
                ps.setLong(5, rs.getLong("bytes"));
                ps.setString(6, rs.getString("status"));
                ps.setString(7, rs.getString("licence_note"));
                ps.setString(8, text.getOrDefault(key(id, "en", "alt_text"), ""));
                ps.setString(9, text.getOrDefault(key(id, "ar", "alt_text"), ""));
                ps.setString(10, uuid(rs.getBytes("uploaded_by")));
                setTime(ps, 11, rs.getTimestamp("created_at"));
                setTime(ps, 12, rs.getTimestamp("updated_at"));
                ps.setInt(13, rs.getInt("version"));
                ps.addBatch();
            }
            ps.executeBatch();
        }
    }

    private void cleanOrphans(Connection connection) throws Exception {
        String[] statements = {
                "DELETE FROM platform_score_bands WHERE item_version_id NOT IN "
                        + "(SELECT id FROM platform_item_versions)",
                "DELETE FROM platform_evidence_rules WHERE item_version_id NOT IN "
                        + "(SELECT id FROM platform_item_versions)",
                "DELETE FROM platform_measurement_bands WHERE item_version_id NOT IN "
                        + "(SELECT id FROM platform_item_versions)",
                "DELETE FROM platform_issue_field_options WHERE issue_field_id NOT IN "
                        + "(SELECT id FROM platform_issue_fields)",
                "DELETE FROM platform_issue_field_options WHERE option_value_id NOT IN "
                        + "(SELECT id FROM platform_option_values)",
                "DELETE FROM platform_issue_fields WHERE item_version_id NOT IN "
                        + "(SELECT id FROM platform_item_versions)",
                "DELETE FROM platform_template_items WHERE item_version_id NOT IN "
                        + "(SELECT id FROM platform_item_versions)"
        };
        try (Statement statement = connection.createStatement()) {
            for (String sql : statements) {
                try {
                    statement.executeUpdate(sql);
                } catch (Exception ignored) {
                    // Table shapes differ in older environments; FK validation will report if needed.
                }
            }
        }
    }

    private static int count(Connection connection, String table) throws Exception {
        try (Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery("SELECT COUNT(*) FROM " + table)) {
            rs.next();
            return rs.getInt(1);
        }
    }

    private Map<String, String> localized(Connection connection, String entityType) throws Exception {
        Map<String, String> result = new HashMap<>();
        String sql = "SELECT entity_id, locale, field_key, text_value FROM localized_content "
                + "WHERE entity_type = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, entityType);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String id = uuid(rs.getBytes("entity_id"));
                    result.put(key(id, rs.getString("locale"), rs.getString("field_key")),
                            rs.getString("text_value"));
                }
            }
        }
        return result;
    }

    private Map<String, BigDecimal> categoryWeights(Connection connection) {
        Map<String, BigDecimal> result = new HashMap<>();
        try (Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(
                     "SELECT category_id, weight_percentage FROM platform_category_config")) {
            while (rs.next()) {
                result.put(rs.getString(1), rs.getBigDecimal(2));
            }
        } catch (Exception ignored) {
            // Side table may not exist in a pre-Phase-1 database.
        }
        return result;
    }

    private Map<String, ItemMetadata> itemMetadata(Connection connection) {
        Map<String, ItemMetadata> result = new HashMap<>();
        try (Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(
                     "SELECT item_id, measurement_unit, sensor_tool, standard_spec_en, "
                             + "standard_spec_ar, safety_critical, multi_point, max_tyre_age_years, "
                             + "allow_free_text_note, sort_order FROM platform_item_metadata")) {
            while (rs.next()) {
                result.put(rs.getString("item_id"), new ItemMetadata(
                        rs.getString("measurement_unit"), rs.getString("sensor_tool"),
                        rs.getString("standard_spec_en"), rs.getString("standard_spec_ar"),
                        rs.getBoolean("safety_critical"), rs.getBoolean("multi_point"),
                        (Integer) rs.getObject("max_tyre_age_years"),
                        rs.getBoolean("allow_free_text_note"), rs.getInt("sort_order")));
            }
        } catch (Exception ignored) {
            // No metadata rows in a fresh database.
        }
        return result;
    }

    private static String key(String id, String locale, String field) {
        return (id == null ? "" : id) + "|" + locale + "|" + field;
    }

    private static String uuid(byte[] bytes) {
        if (bytes == null) {
            return null;
        }
        return BIN.convertToEntityAttribute(bytes).toString();
    }

    private static void setTime(PreparedStatement ps, int index, Timestamp value) throws Exception {
        if (value == null) {
            ps.setTimestamp(index, Timestamp.valueOf(LocalDateTime.now()));
        } else {
            ps.setTimestamp(index, value);
        }
    }

    private static void setNullableInt(PreparedStatement ps, int index, Integer value) throws Exception {
        if (value == null) {
            ps.setNull(index, java.sql.Types.INTEGER);
        } else {
            ps.setInt(index, value);
        }
    }

    private record ItemMetadata(String measurementUnit, String sensorTool, String standardSpecEn,
                                String standardSpecAr, boolean safetyCritical, boolean multiPoint,
                                Integer maxTyreAgeYears, boolean allowFreeTextNote, int sortOrder) {
        static final ItemMetadata EMPTY = new ItemMetadata(null, null, null, null,
                false, false, null, false, 0);
    }
}
