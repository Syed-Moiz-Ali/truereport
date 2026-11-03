package com.truereport.identity.api;

import java.util.UUID;

public record AuditEventDto(
        UUID id,
        UUID workshopId,
        UUID actorUserId,
        String actorRole,
        String action,
        String entityType,
        UUID entityId,
        String occurredAt,
        String reasonCode,
        String metadataJson
) {
}
