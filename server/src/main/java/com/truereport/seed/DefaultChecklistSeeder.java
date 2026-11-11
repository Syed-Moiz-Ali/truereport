package com.truereport.seed;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.masterdata.config.ConfigValidators;
import com.truereport.masterdata.config.ItemConfigRepository;
import com.truereport.masterdata.config.PlatformMasterDtos.EvidenceRuleDto;
import com.truereport.masterdata.config.PlatformMasterDtos.IssueFieldDto;
import com.truereport.masterdata.config.PlatformMasterDtos.MeasurementBandDto;
import com.truereport.masterdata.config.PlatformMasterDtos.ScoreBandDto;
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

    public DefaultChecklistSeeder(JdbcTemplate jdbc, ItemConfigRepository itemConfig,
                                  ObjectMapper objectMapper) {
        this.jdbc = jdbc;
        this.itemConfig = itemConfig;
        this.objectMapper = objectMapper;
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

        // 5. Scoring rule + grade boundaries
        if (ensureScoringRule()) {
            created++;
        } else {
            skipped++;
        }

        // 6. Default template
        if (ensureDefaultTemplate(versionByCode)) {
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
        jdbc.update("""
                INSERT INTO platform_option_sets
                    (id, code, name_en, name_ar, status, sort_order, created_at, updated_at, version)
                VALUES (?, ?, ?, ?, 'ACTIVE', ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, UuidV7.generate().toString(), definition.code(), definition.nameEn(),
                definition.nameAr(), definition.sortOrder());
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
                jdbc.update("""
                        INSERT INTO platform_option_values
                            (id, option_set_id, code, label_en, label_ar, status, sort_order,
                             metadata_json, created_at, updated_at, version)
                        VALUES (?, ?, ?, ?, ?, 'ACTIVE', ?, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                        """, UuidV7.generate().toString(), setId, value.code(), value.en(), value.ar(), order);
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
                    (id, code, name_en, name_ar, weight_percentage, status, sort_order,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, ?, ?, 'ACTIVE', ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, id.toString(), category.code(), category.nameEn(), category.nameAr(),
                category.weight(), category.sortOrder());
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
                    (id, item_id, version_no, status, label_en, label_ar, instruction_en,
                     instruction_ar, measurement_unit, sensor_tool, standard_spec_en, standard_spec_ar,
                     safety_critical, multi_point, max_tyre_age_years, allow_free_text_note,
                     result_options_json, severity_policy_json, applicability_json, reason_codes_json,
                     note_requirement, evidence_requirement, min_photos, equipment_ids_json,
                     guide_image_id, published_at, published_by, created_at, updated_at, version)
                VALUES (?, ?, 1, 'PUBLISHED', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, FALSE, ?, '{}', '{}',
                        '[]', 'OPTIONAL', 'REQUIRED_MIN_N', 1, '[]', NULL, ?, NULL, ?, ?, 0)
                """, versionId.toString(), itemId.toString(), item.nameEn(), item.nameAr(),
                item.instructionEn(), item.instructionAr(), item.unit(), item.tool(), item.specEn(),
                item.specAr(), item.safetyCritical(), item.multiPoint(), item.maxTyreAgeYears(),
                json(RESULTS), now, now, now);
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
        List<ScoreBandDto> bands = List.of(
                new ScoreBandDto("DEFECT_FOUND", 0, 59, 0,
                        "Defect or failure observed", "عطل أو فشل ملحوظ"),
                new ScoreBandDto("ATTENTION_RECOMMENDED", 60, 84, 70,
                        "Attention or maintenance recommended", "يوصى بالانتباه أو الصيانة"),
                new ScoreBandDto("NO_ISSUE_OBSERVED", 85, 100, 100,
                        "Within specification", "ضمن المواصفات"));
        itemConfig.replaceScoreBands(versionId, bands);
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
                            "Below minimum", "أقل من الحد الأدنى", 1),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "3.0", "5.499",
                            "ATTENTION_RECOMMENDED", 70, "Worn", "متآكل", 2),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "5.5", "99", "NO_ISSUE_OBSERVED",
                            100, "Within specification", "ضمن المواصفات", 3));
            case "ELE-BAT-01" -> List.of(
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "0", "59", "DEFECT_FOUND", 0,
                            "Poor state of health", "حالة صحية ضعيفة", 1),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "60", "84",
                            "ATTENTION_RECOMMENDED", 70, "Moderate state of health", "حالة صحية متوسطة", 2),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "85", "100", "NO_ISSUE_OBSERVED",
                            100, "Good state of health", "حالة صحية جيدة", 3));
            case "ELE-ALT-01" -> List.of(
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "0", "12.999", "DEFECT_FOUND", 0,
                            "Charging below specification", "الشحن أقل من المواصفات", 1),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "13", "13.799",
                            "ATTENTION_RECOMMENDED", 70, "Charging marginal", "الشحن حدي", 2),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "13.8", "15.2", "NO_ISSUE_OBSERVED",
                            100, "Charging within specification", "الشحن ضمن المواصفات", 3),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "15.201", "99", "DEFECT_FOUND", 0,
                            "Overcharging", "شحن زائد", 4));
            case "INT-AC-01" -> List.of(
                    band("MEASUREMENT", unit, "LOWER_IS_BETTER", "0", "7", "NO_ISSUE_OBSERVED", 100,
                            "Cold air within specification", "هواء بارد ضمن المواصفات", 1),
                    band("MEASUREMENT", unit, "LOWER_IS_BETTER", "7.001", "16",
                            "ATTENTION_RECOMMENDED", 70, "Cooling weak", "تبريد ضعيف", 2),
                    band("MEASUREMENT", unit, "LOWER_IS_BETTER", "16.001", "99", "DEFECT_FOUND", 0,
                            "Cooling failure", "فشل التبريد", 3));
            case "BRK-HYD-01" -> List.of(
                    band("MEASUREMENT", unit, "LOWER_IS_BETTER", "0", "1.999", "NO_ISSUE_OBSERVED",
                            100, "Moisture within specification", "الرطوبة ضمن المواصفات", 1),
                    band("MEASUREMENT", unit, "LOWER_IS_BETTER", "2", "3", "ATTENTION_RECOMMENDED",
                            70, "Moisture elevated", "ارتفاع الرطوبة", 2),
                    band("MEASUREMENT", unit, "LOWER_IS_BETTER", "3.001", "100", "DEFECT_FOUND", 0,
                            "Moisture above limit", "الرطوبة أعلى من الحد", 3));
            case "BOD-PNT-01" -> List.of(
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "0", "89.999", "DEFECT_FOUND", 0,
                            "Below factory paint range", "أقل من نطاق دهان المصنع", 1),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "90", "149.999",
                            "NO_ISSUE_OBSERVED", 100, "Factory paint range", "نطاق دهان المصنع", 2),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "150", "999", "DEFECT_FOUND", 0,
                            "Possible body repair or filler", "احتمال إصلاح أو معجون هيكل", 3));
            case "ROA-STR-01" -> List.of(
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "0", "649", "DEFECT_FOUND", 0,
                            "Idle below specification", "دوران الخمول أقل من المواصفات", 1),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "650", "750", "NO_ISSUE_OBSERVED",
                            100, "Idle within specification", "دوران الخمول ضمن المواصفات", 2),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "750.001", "9999", "DEFECT_FOUND", 0,
                            "Idle above specification", "دوران الخمول أعلى من المواصفات", 3));
            case "BRK-ROT-01" -> List.of(
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "0", "20", "DEFECT_FOUND", 0,
                            "Below minimum thickness", "أقل من الحد الأدنى للسماكة", 1),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "20.001", "24.999",
                            "ATTENTION_RECOMMENDED", 70, "Worn rotor", "هوب متآكل", 2),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "25", "99", "NO_ISSUE_OBSERVED",
                            100, "Within specification", "ضمن المواصفات", 3));
            default -> List.of(
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "0", "59", "DEFECT_FOUND", 0,
                            "Below specification", "أقل من المواصفات", 1),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "60", "84",
                            "ATTENTION_RECOMMENDED", 70, "Marginal", "حدي", 2),
                    band("MEASUREMENT", unit, "HIGHER_IS_BETTER", "85", "100", "NO_ISSUE_OBSERVED",
                            100, "Within specification", "ضمن المواصفات", 3));
        };
    }

    private MeasurementBandDto band(String field, String unit, String direction, String min,
                                    String max, String result, int score, String en, String ar,
                                    int order) {
        return new MeasurementBandDto(field, unit, direction, new BigDecimal(min),
                new BigDecimal(max), result, score, en, ar, order);
    }

    private void seedIssueFields(ItemSeed item, String versionId) {
        List<IssueFieldDto> fields = new ArrayList<>();
        boolean numeric = item.unit() != null;
        boolean multiPoint = item.multiPoint();
        fields.add(new IssueFieldDto(null, "ISSUE_TYPE", "Issue Type", "نوع العطل",
                "SELECT", "ISSUE_TYPE", null, true,
                List.of("ATTENTION_RECOMMENDED", "DEFECT_FOUND"), null, null, 0, null, null,
                false, false, 1, List.of()));
        fields.add(new IssueFieldDto(null, "LOCATION", "Location", "الموقع",
                multiPoint ? "MULTI_SELECT" : "SELECT", "LOCATION", null, true,
                List.of("ATTENTION_RECOMMENDED", "DEFECT_FOUND"), null, null, 0, null, null,
                multiPoint, false, 2, locationSubset(item)));
        if ("OBD-SCN-01".equals(item.code())) {
            fields.add(new IssueFieldDto(null, "DTC_COUNT", "DTC Count", "عدد رموز الأعطال",
                    "NUMBER", null, null, false, List.of("ATTENTION_RECOMMENDED", "DEFECT_FOUND"),
                    BigDecimal.ZERO, new BigDecimal("999"), 0, null, null, false, false, 3, List.of()));
            fields.add(new IssueFieldDto(null, "DTC_CODE", "DTC Code", "رمز العطل",
                    "TEXT", null, null, false, List.of("ATTENTION_RECOMMENDED", "DEFECT_FOUND"),
                    null, null, 0, null, null, true, true, 4, List.of()));
        } else {
            fields.add(new IssueFieldDto(null, "COMPONENT", "Component", "الجزء",
                    "SELECT", "COMPONENT", null, false,
                    List.of("ATTENTION_RECOMMENDED", "DEFECT_FOUND"), null, null, 0,
                    "LOCATION", "FRONT_LEFT", false, false, 3, componentSubset(item)));
        }
        if (numeric) {
            fields.add(new IssueFieldDto(null, "MEASUREMENT", "Measured Value", "القيمة المقاسة",
                    "NUMBER", null, "UNIT", true, List.of(
                    "NO_ISSUE_OBSERVED", "ATTENTION_RECOMMENDED", "DEFECT_FOUND"),
                    BigDecimal.ZERO, new BigDecimal("9999"), 2, null, null, multiPoint, false, 4,
                    List.of(item.unit())));
        }
        fields.add(new IssueFieldDto(null, "SEVERITY", "Severity", "الخطورة",
                "SELECT", "SEVERITY", null, true,
                List.of("ATTENTION_RECOMMENDED", "DEFECT_FOUND"), null, null, 0,
                null, null, false, false, 5, List.of()));
        fields.add(new IssueFieldDto(null, "ACTION", "Recommended Action", "الإجراء الموصى به",
                "SELECT", "ACTION", null, true,
                List.of("ATTENTION_RECOMMENDED", "DEFECT_FOUND"), null, null, 0,
                "SEVERITY", "MODERATE", false, false, 6, List.of()));
        fields.add(new IssueFieldDto(null, "URGENCY", "Urgency", "الأولوية",
                "SELECT", "URGENCY", null, true,
                List.of("ATTENTION_RECOMMENDED", "DEFECT_FOUND"), null, null, 0,
                "SEVERITY", "MODERATE", false, false, 7, List.of()));
        itemConfig.replaceIssueFields(versionId, fields);
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
        jdbc.update("""
                INSERT INTO platform_document_types
                    (id, code, name_en, name_ar, status, is_required, sort_order,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, ?, 'ACTIVE', TRUE, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, UuidV7.generate().toString(), type.code(), type.nameEn(), type.nameAr(),
                type.sortOrder());
        return true;
    }

    // ---------------------------------------------------------------- scoring

    private boolean ensureScoringRule() {
        Integer count = jdbc.queryForObject("SELECT COUNT(*) FROM platform_scoring_rules", Integer.class);
        if (count != null && count > 0) {
            return false;
        }
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_scoring_rules
                    (id, code, name_en, name_ar, active, category_weight_mode,
                     hard_fail_cap_enabled, hard_fail_cap_grade, pending_approval,
                     created_at, updated_at, version)
                VALUES (?, 'SCORING-GCC', 'GCC scoring standard', 'معيار التقييم الخليجي',
                        TRUE, 'CONFIGURED', TRUE, 'B', FALSE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, id);
        List<String[]> grades = List.of(
                new String[]{"A", "90", "100", "Excellent", "ممتاز"},
                new String[]{"B", "80", "89", "Good", "جيد"},
                new String[]{"C", "65", "79", "Fair", "مقبول"},
                new String[]{"D", "0", "64", "Poor", "ضعيف"});
        int order = 1;
        for (String[] grade : grades) {
            jdbc.update("""
                    INSERT INTO platform_grade_boundaries
                        (id, scoring_rule_id, grade_code, min_score, max_score, label_en, label_ar,
                         sort_order, approved, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                    """, UuidV7.generate().toString(), id, grade[0], Integer.parseInt(grade[1]),
                    Integer.parseInt(grade[2]), grade[3], grade[4], order++);
        }
        return true;
    }

    // --------------------------------------------------------------- template

    private boolean ensureDefaultTemplate(Map<String, UUID> versionByCode) {
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM platform_templates WHERE code = 'TPL-30-GCC'", Integer.class);
        if (count != null && count > 0) {
            return false;
        }
        String templateId = UuidV7.generate().toString();
        String versionId = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_templates
                    (id, code, name_en, name_ar, description_en, description_ar, status,
                     current_published_version_id, created_at, updated_at, version)
                VALUES (?, 'TPL-30-GCC', 'Comprehensive 30-Point GCC Standard',
                        'فحص شامل 30 نقطة وفق المعيار الخليجي',
                        'Full 6-category, 30-item inspection package.',
                        'حزمة فحص كاملة من 6 تصنيفات و30 عنصراً.',
                        'ACTIVE', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, templateId);
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
        int order = 1;
        for (Map.Entry<String, UUID> entry : versionByCode.entrySet()) {
            jdbc.update("""
                    INSERT INTO platform_template_items
                        (id, template_version_id, item_version_id, sort_order, included, item_weight)
                    VALUES (?, ?, ?, ?, TRUE, NULL)
                    """, UuidV7.generate().toString(), versionId, entry.getValue().toString(), order++);
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

    private record CategorySeed(String code, String nameEn, String nameAr, BigDecimal weight,
                                int sortOrder) {
    }

    private record ItemSeed(String code, String categoryCode, String nameEn, String nameAr,
                            String tool, String unit, String specEn, String specAr,
                            boolean safetyCritical, boolean multiPoint, Integer maxTyreAgeYears,
                            int sortOrder) {
        String instructionEn() {
            return "Inspect " + nameEn + " and record the condition with evidence.";
        }

        String instructionAr() {
            return "افحص " + nameAr + " وسجّل الحالة مع الأدلة.";
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
                new CategorySeed("CAT-ENG", "Powertrain & Mechanical", "مجموعة الحركة والميكانيكا",
                        new BigDecimal("25"), 1),
                new CategorySeed("CAT-SUS", "Suspension, Steering & Underbody",
                        "التعليق والتوجيه وأسفل الهيكل", new BigDecimal("18"), 2),
                new CategorySeed("CAT-BRK", "Braking Systems & Tyres", "أنظمة الفرامل والإطارات",
                        new BigDecimal("20"), 3),
                new CategorySeed("CAT-ELE", "Electrical, Battery & Diagnostics",
                        "الكهرباء والبطارية والتشخيص", new BigDecimal("17"), 4),
                new CategorySeed("CAT-BOD", "Body, Glass & Interior", "الهيكل والزجاج والمقصورة",
                        new BigDecimal("10"), 5),
                new CategorySeed("CAT-ROA", "Road Test & Dynamic Performance",
                        "اختبار الطريق والأداء الديناميكي", new BigDecimal("10"), 6));
    }

    private List<ItemSeed> items() {
        return List.of(
                item("ENG-OIL-01", "CAT-ENG", "Engine Oil Condition & Level", "حالة ومستوى زيت المحرك",
                        "Optical Refractometer / Dipstick", null,
                        "Oil level between MIN/MAX; amber/brown colour; normal viscosity.",
                        "مستوى الزيت بين الحد الأدنى والأقصى؛ لون كهرماني؛ لزوجة طبيعية.", false, false, null, 1),
                item("ENG-FLT-01", "CAT-ENG", "Engine Air Filter & Intake System",
                        "فلتر هواء المحرك ونظام السحب", "Visual / Airflow Gauge", null,
                        "Clean filter pleats; intact housing seals; clean MAF housing.",
                        "طيات فلتر نظيفة؛ عوازل السكن سليمة؛ حساس هواء نظيف.", false, false, null, 2),
                item("TRN-FLU-01", "CAT-ENG", "Transmission Fluid & Drivetrain Health",
                        "سائل ناقل الحركة ونظام الدفع", "Dipstick / Sight Tube", null,
                        "Pink/red or clear fluid; no burnt odour; no gear shudder.",
                        "سائل وردي أو أحمر أو صافٍ؛ بلا رائحة احتراق؛ بلا اهتزاز.", false, false, null, 3),
                item("ENG-CLT-01", "CAT-ENG", "Cooling System, Radiator & Hoses",
                        "نظام التبريد والرادياتير والخراطيم", "Pressure Tester (15 psi)", null,
                        "Holds 15 psi for 5 minutes; clean coolant; flexible hoses.",
                        "يحافظ على 15 رطل لمدة 5 دقائق؛ سائل نظيف؛ خراطيم مرنة.", true, false, null, 4),
                item("ENG-BEL-01", "CAT-ENG", "Drive Belts, Pulleys & Tensioners",
                        "سيور المحرك والبكرات والشدادات", "Belt Wear Gauge & Stethoscope", null,
                        "No cracks; no pulley chirp; tensioner aligned.",
                        "بلا تشققات؛ بلا صرير؛ الشداد مستوي.", false, false, null, 5),
                item("ENG-EXH-01", "CAT-ENG", "Exhaust System, Catalytic Converter & Emissions",
                        "نظام العادم والمحول الحفاز والانبعاثات", "Thermal Gun", null,
                        "No exhaust leaks; catalyst delta temperature above 50 C.",
                        "بلا تسريبات عادم؛ فرق حرارة المحول أكبر من 50 درجة.", false, false, null, 6),
                item("SUS-FRT-01", "CAT-SUS", "Front Shocks, Struts & Springs",
                        "المساعدات الأمامية واليايات", "Pry Bar & Bounce Tester", null,
                        "No hydraulic weeping; rebound dampens in 1.5 cycles; unbroken coil.",
                        "بلا تسريب هيدروليكي؛ ارتداد مخمد؛ يايات سليمة.", true, false, null, 7),
                item("SUS-REA-01", "CAT-SUS", "Rear Dampers & Linkages",
                        "المساعدات الخلفية والوصلات", "Pry Bar & Visual Check", null,
                        "Bushings intact; no clunking; symmetrical ride height.",
                        "جلود سليمة؛ بلا طقطقة؛ ارتفاع متساوٍ.", true, false, null, 8),
                item("STR-RCK-01", "CAT-SUS", "Steering Rack, Tie Rods & Boots",
                        "علبة الدركسون ومسامير التوجيه", "Dial Indicator & Play Check", null,
                        "Tie rod play below 0.5 mm; boots sealed; power assist normal.",
                        "خلوص أقل من 0.5 مم؛ أغطية سليمة؛ مساعدة توجيه طبيعية.", true, false, null, 9),
                item("SUS-CTL-01", "CAT-SUS", "Control Arms & Ball Joints",
                        "أذرعة التحكم والركب", "Ball Joint Gauge & Pry Bar", null,
                        "Joint play below 1.0 mm; rubber boots intact.",
                        "خلوص المفصل أقل من 1 مم؛ أغطية مطاطية سليمة.", true, false, null, 10),
                item("BOD-UND-01", "CAT-SUS", "Chassis Rails, Subframe & Floor Pan",
                        "شاسيه السيارة والهيكل السفلي", "High-Lumen Inspection", null,
                        "Zero structural deformation; no frame straightening marks.",
                        "لا يوجد تشوه هيكلي؛ بلا آثار تقويم شاسيه.", true, false, null, 11),
                item("BRK-PAD-01", "CAT-BRK", "Brake Pad Thickness (All 4 Corners)",
                        "سمك أقمشة الفرامل (جميع العجلات)", "Digital Vernier Brake Gauge", "MM",
                        "Friction material above 3.0 mm (above 25% remaining).",
                        "سماكة التيل أعلى من 3.0 مم (أكثر من 25% متبقٍ).", true, true, null, 12),
                item("BRK-ROT-01", "CAT-BRK", "Brake Disc Rotors & Runout",
                        "هوبات الفرامل ونسبة الاستواء", "Micrometer & Dial Indicator", "MM",
                        "Above minimum thickness; lateral runout below 0.05 mm.",
                        "أعلى من الحد الأدنى للسماكة؛ انحراف أقل من 0.05 مم.", true, false, null, 13),
                item("BRK-HYD-01", "CAT-BRK", "Brake Fluid Moisture & Hydraulic Lines",
                        "سائل الفرامل ونظام الليات", "Digital Moisture Pen", "PERCENT",
                        "Fluid moisture below 2.0%; steel lines free of rust.",
                        "رطوبة السائل أقل من 2.0%؛ خطوط فولاذية بلا صدأ.", true, false, null, 14),
                item("TYRE-SET-01", "CAT-BRK", "Tyre Tread Depth (FL, FR, RL, RR)",
                        "عمق مداس الإطارات (الأربعة)", "Digital Tread Depth Gauge", "MM",
                        "Legal minimum above 1.6 mm; recommended replacement below 3.0 mm.",
                        "الحد القانوني أعلى من 1.6 مم؛ يوصى بالاستبدال تحت 3.0 مم.", true, true, null, 15),
                item("TYRE-CND-01", "CAT-BRK", "Tyre Age (DOT), Sidewall & Structural Integrity",
                        "عمر الإطارات والهيكل الخارجي", "Visual DOT Inspection", null,
                        "Age below 5 years (GCC strict below 2 years); zero sidewall bulges.",
                        "العمر أقل من 5 سنوات (المعيار الخليجي أقل من سنتين)؛ بلا انتفاخات.", true, false, 2, 16),
                item("ELE-BAT-01", "CAT-ELE", "Battery Health & CCA", "فحص البطارية والصحة والقدرة",
                        "Digital Conductance Analyzer", "PERCENT",
                        "State of health at least 80%; resting voltage at least 12.6 V.",
                        "صحة البطارية 80% على الأقل؛ جهد السكون 12.6 فولت على الأقل.", true, false, null, 17),
                item("ELE-ALT-01", "CAT-ELE", "Alternator Charging Voltage & Diode Ripple",
                        "جهد شحن الدينامو واختبار الريبل", "Digital Multimeter", "V",
                        "Idle charging 13.8-14.5 V; ripple below 0.5 V.",
                        "شحن الخمول 13.8-14.5 فولت؛ تموج أقل من 0.5 فولت.", true, false, null, 18),
                item("OBD-SCN-01", "CAT-ELE", "Diagnostic Trouble Codes (OBD-II Full Scan)",
                        "فحص كمبيوتر السيارة وأعطال المحرك", "Professional OBD-II Scanner", null,
                        "Zero active or pending powertrain DTCs.",
                        "لا توجد رموز أعطال نشطة أو معلقة في مجموعة الحركة.", false, false, null, 19),
                item("ELE-LGT-01", "CAT-ELE", "Exterior & Interior Lighting Systems",
                        "الإضاءة الخارجية والداخلية", "Visual & Lux Meter", null,
                        "All lights function; correct beam aiming; clear lenses.",
                        "جميع الأضواء تعمل؛ توجيه صحيح؛ عدسات واضحة.", false, false, null, 20),
                item("ELE-INF-01", "CAT-ELE", "Infotainment, Cameras, Radar & ADAS Sensors",
                        "الشاشات والكاميرات وحساسات الرادار", "Functional Testing", null,
                        "360 camera active; parking sensors trigger; touchscreen responsive.",
                        "كاميرا محيطية تعمل؛ حساسات ركن تعمل؛ شاشة تستجيب.", false, false, null, 21),
                item("BOD-PNT-01", "CAT-BOD", "Paint Thickness & Body Panel Integrity",
                        "سماكة دهان الهيكل وسلامة الألواح", "Coating Thickness Gauge", "UM",
                        "Factory paint 90-150 um; uniform readings across panels.",
                        "دهان المصنع 90-150 ميكرومتر؛ قراءات متساوية.", false, false, null, 22),
                item("BOD-GLS-01", "CAT-BOD", "Windshield, Windows & Mirror Glass",
                        "الزجاج الأمامي والنوافذ والمرايا", "Defroster Grid Tester", null,
                        "Zero cracks in driver line of sight; OEM glass stamps match.",
                        "بلا شقوق في خط نظر السائق؛ مطابقة أختام المصنع.", false, false, null, 23),
                item("INT-AC-01", "CAT-BOD", "Air Conditioning & Climate Performance",
                        "أداء نظام التكييف والتحكم بالمناخ", "Digital Thermocouple", "DEG_C",
                        "Vent temperature at most 7 C after five minutes.",
                        "حرارة الفتحة 7 درجات مئوية كحد أقصى بعد خمس دقائق.", false, false, null, 24),
                item("INT-SFT-01", "CAT-BOD", "Seat Belts, Airbags & Restraint Systems",
                        "أحزمة الأمان والوسائد الهوائية", "Belt Retraction Tester", null,
                        "Belts lock on yank; pretensioners active; airbag covers uncut.",
                        "الأحزمة تقفل عند السحب؛ الشدادات تعمل؛ أغطية الوسائد سليمة.", true, false, null, 25),
                item("INT-ROF-01", "CAT-BOD", "Sunroof, Weatherstripping & Cabin Seals",
                        "فتحة السقف والعوازل المطاطية للكبينة", "Water Spray Test", null,
                        "Seals supple; drains unclogged; sunroof glides smoothly.",
                        "عوازل مرنة؛ مصارف مفتوحة؛ فتحة سقف تنزلق بسلاسة.", false, false, null, 26),
                item("ROA-STR-01", "CAT-ROA", "Cold Start, Cranking & Idle Smoothness",
                        "التشغيل على البارد وانتظام دوران المحرك", "Engine RPM Log", "RPM",
                        "Quick start; smooth idle 650-750 RPM; no smoke.",
                        "تشغيل سريع؛ خمول منتظم 650-750 دورة؛ بلا دخان.", false, false, null, 27),
                item("ROA-TRN-01", "CAT-ROA", "Transmission Shift Quality & Clutch Engagement",
                        "سلاسة تبديلات القير واستجابة الكلتش", "Road Acceleration Test", null,
                        "Smooth upshifts and downshifts; no flare; instant torque.",
                        "تبديلات سلسة؛ بلا تسارع فارغ؛ عزم فوري.", false, false, null, 28),
                item("ROA-ALN-01", "CAT-ROA", "Steering Centering, Tracking & Drift",
                        "استقامة المقود وثبات المسار", "Road Test at 80 km/h", null,
                        "Tracks straight for 100 m; steering wheel level.",
                        "يسير مستقيماً 100 متر؛ المقود مستوٍ.", false, false, null, 29),
                item("ROA-BRK-01", "CAT-ROA", "Dynamic Emergency Braking & ABS Cycling",
                        "الفرملة الطارئة وتفعيل مانع الانغلاق", "Deceleration Test at 60 km/h", null,
                        "Straight-line stop; no pedal pulsation; ABS pulses.",
                        "توقف مستقيم؛ بلا نبض دواسة؛ مانع الانغلاق يعمل.", true, false, null, 30));
    }

    private ItemSeed item(String code, String category, String nameEn, String nameAr, String tool,
                          String unit, String specEn, String specAr, boolean safety, boolean multi,
                          Integer maxTyreAge, int sortOrder) {
        return new ItemSeed(code, category, nameEn, nameAr, tool, unit, specEn, specAr,
                safety, multi, maxTyreAge, sortOrder);
    }

    private List<OptionSetDefinition> optionSets() {
        return List.of(
                set("ISSUE_TYPE", "Issue Type", "نوع العطل", 1,
                        value("WORN", "Worn", "متآكل"),
                        value("CRACKED", "Cracked", "متشقق"),
                        value("LEAKING", "Leaking", "يتسرب"),
                        value("BENT", "Bent", "منحني"),
                        value("LOOSE", "Loose", "مرتخي"),
                        value("CORRODED", "Corroded", "متآكل صدئياً"),
                        value("MISSING", "Missing", "مفقود"),
                        value("NOISY", "Noisy", "صاخب"),
                        value("CONTAMINATED", "Contaminated", "ملوث"),
                        value("DAMAGED", "Damaged", "تالف"),
                        value("SEIZED", "Seized", "محتجز"),
                        value("MISALIGNED", "Misaligned", "غير مستوي"),
                        value("WORN_OUT", "Worn out", "منتهي"),
                        value("ACTIVE_DTC", "Active DTC", "رمز عطل نشط"),
                        value("HISTORICAL_DTC", "Historical DTC", "رمز عطل تاريخي"),
                        value("NO_FAULT", "No fault", "لا يوجد عطل")),
                set("LOCATION", "Location", "الموقع", 2,
                        value("FRONT_LEFT", "Front Left", "أمامي أيسر"),
                        value("FRONT_RIGHT", "Front Right", "أمامي أيمن"),
                        value("REAR_LEFT", "Rear Left", "خلفي أيسر"),
                        value("REAR_RIGHT", "Rear Right", "خلفي أيمن"),
                        value("FRONT", "Front", "أمامي"),
                        value("REAR", "Rear", "خلفي"),
                        value("LEFT", "Left", "أيسر"),
                        value("RIGHT", "Right", "أيمن"),
                        value("UNDERBODY", "Underbody", "أسفل الهيكل"),
                        value("ENGINE_BAY", "Engine Bay", "حجرة المحرك"),
                        value("CABIN", "Cabin", "المقصورة"),
                        value("EXTERIOR", "Exterior", "الخارج"),
                        value("WHEEL_ARCH", "Wheel Arch", "قوس العجلة")),
                set("COMPONENT", "Component", "الجزء", 3,
                        value("PAD", "Brake Pad", "قماش الفرامل"),
                        value("ROTOR", "Rotor", "الهوب"),
                        value("CALIPER", "Caliper", "الكاليبر"),
                        value("HOSE", "Hose", "اللي"),
                        value("FLUID", "Fluid", "السائل"),
                        value("BUSHING", "Bushing", "الجلبة"),
                        value("BALL_JOINT", "Ball Joint", "ركبة"),
                        value("STRUT", "Strut", "المساعد"),
                        value("SPRING", "Spring", "الياي"),
                        value("BELT", "Belt", "السير"),
                        value("PULLEY", "Pulley", "البكرة"),
                        value("BATTERY", "Battery", "البطارية"),
                        value("ALTERNATOR", "Alternator", "الدينامو"),
                        value("SENSOR", "Sensor", "الحساس"),
                        value("LAMP", "Lamp", "المصباح"),
                        value("FILTER", "Filter", "الفلتر"),
                        value("GLASS", "Glass", "الزجاج"),
                        value("SEAL", "Seal", "العازل")),
                set("CONDITION", "Condition", "الحالة", 4,
                        value("INNER", "Inner", "داخلي"),
                        value("OUTER", "Outer", "خارجي"),
                        value("UPPER", "Upper", "علوي"),
                        value("LOWER", "Lower", "سفلي"),
                        value("SURFACE", "Surface", "سطحي"),
                        value("STRUCTURAL", "Structural", "هيكلي"),
                        value("ELECTRICAL", "Electrical", "كهربائي"),
                        value("MECHANICAL", "Mechanical", "ميكانيكي")),
                set("SEVERITY", "Severity", "الخطورة", 5,
                        value("MINOR", "Minor", "طفيف"),
                        value("MODERATE", "Moderate", "متوسط"),
                        value("MAJOR", "Major", "كبير"),
                        value("SAFETY_CRITICAL", "Safety critical", "حرج للسلامة")),
                set("ACTION", "Recommended Action", "الإجراء الموصى به", 6,
                        value("REPLACE", "Replace", "استبدال"),
                        value("REPAIR", "Repair", "إصلاح"),
                        value("MONITOR", "Monitor", "مراقبة"),
                        value("ADJUST", "Adjust", "ضبط"),
                        value("CLEAN", "Clean", "تنظيف"),
                        value("FLUSH", "Flush", "تغيير كامل"),
                        value("RECHARGE", "Recharge", "إعادة شحن"),
                        value("ALIGN", "Align", "موازنة"),
                        value("CALIBRATE", "Calibrate", "معايرة")),
                set("URGENCY", "Urgency", "الأولوية", 7,
                        value("IMMEDIATE", "Immediate", "فوري"),
                        value("WITHIN_7_DAYS", "Within 7 days", "خلال 7 أيام"),
                        value("NEXT_SERVICE", "Next service", "الخدمة القادمة"),
                        value("MONITOR", "Monitor", "مراقبة")),
                set("CAUSE", "Likely Cause", "السبب المحتمل", 8,
                        value("WEAR", "Wear", "تآكل"),
                        value("IMPACT", "Impact", "صدمة"),
                        value("CORROSION", "Corrosion", "صدأ"),
                        value("LEAK", "Leak", "تسريب"),
                        value("ELECTRICAL_FAULT", "Electrical fault", "عطل كهربائي"),
                        value("IMPROPER_REPAIR", "Improper repair", "إصلاح غير صحيح"),
                        value("AGE", "Age", "قدم"),
                        value("CONTAMINATION", "Contamination", "تلوث")),
                set("UNIT", "Unit", "الوحدة", 9,
                        value("MM", "mm", "مم"),
                        value("UM", "um", "ميكرومتر"),
                        value("V", "V", "فولت"),
                        value("PSI", "psi", "رطل"),
                        value("DEG_C", "C", "درجة مئوية"),
                        value("PERCENT", "%", "%"),
                        value("A", "A", "أمبير"),
                        value("CCA", "CCA", "CCA"),
                        value("RPM", "rpm", "دورة/دقيقة"),
                        value("NM", "Nm", "نيوتن متر"),
                        value("BAR", "bar", "بار"),
                        value("KM", "km", "كم")),
                set("YES_NO", "Yes / No", "نعم / لا", 10,
                        value("YES", "Yes", "نعم"),
                        value("NO", "No", "لا")));
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
                        "تقرير التشخيص الكهربائي", 1),
                new DocumentTypeSeed("BATTERY_HEALTH", "Battery Health & Conductance Test",
                        "اختبار صحة البطارية والتوصيل", 2),
                new DocumentTypeSeed("PRE_TEST_DRIVE", "Pre-Test Drive Inspection",
                        "فحص ما قبل اختبار القيادة", 3),
                new DocumentTypeSeed("POST_ROAD_TEST", "Post-Road Test Performance",
                        "أداء ما بعد اختبار الطريق", 4),
                new DocumentTypeSeed("TYRE_ALIGNMENT", "Tyre Alignment & Laser Wear Analysis",
                        "تحليل استقامة الإطارات وتآكلها بالليزر", 5));
    }
}
