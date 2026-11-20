package com.truereport.jobs;

import com.truereport.shared.storage.ObjectStorage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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

/**
 * Creates a public-safe, resized JPEG for verified clean evidence photos and
 * records it as {@code normalized_key}. The clean evidence table previously had
 * no public derivative, so the report showcase was always empty even when the
 * technician uploaded real photos.
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
        List<PhotoRow> photos = jdbc.query("""
                SELECT id, storage_key, normalized_key
                FROM platform_evidence_assets
                WHERE job_id = ? AND type = 'PHOTO' AND status = 'VERIFIED'
                  AND deleted_at IS NULL
                """, (rs, i) -> new PhotoRow(
                rs.getString("id"), rs.getString("storage_key"),
                rs.getString("normalized_key")), jobId);

        for (PhotoRow photo : photos) {
            if (photo.normalizedKey() != null && !photo.normalizedKey().isBlank()) {
                continue;
            }
            if (photo.storageKey() == null || photo.storageKey().isBlank()) {
                continue;
            }
            try {
                byte[] original = storage.get(photo.storageKey());
                BufferedImage source = ImageIO.read(new ByteArrayInputStream(original));
                if (source == null) {
                    log.warn("Skipping public derivative for undecodable evidence {}", photo.id());
                    continue;
                }
                BufferedImage resized = resize(source);
                ByteArrayOutputStream out = new ByteArrayOutputStream();
                ImageIO.write(resized, "jpg", out);
                byte[] publicBytes = out.toByteArray();
                String key = "platform-evidence/" + jobId + "/" + photo.id() + "/public.jpg";
                storage.put(key, publicBytes, "image/jpeg");
                jdbc.update("""
                        UPDATE platform_evidence_assets SET normalized_key = ?, updated_at = CURRENT_TIMESTAMP
                        WHERE id = ?
                        """, key, photo.id());
            } catch (Exception exception) {
                log.warn("Could not publish evidence {}: {}", photo.id(), exception.getMessage());
            }
        }
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

    private record PhotoRow(String id, String storageKey, String normalizedKey) {
    }
}
