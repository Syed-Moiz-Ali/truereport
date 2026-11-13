package com.truereport.jobs;

import com.truereport.shared.security.PiiCipher;
import com.truereport.shared.uuid.UuidV7;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Clean workshop job store. Reads and writes only platform_* job tables and the
 * published Platform Admin configuration (templates, scoring, document types).
 */
@Repository
public class PlatformJobStore {

    private final JdbcTemplate jdbc;
    private final PiiCipher pii;

    public PlatformJobStore(JdbcTemplate jdbc, PiiCipher pii) {
        this.jdbc = jdbc;
        this.pii = pii;
    }

    // --------------------------------------------------------------- records

    public record JobRow(
            String id, String workshopId, String reference, String status, String reviewStatus,
            String publicationStatus, String templateVersionId, String assignedTechnicianId,
            String customerName, String customerPhone, String customerEmail,
            String vehicleVin, String vehicleMake, String vehicleModel, Integer vehicleYear,
            String vehiclePlate, Integer odometerValue, String odometerUnit,
            String transmission, String fuelType, String preferredLanguage,
            LocalDateTime scheduledAt, LocalDateTime startedAt, LocalDateTime completedAt,
            LocalDateTime approvedAt, LocalDateTime publishedAt, LocalDateTime cancelledAt,
            String approvedBy, String cancelledBy, String cancelReason,
            Integer score, String gradeCode, boolean safetyCapApplied, String safetyCapReason,
            boolean consentGranted, boolean signaturePresent, String createdBy,
            LocalDateTime createdAt, LocalDateTime updatedAt, int version) {
    }

    public record TemplateVersionRow(
            String versionId, String templateId, String code, String nameEn, String nameAr,
            int versionNo, String status) {
    }

    public record TemplateItemRow(
            String itemVersionId, String stableCode, String labelEn, String labelAr,
            String categoryId, String categoryNameEn, String categoryNameAr,
            boolean safetyCritical, String measurementUnit, int sortOrder) {
    }

    public record ResultRow(
            String id, String jobId, String itemVersionId, String resultCode, Integer score,
            int evidencePhotoCount, int evidenceVideoCount, boolean signaturePresent,
            LocalDateTime completedAt, String issueValuesJson) {
    }

    public record AssignmentRow(
            String id, String jobId, String technicianId, String technicianName,
            String assignedBy, LocalDateTime assignedAt, LocalDateTime unassignedAt,
            String reason) {
    }

    public record EvidenceRuleRow(int minPhotos, int minVideos, String requiredEvidenceType) {
    }

    public record ScoringRuleRow(
            String id, String code, boolean hardFailCapEnabled, String hardFailCapGrade) {
    }

    public record GradeBoundaryRow(
            String gradeCode, int minScore, int maxScore, String labelEn, String labelAr,
            int sortOrder) {
    }

    public record ReportVersionRow(
            String id, String jobId, int versionNo, String snapshotJson, String snapshotHash,
            LocalDateTime createdAt) {
    }

    public record LinkRow(
            String id, String jobId, String reportVersionId, String tokenHash,
            String tokenEncrypted, String status, boolean pdfDownloadEnabled,
            LocalDateTime activatedAt, LocalDateTime revokedAt, String revocationReason) {
    }

    public record DocumentRow(
            String id, String reportVersionId, String documentTypeCode, String nameEn,
            String nameAr, String language, String storageKey, String mime, Long bytes,
            String status, LocalDateTime generatedAt, String error) {
    }

    public record NotificationRow(
            String id, String workshopId, String userId, String type, String payloadJson,
            LocalDateTime readAt, LocalDateTime createdAt) {
    }

    public record DocumentTypeRow(String code, String nameEn, String nameAr, int sortOrder) {
    }

    // --------------------------------------------------------------- jobs

    public Optional<JobRow> findJob(String workshopId, String jobId) {
        return jdbc.query("""
                SELECT * FROM platform_jobs WHERE id = ? AND workshop_id = ?
                """, JOB_MAPPER, jobId, workshopId).stream().findFirst();
    }

    public Optional<JobRow> findJobById(String jobId) {
        return jdbc.query("SELECT * FROM platform_jobs WHERE id = ?",
                JOB_MAPPER, jobId).stream().findFirst();
    }

