package com.truereport.jobs.api;

import java.util.List;

/**
 * Workshop job API contract. All identifiers are UUIDv7 strings
 * because the clean workshop tables do not use the legacy BINARY(16) keys.
 */
public final class WorkshopJobDtos {

    private WorkshopJobDtos() {
    }

    public record AvailableTemplateDto(
            String versionId,
            String templateId,
            String code,
            String nameEn,
            String nameAr,
            int versionNo,
            int itemCount
    ) {
    }

    public record TemplateItemDto(
            String itemVersionId,
            String stableCode,
            String labelEn,
            String labelAr,
            String categoryId,
            String categoryNameEn,
            String categoryNameAr,
            boolean safetyCritical,
            String measurementUnit,
            int sortOrder
    ) {
    }

    public record TemplateVersionDetailDto(
            String versionId,
            String templateId,
            String code,
            String nameEn,
            String nameAr,
            int versionNo,
            String status,
            List<TemplateItemDto> items
    ) {
    }

    public record JobDto(
            String id,
            String reference,
            String status,
            String reviewStatus,
            String publicationStatus,
            String templateVersionId,
            String templateNameEn,
            String templateNameAr,
            Integer templateVersionNo,
            String assignedTechnicianId,
            String assignedTechnicianName,
            String customerName,
            String customerPhone,
            String customerEmail,
            String vehicleVin,
            String vehicleMake,
            String vehicleModel,
            Integer vehicleYear,
            String vehiclePlate,
            Integer odometerValue,
            String odometerUnit,
            String transmission,
            String fuelType,
            String preferredLanguage,
            String scheduledAt,
            String startedAt,
            String completedAt,
            String approvedAt,
            String publishedAt,
            String cancelledAt,
            String approvedBy,
            String cancelledBy,
            String cancelReason,
            Integer score,
            String gradeCode,
            boolean safetyCapApplied,
            String safetyCapReason,
            boolean consentGranted,
            boolean signaturePresent,
            String createdAt,
            String updatedAt,
            int version
    ) {
    }

    public record JobPageDto(
            List<JobDto> items,
            int page,
            int size,
            long total,
            int totalPages
    ) {
    }

    public record JobStatusCountsDto(
            long draft,
            long scheduled,
            long assigned,
            long inProgress,
            long pendingReview,
            long approved,
            long published,
            long rejected,
            long cancelled,
            long total
    ) {
    }

    public record CreateJobRequest(
            String templateVersionId,
            String customerName,
            String customerPhone,
            String customerEmail,
            String vehicleVin,
            String vehicleMake,
            String vehicleModel,
            Integer vehicleYear,
            String vehiclePlate,
            Integer odometerValue,
            String odometerUnit,
            String transmission,
            String fuelType,
            String preferredLanguage,
            String scheduledAt,
            String assignedTechnicianId,
            Boolean consentGranted
    ) {
    }

    public record UpdateJobRequest(
            String customerName,
            String customerPhone,
            String customerEmail,
            String vehicleVin,
            String vehicleMake,
            String vehicleModel,
            Integer vehicleYear,
            String vehiclePlate,
            Integer odometerValue,
            String odometerUnit,
            String transmission,
            String fuelType,
            String preferredLanguage,
            Integer version
    ) {
    }

    public record AssignTechnicianRequest(
            String technicianId,
            String reason,
            Integer version
    ) {
    }

    public record CancelJobRequest(
            String reason,
            Integer version
    ) {
    }

    public record AssignmentDto(
            String id,
            String technicianId,
            String technicianName,
            String assignedBy,
            String assignedAt,
            String unassignedAt,
            String reason
    ) {
    }

    public record ReviewFindingDto(
            String itemVersionId,
            String stableCode,
            String labelEn,
            String labelAr,
            String resultCode,
            Integer score,
            int evidencePhotos,
            int evidenceVideos,
            boolean signaturePresent,
            String completedAt,
            String issueValuesJson
    ) {
    }

    public record ReviewDto(
            String jobId,
            String status,
            int itemsAssessed,
            int itemsTotal,
            Integer scorePreview,
            String gradePreview,
            String safetyCapPreview,
            List<ReviewFindingDto> findings
    ) {
    }

    public record ChecklistItemDto(
            String code,
            boolean passed,
            String messageEn,
            String messageAr
    ) {
    }

    public record PublishChecklistDto(
            String jobId,
            boolean ready,
            List<ChecklistItemDto> items,
            int itemsAssessed,
            int itemsTotal,
            Integer score,
            String gradeCode,
            boolean safetyCapApplied,
            String safetyCapReason,
            boolean consentGranted,
            boolean signaturePresent,
            boolean documentsReady
    ) {
    }

    public record ApproveJobRequest(
            String reason,
            String safetyCapReason,
            Integer version
    ) {
    }

    public record RejectJobRequest(
            String reason,
            Integer version
    ) {
    }

    public record PublishJobRequest(
            Boolean pdfDownloadEnabled
    ) {
    }

    public record ReasonRequest(
            String reason
    ) {
    }

    public record PublicLinkDto(
            String jobId,
            String status,
            String publicUrl,
            String token,
            String qrUrl,
            boolean pdfDownloadEnabled,
            String activatedAt,
            String revokedAt,
            String revocationReason
    ) {
    }

    public record ReportDocumentDto(
            String id,
            String documentTypeCode,
            String nameEn,
            String nameAr,
            String language,
            String status,
            Long bytes,
            String generatedAt,
            String error,
            String downloadUrl
    ) {
    }

    public record NotificationDto(
            String id,
            String type,
            String payloadJson,
            String readAt,
            String createdAt
    ) {
    }
}
