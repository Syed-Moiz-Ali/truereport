package com.truereport.masterdata.config;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.localization.DynamicContentTranslations;
import com.truereport.masterdata.config.PlatformMasterDtos.EvidenceRuleDto;
import com.truereport.masterdata.config.PlatformMasterDtos.IssueFieldDto;
import com.truereport.masterdata.config.PlatformMasterDtos.ItemMetadataDto;
import com.truereport.masterdata.config.PlatformMasterDtos.MeasurementBandDto;
import com.truereport.shared.uuid.UuidV7;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Repository
public class ItemConfigRepository {

    private final JdbcTemplate jdbc;
    private final ObjectMapper objectMapper;
    private final DynamicContentTranslations translations;

    public ItemConfigRepository(JdbcTemplate jdbc, ObjectMapper objectMapper,
                                DynamicContentTranslations translations) {
        this.jdbc = jdbc;
        this.objectMapper = objectMapper;
        this.translations = translations;
    }

    public List<EvidenceRuleDto> evidenceRules(String versionId) {
        return jdbc.query("""
                SELECT result_code, min_photos, min_videos, min_notes_chars, required_evidence_type
                FROM platform_evidence_rules WHERE item_version_id = ? ORDER BY result_code
                """, (rs, i) -> new EvidenceRuleDto(
                rs.getString("result_code"), rs.getInt("min_photos"), rs.getInt("min_videos"),
                rs.getInt("min_notes_chars"), rs.getString("required_evidence_type")), versionId);
    }

    public void replaceEvidenceRules(String versionId, List<EvidenceRuleDto> rules) {
        jdbc.update("DELETE FROM platform_evidence_rules WHERE item_version_id = ?", versionId);
        for (EvidenceRuleDto rule : rules) {
            jdbc.update("""
                    INSERT INTO platform_evidence_rules
                        (id, item_version_id, result_code, min_photos, min_videos, min_notes_chars,
                         required_evidence_type, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                    """, UuidV7.generate().toString(), versionId, rule.resultCode(), rule.minPhotos(),
                    rule.minVideos(), rule.minNotesChars(), rule.requiredEvidenceType());
        }
    }

    public List<MeasurementBandDto> measurementBands(String versionId) {
        return jdbc.query("""
                SELECT id, field_code, unit_code, direction, min_value, max_value, result_code,
                       default_score, label, sort_order
                FROM platform_measurement_bands WHERE item_version_id = ? ORDER BY sort_order, min_value
                """, (rs, i) -> {
            String id = rs.getString("id");
            String label = rs.getString("label");
            Map<String, Map<String, String>> fields = translations.view(
                    "MEASUREMENT_BAND", id, Map.of("label", safe(label)));
            String labelAr = translations.resolve("MEASUREMENT_BAND", id, "label", "ar", safe(label));
            return new MeasurementBandDto(
                    rs.getString("field_code"), rs.getString("unit_code"), rs.getString("direction"),
                    rs.getBigDecimal("min_value"), rs.getBigDecimal("max_value"),
                    rs.getString("result_code"), rs.getInt("default_score"),
                    label, rs.getInt("sort_order"), fields, label, labelAr);
        }, versionId);
    }

    public void replaceMeasurementBands(String versionId, List<MeasurementBandDto> bands) {
        jdbc.update("DELETE FROM platform_measurement_bands WHERE item_version_id = ?", versionId);
        for (MeasurementBandDto band : bands) {
            String bandId = UuidV7.generate().toString();
            String label = firstNonBlank(band.label(), band.labelEn());
            jdbc.update("""
                    INSERT INTO platform_measurement_bands
                        (id, item_version_id, field_code, unit_code, direction, min_value, max_value,
                         result_code, default_score, label, sort_order,
                         created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                    """, bandId, versionId, band.fieldCode(), band.unitCode(),
                    band.direction(), band.minValue(), band.maxValue(), band.resultCode(),
                    band.defaultScore(), label, band.sortOrder());
            translations.saveOverlays("MEASUREMENT_BAND", bandId,
                    legacy(band.translations(), "label", band.labelAr()), "APPROVED");
        }
    }

