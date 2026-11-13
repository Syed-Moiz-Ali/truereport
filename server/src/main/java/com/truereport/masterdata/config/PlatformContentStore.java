package com.truereport.masterdata.config;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.localization.DynamicContentTranslations;
import com.truereport.masterdata.api.CategoryDto;
import com.truereport.masterdata.api.GuideImageDto;
import com.truereport.masterdata.api.ItemDetailDto;
import com.truereport.masterdata.api.ItemSummaryDto;
import com.truereport.masterdata.api.ItemVersionDto;
import com.truereport.masterdata.api.PublishedItemDto;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.uuid.UuidV7;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Clean Platform Admin content store. Reads and writes only the neutral
 * source columns of the platform_* tables; every non-default language lives in
 * {@code platform_translations}.
 */
@Repository
public class PlatformContentStore {

    private final JdbcTemplate jdbc;
    private final ObjectMapper objectMapper;
    private final DynamicContentTranslations translations;

    public PlatformContentStore(JdbcTemplate jdbc, ObjectMapper objectMapper,
                                DynamicContentTranslations translations) {
        this.jdbc = jdbc;
        this.objectMapper = objectMapper;
        this.translations = translations;
    }

    // ------------------------------------------------------------- records

    public record CategoryRow(String id, String code, String name,
                              String status, int sortOrder) {
    }

    public record ItemRow(String id, String stableCode, String categoryId, String categoryName,
                          String status, String currentPublishedVersionId,
                          boolean sampleData, int sortOrder) {
    }

    public record VersionRow(
            String id, String itemId, int versionNo, String status,
            String label, String instruction, String standardSpec,
            String measurementUnit, String sensorTool,
            boolean safetyCritical, boolean multiPoint, Integer maxTyreAgeYears,
            boolean allowFreeTextNote, String resultOptionsJson, String severityPolicyJson,
            String applicabilityJson, String reasonCodesJson, String noteRequirement,
            String evidenceRequirement, int minPhotos, String equipmentIdsJson,
            String guideImageId, LocalDateTime publishedAt, String publishedBy) {
    }

    public record GuideImageRow(String id, String storageKey, byte[] contentHash, String mime,
                                long bytes, String status, String licenceNote, String alt,
                                String uploadedBy, LocalDateTime createdAt) {
    }

    // ---------------------------------------------------------- categories

    private static final RowMapper<CategoryRow> CATEGORY_MAPPER = (rs, i) -> new CategoryRow(
            rs.getString("id"), rs.getString("code"), rs.getString("name"),
            rs.getString("status"), rs.getInt("sort_order"));

    public List<CategoryDto> categories() {
        return jdbc.query("""
                SELECT id, code, name, status, sort_order
                FROM platform_categories ORDER BY sort_order, code
                """, CATEGORY_MAPPER).stream().map(row -> toCategoryDto(row, countItems(row.id()))).toList();
    }

    public List<CategoryDto> activeCategories() {
        return jdbc.query("""
                SELECT id, code, name, status, sort_order
                FROM platform_categories WHERE status = 'ACTIVE' ORDER BY sort_order, code
                """, CATEGORY_MAPPER).stream().map(row -> toCategoryDto(row, countItems(row.id()))).toList();
    }

    public Optional<CategoryRow> category(String id) {
        return jdbc.query("""
                SELECT id, code, name, status, sort_order
                FROM platform_categories WHERE id = ?
                """, CATEGORY_MAPPER, id).stream().findFirst();
    }

    public Optional<CategoryRow> categoryByCode(String code) {
        return jdbc.query("""
                SELECT id, code, name, status, sort_order
                FROM platform_categories WHERE code = ?
                """, CATEGORY_MAPPER, code).stream().findFirst();
    }

    public CategoryDto createCategory(String code, String name,
                                      Map<String, Map<String, String>> fieldTranslations,
                                      int sortOrder, String status) {
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_categories
                    (id, code, name, status, sort_order,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, id, code, name, status, sortOrder);
        translations.saveOverlays("CATEGORY", id, fieldTranslations, "APPROVED");
        return toCategoryDto(category(id).orElseThrow(), 0);
    }

