package com.truereport.media;

import com.truereport.jobs.PlatformJobStore;
import com.truereport.jobs.PlatformJobStore.JobRow;
import com.truereport.media.api.VehiclePhotoDtos.VehiclePhotoCompleteResponse;
import com.truereport.media.api.VehiclePhotoDtos.VehiclePhotoDto;
import com.truereport.media.api.VehiclePhotoDtos.VehiclePhotoInitRequest;
import com.truereport.media.api.VehiclePhotoDtos.VehiclePhotoInitResponse;
import com.truereport.media.api.VehiclePhotoDtos.VehiclePhotoUploadResponse;
import com.truereport.shared.audit.FieldAuditService;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.storage.ObjectStorage;
import com.truereport.shared.time.WallClockTimes;
import com.truereport.shared.uuid.UuidV7;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.HexFormat;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * Vehicle hero photo captured before the inspection. One photo per job; a new
 * init replaces the previous row and storage object. Only the assigned
 * technician or the job creator may read/write it, and only while the job is
 * still pre-publication.
 */
@Service
public class VehiclePhotoService {

    public static final long MAX_BYTES = 8L * 1024 * 1024;

    private static final Set<String> MIMES = Set.of("image/jpeg", "image/png", "image/webp");
    private static final Set<String> WRITABLE_STATUSES = Set.of(
            "ASSIGNED", "IN_PROGRESS", "PENDING_REVIEW", "APPROVED");
    private static final Pattern SHA256 = Pattern.compile("^[0-9a-fA-F]{64}$");

    private final VehiclePhotoStore photos;
    private final PlatformJobStore jobs;
    private final ObjectStorage storage;
    private final FieldAuditService audit;

    public VehiclePhotoService(VehiclePhotoStore photos, PlatformJobStore jobs,
                               ObjectStorage storage, FieldAuditService audit) {
        this.photos = photos;
        this.jobs = jobs;
        this.storage = storage;
        this.audit = audit;
    }

    @Transactional
    public VehiclePhotoInitResponse init(CurrentUser caller, String jobId,
                                         VehiclePhotoInitRequest request) {
        JobRow job = requireWritableJob(caller, jobId);
        if (request == null) {
            throw invalid("A vehicle photo request is required");
        }
        String mime = request.mime() == null
                ? "" : request.mime().trim().toLowerCase(Locale.ROOT);
        if (!MIMES.contains(mime)) {
            throw invalid("Mime must be image/jpeg, image/png or image/webp");
        }
        Long declaredBytes = request.bytes();
        if (declaredBytes == null || declaredBytes <= 0 || declaredBytes > MAX_BYTES) {
            throw invalid("Vehicle photo must be between 1 byte and 8 MB");
        }
        String sha256 = request.sha256() == null ? "" : request.sha256().trim();
        if (!SHA256.matcher(sha256).matches()) {
            throw invalid("sha256 must be 64 hexadecimal characters");
        }
        LocalDateTime capturedAt = parseCapturedAt(request.capturedAt());
        String source = trimTo(request.captureSource(), 20);

        photos.find(job.id()).ifPresent(previous -> {
            if (previous.storageKey() != null && !previous.storageKey().isBlank()) {
                storage.delete(previous.storageKey());
            }
            photos.delete(previous.id());
        });
        String id = UuidV7.generate().toString();
        String storageKey = "vehicle-photo/" + job.id() + "/" + id;
        photos.insert(id, job.id(), mime, declaredBytes, sha256.toLowerCase(Locale.ROOT),
                capturedAt, source, caller.userId().toString(), storageKey);
        audit.record(caller, "JOB_VEHICLE_PHOTO_INIT", "JOB", job.id(),
                null, Map.of("id", id, "mime", mime, "bytes", declaredBytes), null, null);
        return new VehiclePhotoInitResponse(id, "PENDING_UPLOAD", mime, declaredBytes);
    }

