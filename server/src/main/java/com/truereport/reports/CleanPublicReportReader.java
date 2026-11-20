package com.truereport.reports;

import com.truereport.shared.storage.ObjectStorage;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.HexFormat;
import java.util.Optional;

/**
 * Read-only bridge for reports published through the clean Workshop Admin
 * tables. The legacy public path resolves {@code public_share_links ->
 * report_versions -> reports}; clean publish writes {@code platform_public_links
 * -> platform_report_versions -> platform_jobs}. Without this bridge an active
 * clean link returns a neutral 404.
 */
@Component
public class CleanPublicReportReader {

    public record Row(
            String linkId,
            String reportVersionId,
            boolean pdfDownloadEnabled,
            String status,
            String snapshotJson,
            String snapshotHash,
            int versionNo,
            String reportNumber,
            String jobId,
            String workshopId,
            LocalDateTime finalizedAt,
            LocalDateTime publishedAt
    ) {
    }

    public record Photo(byte[] bytes, String mime) {
    }

    private final JdbcTemplate jdbc;
    private final ObjectStorage storage;

    public CleanPublicReportReader(JdbcTemplate jdbc, ObjectStorage storage) {
        this.jdbc = jdbc;
        this.storage = storage;
    }

    public Optional<Row> findByToken(String token) {
        String hash = sha256Hex(token);
        return jdbc.query("""
                SELECT l.id AS link_id, l.report_version_id, l.pdf_download_enabled, l.status,
                       v.snapshot_json, v.snapshot_hash, v.version_no,
                       j.reference, j.id AS job_id, j.workshop_id, j.completed_at, j.published_at
                FROM platform_public_links l
                JOIN platform_report_versions v ON v.id = l.report_version_id
                JOIN platform_jobs j ON j.id = l.job_id
                WHERE l.token_hash = ?
                ORDER BY l.created_at DESC
                LIMIT 1
                """, (rs, i) -> new Row(
                rs.getString("link_id"),
                rs.getString("report_version_id"),
                rs.getBoolean("pdf_download_enabled"),
                rs.getString("status"),
                rs.getString("snapshot_json"),
                rs.getString("snapshot_hash"),
                rs.getInt("version_no"),
                rs.getString("reference"),
                rs.getString("job_id"),
                rs.getString("workshop_id"),
                rs.getObject("completed_at", LocalDateTime.class),
                rs.getObject("published_at", LocalDateTime.class)
        ), hash).stream().findFirst();
    }

    public java.util.List<EvidenceDerivative> publicEvidence(String jobId,
                                                              java.util.UUID reportVersionId,
                                                              java.util.UUID workshopId) {
        return jdbc.query("""
                SELECT id, normalized_key, bytes
                FROM platform_evidence_assets
                WHERE job_id = ? AND type = 'PHOTO' AND status = 'VERIFIED'
                  AND deleted_at IS NULL AND normalized_key IS NOT NULL
                ORDER BY captured_at, id
                """, (rs, i) -> {
            String assetId = rs.getString("id");
            return new EvidenceDerivative(
                    java.util.UUID.fromString(assetId), workshopId, reportVersionId,
                    java.util.UUID.fromString(assetId), "PUBLIC_FULL",
                    rs.getString("normalized_key"), null, "image/jpeg",
                    rs.getLong("bytes"), null, null);
        }, jobId);
    }

    public Optional<Photo> photo(String token, java.util.UUID assetId) {
        Optional<Row> link = findByToken(token);
        if (link.isEmpty() || !"ACTIVE".equals(link.get().status())) {
            return Optional.empty();
        }
        return jdbc.query("""
                SELECT normalized_key, mime
                FROM platform_evidence_assets
                WHERE id = ? AND job_id = ? AND type = 'PHOTO' AND status = 'VERIFIED'
                  AND deleted_at IS NULL AND normalized_key IS NOT NULL
                """, (rs, i) -> new Photo(storage.get(rs.getString("normalized_key")),
                "image/jpeg"), assetId.toString(), link.get().jobId())
                .stream().findFirst();
    }

    private static String sha256Hex(String value) {
        try {
            return HexFormat.of().formatHex(
                    MessageDigest.getInstance("SHA-256")
                            .digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }
}
