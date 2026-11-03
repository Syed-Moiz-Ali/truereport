package com.truereport.templates.api;

import java.util.UUID;

public record TemplateSummaryDto(
        UUID id,
        String name,
        String serviceType,
        String vehicleType,
        String status,
        Integer currentVersion,
        long itemCount,
        String updatedAt
) {
}
