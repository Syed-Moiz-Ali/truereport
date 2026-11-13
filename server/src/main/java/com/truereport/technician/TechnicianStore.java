package com.truereport.technician;

import com.truereport.shared.security.PiiCipher;
import com.truereport.shared.uuid.UuidV7;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * JDBC store for technician inspection execution. Reads and writes only the
 * clean platform_* tables.
 */
@Repository
public class TechnicianStore {

    private final JdbcTemplate jdbc;
    private final PiiCipher pii;

    public TechnicianStore(JdbcTemplate jdbc, PiiCipher pii) {
        this.jdbc = jdbc;
        this.pii = pii;
    }

    // --------------------------------------------------------------- records

    public record JobRow(
            String id, String workshopId, String reference, String status, String reviewStatus,
            String templateVersionId, String assignedTechnicianId, String customerName,
            String customerPhone, String customerEmail, String vehicleVin, String vehicleMake,
            String vehicleModel, Integer vehicleYear, String vehiclePlate, Integer odometerValue,
            String odometerUnit, String transmission, String fuelType, String vehicleType,
            String serviceType, String scope, String preferredLanguage, String assessmentState,
            Long lastClientRevision, LocalDateTime scheduledAt, LocalDateTime startedAt,
            LocalDateTime completedAt, Integer score, String gradeCode, boolean safetyCapApplied,
            String safetyCapReason, boolean signaturePresent, String createdBy,
            LocalDateTime createdAt, LocalDateTime updatedAt, int version) {
    }

    public record TemplateRow(
            String versionId, String templateId, String code, String nameEn, String nameAr,
            int versionNo, String status) {
    }

    public record ItemRow(
            String itemVersionId, String itemId, String itemCode, String categoryId,
            String categoryCode, String categoryNameEn, String categoryNameAr,
            int categorySortOrder, int itemSortOrder, String labelEn, String labelAr,
            String instructionEn, String instructionAr, String standardSpecEn,
            String standardSpecAr, String measurementUnit, String sensorTool,
            boolean safetyCritical, boolean multiPoint, boolean allowFreeTextNote,
            String noteRequirement, String resultOptionsJson, String severityPolicyJson,
            String reasonCodesJson) {
    }

    public record ScoreBandRow(
            String id, String resultCode, int minScore, int maxScore, int defaultScore,
            String criteriaEn, String criteriaAr, int sortOrder) {
    }

    public record EvidenceRuleRow(
            String resultCode, int minPhotos, int minVideos, int minNotesChars,
            String requiredEvidenceType) {
    }

    public record MeasureBandRow(
            String id, String fieldCode, String unitCode, String direction, BigDecimal minValue,
            BigDecimal maxValue, String resultCode, int defaultScore, String labelEn,
            String labelAr, int sortOrder) {
    }

    public record IssueFieldRow(
            String id, String fieldCode, String labelEn, String labelAr, String inputType,
            String optionSetId, String optionSetCode, String unitSetId, String unitSetCode,
            boolean required, String requiredForStatusesJson, BigDecimal minValue,
            BigDecimal maxValue, int decimalPlaces, String dependsOnFieldCode,
            String dependsOnValueCode, boolean allowMultiple, boolean allowFreeText,
            int sortOrder) {
    }

    public record OptionRow(
            String code, String labelEn, String labelAr, int sortOrder) {
    }

    public record AssessmentRow(
            String id, String jobId, String itemVersionId, String itemCode, String resultCode,
            String severityCode, String suggestedResultCode, Integer suggestedScore,
            Integer score, String notesEn, String notesAr, String reasonCode, String state,
            Long clientRevision, Long serverRevision, String conflictState, String assessedBy,
            LocalDateTime createdAt, LocalDateTime updatedAt, int version) {
    }

    public record IssueValueRow(
            String fieldCode, String valueIndex, String optionValueCode, BigDecimal numericValue,
            String unitCode, String textValue, int sortOrder) {
    }

    public record MeasurementRow(
            String fieldCode, String valueIndex, BigDecimal numericValue, String unitCode,
            String bandId, String derivedResultCode, Integer derivedScore) {
    }

    public record EvidenceRow(
            String id, String jobId, String itemVersionId, String itemCode, String assessmentId,
            String type, String status, String storageKey, String normalizedKey, String mime,
            long bytes, String sha256, LocalDateTime capturedAt, String captureSource,
            String deviceId, Integer width, Integer height, Long durationMs, String posterKey,
            String captionEn, String captionAr, String qualityStatus, String uploadedBy,
            LocalDateTime deletedAt, String deletedBy, LocalDateTime createdAt,
            LocalDateTime updatedAt, int version) {
    }

    public record ChecklistRow(
            String id, String jobId, String templateVersionId, String snapshotJson,
            String snapshotHash, LocalDateTime createdAt) {
    }

    public record SignatureRow(
            String id, String jobId, String signerUserId, String signerName,
            LocalDateTime signedAt, String deviceId, String method, String storageKey,
            String signatureHash, LocalDateTime createdAt) {
    }

