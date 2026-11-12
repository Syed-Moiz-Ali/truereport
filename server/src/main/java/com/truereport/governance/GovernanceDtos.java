package com.truereport.governance;

import java.time.LocalDateTime;
import java.util.List;

public final class GovernanceDtos {

    private GovernanceDtos() {
    }

    public record HealthCheckDto(
            String code,
            String severity,
            String messageEn,
            String messageAr,
            int affected,
            List<String> references
    ) {
    }

    public record ConfigHealthDto(boolean healthy, List<HealthCheckDto> checks) {
    }

    public record ImpactDto(
            String entityType,
            String entityId,
            boolean blocked,
            int affectedTemplates,
            int affectedItems,
            int affectedJobs,
            List<String> templateCodes,
            List<String> itemCodes,
            String messageEn,
            String messageAr
    ) {
    }

    public record ReleaseDto(
            String id,
            String entityType,
            String entityId,
            String versionId,
            String status,
            String effectiveFrom,
            String notes,
            String createdBy,
            String approvedBy,
            String approvedAt,
            String createdAt
    ) {
    }

    public record CreateReleaseRequest(
            String entityType,
            String entityId,
            String versionId,
            String effectiveFrom,
            String notes
    ) {
    }

    public record TransitionReleaseRequest(String reason) {
    }

    public record ReleaseTransitionResult(ReleaseDto release, boolean makerCheckerPending) {
    }

    public record GovernanceMessage(String messageEn, String messageAr) {
    }
}
