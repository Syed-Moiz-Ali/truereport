package com.truereport.templates.api;

import java.util.UUID;

public record TemplateVersionOptionDto(
        UUID versionId,
        UUID templateId,
        String templateName,
        int versionNo,
        String serviceType,
        String vehicleType
) {
}
