package com.truereport.reports;

import com.truereport.jobs.InspectionJob;
import com.truereport.jobs.InspectionJobRepository;
import com.truereport.shared.storage.ObjectStorage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Service
public class PublicReportService {

    private static final Logger log = LoggerFactory.getLogger(PublicReportService.class);

    public enum Status {
        ACTIVE, TEMPORARY, UNAVAILABLE
    }

    public record Resolution(Status status, Resolved resolved) {
        static Resolution unavailable() {
            return new Resolution(Status.UNAVAILABLE, null);
        }

        static Resolution temporary() {
            return new Resolution(Status.TEMPORARY, null);
        }
    }

    public record Resolved(PublicShareLink link, Report report, ReportVersion version,
                           Map<String, Object> page, String customerName) {
    }

    public record Photo(byte[] bytes, String mime) {
    }

    private final PublicShareLinkRepository links;
    private final ReportRepository reports;
    private final ReportVersionRepository versions;
    private final ReportGenerationJobRepository jobs;
    private final ReportArtifactRepository artifacts;
    private final EvidenceDerivativeRepository derivatives;
    private final ReportViewMapper viewMapper;
    private final ObjectStorage storage;
    private final ReportTokenService tokenService;
    private final ReportPdfService pdfService;
    private final CleanPublicReportReader cleanReports;
    private final InspectionJobRepository inspectionJobs;

    public PublicReportService(PublicShareLinkRepository links,
                               ReportRepository reports,
                               ReportVersionRepository versions,
                               ReportGenerationJobRepository jobs,
                               ReportArtifactRepository artifacts,
                               EvidenceDerivativeRepository derivatives,
                               ReportViewMapper viewMapper,
                               ObjectStorage storage,
                               ReportTokenService tokenService,
                               ReportPdfService pdfService,
                               CleanPublicReportReader cleanReports,
                               InspectionJobRepository inspectionJobs) {
        this.links = links;
        this.reports = reports;
        this.versions = versions;
        this.jobs = jobs;
        this.artifacts = artifacts;
        this.derivatives = derivatives;
        this.viewMapper = viewMapper;
        this.storage = storage;
        this.tokenService = tokenService;
        this.pdfService = pdfService;
        this.cleanReports = cleanReports;
        this.inspectionJobs = inspectionJobs;
    }

    @Transactional(readOnly = true)
    public Resolution resolve(String token, String language) {
        if (token == null || token.isBlank() || token.length() > 200) {
            return Resolution.unavailable();
        }
        Optional<PublicShareLink> link = links.findByTokenHash(tokenService.hash(token));
        if (link.isEmpty() || !link.get().getStatus().equals("ACTIVE")) {
            return resolveClean(token, language);
        }
        PublicShareLink active = link.get();
        ReportVersion version = versions.findById(active.getReportVersionId()).orElse(null);
        if (version == null) {
            return resolveClean(token, language);
        }
        Report report = reports.findById(version.getReportId()).orElse(null);
        if (report == null) {
            return resolveClean(token, language);
        }
        ReportGenerationJob generation = jobs.findByReportVersionId(version.getId()).orElse(null);
        if (generation == null || !generation.getStatus().equals("READY")) {
            return Resolution.temporary();
        }
        try {
            List<EvidenceDerivative> publicDerivatives =
                    derivatives.findByReportVersionIdOrderByCreatedAtAsc(version.getId());
            String customerName = report.getJobId() == null ? null
                    : inspectionJobs.findById(report.getJobId())
                            .map(InspectionJob::getCustomerName).orElse(null);
            Map<String, Object> page = viewMapper.publicPage(version, publicDerivatives,
                    "en", active.isPdfDownloadEnabled(), token, customerName);
            return new Resolution(Status.ACTIVE,
                    new Resolved(active, report, version, page, customerName));
        } catch (Exception exception) {
            return Resolution.unavailable();
        }
    }

