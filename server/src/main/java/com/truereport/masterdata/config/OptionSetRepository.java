package com.truereport.masterdata.config;

import com.truereport.localization.DynamicContentTranslations;
import com.truereport.masterdata.config.PlatformMasterDtos.OptionSetDto;
import com.truereport.masterdata.config.PlatformMasterDtos.OptionValueDto;
import com.truereport.shared.uuid.UuidV7;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

@Repository
public class OptionSetRepository {

    private final JdbcTemplate jdbc;
    private final DynamicContentTranslations translations;

    public OptionSetRepository(JdbcTemplate jdbc, DynamicContentTranslations translations) {
        this.jdbc = jdbc;
        this.translations = translations;
    }

    public List<OptionSetDto> findAll() {
        return jdbc.query("""
                SELECT id, code, name, status, sort_order
                FROM platform_option_sets ORDER BY sort_order, code
                """, (rs, i) -> optionSet(rs.getString("id"), rs.getString("code"),
                rs.getString("name"), rs.getString("status"), rs.getInt("sort_order")));
    }

    public Optional<OptionSetDto> findById(String id) {
        return jdbc.query("""
                SELECT id, code, name, status, sort_order
                FROM platform_option_sets WHERE id = ?
                """, (rs, i) -> optionSet(rs.getString("id"), rs.getString("code"),
                rs.getString("name"), rs.getString("status"), rs.getInt("sort_order")), id)
                .stream().findFirst();
    }

    public Optional<OptionSetDto> findByCode(String code) {
        return jdbc.query("""
                SELECT id, code, name, status, sort_order
                FROM platform_option_sets WHERE code = ?
                """, (rs, i) -> optionSet(rs.getString("id"), rs.getString("code"),
                rs.getString("name"), rs.getString("status"), rs.getInt("sort_order")), code)
                .stream().findFirst();
    }

    public Set<String> optionSetCodes() {
        return new LinkedHashSet<>(jdbc.query("SELECT code FROM platform_option_sets",
                (rs, i) -> rs.getString(1)));
    }