    public CategoryDto updateCategory(String id, String name,
                                      Map<String, Map<String, String>> fieldTranslations,
                                      Integer sortOrder, String status) {
        CategoryRow current = category(id).orElseThrow(ApiException::notFound);
        jdbc.update("""
                UPDATE platform_categories
                SET name = ?, sort_order = ?, status = ?,
                    updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE id = ?
                """, blankTo(name, current.name()),
                sortOrder == null ? current.sortOrder() : sortOrder,
                status == null ? current.status() : status, id);
        translations.saveOverlays("CATEGORY", id, fieldTranslations, "APPROVED");
        return toCategoryDto(category(id).orElseThrow(), countItems(id));
    }

    public void setCategoryStatus(String id, String status) {
        jdbc.update("""
                UPDATE platform_categories SET status = ?, updated_at = CURRENT_TIMESTAMP,
                    version = version + 1 WHERE id = ?
                """, status, id);
    }

    public void retireCategory(String id) {
        jdbc.update("""
                UPDATE platform_categories SET status = 'RETIRED', updated_at = CURRENT_TIMESTAMP,
                    version = version + 1 WHERE id = ?
                """, id);
    }

    public void reorderCategories(List<String> orderedIds) {
        int order = 1;
        for (String id : orderedIds) {
            jdbc.update("""
                    UPDATE platform_categories SET sort_order = ?, updated_at = CURRENT_TIMESTAMP
                    WHERE id = ?
                    """, order++, id);
        }
    }

    public long countItems(String categoryId) {
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM platform_items WHERE category_id = ?", Integer.class, categoryId);
        return count == null ? 0 : count;
    }

    public CategoryDto categoryDto(String id) {
        CategoryRow row = category(id).orElseThrow(ApiException::notFound);
        return toCategoryDto(row, countItems(id));
    }

    public ItemVersionDto itemVersionDto(String versionId) {
        return toVersionDto(version(versionId).orElseThrow(ApiException::notFound));
    }

    public Map<String, Map<String, String>> categoryTranslations(CategoryRow row) {
        return translations.view("CATEGORY", row.id(), Map.of("name", safe(row.name())));
    }

    private CategoryDto toCategoryDto(CategoryRow row, long itemCount) {
        Map<String, Map<String, String>> fieldTranslations = categoryTranslations(row);
        String labelAr = translations.resolve("CATEGORY", row.id(), "name", "ar",
                safe(row.name()));
        return new CategoryDto(UUID.fromString(row.id()), row.code(), row.status(), row.sortOrder(),
                row.name(), itemCount, row.code(), "ACTIVE".equals(row.status()),
                fieldTranslations, row.name(), labelAr);
    }

    // --------------------------------------------------------------- items

    private static final RowMapper<ItemRow> ITEM_MAPPER = (rs, i) -> new ItemRow(
            rs.getString("id"), rs.getString("stable_code"), rs.getString("category_id"),
            rs.getString("category_name"),
            rs.getString("status"), rs.getString("current_published_version_id"),
            rs.getBoolean("sample_data"), rs.getInt("sort_order"));

    private static final String ITEM_SELECT = """
            SELECT i.id, i.stable_code, i.category_id, c.name AS category_name,
                   i.status, i.current_published_version_id,
                   i.sample_data, i.sort_order
            FROM platform_items i
            JOIN platform_categories c ON c.id = i.category_id
            """;

    public List<ItemRow> items() {
        return jdbc.query(ITEM_SELECT + " ORDER BY i.sort_order, i.stable_code", ITEM_MAPPER);
    }

    public Optional<ItemRow> item(String id) {
        return jdbc.query(ITEM_SELECT + " WHERE i.id = ?", ITEM_MAPPER, id)
                .stream().findFirst();
    }

    public Optional<ItemRow> itemByCode(String stableCode) {
        return jdbc.query(ITEM_SELECT + " WHERE i.stable_code = ?", ITEM_MAPPER, stableCode)
                .stream().findFirst();
    }

    public List<ItemSummaryDto> items(String search, UUID categoryId, String status) {
        String query = search == null ? "" : search.trim().toLowerCase();
        return items().stream()
                .filter(item -> categoryId == null || item.categoryId().equals(categoryId.toString()))
                .filter(item -> status == null || status.isBlank() || item.status().equals(status))
                .map(this::summary)
                .filter(item -> query.isEmpty()
                        || contains(item.stableCode(), query)
                        || contains(item.labelEn(), query)
                        || contains(item.labelAr(), query))
                .toList();
    }

