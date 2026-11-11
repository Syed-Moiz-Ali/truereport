package com.truereport.templates.config;

import com.truereport.shared.error.ApiException;
import com.truereport.shared.uuid.UuidV7;
import com.truereport.templates.config.PlatformTemplateDtos.ChangeRequestDto;
import com.truereport.templates.config.PlatformTemplateDtos.TemplateItemDto;
import com.truereport.templates.config.PlatformTemplateDtos.TemplateItemRequest;
import com.truereport.templates.config.PlatformTemplateDtos.TemplateSummaryDto;
import com.truereport.templates.config.PlatformTemplateDtos.TemplateVersionDto;
import com.truereport.templates.config.PlatformTemplateDtos.TemplateVersionSummaryDto;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

@Repository
public class TemplateRepository {

    private final JdbcTemplate jdbc;

    public TemplateRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    // --------------------------------------------------------------- templates

    public List<TemplateSummaryDto> findAll() {
        List<TemplateRow> rows = jdbc.query("""
                SELECT id, code, name_en, name_ar, description_en, description_ar, status,
                       current_published_version_id
                FROM platform_templates
                ORDER BY code
                """, templateRowMapper());
        List<TemplateSummaryDto> result = new ArrayList<>(rows.size());
        for (TemplateRow row : rows) {
            result.add(toSummary(row));
        }
        return result;
    }

    public Optional<TemplateSummaryDto> findById(String id) {
        List<TemplateRow> rows = jdbc.query("""
                SELECT id, code, name_en, name_ar, description_en, description_ar, status,
                       current_published_version_id
                FROM platform_templates
                WHERE id = ?
                """, templateRowMapper(), id);
        return rows.isEmpty() ? Optional.empty() : Optional.of(toSummary(rows.get(0)));
    }

    public boolean codeExists(String code) {
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM platform_templates WHERE code = ?", Integer.class, code);
        return count != null && count > 0;
    }

    public String insertTemplate(String code, String nameEn, String nameAr,
                                 String descriptionEn, String descriptionAr) {
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_templates
                    (id, code, name_en, name_ar, description_en, description_ar, status,
                     current_published_version_id, created_at, updated_at, version)
                VALUES (?, ?, ?, ?, ?, ?, 'ACTIVE', NULL,
                        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, id, code, nameEn, nameAr, descriptionEn, descriptionAr);
        return id;
    }

