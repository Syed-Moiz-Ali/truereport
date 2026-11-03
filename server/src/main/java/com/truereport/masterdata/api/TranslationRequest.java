package com.truereport.masterdata.api;

import jakarta.validation.constraints.NotBlank;

public record TranslationRequest(
        @NotBlank String label,
        @NotBlank String instruction
) {
}
