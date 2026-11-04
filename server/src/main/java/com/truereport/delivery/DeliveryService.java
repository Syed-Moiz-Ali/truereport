package com.truereport.delivery;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.audit.AuditService;
import com.truereport.inspections.ConsentRecord;
import com.truereport.inspections.ConsentRecordRepository;
import com.truereport.jobs.InspectionJob;
import com.truereport.jobs.InspectionJobRepository;
import com.truereport.reports.PublicShareLink;
import com.truereport.reports.PublicShareLinkRepository;
import com.truereport.reports.Report;
import com.truereport.reports.ReportArtifact;
import com.truereport.reports.ReportArtifactRepository;
import com.truereport.reports.ReportGenerationJob;
import com.truereport.reports.ReportGenerationJobRepository;
import com.truereport.reports.ReportRepository;
import com.truereport.reports.ReportService;
import com.truereport.reports.ReportVersion;
import com.truereport.reports.ReportVersionRepository;
import com.truereport.delivery.api.DeliveryAttemptDto;
import com.truereport.delivery.api.DeliveryDto;
import com.truereport.delivery.api.SendDeliveryRequest;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.security.CurrentUser;
import com.truereport.shared.storage.ObjectStorage;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.HexFormat;

@Service
public class DeliveryService {

    private static final Set<String> CHANNELS = Set.of("WHATSAPP", "SMS", "EMAIL");
    private static final Set<String> LANGUAGES = Set.of("en", "ar");
    private static final Set<String> FAILURE_STATUSES = Set.of("FAILED", "RETRY_PENDING", "DEAD_LETTER");

    private final DeliveryRequestRepository requests;
    private final DeliveryAttemptRepository attempts;
    private final DeliveryProviderRegistry providers;
    private final DeliveryRecipientPolicy recipientPolicy;
    private final InspectionJobRepository jobs;
    private final ReportRepository reports;
    private final ReportVersionRepository reportVersions;
    private final ReportGenerationJobRepository reportJobs;
    private final ReportArtifactRepository artifacts;
    private final PublicShareLinkRepository links;
    private final ConsentRecordRepository consents;
    private final ReportService reportService;
    private final ObjectStorage storage;
    private final AuditService auditService;
    private final ObjectMapper objectMapper;
    private final MeterRegistry meterRegistry;
    private final int maxAttempts;
    private final int retryBaseSeconds;
    private final int rateLimitPerHour;
    private final long emailMaxAttachmentBytes;

    public DeliveryService(DeliveryRequestRepository requests,
                           DeliveryAttemptRepository attempts,
                           DeliveryProviderRegistry providers,
                           DeliveryRecipientPolicy recipientPolicy,
                           InspectionJobRepository jobs,
                           ReportRepository reports,
                           ReportVersionRepository reportVersions,
                           ReportGenerationJobRepository reportJobs,
                           ReportArtifactRepository artifacts,
                           PublicShareLinkRepository links,
                           ConsentRecordRepository consents,
                           ReportService reportService,
                           ObjectStorage storage,
                           AuditService auditService,
                           ObjectMapper objectMapper,
                           MeterRegistry meterRegistry,
                           @Value("${truereport.delivery.max-attempts:3}") int maxAttempts,
                           @Value("${truereport.delivery.retry-base-seconds:30}") int retryBaseSeconds,
                           @Value("${truereport.delivery.rate-limit-per-hour:10}") int rateLimitPerHour,
                           @Value("${truereport.delivery.email-max-attachment-bytes:10485760}")
                           long emailMaxAttachmentBytes) {
        this.requests = requests;
        this.attempts = attempts;
        this.providers = providers;
        this.recipientPolicy = recipientPolicy;
        this.jobs = jobs;
        this.reports = reports;
        this.reportVersions = reportVersions;
        this.reportJobs = reportJobs;
        this.artifacts = artifacts;
        this.links = links;
        this.consents = consents;
        this.reportService = reportService;
        this.storage = storage;
        this.auditService = auditService;
        this.objectMapper = objectMapper;
        this.meterRegistry = meterRegistry;
        this.maxAttempts = maxAttempts;
        this.retryBaseSeconds = retryBaseSeconds;
        this.rateLimitPerHour = rateLimitPerHour;
        this.emailMaxAttachmentBytes = emailMaxAttachmentBytes;
    }

