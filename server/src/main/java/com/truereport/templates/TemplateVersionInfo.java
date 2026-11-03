package com.truereport.templates;

import java.util.UUID;

public record TemplateVersionInfo(
        UUID versionId,
        UUID templateId,
        String templateName,
        int versionNo,
        String serviceType,
        String vehicleType
) {
}
