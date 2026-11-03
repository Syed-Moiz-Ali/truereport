package com.truereport.inspections;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.audit.AuditService;
import com.truereport.inspections.api.EvidenceCompleteRequest;
import com.truereport.inspections.api.EvidenceDto;
import com.truereport.inspections.api.EvidenceInitRequest;
import com.truereport.inspections.api.EvidenceInitResponse;
import com.truereport.jobs.InspectionJob;
import com.truereport.jobs.InspectionJobRepository;
import com.truereport.masterdata.MasterContentService;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.storage.ObjectStorage;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.imageio.ImageIO;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Service
public class EvidenceService {

    static final long MAX_BYTES = 8L * 1024 * 1024;
    private static final long MAX_PIXELS = 40_000_000L;
    private static final Set<String> ALLOWED_MIME = Set.of(
            "image/jpeg", "image/heic", "image/heif");
    private static final Set<String> CONSENT_TYPES = Set.of(
            "PROCESSING", "PUBLIC_LINK", "WHATSAPP", "SMS", "EMAIL", "PDF_DOWNLOAD");

    private final InspectionJobRepository jobs;
    private final InspectionItemSnapshotRepository snapshots;
    private final AssessmentRepository assessments;
    private final EvidenceAssetRepository evidence;
    private final MasterContentService masterContent;
    private final ObjectStorage storage;
    private final AuditService auditService;
    private final ObjectMapper objectMapper;
    private final byte[] tokenPepper = "truereport-evidence-upload".getBytes(java.nio.charset.StandardCharsets.UTF_8);