    public OptionSetDto insert(String code, String name,
                               Map<String, Map<String, String>> fieldTranslations, int sortOrder,
                               String status) {
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_option_sets
                    (id, code, name, status, sort_order, created_at, updated_at, version)
                VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, id, code, name, status, sortOrder);
        translations.saveOverlays("OPTION_SET", id, fieldTranslations, "APPROVED");
        return findById(id).orElseThrow();
    }

    public void update(String id, String name,
                       Map<String, Map<String, String>> fieldTranslations, Integer sortOrder,
                       String status) {
        jdbc.update("""
                UPDATE platform_option_sets
                SET name = COALESCE(?, name), status = COALESCE(?, status),
                    sort_order = COALESCE(?, sort_order), updated_at = CURRENT_TIMESTAMP,
                    version = version + 1
                WHERE id = ?
                """, name, status, sortOrder, id);
        translations.saveOverlays("OPTION_SET", id, fieldTranslations, "APPROVED");
    }

    public void setStatus(String id, String status) {
        jdbc.update("""
                UPDATE platform_option_sets SET status = ?, updated_at = CURRENT_TIMESTAMP,
                    version = version + 1 WHERE id = ?
                """, status, id);
    }

    public void setValueStatus(String id, String status) {
        jdbc.update("""
                UPDATE platform_option_values SET status = ?, updated_at = CURRENT_TIMESTAMP,
                    version = version + 1 WHERE id = ?
                """, status, id);
    }

    public void retire(String id) {
        jdbc.update("""
                UPDATE platform_option_sets SET status = 'RETIRED', updated_at = CURRENT_TIMESTAMP,
                    version = version + 1 WHERE id = ?
                """, id);
    }

    public List<OptionValueDto> values(String optionSetId) {
        return jdbc.query("""
                SELECT id, code, label, status, sort_order, metadata_json
                FROM platform_option_values WHERE option_set_id = ? ORDER BY sort_order, code
                """, (rs, i) -> optionValue(rs.getString("id"), rs.getString("code"),
                rs.getString("label"), rs.getString("status"), rs.getInt("sort_order"),
                rs.getString("metadata_json")), optionSetId);
    }

    public Optional<OptionValueDto> findValue(String id) {
        return jdbc.query("""
                SELECT id, code, label, status, sort_order, metadata_json
                FROM platform_option_values WHERE id = ?
                """, (rs, i) -> optionValue(rs.getString("id"), rs.getString("code"),
                rs.getString("label"), rs.getString("status"), rs.getInt("sort_order"),
                rs.getString("metadata_json")), id).stream().findFirst();
    }

    public Optional<OptionValueDto> findValueByCode(String optionSetId, String code) {
        return jdbc.query("""
                SELECT id, code, label, status, sort_order, metadata_json
                FROM platform_option_values WHERE option_set_id = ? AND code = ?
                """, (rs, i) -> optionValue(rs.getString("id"), rs.getString("code"),
                rs.getString("label"), rs.getString("status"), rs.getInt("sort_order"),
                rs.getString("metadata_json")), optionSetId, code).stream().findFirst();
    }

    public OptionValueDto insertValue(String optionSetId, String code, String label,
                                      Map<String, Map<String, String>> fieldTranslations,
                                      int sortOrder, String metadataJson, String status) {
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_option_values
                    (id, option_set_id, code, label, status, sort_order, metadata_json,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, id, optionSetId, code, label, status, sortOrder, metadataJson);
        translations.saveOverlays("OPTION_VALUE", id, fieldTranslations, "APPROVED");
        return findValue(id).orElseThrow();
    }

    public void updateValue(String id, String label,
                            Map<String, Map<String, String>> fieldTranslations, Integer sortOrder,
                            String metadataJson, String status) {
        jdbc.update("""
                UPDATE platform_option_values
                SET label = COALESCE(?, label), status = COALESCE(?, status),
                    sort_order = COALESCE(?, sort_order), metadata_json = COALESCE(?, metadata_json),
                    updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE id = ?
                """, label, status, sortOrder, metadataJson, id);
        translations.saveOverlays("OPTION_VALUE", id, fieldTranslations, "APPROVED");
    }

    public void retireValue(String id) {
        jdbc.update("""
                UPDATE platform_option_values SET status = 'RETIRED', updated_at = CURRENT_TIMESTAMP,
                    version = version + 1 WHERE id = ?
                """, id);
    }

    public void reorderValues(String optionSetId, List<String> ordered) {
        int order = 1;
        for (String value : ordered) {
            jdbc.update("""
                    UPDATE platform_option_values SET sort_order = ?, updated_at = CURRENT_TIMESTAMP
                    WHERE option_set_id = ? AND (id = ? OR code = ?)
                    """, order++, optionSetId, value, value);
        }
    }

    public boolean valueInUse(String valueId) {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_issue_field_options WHERE option_value_id = ?
                """, Integer.class, valueId);
        return count != null && count > 0;
    }

    public void replaceInUse(String oldValueId, String newValueId) {
        List<String> fieldIds = jdbc.query("""
                SELECT issue_field_id FROM platform_issue_field_options WHERE option_value_id = ?
                """, (rs, i) -> rs.getString(1), oldValueId);
        for (String fieldId : fieldIds) {
            Integer exists = jdbc.queryForObject("""
                    SELECT COUNT(*) FROM platform_issue_field_options
                    WHERE issue_field_id = ? AND option_value_id = ?
                    """, Integer.class, fieldId, newValueId);
            if (exists != null && exists > 0) {
                jdbc.update("DELETE FROM platform_issue_field_options WHERE issue_field_id = ? AND option_value_id = ?",
                        fieldId, oldValueId);
            } else {
                jdbc.update("""
                        UPDATE platform_issue_field_options SET option_value_id = ?
                        WHERE issue_field_id = ? AND option_value_id = ?
                        """, newValueId, fieldId, oldValueId);
            }
        }
    }

    public boolean optionSetInUse(String optionSetId) {
        Integer count = jdbc.queryForObject("""
                SELECT (SELECT COUNT(*) FROM platform_issue_fields WHERE option_set_id = ?)
                     + (SELECT COUNT(*) FROM platform_issue_fields WHERE unit_set_id = ?)
                """, Integer.class, optionSetId, optionSetId);
        return count != null && count > 0;
    }

    public long countValues(String optionSetId) {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_option_values WHERE option_set_id = ?
                """, Integer.class, optionSetId);
        return count == null ? 0 : count;
    }

    private OptionSetDto optionSet(String id, String code, String name, String status, int sortOrder) {
        Map<String, Map<String, String>> fieldTranslations =
                translations.view("OPTION_SET", id, Map.of("name", name == null ? "" : name));
        String nameAr = translations.resolve("OPTION_SET", id, "name", "ar",
                name == null ? "" : name);
        return new OptionSetDto(id, code, name, status, sortOrder, values(id),
                fieldTranslations, name, nameAr);
    }

    private OptionValueDto optionValue(String id, String code, String label, String status,
                                       int sortOrder, String metadataJson) {
        Map<String, Map<String, String>> fieldTranslations =
                translations.view("OPTION_VALUE", id, Map.of("label", label == null ? "" : label));
        String labelAr = translations.resolve("OPTION_VALUE", id, "label", "ar",
                label == null ? "" : label);
        return new OptionValueDto(id, code, label, status, sortOrder, metadataJson,
                fieldTranslations, label, labelAr);
    }

    @SuppressWarnings("unused")
    private static Map<String, String> empty() {
        return new LinkedHashMap<>();
    }
}
