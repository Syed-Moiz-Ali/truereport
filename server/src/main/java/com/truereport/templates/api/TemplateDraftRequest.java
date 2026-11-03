package com.truereport.templates.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.List;

public record TemplateDraftRequest(
        @NotBlank @Size(max = 200) String name,
        @Size(max = 1000) String description,
        @NotBlank @Size(max = 60) String serviceType,
        @Size(max = 60) String vehicleType,
        List<@Valid TemplateItemRequest> items
) {
}
