package com.truereport.jobs.api;

import java.util.List;

/**
 * Workshop dashboard contract. Every figure is a read-only aggregate over the
 * clean workshop tables; the window is {@code days} back from today (Dubai).
 */
public final class WorkshopDashboardDtos {

    private WorkshopDashboardDtos() {
    }

    public record DailyFlowDto(String date, long created, long published) {
    }

    public record TurnaroundDto(Long averageMinutes, int sampleSize) {
    }

    public record QualityDto(Integer averageScore, int scoredJobs) {
    }

    public record StaffLoadDto(String id, String name, long openJobs, long completed) {
    }

    public record StaffSummaryDto(int technicians, int withOpenJobs, List<StaffLoadDto> top) {
    }

    public record CustomerLoadDto(String name, long jobs) {
    }

    public record CustomerSummaryDto(int served, int repeat, List<CustomerLoadDto> top) {
    }

    public record ReportSummaryDto(
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
            String jobId,
            String at,
            String actor,
            String fromStatus,
            String toStatus,
            String reference
    ) {
    }

    public record WorkshopDashboardDto(
            int days,
            String generatedAt,
            DailyFlowDto today,
            List<DailyFlowDto> trend,
            TurnaroundDto turnaround,
            QualityDto quality,
            StaffSummaryDto staff,
            CustomerSummaryDto customers,
            ReportSummaryDto reports,
            List<ActivityDto> activity
    ) {
    }
}
