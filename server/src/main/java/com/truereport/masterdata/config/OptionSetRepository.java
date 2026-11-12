package com.truereport.masterdata.config;

import com.truereport.masterdata.config.PlatformMasterDtos.OptionSetDto;
import com.truereport.masterdata.config.PlatformMasterDtos.OptionValueDto;
import com.truereport.shared.uuid.UuidV7;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

@Repository
public class OptionSetRepository {

    private final JdbcTemplate jdbc;

    public OptionSetRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<OptionSetDto> findAll() {
        List<OptionSetDto> sets = jdbc.query("""
                SELECT id, code, name_en, name_ar, status, sort_order
                FROM platform_option_sets ORDER BY sort_order, code
                """, (rs, i) -> new OptionSetDto(
                rs.getString("id"), rs.getString("code"), rs.getString("name_en"),
                rs.getString("name_ar"), rs.getString("status"), rs.getInt("sort_order"),
                values(rs.getString("id"))));
        return sets;
    }

    public Optional<OptionSetDto> findById(String id) {
        return jdbc.query("""
                SELECT id, code, name_en, name_ar, status, sort_order
                FROM platform_option_sets WHERE id = ?
                """, (rs, i) -> new OptionSetDto(
                rs.getString("id"), rs.getString("code"), rs.getString("name_en"),
                rs.getString("name_ar"), rs.getString("status"), rs.getInt("sort_order"),
                values(rs.getString("id"))), id).stream().findFirst();
    }

    public Optional<OptionSetDto> findByCode(String code) {
        return jdbc.query("""
                SELECT id, code, name_en, name_ar, status, sort_order
                FROM platform_option_sets WHERE code = ?
                """, (rs, i) -> new OptionSetDto(
                rs.getString("id"), rs.getString("code"), rs.getString("name_en"),
                rs.getString("name_ar"), rs.getString("status"), rs.getInt("sort_order"),
                values(rs.getString("id"))), code).stream().findFirst();
    }

    public Set<String> optionSetCodes() {
        return new LinkedHashSet<>(jdbc.query("SELECT code FROM platform_option_sets",
                (rs, i) -> rs.getString(1)));
    }

    public OptionSetDto insert(String code, String nameEn, String nameAr, int sortOrder) {
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_option_sets
                    (id, code, name_en, name_ar, status, sort_order, created_at, updated_at, version)
                VALUES (?, ?, ?, ?, 'ACTIVE', ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, id, code, nameEn, nameAr, sortOrder);
        return findById(id).orElseThrow();
    }

    public void update(String id, String nameEn, String nameAr, Integer sortOrder) {
        jdbc.update("""
                UPDATE platform_option_sets
                SET name_en = COALESCE(?, name_en), name_ar = COALESCE(?, name_ar),
                    sort_order = COALESCE(?, sort_order), updated_at = CURRENT_TIMESTAMP,
                    version = version + 1
                WHERE id = ?
                """, nameEn, nameAr, sortOrder, id);
    }

    public void retire(String id) {
        jdbc.update("""
                UPDATE platform_option_sets SET status = 'RETIRED', updated_at = CURRENT_TIMESTAMP,
                    version = version + 1 WHERE id = ?
                """, id);
    }

    public List<OptionValueDto> values(String optionSetId) {
        return jdbc.query("""
                SELECT id, code, label_en, label_ar, status, sort_order, metadata_json
                FROM platform_option_values WHERE option_set_id = ? ORDER BY sort_order, code
                """, (rs, i) -> new OptionValueDto(
                rs.getString("id"), rs.getString("code"), rs.getString("label_en"),
                rs.getString("label_ar"), rs.getString("status"), rs.getInt("sort_order"),
                rs.getString("metadata_json")), optionSetId);
    }

    public Optional<OptionValueDto> findValue(String id) {
        return jdbc.query("""
                SELECT id, code, label_en, label_ar, status, sort_order, metadata_json
                FROM platform_option_values WHERE id = ?
                """, (rs, i) -> new OptionValueDto(
                rs.getString("id"), rs.getString("code"), rs.getString("label_en"),
                rs.getString("label_ar"), rs.getString("status"), rs.getInt("sort_order"),
                rs.getString("metadata_json")), id).stream().findFirst();
    }

    public Optional<OptionValueDto> findValueByCode(String optionSetId, String code) {
        return jdbc.query("""
                SELECT id, code, label_en, label_ar, status, sort_order, metadata_json
                FROM platform_option_values WHERE option_set_id = ? AND code = ?
                """, (rs, i) -> new OptionValueDto(
                rs.getString("id"), rs.getString("code"), rs.getString("label_en"),
                rs.getString("label_ar"), rs.getString("status"), rs.getInt("sort_order"),
                rs.getString("metadata_json")), optionSetId, code).stream().findFirst();
    }

    public OptionValueDto insertValue(String optionSetId, String code, String labelEn, String labelAr,
                                      int sortOrder, String metadataJson) {
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_option_values
                    (id, option_set_id, code, label_en, label_ar, status, sort_order, metadata_json,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, ?, ?, 'ACTIVE', ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, id, optionSetId, code, labelEn, labelAr, sortOrder, metadataJson);
        return findValue(id).orElseThrow();
    }

    public void updateValue(String id, String labelEn, String labelAr, Integer sortOrder,
                            String metadataJson) {
        jdbc.update("""
                UPDATE platform_option_values
                SET label_en = COALESCE(?, label_en), label_ar = COALESCE(?, label_ar),
                    sort_order = COALESCE(?, sort_order), metadata_json = COALESCE(?, metadata_json),
                    updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE id = ?
                """, labelEn, labelAr, sortOrder, metadataJson, id);
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
}
