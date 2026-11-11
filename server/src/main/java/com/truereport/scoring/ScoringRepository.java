package com.truereport.scoring;

import com.truereport.scoring.ScoringDtos.ChangeRequestInfo;
import com.truereport.scoring.ScoringDtos.GradeBoundaryDto;
import com.truereport.scoring.ScoringDtos.ScoringRuleDto;
import com.truereport.shared.uuid.UuidV7;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public class ScoringRepository {

    private static final RowMapper<ScoringRuleDto> RULE_MAPPER = (rs, i) -> new ScoringRuleDto(
            rs.getString("id"),
            rs.getString("code"),
            rs.getString("name_en"),
            rs.getString("name_ar"),
            rs.getBoolean("active"),
            rs.getString("category_weight_mode"),
            rs.getBoolean("hard_fail_cap_enabled"),
            rs.getString("hard_fail_cap_grade"),
            rs.getBoolean("pending_approval"),
            rs.getInt("version")
    );

    private static final RowMapper<GradeBoundaryDto> BOUNDARY_MAPPER = (rs, i) -> new GradeBoundaryDto(
            rs.getString("grade_code"),
            rs.getInt("min_score"),
            rs.getInt("max_score"),
            rs.getString("label_en"),
            rs.getString("label_ar"),
            rs.getInt("sort_order"),
            rs.getBoolean("approved")
    );

    private static final RowMapper<ChangeRequestInfo> CHANGE_MAPPER = (rs, i) -> new ChangeRequestInfo(
            rs.getString("id"),
            rs.getString("entity_type"),
            rs.getString("entity_id"),
            rs.getString("action_code"),
            rs.getString("status"),
            rs.getString("proposed_by")
    );

    private final JdbcTemplate jdbc;

    public ScoringRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Optional<ScoringRuleDto> findActiveOptional() {
        return jdbc.query("""
                SELECT id, code, name_en, name_ar, active, category_weight_mode,
                       hard_fail_cap_enabled, hard_fail_cap_grade, pending_approval, version
                FROM platform_scoring_rules
                WHERE active = TRUE
                ORDER BY created_at, id
                """, RULE_MAPPER).stream().findFirst();
    }

    public Optional<ScoringRuleDto> findById(String id) {
        return jdbc.query("""
                SELECT id, code, name_en, name_ar, active, category_weight_mode,
                       hard_fail_cap_enabled, hard_fail_cap_grade, pending_approval, version
                FROM platform_scoring_rules
                WHERE id = ?
                """, RULE_MAPPER, id).stream().findFirst();
    }

    public Optional<ScoringRuleDto> findByCode(String code) {
        return jdbc.query("""
                SELECT id, code, name_en, name_ar, active, category_weight_mode,
                       hard_fail_cap_enabled, hard_fail_cap_grade, pending_approval, version
                FROM platform_scoring_rules
                WHERE code = ?
                """, RULE_MAPPER, code).stream().findFirst();
    }

    public Optional<ScoringRuleDto> insertDefaultIfAbsent(String code, String nameEn, String nameAr,
                                                          String categoryWeightMode,
                                                          boolean hardFailCapEnabled,
                                                          String hardFailCapGrade) {
        Optional<ScoringRuleDto> active = findActiveOptional();
        if (active.isPresent()) {
            return active;
        }
        Optional<ScoringRuleDto> existing = findByCode(code);
        if (existing.isPresent()) {
            activate(existing.get().id());
            return findById(existing.get().id());
        }
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_scoring_rules
                    (id, code, name_en, name_ar, active, category_weight_mode,
                     hard_fail_cap_enabled, hard_fail_cap_grade, pending_approval,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, ?, TRUE, ?, ?, ?, FALSE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                """, id, code, nameEn, nameAr, categoryWeightMode, hardFailCapEnabled, hardFailCapGrade);
        return findById(id);
    }

    public void updateRule(String id, String categoryWeightMode, boolean hardFailCapEnabled,
                           String hardFailCapGrade, String nameEn, String nameAr,
                           boolean pendingApproval) {
        jdbc.update("""
                UPDATE platform_scoring_rules
                SET category_weight_mode = ?, hard_fail_cap_enabled = ?, hard_fail_cap_grade = ?,
                    name_en = ?, name_ar = ?, pending_approval = ?,
                    updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE id = ?
                """, categoryWeightMode, hardFailCapEnabled, hardFailCapGrade,
                nameEn, nameAr, pendingApproval, id);
    }

    public void markPending(String ruleId, boolean pending) {
        jdbc.update("""
                UPDATE platform_scoring_rules
                SET pending_approval = ?, updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE id = ?
                """, pending, ruleId);
    }

    public void replaceBoundaries(String ruleId, List<GradeBoundaryDto> boundaries, boolean approved) {
        jdbc.update("DELETE FROM platform_grade_boundaries WHERE scoring_rule_id = ?", ruleId);
        for (GradeBoundaryDto boundary : boundaries) {
            jdbc.update("""
                    INSERT INTO platform_grade_boundaries
                        (id, scoring_rule_id, grade_code, min_score, max_score, label_en, label_ar,
                         sort_order, approved, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                    """,
                    UuidV7.generate().toString(), ruleId, boundary.gradeCode(),
                    boundary.minScore(), boundary.maxScore(), boundary.labelEn(),
                    boundary.labelAr(), boundary.sortOrder(), approved);
        }
    }

    public List<GradeBoundaryDto> boundaries(String ruleId) {
        return jdbc.query("""
                SELECT grade_code, min_score, max_score, label_en, label_ar, sort_order, approved
                FROM platform_grade_boundaries
                WHERE scoring_rule_id = ?
                ORDER BY sort_order, min_score
                """, BOUNDARY_MAPPER, ruleId);
    }

    public String createChangeRequest(String entityType, String entityId, String actionCode,
                                      String payloadJson, String proposedBy) {
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_change_requests
                    (id, entity_type, entity_id, action_code, payload_json, status,
                     proposed_by, proposed_at)
                VALUES (?, ?, ?, ?, ?, 'PENDING', ?, CURRENT_TIMESTAMP)
                """, id, entityType, entityId, actionCode, payloadJson, proposedBy);
        return id;
    }

    public Optional<ChangeRequestInfo> findPendingChange(String entityType, String entityId) {
        return jdbc.query("""
                SELECT id, entity_type, entity_id, action_code, status, proposed_by
                FROM platform_change_requests
                WHERE entity_type = ? AND entity_id = ? AND status = 'PENDING'
                ORDER BY proposed_at DESC
                """, CHANGE_MAPPER, entityType, entityId).stream().findFirst();
    }

    public void approveChange(String id, String decidedBy) {
        jdbc.update("""
                UPDATE platform_change_requests
                SET status = 'APPROVED', decided_by = ?, decided_at = CURRENT_TIMESTAMP
                WHERE id = ? AND status = 'PENDING'
                """, decidedBy, id);
    }

    public void rejectChange(String id, String decidedBy, String reason) {
        jdbc.update("""
                UPDATE platform_change_requests
                SET status = 'REJECTED', decided_by = ?, decided_at = CURRENT_TIMESTAMP,
                    reason = ?
                WHERE id = ? AND status = 'PENDING'
                """, decidedBy, reason, id);
    }

    public int countActiveRules() {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_scoring_rules WHERE active = TRUE
                """, Integer.class);
        return count == null ? 0 : count;
    }

    public void deactivateAll() {
        jdbc.update("""
                UPDATE platform_scoring_rules
                SET active = FALSE, updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE active = TRUE
                """);
    }

    public void activate(String id) {
        jdbc.update("""
                UPDATE platform_scoring_rules
                SET active = TRUE, updated_at = CURRENT_TIMESTAMP, version = version + 1
                WHERE id = ?
                """, id);
    }
}
