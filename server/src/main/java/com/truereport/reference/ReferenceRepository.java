package com.truereport.reference;

import com.truereport.reference.api.ReferenceDtos.ImpactDto;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public class ReferenceRepository {

    /**
     * A reference row backed by an option value. The taxonomy-specific fields
     * (tone, icon, selectable, visibleFor, allowedNext) live in
     * {@code metadata_json} and are parsed by the service.
     */
    public record ReferenceRow(String domainKey, String code, String labelKey,
                               int sortOrder, String metadataJson, String status,
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

    public List<ReferenceRow> findDomain(String domainKey, boolean includeDraft) {
        String statuses = includeDraft ? "('ACTIVE', 'DRAFT', 'RETIRED')" : "('ACTIVE')";
        return jdbc.query("""
                SELECT s.domain_key, v.code, v.label_key, v.sort_order, v.metadata_json,
                       v.status, v.version
                FROM platform_option_values v
                JOIN platform_option_sets s ON s.id = v.option_set_id
                WHERE s.domain_key = ? AND v.status IN %s
                ORDER BY v.sort_order, v.code
                """.formatted(statuses), (rs, i) -> new ReferenceRow(
                rs.getString("domain_key"), rs.getString("code"),
                rs.getString("label_key"), rs.getInt("sort_order"),
                rs.getString("metadata_json"), rs.getString("status"),
                rs.getInt("version")), domainKey);
    }

    public Optional<ReferenceRow> find(String domainKey, String code) {
        return jdbc.query("""
                SELECT s.domain_key, v.code, v.label_key, v.sort_order, v.metadata_json,
                       v.status, v.version
                FROM platform_option_values v
                JOIN platform_option_sets s ON s.id = v.option_set_id
                WHERE s.domain_key = ? AND v.code = ?
                """, (rs, i) -> new ReferenceRow(
                rs.getString("domain_key"), rs.getString("code"),
                rs.getString("label_key"), rs.getInt("sort_order"),
                rs.getString("metadata_json"), rs.getString("status"),
                rs.getInt("version")), domainKey, code)
                .stream().findFirst();
    }

    public void updateValue(String domainKey, String code, String label, String labelKey,
                            int sortOrder, String metadataJson) {
        jdbc.update("""
                UPDATE platform_option_values
                SET label = COALESCE(?, label), label_key = ?, sort_order = ?,
                    metadata_json = ?, version = version + 1, updated_at = CURRENT_TIMESTAMP
                WHERE option_set_id = (SELECT id FROM platform_option_sets WHERE domain_key = ?)
                  AND code = ?
                """, label, labelKey, sortOrder, metadataJson, domainKey, code);
    }

    public void updateValueStatus(String domainKey, String code, String status) {
        jdbc.update("""
                UPDATE platform_option_values
                SET status = ?, version = version + 1, updated_at = CURRENT_TIMESTAMP
                WHERE option_set_id = (SELECT id FROM platform_option_sets WHERE domain_key = ?)
                  AND code = ?
                """, status, domainKey, code);
    }

    public void updateValueOrder(String domainKey, String code, int sortOrder) {
        jdbc.update("""
                UPDATE platform_option_values
                SET sort_order = ?, version = version + 1, updated_at = CURRENT_TIMESTAMP
                WHERE option_set_id = (SELECT id FROM platform_option_sets WHERE domain_key = ?)
                  AND code = ?
                """, sortOrder, domainKey, code);
    }

    public void updateValueMetadata(String domainKey, String code, String metadataJson) {
        jdbc.update("""
                UPDATE platform_option_values
                SET metadata_json = ?, version = version + 1, updated_at = CURRENT_TIMESTAMP
                WHERE option_set_id = (SELECT id FROM platform_option_sets WHERE domain_key = ?)
                  AND code = ?
                """, metadataJson, domainKey, code);
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
