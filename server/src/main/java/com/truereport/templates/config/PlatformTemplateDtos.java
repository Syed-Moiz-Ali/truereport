package com.truereport.templates.config;

import java.util.List;

public final class PlatformTemplateDtos {

    private PlatformTemplateDtos() {
    }

    public record TemplateSummaryDto(
            String id,
            String code,
            String nameEn,
            String nameAr,
            String descriptionEn,
            String descriptionAr,
            String status,
            String currentPublishedVersionId,
            int versionCount,
            Integer currentVersionNo,
            List<TemplateVersionSummaryDto> versions,
            List<TemplateCategoryDto> categories
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
            String nameEn,
            String nameAr,
            int sortOrder,
            int itemCount,
            int includedCount,
            boolean included,
            List<TemplateItemDto> items
    ) {
    }

    public record TemplateItemDto(
            String id,
            String itemId,
            String itemVersionId,
            String itemCode,
            String labelEn,
            String labelAr,
            String categoryId,
            int sortOrder,
            boolean included,
            String itemStatus
    ) {
    }

    public record CreateTemplateRequest(
            String code,
            String nameEn,
            String nameAr,
            String descriptionEn,
            String descriptionAr
    ) {
    }

    public record UpdateTemplateRequest(
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
