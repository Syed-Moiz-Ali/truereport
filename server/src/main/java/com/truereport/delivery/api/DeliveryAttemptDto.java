package com.truereport.delivery.api;

import java.util.UUID;

public record DeliveryAttemptDto(
        UUID id,
        int attemptNo,
        String provider,
        String status,
        String providerMessageId,
        String errorCode,
        String errorMessage,
        String sentAt,
        String deliveredAt
) {
}