    @Transactional
    public VehiclePhotoUploadResponse upload(CurrentUser caller, String jobId, String photoId,
                                             byte[] content) {
        JobRow job = requireWritableJob(caller, jobId);
        VehiclePhotoStore.Row row = photos.findById(job.id(), photoId)
                .orElseThrow(ApiException::notFound);
        if (!"PENDING_UPLOAD".equals(row.status()) && !"UPLOADED".equals(row.status())) {
            throw new ApiException(HttpStatus.CONFLICT, "VEHICLE_PHOTO_STATE_INVALID",
                    "error.technician.vehiclePhotoInvalid",
                    "The vehicle photo is not awaiting an upload");
        }
        byte[] bytes = content == null ? new byte[0] : content;
        if (bytes.length == 0 || bytes.length > MAX_BYTES) {
            throw invalid("Vehicle photo must be between 1 byte and 8 MB");
        }
        if (row.bytes() == null || bytes.length != row.bytes()) {
            throw invalid("Uploaded size does not match the declared size");
        }
        String actual = sha256(bytes);
        if (row.sha256() == null || !actual.equalsIgnoreCase(row.sha256())) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "VEHICLE_PHOTO_CORRUPT",
                    "error.technician.vehiclePhotoCorrupt",
                    "The uploaded photo does not match the declared sha256");
        }
        storage.put(row.storageKey(), bytes, row.mime());
        photos.markUploaded(row.id());
        return new VehiclePhotoUploadResponse(row.id(), "UPLOADED", row.mime(),
                bytes.length, row.sha256());
    }

    @Transactional
    public VehiclePhotoCompleteResponse complete(CurrentUser caller, String jobId,
                                                 String photoId) {
        JobRow job = requireWritableJob(caller, jobId);
        VehiclePhotoStore.Row row = photos.findById(job.id(), photoId)
                .orElseThrow(ApiException::notFound);
        if ("READY".equals(row.status())) {
            return completeResponse(row);
        }
        if (!"UPLOADED".equals(row.status())) {
            throw new ApiException(HttpStatus.CONFLICT, "VEHICLE_PHOTO_STATE_INVALID",
                    "error.technician.vehiclePhotoInvalid",
                    "Upload the vehicle photo before completing it");
        }
        photos.markReady(row.id());
        VehiclePhotoStore.Row ready = photos.findById(job.id(), row.id()).orElse(row);
        audit.record(caller, "JOB_VEHICLE_PHOTO_READY", "JOB", job.id(),
                Map.of("status", row.status()), Map.of("status", "READY"), null, null);
        return completeResponse(ready);
    }

    @Transactional(readOnly = true)
    public Optional<VehiclePhotoDto> get(CurrentUser caller, String jobId) {
        JobRow job = requireJob(caller, jobId);
        return photos.find(job.id()).map(row -> new VehiclePhotoDto(
                row.id(), row.status(), row.mime(), row.bytes(), row.sha256(),
                row.capturedAt() == null ? null : row.capturedAt().toString()));
    }

    @Transactional(readOnly = true)
    public Optional<Content> content(CurrentUser caller, String jobId) {
        JobRow job = requireJob(caller, jobId);
        return photos.find(job.id())
                .filter(row -> Set.of("UPLOADED", "READY").contains(row.status()))
                .filter(row -> row.storageKey() != null && !row.storageKey().isBlank())
                .map(row -> new Content(storage.get(row.storageKey()), row.mime()));
    }

    @Transactional
    public void delete(CurrentUser caller, String jobId) {
        JobRow job = requireWritableJob(caller, jobId);
        photos.find(job.id()).ifPresent(row -> {
            if (row.storageKey() != null && !row.storageKey().isBlank()) {
                storage.delete(row.storageKey());
            }
            photos.delete(row.id());
            audit.record(caller, "JOB_VEHICLE_PHOTO_DELETED", "JOB", job.id(),
                    Map.of("id", row.id()), null, null, null);
        });
    }

    private VehiclePhotoCompleteResponse completeResponse(VehiclePhotoStore.Row row) {
        return new VehiclePhotoCompleteResponse(row.id(), row.status(), row.mime(),
                row.bytes() == null ? 0 : row.bytes(), row.sha256(),
                row.capturedAt() == null ? null : row.capturedAt().toString());
    }

    private JobRow requireWritableJob(CurrentUser caller, String jobId) {
        JobRow job = requireJob(caller, jobId);
        if (!WRITABLE_STATUSES.contains(job.status())) {
            throw new ApiException(HttpStatus.CONFLICT, "JOB_STATE_INVALID",
                    "error.job.statusInvalid",
                    "Vehicle photos can only be changed before the report is published");
        }
        return job;
    }

    private JobRow requireJob(CurrentUser caller, String jobId) {
        if (caller == null || !caller.isTechnician() || caller.workshopId() == null) {
            throw ApiException.forbidden();
        }
        JobRow job = jobs.findJob(caller.workshopId().toString(), jobId)
                .orElseThrow(ApiException::notFound);
        String callerId = caller.userId().toString();
        if (!callerId.equals(job.assignedTechnicianId())
                && !callerId.equals(job.createdBy())) {
            throw ApiException.notFound();
        }
        return job;
    }

    private LocalDateTime parseCapturedAt(String value) {
        try {
            LocalDateTime parsed = WallClockTimes.parse(value);
            if (parsed == null) {
                throw invalid("capturedAt is required");
            }
            return parsed;
        } catch (DateTimeParseException exception) {
            throw invalid("capturedAt must be an ISO local date-time");
        }
    }

    private static String trimTo(String value, int max) {
        if (value == null || value.isBlank()) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.length() <= max ? trimmed : trimmed.substring(0, max);
    }

    private static ApiException invalid(String message) {
        return new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "VEHICLE_PHOTO_INVALID",
                "error.technician.vehiclePhotoInvalid", message);
    }

    private static String sha256(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(
                    MessageDigest.getInstance("SHA-256").digest(bytes)).toLowerCase(Locale.ROOT);
        } catch (Exception exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }

    public record Content(byte[] bytes, String mime) {
    }
}
