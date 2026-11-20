package com.truereport.localization;

import com.truereport.localization.api.OverviewDtos.AlertActionDto;
import com.truereport.localization.api.OverviewDtos.AlertDto;
import com.truereport.localization.api.OverviewDtos.ChecklistSummaryDto;
import com.truereport.localization.api.OverviewDtos.JobsSummaryDto;
import com.truereport.localization.api.OverviewDtos.LanguagesSummaryDto;
import com.truereport.localization.api.OverviewDtos.LocalizedAlertDto;
import com.truereport.localization.api.OverviewDtos.MetricCardDto;
import com.truereport.localization.api.OverviewDtos.OverviewDto;
import com.truereport.localization.api.OverviewDtos.RecentActivityDto;
import com.truereport.localization.api.OverviewDtos.ReportsSummaryDto;
import com.truereport.localization.api.OverviewDtos.StaffSummaryDto;
import com.truereport.localization.api.OverviewDtos.WorkshopsSummaryDto;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Read-only Platform Admin overview aggregation. Every count is defensive:
 * a missing table yields zero (or an empty list) instead of a 500.
 */
@Service
public class PlatformOverviewService {

    private final JdbcTemplate jdbc;
    private final LocalizationService localization;

    public PlatformOverviewService(JdbcTemplate jdbc, LocalizationService localization) {
        this.jdbc = jdbc;
        this.localization = localization;
    }

    @Transactional(readOnly = true)
    public OverviewDto overview() {
        WorkshopsSummaryDto workshopSummary = new WorkshopsSummaryDto(
                count("SELECT COUNT(*) FROM workshops"),
                count("SELECT COUNT(*) FROM workshops WHERE status = 'ACTIVE'"));
        StaffSummaryDto staff = new StaffSummaryDto(
                count("SELECT COUNT(*) FROM workshop_memberships WHERE member_role = 'TECHNICIAN' AND status = 'ACTIVE'"),
                count("SELECT COUNT(*) FROM workshop_memberships WHERE member_role = 'WORKSHOP_ADMIN' AND status = 'ACTIVE'"));
        JobsSummaryDto jobs = new JobsSummaryDto(
                count("SELECT COUNT(*) FROM platform_jobs WHERE status IN ('DRAFT','SCHEDULED','ASSIGNED','IN_PROGRESS')"),
                count("SELECT COUNT(*) FROM platform_jobs WHERE status = 'PENDING_REVIEW'"));
        ReportsSummaryDto reports = new ReportsSummaryDto(
                Math.max(
                        count("SELECT COUNT(*) FROM platform_public_links WHERE status = 'ACTIVE'"),
                        count("SELECT COUNT(*) FROM platform_jobs WHERE publication_status = 'PUBLISHED'")));
        boolean healthy = true;
        int issues = 0;
        try {
            // Same-slice health signal: missing EN/AR master content.
            // A failing coverage check marks the checklist unhealthy.
            var coverage = localization.coverage();
            issues = (int) coverage.namespaces().values().stream()
                    .filter(namespace -> !namespace.missing().isEmpty()).count();
            healthy = issues == 0;
        } catch (RuntimeException ignored) {
            healthy = true;
        }
        ChecklistSummaryDto checklist = new ChecklistSummaryDto(
                count("SELECT COUNT(*) FROM platform_categories"),
                count("SELECT COUNT(*) FROM platform_items WHERE status = 'PUBLISHED'"),
                count("SELECT COUNT(*) FROM platform_templates WHERE status = 'ACTIVE'"),
                healthy, issues);
        LanguagesSummaryDto languages = new LanguagesSummaryDto(
                count("SELECT COUNT(*) FROM platform_languages WHERE status = 'LIVE'"),
                count("SELECT COUNT(*) FROM platform_languages WHERE status = 'TRANSLATING'"));
        List<RecentActivityDto> recent = recentActivity();
        AlertFacts facts = alertFacts(healthy);
        List<AlertDto> alerts = alerts(facts);
        List<LocalizedAlertDto> localizedAlerts = localizedAlerts(facts);
        List<MetricCardDto> metricCards = metricCards(workshopSummary, staff, jobs, reports,
                checklist, languages);
        return new OverviewDto(workshopSummary, staff, jobs, reports, checklist,
                languages, recent, alerts, metricCards, localizedAlerts);
    }

    private int count(String sql) {
        try {
            Integer value = jdbc.queryForObject(sql, Integer.class);
            return value == null ? 0 : value;
        } catch (RuntimeException ex) {
            return 0;
        }
    }

    private List<RecentActivityDto> recentActivity() {
        try {
            List<Map<String, Object>> rows = jdbc.queryForList("""
                    SELECT id, actor_user_id, action_code, entity_type, entity_id, occurred_at
                    FROM platform_audit_events ORDER BY occurred_at DESC
                    """);
            List<RecentActivityDto> result = new ArrayList<>();
            for (Map<String, Object> row : rows) {
                if (result.size() >= 8) {
                    break;
                }
                result.add(new RecentActivityDto(
                        string(row.get("id")),
                        string(row.get("action_code")),
                        string(row.get("entity_type")),
                        string(row.get("entity_id")),
                        string(row.get("actor_user_id")),
                        string(row.get("occurred_at"))));
            }
            return result;
        } catch (RuntimeException ex) {
            return List.of();
        }
    }

    private record AlertFacts(boolean checklistIncomplete, List<String> languageCodes,
                              int failedDocuments, int unpublishedReports) {
    }