    /**
     * Clean report path: platform_public_links -> platform_report_versions.
     * There is no separate generation job; an ACTIVE link with a stored version
     * is renderable immediately.
     */
    private Resolution resolveClean(String token, String language) {
        Optional<CleanPublicReportReader.Row> found = cleanReports.findByToken(token);
        if (found.isEmpty()) {
            return Resolution.unavailable();
        }
        CleanPublicReportReader.Row row = found.get();
        if (!"ACTIVE".equals(row.status())) {
            return "PENDING".equals(row.status()) ? Resolution.temporary() : Resolution.unavailable();
        }
        try {
            UUID workshopId;
            try {
                workshopId = UUID.fromString(row.workshopId());
            } catch (RuntimeException ignored) {
                workshopId = UUID.nameUUIDFromBytes(row.workshopId().getBytes());
            }
            byte[] hash = row.snapshotHash() == null ? new byte[0] : hexToBytes(row.snapshotHash());
            java.time.LocalDateTime finalized = row.finalizedAt() != null
                    ? row.finalizedAt()
                    : (row.publishedAt() != null ? row.publishedAt() : java.time.LocalDateTime.now());
            ReportVersion version = new ReportVersion(
                    UUID.nameUUIDFromBytes(("report:" + row.reportVersionId()).getBytes()),
                    workshopId,
                    row.versionNo(),
                    row.reportNumber(),
                    hash,
                    row.snapshotJson(),
                    hash,
                    finalized);
            List<EvidenceDerivative> publicEvidence = cleanReports.publicEvidence(
                    row.jobId(), UUID.fromString(row.reportVersionId()), workshopId);
            Map<String, Object> page = viewMapper.publicPage(version, publicEvidence, language,
                    row.pdfDownloadEnabled(), token, row.customerName());
            return new Resolution(Status.ACTIVE,
                    new Resolved(PublicShareLink.cleanActive(row.pdfDownloadEnabled()), null,
                            version, page, row.customerName()));
        } catch (Exception exception) {
            return Resolution.unavailable();
        }
    }

    private static byte[] hexToBytes(String hex) {
        if (hex == null || hex.isBlank()) {
            return new byte[0];
        }
        int length = hex.length();
        byte[] bytes = new byte[length / 2];
        for (int i = 0; i < length; i += 2) {
            bytes[i / 2] = (byte) Integer.parseInt(hex.substring(i, i + 2), 16);
        }
        return bytes;
    }

    @Transactional(readOnly = true)
    public Optional<Photo> photo(String token, UUID derivativeId) {
        Resolution resolution = resolve(token, "en");
        if (resolution.status() != Status.ACTIVE) {
            return Optional.empty();
        }
        if (resolution.resolved().report() == null) {
            return cleanReports.photo(token, derivativeId)
                    .map(photo -> new Photo(photo.bytes(), photo.mime()));
        }
        EvidenceDerivative derivative = derivatives.findByIdAndReportVersionId(
                derivativeId, resolution.resolved().version().getId()).orElse(null);
        if (derivative == null) {
            return Optional.empty();
        }
        byte[] bytes = storage.get(derivative.getStorageKey());
        return Optional.of(new Photo(bytes, derivative.getMime()));
    }

    @Transactional(readOnly = true)
    public Optional<Photo> video(String token, UUID derivativeId) {
        Resolution resolution = resolve(token, "en");
        if (resolution.status() != Status.ACTIVE || resolution.resolved().report() != null) {
            return Optional.empty();
        }
        return cleanReports.video(token, derivativeId)
                .map(video -> new Photo(video.bytes(), video.mime()));
    }

    @Transactional(readOnly = true)
    public Optional<byte[]> pdf(String token) {
        Resolution resolution = resolve(token, "en");
        if (resolution.status() != Status.ACTIVE || !resolution.resolved().link().isPdfDownloadEnabled()) {
            return Optional.empty();
        }
        UUID versionId = resolution.resolved().version().getId();
        // 1. Try to serve a pre-generated PDF artifact (legacy happy path).
        if (versionId != null) {
            ReportArtifact artifact = artifacts.findByReportVersionIdAndKind(versionId, "PDF")
                    .orElse(null);
            if (artifact != null) {
                return Optional.of(storage.get(artifact.getStorageKey()));
            }
        }
        // 2. No stored artifact — render on-demand using Chromium so the download
        //    button always works for clean reports and local/dev environments.
        try {
            List<EvidenceDerivative> publicDerivatives;
            if (resolution.resolved().report() == null) {
                Optional<CleanPublicReportReader.Row> row = cleanReports.findByToken(token);
                publicDerivatives = row.isEmpty() ? List.of()
                        : cleanReports.publicEvidence(row.get().jobId(),
                        UUID.fromString(row.get().reportVersionId()),
                        UUID.fromString(row.get().workshopId()));
            } else {
                publicDerivatives = derivatives.findByReportVersionIdOrderByCreatedAtAsc(versionId);
            }
            byte[] pdf = pdfService.render(resolution.resolved().version(), publicDerivatives,
                    resolution.resolved().customerName());
            return Optional.of(pdf);
        } catch (Exception e) {
            log.warn("On-demand public report PDF render failed for version {}: {}",
                    resolution.resolved().version().getId(), e.getMessage(), e);
            return Optional.empty();
        }
    }

    public static HttpStatus statusFor(Status status) {
        return switch (status) {
            case ACTIVE -> HttpStatus.OK;
            case TEMPORARY -> HttpStatus.SERVICE_UNAVAILABLE;
            case UNAVAILABLE -> HttpStatus.NOT_FOUND;
        };
    }
}
