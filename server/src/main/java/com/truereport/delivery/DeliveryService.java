package com.truereport.delivery;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.audit.AuditService;
import com.truereport.delivery.api.DeliveryAttemptDto;
import com.truereport.delivery.api.DeliveryDto;
import com.truereport.delivery.api.SendDeliveryRequest;
import com.truereport.jobs.PlatformJobStore;
import com.truereport.jobs.PlatformJobStore.JobRow;
import com.truereport.jobs.PlatformJobStore.LinkRow;
import com.truereport.jobs.PlatformJobStore.ReportVersionRow;
import com.truereport.jobs.PlatformJobTokenService;
import com.truereport.localization.LanguageRepository;
import com.truereport.localization.api.LanguageDtos.LanguageDto;
import com.truereport.reports.PlatformReportPdfRenderer;
import com.truereport.shared.error.ApiException;
import com.truereport.shared.security.CurrentUser;
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

/**
 * Report delivery for platform jobs. The legacy {@code inspection_jobs} stack is
 * no longer a delivery source: jobs, report versions and public links all come
 * from the clean {@code platform_*} tables, so every workshop job — not only the
 * legacy reference job — can be delivered.
 */
@Service
public class DeliveryService {

    private static final Set<String> CHANNELS = Set.of("WHATSAPP", "SMS", "EMAIL");
    private static final Set<String> FAILURE_STATUSES = Set.of("FAILED", "RETRY_PENDING", "DEAD_LETTER");

    private final DeliveryRequestRepository requests;
    private final DeliveryAttemptRepository attempts;
    private final DeliveryProviderRegistry providers;
    private final DeliveryRecipientPolicy recipientPolicy;
    private final PlatformJobStore jobs;
    private final LanguageRepository languages;
    private final PlatformJobTokenService tokens;
    private final PlatformReportPdfRenderer pdfRenderer;
    private final AuditService auditService;
    private final ObjectMapper objectMapper;
    private final MeterRegistry meterRegistry;
    private final int maxAttempts;
    private final int retryBaseSeconds;
    private final int rateLimitPerHour;
    private final long emailMaxAttachmentBytes;
    private final String publicBaseUrl;

