package com.truereport.localization;

import com.truereport.localization.api.LanguageDtos.BacklogGroupDto;
import com.truereport.localization.api.LanguageDtos.EntityCoverageDto;
import com.truereport.localization.api.LanguageDtos.LanguageBacklogDto;
import com.truereport.localization.api.LanguageDtos.LanguageCoverageDto;
import com.truereport.localization.api.LanguageDtos.LanguageDto;
import com.truereport.localization.api.LanguageDtos.LanguageRefDto;
import com.truereport.localization.api.LanguageDtos.PublishLanguageResultDto;
import com.truereport.localization.api.LanguageDtos.TranslationItemDto;
import com.truereport.localization.api.LanguageDtos.UpsertTranslationRequest;
import com.truereport.shared.audit.FieldAuditService;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.error.FieldIssue;
import com.truereport.shared.security.CurrentUser;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/**
 * Translation overlay backlog, coverage and language publishing for dynamic
 * languages. Backlog covers LIVE content only: active categories, published
 * items, option sets/values used by published items, active templates,
 * active document types and issue fields of published item versions.
 * Draft/retired content never blocks activation.
 */
@Service
public class TranslationBacklogService {

    public static final Set<String> ENTITY_TYPES = Set.of(
            "CATEGORY", "ITEM", "OPTION_SET", "OPTION_VALUE", "TEMPLATE",
            "DOCUMENT_TYPE", "ISSUE_FIELD");

    private static final Set<String> TRANSLATION_STATUSES = Set.of(
            "DRAFT", "TRANSLATING", "REVIEWED", "APPROVED");

    private static final Map<String, List<String>> FIELDS = Map.of(
            "CATEGORY", List.of("name"),
            "ITEM", List.of("label", "instruction"),
            "OPTION_SET", List.of("name"),
            "OPTION_VALUE", List.of("label"),
            "TEMPLATE", List.of("name", "description"),
            "DOCUMENT_TYPE", List.of("name"),
            "ISSUE_FIELD", List.of("label"));

    private static final List<String> GROUP_ORDER = List.of(
            "CATEGORY", "ITEM", "OPTION_SET", "OPTION_VALUE", "TEMPLATE",
            "DOCUMENT_TYPE", "ISSUE_FIELD");

    private final JdbcTemplate jdbc;
    private final LanguageRepository languages;
    private final TranslationRepository translations;
    private final FieldAuditService audit;

    public TranslationBacklogService(JdbcTemplate jdbc, LanguageRepository languages,
                                     TranslationRepository translations, FieldAuditService audit) {
        this.jdbc = jdbc;
        this.languages = languages;
        this.translations = translations;
        this.audit = audit;
    }

    // ------------------------------------------------------------------ upsert

