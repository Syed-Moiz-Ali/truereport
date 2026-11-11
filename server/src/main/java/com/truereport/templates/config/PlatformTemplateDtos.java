package com.truereport.templates.config;

import java.math.BigDecimal;
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
            List<TemplateVersionSummaryDto> versions
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
            String categoryCode,
            String categoryNameEn,
            String categoryNameAr,
            BigDecimal itemWeight,
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

    public record TemplateItemRequest(
            String itemVersionId,
            Boolean included,
            BigDecimal itemWeight,
            Integer sortOrder
    ) {
    }

    public record TemplateItemsRequest(
            List<TemplateItemRequest> items
    ) {
    }

    public record WeightPreviewRow(
            String itemVersionId,
            String itemCode,
            String labelEn,
            String labelAr,
            String categoryId,
            String categoryCode,
            BigDecimal categoryWeight,
            BigDecimal itemWeight,
            BigDecimal normalizedWeight
    ) {
    }

    public record WeightPreviewDto(
            String mode,
            int itemCount,
            BigDecimal categoryWeightTotal,
            List<WeightPreviewRow> rows
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
