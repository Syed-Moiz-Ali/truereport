package com.truereport.media;

import com.truereport.shared.jdbc.JdbcTime;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Optional;

/**
 * One media row per {@code (job_id, kind)}. Vehicle hero photos use the single
 * {@code VEHICLE_HERO} kind; retakes replace the row through the service.
 */
@Repository
public class VehiclePhotoStore {

    public static final String KIND = "VEHICLE_HERO";

    public record Row(
            String id, String jobId, String kind, String storageKey, String mime, Long bytes,
            String sha256, Integer width, Integer height, LocalDateTime capturedAt,
            String captureSource, String uploadedBy, String status,
            LocalDateTime createdAt, LocalDateTime updatedAt, int version) {
    }

    private final JdbcTemplate jdbc;

    public VehiclePhotoStore(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Optional<Row> find(String jobId) {
        return jdbc.query("""
                SELECT * FROM platform_job_media WHERE job_id = ? AND kind = ?
                """, MAPPER, jobId, KIND).stream().findFirst();
    }

    public Optional<Row> findById(String jobId, String id) {
        return jdbc.query("""
                SELECT * FROM platform_job_media WHERE job_id = ? AND kind = ? AND id = ?
                """, MAPPER, jobId, KIND, id).stream().findFirst();
    }

    public Optional<Row> findReady(String jobId) {
        return jdbc.query("""
                SELECT * FROM platform_job_media
                WHERE job_id = ? AND kind = ? AND status = 'READY'
                """, MAPPER, jobId, KIND).stream().findFirst();
    }

    public String insert(String id, String jobId, String mime, long bytes, String sha256,
                         LocalDateTime capturedAt, String captureSource, String uploadedBy,
                         String storageKey) {
        LocalDateTime now = now();
        jdbc.update("""
                INSERT INTO platform_job_media
                    (id, job_id, kind, storage_key, mime, bytes, sha256, width, height,
                     captured_at, capture_source, uploaded_by, status, created_at,
                     updated_at, version)
                VALUES (?, ?, ?, ?, ?, ?, ?, NULL, NULL, ?, ?, ?, 'PENDING_UPLOAD',
                        ?, ?, 0)
                """, id, jobId, KIND, storageKey, mime, bytes, sha256, capturedAt,
                captureSource, uploadedBy, now, now);
        return id;
    }

    public void markUploaded(String id) {
        jdbc.update("""
                UPDATE platform_job_media
                SET status = 'UPLOADED', updated_at = ?, version = version + 1
                WHERE id = ?
                """, now(), id);
    }

    public void markReady(String id) {
        jdbc.update("""
                UPDATE platform_job_media
                SET status = 'READY', updated_at = ?, version = version + 1
                WHERE id = ?
                """, now(), id);
    }

    public void delete(String id) {
        jdbc.update("DELETE FROM platform_job_media WHERE id = ?", id);
    }

    private static LocalDateTime now() {
        return LocalDateTime.now(ZoneOffset.UTC);
    }

    private static final RowMapper<Row> MAPPER = (rs, i) -> new Row(
            rs.getString("id"),
            rs.getString("job_id"),
            rs.getString("kind"),
            rs.getString("storage_key"),
            rs.getString("mime"),
            nullableLong(rs, "bytes"),
            rs.getString("sha256"),
            nullableInt(rs, "width"),
            nullableInt(rs, "height"),
            JdbcTime.localDateTime(rs, "captured_at"),
            rs.getString("capture_source"),
            rs.getString("uploaded_by"),
            rs.getString("status"),
            JdbcTime.localDateTime(rs, "created_at"),
            JdbcTime.localDateTime(rs, "updated_at"),
            rs.getInt("version"));

    private static Long nullableLong(java.sql.ResultSet rs, String column)
            throws java.sql.SQLException {
        long value = rs.getLong(column);
        return rs.wasNull() ? null : value;
    }

    private static Integer nullableInt(java.sql.ResultSet rs, String column)
            throws java.sql.SQLException {
        int value = rs.getInt(column);
        return rs.wasNull() ? null : value;
    }
}
