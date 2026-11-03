package com.truereport.masterdata.api;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

import java.util.List;
import java.util.UUID;

public record RulesRequest(
        List<String> resultOptions,
        String severityPolicy,
        String applicability,
        List<String> reasonCodes,
        @NotBlank String noteRequirement,
        @NotBlank String evidenceRequirement,
        @Min(0) Integer minPhotos,
        List<UUID> equipmentIds,
        UUID guideImageId
) {
}