    private AlertFacts alertFacts(boolean healthy) {
        List<String> languageCodes = List.of();
        try {
            languageCodes = jdbc.queryForList("""
                    SELECT code FROM platform_languages
                    WHERE status IN ('DRAFT', 'TRANSLATING', 'REVIEW') ORDER BY code
                    """, String.class);
        } catch (RuntimeException ignored) {
        }
        int failedDocuments = count(
                "SELECT COUNT(*) FROM platform_report_documents WHERE status = 'FAILED'");
        int unpublished = count(
                "SELECT COUNT(*) FROM platform_jobs WHERE publication_status = 'PUBLISHED'"
                        + " AND id NOT IN (SELECT job_id FROM platform_public_links WHERE status = 'ACTIVE')");
        return new AlertFacts(!healthy, languageCodes, failedDocuments, unpublished);
    }

    private List<AlertDto> alerts(AlertFacts facts) {
        List<AlertDto> alerts = new ArrayList<>();
        if (facts.checklistIncomplete()) {
            alerts.add(new AlertDto(
                    "warning",
                    "Checklist configuration needs attention",
                    "One or more configuration health checks are failing. Review the checklist health console.",
                    "/checklist/health",
                    "dashboard.alert.checklist.title",
                    "dashboard.alert.checklist.body",
                    Map.of()
            ));
        }
        if (!facts.languageCodes().isEmpty()) {
            String joined = String.join(", ", facts.languageCodes());
            alerts.add(new AlertDto(
                    "info",
                    "Languages waiting for translation",
                    "Incomplete translations for: " + joined + ".",
                    "/settings/languages",
                    "dashboard.alert.languages.title",
                    "dashboard.alert.languages.body",
                    Map.of("languages", joined)
            ));
        }
        if (facts.failedDocuments() > 0) {
            alerts.add(new AlertDto(
                    "error",
                    "Report generation failures",
                    facts.failedDocuments() + " report document(s) failed to generate and need retry.",
                    "/reports",
                    "dashboard.alert.reportsFailed.title",
                    "dashboard.alert.reportsFailed.body",
                    Map.of("count", facts.failedDocuments())
            ));
        }
        if (facts.unpublishedReports() > 0) {
            alerts.add(new AlertDto(
                    "warning",
                    "Unpublished reports",
                    facts.unpublishedReports() + " published job(s) have no active public link.",
                    "/reports",
                    "dashboard.alert.reportsUnpublished.title",
                    "dashboard.alert.reportsUnpublished.body",
                    Map.of("count", facts.unpublishedReports())
            ));
        }
        return alerts;
    }

    private List<LocalizedAlertDto> localizedAlerts(AlertFacts facts) {
        List<LocalizedAlertDto> result = new ArrayList<>();
        if (facts.checklistIncomplete()) {
            result.add(new LocalizedAlertDto("checklistIncomplete", "warning", 10,
                    "dashboard.alert.checklist.title", "dashboard.alert.checklist.body",
                    Map.of(),
                    new AlertActionDto("dashboard.alert.checklist.action", "/checklist/health")));
        }
        if (!facts.languageCodes().isEmpty()) {
            result.add(new LocalizedAlertDto("languagesIncomplete", "info", 20,
                    "dashboard.alert.languages.title", "dashboard.alert.languages.body",
                    Map.of("languages", String.join(", ", facts.languageCodes())),
                    new AlertActionDto("dashboard.alert.languages.action", "/settings/languages")));
        }
        if (facts.failedDocuments() > 0) {
            result.add(new LocalizedAlertDto("reportFailures", "danger", 30,
                    "dashboard.alert.reportsFailed.title", "dashboard.alert.reportsFailed.body",
                    Map.of("count", Integer.toString(facts.failedDocuments())),
                    new AlertActionDto("dashboard.alert.reportsFailed.action", "/reports")));
        }
        if (facts.unpublishedReports() > 0) {
            result.add(new LocalizedAlertDto("unpublishedReports", "warning", 40,
                    "dashboard.alert.reportsUnpublished.title",
                    "dashboard.alert.reportsUnpublished.body",
                    Map.of("count", Integer.toString(facts.unpublishedReports())),
                    new AlertActionDto("dashboard.alert.reportsUnpublished.action", "/reports")));
        }
        return result;
    }

    private List<MetricCardDto> metricCards(WorkshopsSummaryDto workshops, StaffSummaryDto staff,
                                            JobsSummaryDto jobs, ReportsSummaryDto reports,
                                            ChecklistSummaryDto checklist,
                                            LanguagesSummaryDto languages) {
        return List.of(
                new MetricCardDto("activeWorkshops", "dashActiveWorkshops",
                        number(workshops.active()), "dashActiveWorkshopsCaption", "neutral", 10),
                new MetricCardDto("technicians", "dashTechnicians",
                        number(staff.technicians()), "dashTechniciansCaption", "info", 20),
                new MetricCardDto("activeJobs", "dashActiveJobs",
                        number(jobs.active()), "dashActiveJobsCaption", "info", 30),
                new MetricCardDto("pendingReviews", "dashPendingReviews",
                        number(jobs.pendingReview()), "dashPendingReviewsCaption", "warning", 40),
                new MetricCardDto("publishedReports", "dashPublishedReports",
                        number(reports.published()), "dashPublishedReportsCaption", "success", 50),
                new MetricCardDto("checklistHealth", "dashChecklistHealth",
                        number(checklist.issues()),
                        "dashChecklistHealthCaption",
                        checklist.issues() == 0 ? "success" : "warning", 60),
                new MetricCardDto("languagesLive", "dashLanguagesLive",
                        number(languages.live()), "dashLanguagesLiveCaption", "info", 70));
    }

    /** Server-side display formatting: no client grouping or rounding. */
    private static String number(int value) {
        return String.format(Locale.ROOT, "%,d", value);
    }

    private static String string(Object value) {
        return value == null ? null : value.toString();
    }
}
