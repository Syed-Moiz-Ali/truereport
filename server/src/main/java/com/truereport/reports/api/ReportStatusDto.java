package com.truereport.reports.api;

public record ReportStatusDto(
        String reportNumber,
        int version,
        String generationStatus,
        boolean ready,
        String finalizedAt
) {
}
