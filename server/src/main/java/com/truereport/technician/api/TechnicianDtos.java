package com.truereport.technician.api;

import java.math.BigDecimal;
import java.util.List;

/**
 * Technician inspection API contract. Records are grouped here so the wire
 * shape stays explicit and shared between the controller and service layer.
 */
public final class TechnicianDtos {

    private TechnicianDtos() {
    }

    public record JobSummaryDto(
            String id, String reference, String status, String reviewStatus,
            String templateVersionId, String templateNameEn, String templateNameAr,
            Integer templateVersionNo, String assignedTechnicianId, String customerName,
            String customerPhone, String customerEmail, String vehicleVin, String vehicleMake,
            String vehicleModel, Integer vehicleYear, String vehiclePlate, Integer odometerValue,
            String odometerUnit, String transmission, String fuelType, String vehicleType,
            String preferredLanguage, String scheduledAt, String startedAt,
            String assessmentState, int completedItems, int totalItems, int version) {
    }

    public record JobPageDto(
            List<JobSummaryDto> items, int page, int size, long total, int totalPages) {
    }

    public record PinnedDto(
            String templateVersionId, Integer templateVersionNo, String snapshotHash) {
    }

    public record CategoryDto(
            String code, String nameEn, String nameAr, String iconCode, int sortOrder) {
    }

    public record ScoreBandDto(
            String resultCode, int minScore, int maxScore, int defaultScore,
            String criteriaEn, String criteriaAr) {
    }

    public record EvidenceRuleDto(
            String resultCode, int minPhotos, int minVideos, int minNotesChars,
            String requiredEvidenceType) {
    }

    public record OptionDto(
            String code, String labelEn, String labelAr, int sortOrder) {
    }

    public record IssueFieldDto(
            String fieldCode, String labelEn, String labelAr, String inputType,
            String optionSetCode, List<OptionDto> options, List<String> allowedOptionCodes,
            boolean required, List<String> requiredForStatuses, BigDecimal minValue,
            BigDecimal maxValue, int decimalPlaces, String unitSetCode,
            String dependsOnFieldCode, String dependsOnValueCode, boolean allowMultiple,
            boolean allowFreeText, int sortOrder) {
    }

    public record MeasurementBandDto(
            String fieldCode, String unitCode, String direction, BigDecimal minValue,
            BigDecimal maxValue, String resultCode, int defaultScore, String labelEn,
            String labelAr) {
    }

    public record EvidenceDto(
            String id, String jobId, String itemCode, String type, String status, String mime,
            Long bytes, String sha256, String capturedAt, String captureSource, String deviceId,
            Integer width, Integer height, Long durationMs, String captionEn, String captionAr,
            boolean posterAvailable, String qualityStatus, String contentUrl, String createdAt) {
    }

    public record IssueValueDto(
            String fieldCode, String valueIndex, String optionValueCode, BigDecimal numericValue,
            String unitCode, String textValue) {
    }

    public record MeasurementDto(
            String fieldCode, String valueIndex, BigDecimal numericValue, String unitCode) {
    }

    public record AssessmentDto(
            String id, String itemCode, String itemVersionId, String resultCode,
            String severityCode, Integer score, String suggestedResultCode,
            Integer suggestedScore, String bandResultCode, String state, Long clientRevision,
            Long serverRevision, String notesEn, String notesAr, String reasonCode, int version,
            List<IssueValueDto> issueValues, List<MeasurementDto> measurements,
            List<EvidenceDto> evidence) {
    }

    public record ChecklistItemDto(
            String itemCode, String itemVersionId, String categoryCode, int sortOrder,
            String labelEn, String labelAr, String instructionEn, String instructionAr,
            String standardSpecEn, String standardSpecAr, String measurementUnit,
            String sensorTool, boolean safetyCritical, boolean multiPoint,
            List<String> multiPointIndexes, boolean allowFreeTextNote, String noteRequirement,
            List<String> resultOptions, List<ScoreBandDto> scoreBands,
            List<EvidenceRuleDto> evidenceRules, List<IssueFieldDto> issueFields,
            List<MeasurementBandDto> measurementBands, AssessmentDto assessment) {
    }

    public record ProgressDto(int completed, int total) {
    }

    public record ChecklistDto(
            JobSummaryDto job, PinnedDto pinned, List<CategoryDto> categories,
            List<ChecklistItemDto> items, ProgressDto progress, Long serverRevision) {
    }

    public record AssessmentRequest(
            Integer baseVersion, Long clientRevision, String resultCode, Integer score,
            String severityCode, String notesEn, String notesAr, String reasonCode,
            List<IssueValueDto> issueValues, List<MeasurementDto> measurements) {
    }

    public record SummaryDto(
            String jobId, String status, int itemsAssessed, int itemsTotal, Integer score,
            String gradeCode, boolean safetyCapApplied, String safetyCapReason,
            List<BlockerDto> blockers, List<BlockerDto> warnings, List<ConflictDto> conflicts) {
    }

    public record BlockerDto(
            String code, String itemCode, String messageEn, String messageAr) {
    }

    public record ReviewDto(
            String jobId, String status, List<BlockerDto> blockers, List<BlockerDto> warnings,
            List<AssessmentDto> findings, List<ConflictDto> conflicts) {
    }

    public record SignatureRequest(
            String signerName, String deviceId, String method, String signatureBase64, String mime) {
    }

    public record SignatureDto(
            String jobId, String signerName, String signedAt, String deviceId, String method,
            String signatureHash) {
    }

    public record CompleteRequest(Long clientRevision) {
    }

    public record CompleteDto(
            String jobId, String status, String completedAt, Integer score, String gradeCode,
            boolean safetyCapApplied, List<BlockerDto> blockers) {
    }

    public record EvidenceInitRequest(
            String type, String mime, Long bytes, String sha256, String capturedAt,
            String captureSource, String deviceId, Integer width, Integer height, Long durationMs,
            String captionEn, String captionAr, String posterBase64) {
    }

    public record EvidenceCompleteRequest(
            String captionEn, String captionAr, String posterBase64) {
    }

    public record SyncMutation(
            String idempotencyKey, String itemCode, Integer baseVersion, Long clientRevision,
            String resultCode, Integer score, String severityCode, String notesEn, String notesAr,
            String reasonCode, List<IssueValueDto> issueValues, List<MeasurementDto> measurements) {
    }

    public record SyncRequest(Long clientRevision, List<SyncMutation> mutations) {
    }

    public record SyncResult(
            List<AssessmentDto> applied, List<ConflictDto> conflicts, Integer jobVersion) {
    }

    public record ConflictDto(
            String itemCode, Long clientRevision, Long serverRevision, String serverPayloadJson,
            String clientPayloadJson) {
    }
}
