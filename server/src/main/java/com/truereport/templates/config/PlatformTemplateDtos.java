package com.truereport.templates.config;

import java.util.List;
import java.util.Map;

public final class PlatformTemplateDtos {

    private PlatformTemplateDtos() {
    }

    public record TemplateSummaryDto(
            String id,
            String code,
            String name,
            String description,
            String status,
            String currentPublishedVersionId,
            int versionCount,
            Integer currentVersionNo,
            List<TemplateVersionSummaryDto> versions,
            List<TemplateCategoryDto> categories,
            Map<String, Map<String, String>> translations,
            String nameEn,
            String nameAr,
            String descriptionEn,
            String descriptionAr
    ) {
    }

    public record TemplateVersionSummaryDto(
            String id,
            int versionNo,
            String status,
            String publishedAt
    ) {
    }

    public record TemplateVersionDto(
            String id,
            String templateId,
            int versionNo,
            String status,
            String publishedAt,
            String publishedBy,
            int categoryCount,
            int itemCount,
            List<TemplateCategoryDto> categories
    ) {
    }

    public record TemplateCategoryDto(
            String categoryId,
            String categoryCode,
            String name,
            int sortOrder,
            int itemCount,
            int includedCount,
            boolean included,
            List<TemplateItemDto> items,
            Map<String, Map<String, String>> translations,
            String nameEn,
            String nameAr
    ) {
    }

    public record TemplateItemDto(
            String id,
            String itemId,
            String itemVersionId,
            String itemCode,
            String label,
            String categoryId,
            int sortOrder,
            boolean included,
            String itemStatus,
            Map<String, Map<String, String>> translations,
            String labelEn,
            String labelAr
    ) {
    }

    public record CreateTemplateRequest(
            String code,
            String name,
            String description,
            Map<String, Map<String, String>> translations,
            String nameEn,
            String nameAr,
            String descriptionEn,
            String descriptionAr
    ) {
    }

    public record UpdateTemplateRequest(
            String name,
            String description,
            Map<String, Map<String, String>> translations,
            String nameEn,
            String nameAr,
            String descriptionEn,
            String descriptionAr
    ) {
    }

    public record TemplateCategoryRequest(
            String categoryId,
            Boolean included,
            Integer sortOrder
    ) {
    }

    public record TemplateCategoriesRequest(
            List<TemplateCategoryRequest> categories
    ) {
    }

    public record TemplateItemRequest(
            String categoryId,
            String itemVersionId,
            Boolean included,
            Integer sortOrder
    ) {
    }

    public record TemplateItemsRequest(
            List<TemplateItemRequest> items
    ) {
    }

    public record ChangeRequestDto(
            String id,
            String entityType,
            String entityId,
            String actionCode,
            String status,
            String proposedBy
    ) {
    }
}
