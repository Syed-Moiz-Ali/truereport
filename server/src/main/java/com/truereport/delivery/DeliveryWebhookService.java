package com.truereport.delivery;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.audit.AuditService;
import com.truereport.delivery.api.DeliveryWebhookRequest;
import com.truereport.shared.error.ApiException;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;

@Service
public class DeliveryWebhookService {

    private final DeliveryWebhookEventRepository events;
    private final DeliveryAttemptRepository attempts;
    private final DeliveryRequestRepository requests;
    private final AuditService auditService;
    private final ObjectMapper objectMapper;
    private final String secret;
    private final MeterRegistry meterRegistry;

    public DeliveryWebhookService(DeliveryWebhookEventRepository events,
                                  DeliveryAttemptRepository attempts,
                                  DeliveryRequestRepository requests,
                                  AuditService auditService,
                                  ObjectMapper objectMapper,
                                  MeterRegistry meterRegistry,
                                  @Value("${truereport.delivery.webhook-secret:change-me-local-only}")
                                  String secret) {
        this.events = events;
        this.attempts = attempts;
        this.requests = requests;
        this.auditService = auditService;
        this.objectMapper = objectMapper;
        this.meterRegistry = meterRegistry;
        this.secret = secret;
    }

    @Transactional
    public void handle(String provider, String payload, String signature) {
        if (!validSignature(payload, signature)) {
            meterRegistry.counter("truereport.delivery.webhook", "status", "invalid").increment();
            throw new ApiException(HttpStatus.UNAUTHORIZED, "WEBHOOK_SIGNATURE_INVALID",
                    "error.webhook.signature", "Webhook signature is invalid");
        }
        DeliveryWebhookRequest body;
        try {
            body = objectMapper.readValue(payload, DeliveryWebhookRequest.class);
        } catch (Exception exception) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "WEBHOOK_INVALID",
                    "error.webhook.invalid", "Webhook payload is invalid");
        }
        if (events.findByProviderAndEventId(provider, body.eventId()).isPresent()) {
            return;
        }
        DeliveryAttempt attempt = attempts.findByProviderMessageId(body.providerMessageId())
                .orElseThrow(ApiException::notFound);
        DeliveryRequestEntity request = requests.findById(attempt.getDeliveryRequestId())
                .orElseThrow(ApiException::notFound);
        if (body.status().equals("DELIVERED")) {
            attempt.delivered();
            request.markDelivered();
        } else if (body.status().equals("FAILED")) {
            attempt.failed(body.errorCode(), body.errorMessage());
            request.markFailed();
        } else {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "WEBHOOK_STATUS_INVALID",
                    "error.webhook.status", "Webhook status is invalid");
        }
        attempts.save(attempt);
        requests.save(request);
        events.save(new DeliveryWebhookEvent(provider, body.eventId(),
                hash(payload), request.getId(), body.status()));
        meterRegistry.counter("truereport.delivery.webhook", "status", body.status()).increment();
        auditService.record(request.getWorkshopId(), null, "PROVIDER",
                "DELIVERY_WEBHOOK_" + body.status(), "DELIVERY", request.getId(),
                body.errorCode(), null);
    }

    private boolean validSignature(String payload, String signature) {
        if (signature == null || signature.isBlank()) {
            return false;
        }
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            String expected = "sha256=" + HexFormat.of().formatHex(
                    mac.doFinal(payload.getBytes(StandardCharsets.UTF_8)));
            return MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8),
                    signature.trim().getBytes(StandardCharsets.UTF_8));
        } catch (Exception exception) {
            return false;
        }
    }

    private byte[] hash(String value) {
        try {
            return MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8));
        } catch (Exception exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }
}