    public List<JobRow> listJobs(String workshopId, String status, String search,
                                 LocalDateTime from, LocalDateTime to, int offset, int limit) {
        StringBuilder sql = new StringBuilder("SELECT * FROM platform_jobs WHERE workshop_id = ?");
        List<Object> args = new ArrayList<>();
        args.add(workshopId);
        if (status != null && !status.isBlank()) {
            sql.append(" AND status = ?");
            args.add(status);
        }
        if (search != null && !search.isBlank()) {
            sql.append("""
                     AND (LOWER(reference) LIKE ? OR LOWER(vehicle_make) LIKE ?
                          OR LOWER(vehicle_model) LIKE ? OR LOWER(vehicle_vin) LIKE ?
                          OR LOWER(vehicle_plate) LIKE ?)
                    """);
            String pattern = "%" + search.trim().toLowerCase() + "%";
            for (int i = 0; i < 5; i++) {
                args.add(pattern);
            }
        }
        if (from != null) {
            sql.append(" AND created_at >= ?");
            args.add(Timestamp.valueOf(from));
        }
        if (to != null) {
            sql.append(" AND created_at <= ?");
            args.add(Timestamp.valueOf(to));
        }
        sql.append(" ORDER BY created_at DESC, id DESC LIMIT ? OFFSET ?");
        args.add(limit);
        args.add(offset);
        return jdbc.query(sql.toString(), JOB_MAPPER, args.toArray());
    }

    public long countJobs(String workshopId, String status, String search,
                          LocalDateTime from, LocalDateTime to) {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM platform_jobs WHERE workshop_id = ?");
        List<Object> args = new ArrayList<>();
        args.add(workshopId);
        if (status != null && !status.isBlank()) {
            sql.append(" AND status = ?");
            args.add(status);
        }
        if (search != null && !search.isBlank()) {
            sql.append("""
                     AND (LOWER(reference) LIKE ? OR LOWER(vehicle_make) LIKE ?
                          OR LOWER(vehicle_model) LIKE ? OR LOWER(vehicle_vin) LIKE ?
                          OR LOWER(vehicle_plate) LIKE ?)
                    """);
            String pattern = "%" + search.trim().toLowerCase() + "%";
            for (int i = 0; i < 5; i++) {
                args.add(pattern);
            }
        }
        if (from != null) {
            sql.append(" AND created_at >= ?");
            args.add(Timestamp.valueOf(from));
        }
        if (to != null) {
            sql.append(" AND created_at <= ?");
            args.add(Timestamp.valueOf(to));
        }
        Long count = jdbc.queryForObject(sql.toString(), Long.class, args.toArray());
        return count == null ? 0 : count;
    }

    public List<String> statuses(String workshopId) {
        return jdbc.queryForList(
                "SELECT status FROM platform_jobs WHERE workshop_id = ?", String.class, workshopId);
    }

