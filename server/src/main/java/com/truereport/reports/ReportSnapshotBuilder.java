package com.truereport.reports;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class ReportSnapshotBuilder {

    private static final String DISCLAIMER_EN = "This is a visual, non-invasive inspection. Components were not "
            + "dismantled. Hidden or intermittent faults may remain. This report is not a warranty, certificate or "
            + "guarantee, and it reflects the vehicle only at the time and within the scope of the inspection.";
    private static final List<String> LIMITATIONS = List.of(
            "Visual inspection only; components were not dismantled.",
            "Road testing, diagnostics and fluid analysis are limited to the recorded scope.",
            "Hidden, intermittent or future faults may not be visible at the time of inspection.",
            "Coverage is not a condition score and a clean result does not mean the vehicle is perfect."
    );

    private final ObjectMapper objectMapper;

    public ReportSnapshotBuilder(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    public ReportSnapshot build(JsonNode finalSnapshot, String snapshotHash) {
        JsonNode root = finalSnapshot;
        String finalizedAt = text(root, "finalizedAt");
        List<ReportSnapshot.ItemSnapshot> items = new ArrayList<>();
        List<ReportSnapshot.NotChecked> notChecked = new ArrayList<>();
        Map<String, List<ReportSnapshot.ItemSnapshot>> grouped = new LinkedHashMap<>();
        Map<String, String> categoryAr = new LinkedHashMap<>();
        int notApplicable = 0;
        int notCheckedCount = 0;
        int couldNotVerify = 0;
        int completed = 0;

        for (JsonNode entry : root.path("items")) {
            JsonNode rules = entry.path("item");
            JsonNode assessment = entry.path("assessment");
            String result = text(assessment, "resultCode");
            String labelEn = text(rules, "labelEn");
            String labelAr = text(rules, "labelAr");
            if (result.equals("NOT_APPLICABLE")) {
                notApplicable++;
                continue;
            }
            List<String> evidenceIds = new ArrayList<>();
            for (JsonNode evidence : entry.path("evidence")) {
                evidenceIds.add(text(evidence, "evidenceId"));
            }
            ReportSnapshot.ItemSnapshot item = new ReportSnapshot.ItemSnapshot(
                    text(rules, "stableCode"), labelEn, labelAr,
                    text(rules, "instructionEn"), text(rules, "instructionAr"),
                    result, text(assessment, "severityCode"), sanitize(text(assessment, "note"), root),
                    text(assessment, "noteLanguage"), text(assessment, "reasonCode"),
                    sanitize(text(assessment, "reasonText"), root), List.copyOf(evidenceIds));
            items.add(item);
            if (result.equals("NOT_CHECKED")) {
                notCheckedCount++;
            } else if (result.equals("COULD_NOT_VERIFY")) {
                couldNotVerify++;
            } else {
                completed++;
            }
            if (result.equals("NOT_CHECKED") || result.equals("COULD_NOT_VERIFY")) {
                String reason = !item.reasonText().isBlank() ? item.reasonText() : item.reasonCode();
                notChecked.add(new ReportSnapshot.NotChecked(labelEn, labelAr, result, reason));
            }
            String categoryEn = !text(rules, "categoryLabelEn").isBlank()
                    ? text(rules, "categoryLabelEn") : "Other checks";
            String categoryLabelAr = !text(rules, "categoryLabelAr").isBlank()
                    ? text(rules, "categoryLabelAr") : categoryEn;
            grouped.computeIfAbsent(categoryEn, ignored -> new ArrayList<>()).add(item);
            categoryAr.putIfAbsent(categoryEn, categoryLabelAr);
        }

        List<ReportSnapshot.Category> categories = new ArrayList<>();
        for (Map.Entry<String, List<ReportSnapshot.ItemSnapshot>> entry : grouped.entrySet()) {
            categories.add(new ReportSnapshot.Category(entry.getKey(),
                    categoryAr.getOrDefault(entry.getKey(), entry.getKey()), List.copyOf(entry.getValue())));
        }

        List<ReportSnapshot.ItemSnapshot> keyFindings = items.stream()
                .filter(item -> item.resultCode().equals("DEFECT_FOUND")
                        || item.resultCode().equals("ATTENTION_RECOMMENDED"))
                .sorted(Comparator.comparingInt(item -> severityRank(item.severityCode())))
                .toList();

        int total = items.size() + notApplicable;
        int applicable = total - notApplicable;
        ReportSnapshot.Coverage coverage = new ReportSnapshot.Coverage(
                total, applicable, completed, notApplicable, notCheckedCount, couldNotVerify);

        return new ReportSnapshot(
                text(root, "reference").isBlank() ? "REPORT" : text(root, "reference"),
                1,
                finalizedAt,
                finalizedAt,
                new ReportSnapshot.Vehicle(
                        text(root, "vehicleMake"), text(root, "vehicleModel"),
                        root.path("vehicleYear").isNumber() ? root.path("vehicleYear").asInt() : null,
                        maskVin(text(root, "vehicleVin")),
                        root.path("odometerValue").isNumber() ? root.path("odometerValue").asInt() : null,
                        text(root, "odometerUnit"), text(root, "vehicleType")),
                new ReportSnapshot.Inspection(text(root, "scope"),
                        root.path("templateVersionNo").isNumber() ? root.path("templateVersionNo").asInt() : null,
                        finalizedAt),
                new ReportSnapshot.Workshop(text(root, "workshopName"), text(root, "workshopBranch")),
                new ReportSnapshot.Technician(text(root, "technicianName")),
                coverage,
                keyFindings,
                List.copyOf(categories),
                List.copyOf(notChecked),
                LIMITATIONS,
                DISCLAIMER_EN,
                snapshotHash
        );
    }

    private int severityRank(String severity) {
        return switch (severity) {
            case "SAFETY_CRITICAL" -> 0;
            case "MAJOR" -> 1;
            case "MODERATE" -> 2;
            case "MINOR" -> 3;
            default -> 4;
        };
    }

    private String sanitize(String value, JsonNode root) {
        String result = value == null ? "" : value;
        for (String field : List.of("customerName", "customerPhone", "customerEmail",
                "vehicleVin", "vehiclePlate")) {
            String privateValue = text(root, field);
            if (!privateValue.isBlank()) {
                result = result.replace(privateValue, "[redacted]");
            }
        }
        result = result.replaceAll("(?i)\\b[A-HJ-NPR-Z0-9]{17}\\b", "[redacted VIN]");
        result = result.replaceAll("(?i)\\b[\\w.+-]+@[\\w.-]+\\.[A-Za-z]{2,}\\b",
                "[redacted email]");
        return result;
    }

    private String maskVin(String vin) {
        if (vin == null || vin.isBlank()) {
            return "";
        }
        String clean = vin.trim();
        if (clean.length() <= 4) {
            return "****";
        }
        return "****" + clean.substring(clean.length() - 4);
    }

    private String text(JsonNode node, String field) {
        JsonNode value = node.path(field);
        return value.isMissingNode() || value.isNull() ? "" : value.asText("");
    }
}