    @Transactional
    public DeliveryDto request(CurrentUser caller, UUID jobId, SendDeliveryRequest body,
                               String idempotencyKey) {
        requireAdmin(caller);
        if (idempotencyKey == null || idempotencyKey.isBlank()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "IDEMPOTENCY_KEY_REQUIRED",
                    "error.idempotency.required", "Idempotency-Key is required");
        }
        String channel = body.channel().toUpperCase(Locale.ROOT);
        if (!CHANNELS.contains(channel)) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "CHANNEL_INVALID",
                    "error.delivery.channel", "Unsupported delivery channel");
        }
        if (!LANGUAGES.contains(body.language())) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "LANGUAGE_INVALID",
                    "error.delivery.language", "Unsupported report language");
        }
        InspectionJob job = jobs.findByIdAndWorkshopId(jobId, caller.workshopId())
                .orElseThrow(ApiException::notFound);
        if (!job.getStatus().equals("FINALIZED")) {
            throw new ApiException(HttpStatus.CONFLICT, "REPORT_NOT_READY",
                    "error.report.notReady", "The inspection is not finalized");
        }
        Report report = reports.findByJobIdAndWorkshopId(jobId, caller.workshopId())
                .orElseThrow(() -> new ApiException(HttpStatus.CONFLICT, "REPORT_NOT_READY",
                        "error.report.notReady", "The report is not ready"));
        ReportVersion version = reportVersions.findFirstByReportIdOrderByVersionNoDesc(
                report.getId()).orElseThrow(ApiException::notFound);
        ReportGenerationJob generation = reportJobs.findByReportVersionId(version.getId()).orElse(null);
        if (generation == null || !generation.getStatus().equals("READY")) {
            throw new ApiException(HttpStatus.CONFLICT, "REPORT_NOT_READY",
                    "error.report.notReady", "The report is not ready");
        }
        String consentType = channel.equals("EMAIL") ? "EMAIL" : channel;
        ConsentRecord consent = latestConsent(jobId, consentType);
        if (consent == null || !consent.getStatus().equals("GRANTED")) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "CONSENT_REQUIRED",
                    "error.delivery.consent", "Channel consent is required");
        }
        if (!channel.equals("EMAIL") && !consentGranted(jobId, "PUBLIC_LINK")) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "CONSENT_REQUIRED",
                    "error.delivery.publicLinkConsent", "Public-link consent is required");
        }
        String recipient = channel.equals("EMAIL") ? job.getCustomerEmail() : job.getCustomerPhone();
        if (recipient == null || recipient.isBlank()) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "RECIPIENT_MISSING",
                    "error.delivery.recipientMissing", "The recorded customer recipient is missing");
        }
        if (!recipientPolicy.allowed(channel, recipient)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "RECIPIENT_NOT_ALLOWED",
                    "error.delivery.recipientNotAllowed",
                    "Real recipients are disabled; only configured test recipients are allowed");
        }
        byte[] idempotencyHash = hash(idempotencyKey);
        byte[] requestHash = hash(jobId + "|" + channel + "|" + body.language());
        DeliveryRequestEntity existing = requests.findByWorkshopIdAndIdempotencyKeyHash(
                caller.workshopId(), idempotencyHash).orElse(null);
        if (existing != null) {
            if (!MessageDigest.isEqual(existing.getRequestHash(), requestHash)) {
                throw ApiException.conflict("IDEMPOTENCY_KEY_REUSED", "Idempotency key was reused");
            }
            return dto(existing);
        }
        if (requests.countByWorkshopIdAndRecipientHashAndCreatedAtAfter(
                caller.workshopId(), recipientPolicy.hash(recipient),
                LocalDateTime.now(ZoneOffset.UTC).minusHours(1)) >= rateLimitPerHour) {
            throw new ApiException(HttpStatus.TOO_MANY_REQUESTS, "DELIVERY_RATE_LIMITED",
                    "error.delivery.rateLimited", "Delivery rate limit exceeded");
        }
        DeliveryRequestEntity request = requests.save(new DeliveryRequestEntity(
                caller.workshopId(), jobId, version.getId(), channel,
                recipientPolicy.masked(channel, recipient), recipientPolicy.hash(recipient),
                body.language(), requestHash, idempotencyHash, consentType,
                caller.userId(), maxAttempts));
        audit(caller, request, "DELIVERY_REQUESTED", null);
        return dto(request);
    }

    @Transactional(readOnly = true)
    public List<DeliveryDto> forAdmin(CurrentUser caller, UUID jobId) {
        requireAdmin(caller);
        jobs.findByIdAndWorkshopId(jobId, caller.workshopId()).orElseThrow(ApiException::notFound);
        return requests.findByWorkshopIdAndJobIdOrderByCreatedAtDesc(
                        caller.workshopId(), jobId).stream().map(this::dto).toList();
    }

    @Transactional(readOnly = true)
    public List<DeliveryDto> forTechnician(CurrentUser caller, UUID jobId) {
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
        return requests.findByWorkshopIdAndJobIdOrderByCreatedAtDesc(
                        caller.workshopId(), jobId).stream().map(this::dto).toList();
    }

    @Transactional(readOnly = true)
    public List<DeliveryDto> forPlatform(CurrentUser caller) {
        if (!caller.isPlatformAdmin()) {
            throw ApiException.notFound();
        }
        return requests.findAll().stream()
                .sorted((left, right) -> right.getCreatedAt().compareTo(left.getCreatedAt()))
                .limit(100).map(this::dto).toList();
    }

    @Transactional
    public DeliveryDto retry(CurrentUser caller, UUID jobId, UUID requestId,
                             String idempotencyKey) {
        requireAdmin(caller);
        if (idempotencyKey == null || idempotencyKey.isBlank()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "IDEMPOTENCY_KEY_REQUIRED",
                    "error.idempotency.required", "Idempotency-Key is required");
        }
        jobs.findByIdAndWorkshopId(jobId, caller.workshopId()).orElseThrow(ApiException::notFound);
        DeliveryRequestEntity request = requests.findById(requestId)
                .filter(value -> value.getWorkshopId().equals(caller.workshopId())
                        && value.getJobId().equals(jobId))
                .orElseThrow(ApiException::notFound);
        byte[] retryHash = hash(idempotencyKey);
        if (request.isRetryKey(retryHash)) {
            return dto(request);
        }
        if (!FAILURE_STATUSES.contains(request.getStatus())) {
            throw new ApiException(HttpStatus.CONFLICT, "DELIVERY_NOT_RETRYABLE",
                    "error.delivery.notRetryable", "Only failed or dead-letter deliveries can be retried");
        }
        request.retryNow(retryHash, maxAttempts);
        requests.save(request);
        audit(caller, request, "DELIVERY_RETRIED", null);
        return dto(request);
    }

    @Scheduled(fixedDelayString = "${truereport.delivery.worker-delay-ms:2000}")
    @Transactional
    public void poll() {
        for (UUID id : requests.findDueIds(LocalDateTime.now(ZoneOffset.UTC))) {
            deliver(id);
        }
    }

    private void deliver(UUID requestId) {
        DeliveryRequestEntity request = requests.findForUpdate(requestId).orElse(null);
        if (request == null || !(request.getStatus().equals("QUEUED")
                || request.getStatus().equals("RETRY_PENDING"))) {
            return;
        }
        InspectionJob job = jobs.findById(request.getJobId()).orElse(null);
        ReportVersion version = reportVersions.findById(request.getReportVersionId()).orElse(null);
        if (job == null || version == null) {
            fail(request, null, "REPORT_NOT_FOUND", "Report source is missing");
            return;
        }
        DeliveryProvider provider;
        try {
            provider = providers.forChannel(request.getChannel());
        } catch (RuntimeException exception) {
            fail(request, null, "PROVIDER_NOT_CONFIGURED", "No provider is configured");
            return;
        }
        DeliveryAttempt attempt = attempts.save(new DeliveryAttempt(
                request.getId(), request.getAttempts() + 1, provider.name()));
        try {
            DeliveryProvider.DeliveryMessage message = buildMessage(request, job, version);
            DeliveryProvider.DeliveryResult result = provider.send(message);
            if (!result.accepted()) {
                fail(request, attempt, result.errorCode(), result.errorMessage());
                return;
            }
            attempt.sent(result.providerMessageId());
            request.markSent(request.getPublicShareLinkId(), message.pdf() != null);
            if (result.delivered()) {
                attempt.delivered();
                request.markDelivered();
            }
            attempts.save(attempt);
            requests.save(request);
            audit(null, request, result.delivered() ? "DELIVERY_DELIVERED" : "DELIVERY_SENT", null);
        } catch (RuntimeException exception) {
            fail(request, attempt, "PROVIDER_FAILURE", exception.getMessage());
        }
    }

    private DeliveryProvider.DeliveryMessage buildMessage(DeliveryRequestEntity request,
                                                          InspectionJob job,
                                                          ReportVersion version) {
        if (request.getChannel().equals("EMAIL")) {
            byte[] pdf = reportPdf(version.getId());
            if (pdf.length > emailMaxAttachmentBytes) {
                if (!consentGranted(job.getId(), "PUBLIC_LINK")) {
                    throw new IllegalStateException("PDF_TOO_LARGE");
                }
                CreatedLink link = createLink(request, version);
                request = link.request();
                DeliveryMessages.Message message = DeliveryMessages.forLink(
                        request.getLanguage(), version.getReportNumber(), link.url());
                return new DeliveryProvider.DeliveryMessage("EMAIL", job.getCustomerEmail(),
                        request.getLanguage(), message.subject(), message.body(),
                        version.getReportNumber(), null, null);
            }
            DeliveryMessages.Message message = DeliveryMessages.forEmail(
                    request.getLanguage(), version.getReportNumber());
            return new DeliveryProvider.DeliveryMessage("EMAIL", job.getCustomerEmail(),
                    request.getLanguage(), message.subject(), message.body(),
                    version.getReportNumber(), pdf, "inspection-report.pdf");
        }
        CreatedLink link = createLink(request, version);
        DeliveryMessages.Message message = DeliveryMessages.forLink(
                request.getLanguage(), version.getReportNumber(), link.url());
        String recipient = job.getCustomerPhone();
        return new DeliveryProvider.DeliveryMessage(request.getChannel(), recipient,
                request.getLanguage(), message.subject(), message.body(),
                version.getReportNumber(), null, null);
    }

    private CreatedLink createLink(DeliveryRequestEntity request, ReportVersion version) {
        if (!consentGranted(request.getJobId(), "PUBLIC_LINK")) {
            throw new IllegalStateException("PUBLIC_LINK_CONSENT_REQUIRED");
        }
        ReportService.CreatedLink created = reportService.createDeliveryLink(
                request.getWorkshopId(), version,
                new CurrentUser(request.getRequestedBy(), "", "WORKSHOP_ADMIN",
                        request.getWorkshopId(), null));
        request.setPublicShareLinkId(created.id());
        return new CreatedLink(request, created.publicUrl(), created.id());
    }

    private byte[] reportPdf(UUID reportVersionId) {
        ReportArtifact artifact = artifacts.findByReportVersionIdAndKind(reportVersionId, "PDF")
                .orElseThrow(() -> new IllegalStateException("REPORT_PDF_MISSING"));
        return storage.get(artifact.getStorageKey());
    }

    private void fail(DeliveryRequestEntity request, DeliveryAttempt attempt,
                      String code, String message) {
        if (attempt != null) {
            attempt.failed(code, message);
            if (request.getAttempts() + 1 >= maxAttempts) {
                attempt.deadLetter();
            } else {
                attempt.retryPending();
            }
            attempts.save(attempt);
        }
        request.markRetry(code, message, maxAttempts, retryBaseSeconds);
        requests.save(request);
        if (request.getStatus().equals("DEAD_LETTER")) {
            meterRegistry.counter("truereport.delivery.dead_letter").increment();
        }
        audit(null, request, request.getStatus().equals("DEAD_LETTER")
                ? "DELIVERY_DEAD_LETTER" : "DELIVERY_FAILED", code);
    }

    private DeliveryDto dto(DeliveryRequestEntity request) {
        String linkState = "PENDING";
        if (request.getPublicShareLinkId() != null) {
            linkState = links.findById(request.getPublicShareLinkId())
                    .map(PublicShareLink::getStatus).orElse("MISSING");
        }
        List<DeliveryAttemptDto> history = attempts
                .findByDeliveryRequestIdOrderByAttemptNoAsc(request.getId()).stream()
                .map(attempt -> new DeliveryAttemptDto(attempt.getId(), attempt.getAttemptNo(),
                        attempt.getProvider(), attempt.getStatus(), attempt.getProviderMessageId(),
                        attempt.getErrorCode(), attempt.getErrorMessage(),
                        attempt.getSentAt() == null ? "" : attempt.getSentAt().toString(),
                        attempt.getDeliveredAt() == null ? "" : attempt.getDeliveredAt().toString()))
                .toList();
        return new DeliveryDto(request.getId(), request.getChannel(), request.getRecipientMasked(),
                request.getLanguage(), request.getStatus(), request.getAttempts(),
                request.getMaxAttempts(), request.isPdfAttached(), linkState,
                request.getLastErrorCode(), request.getLastErrorMessage(),
                request.getNextAttemptAt() == null ? "" : request.getNextAttemptAt().toString(),
                request.getCreatedAt() == null ? "" : request.getCreatedAt().toString(),
                request.getUpdatedAt() == null ? "" : request.getUpdatedAt().toString(), history);
    }

    private ConsentRecord latestConsent(UUID jobId, String type) {
        for (ConsentRecord record : consents.findByJobIdOrderByCapturedAtDesc(jobId)) {
            if (record.getConsentType().equals(type)) {
                return record;
            }
        }
        return null;
    }

    private boolean consentGranted(UUID jobId, String type) {
        ConsentRecord record = latestConsent(jobId, type);
        return record != null && record.getStatus().equals("GRANTED");
    }

    private void requireAdmin(CurrentUser caller) {
        if (!caller.isWorkshopAdmin() || caller.workshopId() == null) {
            throw ApiException.notFound();
        }
    }

    private void audit(CurrentUser caller, DeliveryRequestEntity request, String action,
                       String reasonCode) {
        auditService.record(request.getWorkshopId(), caller == null ? request.getRequestedBy()
                        : caller.userId(), caller == null ? "WORKSHOP_ADMIN" : caller.role(),
                action, "DELIVERY", request.getId(), reasonCode,
                json(Map.of("channel", request.getChannel(), "status", request.getStatus())));
    }

    private byte[] hash(String value) {
        try {
            return MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8));
        } catch (Exception exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }

    private String json(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception exception) {
            return "{}";
        }
    }

    private record CreatedLink(DeliveryRequestEntity request, String url, UUID linkId) {
    }
}
