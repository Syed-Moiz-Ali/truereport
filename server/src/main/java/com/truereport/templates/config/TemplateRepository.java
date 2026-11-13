package com.truereport.templates.config;

import com.truereport.localization.DynamicContentTranslations;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.uuid.UuidV7;
import com.truereport.templates.config.PlatformTemplateDtos.ChangeRequestDto;
import com.truereport.templates.config.PlatformTemplateDtos.TemplateCategoryDto;
import com.truereport.templates.config.PlatformTemplateDtos.TemplateCategoryRequest;
import com.truereport.templates.config.PlatformTemplateDtos.TemplateItemDto;
import com.truereport.templates.config.PlatformTemplateDtos.TemplateItemRequest;
import com.truereport.templates.config.PlatformTemplateDtos.TemplateSummaryDto;
import com.truereport.templates.config.PlatformTemplateDtos.TemplateVersionDto;
import com.truereport.templates.config.PlatformTemplateDtos.TemplateVersionSummaryDto;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

@Repository
public class TemplateRepository {

    private final JdbcTemplate jdbc;
    private final DynamicContentTranslations translations;

    public TemplateRepository(JdbcTemplate jdbc, DynamicContentTranslations translations) {
        this.jdbc = jdbc;
        this.translations = translations;
    }

    // --------------------------------------------------------------- templates

    public List<TemplateSummaryDto> findAll() {
        return findAll(false);
    }

    public List<TemplateSummaryDto> findAll(boolean publishedOnly) {
        List<TemplateRow> rows = jdbc.query("""
                SELECT id, code, name, description, status,
                       current_published_version_id
                FROM platform_templates
                WHERE (? = FALSE OR (status = 'ACTIVE'
                       AND current_published_version_id IS NOT NULL))
                ORDER BY code
                """, templateRowMapper(), publishedOnly);
        List<TemplateSummaryDto> result = new ArrayList<>(rows.size());
        for (TemplateRow row : rows) {
            result.add(toSummary(row));
        }
        return result;
    }

    public Optional<TemplateSummaryDto> findById(String id) {
        List<TemplateRow> rows = jdbc.query("""
                SELECT id, code, name, description, status,
                       current_published_version_id
                FROM platform_templates
                WHERE id = ?
                """, templateRowMapper(), id);
        if (rows.isEmpty()) {
            return Optional.empty();
        }
        TemplateSummaryDto base = toSummary(rows.get(0));
        String versionId = base.currentPublishedVersionId();
        if (versionId == null && !base.versions().isEmpty()) {
            versionId = base.versions().get(0).id();
        }
        List<TemplateCategoryDto> grouped = versionId == null
                ? List.of() : findVersion(base.id(), versionId)
                        .map(TemplateVersionDto::categories).orElse(List.of());
        return Optional.of(new TemplateSummaryDto(base.id(), base.code(), base.name(),
                base.description(), base.status(), base.currentPublishedVersionId(),
                base.versionCount(), base.currentVersionNo(), base.versions(), grouped,
                base.translations(), base.nameEn(), base.nameAr(),
                base.descriptionEn(), base.descriptionAr()));
    }

    public boolean codeExists(String code) {
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM platform_templates WHERE code = ?", Integer.class, code);
        return count != null && count > 0;
    }

    public String insertTemplate(String code, String name, String description,
                                 Map<String, Map<String, String>> fieldTranslations) {
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_templates
                    (id, code, name, description, status,
                     current_published_version_id, created_at, updated_at, version)
                VALUES (?, ?, ?, ?, 'ACTIVE', NULL,
                        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, id, code, name, description);
        translations.saveOverlays("TEMPLATE", id, fieldTranslations, "APPROVED");
        return id;
    }

    public void updateTemplate(String id, String name, String description,
                               Map<String, Map<String, String>> fieldTranslations) {
        jdbc.update("""
                UPDATE platform_templates
                SET name = COALESCE(?, name), description = COALESCE(?, description),
                    updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE id = ?
                """, name, description, id);
        translations.saveOverlays("TEMPLATE", id, fieldTranslations, "APPROVED");
    }