    public void updateTemplate(String id, String nameEn, String nameAr,
                               String descriptionEn, String descriptionAr) {
        jdbc.update("""
                UPDATE platform_templates
                SET name_en = ?, name_ar = ?, description_en = ?, description_ar = ?,
                    updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE id = ?
                """, nameEn, nameAr, descriptionEn, descriptionAr, id);
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
        return Optional.of(new TemplateVersionDto(row.id(), row.templateId(), row.versionNo(),
                row.status(), row.publishedAt(), row.publishedBy(), items(row.id())));
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

    // ------------------------------------------------------------------- items

    public List<TemplateItemDto> items(String templateVersionId) {
        return jdbc.query("""
                SELECT ti.id, ti.item_version_id, ti.sort_order, ti.included, ti.item_weight,
                       v.item_id, v.label_en, v.label_ar, v.status AS version_status,
                       i.stable_code, i.status AS item_status, i.category_id, i.sort_order AS item_sort,
                       c.code AS category_code, c.name_en AS category_name_en,
                       c.name_ar AS category_name_ar
                FROM platform_template_items ti
                LEFT JOIN platform_item_versions v ON v.id = ti.item_version_id
                LEFT JOIN platform_items i ON i.id = v.item_id
                LEFT JOIN platform_categories c ON c.id = i.category_id
                WHERE ti.template_version_id = ?
                ORDER BY ti.sort_order, i.sort_order, i.stable_code
                """, (rs, i) -> new TemplateItemDto(
                rs.getString("id"),
                rs.getString("item_id"),
                rs.getString("item_version_id"),
                rs.getString("stable_code"),
                rs.getString("label_en"),
                rs.getString("label_ar"),
                rs.getString("category_id"),
                rs.getString("category_code"),
                rs.getString("category_name_en"),
                rs.getString("category_name_ar"),
                rs.getBigDecimal("item_weight"),
                rs.getInt("sort_order"),
                rs.getBoolean("included"),
                rs.getString("item_status")), templateVersionId);
    }

    public void replaceItems(String templateVersionId, List<TemplateItemRequest> requests) {
        jdbc.update("DELETE FROM platform_template_items WHERE template_version_id = ?",
                templateVersionId);
        if (requests == null) {
            return;
        }
        int index = 0;
        Set<String> seen = new HashSet<>();
        for (TemplateItemRequest request : requests) {
            boolean included = request.included() == null || request.included();
            String itemVersionId = request.itemVersionId();
            if (itemVersionId == null || itemVersionId.isBlank()) {
                if (included) {
                    throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "ITEM_VERSION_REQUIRED",
                            "error.template.itemVersionRequired",
                            "An item version id is required for every included template item");
                }
                index++;
                continue;
            }
            if (!seen.add(itemVersionId)) {
                throw new ApiException(HttpStatus.CONFLICT, "DUPLICATE_TEMPLATE_ITEM",
                        "error.template.duplicateItem",
                        "A master item version can only appear once in a template");
            }
            if (!itemVersionExists(itemVersionId)) {
                throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "ITEM_VERSION_NOT_FOUND",
                        "error.template.itemVersionNotFound",
                        "Master item version " + itemVersionId + " does not exist");
            }
            int sortOrder = request.sortOrder() == null ? index : request.sortOrder();
            jdbc.update("""
                    INSERT INTO platform_template_items
                        (id, template_version_id, item_version_id, sort_order, included, item_weight)
                    VALUES (?, ?, ?, ?, ?, ?)
                    """, UuidV7.generate().toString(), templateVersionId, itemVersionId,
                    sortOrder, included, request.itemWeight());
            index++;
        }
    }

    public void copyItems(String fromVersionId, String toVersionId) {
        List<ItemRow> rows = jdbc.query("""
                SELECT id, item_version_id, sort_order, included, item_weight
                FROM platform_template_items
                WHERE template_version_id = ?
                ORDER BY sort_order, id
                """, itemRowMapper(), fromVersionId);
        for (ItemRow row : rows) {
            jdbc.update("""
                    INSERT INTO platform_template_items
                        (id, template_version_id, item_version_id, sort_order, included, item_weight)
                    VALUES (?, ?, ?, ?, ?, ?)
                    """, UuidV7.generate().toString(), toVersionId, row.itemVersionId(),
                    row.sortOrder(), row.included(), row.itemWeight());
        }
    }

    public int countItems(String templateVersionId) {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_template_items WHERE template_version_id = ?
                """, Integer.class, templateVersionId);
        return count == null ? 0 : count;
    }

    public BigDecimal categoryWeight(String categoryId) {
        if (categoryId == null || categoryId.isBlank()) {
            return BigDecimal.ZERO;
        }
        return jdbc.query("""
                SELECT weight_percentage FROM platform_categories WHERE id = ?
                """, (rs, i) -> rs.getBigDecimal(1), categoryId).stream().findFirst()
                .orElse(BigDecimal.ZERO);
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
        return new TemplateSummaryDto(row.id(), row.code(), row.nameEn(), row.nameAr(),
                row.descriptionEn(), row.descriptionAr(), row.status(), row.currentPublishedVersionId(),
                versions.size(), currentVersionNo, versions);
    }

    private boolean itemVersionExists(String itemVersionId) {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_item_versions WHERE id = ?
                """, Integer.class, itemVersionId);
        return count != null && count > 0;
    }

    private static String timestampString(ResultSet rs, String column) throws SQLException {
        Timestamp value = rs.getTimestamp(column);
        return value == null ? null : value.toLocalDateTime().toString();
    }

    private RowMapper<TemplateRow> templateRowMapper() {
        return (rs, i) -> new TemplateRow(
                rs.getString("id"),
                rs.getString("code"),
                rs.getString("name_en"),
                rs.getString("name_ar"),
                rs.getString("description_en"),
                rs.getString("description_ar"),
                rs.getString("status"),
                rs.getString("current_published_version_id"));
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
                rs.getInt("sort_order"),
                rs.getBoolean("included"),
                rs.getBigDecimal("item_weight"));
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
            String nameEn,
            String nameAr,
            String descriptionEn,
            String descriptionAr,
            String status,
            String currentPublishedVersionId
    ) {
    }

    private record ItemRow(
            String id,
            String itemVersionId,
            int sortOrder,
            boolean included,
            BigDecimal itemWeight
    ) {
    }
}