    public DeliveryService(DeliveryRequestRepository requests,
                           DeliveryAttemptRepository attempts,
                           DeliveryProviderRegistry providers,
                           DeliveryRecipientPolicy recipientPolicy,
                           PlatformJobStore jobs,
                           LanguageRepository languages,
                           PlatformJobTokenService tokens,
                           PlatformReportPdfRenderer pdfRenderer,
                           AuditService auditService,
                           ObjectMapper objectMapper,
                           MeterRegistry meterRegistry,
                           @Value("${truereport.delivery.max-attempts:3}") int maxAttempts,
                           @Value("${truereport.delivery.retry-base-seconds:30}") int retryBaseSeconds,
                           @Value("${truereport.delivery.rate-limit-per-hour:10}") int rateLimitPerHour,
                           @Value("${truereport.delivery.email-max-attachment-bytes:10485760}")
                           long emailMaxAttachmentBytes,
                           @Value("${truereport.report.public-base-url:http://localhost:8080}")
                           String publicBaseUrl) {
        this.requests = requests;
        this.attempts = attempts;
        this.providers = providers;
        this.recipientPolicy = recipientPolicy;
        this.jobs = jobs;
        this.languages = languages;
        this.tokens = tokens;
        this.pdfRenderer = pdfRenderer;
        this.auditService = auditService;
        this.objectMapper = objectMapper;
        this.meterRegistry = meterRegistry;
        this.maxAttempts = maxAttempts;
        this.retryBaseSeconds = retryBaseSeconds;
        this.rateLimitPerHour = rateLimitPerHour;
        this.emailMaxAttachmentBytes = emailMaxAttachmentBytes;
        this.publicBaseUrl = publicBaseUrl.endsWith("/")
                ? publicBaseUrl.substring(0, publicBaseUrl.length() - 1) : publicBaseUrl;
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
        String language = normalizeLanguage(body.language());
        if (language.isEmpty() || !isLiveLanguage(language)) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "LANGUAGE_INVALID",
                    "error.delivery.language", "Unsupported report language");
        }
        JobRow job = jobs.findJob(caller.workshopId().toString(), jobId.toString())
                .orElseThrow(ApiException::notFound);
        if (!"PUBLISHED".equals(job.status())) {
            throw new ApiException(HttpStatus.CONFLICT, "REPORT_NOT_READY",
                    "error.report.notReady", "The report is not ready");
        }
        ReportVersionRow version = jobs.latestReportVersion(job.id())
                .orElseThrow(() -> new ApiException(HttpStatus.CONFLICT, "REPORT_NOT_READY",
                        "error.report.notReady", "The report is not ready"));
        LinkRow link = jobs.activeLink(job.id())
                .orElseThrow(() -> new ApiException(HttpStatus.CONFLICT, "REPORT_NOT_READY",
                        "error.report.notReady", "The public report link is not active"));
        if (!job.consentGranted()) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "CONSENT_REQUIRED",
                    "error.delivery.consent", "Delivery consent is required");
        }
        String recipient = channel.equals("EMAIL") ? job.customerEmail() : job.customerPhone();
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
        byte[] requestHash = hash(job.id() + "|" + channel + "|" + language);
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
        DeliveryRequestEntity request = new DeliveryRequestEntity(
                caller.workshopId(), job.id(), version.id(), channel,
                recipientPolicy.masked(channel, recipient), recipientPolicy.hash(recipient),
                language, requestHash, idempotencyHash, "PUBLIC_LINK",
                caller.userId(), maxAttempts);
        request.setPublicShareLinkId(link.id());
        requests.save(request);
        audit(caller, request, "DELIVERY_REQUESTED", null);
        return dto(request);
    }

    @Transactional(readOnly = true)
    public List<DeliveryDto> forAdmin(CurrentUser caller, UUID jobId) {
        requireAdmin(caller);
        jobs.findJob(caller.workshopId().toString(), jobId.toString())
                .orElseThrow(ApiException::notFound);
        return requests.findByWorkshopIdAndJobIdOrderByCreatedAtDesc(
                        caller.workshopId(), jobId.toString()).stream().map(this::dto).toList();
    }

    @Transactional(readOnly = true)
    public List<DeliveryDto> forTechnician(CurrentUser caller, UUID jobId) {
        if (!caller.isTechnician() || caller.workshopId() == null) {
            throw ApiException.notFound();
        }
        JobRow job = jobs.findJob(caller.workshopId().toString(), jobId.toString())
                .orElseThrow(ApiException::notFound);
        String callerId = caller.userId().toString();
        if (!callerId.equals(job.assignedTechnicianId()) && !callerId.equals(job.createdBy())) {
            throw new ApiException(HttpStatus.CONFLICT, "JOB_REASSIGNED",
                    "error.job.reassigned", "The job was reassigned");
        }
        return requests.findByWorkshopIdAndJobIdOrderByCreatedAtDesc(
                        caller.workshopId(), jobId.toString()).stream().map(this::dto).toList();
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
        jobs.findJob(caller.workshopId().toString(), jobId.toString())
                .orElseThrow(ApiException::notFound);
        DeliveryRequestEntity request = requests.findById(requestId)
                .filter(value -> value.getWorkshopId().equals(caller.workshopId())
                        && value.getJobId().equals(jobId.toString()))
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
        JobRow job = jobs.findJob(request.getWorkshopId().toString(), request.getJobId())
                .orElse(null);
        ReportVersionRow version = jobs.findReportVersion(request.getReportVersionId())
                .orElse(null);
        LinkRow link = request.getPublicShareLinkId() == null ? null
                : jobs.findLink(request.getPublicShareLinkId()).orElse(null);
        if (job == null || version == null || link == null || !"ACTIVE".equals(link.status())) {
            fail(request, null, "REPORT_NOT_FOUND", "Report source is missing");
            return;
        }
        String recipient = request.getChannel().equals("EMAIL")
                ? job.customerEmail() : job.customerPhone();
        if (recipient == null || recipient.isBlank()) {
            fail(request, null, "RECIPIENT_MISSING", "The recorded customer recipient is missing");
            return;
        }
        if (!recipientPolicy.allowed(request.getChannel(), recipient)) {
            fail(request, null, "RECIPIENT_NOT_ALLOWED", "Recipient is no longer allowed");
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
            DeliveryProvider.DeliveryMessage message = buildMessage(request, job, version, link);
            DeliveryProvider.DeliveryResult result = provider.send(message);
            if (!result.accepted()) {
                fail(request, attempt, result.errorCode(), result.errorMessage());
                return;
            }
            attempt.sent(result.providerMessageId());
            request.markSent(link.id(), message.pdf() != null);
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
                                                          JobRow job,
                                                          ReportVersionRow version,
                                                          LinkRow link) {
        String language = request.getLanguage();
        String reportNumber = job.reference();
        String recipient = request.getChannel().equals("EMAIL")
                ? job.customerEmail() : job.customerPhone();
        if (request.getChannel().equals("EMAIL")) {
            // A render failure or an oversized file must never block delivery:
            // the email falls back to the public link.
            byte[] pdf = pdfRenderer.render(link).orElse(null);
            boolean attach = pdf != null && pdf.length > 0 && pdf.length <= emailMaxAttachmentBytes;
            DeliveryMessages.Message message = attach
                    ? DeliveryMessages.forEmail(language, reportNumber)
                    : DeliveryMessages.forLink(language, reportNumber, publicUrl(link));
            return new DeliveryProvider.DeliveryMessage("EMAIL", recipient, language,
                    message.subject(), message.body(), reportNumber,
                    attach ? pdf : null, attach ? "inspection-report.pdf" : null);
        }
        DeliveryMessages.Message message = DeliveryMessages.forLink(
                language, reportNumber, publicUrl(link));
        return new DeliveryProvider.DeliveryMessage(request.getChannel(), recipient, language,
                message.subject(), message.body(), reportNumber, null, null);
    }

    private String publicUrl(LinkRow link) {
        String token = tokens.decrypt(link.tokenEncrypted());
        if (token == null || token.isBlank()) {
            throw new IllegalStateException("PUBLIC_LINK_TOKEN_UNAVAILABLE");
        }
        return publicBaseUrl + "/r/" + token;
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
            linkState = jobs.findLink(request.getPublicShareLinkId())
                    .map(LinkRow::status).orElse("MISSING");
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

    private String normalizeLanguage(String value) {
        return value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
    }

    /**
     * Delivery accepts every language the Platform Admin registry has published
     * as LIVE. A live code without a delivery bundle is valid: the resource
     * bundle falls back to English per key.
     */
    private boolean isLiveLanguage(String code) {
        LanguageDto language = languages.find(code).orElse(null);
        return language != null && language.active() && "LIVE".equals(language.status());
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
}
