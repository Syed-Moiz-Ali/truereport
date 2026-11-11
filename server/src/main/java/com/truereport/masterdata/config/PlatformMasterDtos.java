package com.truereport.masterdata.config;

import java.math.BigDecimal;
import java.util.List;

public final class PlatformMasterDtos {

    private PlatformMasterDtos() {
    }

    public record CategoryWeightRow(
            String id,
            String code,
            String nameEn,
            String nameAr,
            String status,
            BigDecimal weight
    ) {
    }

    public record CategoryWeightCheck(
            boolean valid,
            BigDecimal total,
            BigDecimal expected,
            List<CategoryWeightRow> categories
    ) {
    }

    public record ReorderIdsRequest(List<String> orderedIds) {
    }

    public record ReorderCodesRequest(List<String> orderedCodes) {
    }

    public record ItemMetadataDto(
            String itemId,
            String measurementUnit,
            String sensorTool,
            String standardSpecEn,
            String standardSpecAr,
            boolean safetyCritical,
            boolean multiPoint,
            Integer maxTyreAgeYears,
            boolean allowFreeTextNote,
            int sortOrder,
            String guideImageId
    ) {
    }

    public record ItemMetadataRequest(
            String measurementUnit,
            String sensorTool,
            String standardSpecEn,
            String standardSpecAr,
            Boolean safetyCritical,
            Boolean multiPoint,
            Integer maxTyreAgeYears,
            Boolean allowFreeTextNote,
            Integer sortOrder,
            String guideImageId
    ) {
    }

    public record ScoreBandDto(
            String resultCode,
            int minScore,
            int maxScore,
            int defaultScore,
            String criteriaEn,
            String criteriaAr
    ) {
    }

    public record ScoreBandsRequest(List<ScoreBandDto> bands) {
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
            String labelEn,
            String labelAr,
            int sortOrder
    ) {
    }

    public record MeasurementBandsRequest(List<MeasurementBandDto> bands) {
    }

    public record IssueFieldDto(
            String id,
            String fieldCode,
            String labelEn,
            String labelAr,
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
            List<String> allowedValues
    ) {
    }

    public record IssueFieldsRequest(List<IssueFieldDto> fields) {
    }

    public record ItemConfigDto(
            ItemMetadataDto metadata,
            List<ScoreBandDto> scoreBands,
            List<EvidenceRuleDto> evidenceRules,
            List<IssueFieldDto> issueFields,
            List<MeasurementBandDto> measurementBands
    ) {
    }

    public record OptionValueDto(
            String id,
            String code,
            String labelEn,
            String labelAr,
            String status,
            int sortOrder,
            String metadataJson
    ) {
    }

    public record OptionSetDto(
            String id,
            String code,
            String nameEn,
            String nameAr,
            String status,
            int sortOrder,
            List<OptionValueDto> values
    ) {
    }

    public record OptionSetRequest(
            String code,
            String nameEn,
            String nameAr,
            Integer sortOrder
    ) {
    }

    public record OptionValueRequest(
            String code,
            String labelEn,
            String labelAr,
            Integer sortOrder,
            String metadataJson
    ) {
    }

    public record OptionValueUpdateRequest(
            String labelEn,
            String labelAr,
            Integer sortOrder,
            String metadataJson
    ) {
    }

    public record RetireOptionValueRequest(String replacementCode) {
    }
}
