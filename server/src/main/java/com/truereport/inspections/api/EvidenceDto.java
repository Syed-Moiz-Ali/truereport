package com.truereport.inspections.api;

import java.util.UUID;

public record EvidenceDto(
        UUID id,
        UUID inspectionItemId,
        String mime,
        long bytes,
        String capturedAt,
        String status,
        String sha256,
        String contentUrl
) {
}
