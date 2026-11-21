package com.truereport.reports;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.util.List;

/**
 * Stored snapshot contract. Unknown fields are ignored so a published snapshot written by a
 * newer server still renders after a rollback (the format only ever grows).
 */
@JsonIgnoreProperties(ignoreUnknown = true)
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
        String verificationHash,
        String language
) {

    @JsonIgnoreProperties(ignoreUnknown = true)
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

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Inspection(
            String scope,
            Integer templateVersionNo,
            String dateTime
    ) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Workshop(String name, String branch) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Technician(String displayName) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
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
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Summary(
            int findingsCount,
            int safetyCriticalCount,
            int passedCount,
            double coveragePercent
    ) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Measurement(
            String fieldCode,
            String valueIndex,
            java.math.BigDecimal numericValue,
            String unitCode,
            String resultCode,
            Integer score
    ) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record ItemSnapshot(
            String stableCode,
            String labelEn,
            String labelAr,
            String instructionEn,
            String instructionAr,
            String label,
            String instruction,
            String standardSpec,
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

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Category(String labelEn, String labelAr, String label, List<ItemSnapshot> items) {
        public Category {
            items = items == null ? List.of() : items;
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record NotChecked(String labelEn, String labelAr, String resultCode, String reason) {
    }
}