    public boolean referenceExists(String workshopId, String reference) {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_jobs WHERE workshop_id = ? AND reference = ?
                """, Integer.class, workshopId, reference);
        return count != null && count > 0;
    }

    public String insertJob(JobRow job) {
        String id = job.id() == null ? UuidV7.generate().toString() : job.id();
        jdbc.update("""
                INSERT INTO platform_jobs
                    (id, workshop_id, reference, status, review_status, publication_status,
                     template_version_id, assigned_technician_id, customer_name, customer_phone,
                     customer_email, vehicle_vin, vehicle_make, vehicle_model, vehicle_year,
                     vehicle_plate, odometer_value, odometer_unit, transmission, fuel_type,
                     preferred_language, scheduled_at, consent_granted, signature_present,
                     created_by, created_at, updated_at, version)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
                """, id, job.workshopId(), job.reference(), job.status(), job.reviewStatus(),
                job.publicationStatus(), job.templateVersionId(), job.assignedTechnicianId(),
                pii.encrypt(job.customerName()), pii.encrypt(job.customerPhone()),
                encryptNullable(job.customerEmail()), pii.encrypt(job.vehicleVin()),
                job.vehicleMake(), job.vehicleModel(), job.vehicleYear(),
                pii.encrypt(job.vehiclePlate()), job.odometerValue(), job.odometerUnit(),
                job.transmission(), job.fuelType(), job.preferredLanguage(),
                job.scheduledAt(), job.consentGranted(), job.signaturePresent(),
                job.createdBy(), now(), now());
        return id;
    }

    public int updateCustomerVehicle(JobRow current, String customerName, String customerPhone,
                                     String customerEmail, String vehicleVin, String vehicleMake,
                                     String vehicleModel, Integer vehicleYear, String vehiclePlate,
                                     Integer odometerValue, String odometerUnit,
                                     String transmission, String fuelType,
                                     String preferredLanguage, int expectedVersion) {
        return jdbc.update("""
                UPDATE platform_jobs
                SET customer_name = ?, customer_phone = ?, customer_email = ?, vehicle_vin = ?,
                    vehicle_make = ?, vehicle_model = ?, vehicle_year = ?, vehicle_plate = ?,
                    odometer_value = ?, odometer_unit = ?, transmission = ?, fuel_type = ?,
                    preferred_language = ?, updated_at = ?, version = version + 1
                WHERE id = ? AND version = ?
                """, pii.encrypt(customerName), pii.encrypt(customerPhone),
                encryptNullable(customerEmail), pii.encrypt(vehicleVin), vehicleMake,
                vehicleModel, vehicleYear, pii.encrypt(vehiclePlate), odometerValue,
                odometerUnit, transmission, fuelType, preferredLanguage, now(),
                current.id(), expectedVersion);
    }

    public int assign(String jobId, int expectedVersion, String technicianId, String status) {
        return jdbc.update("""
                UPDATE platform_jobs
                SET assigned_technician_id = ?, status = ?, updated_at = ?, version = version + 1
                WHERE id = ? AND version = ?
                """, technicianId, status, now(), jobId, expectedVersion);
    }

    public int unassign(String jobId, int expectedVersion) {
        return jdbc.update("""
                UPDATE platform_jobs
                SET assigned_technician_id = NULL, updated_at = ?, version = version + 1
                WHERE id = ? AND version = ?
                """, now(), jobId, expectedVersion);
    }

    public int cancel(String jobId, int expectedVersion, String actorId, String reason) {
        return jdbc.update("""
                UPDATE platform_jobs
                SET status = 'CANCELLED', cancelled_at = ?, cancelled_by = ?, cancel_reason = ?,
                    updated_at = ?, version = version + 1
                WHERE id = ? AND version = ?
                """, now(), actorId, reason, now(), jobId, expectedVersion);
    }

    public int approve(String jobId, int expectedVersion, String actorId, int score,
                       String gradeCode, boolean safetyCapApplied, String safetyCapReason) {
        return jdbc.update("""
                UPDATE platform_jobs
                SET status = 'APPROVED', review_status = 'APPROVED', approved_at = ?,
                    approved_by = ?, completed_at = COALESCE(completed_at, ?), score = ?,
                    grade_code = ?, safety_cap_applied = ?, safety_cap_reason = ?,
                    updated_at = ?, version = version + 1
                WHERE id = ? AND version = ?
                """, now(), actorId, now(), score, gradeCode, safetyCapApplied,
                safetyCapReason, now(), jobId, expectedVersion);
    }

    public int reject(String jobId, int expectedVersion, String actorId) {
        return jdbc.update("""
                UPDATE platform_jobs
                SET status = 'REJECTED', review_status = 'REJECTED', approved_at = ?,
                    approved_by = ?, updated_at = ?, version = version + 1
                WHERE id = ? AND version = ?
                """, now(), actorId, now(), jobId, expectedVersion);
    }

    public int publish(String jobId, int expectedVersion) {
        return jdbc.update("""
                UPDATE platform_jobs
                SET status = 'PUBLISHED', publication_status = 'PUBLISHED', published_at = ?,
                    updated_at = ?, version = version + 1
                WHERE id = ? AND version = ?
                """, now(), now(), jobId, expectedVersion);
    }

    public int updatePublication(String jobId, int expectedVersion, String publicationStatus,
                                 String status) {
        return jdbc.update("""
                UPDATE platform_jobs
                SET publication_status = ?, status = ?, updated_at = ?, version = version + 1
                WHERE id = ? AND version = ?
                """, publicationStatus, status, now(), jobId, expectedVersion);
    }

    public int updateScorePreview(String jobId, int expectedVersion, int score, String grade,
                                  boolean capApplied, String capReason) {
        return jdbc.update("""
                UPDATE platform_jobs
                SET score = ?, grade_code = ?, safety_cap_applied = ?, safety_cap_reason = ?,
                    updated_at = ?, version = version + 1
                WHERE id = ? AND version = ?
                """, score, grade, capApplied, capReason, now(), jobId, expectedVersion);
    }

    public int setConsent(String jobId, int expectedVersion, boolean consent) {
        return jdbc.update("""
                UPDATE platform_jobs SET consent_granted = ?, updated_at = ?, version = version + 1
                WHERE id = ? AND version = ?
                """, consent, now(), jobId, expectedVersion);
    }

    // ---------------------------------------------------------- assignments

    public void insertAssignment(String jobId, String technicianId, String assignedBy,
                                 String reason) {
        jdbc.update("""
                INSERT INTO platform_job_assignments
                    (id, job_id, technician_id, assigned_by, assigned_at, reason)
                VALUES (?, ?, ?, ?, ?, ?)
                """, UuidV7.generate().toString(), jobId, technicianId, assignedBy, now(), reason);
    }

    public void closeAssignments(String jobId, String reason) {
        jdbc.update("""
                UPDATE platform_job_assignments
                SET unassigned_at = ?, reason = COALESCE(?, reason)
                WHERE job_id = ? AND unassigned_at IS NULL
                """, now(), reason, jobId);
    }

    public List<AssignmentRow> assignments(String jobId) {
        return jdbc.query("""
                SELECT a.id, a.job_id, a.technician_id, a.assigned_by, a.assigned_at,
                       a.unassigned_at, a.reason
                FROM platform_job_assignments a
                WHERE a.job_id = ?
                ORDER BY a.assigned_at DESC, a.id
                """, (rs, i) -> new AssignmentRow(
                rs.getString("id"), rs.getString("job_id"), rs.getString("technician_id"),
                null, rs.getString("assigned_by"),
                dateTime(rs, "assigned_at"), dateTime(rs, "unassigned_at"),
                rs.getString("reason")), jobId);
    }

    // ------------------------------------------------------------- history

    public void insertApproval(String jobId, String actorId, String decision, String reason) {
        jdbc.update("""
                INSERT INTO platform_job_approvals
                    (id, job_id, approved_by, approved_at, decision, reason)
                VALUES (?, ?, ?, ?, ?, ?)
                """, UuidV7.generate().toString(), jobId, actorId, now(), decision, reason);
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

    // -------------------------------------------------------------- results

    public List<ResultRow> results(String jobId) {
        return jdbc.query("""
                SELECT * FROM platform_job_results WHERE job_id = ? ORDER BY created_at, id
                """, (rs, i) -> new ResultRow(
                rs.getString("id"), rs.getString("job_id"), rs.getString("item_version_id"),
                rs.getString("result_code"), nullableInt(rs, "score"),
                rs.getInt("evidence_photo_count"), rs.getInt("evidence_video_count"),
                rs.getBoolean("signature_present"), dateTime(rs, "completed_at"),
                rs.getString("issue_values_json")), jobId);
    }

    public void insertResult(String jobId, String itemVersionId, String resultCode, Integer score,
                             int photos, int videos, boolean signaturePresent,
                             String issueValuesJson) {
        jdbc.update("""
                INSERT INTO platform_job_results
                    (id, job_id, item_version_id, result_code, score, evidence_photo_count,
                     evidence_video_count, signature_present, completed_at, issue_values_json,
                     created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, UuidV7.generate().toString(), jobId, itemVersionId, resultCode, score,
                photos, videos, signaturePresent, now(), issueValuesJson, now(), now());
    }