    public record ConflictRow(
            String id, String jobId, String itemCode, Long clientRevision, Long serverRevision,
            String serverPayloadJson, String clientPayloadJson, String state,
            LocalDateTime createdAt, LocalDateTime resolvedAt) {
    }

    public record ScoringRuleRow(
            String id, String code, boolean hardFailCapEnabled, String hardFailCapGrade) {
    }

    public record GradeBoundaryRow(
            String gradeCode, int minScore, int maxScore, int sortOrder) {
    }

    // ------------------------------------------------------------------ jobs

    public Optional<JobRow> findJob(String workshopId, String technicianId, String jobId) {
        return jdbc.query("""
                SELECT * FROM platform_jobs
                WHERE id = ? AND workshop_id = ? AND assigned_technician_id = ?
                """, JOB_MAPPER, jobId, workshopId, technicianId).stream().findFirst();
    }

    public List<JobRow> listJobs(String workshopId, String technicianId, String status,
                                 int offset, int limit) {
        StringBuilder sql = new StringBuilder("""
                SELECT * FROM platform_jobs
                WHERE workshop_id = ? AND assigned_technician_id = ?
                """);
        List<Object> args = new ArrayList<>();
        args.add(workshopId);
        args.add(technicianId);
        if (status != null && !status.isBlank()) {
            sql.append(" AND status = ?");
            args.add(status);
        }
        sql.append(" ORDER BY created_at DESC, id DESC LIMIT ? OFFSET ?");
        args.add(limit);
        args.add(offset);
        return jdbc.query(sql.toString(), JOB_MAPPER, args.toArray());
    }

    public long countJobs(String workshopId, String technicianId, String status) {
        StringBuilder sql = new StringBuilder("""
                SELECT COUNT(*) FROM platform_jobs
                WHERE workshop_id = ? AND assigned_technician_id = ?
                """);
        List<Object> args = new ArrayList<>();
        args.add(workshopId);
        args.add(technicianId);
        if (status != null && !status.isBlank()) {
            sql.append(" AND status = ?");
            args.add(status);
        }
        Long count = jdbc.queryForObject(sql.toString(), Long.class, args.toArray());
        return count == null ? 0 : count;
    }

    public int jobVersion(String jobId) {
        Integer version = jdbc.queryForObject(
                "SELECT version FROM platform_jobs WHERE id = ?", Integer.class, jobId);
        return version == null ? 0 : version;
    }

    public void startJob(String jobId) {
        jdbc.update("""
                UPDATE platform_jobs
                SET status = CASE WHEN status = 'ASSIGNED' THEN 'IN_PROGRESS' ELSE status END,
                    started_at = COALESCE(started_at, ?),
                    assessment_state = CASE WHEN assessment_state = 'NOT_STARTED'
                        THEN 'IN_PROGRESS' ELSE assessment_state END,
                    updated_at = ?, version = version + 1
                WHERE id = ?
                """, now(), now(), jobId);
    }

    public void updateSignaturePresent(String jobId) {
        jdbc.update("""
                UPDATE platform_jobs
                SET signature_present = TRUE, updated_at = ?, version = version + 1
                WHERE id = ?
                """, now(), jobId);
    }

    public void completeJob(String jobId, int score, String gradeCode, boolean capApplied,
                            String capReason, Long clientRevision) {
        jdbc.update("""
                UPDATE platform_jobs
                SET status = 'PENDING_REVIEW', review_status = 'PENDING_REVIEW',
                    assessment_state = 'COMPLETED', completed_at = ?, score = ?, grade_code = ?,
                    safety_cap_applied = ?, safety_cap_reason = ?, last_client_revision = ?,
                    updated_at = ?, version = version + 1
                WHERE id = ?
                """, now(), score, gradeCode, capApplied, capReason, clientRevision, now(), jobId);
    }

    public void insertHistory(String jobId, String fromStatus, String toStatus, String actorId,
                              String reason) {
        jdbc.update("""
                INSERT INTO platform_job_status_history
                    (id, job_id, from_status, to_status, actor_id, occurred_at, reason)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """, UuidV7.generate().toString(), jobId, fromStatus, toStatus, actorId, now(),
                reason);
    }

    public void insertNotification(String workshopId, String userId, String type,
                                   String payloadJson) {
        if (userId == null) {
            return;
        }
        jdbc.update("""
                INSERT INTO platform_notifications
                    (id, workshop_id, user_id, type, payload_json, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
                """, UuidV7.generate().toString(), workshopId, userId, type, payloadJson, now());
    }

    // ------------------------------------------------------------- templates

    public Optional<TemplateRow> template(String versionId) {
        return jdbc.query("""
                SELECT v.id AS version_id, v.template_id, t.code,
                       t.name AS name_en,
                       (SELECT body FROM platform_translations pt
                        WHERE pt.entity_type = 'TEMPLATE' AND pt.entity_id = t.id
                          AND pt.field_name = 'name' AND pt.lang = 'ar') AS name_ar,
                       v.version_no, v.status
                FROM platform_template_versions v
                JOIN platform_templates t ON t.id = v.template_id
                WHERE v.id = ?
                """, (rs, i) -> new TemplateRow(
                rs.getString("version_id"), rs.getString("template_id"), rs.getString("code"),
                rs.getString("name_en"), rs.getString("name_ar"), rs.getInt("version_no"),
                rs.getString("status")), versionId).stream().findFirst();
    }

