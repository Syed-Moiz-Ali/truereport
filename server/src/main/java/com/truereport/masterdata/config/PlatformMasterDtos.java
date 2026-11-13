package com.truereport.masterdata.config;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

public final class PlatformMasterDtos {

    private PlatformMasterDtos() {
    }

    public record ReorderIdsRequest(List<String> orderedIds) {
    }

    public record ReorderCodesRequest(List<String> orderedCodes) {
    }

    public record ItemMetadataDto(
            String itemId,
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
            String standardSpecEn,
            String standardSpecAr
    ) {
    }

    public record ItemMetadataRequest(
            String measurementUnit,
            String sensorTool,
            String standardSpec,
            Map<String, Map<String, String>> translations,
            Boolean safetyCritical,
            Boolean multiPoint,
            Integer maxTyreAgeYears,
            Boolean allowFreeTextNote,
            Integer sortOrder,
            String guideImageId,
            String standardSpecEn,
            String standardSpecAr
    ) {
    }

    public record EvidenceRuleDto(
            String resultCode,
            int minPhotos,
            int minVideos,
            int minNotesChars,
            String requiredEvidenceType
    ) {
    }

    public record EvidenceRulesRequest(List<EvidenceRuleDto> rules) {
    }

    public record MeasurementBandDto(
            String fieldCode,
            String unitCode,
            String direction,
            BigDecimal minValue,
            BigDecimal maxValue,
            String resultCode,
            int defaultScore,
            String label,
            int sortOrder,
            Map<String, Map<String, String>> translations,
            String labelEn,
            String labelAr
    ) {
    }

    public record MeasurementBandsRequest(List<MeasurementBandDto> bands) {
    }

    public record IssueFieldDto(
            String id,
            String fieldCode,
            String label,
            String inputType,
            String optionSetCode,
            String unitSetCode,
            Boolean required,
            List<String> requiredForStatuses,
            BigDecimal minValue,
            BigDecimal maxValue,
            Integer decimalPlaces,
            String dependsOnFieldCode,
            String dependsOnValueCode,
            Boolean allowMultiple,
            Boolean allowFreeText,
            Integer sortOrder,
            List<String> allowedValues,
            Map<String, Map<String, String>> translations,
            String labelEn,
            String labelAr
    ) {
    }

    public record IssueFieldsRequest(List<IssueFieldDto> fields) {
    }

    public record ItemConfigDto(
            ItemMetadataDto metadata,
            List<EvidenceRuleDto> evidenceRules,
            List<IssueFieldDto> issueFields,
            List<MeasurementBandDto> measurementBands
    ) {
    }

    public record OptionValueDto(
            String id,
            String code,
            String label,
            String status,
            int sortOrder,
            String metadataJson,
            Map<String, Map<String, String>> translations,
            String labelEn,
            String labelAr
    ) {
    }

    public record OptionSetDto(
            String id,
            String code,
            String name,
            String status,
            int sortOrder,
            List<OptionValueDto> values,
            Map<String, Map<String, String>> translations,
            String nameEn,
            String nameAr
    ) {
    }

    public record OptionSetRequest(
            String code,
            String name,
            Integer sortOrder,
            Map<String, Map<String, String>> translations,
            String nameEn,
            String nameAr,
            String status
    ) {
    }

    public record OptionValueRequest(
            String code,
            String label,
            Integer sortOrder,
            String metadataJson,
            Map<String, Map<String, String>> translations,
            String labelEn,
            String labelAr
    ) {
    }

    public record OptionValueUpdateRequest(
            String label,
            Integer sortOrder,
            String metadataJson,
            Map<String, Map<String, String>> translations,
            String labelEn,
            String labelAr,
            String status
    ) {
    }

    public record RetireOptionValueRequest(String replacementCode) {
    }
}
