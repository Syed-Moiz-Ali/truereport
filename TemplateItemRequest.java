package com.truereport.templates.api;

import jakarta.validation.constraints.NotNull;

import java.util.Map;
import java.util.UUID;

public record TemplateItemRequest(
        @NotNull UUID masterItemVersionId,
        Integer sortOrder,
        String noteRequirement,
        String evidenceRequirement,
        Integer minPhotos,
        Map<String, Object> overrides
) {
}