    public Optional<EvidenceRuleRow> evidenceRule(String itemVersionId, String resultCode) {
        return jdbc.query("""
                SELECT min_photos, min_videos, required_evidence_type
                FROM platform_evidence_rules
                WHERE item_version_id = ? AND result_code = ?
                """, (rs, i) -> new EvidenceRuleRow(
                rs.getInt("min_photos"), rs.getInt("min_videos"),
                rs.getString("required_evidence_type")), itemVersionId, resultCode)
                .stream().findFirst();
    }

    // -------------------------------------------------------------- templates

    public List<TemplateVersionRow> availableTemplates() {
        return jdbc.query("""
                SELECT v.id AS version_id, v.template_id, t.code,
                       t.name AS name_en,
                       (SELECT body FROM platform_translations pt
                        WHERE pt.entity_type = 'TEMPLATE' AND pt.entity_id = t.id
                          AND pt.field_name = 'name' AND pt.lang = 'ar') AS name_ar,
                       v.version_no, v.status
                FROM platform_template_versions v
                JOIN platform_templates t ON t.id = v.template_id
                WHERE v.status = 'PUBLISHED' AND t.status = 'ACTIVE'
                  AND (t.current_published_version_id IS NULL
                       OR t.current_published_version_id = v.id)
                ORDER BY t.code, v.version_no DESC
                """, TEMPLATE_VERSION_MAPPER);
    }

