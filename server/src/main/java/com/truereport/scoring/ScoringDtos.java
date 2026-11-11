package com.truereport.scoring;

import java.util.List;

public final class ScoringDtos {

    private ScoringDtos() {
    }

    public record ScoringRuleDto(
            String id,
            String code,
            String nameEn,
            String nameAr,
            boolean active,
            String categoryWeightMode,
            boolean hardFailCapEnabled,
            String hardFailCapGrade,
            boolean pendingApproval,
            int version
    ) {
    }

    public record UpdateScoringRuleRequest(
            String categoryWeightMode,
            Boolean hardFailCapEnabled,
            String hardFailCapGrade,
            String nameEn,
            String nameAr
    ) {
    }

    public record GradeBoundaryDto(
            String gradeCode,
            int minScore,
            int maxScore,
            String labelEn,
            String labelAr,
            int sortOrder,
            boolean approved
    ) {
    }

    public record GradeBoundariesRequest(List<GradeBoundaryDto> boundaries) {
    }

    public record ChangeRequestInfo(
            String id,
            String entityType,
            String entityId,
            String actionCode,
            String status,
            String proposedBy
    ) {
    }

    public record ScoringRuleDetail(
            ScoringRuleDto rule,
            List<GradeBoundaryDto> gradeBoundaries
    ) {
    }

    public record RejectScoringRuleRequest(String reason) {
    }
}