    public ItemSummaryDto summary(ItemRow item) {
        Optional<VersionRow> current = currentOrLatestVersion(item);
        String labelEn = current.map(VersionRow::label).orElse("");
        String labelAr = current.map(version -> translations.resolve("ITEM", version.id(),
                "label", "ar", safe(version.label()))).orElse("");
        String standardSpecEn = current.map(VersionRow::standardSpec).orElse("");
        String standardSpecAr = current.map(version -> translations.resolve("ITEM", version.id(),
                "standardSpec", "ar", safe(version.standardSpec()))).orElse("");
        Map<String, Map<String, String>> fieldTranslations = current
                .map(version -> translations.view("ITEM", version.id(), itemSources(version)))
                .orElseGet(Map::of);
        String categoryLabelAr = translations.resolve("CATEGORY", item.categoryId(), "name", "ar",
                safe(item.categoryName()));
        String instruction = current.map(VersionRow::instruction).orElse("");
        return new ItemSummaryDto(
                UUID.fromString(item.id()), item.stableCode(), UUID.fromString(item.categoryId()),
                item.categoryName(), categoryLabelAr, item.status(),
                current.map(VersionRow::versionNo).orElse(null),
                labelEn, instruction,
                item.sampleData(), "",
                current.map(VersionRow::measurementUnit).orElse(""),
                current.map(VersionRow::sensorTool).orElse(""),
                standardSpecEn,
                current.map(VersionRow::safetyCritical).orElse(false),
                current.map(VersionRow::multiPoint).orElse(false),
                current.map(VersionRow::maxTyreAgeYears).orElse(null),
                current.map(VersionRow::allowFreeTextNote).orElse(false),
                item.sortOrder(),
                current.map(VersionRow::guideImageId).orElse(""),
                fieldTranslations, labelEn, labelAr, standardSpecEn, standardSpecAr);
    }

    public ItemDetailDto itemDetail(UUID itemId) {
        ItemRow item = item(itemId.toString()).orElseThrow(ApiException::notFound);
        List<ItemVersionDto> versions = versions(item.id()).stream().map(this::toVersionDto).toList();
        return new ItemDetailDto(summary(item), versions);
    }

    public List<ItemVersionDto> listVersions(UUID itemId) {
        item(itemId.toString()).orElseThrow(ApiException::notFound);
        return versions(itemId.toString()).stream().map(this::toVersionDto).toList();
    }

    public List<PublishedItemDto> publishedItems(String search, UUID categoryId) {
        String query = search == null ? "" : search.trim().toLowerCase();
        return items().stream()
                .filter(item -> "PUBLISHED".equals(item.status()))
                .filter(item -> categoryId == null || item.categoryId().equals(categoryId.toString()))
                .map(item -> currentOrLatestVersion(item)
                        .filter(version -> "PUBLISHED".equals(version.status()))
                        .map(version -> publishedItem(item, version))
                        .orElse(null))
                .filter(java.util.Objects::nonNull)
                .filter(item -> query.isEmpty()
                        || contains(item.stableCode(), query)
                        || contains(item.labelEn(), query)
                        || contains(item.labelAr(), query)
                        || contains(item.categoryLabelEn(), query)
                        || contains(item.categoryLabelAr(), query))
                .toList();
    }

    public PublishedItemDto publishedItem(UUID versionId) {
        VersionRow version = version(versionId.toString()).orElseThrow(ApiException::notFound);
        if (!"PUBLISHED".equals(version.status())) {
            throw ApiException.notFound();
        }
        ItemRow item = item(version.itemId()).orElseThrow(ApiException::notFound);
        if (!"PUBLISHED".equals(item.status())) {
            throw ApiException.notFound();
        }
        return publishedItem(item, version);
    }