    public void retireTemplate(String id) {
        jdbc.update("""
                UPDATE platform_templates
                SET status = 'RETIRED', updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE id = ?
                """, id);
    }

    public void setCurrentPublishedVersion(String templateId, String versionId) {
        jdbc.update("""
                UPDATE platform_templates
                SET current_published_version_id = ?, updated_at = CURRENT_TIMESTAMP,
                    version = version + 1
                WHERE id = ?
                """, versionId, templateId);
    }

    public void setTemplateStatus(String templateId, String status) {
        jdbc.update("""
                UPDATE platform_templates
                SET status = ?, updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE id = ?
                """, status, templateId);
    }

    // ---------------------------------------------------------------- versions

    public List<TemplateVersionSummaryDto> versions(String templateId) {
        return jdbc.query("""
                SELECT id, version_no, status, published_at
                FROM platform_template_versions
                WHERE template_id = ?
                ORDER BY version_no DESC
                """, (rs, i) -> new TemplateVersionSummaryDto(
                rs.getString("id"), rs.getInt("version_no"), rs.getString("status"),
                timestampString(rs, "published_at")), templateId);
    }

    public Optional<TemplateVersionDto> findVersion(String templateId, String versionId) {
        List<VersionRow> rows = jdbc.query("""
                SELECT id, template_id, version_no, status, published_at, published_by
                FROM platform_template_versions
                WHERE id = ? AND template_id = ?
                """, versionRowMapper(), versionId, templateId);
        if (rows.isEmpty()) {
            return Optional.empty();
        }
        VersionRow row = rows.get(0);
        List<TemplateCategoryDto> categories = categories(row.id());
        int itemCount = categories.stream().mapToInt(TemplateCategoryDto::includedCount).sum();
        return Optional.of(new TemplateVersionDto(row.id(), row.templateId(), row.versionNo(),
                row.status(), row.publishedAt(), row.publishedBy(), categories.size(), itemCount,
                categories));
    }

    public Optional<VersionRow> findVersionRow(String versionId) {
        return jdbc.query("""
                SELECT id, template_id, version_no, status, published_at, published_by
                FROM platform_template_versions
                WHERE id = ?
                """, versionRowMapper(), versionId).stream().findFirst();
    }

    public Optional<VersionRow> findLatestVersion(String templateId) {
        return jdbc.query("""
                SELECT id, template_id, version_no, status, published_at, published_by
                FROM platform_template_versions
                WHERE template_id = ?
                ORDER BY version_no DESC
                """, versionRowMapper(), templateId).stream().findFirst();
    }

    public String insertVersion(String templateId, int versionNo, String status) {
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_template_versions
                    (id, template_id, version_no, status, published_at, published_by,
                     created_at, updated_at)
                VALUES (?, ?, ?, ?, NULL, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, id, templateId, versionNo, status);
        return id;
    }

    public void updateVersionStatus(String versionId, String status, String publishedBy) {
        if ("PUBLISHED".equals(status)) {
            jdbc.update("""
                    UPDATE platform_template_versions
                    SET status = ?, published_by = ?, published_at = CURRENT_TIMESTAMP,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE id = ?
                    """, status, publishedBy, versionId);
        } else {
            jdbc.update("""
                    UPDATE platform_template_versions
                    SET status = ?, published_by = ?, updated_at = CURRENT_TIMESTAMP
                    WHERE id = ?
                    """, status, publishedBy, versionId);
        }
    }

    public int latestVersionNo(String templateId) {
        Integer value = jdbc.queryForObject("""
                SELECT COALESCE(MAX(version_no), 0) FROM platform_template_versions
                WHERE template_id = ?
                """, Integer.class, templateId);
        return value == null ? 0 : value;
    }

    // -------------------------------------------------------------- categories

