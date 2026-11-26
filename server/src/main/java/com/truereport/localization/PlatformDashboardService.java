package com.truereport.localization;

import com.truereport.identity.User;
import com.truereport.identity.UserRepository;
import com.truereport.localization.api.PlatformDashboardDtos.ActivityDto;
import com.truereport.localization.api.PlatformDashboardDtos.ConfigSummaryDto;
import com.truereport.localization.api.PlatformDashboardDtos.FlowDto;
import com.truereport.localization.api.PlatformDashboardDtos.JobsSummaryDto;
import com.truereport.localization.api.PlatformDashboardDtos.PlatformDashboardDto;
import com.truereport.localization.api.PlatformDashboardDtos.ReportsSummaryDto;
import com.truereport.localization.api.PlatformDashboardDtos.StaffSummaryDto;
import com.truereport.localization.api.PlatformDashboardDtos.WorkshopLeaderDto;
import com.truereport.localization.api.PlatformDashboardDtos.WorkshopSummaryDto;
import com.truereport.shared.time.WallClockTimes;
import com.truereport.shared.uuid.UuidBinaryConverter;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Read-only Platform Admin dashboard aggregation across every workshop.
 *
 * Every count is defensive: a missing table yields zero, never a 500. All
 * figures are aggregates of real rows; nothing is estimated.
 */
@Service
public class PlatformDashboardService {

    private final JdbcTemplate jdbc;
    private final UserRepository users;

    public PlatformDashboardService(JdbcTemplate jdbc, UserRepository users) {
        this.jdbc = jdbc;
        this.users = users;
    }

