package com.truereport.masterdata.api;

import java.util.UUID;

public record ItemSummaryDto(
        UUID id,
        String stableCode,
        UUID categoryId,
        String categoryLabelEn,
        String categoryLabelAr,
        String status,
        Integer currentVersion,
        String labelEn,
        String labelAr,
        boolean sampleData,
        String updatedAt
) {
}