    public List<TemplateCategoryDto> categories(String templateVersionId) {
        List<TemplateItemDto> allItems = items(templateVersionId);
        Map<String, List<TemplateItemDto>> itemsByCategory = new LinkedHashMap<>();
        for (TemplateItemDto item : allItems) {
            itemsByCategory.computeIfAbsent(item.categoryId(), ignored -> new ArrayList<>())
                    .add(item);
        }
        return jdbc.query("""
                SELECT tc.category_id, tc.sort_order, tc.included,
                       c.code AS category_code, c.name AS category_name,
                       (SELECT COUNT(*) FROM platform_items i
                        WHERE i.category_id = tc.category_id AND i.status <> 'RETIRED') AS item_count
                FROM platform_template_categories tc
                JOIN platform_categories c ON c.id = tc.category_id
                WHERE tc.template_version_id = ?
                ORDER BY tc.sort_order, c.sort_order, c.code
                """, (rs, i) -> {
                    String categoryId = rs.getString("category_id");
                    List<TemplateItemDto> categoryItems = itemsByCategory
                            .getOrDefault(categoryId, List.of());
                    int includedCount = (int) categoryItems.stream()
                            .filter(TemplateItemDto::included).count();
                    String name = rs.getString("category_name");
                    Map<String, Map<String, String>> fields = translations.view(
                            "CATEGORY", categoryId, Map.of("name", name == null ? "" : name));
                    String nameAr = translations.resolve("CATEGORY", categoryId, "name", "ar",
                            name == null ? "" : name);
                    return new TemplateCategoryDto(
                            categoryId,
                            rs.getString("category_code"),
                            name,
                            rs.getInt("sort_order"),
                            rs.getInt("item_count"),
                            includedCount,
                            rs.getBoolean("included"),
                            categoryItems,
                            fields,
                            name,
                            nameAr);
                }, templateVersionId);
    }

