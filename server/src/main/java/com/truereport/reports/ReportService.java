package com.truereport.reports;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.audit.AuditService;
import com.truereport.inspections.ConsentRecord;
import com.truereport.inspections.ConsentRecordRepository;
import com.truereport.inspections.InspectionFinalSnapshot;
import com.truereport.inspections.InspectionFinalSnapshotRepository;
import com.truereport.jobs.InspectionJob;
import com.truereport.jobs.InspectionJobRepository;
import com.truereport.reports.api.ReportAdminDto;
import com.truereport.reports.api.ReportLinkResponse;
import com.truereport.reports.api.ReportStatusDto;
import com.truereport.reports.api.RevokeLinkRequest;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.storage.ObjectStorage;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.HexFormat;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
public class ReportService {

    private static final Set<String> REVOCATION_REASONS = Set.of(
            "PRIVACY", "SECURITY", "LEGAL", "CUSTOMER_REQUEST", "OTHER");

    private final ReportRepository reports;
    private final ReportVersionRepository versions;
    private final ReportGenerationJobRepository generationJobs;
    private final ReportArtifactRepository artifacts;
    private final PublicShareLinkRepository links;
    private final EvidenceDerivativeRepository derivatives;
    private final InspectionJobRepository jobs;
    private final InspectionFinalSnapshotRepository finalSnapshots;
    private final ConsentRecordRepository consents;
    private final ReportSnapshotBuilder snapshotBuilder;
    private final ReportTokenService tokenService;
    private final ObjectStorage storage;
    private final AuditService auditService;
    private final ObjectMapper objectMapper;
    private final String publicBaseUrl;

    public ReportService(ReportRepository reports,
                         ReportVersionRepository versions,
                         ReportGenerationJobRepository generationJobs,
                         ReportArtifactRepository artifacts,
                         PublicShareLinkRepository links,
                         EvidenceDerivativeRepository derivatives,
                         InspectionJobRepository jobs,
                         InspectionFinalSnapshotRepository finalSnapshots,
                         ConsentRecordRepository consents,
                         ReportSnapshotBuilder snapshotBuilder,
                         ReportTokenService tokenService,
                         ObjectStorage storage,
                         AuditService auditService,
                         ObjectMapper objectMapper,
                         @Value("${truereport.report.public-base-url:http://localhost:8080}") String publicBaseUrl) {
        this.reports = reports;
        this.versions = versions;
        this.generationJobs = generationJobs;
        this.artifacts = artifacts;
        this.links = links;
        this.derivatives = derivatives;
        this.jobs = jobs;
        this.finalSnapshots = finalSnapshots;
        this.consents = consents;
        this.snapshotBuilder = snapshotBuilder;
        this.tokenService = tokenService;
        this.storage = storage;
        this.auditService = auditService;
        this.objectMapper = objectMapper;
        this.publicBaseUrl = publicBaseUrl.endsWith("/")
                ? publicBaseUrl.substring(0, publicBaseUrl.length() - 1) : publicBaseUrl;
    }

    @Transactional
    public void createForFinalized(InspectionJob job, String finalSnapshotJson, byte[] finalSnapshotHash) {
        if (reports.findByJobId(job.getId()).isPresent()) {
            return;
        }
        Report report = reports.save(new Report(job.getWorkshopId(), job.getId()));
        createVersion(report, job, finalSnapshotJson, finalSnapshotHash);
    }

    private void createVersion(Report report, InspectionJob job, String finalSnapshotJson,
                               byte[] finalSnapshotHash) {
        ReportSnapshot snapshot = snapshotBuilder.build(parse(finalSnapshotJson), hex(finalSnapshotHash));
        String snapshotJson = json(snapshot);
        ReportVersion version = versions.save(new ReportVersion(
                report.getId(), report.getWorkshopId(), 1, snapshot.reportNumber(),
                finalSnapshotHash, snapshotJson, hash(snapshotJson),
                LocalDateTime.parse(snapshot.finalizedAt())));
        generationJobs.save(new ReportGenerationJob(version.getId()));
        links.save(new PublicShareLink(report.getWorkshopId(), version.getId()));
    }

