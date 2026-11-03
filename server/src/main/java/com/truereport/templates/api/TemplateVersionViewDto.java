package com.truereport.templates.api;

import java.util.List;
import java.util.UUID;

public record TemplateVersionViewDto(
        UUID id,
        int versionNo,
        String status,
        String publishedAt,
        List<TemplateItemViewDto> items
) {
}