    public ItemDetailDto createItem(UUID categoryId, String stableCode, boolean sampleData,
                                    int sortOrder, String label, String instruction,
                                    String standardSpec,
                                    Map<String, Map<String, String>> fieldTranslations,
                                    String measurementUnit, String sensorTool,
                                    boolean safetyCritical, boolean multiPoint,
                                    Integer maxTyreAgeYears, boolean allowFreeTextNote,
                                    List<String> resultOptions, String severityPolicy,
                                    String applicability, List<String> reasonCodes,
                                    String noteRequirement, String evidenceRequirement,
                                    int minPhotos, List<UUID> equipmentIds, UUID guideImageId) {
        String itemId = UuidV7.generate().toString();
        String versionId = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_items
                    (id, stable_code, category_id, status, current_published_version_id,
                     sample_data, sort_order, created_at, updated_at, version)
                VALUES (?, ?, ?, 'DRAFT', NULL, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, itemId, stableCode, categoryId.toString(), sampleData, sortOrder);
        jdbc.update("""
                INSERT INTO platform_item_versions
                    (id, item_id, version_no, status, label, instruction, standard_spec,
                     measurement_unit, sensor_tool,
                     safety_critical, multi_point, max_tyre_age_years, allow_free_text_note,
                     result_options_json, severity_policy_json, applicability_json, reason_codes_json,
                     note_requirement, evidence_requirement, min_photos, equipment_ids_json,
                     guide_image_id, published_at, published_by, created_at, updated_at, version)
                VALUES (?, ?, 1, 'DRAFT', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                        ?, NULL, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, versionId, itemId, label, instruction, standardSpec,
                measurementUnit, sensorTool, safetyCritical,
                multiPoint, maxTyreAgeYears, allowFreeTextNote, json(resultOptions),
                blankTo(severityPolicy, "{}"), blankTo(applicability, "{}"), json(reasonCodes),
                blankTo(noteRequirement, "OPTIONAL"), blankTo(evidenceRequirement, "NONE"),
                Math.max(0, minPhotos), json(equipmentIds == null ? List.of()
                        : equipmentIds.stream().map(UUID::toString).toList()),
                guideImageId == null ? null : guideImageId.toString());
        translations.saveOverlays("ITEM", versionId, fieldTranslations, "APPROVED");
        return itemDetail(UUID.fromString(itemId));
    }

    public ItemDetailDto createDraft(UUID itemId) {
        ItemRow item = item(itemId.toString()).orElseThrow(ApiException::notFound);
        if ("RETIRED".equals(item.status())) {
            throw ApiException.conflict("ITEM_RETIRED", "Retired items cannot be edited");
        }
        VersionRow latest = latestVersion(itemId.toString())
                .orElseThrow(() -> ApiException.conflict("NO_VERSION", "Item has no version"));
        if ("DRAFT".equals(latest.status())) {
            throw ApiException.conflict("DRAFT_EXISTS",
                    "A draft already exists; edit it before creating another");
        }
        String draftId = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_item_versions
                    (id, item_id, version_no, status, label, instruction, standard_spec,
                     measurement_unit, sensor_tool,
                     safety_critical, multi_point, max_tyre_age_years, allow_free_text_note,
                     result_options_json, severity_policy_json, applicability_json, reason_codes_json,
                     note_requirement, evidence_requirement, min_photos, equipment_ids_json,
                     guide_image_id, published_at, published_by, created_at, updated_at, version)
                SELECT ?, item_id, ?, 'DRAFT', label, instruction, standard_spec,
                       measurement_unit, sensor_tool,
                       safety_critical, multi_point, max_tyre_age_years, allow_free_text_note,
                       result_options_json, severity_policy_json, applicability_json, reason_codes_json,
                       note_requirement, evidence_requirement, min_photos, equipment_ids_json,
                       guide_image_id, NULL, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0
                FROM platform_item_versions WHERE id = ?
                """, draftId, latest.versionNo() + 1, latest.id());
        translations.saveOverlays("ITEM", draftId,
                translations.view("ITEM", latest.id(), itemSources(latest)), "APPROVED");
        return itemDetail(itemId);
    }

    public VersionRow updateTranslation(UUID itemId, UUID versionId, String locale,
                                        String label, String instruction) {
        requireDraft(itemId, versionId);
        String language = translations.requireLanguage(locale);
        if (language.equals(translations.defaultCode())) {
            jdbc.update("""
                    UPDATE platform_item_versions
                    SET label = ?, instruction = ?, updated_at = CURRENT_TIMESTAMP,
                        version = version + 1
                    WHERE id = ?
                    """, blankTo(label, ""), blankTo(instruction, ""), versionId.toString());
            translations.deleteAll("ITEM", versionId.toString());
        } else {
            Map<String, Map<String, String>> overlays = new LinkedHashMap<>();
            overlays.put("label", Map.of(language, label == null ? "" : label));
            overlays.put("instruction", Map.of(language, instruction == null ? "" : instruction));
            translations.saveOverlays("ITEM", versionId.toString(), overlays, "APPROVED");
        }
        return version(versionId.toString()).orElseThrow();
    }

