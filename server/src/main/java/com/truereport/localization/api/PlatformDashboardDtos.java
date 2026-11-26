package com.truereport.localization.api;

import java.util.List;
import java.util.Map;

/** Read-only Platform Admin dashboard aggregates. */
public final class PlatformDashboardDtos {

    private PlatformDashboardDtos() {
    }

    public record FlowDto(String date, long created, long published) {
    }

    public record WorkshopLeaderDto(String id, String name, long jobs) {
    }

    public record WorkshopSummaryDto(
            long total,
            long active,
            long disabled,
            long createdInRange,
            List<WorkshopLeaderDto> top
    ) {
    }

    public record StaffSummaryDto(long admins, long technicians, long createdInRange) {
    }

    public record JobsSummaryDto(
            long total,
            long active,
            long pendingReview,
            long published,
            long publishedInRange,
            Map<String, Long> byStatus
    ) {
    }

    public record ConfigSummaryDto(
            long templates,
            long templateVersions,
            long categories,
            long items,
            long languagesLive,
            long languagesTranslating,
            long languagesReview,
            long languagesDraft
    ) {
    }

    public record ReportsSummaryDto(
            long versions,
            long published,
            long documents,
            long readyDocuments,
            long failedDocuments,
            long exportBytes,
            long activeLinks,
            long revokedLinks
    ) {
    }

    public record ActivityDto(
            String at,
            String actor,
            String action,
            String entityType,
            String entityId
    ) {
    }

    public record PlatformDashboardDto(
            int days,
            String generatedAt,
            FlowDto today,
            List<FlowDto> trend,
            WorkshopSummaryDto workshops,
            StaffSummaryDto staff,
            JobsSummaryDto jobs,
            ConfigSummaryDto config,
            ReportsSummaryDto reports,
            List<ActivityDto> activity
    ) {
    }
}
