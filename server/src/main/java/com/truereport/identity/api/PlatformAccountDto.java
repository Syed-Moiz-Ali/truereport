package com.truereport.identity.api;

import java.util.UUID;

public record PlatformAccountDto(
        UUID userId,
        String displayName,
        String emailMasked,
        String role,
        String status,
        UUID workshopId,
        boolean primary
) {
}
