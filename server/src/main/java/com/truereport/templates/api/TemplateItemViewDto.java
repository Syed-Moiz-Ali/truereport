package com.truereport.templates.api;

import java.util.List;
import java.util.UUID;

public record TemplateItemViewDto(
        UUID masterItemVersionId,
        int sortOrder,
        String stableCode,
        String categoryLabelEn,
        String categoryLabelAr,
        String labelEn,
        String labelAr,
        String instructionEn,
        String instructionAr,
        int versionNo,
        List<String> resultOptions,
        String severityPolicy,
        String applicability,
        List<String> reasonCodes,
        String noteRequirement,
        String evidenceRequirement,
        int minPhotos,
        List<UUID> equipmentIds,
        UUID guideImageId,
        boolean sampleData
) {
}
