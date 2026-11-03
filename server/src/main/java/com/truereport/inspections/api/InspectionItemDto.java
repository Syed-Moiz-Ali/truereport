package com.truereport.inspections.api;

import java.util.List;
import java.util.UUID;

public record InspectionItemDto(
        UUID inspectionItemId,
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
        List<String> equipmentIds,
        UUID guideImageId,
        boolean sampleData,
        AssessmentDto assessment
) {
}
