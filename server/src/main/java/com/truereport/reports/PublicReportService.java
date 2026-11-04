package com.truereport.reports;

import com.truereport.shared.storage.ObjectStorage;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Service
public class PublicReportService {

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
                           Map<String, Object> page) {
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

    public PublicReportService(PublicShareLinkRepository links,
                               ReportRepository reports,
                               ReportVersionRepository versions,
                               ReportGenerationJobRepository jobs,
                               ReportArtifactRepository artifacts,
                               EvidenceDerivativeRepository derivatives,
                               ReportViewMapper viewMapper,
                               ObjectStorage storage,
                               ReportTokenService tokenService) {
        this.links = links;
        this.reports = reports;
        this.versions = versions;
        this.jobs = jobs;
        this.artifacts = artifacts;
        this.derivatives = derivatives;
        this.viewMapper = viewMapper;
        this.storage = storage;
        this.tokenService = tokenService;
    }

    @Transactional(readOnly = true)
    public Resolution resolve(String token, String language) {
        if (token == null || token.isBlank() || token.length() > 200) {
            return Resolution.unavailable();
        }
        Optional<PublicShareLink> link = links.findByTokenHash(tokenService.hash(token));
        if (link.isEmpty() || !link.get().getStatus().equals("ACTIVE")) {
            return Resolution.unavailable();
        }
        PublicShareLink active = link.get();
        ReportVersion version = versions.findById(active.getReportVersionId()).orElse(null);
        if (version == null) {
            return Resolution.unavailable();
        }
        Report report = reports.findById(version.getReportId()).orElse(null);
        if (report == null) {
            return Resolution.unavailable();
        }
        ReportGenerationJob generation = jobs.findByReportVersionId(version.getId()).orElse(null);
        if (generation == null || !generation.getStatus().equals("READY")) {
            return Resolution.temporary();
        }
        try {
            List<EvidenceDerivative> publicDerivatives =
                    derivatives.findByReportVersionIdOrderByCreatedAtAsc(version.getId());
            Map<String, Object> page = viewMapper.publicPage(version, publicDerivatives,
                    "ar".equals(language) ? "ar" : "en", active.isPdfDownloadEnabled());
            return new Resolution(Status.ACTIVE, new Resolved(active, report, version, page));
        } catch (Exception exception) {
            return Resolution.unavailable();
        }
    }

    @Transactional(readOnly = true)
    public Optional<Photo> photo(String token, UUID derivativeId) {
        Resolution resolution = resolve(token, "en");
        if (resolution.status() != Status.ACTIVE) {
            return Optional.empty();
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
    public Optional<byte[]> pdf(String token) {
        Resolution resolution = resolve(token, "en");
        if (resolution.status() != Status.ACTIVE || !resolution.resolved().link().isPdfDownloadEnabled()) {
            return Optional.empty();
        }
        ReportArtifact artifact = artifacts.findByReportVersionIdAndKind(
                resolution.resolved().version().getId(), "PDF").orElse(null);
        if (artifact == null) {
            return Optional.empty();
        }
        return Optional.of(storage.get(artifact.getStorageKey()));
    }

    public static HttpStatus statusFor(Status status) {
        return switch (status) {
            case ACTIVE -> HttpStatus.OK;
            case TEMPORARY -> HttpStatus.SERVICE_UNAVAILABLE;
            case UNAVAILABLE -> HttpStatus.NOT_FOUND;
        };
    }
}
