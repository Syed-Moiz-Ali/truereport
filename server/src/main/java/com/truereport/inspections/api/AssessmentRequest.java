package com.truereport.inspections.api;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

public record AssessmentRequest(
        @Min(0) int baseVersion,
        @Min(1) long clientRevision,
        @NotBlank String resultCode,
        String severityCode,
        String note,
        String noteLanguage,
        String reasonCode,
        String reasonText
) {
}
