package com.truereport.seed;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.localization.DynamicContentTranslations;
import com.truereport.masterdata.config.ConfigValidators;
import com.truereport.masterdata.config.ItemConfigRepository;
import com.truereport.masterdata.config.PlatformMasterDtos.EvidenceRuleDto;
import com.truereport.masterdata.config.PlatformMasterDtos.IssueFieldDto;
import com.truereport.masterdata.config.PlatformMasterDtos.MeasurementBandDto;
import com.truereport.shared.uuid.UuidV7;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Idempotent seed for the approved 6-category / 30-item GCC checklist.
 * Existing codes are never overwritten.
 */
@Service
public class DefaultChecklistSeeder {

    private static final List<String> RESULTS = List.of(
            "NO_ISSUE_OBSERVED", "ATTENTION_RECOMMENDED", "DEFECT_FOUND");

    private final JdbcTemplate jdbc;
    private final ItemConfigRepository itemConfig;
    private final ObjectMapper objectMapper;
    private final DynamicContentTranslations translations;

    public DefaultChecklistSeeder(JdbcTemplate jdbc, ItemConfigRepository itemConfig,
                                  ObjectMapper objectMapper,
                                  DynamicContentTranslations translations) {
        this.jdbc = jdbc;
        this.itemConfig = itemConfig;
        this.objectMapper = objectMapper;
        this.translations = translations;
    }

    @Transactional
    public SeedResult seedDefaultChecklist() {
        int created = 0;
        int skipped = 0;
        List<String> errors = new ArrayList<>();

        // 1. Option sets and values
        for (OptionSetDefinition definition : optionSets()) {
            boolean createdSet = ensureOptionSet(definition);
            if (createdSet) {
                created++;
            } else {
                skipped++;
            }
            created += ensureOptionValues(definition);
        }

        // 2. Categories
        Map<String, UUID> categoryIds = new LinkedHashMap<>();
        for (CategorySeed category : categories()) {
            Optional<UUID> existing = findCategoryBySlug(category.code());
            if (existing.isPresent()) {
                categoryIds.put(category.code(), existing.get());
                skipped++;
            } else {
                UUID id = insertCategory(category);
                categoryIds.put(category.code(), id);
                created++;
            }
        }

        // 3. Items
        Map<String, UUID> versionByCode = new LinkedHashMap<>();
        for (ItemSeed item : items()) {
            Optional<UUID> existing = findItemByCode(item.code());
            if (existing.isPresent()) {
                skipped++;
                findCurrentVersion(existing.get()).ifPresent(versionId ->
                        versionByCode.put(item.code(), versionId));
            } else {
                UUID categoryId = categoryIds.get(item.categoryCode());
                if (categoryId == null) {
                    errors.add("CATEGORY_MISSING:" + item.categoryCode());
                    continue;
                }
                UUID versionId = insertItem(item, categoryId);
                versionByCode.put(item.code(), versionId);
                created++;
            }
        }

        // 4. Document types
        for (DocumentTypeSeed documentType : documentTypes()) {
            if (ensureDocumentType(documentType)) {
                created++;
            } else {
                skipped++;
            }
        }

        // 5. Default template
        if (ensureDefaultTemplate(versionByCode, categoryIds)) {
            created++;
        } else {
            skipped++;
        }

        return new SeedResult(created, skipped, errors);
    }

    public record SeedResult(int created, int skipped, List<String> errors) {
    }

    // ------------------------------------------------------------ option sets