    public List<IssueFieldDto> issueFields(String versionId) {
        List<IssueFieldDto> fields = jdbc.query("""
                SELECT f.id, f.field_code, f.label, f.input_type,
                       os.code AS option_set_code, us.code AS unit_set_code, f.is_required,
                       f.required_for_statuses_json, f.min_value, f.max_value, f.decimal_places,
                       f.depends_on_field_code, f.depends_on_value_code, f.allow_multiple,
                       f.allow_free_text, f.sort_order
                FROM platform_issue_fields f
                LEFT JOIN platform_option_sets os ON os.id = f.option_set_id
                LEFT JOIN platform_option_sets us ON us.id = f.unit_set_id
                WHERE f.item_version_id = ? ORDER BY f.sort_order, f.field_code
                """, (rs, i) -> {
            String id = rs.getString("id");
            String label = rs.getString("label");
            Map<String, Map<String, String>> fieldsForRecord = translations.view(
                    "ISSUE_FIELD", id, Map.of("label", safe(label)));
            String labelAr = translations.resolve("ISSUE_FIELD", id, "label", "ar", safe(label));
            return new IssueFieldDto(
                    id, rs.getString("field_code"), label, rs.getString("input_type"),
                    rs.getString("option_set_code"), rs.getString("unit_set_code"),
                    rs.getBoolean("is_required"),
                    parseStatuses(rs.getString("required_for_statuses_json")),
                    rs.getBigDecimal("min_value"), rs.getBigDecimal("max_value"),
                    rs.getInt("decimal_places"), rs.getString("depends_on_field_code"),
                    rs.getString("depends_on_value_code"), rs.getBoolean("allow_multiple"),
                    rs.getBoolean("allow_free_text"), rs.getInt("sort_order"),
                    new ArrayList<>(), fieldsForRecord, label, labelAr);
        }, versionId);
        for (IssueFieldDto field : fields) {
            field.allowedValues().addAll(allowedValues(field.id()));
        }
        return fields;
    }

    public void replaceIssueFields(String versionId, List<IssueFieldDto> fields) {
        List<String> existing = jdbc.query("""
                SELECT id FROM platform_issue_fields WHERE item_version_id = ?
                """, (rs, i) -> rs.getString(1), versionId);
        for (String id : existing) {
            jdbc.update("DELETE FROM platform_issue_field_options WHERE issue_field_id = ?", id);
        }
        jdbc.update("DELETE FROM platform_issue_fields WHERE item_version_id = ?", versionId);
        for (IssueFieldDto field : fields) {
            String fieldId = field.id() == null || field.id().isBlank()
                    ? UuidV7.generate().toString() : field.id();
            String label = firstNonBlank(field.label(), field.labelEn());
            jdbc.update("""
                    INSERT INTO platform_issue_fields
                        (id, item_version_id, field_code, label, input_type,
                         option_set_id, unit_set_id, is_required, required_for_statuses_json,
                         min_value, max_value, decimal_places, depends_on_field_code,
                         depends_on_value_code, allow_multiple, allow_free_text, sort_order,
                         created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                    """, fieldId, versionId, field.fieldCode(), label,
                    field.inputType(), optionSetId(field.optionSetCode()), optionSetId(field.unitSetCode()),
                    Boolean.TRUE.equals(field.required()), toJson(field.requiredForStatuses()),
                    field.minValue(), field.maxValue(),
                    field.decimalPlaces() == null ? 0 : field.decimalPlaces(),
                    field.dependsOnFieldCode(), field.dependsOnValueCode(),
                    Boolean.TRUE.equals(field.allowMultiple()),
                    Boolean.TRUE.equals(field.allowFreeText()),
                    field.sortOrder() == null ? 0 : field.sortOrder());
            translations.saveOverlays("ISSUE_FIELD", fieldId,
                    legacy(field.translations(), "label", field.labelAr()), "APPROVED");
            if (field.allowedValues() != null) {
                for (String valueCode : field.allowedValues()) {
                    String valueId = optionValueId(field.optionSetCode(), valueCode);
                    if (valueId != null) {
                        jdbc.update("""
                                INSERT INTO platform_issue_field_options
                                    (id, issue_field_id, option_value_id)
                                VALUES (?, ?, ?)
                                """, UuidV7.generate().toString(), fieldId, valueId);
                    }
                }
            }
        }
    }

