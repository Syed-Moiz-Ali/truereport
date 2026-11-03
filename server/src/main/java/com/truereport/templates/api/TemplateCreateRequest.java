package com.truereport.templates.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record TemplateCreateRequest(
        @NotBlank @Size(max = 200) String name,
        @Size(max = 1000) String description,
        @NotBlank @Size(max = 60) String serviceType,
        @Size(max = 60) String vehicleType
) {
}
