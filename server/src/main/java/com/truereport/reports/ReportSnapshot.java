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
        Coverage coverage,
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
            String vehicleType
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
            List<String> evidenceIds
    ) {
    }

    public record Category(String labelEn, String labelAr, List<ItemSnapshot> items) {
    }

    public record NotChecked(String labelEn, String labelAr, String resultCode, String reason) {
    }
}