    public VersionRow updateRules(UUID itemId, UUID versionId, List<String> resultOptions,
                                  String severityPolicy, String applicability, List<String> reasonCodes,
                                  String noteRequirement, String evidenceRequirement, int minPhotos,
                                  List<UUID> equipmentIds, UUID guideImageId) {
        requireDraft(itemId, versionId);
        jdbc.update("""
                UPDATE platform_item_versions
                SET result_options_json = ?, severity_policy_json = ?, applicability_json = ?,
                    reason_codes_json = ?, note_requirement = ?, evidence_requirement = ?,
                    min_photos = ?, equipment_ids_json = ?, guide_image_id = ?,
                    updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE id = ?
                """, json(resultOptions), blankTo(severityPolicy, "{}"),
                blankTo(applicability, "{}"), json(reasonCodes),
                blankTo(noteRequirement, "OPTIONAL"), blankTo(evidenceRequirement, "NONE"),
                Math.max(0, minPhotos), json(equipmentIds == null ? List.of()
                        : equipmentIds.stream().map(UUID::toString).toList()),
                guideImageId == null ? null : guideImageId.toString(), versionId.toString());
        return version(versionId.toString()).orElseThrow();
    }

    public VersionRow updateMetadata(UUID itemId, UUID versionId, String measurementUnit,
                                     String sensorTool, String standardSpec,
                                     Map<String, Map<String, String>> fieldTranslations,
                                     boolean safetyCritical, boolean multiPoint,
                                     Integer maxTyreAgeYears, boolean allowFreeTextNote,
                                     String guideImageId) {
        requireDraft(itemId, versionId);
        jdbc.update("""
                UPDATE platform_item_versions
                SET measurement_unit = ?, sensor_tool = ?, standard_spec = ?,
                    safety_critical = ?, multi_point = ?, max_tyre_age_years = ?,
                    allow_free_text_note = ?, guide_image_id = ?, updated_at = CURRENT_TIMESTAMP,
                    version = version + 1
                WHERE id = ?
                """, measurementUnit, sensorTool, standardSpec, safetyCritical,
                multiPoint, maxTyreAgeYears, allowFreeTextNote,
                guideImageId == null || guideImageId.isBlank() ? null : guideImageId,
                versionId.toString());
        translations.saveOverlays("ITEM", versionId.toString(), fieldTranslations, "APPROVED");
        return version(versionId.toString()).orElseThrow();
    }

    public VersionRow publish(UUID itemId, UUID versionId, UUID actorId) {
        requireDraft(itemId, versionId);
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        jdbc.update("""
                UPDATE platform_item_versions
                SET status = 'PUBLISHED', published_at = ?, published_by = ?,
                    updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE id = ?
                """, now, actorId.toString(), versionId.toString());
        jdbc.update("""
                UPDATE platform_items
                SET status = 'PUBLISHED', current_published_version_id = ?,
                    updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE id = ?
                """, versionId.toString(), itemId.toString());
        return version(versionId.toString()).orElseThrow();
    }

    public ItemSummaryDto retireItem(UUID itemId) {
        ItemRow item = item(itemId.toString()).orElseThrow(ApiException::notFound);
        jdbc.update("""
                UPDATE platform_items SET status = 'RETIRED', updated_at = CURRENT_TIMESTAMP,
                    version = version + 1 WHERE id = ?
                """, itemId.toString());
        return summary(item(itemId.toString()).orElse(item));
    }

    public void reorderItems(List<String> orderedIds) {
        int order = 1;
        for (String id : orderedIds) {
            jdbc.update("""
                    UPDATE platform_items SET sort_order = ?, updated_at = CURRENT_TIMESTAMP
                    WHERE id = ?
                    """, order++, id);
        }
    }

    public void updateItemSortOrder(String itemId, int sortOrder) {
        jdbc.update("""
                UPDATE platform_items SET sort_order = ?, updated_at = CURRENT_TIMESTAMP,
                    version = version + 1 WHERE id = ?
                """, sortOrder, itemId);
    }

