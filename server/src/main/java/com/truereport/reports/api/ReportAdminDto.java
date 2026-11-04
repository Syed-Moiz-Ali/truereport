package com.truereport.reports.api;

import java.util.UUID;

public record ReportAdminDto(
        UUID reportId,
        UUID jobId,
        String reportNumber,
        int version,
        String generationStatus,
        String generationError,
        int attempts,
        boolean reportReady,
        boolean pdfReady,
        boolean pdfDownloadEnabled,
        String linkState,
        String consentState,
        String publicUrl,
        String finalizedAt,
        String snapshotHash,
        long activeLinkCount,
        com.truereport.reports.ReportSnapshot content
) {
}
