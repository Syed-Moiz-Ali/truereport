package com.truereport.inspections.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CustomerUpdateRequest(
        @NotBlank @Size(max = 200) String customerName,
        @Size(max = 40) String customerPhone,
        @Size(max = 320) String customerEmail
) {
}
