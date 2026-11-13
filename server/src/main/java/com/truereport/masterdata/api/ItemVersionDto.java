package com.truereport.masterdata.api;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public record ItemVersionDto(
        UUID id,
        int versionNo,
        String status,
        List<String> resultOptions,
        String severityPolicy,
        String applicability,
        List<String> reasonCodes,
        String noteRequirement,
        String evidenceRequirement,
        int minPhotos,
        List<UUID> equipmentIds,
        UUID guideImageId,
        String publishedAt,
        String label,
        String instruction,
        String standardSpec,
        Map<String, Map<String, String>> translations,
        String labelEn,
        String labelAr,
        String instructionEn,
        String instructionAr
) {
}
