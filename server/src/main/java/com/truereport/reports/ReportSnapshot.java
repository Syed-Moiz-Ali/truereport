package com.truereport.reports;

import java.util.List;

public record ReportSnapshot(
        String reportNumber,
        int reportVersion,
        String finalizedAt,
        String publishedAt,
        Vehicle vehicle,
        Inspection inspection,
        Workshop workshop,
        Technician technician,
        String customerName,
        Coverage coverage,
        Summary summary,
        Integer score,
        String gradeCode,
        boolean safetyCapApplied,
        String safetyCapReason,
        List<ItemSnapshot> keyFindings,
        List<Category> categories,
        List<NotChecked> notChecked,
        List<String> limitations,
        String disclaimer,
        String verificationHash
) {

    public record Vehicle(
            String make,
            String model,
            Integer year,
            String vinMasked,
            Integer odometerValue,
            String odometerUnit,
            String vehicleType,
            String transmission,
            String fuelType
    ) {
    }

    public record Inspection(
            String scope,
            Integer templateVersionNo,
            String dateTime
    ) {
    }

    public record Workshop(String name, String branch) {
    }

    public record Technician(String displayName) {
    }

    public record Coverage(
            int total,
            int applicable,
            int completed,
            int notApplicable,
            int notChecked,
            int couldNotVerify
    ) {
    }

    /**
     * Headline figures computed by the server from the stored snapshot/score.
     * The client never derives these from the detail arrays.
     */
    public record Summary(
            int findingsCount,
            int safetyCriticalCount,
            int passedCount,
            double coveragePercent
    ) {
    }

    public record Measurement(
            String fieldCode,
            String valueIndex,
            java.math.BigDecimal numericValue,
            String unitCode,
            String resultCode,
            Integer score
    ) {
    }

    public record ItemSnapshot(
            String stableCode,
            String labelEn,
            String labelAr,
            String instructionEn,
            String instructionAr,
            String resultCode,
            String severityCode,
            String note,
            String noteLanguage,
            String reasonCode,
            String reasonText,
            List<String> evidenceIds,
            List<Measurement> measurements
    ) {
        public ItemSnapshot {
            evidenceIds = evidenceIds == null ? List.of() : evidenceIds;
            measurements = measurements == null ? List.of() : measurements;
        }
    }

    public record Category(String labelEn, String labelAr, List<ItemSnapshot> items) {
        public Category {
            items = items == null ? List.of() : items;
        }
    }

    public record NotChecked(String labelEn, String labelAr, String resultCode, String reason) {
    }
}
