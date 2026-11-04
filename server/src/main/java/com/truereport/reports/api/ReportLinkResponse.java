package com.truereport.reports.api;

public record ReportLinkResponse(
        String state,
        String publicUrl,
        boolean pdfDownloadEnabled
) {
}