    @Transactional
    public TranslationItemDto upsert(CurrentUser actor, UpsertTranslationRequest request,
                                     HttpServletRequest http) {
        String entityType = upper(request == null ? null : request.entityType());
        String entityId = request == null ? null : request.entityId();
        String field = request == null ? null : request.field();
        String language = request == null || request.language() == null
                ? "" : request.language().trim().toLowerCase(Locale.ROOT);
        if (!ENTITY_TYPES.contains(entityType)) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "TRANSLATION_ENTITY_INVALID",
                    "error.validation.failed", "Unknown translation entity type");
        }
        if (!FIELDS.get(entityType).contains(field)) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "TRANSLATION_FIELD_INVALID",
                    "error.validation.failed", "Unknown translation field for " + entityType);
        }
        LanguageDto target = languages.find(language)
                .orElseThrow(() -> validation("language", "LANGUAGE_UNKNOWN", "error.locale.invalid"));
        if (entityId == null || entityId.isBlank() || !entityExists(entityType, entityId.trim())) {
            throw ApiException.notFound();
        }
        if (request.text() == null || request.text().isBlank()) {
            throw validation("text", "TRANSLATION_TEXT_REQUIRED", "error.validation.failed");
        }
        String status = request.status() == null || request.status().isBlank()
                ? "DRAFT" : request.status().trim().toUpperCase(Locale.ROOT);
        if (!TRANSLATION_STATUSES.contains(status)) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "TRANSLATION_STATUS_INVALID",
                    "error.validation.failed", "Unknown translation status");
        }
        entityId = entityId.trim();
        translations.upsert(entityType, entityId, field, target.code(),
                request.text().trim(), status);
        if ("DRAFT".equals(target.status())) {
            languages.setStatus(target.code(), "TRANSLATING");
        }
        audit.record(actor, "TRANSLATION_UPSERTED", entityType, entityId,
                null, Map.of("field", field, "language", target.code(), "status", status),
                null, http);
        return itemFor(entityType, entityId, field, target.code());
    }

    // ----------------------------------------------------------------- backlog

    @Transactional(readOnly = true)
    public LanguageBacklogDto backlog(String code) {
        LanguageDto language = requireLanguage(code);
        List<TranslationItemDto> all = requiredItems(language.code());
        Map<String, List<TranslationItemDto>> byType = new LinkedHashMap<>();
        for (String type : GROUP_ORDER) {
            byType.put(type, new ArrayList<>());
        }
        for (TranslationItemDto item : all) {
            byType.computeIfAbsent(item.entityType(), ignored -> new ArrayList<>()).add(item);
        }
        List<BacklogGroupDto> groups = new ArrayList<>();
        int approvedTotal = 0;
        for (Map.Entry<String, List<TranslationItemDto>> entry : byType.entrySet()) {
            int approved = (int) entry.getValue().stream()
                    .filter(item -> "APPROVED".equals(item.status())).count();
            approvedTotal += approved;
            groups.add(new BacklogGroupDto(entry.getKey(), entry.getValue().size(),
                    approved, List.copyOf(entry.getValue())));
        }
        return new LanguageBacklogDto(new LanguageRefDto(language.code(), language.status()),
                all.size(), approvedTotal, percent(approvedTotal, all.size()), groups);
    }

    @Transactional(readOnly = true)
    public LanguageCoverageDto coverage(String code) {
        LanguageDto language = requireLanguage(code);
        List<TranslationItemDto> all = requiredItems(language.code());
        Map<String, EntityCoverageDto> byEntity = new LinkedHashMap<>();
        int approvedTotal = 0;
        for (String type : GROUP_ORDER) {
            byEntity.put(type, new EntityCoverageDto(0, 0));
        }
        Map<String, List<TranslationItemDto>> grouped = new LinkedHashMap<>();
        for (TranslationItemDto item : all) {
            grouped.computeIfAbsent(item.entityType(), ignored -> new ArrayList<>()).add(item);
        }
        for (Map.Entry<String, List<TranslationItemDto>> entry : grouped.entrySet()) {
            int approved = (int) entry.getValue().stream()
                    .filter(item -> "APPROVED".equals(item.status())).count();
            approvedTotal += approved;
            byEntity.put(entry.getKey(),
                    new EntityCoverageDto(entry.getValue().size(), approved));
        }
        return new LanguageCoverageDto(language.code(), all.size(), approvedTotal,
                percent(approvedTotal, all.size()), byEntity);
    }

    @Transactional
    public PublishLanguageResultDto publish(CurrentUser actor, String code, HttpServletRequest http) {
        LanguageDto language = requireLanguage(code);
        LanguageCoverageDto coverage = coverage(language.code());
        if (coverage.totalRequired() > 0
                && coverage.approvedCount() < coverage.totalRequired()) {
            List<FieldIssue> missing = new ArrayList<>();
            for (Map.Entry<String, EntityCoverageDto> entry : coverage.byEntity().entrySet()) {
                int open = entry.getValue().total() - entry.getValue().approved();
                if (open > 0) {
                    missing.add(new FieldIssue(entry.getKey(), "TRANSLATION_REQUIRED",
                            "error.translation.required",
                            open + " " + entry.getKey() + " translation(s) missing",
                            null, "missing=" + open));
                }
            }
            throw ApiException.validation("TRANSLATION_REQUIRED",
                    "Language " + language.code() + " is not fully translated", missing);
        }
        languages.setLive(language.code());
        audit.record(actor, "LANGUAGE_PUBLISHED", "LANGUAGE", language.code(),
                Map.of("status", language.status()), Map.of("status", "LIVE"), null, http);
        return new PublishLanguageResultDto(language.code(), "LIVE", coverage.coveragePercent());
    }

    // ------------------------------------------------------------ required set

    private List<TranslationItemDto> requiredItems(String language) {
        List<TranslationItemDto> items = new ArrayList<>();
        String defaultLang = languages.defaultCode() == null ? "en" : languages.defaultCode();
        for (CategoryRow row : activeCategories()) {
            add(items, "CATEGORY", row.id(), row.code(), "name",
                    display(row.nameEn(), row.nameAr(), language, defaultLang), language);
        }
        for (ItemRow row : publishedItems()) {
            // ITEM overlays are keyed by the published version: a new draft that
            // changes labels must ship its own approved overlay before publishing.
            add(items, "ITEM", row.versionId(), row.code(), "label",
                    display(row.labelEn(), row.labelAr(), language, defaultLang), language);
            add(items, "ITEM", row.versionId(), row.code(), "instruction",
                    display(row.instructionEn(), row.instructionAr(), language, defaultLang), language);
        }
        for (NamedRow row : usedOptionSets()) {
            add(items, "OPTION_SET", row.id(), row.code(), "name",
                    display(row.nameEn(), row.nameAr(), language, defaultLang), language);
        }
        for (NamedRow row : usedOptionValues()) {
            add(items, "OPTION_VALUE", row.id(), row.code(), "label",
                    display(row.nameEn(), row.nameAr(), language, defaultLang), language);
        }
        for (TemplateRow row : activeTemplates()) {
            add(items, "TEMPLATE", row.id(), row.code(), "name",
                    display(row.nameEn(), row.nameAr(), language, defaultLang), language);
            add(items, "TEMPLATE", row.id(), row.code(), "description",
                    display(row.descriptionEn(), row.descriptionAr(), language, defaultLang), language);
        }
        for (NamedRow row : activeDocumentTypes()) {
            add(items, "DOCUMENT_TYPE", row.id(), row.code(), "name",
                    display(row.nameEn(), row.nameAr(), language, defaultLang), language);
        }
        for (NamedRow row : publishedIssueFields()) {
            add(items, "ISSUE_FIELD", row.id(), row.code(), "label",
                    display(row.nameEn(), row.nameAr(), language, defaultLang), language);
        }
        return items;
    }

    private void add(List<TranslationItemDto> items, String entityType, String entityId,
                     String entityCode, String field, String defaultText, String language) {
        if ("en".equals(language) || "ar".equals(language)) {
            boolean present = defaultText != null && !defaultText.isBlank();
            items.add(new TranslationItemDto(entityType, entityId, entityCode, field,
                    defaultText == null ? "" : defaultText,
                    present ? defaultText : null, present ? "APPROVED" : "MISSING"));
            return;
        }
        TranslationRepository.Overlay overlay =
                translations.find(entityType, entityId, field, language);
        items.add(new TranslationItemDto(entityType, entityId, entityCode, field,
                defaultText == null ? "" : defaultText,
                overlay == null ? null : overlay.text(),
                overlay == null ? "MISSING" : overlay.status()));
    }

    private TranslationItemDto itemFor(String entityType, String entityId, String field,
                                       String language) {
        String defaultLang = languages.defaultCode() == null ? "en" : languages.defaultCode();
        String[] base = baseText(entityType, entityId, field);
        TranslationRepository.Overlay overlay =
                translations.find(entityType, entityId, field, language);
        String code = entityCode(entityType, entityId);
        if ("en".equals(language) || "ar".equals(language)) {
            String text = display(base[0], base[1], language, defaultLang);
            boolean present = text != null && !text.isBlank();
            return new TranslationItemDto(entityType, entityId, code, field,
                    text == null ? "" : text, present ? text : null,
                    present ? "APPROVED" : "MISSING");
        }
        return new TranslationItemDto(entityType, entityId, code, field,
                display(base[0], base[1], language, defaultLang),
                overlay == null ? null : overlay.text(),
                overlay == null ? "MISSING" : overlay.status());
    }

    // ------------------------------------------------------------------ queries

    private record CategoryRow(String id, String code, String nameEn, String nameAr) {
    }

    private record ItemRow(String id, String versionId, String code, String labelEn, String labelAr,
                           String instructionEn, String instructionAr) {
    }

    private record NamedRow(String id, String code, String nameEn, String nameAr) {
    }

    private record TemplateRow(String id, String code, String nameEn, String nameAr,
                               String descriptionEn, String descriptionAr) {
    }

    private List<CategoryRow> activeCategories() {
        return jdbc.query("""
                SELECT id, code, name_en, name_ar FROM platform_categories
                WHERE status = 'ACTIVE' ORDER BY sort_order, code
                """, (rs, i) -> new CategoryRow(rs.getString("id"), rs.getString("code"),
                rs.getString("name_en"), rs.getString("name_ar")));
    }

    private List<ItemRow> publishedItems() {
        return jdbc.query("""
                SELECT i.id, v.id AS version_id, i.stable_code, v.label_en, v.label_ar,
                       v.instruction_en, v.instruction_ar
                FROM platform_items i
                JOIN platform_item_versions v ON v.id = i.current_published_version_id
                WHERE i.status = 'PUBLISHED'
                ORDER BY i.sort_order, i.stable_code
                """, (rs, i) -> new ItemRow(rs.getString("id"), rs.getString("version_id"),
                rs.getString("stable_code"),
                rs.getString("label_en"), rs.getString("label_ar"),
                rs.getString("instruction_en"), rs.getString("instruction_ar")));
    }

    private List<NamedRow> usedOptionSets() {
        return jdbc.query("""
                SELECT DISTINCT s.id, s.code, s.name_en, s.name_ar
                FROM platform_option_sets s
                WHERE s.status = 'ACTIVE'
                  AND EXISTS (
                    SELECT 1 FROM platform_issue_fields f
                    JOIN platform_item_versions v ON v.id = f.item_version_id
                    JOIN platform_items i ON i.id = v.item_id
                       AND i.current_published_version_id = v.id
                    WHERE i.status = 'PUBLISHED' AND v.status = 'PUBLISHED'
                      AND (f.option_set_id = s.id OR f.unit_set_id = s.id))
                ORDER BY s.code
                """, (rs, i) -> new NamedRow(rs.getString("id"), rs.getString("code"),
                rs.getString("name_en"), rs.getString("name_ar")));
    }

    private List<NamedRow> usedOptionValues() {
        return jdbc.query("""
                SELECT DISTINCT v.id, CONCAT(s.code, '.', v.code) AS code,
                       v.label_en, v.label_ar
                FROM platform_option_values v
                JOIN platform_option_sets s ON s.id = v.option_set_id
                WHERE v.status = 'ACTIVE'
                  AND EXISTS (
                    SELECT 1 FROM platform_issue_field_options fo
                    JOIN platform_issue_fields f ON f.id = fo.issue_field_id
                    JOIN platform_item_versions iv ON iv.id = f.item_version_id
                    JOIN platform_items i ON i.id = iv.item_id
                       AND i.current_published_version_id = iv.id
                    WHERE fo.option_value_id = v.id
                      AND i.status = 'PUBLISHED' AND iv.status = 'PUBLISHED')
                ORDER BY code
                """, (rs, i) -> new NamedRow(rs.getString("id"), rs.getString("code"),
                rs.getString("label_en"), rs.getString("label_ar")));
    }

    private List<TemplateRow> activeTemplates() {
        return jdbc.query("""
                SELECT id, code, name_en, name_ar, description_en, description_ar
                FROM platform_templates WHERE status = 'ACTIVE' ORDER BY code
                """, (rs, i) -> new TemplateRow(rs.getString("id"), rs.getString("code"),
                rs.getString("name_en"), rs.getString("name_ar"),
                rs.getString("description_en"), rs.getString("description_ar")));
    }

    private List<NamedRow> activeDocumentTypes() {
        return jdbc.query("""
                SELECT id, code, name_en, name_ar FROM platform_document_types
                WHERE status = 'ACTIVE' ORDER BY code
                """, (rs, i) -> new NamedRow(rs.getString("id"), rs.getString("code"),
                rs.getString("name_en"), rs.getString("name_ar")));
    }

    private List<NamedRow> publishedIssueFields() {
        return jdbc.query("""
                SELECT f.id, CONCAT(i.stable_code, '.', f.field_code) AS code,
                       f.label_en, f.label_ar
                FROM platform_issue_fields f
                JOIN platform_item_versions v ON v.id = f.item_version_id
                JOIN platform_items i ON i.id = v.item_id
                   AND i.current_published_version_id = v.id
                WHERE i.status = 'PUBLISHED' AND v.status = 'PUBLISHED'
                ORDER BY code
                """, (rs, i) -> new NamedRow(rs.getString("id"), rs.getString("code"),
                rs.getString("label_en"), rs.getString("label_ar")));
    }

    private boolean entityExists(String entityType, String entityId) {
        String sql = switch (entityType) {
            case "CATEGORY" -> "SELECT COUNT(*) FROM platform_categories WHERE id = ?";
            case "ITEM" -> "SELECT COUNT(*) FROM platform_item_versions WHERE id = ?";
            case "OPTION_SET" -> "SELECT COUNT(*) FROM platform_option_sets WHERE id = ?";
            case "OPTION_VALUE" -> "SELECT COUNT(*) FROM platform_option_values WHERE id = ?";
            case "TEMPLATE" -> "SELECT COUNT(*) FROM platform_templates WHERE id = ?";
            case "DOCUMENT_TYPE" -> "SELECT COUNT(*) FROM platform_document_types WHERE id = ?";
            case "ISSUE_FIELD" -> "SELECT COUNT(*) FROM platform_issue_fields WHERE id = ?";
            default -> null;
        };
        if (sql == null) {
            return false;
        }
        Integer count = jdbc.queryForObject(sql, Integer.class, entityId);
        return count != null && count > 0;
    }

    private String[] baseText(String entityType, String entityId, String field) {
        List<Map<String, Object>> rows = switch (entityType) {
            case "CATEGORY" -> jdbc.queryForList(
                    "SELECT name_en, name_ar FROM platform_categories WHERE id = ?", entityId);
            case "ITEM" -> "label".equals(field)
                    ? jdbc.queryForList("""
                    SELECT label_en AS name_en, label_ar AS name_ar
                    FROM platform_item_versions WHERE id = ?""", entityId)
                    : jdbc.queryForList("""
                    SELECT instruction_en AS name_en, instruction_ar AS name_ar
                    FROM platform_item_versions WHERE id = ?""", entityId);
            case "OPTION_SET" -> jdbc.queryForList(
                    "SELECT name_en, name_ar FROM platform_option_sets WHERE id = ?", entityId);
            case "OPTION_VALUE" -> jdbc.queryForList(
                    "SELECT label_en AS name_en, label_ar AS name_ar FROM platform_option_values WHERE id = ?",
                    entityId);
            case "TEMPLATE" -> "name".equals(field)
                    ? jdbc.queryForList(
                    "SELECT name_en, name_ar FROM platform_templates WHERE id = ?", entityId)
                    : jdbc.queryForList(
                    "SELECT description_en AS name_en, description_ar AS name_ar FROM platform_templates WHERE id = ?",
                    entityId);
            case "DOCUMENT_TYPE" -> jdbc.queryForList(
                    "SELECT name_en, name_ar FROM platform_document_types WHERE id = ?", entityId);
            case "ISSUE_FIELD" -> jdbc.queryForList(
                    "SELECT label_en AS name_en, label_ar AS name_ar FROM platform_issue_fields WHERE id = ?",
                    entityId);
            default -> List.of();
        };
        if (rows.isEmpty()) {
            return new String[]{"", ""};
        }
        Object en = rows.get(0).get("name_en");
        // H2 upper-cases unaliased labels only when not quoted; aliases above are lowercase.
        Object ar = rows.get(0).get("name_ar");
        if (en == null) {
            en = rows.get(0).get("NAME_EN");
        }
        if (ar == null) {
            ar = rows.get(0).get("NAME_AR");
        }
        return new String[]{en == null ? "" : en.toString(), ar == null ? "" : ar.toString()};
    }

    private String entityCode(String entityType, String entityId) {
        String sql = switch (entityType) {
            case "CATEGORY" -> "SELECT code FROM platform_categories WHERE id = ?";
            case "ITEM" -> """
                    SELECT i.stable_code FROM platform_item_versions v
                    JOIN platform_items i ON i.id = v.item_id WHERE v.id = ?""";
            case "OPTION_SET" -> "SELECT code FROM platform_option_sets WHERE id = ?";
            case "OPTION_VALUE" -> """
                    SELECT CONCAT(s.code, '.', v.code) FROM platform_option_values v
                    JOIN platform_option_sets s ON s.id = v.option_set_id WHERE v.id = ?""";
            case "TEMPLATE" -> "SELECT code FROM platform_templates WHERE id = ?";
            case "DOCUMENT_TYPE" -> "SELECT code FROM platform_document_types WHERE id = ?";
            case "ISSUE_FIELD" -> """
                    SELECT CONCAT(i.stable_code, '.', f.field_code)
                    FROM platform_issue_fields f
                    JOIN platform_item_versions v ON v.id = f.item_version_id
                    JOIN platform_items i ON i.id = v.item_id WHERE f.id = ?""";
            default -> null;
        };
        if (sql == null) {
            return entityId;
        }
        return jdbc.query(sql, (rs, i) -> rs.getString(1), entityId)
                .stream().findFirst().orElse(entityId);
    }

    // ----------------------------------------------------------------- helpers

    private LanguageDto requireLanguage(String code) {
        if (code == null || code.isBlank()) {
            throw validation("language", "LANGUAGE_REQUIRED", "error.validation.failed");
        }
        return languages.find(code.trim().toLowerCase(Locale.ROOT))
                .orElseThrow(() -> validation("language", "LANGUAGE_UNKNOWN", "error.locale.invalid"));
    }

    private static String upper(String value) {
        return value == null ? "" : value.trim().toUpperCase(Locale.ROOT);
    }

    private static String display(String en, String ar, String language, String defaultLang) {
        if ("ar".equals(language) || "ar".equals(defaultLang)) {
            if (ar != null && !ar.isBlank()) {
                return ar;
            }
        }
        if (en != null && !en.isBlank()) {
            return en;
        }
        return ar == null ? "" : ar;
    }

    private static int percent(int approved, int total) {
        if (total <= 0) {
            return 100;
        }
        return (int) Math.round(approved * 100.0 / total);
    }

    private static ApiException validation(String field, String code, String messageKey) {
        return ApiException.validation(code, "Invalid language request",
                List.of(FieldIssue.of(field, code, messageKey)));
    }
}
