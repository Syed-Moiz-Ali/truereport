package com.truereport.templates.api;

import java.util.List;
import java.util.UUID;

public record TemplateDetailDto(
        UUID id,
        String name,
        String description,
        String serviceType,
        String vehicleType,
        String status,
        UUID currentPublishedVersionId,
        List<TemplateVersionSummaryDto> versions,
        TemplateVersionViewDto draft
) {
}
