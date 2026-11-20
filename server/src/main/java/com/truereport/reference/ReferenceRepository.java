package com.truereport.reference;

import com.truereport.reference.api.ReferenceDtos.ImpactDto;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public class ReferenceRepository {

    public record ReferenceRow(String domainKey, String code, String labelKey, String tone,
                               String icon, int sortOrder, boolean selectable,
                               String visibleForJson, String allowedNextJson, String status,
                               int version) {
    }

    public record TransitionRow(String entity, String fromCode, String toCode, String role,
                                String guardJson, int version) {
    }

    public record OptionSetRow(String id, String code, String status) {
    }

    public record OptionValueRow(String code, String label, String status, int sortOrder,
                                 String metadataJson, int version) {
    }

    private final JdbcTemplate jdbc;

    public ReferenceRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<ReferenceRow> findDomain(String domainType, String domainKey,
                                         boolean includeDraft) {
        String statuses = includeDraft
                ? "('PUBLISHED', 'DRAFT', 'RETIRED')" : "('PUBLISHED')";
        return jdbc.query("""
                SELECT domain_key, code, label_key, tone, icon, sort_order, selectable,
                       visible_for_json, allowed_next_json, status, version
                FROM reference_domain
                WHERE domain_type = ? AND domain_key = ? AND status IN %s
                ORDER BY sort_order, code
                """.formatted(statuses), (rs, i) -> new ReferenceRow(
                rs.getString("domain_key"), rs.getString("code"),
                rs.getString("label_key"), rs.getString("tone"), rs.getString("icon"),
                rs.getInt("sort_order"), rs.getBoolean("selectable"),
                rs.getString("visible_for_json"), rs.getString("allowed_next_json"),
                rs.getString("status"), rs.getInt("version")), domainType, domainKey);
    }

    public Optional<ReferenceRow> find(String domainKey, String code) {
        return jdbc.query("""
                SELECT domain_key, code, label_key, tone, icon, sort_order, selectable,
                       visible_for_json, allowed_next_json, status, version
                FROM reference_domain
                WHERE domain_key = ? AND code = ?
                """, (rs, i) -> new ReferenceRow(
                rs.getString("domain_key"), rs.getString("code"),
                rs.getString("label_key"), rs.getString("tone"), rs.getString("icon"),
                rs.getInt("sort_order"), rs.getBoolean("selectable"),
                rs.getString("visible_for_json"), rs.getString("allowed_next_json"),
                rs.getString("status"), rs.getInt("version")), domainKey, code)
                .stream().findFirst();
    }

    public void insert(String domainType, String domainKey, String code, String labelKey,
                       String tone, String icon, int sortOrder, boolean selectable,
                       String visibleForJson, String allowedNextJson, String status) {
        jdbc.update("""
                INSERT INTO reference_domain
                    (id, domain_type, domain_key, code, label_key, tone, icon, sort_order,
                     selectable, visible_for_json, allowed_next_json, status, version,
                     created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """, ReferenceSeeder.idBytes(com.truereport.shared.uuid.UuidV7.generate()),
                domainType, domainKey, code, labelKey, tone, icon, sortOrder, selectable,
                visibleForJson, allowedNextJson, status);
    }

    public void update(String domainKey, String code, String labelKey, String tone, String icon,
                       int sortOrder, boolean selectable, String visibleForJson,
                       String allowedNextJson) {
        jdbc.update("""
                UPDATE reference_domain
                SET label_key = ?, tone = ?, icon = ?, sort_order = ?, selectable = ?,
                    visible_for_json = ?, allowed_next_json = ?, version = version + 1,
                    updated_at = CURRENT_TIMESTAMP
                WHERE domain_key = ? AND code = ?
                """, labelKey, tone, icon, sortOrder, selectable, visibleForJson,
                allowedNextJson, domainKey, code);
    }

    public void updateStatus(String domainKey, String code, String status) {
        jdbc.update("""
                UPDATE reference_domain
                SET status = ?, version = version + 1, updated_at = CURRENT_TIMESTAMP
                WHERE domain_key = ? AND code = ?
                """, status, domainKey, code);
    }

    public void updateOrder(String domainKey, String code, int sortOrder) {
        jdbc.update("""
                UPDATE reference_domain
                SET sort_order = ?, version = version + 1, updated_at = CURRENT_TIMESTAMP
                WHERE domain_key = ? AND code = ?
                """, sortOrder, domainKey, code);
    }

    public List<TransitionRow> findTransitions(String entity) {
        return jdbc.query("""
                SELECT entity, from_code, to_code, role, guard_json, version
                FROM status_transition
                WHERE entity = ?
                ORDER BY from_code, to_code, role
                """, (rs, i) -> new TransitionRow(
                rs.getString("entity"), rs.getString("from_code"), rs.getString("to_code"),
                rs.getString("role"), rs.getString("guard_json"), rs.getInt("version")),
                entity);
    }

    public void deleteTransitions(String entity) {
        jdbc.update("DELETE FROM status_transition WHERE entity = ?", entity);
    }

    public void insertTransition(String entity, String fromCode, String toCode, String role,
                                 String guardJson) {
        jdbc.update("""
                INSERT INTO status_transition
                    (id, entity, from_code, to_code, role, guard_json, version)
                VALUES (?, ?, ?, ?, ?, ?, 0)
                """, ReferenceSeeder.idBytes(com.truereport.shared.uuid.UuidV7.generate()),
                entity, fromCode, toCode, role, guardJson);
    }

    public Optional<OptionSetRow> findOptionSet(String code) {
        return jdbc.query("""
                SELECT id, code, status FROM platform_option_sets WHERE code = ?
                """, (rs, i) -> new OptionSetRow(
                rs.getString("id"), rs.getString("code"), rs.getString("status")), code)
                .stream().findFirst();
    }

    public List<OptionValueRow> findOptionValues(String optionSetId) {
        return jdbc.query("""
                SELECT code, label, status, sort_order, metadata_json, version
                FROM platform_option_values
                WHERE option_set_id = ?
                ORDER BY sort_order, code
                """, (rs, i) -> new OptionValueRow(
                rs.getString("code"), rs.getString("label"), rs.getString("status"),
                rs.getInt("sort_order"), rs.getString("metadata_json"), rs.getInt("version")),
                optionSetId);
    }

    public ImpactDto impact(String domainKey, String code) {
        int jobs = switch (domainKey) {
            case ReferenceTaxonomy.JOB_STATUS -> count(
                    "SELECT COUNT(*) FROM platform_jobs WHERE status = ?", code);
            case ReferenceTaxonomy.REVIEW_STATUS -> count(
                    "SELECT COUNT(*) FROM platform_jobs WHERE review_status = ?", code);
            case ReferenceTaxonomy.PUBLICATION_STATUS -> count(
                    "SELECT COUNT(*) FROM platform_jobs WHERE publication_status = ?", code);
            case ReferenceTaxonomy.GRADE -> count(
                    "SELECT COUNT(*) FROM platform_jobs WHERE grade_code = ?", code);
            case ReferenceTaxonomy.SEVERITY -> count(
                    "SELECT COUNT(DISTINCT job_id) FROM platform_assessments WHERE severity_code = ?", code);
            case ReferenceTaxonomy.RESULT -> count(
                    "SELECT COUNT(DISTINCT job_id) FROM platform_assessments WHERE result_code = ?", code);
            default -> 0;
        };
        int items = switch (domainKey) {
            case ReferenceTaxonomy.MEASUREMENT_UNIT -> count(
                    "SELECT COUNT(*) FROM platform_item_versions WHERE measurement_unit = ?", code);
            case ReferenceTaxonomy.EVIDENCE_TYPE -> count(
                    "SELECT COUNT(*) FROM platform_evidence_assets WHERE type = ?", code);
            default -> 0;
        };
        int templates = switch (domainKey) {
            case ReferenceTaxonomy.TEMPLATE_STATUS -> count(
                    "SELECT COUNT(*) FROM platform_template_versions WHERE status = ?", code);
            default -> 0;
        };
        int documents = switch (domainKey) {
            case ReferenceTaxonomy.DOCUMENT_STATUS -> count(
                    "SELECT COUNT(*) FROM platform_report_documents WHERE status = ?", code);
            default -> 0;
        };
        return new ImpactDto(items, jobs, templates, documents);
    }

    private int count(String sql, String code) {
        Integer value = jdbc.queryForObject(sql, Integer.class, code);
        return value == null ? 0 : value;
    }
}
