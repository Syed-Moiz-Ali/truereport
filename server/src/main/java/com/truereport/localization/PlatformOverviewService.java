package com.truereport.localization;

import com.truereport.localization.api.OverviewDtos.AlertDto;
import com.truereport.localization.api.OverviewDtos.ChecklistSummaryDto;
import com.truereport.localization.api.OverviewDtos.JobsSummaryDto;
import com.truereport.localization.api.OverviewDtos.LanguagesSummaryDto;
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
        List<AlertDto> alerts = alerts(healthy, languages);
        return new OverviewDto(workshopSummary, staff, jobs, reports, checklist,
                languages, recent, alerts);
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

    private List<AlertDto> alerts(boolean healthy, LanguagesSummaryDto languages) {
        List<AlertDto> alerts = new ArrayList<>();
        if (!healthy) {
            alerts.add(new AlertDto("warning", "Checklist configuration needs attention",
                    "One or more configuration health checks are failing. Review the checklist health console.",
                    "/checklist/health"));
        }
        try {
            List<Map<String, Object>> incomplete = jdbc.queryForList("""
                    SELECT code FROM platform_languages
                    WHERE status IN ('DRAFT', 'TRANSLATING', 'REVIEW') ORDER BY code
                    """);
            if (!incomplete.isEmpty()) {
                List<String> codes = incomplete.stream()
                        .map(row -> string(row.get("code"))).toList();
                alerts.add(new AlertDto("info", "Languages waiting for translation",
                        "Incomplete translations for: " + String.join(", ", codes) + ".",
                        "/settings/languages"));
            }
        } catch (RuntimeException ignored) {
        }
        int failedDocuments = count(
                "SELECT COUNT(*) FROM platform_report_documents WHERE status = 'FAILED'");
        if (failedDocuments > 0) {
            alerts.add(new AlertDto("error", "Report generation failures",
                    failedDocuments + " report document(s) failed to generate and need retry.",
                    "/reports"));
        }
        int unpublished = count(
                "SELECT COUNT(*) FROM platform_jobs WHERE publication_status = 'PUBLISHED'"
                        + " AND id NOT IN (SELECT job_id FROM platform_public_links WHERE status = 'ACTIVE')");
        if (unpublished > 0) {
            alerts.add(new AlertDto("warning", "Unpublished reports",
                    unpublished + " published job(s) have no active public link.",
                    "/reports"));
        }
        return alerts;
    }

    private static String string(Object value) {
        return value == null ? null : value.toString();
    }
}
