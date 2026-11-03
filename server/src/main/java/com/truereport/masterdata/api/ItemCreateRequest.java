package com.truereport.masterdata.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

public record ItemCreateRequest(
        @NotBlank @Size(max = 60) String stableCode,
        @NotNull UUID categoryId,
        @NotBlank @Size(max = 200) String labelEn,
        @NotBlank @Size(max = 200) String labelAr,
        @NotBlank String instructionEn,
        @NotBlank String instructionAr,
        boolean sampleData,
        List<String> resultOptions,
        String severityPolicy,
        String applicability,
        List<String> reasonCodes,
        String noteRequirement,
        String evidenceRequirement,
        Integer minPhotos,
        List<UUID> equipmentIds,
        UUID guideImageId
) {
}
