package com.truereport.inspections.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ConsentRequest(
        @NotBlank String consentType,
        @NotBlank String status,
        @NotBlank @Size(max = 40) String wordingVersion,
        @NotBlank @Size(max = 40) String channel,
        @Size(max = 255) String evidenceRef
) {
}