    public VersionRow requireDraft(UUID itemId, UUID versionId) {
        VersionRow version = version(versionId.toString()).orElseThrow(ApiException::notFound);
        if (!version.itemId().equals(itemId.toString())) {
            throw ApiException.notFound();
        }
        if (!"DRAFT".equals(version.status())) {
            throw ApiException.conflict("VERSION_IMMUTABLE",
                    "Published versions cannot be edited");
        }
        return version;
    }

    private static final String VERSION_SELECT = """
            SELECT id, item_id, version_no, status, label, instruction, standard_spec,
                   measurement_unit, sensor_tool, safety_critical, multi_point, max_tyre_age_years,
                   allow_free_text_note, result_options_json, severity_policy_json,
                   applicability_json, reason_codes_json, note_requirement,
                   evidence_requirement, min_photos, equipment_ids_json, guide_image_id,
                   published_at, published_by
            FROM platform_item_versions
            """;

    public Optional<VersionRow> version(String versionId) {
        return jdbc.query(VERSION_SELECT + " WHERE id = ?", VERSION_MAPPER, versionId)
                .stream().findFirst();
    }

    public List<VersionRow> versions(String itemId) {
        return jdbc.query(VERSION_SELECT + " WHERE item_id = ? ORDER BY version_no DESC",
                VERSION_MAPPER, itemId);
    }

    public Optional<VersionRow> latestVersion(String itemId) {
        return jdbc.query(VERSION_SELECT + " WHERE item_id = ? ORDER BY version_no DESC",
                VERSION_MAPPER, itemId).stream().findFirst();
    }

    public Optional<VersionRow> currentOrLatestVersion(ItemRow item) {
        if (item.currentPublishedVersionId() != null) {
            Optional<VersionRow> published = version(item.currentPublishedVersionId());
            if (published.isPresent()) {
                return published;
            }
        }
        return latestVersion(item.id());
    }

    private static final RowMapper<VersionRow> VERSION_MAPPER = (rs, i) -> new VersionRow(
            rs.getString("id"), rs.getString("item_id"), rs.getInt("version_no"),
            rs.getString("status"), rs.getString("label"), rs.getString("instruction"),
            rs.getString("standard_spec"),
            rs.getString("measurement_unit"), rs.getString("sensor_tool"),
            rs.getBoolean("safety_critical"), rs.getBoolean("multi_point"),
            (Integer) rs.getObject("max_tyre_age_years"), rs.getBoolean("allow_free_text_note"),
            rs.getString("result_options_json"), rs.getString("severity_policy_json"),
            rs.getString("applicability_json"), rs.getString("reason_codes_json"),
            rs.getString("note_requirement"), rs.getString("evidence_requirement"),
            rs.getInt("min_photos"), rs.getString("equipment_ids_json"),
            rs.getString("guide_image_id"),
            rs.getObject("published_at", LocalDateTime.class), rs.getString("published_by"));

    private Map<String, String> itemSources(VersionRow row) {
        Map<String, String> sources = new LinkedHashMap<>();
        sources.put("label", safe(row.label()));
        sources.put("instruction", safe(row.instruction()));
        sources.put("standardSpec", safe(row.standardSpec()));
        return sources;
    }

    private ItemVersionDto toVersionDto(VersionRow row) {
        Map<String, Map<String, String>> fieldTranslations =
                translations.view("ITEM", row.id(), itemSources(row));
        String labelAr = translations.resolve("ITEM", row.id(), "label", "ar", safe(row.label()));
        String instructionAr = translations.resolve("ITEM", row.id(), "instruction", "ar",
                safe(row.instruction()));
        return new ItemVersionDto(UUID.fromString(row.id()), row.versionNo(), row.status(),
                parseStrings(row.resultOptionsJson()), row.severityPolicyJson(),
                row.applicabilityJson(), parseStrings(row.reasonCodesJson()),
                row.noteRequirement(), row.evidenceRequirement(), row.minPhotos(),
                parseUuids(row.equipmentIdsJson()),
                row.guideImageId() == null || row.guideImageId().isBlank()
                        ? null : UUID.fromString(row.guideImageId()),
                row.publishedAt() == null ? "" : row.publishedAt().toString(),
                safe(row.label()), safe(row.instruction()), safe(row.standardSpec()),
                fieldTranslations, safe(row.label()), labelAr,
                safe(row.instruction()), instructionAr);
    }