    public List<ItemRow> items(String templateVersionId) {
        return jdbc.query("""
                SELECT ti.item_version_id, v.item_id, i.stable_code AS item_code,
                       i.category_id, c.code AS category_code, c.name AS category_name_en,
                       (SELECT body FROM platform_translations pt
                        WHERE pt.entity_type = 'CATEGORY' AND pt.entity_id = c.id
                          AND pt.field_name = 'name' AND pt.lang = 'ar') AS category_name_ar,
                       c.sort_order AS category_sort_order,
                       ti.sort_order AS item_sort_order,
                       v.label AS label_en,
                       (SELECT body FROM platform_translations pt
                        WHERE pt.entity_type = 'ITEM' AND pt.entity_id = v.id
                          AND pt.field_name = 'label' AND pt.lang = 'ar') AS label_ar,
                       v.instruction AS instruction_en,
                       (SELECT body FROM platform_translations pt
                        WHERE pt.entity_type = 'ITEM' AND pt.entity_id = v.id
                          AND pt.field_name = 'instruction' AND pt.lang = 'ar') AS instruction_ar,
                       v.standard_spec AS standard_spec_en,
                       (SELECT body FROM platform_translations pt
                        WHERE pt.entity_type = 'ITEM' AND pt.entity_id = v.id
                          AND pt.field_name = 'standardSpec' AND pt.lang = 'ar') AS standard_spec_ar,
                       v.measurement_unit, v.sensor_tool,
                       v.safety_critical, v.multi_point, v.allow_free_text_note,
                       v.note_requirement, v.result_options_json, v.severity_policy_json,
                       v.reason_codes_json
                FROM platform_template_items ti
                JOIN platform_item_versions v ON v.id = ti.item_version_id
                JOIN platform_items i ON i.id = v.item_id
                JOIN platform_categories c ON c.id = i.category_id
                WHERE ti.template_version_id = ? AND ti.included = TRUE
                ORDER BY ti.sort_order, i.sort_order, i.stable_code
                """, (rs, i) -> new ItemRow(
                rs.getString("item_version_id"), rs.getString("item_id"),
                rs.getString("item_code"), rs.getString("category_id"),
                rs.getString("category_code"), rs.getString("category_name_en"),
                rs.getString("category_name_ar"), rs.getInt("category_sort_order"),
                rs.getInt("item_sort_order"), rs.getString("label_en"), rs.getString("label_ar"),
                rs.getString("instruction_en"), rs.getString("instruction_ar"),
                rs.getString("standard_spec_en"), rs.getString("standard_spec_ar"),
                rs.getString("measurement_unit"), rs.getString("sensor_tool"),
                rs.getBoolean("safety_critical"), rs.getBoolean("multi_point"),
                rs.getBoolean("allow_free_text_note"), rs.getString("note_requirement"),
                rs.getString("result_options_json"), rs.getString("severity_policy_json"),
                rs.getString("reason_codes_json")), templateVersionId);
    }

    public Optional<ItemRow> itemByCode(String templateVersionId, String itemCode) {
        return items(templateVersionId).stream()
                .filter(item -> item.itemCode().equals(itemCode))
                .findFirst();
    }

