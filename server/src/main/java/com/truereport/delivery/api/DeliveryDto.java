package com.truereport.delivery.api;

import java.util.List;
import java.util.UUID;

public record DeliveryDto(
        UUID id,
        String channel,
        String recipientMasked,
        String language,
        String status,
        int attempts,
        int maxAttempts,
        boolean pdfAttached,
        String linkState,
        String lastErrorCode,
        String lastErrorMessage,
        String nextAttemptAt,
        String createdAt,
        String updatedAt,
        List<DeliveryAttemptDto> attemptHistory
) {
}
