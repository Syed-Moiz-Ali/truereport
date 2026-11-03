package com.truereport.inspections.api;

import java.util.List;
import java.util.UUID;

public record AssessmentDto(
        UUID id,
        String resultCode,
        String severityCode,
        String note,
        String noteLanguage,
        String reasonCode,
        String reasonText,
        long clientRevision,
        long serverRevision,
        int version
) {
}
