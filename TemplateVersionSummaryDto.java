package com.truereport.templates.api;

import java.util.UUID;

public record TemplateVersionSummaryDto(
        UUID id,
        int versionNo,
        String status,
        String publishedAt,
        long itemCount
) {
}