    public void replaceCategories(String templateVersionId,
                                  List<TemplateCategoryRequest> requests) {
        List<TemplateCategoryRequest> rows = requests == null ? List.of() : requests;
        Set<String> categories = new HashSet<>();
        for (TemplateCategoryRequest request : rows) {
            if (request.categoryId() == null || request.categoryId().isBlank()) {
                throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                        "TEMPLATE_CATEGORY_REQUIRED", "error.template.categoryRequired",
                        "A category id is required for every template category");
            }
            if (!categories.add(request.categoryId())) {
                throw new ApiException(HttpStatus.CONFLICT, "DUPLICATE_TEMPLATE_CATEGORY",
                        "error.template.duplicateCategory",
                        "A category can only appear once in a template version");
            }
            if (!categoryExists(request.categoryId())) {
                throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                        "TEMPLATE_CATEGORY_NOT_FOUND", "error.template.categoryNotFound",
                        "Category " + request.categoryId() + " does not exist");
            }
        }

        jdbc.update("DELETE FROM platform_template_categories WHERE template_version_id = ?",
                templateVersionId);
        if (categories.isEmpty()) {
            jdbc.update("DELETE FROM platform_template_items WHERE template_version_id = ?",
                    templateVersionId);
            return;
        }

        int index = 0;
        for (TemplateCategoryRequest request : rows) {
            boolean included = request.included() == null || request.included();
            int sortOrder = request.sortOrder() == null ? index : request.sortOrder();
            jdbc.update("""
                    INSERT INTO platform_template_categories
                        (id, template_version_id, category_id, sort_order, included)
                    VALUES (?, ?, ?, ?, ?)
                    """, UuidV7.generate().toString(), templateVersionId,
                    request.categoryId(), sortOrder, included);
            index++;
        }

        String placeholders = String.join(",", java.util.Collections.nCopies(categories.size(), "?"));
        List<Object> args = new ArrayList<>();
        args.add(templateVersionId);
        args.addAll(categories);
        jdbc.update("""
                DELETE FROM platform_template_items
                WHERE template_version_id = ? AND category_id NOT IN (%s)
                """.formatted(placeholders), args.toArray());
    }

    // ------------------------------------------------------------------- items

    public List<TemplateItemDto> items(String templateVersionId) {
        return jdbc.query("""
                SELECT ti.id, ti.item_version_id, ti.sort_order, ti.included, ti.category_id,
                       v.item_id, v.label,
                       i.stable_code, i.status AS item_status
                FROM platform_template_items ti
                LEFT JOIN platform_item_versions v ON v.id = ti.item_version_id
                LEFT JOIN platform_items i ON i.id = v.item_id
                WHERE ti.template_version_id = ?
                ORDER BY ti.sort_order, i.sort_order, i.stable_code
                """, (rs, i) -> {
            String label = rs.getString("label");
            Map<String, Map<String, String>> fields = translations.view(
                    "ITEM", rs.getString("item_version_id"),
                    Map.of("label", label == null ? "" : label));
            String labelAr = translations.resolve("ITEM", rs.getString("item_version_id"),
                    "label", "ar", label == null ? "" : label);
            return new TemplateItemDto(
                    rs.getString("id"),
                    rs.getString("item_id"),
                    rs.getString("item_version_id"),
                    rs.getString("stable_code"),
                    label,
                    rs.getString("category_id"),
                    rs.getInt("sort_order"),
                    rs.getBoolean("included"),
                    rs.getString("item_status"),
                    fields,
                    label,
                    labelAr);
        }, templateVersionId);
    }

    public void replaceItems(String templateVersionId, List<TemplateItemRequest> requests) {
        List<TemplateItemRequest> rows = requests == null ? List.of() : requests;
        Map<String, String> itemCategories = new LinkedHashMap<>();
        Set<String> seen = new HashSet<>();
        for (TemplateItemRequest request : rows) {
            String itemVersionId = request.itemVersionId();
            if (itemVersionId == null || itemVersionId.isBlank()) {
                continue;
            }
            if (!seen.add(itemVersionId)) {
                throw new ApiException(HttpStatus.CONFLICT, "DUPLICATE_TEMPLATE_ITEM",
                        "error.template.duplicateItem",
                        "A master item version can only appear once in a template");
            }
            String categoryId = request.categoryId();
            if (categoryId == null || categoryId.isBlank()) {
                throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                        "TEMPLATE_ITEM_CATEGORY_REQUIRED", "error.template.itemCategoryRequired",
                        "Every template item must declare its category");
            }
            String masterCategory = itemVersionCategory(itemVersionId).orElseThrow(() ->
                    new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                            "ITEM_VERSION_NOT_FOUND", "error.template.itemVersionNotFound",
                            "Master item version " + itemVersionId + " does not exist"));
            if (!masterCategory.equals(categoryId)) {
                throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                        "ITEM_CATEGORY_MISMATCH", "error.template.itemCategoryMismatch",
                        "Item version " + itemVersionId + " does not belong to category "
                                + categoryId);
            }
            if (!categoryLinked(templateVersionId, categoryId)) {
                throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                        "TEMPLATE_CATEGORY_NOT_LINKED", "error.template.categoryNotLinked",
                        "Category " + categoryId + " is not included in this template version");
            }
            itemCategories.put(itemVersionId, categoryId);
        }

        jdbc.update("DELETE FROM platform_template_items WHERE template_version_id = ?",
                templateVersionId);
        int index = 0;
        for (TemplateItemRequest request : rows) {
            String itemVersionId = request.itemVersionId();
            if (itemVersionId == null || itemVersionId.isBlank()) {
                index++;
                continue;
            }
            boolean included = request.included() == null || request.included();
            int sortOrder = request.sortOrder() == null ? index : request.sortOrder();
            jdbc.update("""
                    INSERT INTO platform_template_items
                        (id, template_version_id, item_version_id, category_id, sort_order, included)
                    VALUES (?, ?, ?, ?, ?, ?)
                    """, UuidV7.generate().toString(), templateVersionId, itemVersionId,
                    itemCategories.get(itemVersionId), sortOrder, included);
            index++;
        }

        jdbc.update("""
                DELETE FROM platform_template_categories tc
                WHERE tc.template_version_id = ?
                  AND NOT EXISTS (
                      SELECT 1 FROM platform_template_items ti
                      WHERE ti.template_version_id = tc.template_version_id
                        AND ti.category_id = tc.category_id
                        AND ti.included = TRUE
                  )
                """, templateVersionId);
    }

    public void copyItems(String fromVersionId, String toVersionId) {
        List<CategoryRow> categories = jdbc.query("""
                SELECT category_id, sort_order, included
                FROM platform_template_categories
                WHERE template_version_id = ?
                ORDER BY sort_order
                """, (rs, i) -> new CategoryRow(rs.getString("category_id"),
                rs.getInt("sort_order"), rs.getBoolean("included")), fromVersionId);
        for (CategoryRow category : categories) {
            jdbc.update("""
                    INSERT INTO platform_template_categories
                        (id, template_version_id, category_id, sort_order, included)
                    VALUES (?, ?, ?, ?, ?)
                    """, UuidV7.generate().toString(), toVersionId, category.categoryId(),
                    category.sortOrder(), category.included());
        }
        List<ItemRow> rows = jdbc.query("""
                SELECT id, item_version_id, category_id, sort_order, included
                FROM platform_template_items
                WHERE template_version_id = ?
                ORDER BY sort_order, id
                """, itemRowMapper(), fromVersionId);
        for (ItemRow row : rows) {
            jdbc.update("""
                    INSERT INTO platform_template_items
                        (id, template_version_id, item_version_id, category_id, sort_order, included)
                    VALUES (?, ?, ?, ?, ?, ?)
                    """, UuidV7.generate().toString(), toVersionId, row.itemVersionId(),
                    row.categoryId(), row.sortOrder(), row.included());
        }
    }

    public int countItems(String templateVersionId) {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_template_items
                WHERE template_version_id = ? AND included = TRUE
                """, Integer.class, templateVersionId);
        return count == null ? 0 : count;
    }

    public int countCategories(String templateVersionId) {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_template_categories
                WHERE template_version_id = ? AND included = TRUE
                """, Integer.class, templateVersionId);
        return count == null ? 0 : count;
    }

    // --------------------------------------------------------- change requests

    public String createPendingChangeRequest(String entityType, String entityId, String actionCode,
                                             String payloadJson, String proposedBy) {
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_change_requests
                    (id, entity_type, entity_id, action_code, payload_json, status,
                     proposed_by, proposed_at)
                VALUES (?, ?, ?, ?, ?, 'PENDING', ?, CURRENT_TIMESTAMP)
                """, id, entityType, entityId, actionCode, payloadJson, proposedBy);
        return id;
    }

    public Optional<ChangeRequestDto> findPendingChangeRequest(String entityType, String entityId) {
        return jdbc.query("""
                SELECT id, entity_type, entity_id, action_code, status, proposed_by
                FROM platform_change_requests
                WHERE entity_type = ? AND entity_id = ? AND status = 'PENDING'
                ORDER BY proposed_at DESC
                """, (rs, i) -> new ChangeRequestDto(
                rs.getString("id"), rs.getString("entity_type"), rs.getString("entity_id"),
                rs.getString("action_code"), rs.getString("status"), rs.getString("proposed_by")),
                entityType, entityId).stream().findFirst();
    }

    public void approveChangeRequest(String requestId, String decidedBy) {
        jdbc.update("""
                UPDATE platform_change_requests
                SET status = 'APPROVED', decided_by = ?, decided_at = CURRENT_TIMESTAMP
                WHERE id = ?
                """, decidedBy, requestId);
    }

    public void rejectChangeRequest(String requestId, String decidedBy, String reason) {
        jdbc.update("""
                UPDATE platform_change_requests
                SET status = 'REJECTED', decided_by = ?, decided_at = CURRENT_TIMESTAMP,
                    reason = ?
                WHERE id = ?
                """, decidedBy, reason, requestId);
    }

    // ----------------------------------------------------------------- helpers

    private TemplateSummaryDto toSummary(TemplateRow row) {
        List<TemplateVersionSummaryDto> versions = versions(row.id());
        Integer currentVersionNo = null;
        if (row.currentPublishedVersionId() != null) {
            for (TemplateVersionSummaryDto version : versions) {
                if (row.currentPublishedVersionId().equals(version.id())) {
                    currentVersionNo = version.versionNo();
                    break;
                }
            }
        }
        if (currentVersionNo == null && !versions.isEmpty()) {
            currentVersionNo = versions.get(0).versionNo();
        }
        return new TemplateSummaryDto(row.id(), row.code(), row.name(),
                row.description(), row.status(), row.currentPublishedVersionId(),
                versions.size(), currentVersionNo, versions, List.of(),
                templateTranslations(row), row.name(), row.nameAr(),
                row.description(), row.descriptionAr());
    }

    private Map<String, Map<String, String>> templateTranslations(TemplateRow row) {
        return translations.view("TEMPLATE", row.id(), Map.of(
                "name", row.name() == null ? "" : row.name(),
                "description", row.description() == null ? "" : row.description()));
    }

    private boolean categoryExists(String categoryId) {
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM platform_categories WHERE id = ?", Integer.class, categoryId);
        return count != null && count > 0;
    }

    private boolean categoryLinked(String templateVersionId, String categoryId) {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_template_categories
                WHERE template_version_id = ? AND category_id = ? AND included = TRUE
                """, Integer.class, templateVersionId, categoryId);
        return count != null && count > 0;
    }

    private Optional<String> itemVersionCategory(String itemVersionId) {
        return jdbc.query("""
                SELECT i.category_id
                FROM platform_item_versions v
                JOIN platform_items i ON i.id = v.item_id
                WHERE v.id = ?
                """, (rs, i) -> rs.getString(1), itemVersionId).stream().findFirst();
    }

    private static String timestampString(ResultSet rs, String column) throws SQLException {
        Timestamp value = rs.getTimestamp(column);
        return value == null ? null : value.toLocalDateTime().toString();
    }

    private RowMapper<TemplateRow> templateRowMapper() {
        return (rs, i) -> {
            String id = rs.getString("id");
            String name = rs.getString("name");
            String description = rs.getString("description");
            String nameAr = translations.resolve("TEMPLATE", id, "name", "ar",
                    name == null ? "" : name);
            String descriptionAr = translations.resolve("TEMPLATE", id, "description", "ar",
                    description == null ? "" : description);
            return new TemplateRow(id, rs.getString("code"), name, description, nameAr,
                    descriptionAr, rs.getString("status"),
                    rs.getString("current_published_version_id"));
        };
    }

    private RowMapper<VersionRow> versionRowMapper() {
        return (rs, i) -> new VersionRow(
                rs.getString("id"),
                rs.getString("template_id"),
                rs.getInt("version_no"),
                rs.getString("status"),
                timestampString(rs, "published_at"),
                rs.getString("published_by"));
    }

    private RowMapper<ItemRow> itemRowMapper() {
        return (rs, i) -> new ItemRow(
                rs.getString("id"),
                rs.getString("item_version_id"),
                rs.getString("category_id"),
                rs.getInt("sort_order"),
                rs.getBoolean("included"));
    }

    public record VersionRow(
            String id,
            String templateId,
            int versionNo,
            String status,
            String publishedAt,
            String publishedBy
    ) {
    }

    private record TemplateRow(
            String id,
            String code,
            String name,
            String description,
            String nameAr,
            String descriptionAr,
            String status,
            String currentPublishedVersionId
    ) {
    }

    private record CategoryRow(
            String categoryId,
            int sortOrder,
            boolean included
    ) {
    }

    private record ItemRow(
            String id,
            String itemVersionId,
            String categoryId,
            int sortOrder,
            boolean included
    ) {
    }
}


