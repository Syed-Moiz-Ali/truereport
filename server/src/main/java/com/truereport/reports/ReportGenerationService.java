package com.truereport.reports;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.inspections.EvidenceAsset;
import com.truereport.inspections.EvidenceAssetRepository;
import com.truereport.shared.storage.ObjectStorage;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.imageio.IIOImage;
import javax.imageio.ImageIO;
import javax.imageio.ImageWriteParam;
import javax.imageio.ImageWriter;
import javax.imageio.stream.ImageOutputStream;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
public class ReportGenerationService {

    private final ReportGenerationJobRepository jobs;
    private final ReportVersionRepository versions;
    private final ReportRepository reports;
    private final EvidenceDerivativeRepository derivatives;
    private final EvidenceAssetRepository evidence;
    private final ReportArtifactRepository artifacts;
    private final ReportPdfService pdfService;
    private final ObjectStorage storage;
    private final ObjectMapper objectMapper;

    public ReportGenerationService(ReportGenerationJobRepository jobs,
                                   ReportVersionRepository versions,
                                   ReportRepository reports,
                                   EvidenceDerivativeRepository derivatives,
                                   EvidenceAssetRepository evidence,
                                   ReportArtifactRepository artifacts,
                                   ReportPdfService pdfService,
                                   ObjectStorage storage,
                                   ObjectMapper objectMapper) {
        this.jobs = jobs;
        this.versions = versions;
        this.reports = reports;
        this.derivatives = derivatives;
        this.evidence = evidence;
        this.artifacts = artifacts;
        this.pdfService = pdfService;
        this.storage = storage;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public void poll() {
        List<UUID> due = jobs.findDueIds(LocalDateTime.now(ZoneOffset.UTC));
        for (UUID id : due) {
            generate(id);
        }
    }

    private void generate(UUID jobId) {
        ReportGenerationJob job = jobs.findForUpdate(jobId).orElse(null);
        if (job == null || job.getStatus().equals("GENERATING") || job.getStatus().equals("READY")) {
            return;
        }
        job.markGenerating();
        jobs.save(job);
        try {
            ReportVersion version = versions.findById(job.getReportVersionId())
                    .orElseThrow(() -> new IllegalStateException("Report version is missing"));
            Report report = reports.findById(version.getReportId())
                    .orElseThrow(() -> new IllegalStateException("Report is missing"));
            List<EvidenceDerivative> generated = generateDerivatives(version, report);
            byte[] pdf = pdfService.render(version, generated);
            String key = "reports/" + version.getWorkshopId() + "/" + version.getId() + "/report.pdf";
            storage.put(key, pdf, "application/pdf");
            ReportArtifact artifact = artifacts.findByReportVersionIdAndKind(version.getId(), "PDF")
                    .orElse(null);
            if (artifact == null) {
                artifacts.save(new ReportArtifact(version.getId(), "PDF", key, hash(pdf),
                        pdf.length, "application/pdf"));
            } else {
                artifact.replace(key, hash(pdf), pdf.length, "application/pdf");
                artifacts.save(artifact);
            }
            job.markReady();
            jobs.save(job);
        } catch (Exception exception) {
            job.markFailed(exception.getMessage());
            jobs.save(job);
        }
    }

    private List<EvidenceDerivative> generateDerivatives(ReportVersion version, Report report) throws Exception {
        ReportSnapshot snapshot = objectMapper.readValue(version.getSnapshotJson(), ReportSnapshot.class);
        Set<UUID> ids = new HashSet<>();
        for (ReportSnapshot.Category category : snapshot.categories()) {
            for (ReportSnapshot.ItemSnapshot item : category.items()) {
                for (String raw : item.evidenceIds()) {
                    try {
                        ids.add(UUID.fromString(raw));
                    } catch (RuntimeException ignored) {
                        // Ignore malformed IDs in frozen data; they cannot become public.
                    }
                }
            }
        }
        for (UUID id : ids) {
            if (derivatives.findByEvidenceAssetIdAndPurpose(id, "PUBLIC_FULL").isPresent()) {
                continue;
            }
            EvidenceAsset asset = evidence.findById(id)
                    .orElseThrow(() -> new IllegalStateException("Evidence is missing"));
            if (!asset.getJobId().equals(report.getJobId())
                    || asset.getNormalizedStorageKey() == null
                    || !asset.getUploadStatus().equals("VERIFIED")) {
                throw new IllegalStateException("Evidence is not public-safe");
            }
            byte[] original = storage.get(asset.getNormalizedStorageKey());
            BufferedImage source = ImageIO.read(new ByteArrayInputStream(original));
            if (source == null) {
                throw new IllegalStateException("Evidence image cannot be decoded");
            }
            BufferedImage resized = resize(source, 1400);
            byte[] publicBytes = jpeg(resized);
            String key = "reports/" + report.getWorkshopId() + "/" + version.getId()
                    + "/evidence/" + id + "-public.jpg";
            storage.put(key, publicBytes, "image/jpeg");
            derivatives.save(new EvidenceDerivative(report.getWorkshopId(), version.getId(), id,
                    "PUBLIC_FULL", key, hash(publicBytes), "image/jpeg", publicBytes.length,
                    resized.getWidth(), resized.getHeight()));
        }
        return derivatives.findByReportVersionIdOrderByCreatedAtAsc(version.getId());
    }

    private BufferedImage resize(BufferedImage source, int max) {
        int width = source.getWidth();
        int height = source.getHeight();
        double scale = Math.min(1.0, (double) max / Math.max(width, height));
        int targetWidth = Math.max(1, (int) Math.round(width * scale));
        int targetHeight = Math.max(1, (int) Math.round(height * scale));
        BufferedImage result = new BufferedImage(targetWidth, targetHeight, BufferedImage.TYPE_INT_RGB);
        Graphics2D graphics = result.createGraphics();
        graphics.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
        graphics.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
        graphics.drawImage(source, 0, 0, targetWidth, targetHeight, null);
        graphics.dispose();
        return result;
    }

    private byte[] jpeg(BufferedImage image) throws Exception {
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        ImageWriter writer = ImageIO.getImageWritersByFormatName("jpg").next();
        ImageWriteParam params = writer.getDefaultWriteParam();
        params.setCompressionMode(ImageWriteParam.MODE_EXPLICIT);
        params.setCompressionQuality(0.82f);
        try (ImageOutputStream stream = ImageIO.createImageOutputStream(output)) {
            writer.setOutput(stream);
            writer.write(null, new IIOImage(image, null, null), params);
        } finally {
            writer.dispose();
        }
        return output.toByteArray();
    }

    private byte[] hash(byte[] value) throws Exception {
        return MessageDigest.getInstance("SHA-256").digest(value);
    }
}