    private PublishedItemDto publishedItem(ItemRow item, VersionRow version) {
        ItemVersionDto versionDto = toVersionDto(version);
        String labelAr = translations.resolve("ITEM", version.id(), "label", "ar",
                safe(version.label()));
        String categoryLabelAr = translations.resolve("CATEGORY", item.categoryId(), "name", "ar",
                safe(item.categoryName()));
        return new PublishedItemDto(UUID.fromString(item.id()), UUID.fromString(version.id()),
                item.stableCode(), UUID.fromString(item.categoryId()),
                item.categoryName(), categoryLabelAr,
                safe(version.label()), safe(version.instruction()),
                safe(version.label()), labelAr, item.sampleData(), versionDto);
    }

    private List<String> parseStrings(String value) {
        if (value == null || value.isBlank()) {
            return List.of();
        }
        try {
            return objectMapper.readValue(value, new TypeReference<List<String>>() {
            });
        } catch (Exception ex) {
            return List.of();
        }
    }

    private List<UUID> parseUuids(String value) {
        return parseStrings(value).stream().map(UUID::fromString).toList();
    }

    private String json(Object value) {
        try {
            return objectMapper.writeValueAsString(value == null ? List.of() : value);
        } catch (Exception ex) {
            return "[]";
        }
    }

    private static boolean contains(String value, String query) {
        return value != null && value.toLowerCase().contains(query);
    }

    private static String blankTo(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }

    private static String safe(String value) {
        return value == null ? "" : value;
    }

    // --------------------------------------------------------- guide images

    public List<GuideImageDto> guideImages() {
        return jdbc.query("""
                SELECT id, storage_key, content_hash, mime, bytes, status, licence_note, alt,
                       uploaded_by, created_at
                FROM platform_guide_images WHERE status = 'ACTIVE' ORDER BY created_at DESC
                """, GUIDE_MAPPER).stream().map(this::toGuideDto).toList();
    }

    public GuideImageRow createGuideImage(String storageKey, byte[] hash, String mime, long bytes,
                                          String licenceNote, String alt,
                                          Map<String, Map<String, String>> fieldTranslations,
                                          UUID uploadedBy) {
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_guide_images
                    (id, storage_key, content_hash, mime, bytes, status, licence_note, alt,
                     uploaded_by, created_at, updated_at, version)
                VALUES (?, ?, ?, ?, ?, 'ACTIVE', ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, id, storageKey, hash, mime, bytes, licenceNote, alt,
                uploadedBy == null ? null : uploadedBy.toString());
        translations.saveOverlays("GUIDE_IMAGE", id, fieldTranslations, "APPROVED");
        return guideImage(id).orElseThrow();
    }

    public Optional<GuideImageRow> guideImage(String id) {
        return jdbc.query("""
                SELECT id, storage_key, content_hash, mime, bytes, status, licence_note, alt,
                       uploaded_by, created_at
                FROM platform_guide_images WHERE id = ?
                """, GUIDE_MAPPER, id).stream().findFirst();
    }

    public void retireGuideImage(String id) {
        jdbc.update("""
                UPDATE platform_guide_images SET status = 'RETIRED', updated_at = CURRENT_TIMESTAMP,
                    version = version + 1 WHERE id = ?
                """, id);
    }

    public GuideImageDto toGuideDto(GuideImageRow row) {
        Map<String, Map<String, String>> fieldTranslations =
                translations.view("GUIDE_IMAGE", row.id(), Map.of("alt", safe(row.alt())));
        String altAr = translations.resolve("GUIDE_IMAGE", row.id(), "alt", "ar", safe(row.alt()));
        return new GuideImageDto(UUID.fromString(row.id()), row.status(), row.mime(), row.bytes(),
                row.licenceNote(), safe(row.alt()),
                "/api/v1/platform/master/guide-images/" + row.id() + "/content",
                fieldTranslations, safe(row.alt()), altAr);
    }

    private static final RowMapper<GuideImageRow> GUIDE_MAPPER = (rs, i) -> new GuideImageRow(
            rs.getString("id"), rs.getString("storage_key"), rs.getBytes("content_hash"),
            rs.getString("mime"), rs.getLong("bytes"), rs.getString("status"),
            rs.getString("licence_note"), rs.getString("alt"),
            rs.getString("uploaded_by"), rs.getObject("created_at", LocalDateTime.class));

    @SuppressWarnings("unused")
    private static List<String> empty() {
        return new ArrayList<>();
    }
}


