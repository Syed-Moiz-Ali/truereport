package com.truereport.inspections.api;

import java.util.UUID;

public record EvidenceInitResponse(
        UUID evidenceId,
        String status,
        String uploadUrl,
        String uploadToken,
        String expiresAt
) {
}