    @Transactional
    public ReportAdminDto adminForJob(CurrentUser caller, UUID jobId) {
        ReportContext context = contextForAdmin(caller, jobId);
        return adminDto(context);
    }

    @Transactional
    public ReportAdminDto retry(CurrentUser caller, UUID jobId) {
        ReportContext context = contextForAdmin(caller, jobId);
        ReportGenerationJob job = generationJobs.findByReportVersionId(context.version().getId())
                .orElseThrow(() -> new ApiException(HttpStatus.CONFLICT, "REPORT_NOT_READY",
                        "error.report.notReady", "Report generation job is missing"));
        if (job.getStatus().equals("GENERATING")) {
            throw new ApiException(HttpStatus.CONFLICT, "REPORT_GENERATING",
                    "error.report.generating", "Report generation is already running");
        }
        if (job.getStatus().equals("READY")) {
            return adminDto(context);
        }
        job.retry();
        generationJobs.save(job);
        audit(caller, context.report(), "REPORT_RETRY", null);
        return adminDto(new ReportContext(context.report(), context.version(), job, context.link()));
    }

    @Transactional
    public ReportLinkResponse activate(CurrentUser caller, UUID jobId) {
        ReportContext context = contextForAdmin(caller, jobId);
        PublicShareLink link = context.link();
        if (link == null) {
            link = links.save(new PublicShareLink(context.report().getWorkshopId(), context.version().getId()));
        }
        if (link.getStatus().equals("REVOKED")) {
            throw new ApiException(HttpStatus.CONFLICT, "LINK_REVOKED",
                    "error.link.revoked", "A revoked link cannot be reactivated in V1");
        }
        if (link.getStatus().equals("ACTIVE")) {
            return new ReportLinkResponse(link.getStatus(), null, link.isPdfDownloadEnabled());
        }
        if (!consentGranted(context.report().getJobId())) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "CONSENT_REQUIRED",
                    "error.consent.required", "Public-link consent must be granted before activation");
        }
        String token = tokenService.newToken();
        try {
            link.activate(tokenService.hash(token), now());
        } catch (IllegalStateException exception) {
            throw new ApiException(HttpStatus.CONFLICT, "LINK_STATE_CONFLICT",
                    "error.link.state", "Link state does not allow activation");
        }
        links.save(link);
        audit(caller, context.report(), "PUBLIC_LINK_ACTIVATED", null);
        return new ReportLinkResponse(link.getStatus(), publicBaseUrl + "/r/" + token,
                link.isPdfDownloadEnabled());
    }

    @Transactional
    public ReportLinkResponse revoke(CurrentUser caller, UUID jobId, RevokeLinkRequest request) {
        ReportContext context = contextForAdmin(caller, jobId);
        PublicShareLink link = context.link();
        if (link == null) {
            throw new ApiException(HttpStatus.CONFLICT, "LINK_NOT_CREATED",
                    "error.link.notCreated", "No public link exists");
        }
        if (!REVOCATION_REASONS.contains(request.reasonCode())) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "REVOCATION_REASON_INVALID",
                    "error.revocation.reason", "Revocation reason is invalid");
        }
        var activeLinks = links.findByReportVersionIdAndStatusOrderByCreatedAtDesc(
                context.version().getId(), "ACTIVE");
        if (activeLinks.isEmpty() && !link.getStatus().equals("REVOKED")) {
            link.revoke(caller.userId(), request.reasonCode(), request.note(), now());
            links.save(link);
            audit(caller, context.report(), "PUBLIC_LINK_REVOKED", request.reasonCode());
        } else {
            for (PublicShareLink active : activeLinks) {
                active.revoke(caller.userId(), request.reasonCode(), request.note(), now());
                links.save(active);
            }
            if (!activeLinks.isEmpty()) {
                audit(caller, context.report(), "PUBLIC_LINK_REVOKED", request.reasonCode());
            }
        }
        return new ReportLinkResponse(link.getStatus(), null, link.isPdfDownloadEnabled());
    }

    @Transactional
    public ReportLinkResponse setPdfDownload(CurrentUser caller, UUID jobId, boolean enabled) {
        ReportContext context = contextForAdmin(caller, jobId);
        PublicShareLink link = context.link();
        if (link == null) {
            throw new ApiException(HttpStatus.CONFLICT, "LINK_NOT_CREATED",
                    "error.link.notCreated", "No public link exists");
        }
        link.setPdfDownloadEnabled(enabled);
        links.save(link);
        audit(caller, context.report(), "PDF_DOWNLOAD_SETTING_CHANGED", enabled ? "ENABLED" : "DISABLED");
        return new ReportLinkResponse(link.getStatus(), null, link.isPdfDownloadEnabled());
    }

    @Transactional
    public byte[] pdfForAdmin(CurrentUser caller, UUID jobId) {
        ReportContext context = contextForAdmin(caller, jobId);
        ReportGenerationJob job = context.generationJob();
        if (job == null || !job.getStatus().equals("READY")) {
            throw new ApiException(HttpStatus.CONFLICT, "REPORT_NOT_READY",
                    "error.report.notReady", "The report PDF is not ready");
        }
        ReportArtifact artifact = artifacts.findByReportVersionIdAndKind(
                        context.version().getId(), "PDF")
                .orElseThrow(() -> new ApiException(HttpStatus.CONFLICT, "REPORT_NOT_READY",
                        "error.report.notReady", "The report PDF is not ready"));
        return storage.get(artifact.getStorageKey());
    }

    @Transactional(readOnly = true)
    public ReportStatusDto technicianStatus(CurrentUser caller, UUID jobId) {
        InspectionJob job = jobs.findByIdAndWorkshopId(jobId, caller.workshopId())
                .orElseThrow(ApiException::notFound);
        if (!caller.userId().equals(job.getAssignedTechnicianId())
                && !caller.userId().equals(job.getCreatedBy())) {
            throw new ApiException(HttpStatus.CONFLICT, "JOB_REASSIGNED",
                    "error.job.reassigned", "The job was reassigned");
        }
        Report report = reports.findByJobIdAndWorkshopId(jobId, caller.workshopId())
                .orElseThrow(ApiException::notFound);
        ReportVersion version = versions.findFirstByReportIdOrderByVersionNoDesc(report.getId())
                .orElseThrow(ApiException::notFound);
        ReportGenerationJob generation = generationJobs.findByReportVersionId(version.getId()).orElse(null);
        return new ReportStatusDto(version.getReportNumber(), version.getVersionNo(),
                generation == null ? "QUEUED" : generation.getStatus(),
                generation != null && generation.getStatus().equals("READY"),
                version.getFinalizedAt().toString());
    }

    public ReportContext contextForAdmin(CurrentUser caller, UUID jobId) {
        if (!caller.isWorkshopAdmin() || caller.workshopId() == null) {
            throw ApiException.notFound();
        }
        InspectionJob job = jobs.findByIdAndWorkshopId(jobId, caller.workshopId())
                .orElseThrow(ApiException::notFound);
        if (!job.getStatus().equals("FINALIZED")) {
            throw new ApiException(HttpStatus.CONFLICT, "REPORT_NOT_READY",
                    "error.report.notReady", "The inspection is not finalized");
        }
        Report report = reports.findByJobIdAndWorkshopId(jobId, caller.workshopId())
                .orElseGet(() -> createLegacyReport(job));
        ReportVersion version = versions.findFirstByReportIdOrderByVersionNoDesc(report.getId())
                .orElseThrow(ApiException::notFound);
        ReportGenerationJob generation = generationJobs.findByReportVersionId(version.getId()).orElse(null);
        PublicShareLink link = links.findFirstByReportVersionIdOrderByCreatedAtDesc(version.getId()).orElse(null);
        return new ReportContext(report, version, generation, link);
    }

    private Report createLegacyReport(InspectionJob job) {
        InspectionFinalSnapshot snapshot = finalSnapshots.findByJobId(job.getId())
                .orElseThrow(() -> new ApiException(HttpStatus.CONFLICT, "REPORT_NOT_READY",
                        "error.report.notReady", "The final snapshot is missing"));
        Report report = reports.save(new Report(job.getWorkshopId(), job.getId()));
        createVersion(report, job, snapshot.getSnapshotJson(), snapshot.getSnapshotHash());
        return report;
    }

    private ReportAdminDto adminDto(ReportContext context) {
        ReportGenerationJob generation = context.generationJob();
        PublicShareLink link = context.link();
        ReportArtifact pdf = artifacts.findByReportVersionIdAndKind(context.version().getId(), "PDF")
                .orElse(null);
        return new ReportAdminDto(
                context.report().getId(), context.report().getJobId(),
                context.version().getReportNumber(), context.version().getVersionNo(),
                generation == null ? "QUEUED" : generation.getStatus(),
                generation == null ? null : generation.getLastError(),
                generation == null ? 0 : generation.getAttempts(),
                generation != null && generation.getStatus().equals("READY"),
                pdf != null,
                link != null && link.isPdfDownloadEnabled(),
                link == null ? "PENDING_CONSENT" : link.getStatus(),
                consentGranted(context.report().getJobId()) ? "GRANTED" : "MISSING_OR_NOT_GRANTED",
                null,
                context.version().getFinalizedAt().toString(),
                hex(context.version().getSnapshotHash()),
                links.countByReportVersionIdAndStatus(context.version().getId(), "ACTIVE"),
                parseSnapshot(context.version()));
    }

    @Transactional
    public CreatedLink createDeliveryLink(UUID workshopId, ReportVersion version, CurrentUser caller) {
        String token = tokenService.newToken();
        PublicShareLink link = new PublicShareLink(workshopId, version.getId());
        link.activate(tokenService.hash(token), now());
        links.save(link);
        audit(caller, reports.findById(version.getReportId())
                        .orElseThrow(() -> new IllegalStateException("Report is missing")),
                "PUBLIC_LINK_CREATED_FOR_DELIVERY", null);
        return new CreatedLink(link.getId(), token, publicBaseUrl + "/r/" + token,
                link.isPdfDownloadEnabled());
    }

    public CreatedLink createDeliveryLink(UUID workshopId, ReportVersion version,
                                          String token, CurrentUser caller) {
        return createDeliveryLink(workshopId, version, caller);
    }

    public boolean consentGranted(UUID jobId) {
        List<ConsentRecord> records = consents.findByJobIdOrderByCapturedAtDesc(jobId);
        for (ConsentRecord record : records) {
            if (record.getConsentType().equals("PUBLIC_LINK")) {
                return record.getStatus().equals("GRANTED");
            }
        }
        return false;
    }

    private void audit(CurrentUser caller, Report report, String action, String reason) {
        auditService.record(report.getWorkshopId(), caller.userId(), caller.role(), action,
                "REPORT", report.getId(), reason, null);
    }

    private ReportSnapshot parseSnapshot(ReportVersion version) {
        try {
            return objectMapper.readValue(version.getSnapshotJson(), ReportSnapshot.class);
        } catch (Exception exception) {
            throw new IllegalStateException("Invalid report snapshot", exception);
        }
    }

    private LocalDateTime now() {
        return LocalDateTime.now(ZoneOffset.UTC);
    }

    private String hex(byte[] value) {
        return value == null ? "" : HexFormat.of().formatHex(value);
    }

    private byte[] hash(String value) {
        try {
            return MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }

    private com.fasterxml.jackson.databind.JsonNode parse(String value) {
        try {
            return objectMapper.readTree(value);
        } catch (Exception exception) {
            throw new IllegalStateException("Invalid final snapshot", exception);
        }
    }

    private String json(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception exception) {
            throw new IllegalStateException("Cannot serialize report snapshot", exception);
        }
    }

    public record CreatedLink(UUID id, String token, String publicUrl, boolean pdfDownloadEnabled) {
    }

    public record ReportContext(Report report, ReportVersion version,
                                ReportGenerationJob generationJob, PublicShareLink link) {
    }
}