    public void copyVersionConfig(String fromVersionId, String toVersionId) {
        replaceEvidenceRules(toVersionId, evidenceRules(fromVersionId));
        List<IssueFieldDto> copies = issueFields(fromVersionId).stream()
                .map(field -> new IssueFieldDto(
                        null, field.fieldCode(), field.label(), field.inputType(),
                        field.optionSetCode(), field.unitSetCode(), field.required(),
                        field.requiredForStatuses(), field.minValue(), field.maxValue(),
                        field.decimalPlaces(), field.dependsOnFieldCode(), field.dependsOnValueCode(),
                        field.allowMultiple(), field.allowFreeText(), field.sortOrder(),
                        field.allowedValues(), field.translations(), field.labelEn(),
                        field.labelAr()))
                .toList();
        replaceIssueFields(toVersionId, copies);
        replaceMeasurementBands(toVersionId, measurementBands(fromVersionId));
    }

    public long countIssueFieldsUsingOptionSet(String optionSetId) {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_issue_fields WHERE option_set_id = ?
                """, Integer.class, optionSetId);
        return count == null ? 0 : count;
    }

    public long countIssueFieldsUsingUnitSet(String optionSetId) {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_issue_fields WHERE unit_set_id = ?
                """, Integer.class, optionSetId);
        return count == null ? 0 : count;
    }

    private List<String> allowedValues(String issueFieldId) {
        return jdbc.query("""
                SELECT v.code FROM platform_issue_field_options fo
                JOIN platform_option_values v ON v.id = fo.option_value_id
                WHERE fo.issue_field_id = ? ORDER BY v.sort_order, v.code
                """, (rs, i) -> rs.getString(1), issueFieldId);
    }

    private String optionSetId(String code) {
        if (code == null || code.isBlank()) {
            return null;
        }
        return jdbc.query("SELECT id FROM platform_option_sets WHERE code = ?",
                (rs, i) -> rs.getString(1), code).stream().findFirst().orElse(null);
    }

    private String optionValueId(String setCode, String valueCode) {
        if (setCode == null || setCode.isBlank() || valueCode == null || valueCode.isBlank()) {
            return null;
        }
        return jdbc.query("""
                SELECT v.id FROM platform_option_values v
                JOIN platform_option_sets s ON s.id = v.option_set_id
                WHERE s.code = ? AND v.code = ?
                """, (rs, i) -> rs.getString(1), setCode, valueCode).stream().findFirst().orElse(null);
    }

    private List<String> parseStatuses(String json) {
        if (json == null || json.isBlank()) {
            return new ArrayList<>();
        }
        try {
            return new ArrayList<>(objectMapper.readValue(json, new TypeReference<List<String>>() {
            }));
        } catch (Exception ex) {
            return new ArrayList<>();
        }
    }

    private String toJson(List<String> values) {
        try {
            return objectMapper.writeValueAsString(values == null ? List.of() : values);
        } catch (Exception ex) {
            return "[]";
        }
    }

    private Map<String, Map<String, String>> legacy(
            Map<String, Map<String, String>> provided, String field, String legacyAr) {
        Map<String, String> legacy = new LinkedHashMap<>();
        if (legacyAr != null && !legacyAr.isBlank()) {
            legacy.put(field, legacyAr);
        }
        return translations.mergeLegacy(provided, legacy);
    }

    private static String firstNonBlank(String preferred, String fallback) {
        if (preferred != null && !preferred.isBlank()) {
            return preferred.trim();
        }
        return fallback == null ? "" : fallback.trim();
    }

    private static String safe(String value) {
        return value == null ? "" : value;
    }

    public record MetadataRow(String itemId, String measurementUnit, String sensorTool,
                              String standardSpec, boolean safetyCritical, boolean multiPoint,
                              Integer maxTyreAgeYears, boolean allowFreeTextNote, int sortOrder,
                              String guideImageId) {
    }

    public RowMapper<ItemMetadataDto> metadataMapper() {
        return (rs, i) -> {
            String itemId = rs.getString("item_id");
            String standardSpec = rs.getString("standard_spec");
            Map<String, Map<String, String>> fields = translations.view(
                    "ITEM", itemId, Map.of("standardSpec", safe(standardSpec)));
            String standardSpecAr = translations.resolve("ITEM", itemId, "standardSpec", "ar",
                    safe(standardSpec));
            return new ItemMetadataDto(itemId, rs.getString("measurement_unit"),
                    rs.getString("sensor_tool"), standardSpec, rs.getBoolean("safety_critical"),
                    rs.getBoolean("multi_point"), (Integer) rs.getObject("max_tyre_age_years"),
                    rs.getBoolean("allow_free_text_note"), rs.getInt("sort_order"),
                    rs.getString("guide_image_id"), fields, standardSpec, standardSpecAr);
        };
    }

    @SuppressWarnings("unused")
    private static BigDecimal zeroIfNull(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value;
    }
}
