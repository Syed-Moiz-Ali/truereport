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
        int versionNo,
        List<String> resultOptions,
        String severityPolicy,
        List<String> reasonCodes,
        String noteRequirement,
        String evidenceRequirement,
        int minPhotos,
        List<UUID> equipmentIds,
        UUID guideImageId,
        boolean sampleData
) {
}
