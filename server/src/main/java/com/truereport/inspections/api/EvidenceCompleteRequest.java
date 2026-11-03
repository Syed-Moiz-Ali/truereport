package com.truereport.inspections.api;

import jakarta.validation.constraints.NotBlank;

public record EvidenceCompleteRequest(@NotBlank String sha256) {
}