    private boolean ensureOptionSet(OptionSetDefinition definition) {
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM platform_option_sets WHERE code = ?", Integer.class,
                definition.code());
        if (count != null && count > 0) {
            return false;
        }
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_option_sets
                    (id, code, name, status, sort_order, created_at, updated_at, version)
                VALUES (?, ?, ?, 'ACTIVE', ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, id, definition.code(), definition.nameEn(), definition.sortOrder());
        translations.saveOverlays("OPTION_SET", id, translation("name", definition.nameAr()),
                "APPROVED");
        return true;
    }

    private int ensureOptionValues(OptionSetDefinition definition) {
        String setId = jdbc.query("SELECT id FROM platform_option_sets WHERE code = ?",
                (rs, i) -> rs.getString(1), definition.code()).stream().findFirst().orElse(null);
        if (setId == null) {
            return 0;
        }
        int created = 0;
        int order = 1;
        for (OptionValueSeed value : definition.values()) {
            Integer count = jdbc.queryForObject("""
                    SELECT COUNT(*) FROM platform_option_values WHERE option_set_id = ? AND code = ?
                    """, Integer.class, setId, value.code());
            if (count == null || count == 0) {
                String valueId = UuidV7.generate().toString();
                jdbc.update("""
                        INSERT INTO platform_option_values
                            (id, option_set_id, code, label, status, sort_order,
                             metadata_json, created_at, updated_at, version)
                        VALUES (?, ?, ?, ?, 'ACTIVE', ?, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                        """, valueId, setId, value.code(), value.en(), order);
                translations.saveOverlays("OPTION_VALUE", valueId, translation("label", value.ar()),
                        "APPROVED");
                created++;
            }
            order++;
        }
        return created;
    }

    // -------------------------------------------------------------- categories

    private UUID insertCategory(CategorySeed category) {
        UUID id = UuidV7.generate();
        jdbc.update("""
                INSERT INTO platform_categories
                    (id, code, name, status, sort_order,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, 'ACTIVE', ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, id.toString(), category.code(), category.nameEn(), category.sortOrder());
        translations.saveOverlays("CATEGORY", id.toString(),
                translation("name", category.nameAr()), "APPROVED");
        return id;
    }

    private Optional<UUID> findCategoryBySlug(String code) {
        return jdbc.query("SELECT id FROM platform_categories WHERE code = ?",
                (rs, i) -> UUID.fromString(rs.getString(1)), code)
                .stream().findFirst();
    }

    // ------------------------------------------------------------------ items

    private UUID insertItem(ItemSeed item, UUID categoryId) {
        UUID itemId = UuidV7.generate();
        UUID versionId = UuidV7.generate();
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        jdbc.update("""
                INSERT INTO platform_items
                    (id, stable_code, category_id, status, current_published_version_id, sample_data,
                     sort_order, created_at, updated_at, version)
                VALUES (?, ?, ?, 'DRAFT', NULL, FALSE, ?, ?, ?, 0)
                """, itemId.toString(), item.code(), categoryId.toString(),
                item.sortOrder(), now, now);
        jdbc.update("""
                INSERT INTO platform_item_versions
                    (id, item_id, version_no, status, label, instruction,
                     standard_spec, measurement_unit, sensor_tool,
                     safety_critical, multi_point, max_tyre_age_years, allow_free_text_note,
                     result_options_json, severity_policy_json, applicability_json, reason_codes_json,
                     note_requirement, evidence_requirement, min_photos, equipment_ids_json,
                     guide_image_id, published_at, published_by, created_at, updated_at, version)
                VALUES (?, ?, 1, 'PUBLISHED', ?, ?, ?, ?, ?, ?, ?, ?, FALSE, ?, '{}', '{}',
                        '[]', 'OPTIONAL', 'REQUIRED_MIN_N', 1, '[]', NULL, ?, NULL, ?, ?, 0)
                """, versionId.toString(), itemId.toString(), item.nameEn(),
                item.instructionEn(), item.specEn(), item.unit(), item.tool(),
                item.safetyCritical(), item.multiPoint(), item.maxTyreAgeYears(),
                json(RESULTS), now, now, now);
        Map<String, Map<String, String>> overlays = new LinkedHashMap<>();
        putTranslation(overlays, "label", item.nameAr());
        putTranslation(overlays, "instruction", item.instructionAr());
        putTranslation(overlays, "standardSpec", item.specAr());
        translations.saveOverlays("ITEM", versionId.toString(), overlays, "APPROVED");
        jdbc.update("""
                UPDATE platform_items SET status = 'PUBLISHED', current_published_version_id = ?,
                    updated_at = CURRENT_TIMESTAMP, version = version + 1 WHERE id = ?
                """, versionId.toString(), itemId.toString());
        seedBandsAndRules(item, versionId.toString());
        seedMeasurementBands(item, versionId.toString());
        seedIssueFields(item, versionId.toString());
        return versionId;
    }

    private Optional<UUID> findItemByCode(String code) {
        return jdbc.query("SELECT id FROM platform_items WHERE stable_code = ?",
                (rs, i) -> UUID.fromString(rs.getString(1)), code)
                .stream().findFirst();
    }

    private Optional<UUID> findCurrentVersion(UUID itemId) {
        return jdbc.query("SELECT current_published_version_id FROM platform_items WHERE id = ?",
                (rs, i) -> {
                    String value = rs.getString(1);
                    return value == null ? null : UUID.fromString(value);
                }, itemId.toString()).stream().filter(v -> v != null).findFirst();
    }

    private void seedBandsAndRules(ItemSeed item, String versionId) {

        List<EvidenceRuleDto> rules = new ArrayList<>(List.of(
                new EvidenceRuleDto("NO_ISSUE_OBSERVED", 1, 1, 0, "PHOTO"),
                new EvidenceRuleDto("ATTENTION_RECOMMENDED", 1, 1, 15, "PHOTO"),
                new EvidenceRuleDto("DEFECT_FOUND", 2, 1, 15, "PHOTO")));
        if ("OBD-SCN-01".equals(item.code())) {
            rules = new ArrayList<>(List.of(
                    new EvidenceRuleDto("NO_ISSUE_OBSERVED", 1, 1, 0, "PHOTO"),
                    new EvidenceRuleDto("ATTENTION_RECOMMENDED", 1, 1, 15, "DOCUMENT"),
                    new EvidenceRuleDto("DEFECT_FOUND", 2, 1, 15, "DOCUMENT")));
        }
        itemConfig.replaceEvidenceRules(versionId, rules);
    }

    private void seedMeasurementBands(ItemSeed item, String versionId) {
        List<MeasurementBandDto> bands = measurementBands(item);
        if (!bands.isEmpty()) {
            ConfigValidators.validateMeasurementBands(bands);
            itemConfig.replaceMeasurementBands(versionId, bands);
        }
    }

    private List<MeasurementBandDto> measurementBands(ItemSeed item) {
        String unit = item.unit();
        if (unit == null) {
            return List.of();
        }
        return switch (item.code()) {
            case "BRK-PAD-01", "TYRE-SET-01" -> List.of(
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "0", "2.999", "DEFECT_FOUND", 0,
                            "Below minimum", "Ø£Ù‚Ù„ Ù…Ù† Ø§Ù„Ø­Ø¯ Ø§Ù„Ø£Ø¯Ù†Ù‰", 1),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "3.0", "5.499",
                            "ATTENTION_RECOMMENDED", 70, "Worn", "Ù…ØªØ¢ÙƒÙ„", 2),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "5.5", "99", "NO_ISSUE_OBSERVED",
                            100, "Within specification", "Ø¶Ù…Ù† Ø§Ù„Ù…ÙˆØ§ØµÙØ§Øª", 3));
            case "ELE-BAT-01" -> List.of(
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "0", "59", "DEFECT_FOUND", 0,
                            "Poor state of health", "Ø­Ø§Ù„Ø© ØµØ­ÙŠØ© Ø¶Ø¹ÙŠÙØ©", 1),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "60", "84",
                            "ATTENTION_RECOMMENDED", 70, "Moderate state of health", "Ø­Ø§Ù„Ø© ØµØ­ÙŠØ© Ù…ØªÙˆØ³Ø·Ø©", 2),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "85", "100", "NO_ISSUE_OBSERVED",
                            100, "Good state of health", "Ø­Ø§Ù„Ø© ØµØ­ÙŠØ© Ø¬ÙŠØ¯Ø©", 3));
            case "ELE-ALT-01" -> List.of(
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "0", "12.999", "DEFECT_FOUND", 0,
                            "Charging below specification", "Ø§Ù„Ø´Ø­Ù† Ø£Ù‚Ù„ Ù…Ù† Ø§Ù„Ù…ÙˆØ§ØµÙØ§Øª", 1),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "13", "13.799",
                            "ATTENTION_RECOMMENDED", 70, "Charging marginal", "Ø§Ù„Ø´Ø­Ù† Ø­Ø¯ÙŠ", 2),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "13.8", "15.2", "NO_ISSUE_OBSERVED",
                            100, "Charging within specification", "Ø§Ù„Ø´Ø­Ù† Ø¶Ù…Ù† Ø§Ù„Ù…ÙˆØ§ØµÙØ§Øª", 3),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "15.201", "99", "DEFECT_FOUND", 0,
                            "Overcharging", "Ø´Ø­Ù† Ø²Ø§Ø¦Ø¯", 4));
            case "INT-AC-01" -> List.of(
                    band("MEASUREMENT", unit, "LOWER_IS_BETTER", "0", "7", "NO_ISSUE_OBSERVED", 100,
                            "Cold air within specification", "Ù‡ÙˆØ§Ø¡ Ø¨Ø§Ø±Ø¯ Ø¶Ù…Ù† Ø§Ù„Ù…ÙˆØ§ØµÙØ§Øª", 1),
                    band("MEASUREMENT", unit, "LOWER_IS_BETTER", "7.001", "16",
                            "ATTENTION_RECOMMENDED", 70, "Cooling weak", "ØªØ¨Ø±ÙŠØ¯ Ø¶Ø¹ÙŠÙ", 2),
                    band("MEASUREMENT", unit, "LOWER_IS_BETTER", "16.001", "99", "DEFECT_FOUND", 0,
                            "Cooling failure", "ÙØ´Ù„ Ø§Ù„ØªØ¨Ø±ÙŠØ¯", 3));
            case "BRK-HYD-01" -> List.of(
                    band("MEASUREMENT", unit, "LOWER_IS_BETTER", "0", "1.999", "NO_ISSUE_OBSERVED",
                            100, "Moisture within specification", "Ø§Ù„Ø±Ø·ÙˆØ¨Ø© Ø¶Ù…Ù† Ø§Ù„Ù…ÙˆØ§ØµÙØ§Øª", 1),
                    band("MEASUREMENT", unit, "LOWER_IS_BETTER", "2", "3", "ATTENTION_RECOMMENDED",
                            70, "Moisture elevated", "Ø§Ø±ØªÙØ§Ø¹ Ø§Ù„Ø±Ø·ÙˆØ¨Ø©", 2),
                    band("MEASUREMENT", unit, "LOWER_IS_BETTER", "3.001", "100", "DEFECT_FOUND", 0,
                            "Moisture above limit", "Ø§Ù„Ø±Ø·ÙˆØ¨Ø© Ø£Ø¹Ù„Ù‰ Ù…Ù† Ø§Ù„Ø­Ø¯", 3));
            case "BOD-PNT-01" -> List.of(
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "0", "89.999", "DEFECT_FOUND", 0,
                            "Below factory paint range", "Ø£Ù‚Ù„ Ù…Ù† Ù†Ø·Ø§Ù‚ Ø¯Ù‡Ø§Ù† Ø§Ù„Ù…ØµÙ†Ø¹", 1),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "90", "149.999",
                            "NO_ISSUE_OBSERVED", 100, "Factory paint range", "Ù†Ø·Ø§Ù‚ Ø¯Ù‡Ø§Ù† Ø§Ù„Ù…ØµÙ†Ø¹", 2),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "150", "999", "DEFECT_FOUND", 0,
                            "Possible body repair or filler", "Ø§Ø­ØªÙ…Ø§Ù„ Ø¥ØµÙ„Ø§Ø­ Ø£Ùˆ Ù…Ø¹Ø¬ÙˆÙ† Ù‡ÙŠÙƒÙ„", 3));
            case "ROA-STR-01" -> List.of(
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "0", "649", "DEFECT_FOUND", 0,
                            "Idle below specification", "Ø¯ÙˆØ±Ø§Ù† Ø§Ù„Ø®Ù…ÙˆÙ„ Ø£Ù‚Ù„ Ù…Ù† Ø§Ù„Ù…ÙˆØ§ØµÙØ§Øª", 1),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "650", "750", "NO_ISSUE_OBSERVED",
                            100, "Idle within specification", "Ø¯ÙˆØ±Ø§Ù† Ø§Ù„Ø®Ù…ÙˆÙ„ Ø¶Ù…Ù† Ø§Ù„Ù…ÙˆØ§ØµÙØ§Øª", 2),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "750.001", "9999", "DEFECT_FOUND", 0,
                            "Idle above specification", "Ø¯ÙˆØ±Ø§Ù† Ø§Ù„Ø®Ù…ÙˆÙ„ Ø£Ø¹Ù„Ù‰ Ù…Ù† Ø§Ù„Ù…ÙˆØ§ØµÙØ§Øª", 3));
            case "BRK-ROT-01" -> List.of(
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "0", "20", "DEFECT_FOUND", 0,
                            "Below minimum thickness", "Ø£Ù‚Ù„ Ù…Ù† Ø§Ù„Ø­Ø¯ Ø§Ù„Ø£Ø¯Ù†Ù‰ Ù„Ù„Ø³Ù…Ø§ÙƒØ©", 1),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "20.001", "24.999",
                            "ATTENTION_RECOMMENDED", 70, "Worn rotor", "Ù‡ÙˆØ¨ Ù…ØªØ¢ÙƒÙ„", 2),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "25", "99", "NO_ISSUE_OBSERVED",
                            100, "Within specification", "Ø¶Ù…Ù† Ø§Ù„Ù…ÙˆØ§ØµÙØ§Øª", 3));
            default -> List.of(
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "0", "59", "DEFECT_FOUND", 0,
                            "Below specification", "Ø£Ù‚Ù„ Ù…Ù† Ø§Ù„Ù…ÙˆØ§ØµÙØ§Øª", 1),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "60", "84",
                            "ATTENTION_RECOMMENDED", 70, "Marginal", "Ø­Ø¯ÙŠ", 2),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "85", "100", "NO_ISSUE_OBSERVED",
                            100, "Within specification", "Ø¶Ù…Ù† Ø§Ù„Ù…ÙˆØ§ØµÙØ§Øª", 3));
        };
    }

    private MeasurementBandDto band(String field, String unit, String direction, String min,
                                    String max, String result, int score, String en, String ar,
                                    int order) {
        return new MeasurementBandDto(field, unit, direction, new BigDecimal(min),
                new BigDecimal(max), result, score, en, order, translation("label", ar), en, ar);
    }

    private void seedIssueFields(ItemSeed item, String versionId) {
        List<IssueFieldDto> fields = new ArrayList<>();
        boolean numeric = item.unit() != null;
        boolean multiPoint = item.multiPoint();
        fields.add(field(null, "ISSUE_TYPE", "Issue Type", "Ù†ÙˆØ¹ Ø§Ù„Ø¹Ø·Ù„",
                "SELECT", "ISSUE_TYPE", null, true,
                List.of("ATTENTION_RECOMMENDED", "DEFECT_FOUND"), null, null, 0, null, null,
                false, false, 1, List.of()));
        fields.add(field(null, "LOCATION", "Location", "Ø§Ù„Ù…ÙˆÙ‚Ø¹",
                multiPoint ? "MULTI_SELECT" : "SELECT", "LOCATION", null, true,
                List.of("ATTENTION_RECOMMENDED", "DEFECT_FOUND"), null, null, 0, null, null,
                multiPoint, false, 2, locationSubset(item)));
        if ("OBD-SCN-01".equals(item.code())) {
            fields.add(field(null, "DTC_COUNT", "DTC Count", "Ø¹Ø¯Ø¯ Ø±Ù…ÙˆØ² Ø§Ù„Ø£Ø¹Ø·Ø§Ù„",
                    "NUMBER", null, null, false, List.of("ATTENTION_RECOMMENDED", "DEFECT_FOUND"),
                    BigDecimal.ZERO, new BigDecimal("999"), 0, null, null, false, false, 3, List.of()));
            fields.add(field(null, "DTC_CODE", "DTC Code", "Ø±Ù…Ø² Ø§Ù„Ø¹Ø·Ù„",
                    "TEXT", null, null, false, List.of("ATTENTION_RECOMMENDED", "DEFECT_FOUND"),
                    null, null, 0, null, null, true, true, 4, List.of()));
        } else {
            fields.add(field(null, "COMPONENT", "Component", "Ø§Ù„Ø¬Ø²Ø¡",
                    "SELECT", "COMPONENT", null, false,
                    List.of("ATTENTION_RECOMMENDED", "DEFECT_FOUND"), null, null, 0,
                    "LOCATION", "FRONT_LEFT", false, false, 3, componentSubset(item)));
        }
        if (numeric) {
            fields.add(field(null, "MEASUREMENT", "Measured Value", "Ø§Ù„Ù‚ÙŠÙ…Ø© Ø§Ù„Ù…Ù‚Ø§Ø³Ø©",
                    "NUMBER", null, "UNIT", true, List.of(
                    "NO_ISSUE_OBSERVED", "ATTENTION_RECOMMENDED", "DEFECT_FOUND"),
                    BigDecimal.ZERO, new BigDecimal("9999"), 2, null, null, multiPoint, false, 4,
                    List.of(item.unit())));
        }
        fields.add(field(null, "SEVERITY", "Severity", "Ø§Ù„Ø®Ø·ÙˆØ±Ø©",
                "SELECT", "SEVERITY", null, true,
                List.of("ATTENTION_RECOMMENDED", "DEFECT_FOUND"), null, null, 0,
                null, null, false, false, 5, List.of()));
        fields.add(field(null, "ACTION", "Recommended Action", "Ø§Ù„Ø¥Ø¬Ø±Ø§Ø¡ Ø§Ù„Ù…ÙˆØµÙ‰ Ø¨Ù‡",
                "SELECT", "ACTION", null, true,
                List.of("ATTENTION_RECOMMENDED", "DEFECT_FOUND"), null, null, 0,
                "SEVERITY", "MODERATE", false, false, 6, List.of()));
        fields.add(field(null, "URGENCY", "Urgency", "Ø§Ù„Ø£ÙˆÙ„ÙˆÙŠØ©",
                "SELECT", "URGENCY", null, true,
                List.of("ATTENTION_RECOMMENDED", "DEFECT_FOUND"), null, null, 0,
                "SEVERITY", "MODERATE", false, false, 7, List.of()));
        itemConfig.replaceIssueFields(versionId, fields);
    }

    private IssueFieldDto field(String id, String fieldCode, String label, String labelAr,
                                String inputType, String optionSet, String unitSet, boolean required,
                                List<String> statuses, BigDecimal min, BigDecimal max, int decimals,
                                String dependsField, String dependsValue, boolean multiple,
                                boolean freeText, int sortOrder, List<String> allowed) {
        return new IssueFieldDto(id, fieldCode, label, inputType, optionSet, unitSet, required,
                statuses, min, max, decimals, dependsField, dependsValue, multiple, freeText,
                sortOrder, allowed, translation("label", labelAr), label, labelAr);
    }

    private Map<String, Map<String, String>> translation(String field, String ar) {
        if (ar == null || ar.isBlank()) {
            return Map.of();
        }
        Map<String, String> values = new LinkedHashMap<>();
        values.put("ar", ar.trim());
        Map<String, Map<String, String>> result = new LinkedHashMap<>();
        result.put(field, values);
        return result;
    }

    private void putTranslation(Map<String, Map<String, String>> target, String field, String ar) {
        if (ar != null && !ar.isBlank()) {
            target.computeIfAbsent(field, ignored -> new LinkedHashMap<>()).put("ar", ar.trim());
        }
    }
    private List<String> locationSubset(ItemSeed item) {
        if ("BRK-PAD-01".equals(item.code()) || "TYRE-SET-01".equals(item.code())) {
            return List.of("FRONT_LEFT", "FRONT_RIGHT", "REAR_LEFT", "REAR_RIGHT");
        }
        return List.of();
    }

    private List<String> componentSubset(ItemSeed item) {
        if ("BRK-PAD-01".equals(item.code())) {
            return List.of("PAD", "ROTOR", "CALIPER", "HOSE", "FLUID");
        }
        return List.of();
    }

    // ------------------------------------------------------- document types

    private boolean ensureDocumentType(DocumentTypeSeed type) {
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM platform_document_types WHERE code = ?", Integer.class, type.code());
        if (count != null && count > 0) {
            return false;
        }
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_document_types
                    (id, code, name, status, is_required, sort_order,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, 'ACTIVE', TRUE, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, id, type.code(), type.nameEn(), type.sortOrder());
        translations.saveOverlays("DOCUMENT_TYPE", id, translation("name", type.nameAr()),
                "APPROVED");
        return true;
    }

    // --------------------------------------------------------------- template

    private boolean ensureDefaultTemplate(Map<String, UUID> versionByCode,
                                         Map<String, UUID> categoryIds) {
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM platform_templates WHERE code = 'TPL-30-GCC'", Integer.class);
        if (count != null && count > 0) {
            return false;
        }
        String templateId = UuidV7.generate().toString();
        String versionId = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_templates
                    (id, code, name, description, status,
                     current_published_version_id, created_at, updated_at, version)
                VALUES (?, 'TPL-30-GCC', 'Comprehensive 30-Point GCC Standard',
                        'Full 6-category, 30-item inspection package.',
                        'ACTIVE', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, templateId);
        Map<String, Map<String, String>> templateOverlays = new LinkedHashMap<>();
        putTranslation(templateOverlays, "name",
                "فحص شامل 30 نقطة وفق معايير المحيط الخليجي");
        putTranslation(templateOverlays, "description",
                "حزمة فحص كاملة من 6 فئات و30 عنصرًا.");
        translations.saveOverlays("TEMPLATE", templateId, templateOverlays, "APPROVED");
        jdbc.update("""
                INSERT INTO platform_template_versions
                    (id, template_id, version_no, status, published_at, published_by,
                     created_at, updated_at)
                VALUES (?, ?, 1, 'PUBLISHED', CURRENT_TIMESTAMP, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, versionId, templateId);
        jdbc.update("""
                UPDATE platform_templates SET current_published_version_id = ?,
                    updated_at = CURRENT_TIMESTAMP, version = version + 1 WHERE id = ?
                """, versionId, templateId);
        int categoryOrder = 1;
        for (CategorySeed category : categories()) {
            UUID categoryId = categoryIds.get(category.code());
            if (categoryId == null) {
                continue;
            }
            jdbc.update("""
                    INSERT INTO platform_template_categories
                        (id, template_version_id, category_id, sort_order, included)
                    VALUES (?, ?, ?, ?, TRUE)
                    """, UuidV7.generate().toString(), versionId, categoryId.toString(), categoryOrder++);
            int itemOrder = 1;
            for (ItemSeed item : items()) {
                if (!item.categoryCode().equals(category.code())) {
                    continue;
                }
                UUID itemVersionId = versionByCode.get(item.code());
                if (itemVersionId == null) {
                    continue;
                }
                jdbc.update("""
                        INSERT INTO platform_template_items
                            (id, template_version_id, item_version_id, category_id, sort_order, included)
                        VALUES (?, ?, ?, ?, ?, TRUE)
                        """, UuidV7.generate().toString(), versionId, itemVersionId.toString(),
                        categoryId.toString(), itemOrder++);
            }
        }
        return true;
    }

    // ------------------------------------------------------------------ json

    private String json(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception ex) {
            return "[]";
        }
    }

    // ------------------------------------------------------------ seed data

    private record CategorySeed(String code, String nameEn, String nameAr, int sortOrder) {
    }

    private record ItemSeed(String code, String categoryCode, String nameEn, String nameAr,
                            String tool, String unit, String specEn, String specAr,
                            boolean safetyCritical, boolean multiPoint, Integer maxTyreAgeYears,
                            int sortOrder) {
        String instructionEn() {
            return "Inspect " + nameEn + " and record the condition with evidence.";
        }

        String instructionAr() {
            return "Ø§ÙØ­Øµ " + nameAr + " ÙˆØ³Ø¬Ù‘Ù„ Ø§Ù„Ø­Ø§Ù„Ø© Ù…Ø¹ Ø§Ù„Ø£Ø¯Ù„Ø©.";
        }
    }

    private record OptionSetDefinition(String code, String nameEn, String nameAr, int sortOrder,
                                       List<OptionValueSeed> values) {
    }

    private record OptionValueSeed(String code, String en, String ar) {
    }

    private record DocumentTypeSeed(String code, String nameEn, String nameAr, int sortOrder) {
    }

    private List<CategorySeed> categories() {
        return List.of(
                new CategorySeed("CAT-ENG", "Powertrain & Mechanical", "Ù…Ø¬Ù…ÙˆØ¹Ø© Ø§Ù„Ø­Ø±ÙƒØ© ÙˆØ§Ù„Ù…ÙŠÙƒØ§Ù†ÙŠÙƒØ§", 1),
                new CategorySeed("CAT-SUS", "Suspension, Steering & Underbody",
                        "Ø§Ù„ØªØ¹Ù„ÙŠÙ‚ ÙˆØ§Ù„ØªÙˆØ¬ÙŠÙ‡ ÙˆØ£Ø³ÙÙ„ Ø§Ù„Ù‡ÙŠÙƒÙ„", 2),
                new CategorySeed("CAT-BRK", "Braking Systems & Tyres", "Ø£Ù†Ø¸Ù…Ø© Ø§Ù„ÙØ±Ø§Ù…Ù„ ÙˆØ§Ù„Ø¥Ø·Ø§Ø±Ø§Øª", 3),
                new CategorySeed("CAT-ELE", "Electrical, Battery & Diagnostics",
                        "Ø§Ù„ÙƒÙ‡Ø±Ø¨Ø§Ø¡ ÙˆØ§Ù„Ø¨Ø·Ø§Ø±ÙŠØ© ÙˆØ§Ù„ØªØ´Ø®ÙŠØµ", 4),
                new CategorySeed("CAT-BOD", "Body, Glass & Interior", "Ø§Ù„Ù‡ÙŠÙƒÙ„ ÙˆØ§Ù„Ø²Ø¬Ø§Ø¬ ÙˆØ§Ù„Ù…Ù‚ØµÙˆØ±Ø©", 5),
                new CategorySeed("CAT-ROA", "Road Test & Dynamic Performance",
                        "Ø§Ø®ØªØ¨Ø§Ø± Ø§Ù„Ø·Ø±ÙŠÙ‚ ÙˆØ§Ù„Ø£Ø¯Ø§Ø¡ Ø§Ù„Ø¯ÙŠÙ†Ø§Ù…ÙŠÙƒÙŠ", 6));
    }

    private List<ItemSeed> items() {
        return List.of(
                item("ENG-OIL-01", "CAT-ENG", "Engine Oil Condition & Level", "Ø­Ø§Ù„Ø© ÙˆÙ…Ø³ØªÙˆÙ‰ Ø²ÙŠØª Ø§Ù„Ù…Ø­Ø±Ùƒ",
                        "Optical Refractometer / Dipstick", null,
                        "Oil level between MIN/MAX; amber/brown colour; normal viscosity.",
                        "Ù…Ø³ØªÙˆÙ‰ Ø§Ù„Ø²ÙŠØª Ø¨ÙŠÙ† Ø§Ù„Ø­Ø¯ Ø§Ù„Ø£Ø¯Ù†Ù‰ ÙˆØ§Ù„Ø£Ù‚ØµÙ‰Ø› Ù„ÙˆÙ† ÙƒÙ‡Ø±Ù…Ø§Ù†ÙŠØ› Ù„Ø²ÙˆØ¬Ø© Ø·Ø¨ÙŠØ¹ÙŠØ©.", false, false, null, 1),
                item("ENG-FLT-01", "CAT-ENG", "Engine Air Filter & Intake System",
                        "ÙÙ„ØªØ± Ù‡ÙˆØ§Ø¡ Ø§Ù„Ù…Ø­Ø±Ùƒ ÙˆÙ†Ø¸Ø§Ù… Ø§Ù„Ø³Ø­Ø¨", "Visual / Airflow Gauge", null,
                        "Clean filter pleats; intact housing seals; clean MAF housing.",
                        "Ø·ÙŠØ§Øª ÙÙ„ØªØ± Ù†Ø¸ÙŠÙØ©Ø› Ø¹ÙˆØ§Ø²Ù„ Ø§Ù„Ø³ÙƒÙ† Ø³Ù„ÙŠÙ…Ø©Ø› Ø­Ø³Ø§Ø³ Ù‡ÙˆØ§Ø¡ Ù†Ø¸ÙŠÙ.", false, false, null, 2),
                item("TRN-FLU-01", "CAT-ENG", "Transmission Fluid & Drivetrain Health",
                        "Ø³Ø§Ø¦Ù„ Ù†Ø§Ù‚Ù„ Ø§Ù„Ø­Ø±ÙƒØ© ÙˆÙ†Ø¸Ø§Ù… Ø§Ù„Ø¯ÙØ¹", "Dipstick / Sight Tube", null,
                        "Pink/red or clear fluid; no burnt odour; no gear shudder.",
                        "Ø³Ø§Ø¦Ù„ ÙˆØ±Ø¯ÙŠ Ø£Ùˆ Ø£Ø­Ù…Ø± Ø£Ùˆ ØµØ§ÙÙØ› Ø¨Ù„Ø§ Ø±Ø§Ø¦Ø­Ø© Ø§Ø­ØªØ±Ø§Ù‚Ø› Ø¨Ù„Ø§ Ø§Ù‡ØªØ²Ø§Ø².", false, false, null, 3),
                item("ENG-CLT-01", "CAT-ENG", "Cooling System, Radiator & Hoses",
                        "Ù†Ø¸Ø§Ù… Ø§Ù„ØªØ¨Ø±ÙŠØ¯ ÙˆØ§Ù„Ø±Ø§Ø¯ÙŠØ§ØªÙŠØ± ÙˆØ§Ù„Ø®Ø±Ø§Ø·ÙŠÙ…", "Pressure Tester (15 psi)", null,
                        "Holds 15 psi for 5 minutes; clean coolant; flexible hoses.",
                        "ÙŠØ­Ø§ÙØ¸ Ø¹Ù„Ù‰ 15 Ø±Ø·Ù„ Ù„Ù…Ø¯Ø© 5 Ø¯Ù‚Ø§Ø¦Ù‚Ø› Ø³Ø§Ø¦Ù„ Ù†Ø¸ÙŠÙØ› Ø®Ø±Ø§Ø·ÙŠÙ… Ù…Ø±Ù†Ø©.", true, false, null, 4),
                item("ENG-BEL-01", "CAT-ENG", "Drive Belts, Pulleys & Tensioners",
                        "Ø³ÙŠÙˆØ± Ø§Ù„Ù…Ø­Ø±Ùƒ ÙˆØ§Ù„Ø¨ÙƒØ±Ø§Øª ÙˆØ§Ù„Ø´Ø¯Ø§Ø¯Ø§Øª", "Belt Wear Gauge & Stethoscope", null,
                        "No cracks; no pulley chirp; tensioner aligned.",
                        "Ø¨Ù„Ø§ ØªØ´Ù‚Ù‚Ø§ØªØ› Ø¨Ù„Ø§ ØµØ±ÙŠØ±Ø› Ø§Ù„Ø´Ø¯Ø§Ø¯ Ù…Ø³ØªÙˆÙŠ.", false, false, null, 5),
                item("ENG-EXH-01", "CAT-ENG", "Exhaust System, Catalytic Converter & Emissions",
                        "Ù†Ø¸Ø§Ù… Ø§Ù„Ø¹Ø§Ø¯Ù… ÙˆØ§Ù„Ù…Ø­ÙˆÙ„ Ø§Ù„Ø­ÙØ§Ø² ÙˆØ§Ù„Ø§Ù†Ø¨Ø¹Ø§Ø«Ø§Øª", "Thermal Gun", null,
                        "No exhaust leaks; catalyst delta temperature above 50 C.",
                        "Ø¨Ù„Ø§ ØªØ³Ø±ÙŠØ¨Ø§Øª Ø¹Ø§Ø¯Ù…Ø› ÙØ±Ù‚ Ø­Ø±Ø§Ø±Ø© Ø§Ù„Ù…Ø­ÙˆÙ„ Ø£ÙƒØ¨Ø± Ù…Ù† 50 Ø¯Ø±Ø¬Ø©.", false, false, null, 6),
                item("SUS-FRT-01", "CAT-SUS", "Front Shocks, Struts & Springs",
                        "Ø§Ù„Ù…Ø³Ø§Ø¹Ø¯Ø§Øª Ø§Ù„Ø£Ù…Ø§Ù…ÙŠØ© ÙˆØ§Ù„ÙŠØ§ÙŠØ§Øª", "Pry Bar & Bounce Tester", null,
                        "No hydraulic weeping; rebound dampens in 1.5 cycles; unbroken coil.",
                        "Ø¨Ù„Ø§ ØªØ³Ø±ÙŠØ¨ Ù‡ÙŠØ¯Ø±ÙˆÙ„ÙŠÙƒÙŠØ› Ø§Ø±ØªØ¯Ø§Ø¯ Ù…Ø®Ù…Ø¯Ø› ÙŠØ§ÙŠØ§Øª Ø³Ù„ÙŠÙ…Ø©.", true, false, null, 7),
                item("SUS-REA-01", "CAT-SUS", "Rear Dampers & Linkages",
                        "Ø§Ù„Ù…Ø³Ø§Ø¹Ø¯Ø§Øª Ø§Ù„Ø®Ù„ÙÙŠØ© ÙˆØ§Ù„ÙˆØµÙ„Ø§Øª", "Pry Bar & Visual Check", null,
                        "Bushings intact; no clunking; symmetrical ride height.",
                        "Ø¬Ù„ÙˆØ¯ Ø³Ù„ÙŠÙ…Ø©Ø› Ø¨Ù„Ø§ Ø·Ù‚Ø·Ù‚Ø©Ø› Ø§Ø±ØªÙØ§Ø¹ Ù…ØªØ³Ø§ÙˆÙ.", true, false, null, 8),
                item("STR-RCK-01", "CAT-SUS", "Steering Rack, Tie Rods & Boots",
                        "Ø¹Ù„Ø¨Ø© Ø§Ù„Ø¯Ø±ÙƒØ³ÙˆÙ† ÙˆÙ…Ø³Ø§Ù…ÙŠØ± Ø§Ù„ØªÙˆØ¬ÙŠÙ‡", "Dial Indicator & Play Check", null,
                        "Tie rod play below 0.5 mm; boots sealed; power assist normal.",
                        "Ø®Ù„ÙˆØµ Ø£Ù‚Ù„ Ù…Ù† 0.5 Ù…Ù…Ø› Ø£ØºØ·ÙŠØ© Ø³Ù„ÙŠÙ…Ø©Ø› Ù…Ø³Ø§Ø¹Ø¯Ø© ØªÙˆØ¬ÙŠÙ‡ Ø·Ø¨ÙŠØ¹ÙŠØ©.", true, false, null, 9),
                item("SUS-CTL-01", "CAT-SUS", "Control Arms & Ball Joints",
                        "Ø£Ø°Ø±Ø¹Ø© Ø§Ù„ØªØ­ÙƒÙ… ÙˆØ§Ù„Ø±ÙƒØ¨", "Ball Joint Gauge & Pry Bar", null,
                        "Joint play below 1.0 mm; rubber boots intact.",
                        "Ø®Ù„ÙˆØµ Ø§Ù„Ù…ÙØµÙ„ Ø£Ù‚Ù„ Ù…Ù† 1 Ù…Ù…Ø› Ø£ØºØ·ÙŠØ© Ù…Ø·Ø§Ø·ÙŠØ© Ø³Ù„ÙŠÙ…Ø©.", true, false, null, 10),
                item("BOD-UND-01", "CAT-SUS", "Chassis Rails, Subframe & Floor Pan",
                        "Ø´Ø§Ø³ÙŠÙ‡ Ø§Ù„Ø³ÙŠØ§Ø±Ø© ÙˆØ§Ù„Ù‡ÙŠÙƒÙ„ Ø§Ù„Ø³ÙÙ„ÙŠ", "High-Lumen Inspection", null,
                        "Zero structural deformation; no frame straightening marks.",
                        "Ù„Ø§ ÙŠÙˆØ¬Ø¯ ØªØ´ÙˆÙ‡ Ù‡ÙŠÙƒÙ„ÙŠØ› Ø¨Ù„Ø§ Ø¢Ø«Ø§Ø± ØªÙ‚ÙˆÙŠÙ… Ø´Ø§Ø³ÙŠÙ‡.", true, false, null, 11),
                item("BRK-PAD-01", "CAT-BRK", "Brake Pad Thickness (All 4 Corners)",
                        "Ø³Ù…Ùƒ Ø£Ù‚Ù…Ø´Ø© Ø§Ù„ÙØ±Ø§Ù…Ù„ (Ø¬Ù…ÙŠØ¹ Ø§Ù„Ø¹Ø¬Ù„Ø§Øª)", "Digital Vernier Brake Gauge", "MM",
                        "Friction material above 3.0 mm (above 25% remaining).",
                        "Ø³Ù…Ø§ÙƒØ© Ø§Ù„ØªÙŠÙ„ Ø£Ø¹Ù„Ù‰ Ù…Ù† 3.0 Ù…Ù… (Ø£ÙƒØ«Ø± Ù…Ù† 25% Ù…ØªØ¨Ù‚Ù).", true, true, null, 12),
                item("BRK-ROT-01", "CAT-BRK", "Brake Disc Rotors & Runout",
                        "Ù‡ÙˆØ¨Ø§Øª Ø§Ù„ÙØ±Ø§Ù…Ù„ ÙˆÙ†Ø³Ø¨Ø© Ø§Ù„Ø§Ø³ØªÙˆØ§Ø¡", "Micrometer & Dial Indicator", "MM",
                        "Above minimum thickness; lateral runout below 0.05 mm.",
                        "Ø£Ø¹Ù„Ù‰ Ù…Ù† Ø§Ù„Ø­Ø¯ Ø§Ù„Ø£Ø¯Ù†Ù‰ Ù„Ù„Ø³Ù…Ø§ÙƒØ©Ø› Ø§Ù†Ø­Ø±Ø§Ù Ø£Ù‚Ù„ Ù…Ù† 0.05 Ù…Ù….", true, false, null, 13),
                item("BRK-HYD-01", "CAT-BRK", "Brake Fluid Moisture & Hydraulic Lines",
                        "Ø³Ø§Ø¦Ù„ Ø§Ù„ÙØ±Ø§Ù…Ù„ ÙˆÙ†Ø¸Ø§Ù… Ø§Ù„Ù„ÙŠØ§Øª", "Digital Moisture Pen", "PERCENT",
                        "Fluid moisture below 2.0%; steel lines free of rust.",
                        "Ø±Ø·ÙˆØ¨Ø© Ø§Ù„Ø³Ø§Ø¦Ù„ Ø£Ù‚Ù„ Ù…Ù† 2.0%Ø› Ø®Ø·ÙˆØ· ÙÙˆÙ„Ø§Ø°ÙŠØ© Ø¨Ù„Ø§ ØµØ¯Ø£.", true, false, null, 14),
                item("TYRE-SET-01", "CAT-BRK", "Tyre Tread Depth (FL, FR, RL, RR)",
                        "Ø¹Ù…Ù‚ Ù…Ø¯Ø§Ø³ Ø§Ù„Ø¥Ø·Ø§Ø±Ø§Øª (Ø§Ù„Ø£Ø±Ø¨Ø¹Ø©)", "Digital Tread Depth Gauge", "MM",
                        "Legal minimum above 1.6 mm; recommended replacement below 3.0 mm.",
                        "Ø§Ù„Ø­Ø¯ Ø§Ù„Ù‚Ø§Ù†ÙˆÙ†ÙŠ Ø£Ø¹Ù„Ù‰ Ù…Ù† 1.6 Ù…Ù…Ø› ÙŠÙˆØµÙ‰ Ø¨Ø§Ù„Ø§Ø³ØªØ¨Ø¯Ø§Ù„ ØªØ­Øª 3.0 Ù…Ù….", true, true, null, 15),
                item("TYRE-CND-01", "CAT-BRK", "Tyre Age (DOT), Sidewall & Structural Integrity",
                        "Ø¹Ù…Ø± Ø§Ù„Ø¥Ø·Ø§Ø±Ø§Øª ÙˆØ§Ù„Ù‡ÙŠÙƒÙ„ Ø§Ù„Ø®Ø§Ø±Ø¬ÙŠ", "Visual DOT Inspection", null,
                        "Age below 5 years (GCC strict below 2 years); zero sidewall bulges.",
                        "Ø§Ù„Ø¹Ù…Ø± Ø£Ù‚Ù„ Ù…Ù† 5 Ø³Ù†ÙˆØ§Øª (Ø§Ù„Ù…Ø¹ÙŠØ§Ø± Ø§Ù„Ø®Ù„ÙŠØ¬ÙŠ Ø£Ù‚Ù„ Ù…Ù† Ø³Ù†ØªÙŠÙ†)Ø› Ø¨Ù„Ø§ Ø§Ù†ØªÙØ§Ø®Ø§Øª.", true, false, 2, 16),
                item("ELE-BAT-01", "CAT-ELE", "Battery Health & CCA", "ÙØ­Øµ Ø§Ù„Ø¨Ø·Ø§Ø±ÙŠØ© ÙˆØ§Ù„ØµØ­Ø© ÙˆØ§Ù„Ù‚Ø¯Ø±Ø©",
                        "Digital Conductance Analyzer", "PERCENT",
                        "State of health at least 80%; resting voltage at least 12.6 V.",
                        "ØµØ­Ø© Ø§Ù„Ø¨Ø·Ø§Ø±ÙŠØ© 80% Ø¹Ù„Ù‰ Ø§Ù„Ø£Ù‚Ù„Ø› Ø¬Ù‡Ø¯ Ø§Ù„Ø³ÙƒÙˆÙ† 12.6 ÙÙˆÙ„Øª Ø¹Ù„Ù‰ Ø§Ù„Ø£Ù‚Ù„.", true, false, null, 17),
                item("ELE-ALT-01", "CAT-ELE", "Alternator Charging Voltage & Diode Ripple",
                        "Ø¬Ù‡Ø¯ Ø´Ø­Ù† Ø§Ù„Ø¯ÙŠÙ†Ø§Ù…Ùˆ ÙˆØ§Ø®ØªØ¨Ø§Ø± Ø§Ù„Ø±ÙŠØ¨Ù„", "Digital Multimeter", "V",
                        "Idle charging 13.8-14.5 V; ripple below 0.5 V.",
                        "Ø´Ø­Ù† Ø§Ù„Ø®Ù…ÙˆÙ„ 13.8-14.5 ÙÙˆÙ„ØªØ› ØªÙ…ÙˆØ¬ Ø£Ù‚Ù„ Ù…Ù† 0.5 ÙÙˆÙ„Øª.", true, false, null, 18),
                item("OBD-SCN-01", "CAT-ELE", "Diagnostic Trouble Codes (OBD-II Full Scan)",
                        "ÙØ­Øµ ÙƒÙ…Ø¨ÙŠÙˆØªØ± Ø§Ù„Ø³ÙŠØ§Ø±Ø© ÙˆØ£Ø¹Ø·Ø§Ù„ Ø§Ù„Ù…Ø­Ø±Ùƒ", "Professional OBD-II Scanner", null,
                        "Zero active or pending powertrain DTCs.",
                        "Ù„Ø§ ØªÙˆØ¬Ø¯ Ø±Ù…ÙˆØ² Ø£Ø¹Ø·Ø§Ù„ Ù†Ø´Ø·Ø© Ø£Ùˆ Ù…Ø¹Ù„Ù‚Ø© ÙÙŠ Ù…Ø¬Ù…ÙˆØ¹Ø© Ø§Ù„Ø­Ø±ÙƒØ©.", false, false, null, 19),
                item("ELE-LGT-01", "CAT-ELE", "Exterior & Interior Lighting Systems",
                        "Ø§Ù„Ø¥Ø¶Ø§Ø¡Ø© Ø§Ù„Ø®Ø§Ø±Ø¬ÙŠØ© ÙˆØ§Ù„Ø¯Ø§Ø®Ù„ÙŠØ©", "Visual & Lux Meter", null,
                        "All lights function; correct beam aiming; clear lenses.",
                        "Ø¬Ù…ÙŠØ¹ Ø§Ù„Ø£Ø¶ÙˆØ§Ø¡ ØªØ¹Ù…Ù„Ø› ØªÙˆØ¬ÙŠÙ‡ ØµØ­ÙŠØ­Ø› Ø¹Ø¯Ø³Ø§Øª ÙˆØ§Ø¶Ø­Ø©.", false, false, null, 20),
                item("ELE-INF-01", "CAT-ELE", "Infotainment, Cameras, Radar & ADAS Sensors",
                        "Ø§Ù„Ø´Ø§Ø´Ø§Øª ÙˆØ§Ù„ÙƒØ§Ù…ÙŠØ±Ø§Øª ÙˆØ­Ø³Ø§Ø³Ø§Øª Ø§Ù„Ø±Ø§Ø¯Ø§Ø±", "Functional Testing", null,
                        "360 camera active; parking sensors trigger; touchscreen responsive.",
                        "ÙƒØ§Ù…ÙŠØ±Ø§ Ù…Ø­ÙŠØ·ÙŠØ© ØªØ¹Ù…Ù„Ø› Ø­Ø³Ø§Ø³Ø§Øª Ø±ÙƒÙ† ØªØ¹Ù…Ù„Ø› Ø´Ø§Ø´Ø© ØªØ³ØªØ¬ÙŠØ¨.", false, false, null, 21),
                item("BOD-PNT-01", "CAT-BOD", "Paint Thickness & Body Panel Integrity",
                        "Ø³Ù…Ø§ÙƒØ© Ø¯Ù‡Ø§Ù† Ø§Ù„Ù‡ÙŠÙƒÙ„ ÙˆØ³Ù„Ø§Ù…Ø© Ø§Ù„Ø£Ù„ÙˆØ§Ø­", "Coating Thickness Gauge", "UM",
                        "Factory paint 90-150 um; uniform readings across panels.",
                        "Ø¯Ù‡Ø§Ù† Ø§Ù„Ù…ØµÙ†Ø¹ 90-150 Ù…ÙŠÙƒØ±ÙˆÙ…ØªØ±Ø› Ù‚Ø±Ø§Ø¡Ø§Øª Ù…ØªØ³Ø§ÙˆÙŠØ©.", false, false, null, 22),
                item("BOD-GLS-01", "CAT-BOD", "Windshield, Windows & Mirror Glass",
                        "Ø§Ù„Ø²Ø¬Ø§Ø¬ Ø§Ù„Ø£Ù…Ø§Ù…ÙŠ ÙˆØ§Ù„Ù†ÙˆØ§ÙØ° ÙˆØ§Ù„Ù…Ø±Ø§ÙŠØ§", "Defroster Grid Tester", null,
                        "Zero cracks in driver line of sight; OEM glass stamps match.",
                        "Ø¨Ù„Ø§ Ø´Ù‚ÙˆÙ‚ ÙÙŠ Ø®Ø· Ù†Ø¸Ø± Ø§Ù„Ø³Ø§Ø¦Ù‚Ø› Ù…Ø·Ø§Ø¨Ù‚Ø© Ø£Ø®ØªØ§Ù… Ø§Ù„Ù…ØµÙ†Ø¹.", false, false, null, 23),
                item("INT-AC-01", "CAT-BOD", "Air Conditioning & Climate Performance",
                        "Ø£Ø¯Ø§Ø¡ Ù†Ø¸Ø§Ù… Ø§Ù„ØªÙƒÙŠÙŠÙ ÙˆØ§Ù„ØªØ­ÙƒÙ… Ø¨Ø§Ù„Ù…Ù†Ø§Ø®", "Digital Thermocouple", "DEG_C",
                        "Vent temperature at most 7 C after five minutes.",
                        "Ø­Ø±Ø§Ø±Ø© Ø§Ù„ÙØªØ­Ø© 7 Ø¯Ø±Ø¬Ø§Øª Ù…Ø¦ÙˆÙŠØ© ÙƒØ­Ø¯ Ø£Ù‚ØµÙ‰ Ø¨Ø¹Ø¯ Ø®Ù…Ø³ Ø¯Ù‚Ø§Ø¦Ù‚.", false, false, null, 24),
                item("INT-SFT-01", "CAT-BOD", "Seat Belts, Airbags & Restraint Systems",
                        "Ø£Ø­Ø²Ù…Ø© Ø§Ù„Ø£Ù…Ø§Ù† ÙˆØ§Ù„ÙˆØ³Ø§Ø¦Ø¯ Ø§Ù„Ù‡ÙˆØ§Ø¦ÙŠØ©", "Belt Retraction Tester", null,
                        "Belts lock on yank; pretensioners active; airbag covers uncut.",
                        "Ø§Ù„Ø£Ø­Ø²Ù…Ø© ØªÙ‚ÙÙ„ Ø¹Ù†Ø¯ Ø§Ù„Ø³Ø­Ø¨Ø› Ø§Ù„Ø´Ø¯Ø§Ø¯Ø§Øª ØªØ¹Ù…Ù„Ø› Ø£ØºØ·ÙŠØ© Ø§Ù„ÙˆØ³Ø§Ø¦Ø¯ Ø³Ù„ÙŠÙ…Ø©.", true, false, null, 25),
                item("INT-ROF-01", "CAT-BOD", "Sunroof, Weatherstripping & Cabin Seals",
                        "ÙØªØ­Ø© Ø§Ù„Ø³Ù‚Ù ÙˆØ§Ù„Ø¹ÙˆØ§Ø²Ù„ Ø§Ù„Ù…Ø·Ø§Ø·ÙŠØ© Ù„Ù„ÙƒØ¨ÙŠÙ†Ø©", "Water Spray Test", null,
                        "Seals supple; drains unclogged; sunroof glides smoothly.",
                        "Ø¹ÙˆØ§Ø²Ù„ Ù…Ø±Ù†Ø©Ø› Ù…ØµØ§Ø±Ù Ù…ÙØªÙˆØ­Ø©Ø› ÙØªØ­Ø© Ø³Ù‚Ù ØªÙ†Ø²Ù„Ù‚ Ø¨Ø³Ù„Ø§Ø³Ø©.", false, false, null, 26),
                item("ROA-STR-01", "CAT-ROA", "Cold Start, Cranking & Idle Smoothness",
                        "Ø§Ù„ØªØ´ØºÙŠÙ„ Ø¹Ù„Ù‰ Ø§Ù„Ø¨Ø§Ø±Ø¯ ÙˆØ§Ù†ØªØ¸Ø§Ù… Ø¯ÙˆØ±Ø§Ù† Ø§Ù„Ù…Ø­Ø±Ùƒ", "Engine RPM Log", "RPM",
                        "Quick start; smooth idle 650-750 RPM; no smoke.",
                        "ØªØ´ØºÙŠÙ„ Ø³Ø±ÙŠØ¹Ø› Ø®Ù…ÙˆÙ„ Ù…Ù†ØªØ¸Ù… 650-750 Ø¯ÙˆØ±Ø©Ø› Ø¨Ù„Ø§ Ø¯Ø®Ø§Ù†.", false, false, null, 27),
                item("ROA-TRN-01", "CAT-ROA", "Transmission Shift Quality & Clutch Engagement",
                        "Ø³Ù„Ø§Ø³Ø© ØªØ¨Ø¯ÙŠÙ„Ø§Øª Ø§Ù„Ù‚ÙŠØ± ÙˆØ§Ø³ØªØ¬Ø§Ø¨Ø© Ø§Ù„ÙƒÙ„ØªØ´", "Road Acceleration Test", null,
                        "Smooth upshifts and downshifts; no flare; instant torque.",
                        "ØªØ¨Ø¯ÙŠÙ„Ø§Øª Ø³Ù„Ø³Ø©Ø› Ø¨Ù„Ø§ ØªØ³Ø§Ø±Ø¹ ÙØ§Ø±ØºØ› Ø¹Ø²Ù… ÙÙˆØ±ÙŠ.", false, false, null, 28),
                item("ROA-ALN-01", "CAT-ROA", "Steering Centering, Tracking & Drift",
                        "Ø§Ø³ØªÙ‚Ø§Ù…Ø© Ø§Ù„Ù…Ù‚ÙˆØ¯ ÙˆØ«Ø¨Ø§Øª Ø§Ù„Ù…Ø³Ø§Ø±", "Road Test at 80 km/h", null,
                        "Tracks straight for 100 m; steering wheel level.",
                        "ÙŠØ³ÙŠØ± Ù…Ø³ØªÙ‚ÙŠÙ…Ø§Ù‹ 100 Ù…ØªØ±Ø› Ø§Ù„Ù…Ù‚ÙˆØ¯ Ù…Ø³ØªÙˆÙ.", false, false, null, 29),
                item("ROA-BRK-01", "CAT-ROA", "Dynamic Emergency Braking & ABS Cycling",
                        "Ø§Ù„ÙØ±Ù…Ù„Ø© Ø§Ù„Ø·Ø§Ø±Ø¦Ø© ÙˆØªÙØ¹ÙŠÙ„ Ù…Ø§Ù†Ø¹ Ø§Ù„Ø§Ù†ØºÙ„Ø§Ù‚", "Deceleration Test at 60 km/h", null,
                        "Straight-line stop; no pedal pulsation; ABS pulses.",
                        "ØªÙˆÙ‚Ù Ù…Ø³ØªÙ‚ÙŠÙ…Ø› Ø¨Ù„Ø§ Ù†Ø¨Ø¶ Ø¯ÙˆØ§Ø³Ø©Ø› Ù…Ø§Ù†Ø¹ Ø§Ù„Ø§Ù†ØºÙ„Ø§Ù‚ ÙŠØ¹Ù…Ù„.", true, false, null, 30));
    }

    private ItemSeed item(String code, String category, String nameEn, String nameAr, String tool,
                          String unit, String specEn, String specAr, boolean safety, boolean multi,
                          Integer maxTyreAge, int sortOrder) {
        return new ItemSeed(code, category, nameEn, nameAr, tool, unit, specEn, specAr,
                safety, multi, maxTyreAge, sortOrder);
    }

    private List<OptionSetDefinition> optionSets() {
        return List.of(
                set("ISSUE_TYPE", "Issue Type", "Ù†ÙˆØ¹ Ø§Ù„Ø¹Ø·Ù„", 1,
                        value("WORN", "Worn", "Ù…ØªØ¢ÙƒÙ„"),
                        value("CRACKED", "Cracked", "Ù…ØªØ´Ù‚Ù‚"),
                        value("LEAKING", "Leaking", "ÙŠØªØ³Ø±Ø¨"),
                        value("BENT", "Bent", "Ù…Ù†Ø­Ù†ÙŠ"),
                        value("LOOSE", "Loose", "Ù…Ø±ØªØ®ÙŠ"),
                        value("CORRODED", "Corroded", "Ù…ØªØ¢ÙƒÙ„ ØµØ¯Ø¦ÙŠØ§Ù‹"),
                        value("MISSING", "Missing", "Ù…ÙÙ‚ÙˆØ¯"),
                        value("NOISY", "Noisy", "ØµØ§Ø®Ø¨"),
                        value("CONTAMINATED", "Contaminated", "Ù…Ù„ÙˆØ«"),
                        value("DAMAGED", "Damaged", "ØªØ§Ù„Ù"),
                        value("SEIZED", "Seized", "Ù…Ø­ØªØ¬Ø²"),
                        value("MISALIGNED", "Misaligned", "ØºÙŠØ± Ù…Ø³ØªÙˆÙŠ"),
                        value("WORN_OUT", "Worn out", "Ù…Ù†ØªÙ‡ÙŠ"),
                        value("ACTIVE_DTC", "Active DTC", "Ø±Ù…Ø² Ø¹Ø·Ù„ Ù†Ø´Ø·"),
                        value("HISTORICAL_DTC", "Historical DTC", "Ø±Ù…Ø² Ø¹Ø·Ù„ ØªØ§Ø±ÙŠØ®ÙŠ"),
                        value("NO_FAULT", "No fault", "Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ø¹Ø·Ù„")),
                set("LOCATION", "Location", "Ø§Ù„Ù…ÙˆÙ‚Ø¹", 2,
                        value("FRONT_LEFT", "Front Left", "Ø£Ù…Ø§Ù…ÙŠ Ø£ÙŠØ³Ø±"),
                        value("FRONT_RIGHT", "Front Right", "Ø£Ù…Ø§Ù…ÙŠ Ø£ÙŠÙ…Ù†"),
                        value("REAR_LEFT", "Rear Left", "Ø®Ù„ÙÙŠ Ø£ÙŠØ³Ø±"),
                        value("REAR_RIGHT", "Rear Right", "Ø®Ù„ÙÙŠ Ø£ÙŠÙ…Ù†"),
                        value("FRONT", "Front", "Ø£Ù…Ø§Ù…ÙŠ"),
                        value("REAR", "Rear", "Ø®Ù„ÙÙŠ"),
                        value("LEFT", "Left", "Ø£ÙŠØ³Ø±"),
                        value("RIGHT", "Right", "Ø£ÙŠÙ…Ù†"),
                        value("UNDERBODY", "Underbody", "Ø£Ø³ÙÙ„ Ø§Ù„Ù‡ÙŠÙƒÙ„"),
                        value("ENGINE_BAY", "Engine Bay", "Ø­Ø¬Ø±Ø© Ø§Ù„Ù…Ø­Ø±Ùƒ"),
                        value("CABIN", "Cabin", "Ø§Ù„Ù…Ù‚ØµÙˆØ±Ø©"),
                        value("EXTERIOR", "Exterior", "Ø§Ù„Ø®Ø§Ø±Ø¬"),
                        value("WHEEL_ARCH", "Wheel Arch", "Ù‚ÙˆØ³ Ø§Ù„Ø¹Ø¬Ù„Ø©")),
                set("COMPONENT", "Component", "Ø§Ù„Ø¬Ø²Ø¡", 3,
                        value("PAD", "Brake Pad", "Ù‚Ù…Ø§Ø´ Ø§Ù„ÙØ±Ø§Ù…Ù„"),
                        value("ROTOR", "Rotor", "Ø§Ù„Ù‡ÙˆØ¨"),
                        value("CALIPER", "Caliper", "Ø§Ù„ÙƒØ§Ù„ÙŠØ¨Ø±"),
                        value("HOSE", "Hose", "Ø§Ù„Ù„ÙŠ"),
                        value("FLUID", "Fluid", "Ø§Ù„Ø³Ø§Ø¦Ù„"),
                        value("BUSHING", "Bushing", "Ø§Ù„Ø¬Ù„Ø¨Ø©"),
                        value("BALL_JOINT", "Ball Joint", "Ø±ÙƒØ¨Ø©"),
                        value("STRUT", "Strut", "Ø§Ù„Ù…Ø³Ø§Ø¹Ø¯"),
                        value("SPRING", "Spring", "Ø§Ù„ÙŠØ§ÙŠ"),
                        value("BELT", "Belt", "Ø§Ù„Ø³ÙŠØ±"),
                        value("PULLEY", "Pulley", "Ø§Ù„Ø¨ÙƒØ±Ø©"),
                        value("BATTERY", "Battery", "Ø§Ù„Ø¨Ø·Ø§Ø±ÙŠØ©"),
                        value("ALTERNATOR", "Alternator", "Ø§Ù„Ø¯ÙŠÙ†Ø§Ù…Ùˆ"),
                        value("SENSOR", "Sensor", "Ø§Ù„Ø­Ø³Ø§Ø³"),
                        value("LAMP", "Lamp", "Ø§Ù„Ù…ØµØ¨Ø§Ø­"),
                        value("FILTER", "Filter", "Ø§Ù„ÙÙ„ØªØ±"),
                        value("GLASS", "Glass", "Ø§Ù„Ø²Ø¬Ø§Ø¬"),
                        value("SEAL", "Seal", "Ø§Ù„Ø¹Ø§Ø²Ù„")),
                set("CONDITION", "Condition", "Ø§Ù„Ø­Ø§Ù„Ø©", 4,
                        value("INNER", "Inner", "Ø¯Ø§Ø®Ù„ÙŠ"),
                        value("OUTER", "Outer", "Ø®Ø§Ø±Ø¬ÙŠ"),
                        value("UPPER", "Upper", "Ø¹Ù„ÙˆÙŠ"),
                        value("LOWER", "Lower", "Ø³ÙÙ„ÙŠ"),
                        value("SURFACE", "Surface", "Ø³Ø·Ø­ÙŠ"),
                        value("STRUCTURAL", "Structural", "Ù‡ÙŠÙƒÙ„ÙŠ"),
                        value("ELECTRICAL", "Electrical", "ÙƒÙ‡Ø±Ø¨Ø§Ø¦ÙŠ"),
                        value("MECHANICAL", "Mechanical", "Ù…ÙŠÙƒØ§Ù†ÙŠÙƒÙŠ")),
                set("SEVERITY", "Severity", "Ø§Ù„Ø®Ø·ÙˆØ±Ø©", 5,
                        value("MINOR", "Minor", "Ø·ÙÙŠÙ"),
                        value("MODERATE", "Moderate", "Ù…ØªÙˆØ³Ø·"),
                        value("MAJOR", "Major", "ÙƒØ¨ÙŠØ±"),
                        value("SAFETY_CRITICAL", "Safety critical", "Ø­Ø±Ø¬ Ù„Ù„Ø³Ù„Ø§Ù…Ø©")),
                set("ACTION", "Recommended Action", "Ø§Ù„Ø¥Ø¬Ø±Ø§Ø¡ Ø§Ù„Ù…ÙˆØµÙ‰ Ø¨Ù‡", 6,
                        value("REPLACE", "Replace", "Ø§Ø³ØªØ¨Ø¯Ø§Ù„"),
                        value("REPAIR", "Repair", "Ø¥ØµÙ„Ø§Ø­"),
                        value("MONITOR", "Monitor", "Ù…Ø±Ø§Ù‚Ø¨Ø©"),
                        value("ADJUST", "Adjust", "Ø¶Ø¨Ø·"),
                        value("CLEAN", "Clean", "ØªÙ†Ø¸ÙŠÙ"),
                        value("FLUSH", "Flush", "ØªØºÙŠÙŠØ± ÙƒØ§Ù…Ù„"),
                        value("RECHARGE", "Recharge", "Ø¥Ø¹Ø§Ø¯Ø© Ø´Ø­Ù†"),
                        value("ALIGN", "Align", "Ù…ÙˆØ§Ø²Ù†Ø©"),
                        value("CALIBRATE", "Calibrate", "Ù…Ø¹Ø§ÙŠØ±Ø©")),
                set("URGENCY", "Urgency", "Ø§Ù„Ø£ÙˆÙ„ÙˆÙŠØ©", 7,
                        value("IMMEDIATE", "Immediate", "ÙÙˆØ±ÙŠ"),
                        value("WITHIN_7_DAYS", "Within 7 days", "Ø®Ù„Ø§Ù„ 7 Ø£ÙŠØ§Ù…"),
                        value("NEXT_SERVICE", "Next service", "Ø§Ù„Ø®Ø¯Ù…Ø© Ø§Ù„Ù‚Ø§Ø¯Ù…Ø©"),
                        value("MONITOR", "Monitor", "Ù…Ø±Ø§Ù‚Ø¨Ø©")),
                set("CAUSE", "Likely Cause", "Ø§Ù„Ø³Ø¨Ø¨ Ø§Ù„Ù…Ø­ØªÙ…Ù„", 8,
                        value("WEAR", "Wear", "ØªØ¢ÙƒÙ„"),
                        value("IMPACT", "Impact", "ØµØ¯Ù…Ø©"),
                        value("CORROSION", "Corrosion", "ØµØ¯Ø£"),
                        value("LEAK", "Leak", "ØªØ³Ø±ÙŠØ¨"),
                        value("ELECTRICAL_FAULT", "Electrical fault", "Ø¹Ø·Ù„ ÙƒÙ‡Ø±Ø¨Ø§Ø¦ÙŠ"),
                        value("IMPROPER_REPAIR", "Improper repair", "Ø¥ØµÙ„Ø§Ø­ ØºÙŠØ± ØµØ­ÙŠØ­"),
                        value("AGE", "Age", "Ù‚Ø¯Ù…"),
                        value("CONTAMINATION", "Contamination", "ØªÙ„ÙˆØ«")),
                set("UNIT", "Unit", "Ø§Ù„ÙˆØ­Ø¯Ø©", 9,
                        value("MM", "mm", "Ù…Ù…"),
                        value("UM", "um", "Ù…ÙŠÙƒØ±ÙˆÙ…ØªØ±"),
                        value("V", "V", "ÙÙˆÙ„Øª"),
                        value("PSI", "psi", "Ø±Ø·Ù„"),
                        value("DEG_C", "C", "Ø¯Ø±Ø¬Ø© Ù…Ø¦ÙˆÙŠØ©"),
                        value("PERCENT", "%", "%"),
                        value("A", "A", "Ø£Ù…Ø¨ÙŠØ±"),
                        value("CCA", "CCA", "CCA"),
                        value("RPM", "rpm", "Ø¯ÙˆØ±Ø©/Ø¯Ù‚ÙŠÙ‚Ø©"),
                        value("NM", "Nm", "Ù†ÙŠÙˆØªÙ† Ù…ØªØ±"),
                        value("BAR", "bar", "Ø¨Ø§Ø±"),
                        value("KM", "km", "ÙƒÙ…")),
                set("YES_NO", "Yes / No", "Ù†Ø¹Ù… / Ù„Ø§", 10,
                        value("YES", "Yes", "Ù†Ø¹Ù…"),
                        value("NO", "No", "Ù„Ø§")));
    }

    private OptionSetDefinition set(String code, String en, String ar, int order,
                                    OptionValueSeed... values) {
        return new OptionSetDefinition(code, en, ar, order, List.of(values));
    }

    private OptionValueSeed value(String code, String en, String ar) {
        return new OptionValueSeed(code, en, ar);
    }

    private List<DocumentTypeSeed> documentTypes() {
        return List.of(
                new DocumentTypeSeed("ELECTRICAL_DIAGNOSTICS", "Electrical Diagnostics Report",
                        "ØªÙ‚Ø±ÙŠØ± Ø§Ù„ØªØ´Ø®ÙŠØµ Ø§Ù„ÙƒÙ‡Ø±Ø¨Ø§Ø¦ÙŠ", 1),
                new DocumentTypeSeed("BATTERY_HEALTH", "Battery Health & Conductance Test",
                        "Ø§Ø®ØªØ¨Ø§Ø± ØµØ­Ø© Ø§Ù„Ø¨Ø·Ø§Ø±ÙŠØ© ÙˆØ§Ù„ØªÙˆØµÙŠÙ„", 2),
                new DocumentTypeSeed("PRE_TEST_DRIVE", "Pre-Test Drive Inspection",
                        "ÙØ­Øµ Ù…Ø§ Ù‚Ø¨Ù„ Ø§Ø®ØªØ¨Ø§Ø± Ø§Ù„Ù‚ÙŠØ§Ø¯Ø©", 3),
                new DocumentTypeSeed("POST_ROAD_TEST", "Post-Road Test Performance",
                        "Ø£Ø¯Ø§Ø¡ Ù…Ø§ Ø¨Ø¹Ø¯ Ø§Ø®ØªØ¨Ø§Ø± Ø§Ù„Ø·Ø±ÙŠÙ‚", 4),
                new DocumentTypeSeed("TYRE_ALIGNMENT", "Tyre Alignment & Laser Wear Analysis",
                        "ØªØ­Ù„ÙŠÙ„ Ø§Ø³ØªÙ‚Ø§Ù…Ø© Ø§Ù„Ø¥Ø·Ø§Ø±Ø§Øª ÙˆØªØ¢ÙƒÙ„Ù‡Ø§ Ø¨Ø§Ù„Ù„ÙŠØ²Ø±", 5));
    }
}

