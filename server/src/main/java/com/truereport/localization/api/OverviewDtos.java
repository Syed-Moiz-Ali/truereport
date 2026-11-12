package com.truereport.localization.api;

import java.util.List;

public final class OverviewDtos {

    private OverviewDtos() {
    }

    public record WorkshopsSummaryDto(int total, int active) {
    }

    public record StaffSummaryDto(int technicians, int admins) {
    }

    public record JobsSummaryDto(int active, int pendingReview) {
    }

    public record ReportsSummaryDto(int published) {
    }

    public record ChecklistSummaryDto(int categories, int items, int templates,
                                      boolean healthy, int issues) {
    }

    public record LanguagesSummaryDto(int live, int translating) {
    }

    public record RecentActivityDto(String id, String action, String entityType,
                                    String entityId, String actor, String occurredAt) {
    }

    public record AlertDto(String severity, String title, String body, String route) {
    }

    public record OverviewDto(
            WorkshopsSummaryDto workshops,
            StaffSummaryDto staff,
            JobsSummaryDto jobs,
            ReportsSummaryDto reports,
            ChecklistSummaryDto checklist,
            LanguagesSummaryDto languages,
            List<RecentActivityDto> recentActivity,
            List<AlertDto> alerts
    ) {
    }
}