    public int templateItemCount(String templateVersionId) {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_template_items
                WHERE template_version_id = ? AND included = TRUE
                """, Integer.class, templateVersionId);
        return count == null ? 0 : count;
    }

    public List<ScoreBandRow> scoreBands(String itemVersionId) {
        return jdbc.query("""
                SELECT b.id, b.result_code, b.min_score, b.max_score, b.default_score,
                       b.criteria AS criteria_en,
                       (SELECT body FROM platform_translations pt
                        WHERE pt.entity_type = 'SCORE_BAND' AND pt.entity_id = b.id
                          AND pt.field_name = 'criteria' AND pt.lang = 'ar') AS criteria_ar,
                       b.sort_order
                FROM platform_score_bands b WHERE b.item_version_id = ?
                ORDER BY sort_order, min_score
                """, (rs, i) -> new ScoreBandRow(
                rs.getString("id"), rs.getString("result_code"), rs.getInt("min_score"),
                rs.getInt("max_score"), rs.getInt("default_score"), rs.getString("criteria_en"),
                rs.getString("criteria_ar"), rs.getInt("sort_order")), itemVersionId);
    }

    public List<EvidenceRuleRow> evidenceRules(String itemVersionId) {
        return jdbc.query("""
                SELECT result_code, min_photos, min_videos, min_notes_chars,
                       required_evidence_type
                FROM platform_evidence_rules WHERE item_version_id = ?
                ORDER BY result_code
                """, (rs, i) -> new EvidenceRuleRow(
                rs.getString("result_code"), rs.getInt("min_photos"), rs.getInt("min_videos"),
                rs.getInt("min_notes_chars"), rs.getString("required_evidence_type")),
                itemVersionId);
    }

    public List<MeasureBandRow> measurementBands(String itemVersionId) {
        return jdbc.query("""
                SELECT b.id, b.field_code, b.unit_code, b.direction, b.min_value, b.max_value,
                       b.result_code, b.default_score,
                       b.label AS label_en,
                       (SELECT body FROM platform_translations pt
                        WHERE pt.entity_type = 'MEASUREMENT_BAND' AND pt.entity_id = b.id
                          AND pt.field_name = 'label' AND pt.lang = 'ar') AS label_ar,
                       b.sort_order
                FROM platform_measurement_bands b WHERE b.item_version_id = ?
                ORDER BY field_code, sort_order, min_value
                """, (rs, i) -> new MeasureBandRow(
                rs.getString("id"), rs.getString("field_code"), rs.getString("unit_code"),
                rs.getString("direction"), rs.getBigDecimal("min_value"),
                rs.getBigDecimal("max_value"), rs.getString("result_code"),
                rs.getInt("default_score"), rs.getString("label_en"), rs.getString("label_ar"),
                rs.getInt("sort_order")), itemVersionId);
    }

    public List<IssueFieldRow> issueFields(String itemVersionId) {
        return jdbc.query("""
                SELECT f.id, f.field_code,
                       f.label AS label_en,
                       (SELECT body FROM platform_translations pt
                        WHERE pt.entity_type = 'ISSUE_FIELD' AND pt.entity_id = f.id
                          AND pt.field_name = 'label' AND pt.lang = 'ar') AS label_ar,
                       f.input_type,
                       f.option_set_id, os.code AS option_set_code,
                       f.unit_set_id, us.code AS unit_set_code, f.is_required,
                       f.required_for_statuses_json, f.min_value, f.max_value, f.decimal_places,
                       f.depends_on_field_code, f.depends_on_value_code, f.allow_multiple,
                       f.allow_free_text, f.sort_order
                FROM platform_issue_fields f
                LEFT JOIN platform_option_sets os ON os.id = f.option_set_id
                LEFT JOIN platform_option_sets us ON us.id = f.unit_set_id
                WHERE f.item_version_id = ?
                ORDER BY f.sort_order, f.field_code
                """, (rs, i) -> new IssueFieldRow(
                rs.getString("id"), rs.getString("field_code"), rs.getString("label_en"),
                rs.getString("label_ar"), rs.getString("input_type"),
                rs.getString("option_set_id"), rs.getString("option_set_code"),
                rs.getString("unit_set_id"), rs.getString("unit_set_code"),
                rs.getBoolean("is_required"), rs.getString("required_for_statuses_json"),
                rs.getBigDecimal("min_value"), rs.getBigDecimal("max_value"),
                rs.getInt("decimal_places"), rs.getString("depends_on_field_code"),
                rs.getString("depends_on_value_code"), rs.getBoolean("allow_multiple"),
                rs.getBoolean("allow_free_text"), rs.getInt("sort_order")), itemVersionId);
    }

    public List<OptionRow> options(String issueFieldId, String optionSetId) {
        if (issueFieldId != null) {
            List<OptionRow> subset = jdbc.query("""
                    SELECT ov.code, ov.label AS label_en,
                           (SELECT body FROM platform_translations pt
                            WHERE pt.entity_type = 'OPTION_VALUE' AND pt.entity_id = ov.id
                              AND pt.field_name = 'label' AND pt.lang = 'ar') AS label_ar,
                           ov.sort_order
                    FROM platform_issue_field_options ifo
                    JOIN platform_option_values ov ON ov.id = ifo.option_value_id
                    WHERE ifo.issue_field_id = ? AND ov.status = 'ACTIVE'
                    ORDER BY ov.sort_order, ov.code
                    """, OPTION_MAPPER, issueFieldId);
            if (!subset.isEmpty()) {
                return subset;
            }
        }
        if (optionSetId == null) {
            return List.of();
        }
        return jdbc.query("""
                SELECT ov.code, ov.label AS label_en,
                       (SELECT body FROM platform_translations pt
                        WHERE pt.entity_type = 'OPTION_VALUE' AND pt.entity_id = ov.id
                          AND pt.field_name = 'label' AND pt.lang = 'ar') AS label_ar,
                       ov.sort_order
                FROM platform_option_values ov
                WHERE ov.option_set_id = ? AND ov.status = 'ACTIVE'
                ORDER BY sort_order, code
                """, OPTION_MAPPER, optionSetId);
    }

    public List<String> unitCodes(String unitSetId) {
        if (unitSetId == null) {
            return List.of();
        }
        return jdbc.queryForList("""
                SELECT code FROM platform_option_values
                WHERE option_set_id = ? AND status = 'ACTIVE'
                ORDER BY sort_order, code
                """, String.class, unitSetId);
    }

    // ----------------------------------------------------------- assessments

    public Optional<AssessmentRow> assessment(String jobId, String itemCode) {
        return jdbc.query("""
                SELECT * FROM platform_assessments WHERE job_id = ? AND item_code = ?
                """, ASSESSMENT_MAPPER, jobId, itemCode).stream().findFirst();
    }

    public Optional<AssessmentRow> assessmentById(String assessmentId) {
        return jdbc.query("SELECT * FROM platform_assessments WHERE id = ?",
                ASSESSMENT_MAPPER, assessmentId).stream().findFirst();
    }

    public List<AssessmentRow> assessments(String jobId) {
        return jdbc.query("""
                SELECT * FROM platform_assessments WHERE job_id = ?
                ORDER BY created_at, item_code
                """, ASSESSMENT_MAPPER, jobId);
    }

    public List<IssueValueRow> issueValues(String assessmentId) {
        return jdbc.query("""
                SELECT field_code, value_index, option_value_code, numeric_value, unit_code,
                       text_value, sort_order
                FROM platform_assessment_issue_values
                WHERE assessment_id = ? ORDER BY sort_order, field_code, value_index
                """, (rs, i) -> new IssueValueRow(
                rs.getString("field_code"), rs.getString("value_index"),
                rs.getString("option_value_code"), rs.getBigDecimal("numeric_value"),
                rs.getString("unit_code"), rs.getString("text_value"),
                rs.getInt("sort_order")), assessmentId);
    }

    public List<MeasurementRow> measurements(String assessmentId) {
        return jdbc.query("""
                SELECT field_code, value_index, numeric_value, unit_code, band_id,
                       derived_result_code, derived_score
                FROM platform_assessment_measurements
                WHERE assessment_id = ? ORDER BY field_code, value_index
                """, (rs, i) -> new MeasurementRow(
                rs.getString("field_code"), rs.getString("value_index"),
                rs.getBigDecimal("numeric_value"), rs.getString("unit_code"),
                rs.getString("band_id"), rs.getString("derived_result_code"),
                nullableInt(rs, "derived_score")), assessmentId);
    }

    public String insertAssessment(String jobId, String itemVersionId, String itemCode,
                                   String resultCode, String severityCode,
                                   String suggestedResultCode, Integer suggestedScore,
                                   Integer score, String notesEn, String notesAr,
                                   String reasonCode, Long clientRevision, String assessedBy) {
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_assessments
                    (id, job_id, item_version_id, item_code, result_code, severity_code,
                     suggested_result_code, suggested_score, score, notes_en, notes_ar,
                     reason_code, state, client_revision, server_revision, conflict_state,
                     assessed_by, created_at, updated_at, version)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'COMPLETE', ?, 1, 'NONE', ?, ?, ?, 0)
                """, id, jobId, itemVersionId, itemCode, resultCode, severityCode,
                suggestedResultCode, suggestedScore, score, notesEn, notesAr, reasonCode,
                clientRevision, assessedBy, now(), now());
        return id;
    }

    public void updateAssessment(String assessmentId, String resultCode, String severityCode,
                                 String suggestedResultCode, Integer suggestedScore, Integer score,
                                 String notesEn, String notesAr, String reasonCode,
                                 Long clientRevision, String assessedBy) {
        jdbc.update("""
                UPDATE platform_assessments
                SET result_code = ?, severity_code = ?, suggested_result_code = ?,
                    suggested_score = ?, score = ?, notes_en = ?, notes_ar = ?, reason_code = ?,
                    state = 'COMPLETE', client_revision = ?, server_revision = server_revision + 1,
                    conflict_state = 'NONE', assessed_by = ?, updated_at = ?,
                    version = version + 1
                WHERE id = ?
                """, resultCode, severityCode, suggestedResultCode, suggestedScore, score,
                notesEn, notesAr, reasonCode, clientRevision, assessedBy, now(), assessmentId);
    }

    public void deleteIssueValues(String assessmentId) {
        jdbc.update("DELETE FROM platform_assessment_issue_values WHERE assessment_id = ?",
                assessmentId);
    }

    public void insertIssueValue(String assessmentId, String fieldCode, String valueIndex,
                                 String optionValueCode, BigDecimal numericValue, String unitCode,
                                 String textValue, int sortOrder) {
        jdbc.update("""
                INSERT INTO platform_assessment_issue_values
                    (id, assessment_id, field_code, value_index, option_value_code, numeric_value,
                     unit_code, text_value, sort_order)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, UuidV7.generate().toString(), assessmentId, fieldCode, valueIndex,
                optionValueCode, numericValue, unitCode, textValue, sortOrder);
    }

    public void deleteMeasurements(String assessmentId) {
        jdbc.update("DELETE FROM platform_assessment_measurements WHERE assessment_id = ?",
                assessmentId);
    }

    public void insertMeasurement(String assessmentId, String fieldCode, String valueIndex,
                                  BigDecimal numericValue, String unitCode, String bandId,
                                  String derivedResultCode, Integer derivedScore) {
        jdbc.update("""
                INSERT INTO platform_assessment_measurements
                    (id, assessment_id, field_code, value_index, numeric_value, unit_code,
                     band_id, derived_result_code, derived_score)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, UuidV7.generate().toString(), assessmentId, fieldCode, valueIndex,
                numericValue, unitCode, bandId, derivedResultCode, derivedScore);
    }

    public void insertConflict(String jobId, String itemCode, Long clientRevision,
                               Long serverRevision, String serverPayloadJson,
                               String clientPayloadJson) {
        jdbc.update("""
                INSERT INTO platform_sync_conflicts
                    (id, job_id, item_code, client_revision, server_revision, server_payload_json,
                     client_payload_json, state, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, 'OPEN', ?)
                """, UuidV7.generate().toString(), jobId, itemCode, clientRevision,
                serverRevision, serverPayloadJson, clientPayloadJson, now());
    }

    public List<ConflictRow> conflicts(String jobId, boolean openOnly) {
        String sql = openOnly
                ? "SELECT * FROM platform_sync_conflicts WHERE job_id = ? AND state = 'OPEN' "
                        + "ORDER BY created_at, item_code"
                : "SELECT * FROM platform_sync_conflicts WHERE job_id = ? "
                        + "ORDER BY created_at, item_code";
        return jdbc.query(sql, (rs, i) -> new ConflictRow(
                rs.getString("id"), rs.getString("job_id"), rs.getString("item_code"),
                nullableLong(rs, "client_revision"), nullableLong(rs, "server_revision"),
                rs.getString("server_payload_json"), rs.getString("client_payload_json"),
                rs.getString("state"), dateTime(rs, "created_at"),
                dateTime(rs, "resolved_at")), jobId);
    }

    public void resolveConflicts(String jobId, String itemCode) {
        jdbc.update("""
                UPDATE platform_sync_conflicts
                SET state = 'RESOLVED', resolved_at = ?
                WHERE job_id = ? AND item_code = ? AND state = 'OPEN'
                """, now(), jobId, itemCode);
    }

    // -------------------------------------------------------------- checklist

    public Optional<ChecklistRow> checklist(String jobId) {
        return jdbc.query("SELECT * FROM platform_job_checklists WHERE job_id = ?",
                (rs, i) -> new ChecklistRow(
                        rs.getString("id"), rs.getString("job_id"),
                        rs.getString("template_version_id"), rs.getString("snapshot_json"),
                        rs.getString("snapshot_hash"), dateTime(rs, "created_at")),
                jobId).stream().findFirst();
    }

    public void insertChecklist(String jobId, String templateVersionId, String snapshotJson,
                                String snapshotHash) {
        jdbc.update("""
                INSERT INTO platform_job_checklists
                    (id, job_id, template_version_id, snapshot_json, snapshot_hash, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
                """, UuidV7.generate().toString(), jobId, templateVersionId, snapshotJson,
                snapshotHash, now());
    }

    // --------------------------------------------------------------- evidence

    public List<EvidenceRow> evidence(String jobId, String itemCode) {
        return jdbc.query("""
                SELECT * FROM platform_evidence_assets
                WHERE job_id = ? AND item_code = ? AND status <> 'DELETED'
                ORDER BY captured_at, created_at
                """, EVIDENCE_MAPPER, jobId, itemCode);
    }

    public Optional<EvidenceRow> evidence(String jobId, String itemCode, String evidenceId) {
        return jdbc.query("""
                SELECT * FROM platform_evidence_assets
                WHERE id = ? AND job_id = ? AND item_code = ? AND status <> 'DELETED'
                """, EVIDENCE_MAPPER, evidenceId, jobId, itemCode).stream().findFirst();
    }

    public boolean duplicateSha(String sha256) {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_evidence_assets
                WHERE sha256 = ? AND status <> 'DELETED'
                """, Integer.class, sha256);
        return count != null && count > 0;
    }

    public int evidenceCount(String jobId, String itemCode, String type) {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_evidence_assets
                WHERE job_id = ? AND item_code = ? AND type = ?
                  AND status IN ('UPLOADED', 'VERIFIED')
                """, Integer.class, jobId, itemCode, type);
        return count == null ? 0 : count;
    }

    public void insertEvidence(String id, String jobId, String itemVersionId, String itemCode,
                               String assessmentId, String type, String storageKey,
                               String mime, long bytes, String sha256, LocalDateTime capturedAt,
                               String captureSource, String deviceId, Integer width,
                               Integer height, Long durationMs, String captionEn,
                               String captionAr, String uploadedBy) {
        jdbc.update("""
                INSERT INTO platform_evidence_assets
                    (id, job_id, item_version_id, item_code, assessment_id, type, status,
                     storage_key, normalized_key, mime, bytes, sha256, captured_at,
                     capture_source, device_id, width, height, duration_ms, poster_key,
                     caption_en, caption_ar, quality_status, quality_json, uploaded_by,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, ?, ?, ?, 'PENDING', ?, NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL,
                        ?, ?, 'PENDING', NULL, ?, ?, ?, 0)
                """, id, jobId, itemVersionId, itemCode, assessmentId, type, storageKey, mime,
                bytes, sha256, capturedAt, captureSource, deviceId, width, height, durationMs,
                captionEn, captionAr, uploadedBy, now(), now());
    }

    public void markEvidenceUploaded(String evidenceId) {
        jdbc.update("""
                UPDATE platform_evidence_assets
                SET status = 'UPLOADED', updated_at = ?, version = version + 1
                WHERE id = ?
                """, now(), evidenceId);
    }

    public void completeEvidence(String evidenceId, String captionEn, String captionAr,
                                 String posterKey) {
        jdbc.update("""
                UPDATE platform_evidence_assets
                SET caption_en = ?, caption_ar = ?, poster_key = ?, quality_status = 'PASS',
                    status = 'VERIFIED', updated_at = ?, version = version + 1
                WHERE id = ?
                """, captionEn, captionAr, posterKey, now(), evidenceId);
    }

    public void softDeleteEvidence(String evidenceId, String deletedBy) {
        jdbc.update("""
                UPDATE platform_evidence_assets
                SET status = 'DELETED', deleted_at = ?, deleted_by = ?, updated_at = ?,
                    version = version + 1
                WHERE id = ?
                """, now(), deletedBy, now(), evidenceId);
    }

    public void insertDerivative(String assetId, String kind, String storageKey, String mime,
                                 long bytes, String sha256) {
        jdbc.update("""
                INSERT INTO platform_evidence_derivatives
                    (id, asset_id, kind, storage_key, mime, bytes, sha256, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, UuidV7.generate().toString(), assetId, kind, storageKey, mime, bytes,
                sha256, now());
    }

    // -------------------------------------------------------------- signature

    public Optional<SignatureRow> signature(String jobId) {
        return jdbc.query("SELECT * FROM platform_job_signatures WHERE job_id = ?",
                (rs, i) -> new SignatureRow(
                        rs.getString("id"), rs.getString("job_id"),
                        rs.getString("signer_user_id"), rs.getString("signer_name"),
                        dateTime(rs, "signed_at"), rs.getString("device_id"),
                        rs.getString("method"), rs.getString("storage_key"),
                        rs.getString("signature_hash"), dateTime(rs, "created_at")),
                jobId).stream().findFirst();
    }

    public void upsertSignature(String jobId, String signerUserId, String signerName,
                                LocalDateTime signedAt, String deviceId, String method,
                                String storageKey, String signatureHash) {
        int updated = jdbc.update("""
                UPDATE platform_job_signatures
                SET signer_user_id = ?, signer_name = ?, signed_at = ?, device_id = ?,
                    method = ?, storage_key = ?, signature_hash = ?
                WHERE job_id = ?
                """, signerUserId, signerName, signedAt, deviceId, method, storageKey,
                signatureHash, jobId);
        if (updated == 0) {
            jdbc.update("""
                    INSERT INTO platform_job_signatures
                        (id, job_id, signer_user_id, signer_name, signed_at, device_id, method,
                         storage_key, signature_hash, created_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, UuidV7.generate().toString(), jobId, signerUserId, signerName, signedAt,
                    deviceId, method, storageKey, signatureHash, now());
        }
    }

    // ------------------------------------------------------------ projections

    public void deleteResults(String jobId) {
        jdbc.update("DELETE FROM platform_job_results WHERE job_id = ?", jobId);
    }

    public void insertResult(String jobId, String itemVersionId, String itemCode,
                             String assessmentId, String resultCode, Integer score,
                             Integer scoreSuggested, int photos, int videos, int documents,
                             boolean signaturePresent, String issueValuesJson) {
        jdbc.update("""
                INSERT INTO platform_job_results
                    (id, job_id, item_version_id, item_code, assessment_id, result_code, score,
                     score_suggested, evidence_photo_count, evidence_video_count,
                     evidence_document_count, signature_present, completed_at, issue_values_json,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
                """, UuidV7.generate().toString(), jobId, itemVersionId, itemCode, assessmentId,
                resultCode, score, scoreSuggested, photos, videos, documents, signaturePresent,
                now(), issueValuesJson, now(), now());
    }

    // --------------------------------------------------------------- scoring

    public Optional<ScoringRuleRow> activeScoringRule() {
        return jdbc.query("""
                SELECT id, code, hard_fail_cap_enabled, hard_fail_cap_grade
                FROM platform_scoring_rules WHERE active = TRUE
                ORDER BY created_at, id
                """, (rs, i) -> new ScoringRuleRow(
                rs.getString("id"), rs.getString("code"), rs.getBoolean("hard_fail_cap_enabled"),
                rs.getString("hard_fail_cap_grade"))).stream().findFirst();
    }

    public List<GradeBoundaryRow> gradeBoundaries(String ruleId) {
        return jdbc.query("""
                SELECT grade_code, min_score, max_score, sort_order
                FROM platform_grade_boundaries WHERE scoring_rule_id = ?
                ORDER BY sort_order, min_score
                """, (rs, i) -> new GradeBoundaryRow(
                rs.getString("grade_code"), rs.getInt("min_score"), rs.getInt("max_score"),
                rs.getInt("sort_order")), ruleId);
    }

    public BigDecimal categoryWeight(String categoryId) {
        if (categoryId == null || categoryId.isBlank()) {
            return BigDecimal.ZERO;
        }
        return jdbc.query("SELECT weight_percentage FROM platform_categories WHERE id = ?",
                (rs, i) -> rs.getBigDecimal(1), categoryId).stream().findFirst()
                .orElse(BigDecimal.ZERO);
    }

    // --------------------------------------------------------------- helpers

    private static LocalDateTime now() {
        return LocalDateTime.now(ZoneOffset.UTC);
    }

    private static LocalDateTime dateTime(ResultSet rs, String column) throws SQLException {
        Timestamp value = rs.getTimestamp(column);
        return value == null ? null : value.toLocalDateTime();
    }

    private static Integer nullableInt(ResultSet rs, String column) throws SQLException {
        int value = rs.getInt(column);
        return rs.wasNull() ? null : value;
    }

    private static Long nullableLong(ResultSet rs, String column) throws SQLException {
        long value = rs.getLong(column);
        return rs.wasNull() ? null : value;
    }

    private String decrypt(String value) {
        return value == null || value.isEmpty() ? value : pii.decrypt(value);
    }

    private final RowMapper<JobRow> JOB_MAPPER = (rs, i) -> new JobRow(
            rs.getString("id"), rs.getString("workshop_id"), rs.getString("reference"),
            rs.getString("status"), rs.getString("review_status"),
            rs.getString("template_version_id"), rs.getString("assigned_technician_id"),
            decrypt(rs.getString("customer_name")), decrypt(rs.getString("customer_phone")),
            decrypt(rs.getString("customer_email")), decrypt(rs.getString("vehicle_vin")),
            rs.getString("vehicle_make"), rs.getString("vehicle_model"),
            nullableInt(rs, "vehicle_year"), decrypt(rs.getString("vehicle_plate")),
            nullableInt(rs, "odometer_value"), rs.getString("odometer_unit"),
            rs.getString("transmission"), rs.getString("fuel_type"),
            rs.getString("vehicle_type"), rs.getString("service_type"), rs.getString("scope"),
            rs.getString("preferred_language"), rs.getString("assessment_state"),
            nullableLong(rs, "last_client_revision"), dateTime(rs, "scheduled_at"),
            dateTime(rs, "started_at"), dateTime(rs, "completed_at"),
            nullableInt(rs, "score"), rs.getString("grade_code"),
            rs.getBoolean("safety_cap_applied"), rs.getString("safety_cap_reason"),
            rs.getBoolean("signature_present"), rs.getString("created_by"),
            dateTime(rs, "created_at"), dateTime(rs, "updated_at"), rs.getInt("version"));

    private final RowMapper<OptionRow> OPTION_MAPPER = (rs, i) -> new OptionRow(
            rs.getString("code"), rs.getString("label_en"), rs.getString("label_ar"),
            rs.getInt("sort_order"));

    private final RowMapper<AssessmentRow> ASSESSMENT_MAPPER = (rs, i) -> new AssessmentRow(
            rs.getString("id"), rs.getString("job_id"), rs.getString("item_version_id"),
            rs.getString("item_code"), rs.getString("result_code"),
            rs.getString("severity_code"), rs.getString("suggested_result_code"),
            nullableInt(rs, "suggested_score"), nullableInt(rs, "score"),
            rs.getString("notes_en"), rs.getString("notes_ar"), rs.getString("reason_code"),
            rs.getString("state"), nullableLong(rs, "client_revision"),
            rs.getLong("server_revision"), rs.getString("conflict_state"),
            rs.getString("assessed_by"), dateTime(rs, "created_at"),
            dateTime(rs, "updated_at"), rs.getInt("version"));

    private final RowMapper<EvidenceRow> EVIDENCE_MAPPER = (rs, i) -> new EvidenceRow(
            rs.getString("id"), rs.getString("job_id"), rs.getString("item_version_id"),
            rs.getString("item_code"), rs.getString("assessment_id"), rs.getString("type"),
            rs.getString("status"), rs.getString("storage_key"),
            rs.getString("normalized_key"), rs.getString("mime"), rs.getLong("bytes"),
            rs.getString("sha256"), dateTime(rs, "captured_at"),
            rs.getString("capture_source"), rs.getString("device_id"),
            nullableInt(rs, "width"), nullableInt(rs, "height"),
            nullableLong(rs, "duration_ms"), rs.getString("poster_key"),
            rs.getString("caption_en"), rs.getString("caption_ar"),
            rs.getString("quality_status"), rs.getString("uploaded_by"),
            dateTime(rs, "deleted_at"), rs.getString("deleted_by"),
            dateTime(rs, "created_at"), dateTime(rs, "updated_at"), rs.getInt("version"));
}