    public Optional<TemplateVersionRow> templateVersion(String versionId) {
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
                """, TEMPLATE_VERSION_MAPPER, versionId).stream().findFirst();
    }

    public int templateItemCount(String versionId) {
        Integer count = jdbc.queryForObject("""
                SELECT COUNT(*) FROM platform_template_items
                WHERE template_version_id = ? AND included = TRUE
                """, Integer.class, versionId);
        return count == null ? 0 : count;
    }

    public List<TemplateItemRow> templateItems(String versionId) {
        return jdbc.query("""
                SELECT ti.item_version_id, i.stable_code,
                       v.label AS label_en,
                       (SELECT body FROM platform_translations pt
                        WHERE pt.entity_type = 'ITEM' AND pt.entity_id = v.id
                          AND pt.field_name = 'label' AND pt.lang = 'ar') AS label_ar,
                       i.category_id,
                       c.name AS category_name_en,
                       (SELECT body FROM platform_translations pt
                        WHERE pt.entity_type = 'CATEGORY' AND pt.entity_id = c.id
                          AND pt.field_name = 'name' AND pt.lang = 'ar') AS category_name_ar,
                       v.safety_critical, v.measurement_unit, ti.sort_order,
                       c.weight_percentage
                FROM platform_template_items ti
                JOIN platform_item_versions v ON v.id = ti.item_version_id
                JOIN platform_items i ON i.id = v.item_id
                JOIN platform_categories c ON c.id = i.category_id
                WHERE ti.template_version_id = ? AND ti.included = TRUE
                ORDER BY ti.sort_order, i.sort_order, i.stable_code
                """, (rs, i) -> new TemplateItemRow(
                rs.getString("item_version_id"), rs.getString("stable_code"),
                rs.getString("label_en"), rs.getString("label_ar"), rs.getString("category_id"),
                rs.getString("category_name_en"), rs.getString("category_name_ar"),
                rs.getBoolean("safety_critical"), rs.getString("measurement_unit"),
                rs.getInt("sort_order")), versionId);
    }

    public java.math.BigDecimal categoryWeight(String categoryId) {
        if (categoryId == null || categoryId.isBlank()) {
            return java.math.BigDecimal.ZERO;
        }
        return jdbc.query("SELECT weight_percentage FROM platform_categories WHERE id = ?",
                (rs, i) -> rs.getBigDecimal(1), categoryId).stream().findFirst()
                .orElse(java.math.BigDecimal.ZERO);
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
                SELECT g.grade_code, g.min_score, g.max_score,
                       g.label AS label_en,
                       (SELECT body FROM platform_translations pt
                        WHERE pt.entity_type = 'GRADE_BOUNDARY' AND pt.entity_id = g.id
                          AND pt.field_name = 'label' AND pt.lang = 'ar') AS label_ar,
                       g.sort_order
                FROM platform_grade_boundaries g WHERE g.scoring_rule_id = ?
                ORDER BY g.sort_order, g.min_score
                """, (rs, i) -> new GradeBoundaryRow(
                rs.getString("grade_code"), rs.getInt("min_score"), rs.getInt("max_score"),
                rs.getString("label_en"), rs.getString("label_ar"), rs.getInt("sort_order")),
                ruleId);
    }

    // ------------------------------------------------------- report versions

    public String insertReportVersion(String jobId, int versionNo, String snapshotJson,
                                      String snapshotHash, String createdBy) {
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_report_versions
                    (id, job_id, version_no, snapshot_json, snapshot_hash, created_by, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """, id, jobId, versionNo, snapshotJson, snapshotHash, createdBy, now());
        return id;
    }

    public int nextReportVersionNo(String jobId) {
        Integer value = jdbc.queryForObject("""
                SELECT COALESCE(MAX(version_no), 0) FROM platform_report_versions WHERE job_id = ?
                """, Integer.class, jobId);
        return (value == null ? 0 : value) + 1;
    }

    public Optional<ReportVersionRow> latestReportVersion(String jobId) {
        return jdbc.query("""
                SELECT * FROM platform_report_versions WHERE job_id = ?
                ORDER BY version_no DESC
                """, (rs, i) -> new ReportVersionRow(
                rs.getString("id"), rs.getString("job_id"), rs.getInt("version_no"),
                rs.getString("snapshot_json"), rs.getString("snapshot_hash"),
                dateTime(rs, "created_at")), jobId).stream().findFirst();
    }

    // ---------------------------------------------------------- public links

    public Optional<LinkRow> latestLink(String jobId) {
        return jdbc.query("""
                SELECT * FROM platform_public_links WHERE job_id = ?
                ORDER BY created_at DESC, id DESC
                """, LINK_MAPPER, jobId).stream().findFirst();
    }

    public Optional<LinkRow> activeLink(String jobId) {
        return jdbc.query("""
                SELECT * FROM platform_public_links WHERE job_id = ? AND status = 'ACTIVE'
                ORDER BY created_at DESC
                """, LINK_MAPPER, jobId).stream().findFirst();
    }

    public String insertLink(String jobId, String reportVersionId, String tokenHash,
                             String encryptedToken, boolean pdfDownloadEnabled) {
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_public_links
                    (id, job_id, report_version_id, token_hash, token_encrypted, status,
                     pdf_download_enabled, activated_at, created_at, updated_at, version)
                VALUES (?, ?, ?, ?, ?, 'ACTIVE', ?, ?, ?, ?, 0)
                """, id, jobId, reportVersionId, tokenHash, encryptedToken, pdfDownloadEnabled,
                now(), now(), now());
        return id;
    }

    public void rotateLink(String linkId, String tokenHash, String encryptedToken) {
        jdbc.update("""
                UPDATE platform_public_links
                SET token_hash = ?, token_encrypted = ?, activated_at = ?, updated_at = ?,
                    version = version + 1
                WHERE id = ?
                """, tokenHash, encryptedToken, now(), now(), linkId);
    }

    public void revokeLink(String linkId, String reason) {
        jdbc.update("""
                UPDATE platform_public_links
                SET status = 'REVOKED', revoked_at = ?, revocation_reason = ?, updated_at = ?,
                    version = version + 1
                WHERE id = ?
                """, now(), reason, now(), linkId);
    }

    public void setPdfDownload(String linkId, boolean enabled) {
        jdbc.update("""
                UPDATE platform_public_links
                SET pdf_download_enabled = ?, updated_at = ?, version = version + 1
                WHERE id = ?
                """, enabled, now(), linkId);
    }

    // ------------------------------------------------------------ documents

    public List<DocumentTypeRow> activeDocumentTypes() {
        return jdbc.query("""
                SELECT d.code, d.name AS name_en,
                       (SELECT body FROM platform_translations pt
                        WHERE pt.entity_type = 'DOCUMENT_TYPE' AND pt.entity_id = d.id
                          AND pt.field_name = 'name' AND pt.lang = 'ar') AS name_ar,
                       d.sort_order
                FROM platform_document_types d
                WHERE d.status = 'ACTIVE' ORDER BY d.sort_order, d.code
                """, (rs, i) -> new DocumentTypeRow(
                rs.getString("code"), rs.getString("name_en"), rs.getString("name_ar"),
                rs.getInt("sort_order")));
    }

    public Optional<DocumentTypeRow> documentType(String code) {
        return jdbc.query("""
                SELECT d.code, d.name AS name_en,
                       (SELECT body FROM platform_translations pt
                        WHERE pt.entity_type = 'DOCUMENT_TYPE' AND pt.entity_id = d.id
                          AND pt.field_name = 'name' AND pt.lang = 'ar') AS name_ar,
                       d.sort_order
                FROM platform_document_types d
                WHERE d.code = ?
                """, (rs, i) -> new DocumentTypeRow(
                rs.getString("code"), rs.getString("name_en"), rs.getString("name_ar"),
                rs.getInt("sort_order")), code).stream().findFirst();
    }

    public String insertDocument(String reportVersionId, String documentTypeCode, String language) {
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_report_documents
                    (id, report_version_id, document_type_code, language, status,
                     created_at, updated_at, version)
                VALUES (?, ?, ?, ?, 'PENDING', ?, ?, 0)
                """, id, reportVersionId, documentTypeCode, language, now(), now());
        return id;
    }

    public void markDocumentReady(String id, String storageKey, String mime, long bytes) {
        jdbc.update("""
                UPDATE platform_report_documents
                SET storage_key = ?, mime = ?, bytes = ?, status = 'READY', generated_at = ?,
                    error = NULL, updated_at = ?, version = version + 1
                WHERE id = ?
                """, storageKey, mime, bytes, now(), now(), id);
    }

    public void markDocumentFailed(String id, String error) {
        jdbc.update("""
                UPDATE platform_report_documents
                SET status = 'FAILED', error = ?, updated_at = ?, version = version + 1
                WHERE id = ?
                """, trim(error, 1000), now(), id);
    }

    public List<DocumentRow> documents(String reportVersionId) {
        return jdbc.query("""
                SELECT d.*, t.name AS name_en,
                       (SELECT body FROM platform_translations pt
                        WHERE pt.entity_type = 'DOCUMENT_TYPE' AND pt.entity_id = t.id
                          AND pt.field_name = 'name' AND pt.lang = 'ar') AS name_ar
                FROM platform_report_documents d
                LEFT JOIN platform_document_types t ON t.code = d.document_type_code
                WHERE d.report_version_id = ?
                ORDER BY t.sort_order, d.document_type_code, d.language
                """, DOCUMENT_MAPPER, reportVersionId);
    }

    public List<DocumentRow> documents(String reportVersionId, String documentTypeCode) {
        return jdbc.query("""
                SELECT d.*, t.name AS name_en,
                       (SELECT body FROM platform_translations pt
                        WHERE pt.entity_type = 'DOCUMENT_TYPE' AND pt.entity_id = t.id
                          AND pt.field_name = 'name' AND pt.lang = 'ar') AS name_ar
                FROM platform_report_documents d
                LEFT JOIN platform_document_types t ON t.code = d.document_type_code
                WHERE d.report_version_id = ? AND d.document_type_code = ?
                ORDER BY d.language
                """, DOCUMENT_MAPPER, reportVersionId, documentTypeCode);
    }

    public Optional<DocumentRow> document(String id) {
        return jdbc.query("""
                SELECT d.*, t.name AS name_en,
                       (SELECT body FROM platform_translations pt
                        WHERE pt.entity_type = 'DOCUMENT_TYPE' AND pt.entity_id = t.id
                          AND pt.field_name = 'name' AND pt.lang = 'ar') AS name_ar
                FROM platform_report_documents d
                LEFT JOIN platform_document_types t ON t.code = d.document_type_code
                WHERE d.id = ?
                """, DOCUMENT_MAPPER, id).stream().findFirst();
    }

    // --------------------------------------------------------- notifications

    public String insertNotification(String workshopId, String userId, String type,
                                     String payloadJson) {
        String id = UuidV7.generate().toString();
        jdbc.update("""
                INSERT INTO platform_notifications
                    (id, workshop_id, user_id, type, payload_json, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
                """, id, workshopId, userId, type, payloadJson, now());
        return id;
    }

    public List<NotificationRow> notifications(String workshopId, String userId,
                                               boolean unreadOnly) {
        String sql = unreadOnly
                ? "SELECT * FROM platform_notifications WHERE workshop_id = ? AND user_id = ? "
                        + "AND read_at IS NULL ORDER BY created_at DESC"
                : "SELECT * FROM platform_notifications WHERE workshop_id = ? AND user_id = ? "
                        + "ORDER BY created_at DESC";
        return jdbc.query(sql, (rs, i) -> new NotificationRow(
                rs.getString("id"), rs.getString("workshop_id"), rs.getString("user_id"),
                rs.getString("type"), rs.getString("payload_json"), dateTime(rs, "read_at"),
                dateTime(rs, "created_at")), workshopId, userId);
    }

    public Optional<NotificationRow> notification(String workshopId, String userId, String id) {
        return jdbc.query("""
                SELECT * FROM platform_notifications
                WHERE id = ? AND workshop_id = ? AND user_id = ?
                """, (rs, i) -> new NotificationRow(
                rs.getString("id"), rs.getString("workshop_id"), rs.getString("user_id"),
                rs.getString("type"), rs.getString("payload_json"), dateTime(rs, "read_at"),
                dateTime(rs, "created_at")), id, workshopId, userId).stream().findFirst();
    }

    public void markNotificationRead(String id) {
        jdbc.update("""
                UPDATE platform_notifications SET read_at = COALESCE(read_at, ?) WHERE id = ?
                """, now(), id);
    }

    // -------------------------------------------------------------- helpers

    private String encryptNullable(String value) {
        return value == null || value.isBlank() ? null : pii.encrypt(value);
    }

    private static String trim(String value, int max) {
        if (value == null) {
            return null;
        }
        return value.length() <= max ? value : value.substring(0, max);
    }

    private static LocalDateTime now() {
        return LocalDateTime.now(ZoneOffset.UTC);
    }

    private static LocalDateTime dateTime(java.sql.ResultSet rs, String column)
            throws java.sql.SQLException {
        Timestamp value = rs.getTimestamp(column);
        return value == null ? null : value.toLocalDateTime();
    }

    private static Integer nullableInt(java.sql.ResultSet rs, String column)
            throws java.sql.SQLException {
        int value = rs.getInt(column);
        return rs.wasNull() ? null : value;
    }

    private final RowMapper<JobRow> JOB_MAPPER = (rs, i) -> new JobRow(
            rs.getString("id"), rs.getString("workshop_id"), rs.getString("reference"),
            rs.getString("status"), rs.getString("review_status"),
            rs.getString("publication_status"), rs.getString("template_version_id"),
            rs.getString("assigned_technician_id"),
            decrypt(rs.getString("customer_name")), decrypt(rs.getString("customer_phone")),
            decrypt(rs.getString("customer_email")), decrypt(rs.getString("vehicle_vin")),
            rs.getString("vehicle_make"), rs.getString("vehicle_model"),
            nullableInt(rs, "vehicle_year"), decrypt(rs.getString("vehicle_plate")),
            nullableInt(rs, "odometer_value"), rs.getString("odometer_unit"),
            rs.getString("transmission"), rs.getString("fuel_type"),
            rs.getString("preferred_language"), dateTime(rs, "scheduled_at"),
            dateTime(rs, "started_at"), dateTime(rs, "completed_at"),
            dateTime(rs, "approved_at"), dateTime(rs, "published_at"),
            dateTime(rs, "cancelled_at"), rs.getString("approved_by"),
            rs.getString("cancelled_by"), rs.getString("cancel_reason"),
            nullableInt(rs, "score"), rs.getString("grade_code"),
            rs.getBoolean("safety_cap_applied"), rs.getString("safety_cap_reason"),
            rs.getBoolean("consent_granted"), rs.getBoolean("signature_present"),
            rs.getString("created_by"), dateTime(rs, "created_at"),
            dateTime(rs, "updated_at"), rs.getInt("version"));

    private final RowMapper<TemplateVersionRow> TEMPLATE_VERSION_MAPPER = (rs, i) ->
            new TemplateVersionRow(
                    rs.getString("version_id"), rs.getString("template_id"),
                    rs.getString("code"), rs.getString("name_en"), rs.getString("name_ar"),
                    rs.getInt("version_no"), rs.getString("status"));

    private final RowMapper<LinkRow> LINK_MAPPER = (rs, i) -> new LinkRow(
            rs.getString("id"), rs.getString("job_id"), rs.getString("report_version_id"),
            rs.getString("token_hash"), rs.getString("token_encrypted"), rs.getString("status"),
            rs.getBoolean("pdf_download_enabled"), dateTime(rs, "activated_at"),
            dateTime(rs, "revoked_at"), rs.getString("revocation_reason"));

    private final RowMapper<DocumentRow> DOCUMENT_MAPPER = (rs, i) -> new DocumentRow(
            rs.getString("id"), rs.getString("report_version_id"),
            rs.getString("document_type_code"), rs.getString("name_en"), rs.getString("name_ar"),
            rs.getString("language"), rs.getString("storage_key"), rs.getString("mime"),
            nullableLong(rs, "bytes"), rs.getString("status"), dateTime(rs, "generated_at"),
            rs.getString("error"));

    private static Long nullableLong(java.sql.ResultSet rs, String column)
            throws java.sql.SQLException {
        long value = rs.getLong(column);
        return rs.wasNull() ? null : value;
    }

    private String decrypt(String value) {
        return value == null || value.isEmpty() ? value : pii.decrypt(value);
    }
}

