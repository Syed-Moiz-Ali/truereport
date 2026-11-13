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
import com.truereport.uimessages.api.UiMessagePublishGuard;
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
 * Translation workspace and language readiness.
 *
 * <p>Two distinct scopes are intentional:</p>
 * <ul>
 *   <li>{@link Scope#TRANSLATION} covers every non-retired source record,
 *   including DRAFT categories/options/document types, the latest draft item
 *   version, and its issue fields. This is what the workspace edits and what
 *   Google generation translates.</li>
 *   <li>{@link Scope#READINESS} covers only content that is currently visible:
 *   ACTIVE categories/options/document types, published item versions, and
 *   their issue fields. This is what can block a language from going LIVE.</li>
 * </ul>
 */
@Service
public class TranslationBacklogService {

    public enum Scope {
        TRANSLATION,
        READINESS
    }

    public static final Set<String> ENTITY_TYPES =
            Set.copyOf(TranslationFieldRegistry.GROUP_ORDER);

    private static final Set<String> TRANSLATION_STATUSES = Set.of(
            "DRAFT", "TRANSLATING", "REVIEWED", "APPROVED");

    private static final Map<String, List<String>> FIELDS = TranslationFieldRegistry.FIELDS;

    private static final List<String> GROUP_ORDER = TranslationFieldRegistry.GROUP_ORDER;

    private final JdbcTemplate jdbc;
    private final LanguageRepository languages;
    private final TranslationRepository translations;
    private final FieldAuditService audit;
    private final UiMessagePublishGuard uiMessageGuard;

    public TranslationBacklogService(JdbcTemplate jdbc, LanguageRepository languages,
                                     TranslationRepository translations, FieldAuditService audit,
                                     UiMessagePublishGuard uiMessageGuard) {
        this.jdbc = jdbc;
        this.languages = languages;
        this.translations = translations;
        this.audit = audit;
        this.uiMessageGuard = uiMessageGuard;
    }

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
        String defaultCode = languages.defaultCode() == null ? "en" : languages.defaultCode();
        if (target.code().equals(defaultCode)) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "TRANSLATION_SOURCE_INVALID",
                    "error.validation.failed",
                    "The default language is the source and cannot be overlaid");
        }
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

    /** Full workspace backlog: includes DRAFT and unpublished content. */
    @Transactional(readOnly = true)
    public LanguageBacklogDto backlog(String code) {
        LanguageDto language = requireLanguage(code);
        List<TranslationItemDto> all = requiredItems(language.code(), Scope.TRANSLATION);
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

    /** Language readiness: only LIVE/ACTIVE/published content counts. */
    @Transactional(readOnly = true)
    public LanguageCoverageDto coverage(String code) {
        LanguageDto language = requireLanguage(code);
        List<TranslationItemDto> all = requiredItems(language.code(), Scope.READINESS);
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
        String defaultCode = languages.defaultCode();
        LanguageDto defaultLanguage =
                defaultCode == null ? null : languages.find(defaultCode).orElse(null);
        uiMessageGuard.requirePublishable(language.code(), language.uiMessagesPath(),
                defaultLanguage == null ? null : defaultLanguage.uiMessagesPath());
        languages.setLive(language.code());
        audit.record(actor, "LANGUAGE_PUBLISHED", "LANGUAGE", language.code(),
                Map.of("status", language.status()), Map.of("status", "LIVE"), null, http);
        return new PublishLanguageResultDto(language.code(), "LIVE", coverage.coveragePercent());
    }

    // ------------------------------------------------------------ required set

    private List<TranslationItemDto> requiredItems(String language, Scope scope) {
        List<TranslationItemDto> items = new ArrayList<>();
        String defaultLang = languages.defaultCode() == null ? "en" : languages.defaultCode();
        for (CategoryRow row : categories(scope)) {
            add(items, "CATEGORY", row.id(), row.code(), "name", row.name(),
                    language, defaultLang, row.status());
        }
        for (ItemRow row : items(scope)) {
            add(items, "ITEM", row.versionId(), row.code(), "label", row.label(),
                    language, defaultLang, row.status());
            add(items, "ITEM", row.versionId(), row.code(), "instruction", row.instruction(),
                    language, defaultLang, row.status());
            if (hasText(row.standardSpec())) {
                add(items, "ITEM", row.versionId(), row.code(), "standardSpec", row.standardSpec(),
                        language, defaultLang, row.status());
            }
        }
        for (NamedRow row : optionSets(scope)) {
            add(items, "OPTION_SET", row.id(), row.code(), "name", row.name(),
                    language, defaultLang, row.status());
        }
        for (NamedRow row : optionValues(scope)) {
            add(items, "OPTION_VALUE", row.id(), row.code(), "label", row.name(),
                    language, defaultLang, row.status());
        }
        for (TemplateRow row : templates(scope)) {
            add(items, "TEMPLATE", row.id(), row.code(), "name", row.name(),
                    language, defaultLang, row.status());
            if (hasText(row.description())) {
                add(items, "TEMPLATE", row.id(), row.code(), "description", row.description(),
                        language, defaultLang, row.status());
            }
        }
        for (NamedRow row : documentTypes(scope)) {
            add(items, "DOCUMENT_TYPE", row.id(), row.code(), "name", row.name(),
                    language, defaultLang, row.status());
        }
        for (NamedRow row : issueFields(scope)) {
            add(items, "ISSUE_FIELD", row.id(), row.code(), "label", row.name(),
                    language, defaultLang, row.status());
        }
        return items;
    }

    private void add(List<TranslationItemDto> items, String entityType, String entityId,
                     String entityCode, String field, String sourceText,
                     String language, String defaultLang, String contentStatus) {
        if (language.equals(defaultLang)) {
            boolean present = sourceText != null && !sourceText.isBlank();
            items.add(new TranslationItemDto(entityType, entityId, entityCode, field,
                    sourceText == null ? "" : sourceText,
                    present ? sourceText : null, present ? "APPROVED" : "MISSING",
                    contentStatus));
            return;
        }
        TranslationRepository.Overlay overlay =
                translations.find(entityType, entityId, field, language);
        items.add(new TranslationItemDto(entityType, entityId, entityCode, field,
                sourceText == null ? "" : sourceText,
                overlay == null ? null : overlay.text(),
                overlay == null ? "MISSING" : overlay.status(), contentStatus));
    }

    private TranslationItemDto itemFor(String entityType, String entityId, String field,
                                       String language) {
        String defaultLang = languages.defaultCode() == null ? "en" : languages.defaultCode();
        String source = sourceText(entityType, entityId, field);
        String code = entityCode(entityType, entityId);
        String contentStatus = contentStatus(entityType, entityId);
        if (language.equals(defaultLang)) {
            boolean present = source != null && !source.isBlank();
            return new TranslationItemDto(entityType, entityId, code, field,
                    source == null ? "" : source, present ? source : null,
                    present ? "APPROVED" : "MISSING", contentStatus);
        }
        TranslationRepository.Overlay overlay =
                translations.find(entityType, entityId, field, language);
        return new TranslationItemDto(entityType, entityId, code, field,
                source == null ? "" : source,
                overlay == null ? null : overlay.text(),
                overlay == null ? "MISSING" : overlay.status(), contentStatus);
    }

    // ------------------------------------------------------------------ queries

    private record CategoryRow(String id, String code, String name, String status) {
    }

    private record ItemRow(String id, String versionId, String code, String label,
                           String instruction, String standardSpec, String status) {
    }

    private record NamedRow(String id, String code, String name, String status) {
    }

    private record TemplateRow(String id, String code, String name, String description,
                               String status) {
    }

    private List<CategoryRow> categories(Scope scope) {
        String filter = scope == Scope.TRANSLATION ? "status <> 'RETIRED'" : "status = 'ACTIVE'";
        return jdbc.query("SELECT id, code, name, status FROM platform_categories WHERE "
                        + filter + " ORDER BY sort_order, code",
                (rs, i) -> new CategoryRow(rs.getString("id"), rs.getString("code"),
                        rs.getString("name"), rs.getString("status")));
    }

    private List<ItemRow> items(Scope scope) {
        if (scope == Scope.TRANSLATION) {
            return jdbc.query("""
                    SELECT i.id, v.id AS version_id, i.stable_code, v.label, v.instruction,
                           v.standard_spec, v.status
                    FROM platform_items i
                    JOIN platform_item_versions v ON v.item_id = i.id
                    WHERE i.status <> 'RETIRED'
                      AND (v.id = i.current_published_version_id
                        OR v.version_no = (
                            SELECT MAX(v2.version_no) FROM platform_item_versions v2
                            WHERE v2.item_id = i.id))
                    ORDER BY i.sort_order, i.stable_code, v.version_no DESC
                    """, (rs, i) -> new ItemRow(rs.getString("id"), rs.getString("version_id"),
                    rs.getString("stable_code"), rs.getString("label"),
                    rs.getString("instruction"), rs.getString("standard_spec"),
                    rs.getString("status")));
        }
        return jdbc.query("""
                SELECT i.id, v.id AS version_id, i.stable_code, v.label, v.instruction,
                       v.standard_spec, v.status
                FROM platform_items i
                JOIN platform_item_versions v ON v.id = i.current_published_version_id
                WHERE i.status = 'PUBLISHED'
                ORDER BY i.sort_order, i.stable_code
                """, (rs, i) -> new ItemRow(rs.getString("id"), rs.getString("version_id"),
                rs.getString("stable_code"), rs.getString("label"), rs.getString("instruction"),
                rs.getString("standard_spec"), rs.getString("status")));
    }

    private List<NamedRow> optionSets(Scope scope) {
        String filter = scope == Scope.TRANSLATION ? "status <> 'RETIRED'" : "status = 'ACTIVE'";
        return jdbc.query("SELECT id, code, name, status FROM platform_option_sets WHERE "
                        + filter + " ORDER BY code",
                (rs, i) -> new NamedRow(rs.getString("id"), rs.getString("code"),
                        rs.getString("name"), rs.getString("status")));
    }

    private List<NamedRow> optionValues(Scope scope) {
        String filter = scope == Scope.TRANSLATION
                ? "v.status <> 'RETIRED' AND s.status <> 'RETIRED'"
                : "v.status = 'ACTIVE' AND s.status = 'ACTIVE'";
        return jdbc.query("""
                SELECT v.id, CONCAT(s.code, '.', v.code) AS code, v.label, v.status
                FROM platform_option_values v
                JOIN platform_option_sets s ON s.id = v.option_set_id
                WHERE %s
                ORDER BY code
                """.formatted(filter), (rs, i) -> new NamedRow(rs.getString("id"),
                rs.getString("code"), rs.getString("label"), rs.getString("status")));
    }

    private List<TemplateRow> templates(Scope scope) {
        if (scope == Scope.TRANSLATION) {
            return jdbc.query("""
                    SELECT id, code, name, description,
                           CASE WHEN current_published_version_id IS NULL
                                THEN 'DRAFT' ELSE status END AS content_status
                    FROM platform_templates WHERE status <> 'RETIRED' ORDER BY code
                    """, (rs, i) -> new TemplateRow(rs.getString("id"), rs.getString("code"),
                    rs.getString("name"), rs.getString("description"),
                    rs.getString("content_status")));
        }
        return jdbc.query("""
                SELECT id, code, name, description, status
                FROM platform_templates
                WHERE status = 'ACTIVE' AND current_published_version_id IS NOT NULL
                ORDER BY code
                """, (rs, i) -> new TemplateRow(rs.getString("id"), rs.getString("code"),
                rs.getString("name"), rs.getString("description"), rs.getString("status")));
    }

    private List<NamedRow> documentTypes(Scope scope) {
        String filter = scope == Scope.TRANSLATION ? "status <> 'RETIRED'" : "status = 'ACTIVE'";
        return jdbc.query("SELECT id, code, name, status FROM platform_document_types WHERE "
                        + filter + " ORDER BY code",
                (rs, i) -> new NamedRow(rs.getString("id"), rs.getString("code"),
                        rs.getString("name"), rs.getString("status")));
    }

    private List<NamedRow> issueFields(Scope scope) {
        if (scope == Scope.TRANSLATION) {
            return jdbc.query("""
                    SELECT f.id, CONCAT(i.stable_code, '.', f.field_code) AS code, f.label,
                           v.status
                    FROM platform_issue_fields f
                    JOIN platform_item_versions v ON v.id = f.item_version_id
                    JOIN platform_items i ON i.id = v.item_id
                    WHERE i.status <> 'RETIRED'
                      AND (v.id = i.current_published_version_id
                        OR v.version_no = (
                            SELECT MAX(v2.version_no) FROM platform_item_versions v2
                            WHERE v2.item_id = i.id))
                    ORDER BY code
                    """, (rs, i) -> new NamedRow(rs.getString("id"), rs.getString("code"),
                    rs.getString("label"), rs.getString("status")));
        }
        return jdbc.query("""
                SELECT f.id, CONCAT(i.stable_code, '.', f.field_code) AS code, f.label, v.status
                FROM platform_issue_fields f
                JOIN platform_item_versions v ON v.id = f.item_version_id
                JOIN platform_items i ON i.id = v.item_id
                   AND i.current_published_version_id = v.id
                WHERE i.status = 'PUBLISHED' AND v.status = 'PUBLISHED'
                ORDER BY code
                """, (rs, i) -> new NamedRow(rs.getString("id"), rs.getString("code"),
                rs.getString("label"), rs.getString("status")));
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

    private String contentStatus(String entityType, String entityId) {
        String sql = switch (entityType) {
            case "CATEGORY" -> "SELECT status FROM platform_categories WHERE id = ?";
            case "ITEM" -> "SELECT status FROM platform_item_versions WHERE id = ?";
            case "OPTION_SET" -> "SELECT status FROM platform_option_sets WHERE id = ?";
            case "OPTION_VALUE" -> "SELECT status FROM platform_option_values WHERE id = ?";
            case "TEMPLATE" -> """
                    SELECT CASE
                             WHEN current_published_version_id IS NULL THEN 'DRAFT'
                             ELSE status
                           END
                    FROM platform_templates WHERE id = ?""";
            case "DOCUMENT_TYPE" -> "SELECT status FROM platform_document_types WHERE id = ?";
            case "ISSUE_FIELD" -> """
                    SELECT v.status FROM platform_issue_fields f
                    JOIN platform_item_versions v ON v.id = f.item_version_id
                    WHERE f.id = ?""";
            default -> null;
        };
        if (sql == null) {
            return "";
        }
        return jdbc.query(sql, (rs, i) -> rs.getString(1), entityId)
                .stream().findFirst().orElse("");
    }

    private String sourceText(String entityType, String entityId, String field) {
        List<String> rows = switch (entityType) {
            case "CATEGORY" -> jdbc.query("SELECT name FROM platform_categories WHERE id = ?",
                    (rs, i) -> rs.getString(1), entityId);
            case "ITEM" -> jdbc.query("SELECT "
                            + switch (field) {
                                case "label" -> "label";
                                case "standardSpec" -> "standard_spec";
                                default -> "instruction";
                            }
                            + " FROM platform_item_versions WHERE id = ?",
                    (rs, i) -> rs.getString(1), entityId);
            case "OPTION_SET" -> jdbc.query("SELECT name FROM platform_option_sets WHERE id = ?",
                    (rs, i) -> rs.getString(1), entityId);
            case "OPTION_VALUE" -> jdbc.query("SELECT label FROM platform_option_values WHERE id = ?",
                    (rs, i) -> rs.getString(1), entityId);
            case "TEMPLATE" -> jdbc.query("SELECT " + ("name".equals(field) ? "name" : "description")
                            + " FROM platform_templates WHERE id = ?",
                    (rs, i) -> rs.getString(1), entityId);
            case "DOCUMENT_TYPE" -> jdbc.query("SELECT name FROM platform_document_types WHERE id = ?",
                    (rs, i) -> rs.getString(1), entityId);
            case "ISSUE_FIELD" -> jdbc.query("SELECT label FROM platform_issue_fields WHERE id = ?",
                    (rs, i) -> rs.getString(1), entityId);
            default -> List.of();
        };
        return rows.isEmpty() || rows.get(0) == null ? "" : rows.get(0);
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

    private static boolean hasText(String value) {
        return value != null && !value.isBlank();
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