    public EvidenceService(InspectionJobRepository jobs,
                           InspectionItemSnapshotRepository snapshots,
                           AssessmentRepository assessments,
                           EvidenceAssetRepository evidence,
                           MasterContentService masterContent,
                           ObjectStorage storage,
                           AuditService auditService,
                           ObjectMapper objectMapper) {
        this.jobs = jobs;
        this.snapshots = snapshots;
        this.assessments = assessments;
        this.evidence = evidence;
        this.masterContent = masterContent;
        this.storage = storage;
        this.auditService = auditService;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public EvidenceInitResponse init(CurrentUser caller, UUID jobId, UUID itemId,
                                     EvidenceInitRequest request) {
        InspectionJob job = requireMutableOwnJob(caller, jobId);
        InspectionItemSnapshot item = requireItem(jobId, itemId);
        if (!ALLOWED_MIME.contains(request.mime())) {
            throw new ApiException(HttpStatus.UNSUPPORTED_MEDIA_TYPE, "EVIDENCE_TYPE_INVALID",
                    "error.evidence.type", "Only JPEG and HEIC/HEIF evidence is allowed");
        }
        if (request.bytes() <= 0 || request.bytes() > MAX_BYTES) {
            throw new ApiException(HttpStatus.PAYLOAD_TOO_LARGE, "EVIDENCE_TOO_LARGE",
                    "error.evidence.tooLarge", "Evidence exceeds the 8 MB hard limit");
        }
        byte[] expected = hex(request.sha256());
        EvidenceAsset existing = evidence.findByIdAndJobId(request.evidenceId(), jobId).orElse(null);
        if (existing != null) {
            if (!existing.getInspectionItemId().equals(itemId)
                    || !existing.getUploadedBy().equals(caller.userId())
                    || !MessageDigest.isEqual(existing.getContentHash(), expected)) {
                throw ApiException.conflict("EVIDENCE_ID_CONFLICT", "Evidence id is already used");
            }
            if (existing.getUploadStatus().equals("VERIFIED")) {
                return new EvidenceInitResponse(existing.getId(), existing.getUploadStatus(), null, null, "");
            }
            if (existing.getUploadStatus().equals("REJECTED")) {
                return new EvidenceInitResponse(existing.getId(), existing.getUploadStatus(), null, null, "");
            }
            String raw = randomToken();
            existing.setUploadToken(hashToken(raw), now().plusMinutes(15));
            evidence.save(existing);
            return initResponse(existing, raw);
        }
        String key = "evidence/" + job.getWorkshopId() + "/" + jobId + "/"
                + request.evidenceId() + "/original";
        EvidenceAsset asset = new EvidenceAsset(request.evidenceId(), job.getWorkshopId(), jobId,
                itemId, assessments.findByJobIdAndInspectionItemId(jobId, itemId)
                .map(Assessment::getId).orElse(null), key, expected, request.mime(),
                request.bytes(), parseCapturedAt(request.capturedAt()), caller.userId());
        String raw = randomToken();
        asset.setUploadToken(hashToken(raw), now().plusMinutes(15));
        evidence.save(asset);
        audit(caller, job, "EVIDENCE_SLOT_ISSUED", Map.of("evidenceId", asset.getId().toString()));
        return initResponse(asset, raw);
    }

    @Transactional
    public void upload(CurrentUser caller, UUID evidenceId, String token, byte[] bytes) {
        EvidenceAsset asset = evidence.findById(evidenceId).orElseThrow(ApiException::notFound);
        InspectionJob job = requireOwnJob(caller, asset.getJobId());
        if (asset.getDeletedAt() != null || job.getStatus().equals("FINALIZED")) {
            throw new ApiException(HttpStatus.CONFLICT, "EVIDENCE_IMMUTABLE",
                    "error.evidence.immutable", "Evidence cannot be changed after finalization");
        }
        if (asset.getUploadTokenHash() == null
                || asset.getUploadTokenExpiresAt() == null
                || asset.getUploadTokenExpiresAt().isBefore(now())
                || !MessageDigest.isEqual(asset.getUploadTokenHash(), hashToken(token))) {
            throw new ApiException(HttpStatus.FORBIDDEN, "EVIDENCE_TOKEN_INVALID",
                    "error.evidence.token", "The upload token is invalid or expired");
        }
        if (bytes == null || bytes.length == 0 || bytes.length > MAX_BYTES) {
            throw new ApiException(HttpStatus.PAYLOAD_TOO_LARGE, "EVIDENCE_TOO_LARGE",
                    "error.evidence.tooLarge", "Evidence exceeds the 8 MB hard limit");
        }
        String sniffed = sniff(bytes);
        if (sniffed == null || !sniffed.equals(asset.getMime())) {
            asset.markRejected();
            evidence.save(asset);
            throw new ApiException(HttpStatus.UNSUPPORTED_MEDIA_TYPE, "EVIDENCE_TYPE_INVALID",
                    "error.evidence.type", "Uploaded bytes do not match an allowed image type");
        }
        storage.put(asset.getStorageKey(), bytes, asset.getMime());
        asset.markReceived();
        evidence.save(asset);
        audit(caller, job, "EVIDENCE_UPLOAD_RECEIVED",
                Map.of("evidenceId", asset.getId().toString()));
    }

    @Transactional
    public EvidenceDto complete(CurrentUser caller, UUID jobId, UUID itemId, UUID evidenceId,
                                EvidenceCompleteRequest request) {
        InspectionJob job = requireMutableOwnJob(caller, jobId);
        requireItem(jobId, itemId);
        EvidenceAsset asset = evidence.findByIdAndJobId(evidenceId, jobId)
                .orElseThrow(ApiException::notFound);
        if (!asset.getInspectionItemId().equals(itemId)) {
            throw ApiException.notFound();
        }
        if (asset.getUploadStatus().equals("VERIFIED")) {
            return dto(asset);
        }
        if (asset.getDeletedAt() != null || asset.getUploadStatus().equals("REJECTED")) {
            throw new ApiException(HttpStatus.CONFLICT, "EVIDENCE_NOT_AVAILABLE",
                    "error.evidence.unavailable", "Evidence slot is not available");
        }
        byte[] expected = hex(request.sha256());
        if (!MessageDigest.isEqual(asset.getContentHash(), expected)) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "EVIDENCE_HASH_MISMATCH",
                    "error.evidence.hash", "The client hash does not match the expected hash");
        }
        byte[] original = storage.get(asset.getStorageKey());
        if (original == null || !MessageDigest.isEqual(hashBytes(original), expected)) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "EVIDENCE_HASH_MISMATCH",
                    "error.evidence.hash", "The stored evidence hash does not match");
        }
        String sniffed = sniff(original);
        if (sniffed == null) {
            asset.markRejected();
            evidence.save(asset);
            throw new ApiException(HttpStatus.UNSUPPORTED_MEDIA_TYPE, "EVIDENCE_TYPE_INVALID",
                    "error.evidence.type", "Uploaded evidence is not a valid image");
        }
        try {
            NormalizedImage normalized = normalize(original);
            String normalizedKey = "evidence/" + job.getWorkshopId() + "/" + jobId + "/"
                    + evidenceId + "/normalized.jpg";
            storage.put(normalizedKey, normalized.bytes(), "image/jpeg");
            asset.markVerified(normalizedKey, hashBytes(normalized.bytes()),
                    normalized.bytes().length, "image/jpeg", normalized.width(), normalized.height());
            evidence.save(asset);
            audit(caller, job, "EVIDENCE_VERIFIED",
                    Map.of("evidenceId", asset.getId().toString()));
            return dto(asset);
        } catch (IOException exception) {
            asset.markRejected();
            evidence.save(asset);
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "EVIDENCE_NORMALIZE_FAILED",
                    "error.evidence.normalize", "Evidence could not be converted to a safe JPEG");
        }
    }

    @Transactional(readOnly = true)
    public List<EvidenceDto> list(CurrentUser caller, UUID jobId, UUID itemId) {
        requireOwnJob(caller, jobId);
        requireItem(jobId, itemId);
        return evidence.findByJobIdAndDeletedAtIsNullOrderByCreatedAtAsc(jobId).stream()
                .filter(asset -> asset.getInspectionItemId().equals(itemId))
                .map(this::dto)
                .toList();
    }

    @Transactional
    public void delete(CurrentUser caller, UUID jobId, UUID evidenceId) {
        InspectionJob job = requireMutableOwnJob(caller, jobId);
        EvidenceAsset asset = evidence.findByIdAndJobId(evidenceId, jobId)
                .orElseThrow(ApiException::notFound);
        if (asset.getDeletedAt() != null) {
            return;
        }
        asset.delete(caller.userId(), now());
        evidence.save(asset);
        try {
            if (asset.getNormalizedStorageKey() != null) {
                storage.delete(asset.getNormalizedStorageKey());
            }
            storage.delete(asset.getStorageKey());
        } catch (RuntimeException ignored) {
            // The audit trail and soft-delete remain authoritative.
        }
        audit(caller, job, "EVIDENCE_REMOVED",
                Map.of("evidenceId", asset.getId().toString()));
    }

    @Transactional(readOnly = true)
    public EvidenceContent content(CurrentUser caller, UUID evidenceId) {
        EvidenceAsset asset = evidence.findById(evidenceId).orElseThrow(ApiException::notFound);
        requireOwnJob(caller, asset.getJobId());
        if (asset.getDeletedAt() != null || !asset.getUploadStatus().equals("VERIFIED")
                || asset.getNormalizedStorageKey() == null) {
            throw new ApiException(HttpStatus.CONFLICT, "EVIDENCE_NOT_VERIFIED",
                    "error.evidence.notVerified", "Evidence is not verified");
        }
        return new EvidenceContent(asset.getNormalizedMime(), storage.get(asset.getNormalizedStorageKey()));
    }

    @Transactional(readOnly = true)
    public MasterContentService.GuideImageContent guideImage(CurrentUser caller, UUID jobId, UUID itemId) {
        requireOwnJob(caller, jobId);
        InspectionItemSnapshot item = requireItem(jobId, itemId);
        JsonNode json = parse(item.getItemJson());
        String guideImageId = json.path("guideImageId").asText("");
        if (guideImageId.isBlank()) {
            throw ApiException.notFound();
        }
        return masterContent.guideImageContent(UUID.fromString(guideImageId));
    }

    public long verifiedCount(UUID jobId, UUID itemId) {
        return evidence.countByJobIdAndInspectionItemIdAndUploadStatusAndDeletedAtIsNull(
                jobId, itemId, "VERIFIED");
    }

    public int requiredCount(JsonNode rules) {
        String requirement = rules.path("evidenceRequirement").asText("NONE");
        int minimum = Math.max(0, rules.path("minPhotos").asInt(0));
        if (requirement.equals("REQUIRED") || requirement.equals("REQUIRED_MIN_N")) {
            return Math.max(1, minimum);
        }
        return minimum;
    }

    public List<EvidenceAsset> verified(UUID jobId, UUID itemId) {
        return evidence.findByJobIdAndInspectionItemIdAndUploadStatusAndDeletedAtIsNull(
                jobId, itemId, "VERIFIED");
    }

    private InspectionJob requireMutableOwnJob(CurrentUser caller, UUID jobId) {
        InspectionJob job = requireOwnJob(caller, jobId);
        if (job.getStatus().equals("FINALIZED")) {
            throw new ApiException(HttpStatus.CONFLICT, "ALREADY_FINALIZED",
                    "error.finalized", "Finalized evidence is immutable");
        }
        if (job.getStatus().equals("CANCELLED")) {
            throw new ApiException(HttpStatus.CONFLICT, "JOB_CANCELLED",
                    "error.job.cancelled", "The job is cancelled");
        }
        return job;
    }

    private InspectionJob requireOwnJob(CurrentUser caller, UUID jobId) {
        if (!caller.isTechnician() || caller.workshopId() == null) {
            throw ApiException.notFound();
        }
        InspectionJob job = jobs.findByIdAndWorkshopId(jobId, caller.workshopId())
                .orElseThrow(ApiException::notFound);
        if (!caller.userId().equals(job.getAssignedTechnicianId())
                && !caller.userId().equals(job.getCreatedBy())) {
            throw new ApiException(HttpStatus.CONFLICT, "JOB_REASSIGNED",
                    "error.job.reassigned", "The job was reassigned");
        }
        return job;
    }

    private InspectionItemSnapshot requireItem(UUID jobId, UUID itemId) {
        return snapshots.findByIdAndJobId(itemId, jobId).orElseThrow(ApiException::notFound);
    }

    private EvidenceInitResponse initResponse(EvidenceAsset asset, String rawToken) {
        String uploadUrl = "/api/v1/technician/evidence/" + asset.getId()
                + "/upload?token=" + rawToken;
        return new EvidenceInitResponse(asset.getId(), asset.getUploadStatus(), uploadUrl, rawToken,
                asset.getUploadTokenExpiresAt() == null ? "" : asset.getUploadTokenExpiresAt().toString());
    }

    private EvidenceDto dto(EvidenceAsset asset) {
        return new EvidenceDto(asset.getId(), asset.getInspectionItemId(), asset.getMime(),
                asset.getBytes(), asset.getCapturedAt() == null ? "" : asset.getCapturedAt().toString(),
                asset.getUploadStatus(), hex(asset.getContentHash()),
                "/api/v1/technician/evidence/" + asset.getId() + "/content");
    }

    private NormalizedImage normalize(byte[] bytes) throws IOException {
        BufferedImage source = ImageIO.read(new ByteArrayInputStream(bytes));
        if (source == null || (long) source.getWidth() * source.getHeight() > MAX_PIXELS) {
            throw new IOException("Image cannot be decoded safely");
        }
        BufferedImage rgb = new BufferedImage(source.getWidth(), source.getHeight(),
                BufferedImage.TYPE_INT_RGB);
        Graphics2D graphics = rgb.createGraphics();
        try {
            graphics.drawImage(source, 0, 0, java.awt.Color.WHITE, null);
        } finally {
            graphics.dispose();
        }
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        if (!ImageIO.write(rgb, "jpg", output)) {
            throw new IOException("JPEG writer unavailable");
        }
        return new NormalizedImage(output.toByteArray(), rgb.getWidth(), rgb.getHeight());
    }

    private String sniff(byte[] bytes) {
        if (bytes.length >= 3 && (bytes[0] & 0xFF) == 0xFF
                && (bytes[1] & 0xFF) == 0xD8 && (bytes[2] & 0xFF) == 0xFF) {
            return "image/jpeg";
        }
        if (bytes.length >= 12 && new String(bytes, 4, 4, java.nio.charset.StandardCharsets.US_ASCII)
                .equals("ftyp")) {
            String brand = new String(bytes, 8, 4, java.nio.charset.StandardCharsets.US_ASCII);
            if (brand.equals("heic") || brand.equals("heix") || brand.equals("heif")
                    || brand.equals("mif1")) {
                return "image/heic";
            }
        }
        return null;
    }

    private LocalDateTime parseCapturedAt(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            if (value.contains("Z") || value.matches(".*[+-]\\d{2}:?\\d{2}$")) {
                return OffsetDateTime.parse(value)
                        .atZoneSameInstant(ZoneOffset.UTC)
                        .toLocalDateTime();
            }
            return LocalDateTime.parse(value);
        } catch (RuntimeException exception) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "CAPTURED_AT_INVALID",
                    "error.capturedAt.invalid", "Captured time is invalid");
        }
    }

    private byte[] hex(String value) {
        try {
            return HexFormat.of().parseHex(value);
        } catch (IllegalArgumentException exception) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "HASH_INVALID",
                    "error.hash.invalid", "SHA-256 hash must be hex");
        }
    }

    private byte[] hashBytes(byte[] value) {
        try {
            return MessageDigest.getInstance("SHA-256").digest(value);
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 unavailable", exception);
        }
    }

    private byte[] hashToken(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            digest.update(tokenPepper);
            return digest.digest(value.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 unavailable", exception);
        }
    }

    private String randomToken() {
        byte[] bytes = new byte[32];
        java.security.SecureRandom random = new java.security.SecureRandom();
        random.nextBytes(bytes);
        return java.util.Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private String hex(byte[] value) {
        return value == null ? "" : HexFormat.of().formatHex(value);
    }

    private String json(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception exception) {
            return "{}";
        }
    }

    private JsonNode parse(String value) {
        try {
            return objectMapper.readTree(value == null || value.isBlank() ? "{}" : value);
        } catch (Exception exception) {
            throw new IllegalStateException("Invalid pinned item JSON", exception);
        }
    }

    private LocalDateTime now() {
        return LocalDateTime.now(ZoneOffset.UTC);
    }

    private void audit(CurrentUser caller, InspectionJob job, String action,
                       Map<String, String> metadata) {
        auditService.record(job.getWorkshopId(), caller.userId(), caller.role(), action,
                "EVIDENCE", job.getId(), null,
                json(metadata));
    }

    public record EvidenceContent(String mime, byte[] bytes) {
    }

    private record NormalizedImage(byte[] bytes, int width, int height) {
    }
}