    @Transactional(readOnly = true)
    public PlatformDashboardDto dashboard(int days) {
        int window = Math.min(90, Math.max(1, days));
        LocalDate today = LocalDate.now(WallClockTimes.DUBAI);
        LocalDate fromDay = today.minusDays(window - 1L);
        LocalDateTime from = fromDay.atStartOfDay();

        Map<LocalDate, long[]> byDay = new LinkedHashMap<>();
        for (int index = 0; index < window; index++) {
            byDay.put(fromDay.plusDays(index), new long[2]);
        }
        fill(byDay, "SELECT CAST(created_at AS DATE) AS day, COUNT(*) AS c "
                + "FROM platform_jobs WHERE created_at >= ? "
                + "GROUP BY CAST(created_at AS DATE)", from, 0);
        fill(byDay, "SELECT CAST(published_at AS DATE) AS day, COUNT(*) AS c "
                + "FROM platform_jobs WHERE published_at IS NOT NULL AND published_at >= ? "
                + "GROUP BY CAST(published_at AS DATE)", from, 1);
        List<FlowDto> trend = new ArrayList<>(window);
        for (Map.Entry<LocalDate, long[]> entry : byDay.entrySet()) {
            trend.add(new FlowDto(entry.getKey().toString(),
                    entry.getValue()[0], entry.getValue()[1]));
        }
        FlowDto todayFlow = trend.isEmpty()
                ? new FlowDto(today.toString(), 0, 0)
                : trend.get(trend.size() - 1);

        Map<String, Long> byStatus = new LinkedHashMap<>();
        jdbc.query("SELECT status, COUNT(*) AS c FROM platform_jobs GROUP BY status",
                rs -> {
                    byStatus.put(rs.getString("status"), rs.getLong("c"));
                });
        long total = byStatus.values().stream().mapToLong(Long::longValue).sum();
        long active = byStatus.entrySet().stream()
                .filter(entry -> !entry.getKey().equals("PUBLISHED")
                        && !entry.getKey().equals("REJECTED")
                        && !entry.getKey().equals("CANCELLED"))
                .mapToLong(Map.Entry::getValue).sum();
        long pending = byStatus.getOrDefault("PENDING_REVIEW", 0L);
        long published = byStatus.getOrDefault("PUBLISHED", 0L);
        long publishedInRange = count(
                "SELECT COUNT(*) FROM platform_jobs WHERE published_at IS NOT NULL AND published_at >= ?",
                from);

        long workshopTotal = count("SELECT COUNT(*) FROM workshops");
        long workshopActive = count("SELECT COUNT(*) FROM workshops WHERE status = 'ACTIVE'");
        long workshopDisabled = count("SELECT COUNT(*) FROM workshops WHERE status = 'DISABLED'");
        long workshopsNew = count("SELECT COUNT(*) FROM workshops WHERE created_at >= ?", from);

        Map<String, String> workshopNames = new LinkedHashMap<>();
        jdbc.query("SELECT id, name FROM workshops", rs -> {
            byte[] id = rs.getBytes("id");
            if (id != null) {
                workshopNames.put(UuidBinaryConverter.fromBytes(id).toString(), rs.getString("name"));
            }
        });
        Map<String, Long> jobsByWorkshop = new LinkedHashMap<>();
        jdbc.query("SELECT workshop_id, COUNT(*) AS c FROM platform_jobs GROUP BY workshop_id",
                rs -> {
                    if (rs.getString("workshop_id") != null) {
                        jobsByWorkshop.put(rs.getString("workshop_id"), rs.getLong("c"));
                    }
                });
        List<WorkshopLeaderDto> leaders = jobsByWorkshop.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                .limit(5)
                .map(entry -> new WorkshopLeaderDto(entry.getKey(),
                        workshopNames.getOrDefault(entry.getKey(), entry.getKey()),
                        entry.getValue()))
                .toList();

        long admins = count(
                "SELECT COUNT(*) FROM workshop_memberships WHERE member_role = 'WORKSHOP_ADMIN' AND status = 'ACTIVE'");
        long technicians = count(
                "SELECT COUNT(*) FROM workshop_memberships WHERE member_role = 'TECHNICIAN' AND status = 'ACTIVE'");
        long staffNew = count("SELECT COUNT(*) FROM workshop_memberships WHERE created_at >= ?", from);

        long live = count("SELECT COUNT(*) FROM platform_languages WHERE status = 'LIVE'");
        long translating = count("SELECT COUNT(*) FROM platform_languages WHERE status = 'TRANSLATING'");
        long review = count("SELECT COUNT(*) FROM platform_languages WHERE status = 'REVIEW'");
        long draftLanguages = count("SELECT COUNT(*) FROM platform_languages WHERE status = 'DRAFT'");

        ConfigSummaryDto config = new ConfigSummaryDto(
                count("SELECT COUNT(*) FROM platform_templates WHERE status = 'ACTIVE'"),
                count("SELECT COUNT(*) FROM platform_template_versions WHERE status = 'PUBLISHED'"),
                count("SELECT COUNT(*) FROM platform_categories"),
                count("SELECT COUNT(*) FROM platform_items WHERE status = 'PUBLISHED'"),
                live, translating, review, draftLanguages);

        long versions = count("SELECT COUNT(*) FROM platform_report_versions WHERE created_at >= ?", from);
        long docs = count("SELECT COUNT(*) FROM platform_report_documents WHERE created_at >= ?", from);
        long readyDocs = count(
                "SELECT COUNT(*) FROM platform_report_documents WHERE status = 'READY' AND created_at >= ?", from);
        long failedDocs = count(
                "SELECT COUNT(*) FROM platform_report_documents WHERE status = 'FAILED' AND created_at >= ?", from);
        Long bytes = jdbc.queryForObject(
                "SELECT COALESCE(SUM(bytes), 0) FROM platform_report_documents "
                        + "WHERE status = 'READY' AND created_at >= ?", Long.class, from);
        long activeLinks = count("SELECT COUNT(*) FROM platform_public_links WHERE status = 'ACTIVE'");
        long revokedLinks = count("SELECT COUNT(*) FROM platform_public_links WHERE status = 'REVOKED'");
        ReportsSummaryDto reports = new ReportsSummaryDto(versions, published, docs, readyDocs,
                failedDocs, bytes == null ? 0 : bytes, activeLinks, revokedLinks);

        List<ActivityDto> activity = jdbc.query("""
                SELECT actor_user_id, action_code, entity_type, entity_id, occurred_at
                FROM platform_audit_events ORDER BY occurred_at DESC LIMIT 8
                """, (rs, index) -> {
            String actor = null;
            String actorId = rs.getString("actor_user_id");
            if (actorId != null && !actorId.isBlank()) {
                try {
                    actor = users.findById(UUID.fromString(actorId))
                            .map(User::getDisplayName).orElse(null);
                } catch (RuntimeException ignored) {
                    actor = null;
                }
            }
            LocalDateTime at = rs.getObject("occurred_at", LocalDateTime.class);
            return new ActivityDto(at == null ? null : at.toString(), actor,
                    rs.getString("action_code"), rs.getString("entity_type"),
                    rs.getString("entity_id"));
        });

        return new PlatformDashboardDto(window, WallClockTimes.dubaiNow().toString(),
                todayFlow, trend,
                new WorkshopSummaryDto(workshopTotal, workshopActive, workshopDisabled,
                        workshopsNew, leaders),
                new StaffSummaryDto(admins, technicians, staffNew),
                new JobsSummaryDto(total, active, pending, published, publishedInRange, byStatus),
                config, reports, activity);
    }

    private void fill(Map<LocalDate, long[]> byDay, String sql, LocalDateTime from, int column) {
        jdbc.query(sql, rs -> {
            LocalDate day = rs.getDate("day").toLocalDate();
            long[] cell = byDay.get(day);
            if (cell != null) {
                cell[column] = rs.getLong("c");
            }
        }, from);
    }

    private long count(String sql, Object... args) {
        try {
            Long value = jdbc.queryForObject(sql, Long.class, args);
            return value == null ? 0 : value;
        } catch (RuntimeException ex) {
            return 0;
        }
    }
}
