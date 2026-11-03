package com.truereport.identity.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AccountActionRequest(
        @NotBlank @Size(max = 255) String reason
) {
}
