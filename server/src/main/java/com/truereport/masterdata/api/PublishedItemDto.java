package com.truereport.masterdata.api;

import java.util.UUID;

public record PublishedItemDto(
        UUID itemId,
        UUID versionId,
        String stableCode,
        UUID categoryId,
        String categoryLabelEn,
        String categoryLabelAr,
        String labelEn,
        String labelAr,
        boolean sampleData,
        ItemVersionDto version
) {
}
