package com.truereport.masterdata.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public record ItemCreateRequest(
        @NotBlank @Size(max = 60) String stableCode,
        @NotNull UUID categoryId,
        @Size(max = 200) String label,
        String instruction,
        String standardSpec,
        boolean sampleData,
        List<String> resultOptions,
        String severityPolicy,
        String applicability,
        List<String> reasonCodes,
        String noteRequirement,
        String evidenceRequirement,
        Integer minPhotos,
        List<UUID> equipmentIds,
        UUID guideImageId,
        String measurementUnit,
        String sensorTool,
        Boolean safetyCritical,
        Boolean multiPoint,
        Integer maxTyreAgeYears,
        Boolean allowFreeTextNote,
        Integer sortOrder,
        Map<String, Map<String, String>> translations,
        String labelEn,
        String labelAr,
        String instructionEn,
        String instructionAr,
        String standardSpecEn,
        String standardSpecAr
) {
    public ItemCreateRequest(String stableCode, UUID categoryId, String labelEn, String labelAr,
                             String instructionEn, String instructionAr, boolean sampleData,
                             List<String> resultOptions, String severityPolicy, String applicability,
                             List<String> reasonCodes, String noteRequirement, String evidenceRequirement,
                             Integer minPhotos, List<UUID> equipmentIds, UUID guideImageId) {
        this(stableCode, categoryId, labelEn, instructionEn, null, sampleData,
                resultOptions, severityPolicy, applicability, reasonCodes, noteRequirement,
                evidenceRequirement, minPhotos, equipmentIds, guideImageId,
                null, null, null, null, null, null, null, null,
                labelEn, labelAr, instructionEn, instructionAr, null, null);
    }
}
