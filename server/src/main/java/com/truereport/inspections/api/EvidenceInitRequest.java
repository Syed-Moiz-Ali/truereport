package com.truereport.inspections.api;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record EvidenceInitRequest(
        @NotNull UUID evidenceId,
        @NotBlank String mime,
        @Min(1) long bytes,
        @NotBlank String sha256,
        String capturedAt
) {
}
