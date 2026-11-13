package com.truereport.masterdata.api;

import java.util.Map;
import java.util.UUID;

public record ItemSummaryDto(
        UUID id,
        String stableCode,
        UUID categoryId,
        String categoryLabelEn,
        String categoryLabelAr,
        String status,
        Integer currentVersion,
        String label,
        String instruction,
        boolean sampleData,
        String updatedAt,
        String measurementUnit,
        String sensorTool,
        String standardSpec,
        boolean safetyCritical,
        boolean multiPoint,
        Integer maxTyreAgeYears,
        boolean allowFreeTextNote,
        int sortOrder,
        String guideImageId,
        Map<String, Map<String, String>> translations,
        String labelEn,
        String labelAr,
        String standardSpecEn,
        String standardSpecAr
) {
}
