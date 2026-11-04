package com.truereport.delivery.api;

import jakarta.validation.constraints.NotBlank;

public record DeliveryWebhookRequest(
        @NotBlank String eventId,
        @NotBlank String providerMessageId,
        @NotBlank String status,
        String errorCode,
        String errorMessage
) {
}
