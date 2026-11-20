package com.truereport.jobs;

import com.truereport.shared.error.ApiException;
import com.truereport.shared.storage.ObjectStorage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.imageio.ImageIO;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.util.List;
import java.util.Locale;

/**
 * Creates public-safe derivatives for verified clean evidence. Photos are
 * resized to JPEG; videos are copied to a public key because the report viewer
 * streams them through the authorized public-report endpoint.
 */
@Service
public class CleanEvidencePublicationService {

    private static final Logger log = LoggerFactory.getLogger(CleanEvidencePublicationService.class);
    private static final int MAX_EDGE = 1400;

    private final JdbcTemplate jdbc;
    private final ObjectStorage storage;

    public CleanEvidencePublicationService(JdbcTemplate jdbc, ObjectStorage storage) {
        this.jdbc = jdbc;
        this.storage = storage;
    }

    @Transactional
    public void prepare(String jobId) {
        List<EvidenceRow> assets = jdbc.query("""
                SELECT id, type, storage_key, normalized_key, mime
                FROM platform_evidence_assets
                WHERE job_id = ? AND status = 'VERIFIED'
                  AND type IN ('PHOTO', 'VIDEO')
                  AND deleted_at IS NULL
                ORDER BY captured_at, id
                """, (rs, i) -> new EvidenceRow(
                rs.getString("id"), rs.getString("type"), rs.getString("storage_key"),
                rs.getString("normalized_key"), rs.getString("mime")), jobId);

        for (EvidenceRow asset : assets) {
            if (asset.normalizedKey() != null && !asset.normalizedKey().isBlank()) {
                continue;
            }
            if (asset.storageKey() == null || asset.storageKey().isBlank()) {
                throw publicationFailure(asset, null);
            }
            try {
                byte[] original = storage.get(asset.storageKey());
                byte[] publicBytes;
                String mime;
                String key;
                if ("PHOTO".equals(asset.type())) {
                    BufferedImage source = ImageIO.read(new ByteArrayInputStream(original));
                    if (source == null) {
                        throw new IllegalStateException("Evidence image cannot be decoded");
                    }
                    BufferedImage resized = resize(source);
                    ByteArrayOutputStream out = new ByteArrayOutputStream();
                    ImageIO.write(resized, "jpg", out);
                    publicBytes = out.toByteArray();
                    mime = "image/jpeg";
                    key = "platform-evidence/" + jobId + "/" + asset.id() + "-public.jpg";
                } else if ("VIDEO".equals(asset.type())) {
                    publicBytes = original;
                    mime = asset.mime() == null || asset.mime().isBlank()
                            ? "video/mp4" : asset.mime();
                    key = "platform-evidence/" + jobId + "/" + asset.id()
                            + "-public" + extension(mime);
                } else {
                    continue;
                }
                storage.put(key, publicBytes, mime);
                jdbc.update("""
                        UPDATE platform_evidence_assets SET normalized_key = ?, updated_at = CURRENT_TIMESTAMP
                        WHERE id = ?
                        """, key, asset.id());
            } catch (Exception exception) {
                log.error("Could not publish evidence {} (type {}, key {}): {}",
                        asset.id(), asset.type(), asset.storageKey(),
                        exception.getMessage(), exception);
                throw publicationFailure(asset, exception);
            }
        }
    }

    private ApiException publicationFailure(EvidenceRow asset, Exception cause) {
        String detail = cause == null ? "missing storage key" : cause.getMessage();
        return new ApiException(HttpStatus.INTERNAL_SERVER_ERROR,
                "EVIDENCE_PUBLICATION_FAILED", "error.evidence.publicationFailed",
                "Could not publish evidence " + asset.id() + " (" + detail + ")", List.of(),
                cause);
    }

    private static String extension(String mime) {
        String value = mime == null ? "" : mime.toLowerCase(Locale.ROOT);
        return switch (value) {
            case "video/webm" -> ".webm";
            case "video/quicktime" -> ".mov";
            default -> ".mp4";
        };
    }

    private BufferedImage resize(BufferedImage source) {
        int width = source.getWidth();
        int height = source.getHeight();
        double scale = Math.min(1.0, (double) MAX_EDGE / Math.max(width, height));
        int targetWidth = Math.max(1, (int) Math.round(width * scale));
        int targetHeight = Math.max(1, (int) Math.round(height * scale));
        BufferedImage result = new BufferedImage(targetWidth, targetHeight, BufferedImage.TYPE_INT_RGB);
        Graphics2D graphics = result.createGraphics();
        try {
            graphics.setRenderingHint(RenderingHints.KEY_INTERPOLATION,
                    RenderingHints.VALUE_INTERPOLATION_BICUBIC);
            graphics.setRenderingHint(RenderingHints.KEY_RENDERING,
                    RenderingHints.VALUE_RENDER_QUALITY);
            graphics.drawImage(source, 0, 0, targetWidth, targetHeight, null);
        } finally {
            graphics.dispose();
        }
        return result;
    }

    private record EvidenceRow(String id, String type, String storageKey,
                               String normalizedKey, String mime) {
    }
}
