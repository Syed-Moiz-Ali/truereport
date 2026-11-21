package com.truereport.reports;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Phase 5 report proof: three outcome profiles, no empty rendered fields, and
 * HTML/PDF parity at the rendered view-model level (the data both templates
 * receive).
 */
class ReportProfileParityTest {

    private static final Pattern TEMPLATE_ROOT =
            Pattern.compile("\\br\\.([A-Za-z_][A-Za-z0-9_]*)");
    private static final Set<String> LAYOUT_ONLY_PATHS = Set.of(
            "lang", "dir", "isRtl", "pdfDownloadEnabled", "fontCss",
            "heroPhotoUrl", "heroPhotoDataUri");
    private static final Set<String> PUBLIC_LAYOUT_ONLY_ROOTS = Set.of(
            "categoriesSummary", "inspectionVideos", "showcaseExterior",
            "showcaseInterior", "showcaseMechanical", "labels",
            "pdfDownloadEnabled", "disclaimer", "heroPhotoUrl");
    private static final Set<String> PRINT_LAYOUT_ONLY_ROOTS = Set.of(
            "en", "finalizedAt", "fontCss", "limitationsEn", "disclaimerEn",
            "heroPhotoDataUri");

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final ReportSnapshotBuilder snapshotBuilder = new ReportSnapshotBuilder(objectMapper);
    private final ReportViewMapper viewMapper = new ReportViewMapper(objectMapper);

    enum Profile {
        PASS, ATTENTION, SAFETY_CRITICAL
    }

    @Test
    void allPassProfileHasCorrectSummaryAndNoEmptyRenderedFields() throws Exception {
        assertProfile(Profile.PASS, 0, 3, 0, 92, "B", false);
    }

    @Test
    void attentionProfileHasCorrectSummaryAndNoEmptyRenderedFields() throws Exception {
        assertProfile(Profile.ATTENTION, 1, 2, 0, 78, "C", false);
    }

    @Test
    void safetyCriticalProfileSetsSummaryAndSafetyCapReason() throws Exception {
        Built built = assertProfile(Profile.SAFETY_CRITICAL, 1, 2, 1, 68, "D", true);
        assertThat(built.snapshot().safetyCapApplied()).isTrue();
        assertThat(built.snapshot().safetyCapReason())
                .contains("Safety-critical item failed", "BRK-PAD-01");
        assertThat(built.publicPage().get("safetyCapReason"))
                .isEqualTo(built.snapshot().safetyCapReason());
        assertThat(built.printPage().get("safetyCapReason"))
                .isEqualTo(built.snapshot().safetyCapReason());
    }

    @Test
    void publicAndPrintViewModelsExposeTheSameReportFields() throws Exception {
        for (Profile profile : Profile.values()) {
            Built built = build(profile);
            assertThat(normalizedFields(built.publicPage()))
                    .as("HTML/PDF field parity for %s", profile)
                    .isEqualTo(normalizedFields(built.printPage()));
        }
    }

    @Test
    void everyTemplateFieldIsServedByTheViewModel() throws Exception {
        Built built = build(Profile.SAFETY_CRITICAL);
        assertTemplateFieldsServed("public-report.html", built.publicPage(), Set.of());
        assertTemplateFieldsServed("print-report.html", built.printPage(), Set.of("fontCss"));
    }

    @Test
    void templatesOnlyDivergeOnDocumentedLayoutFields() throws Exception {
        Set<String> publicRoots = templateRoots("public-report.html");
        Set<String> printRoots = templateRoots("print-report.html");
        Set<String> publicOnly = new TreeSet<>(publicRoots);
        publicOnly.removeAll(printRoots);
        Set<String> printOnly = new TreeSet<>(printRoots);
        printOnly.removeAll(publicRoots);

        assertThat(publicOnly)
                .as("public template fields absent from print (must be documented layout-only)")
                .containsExactlyInAnyOrderElementsOf(PUBLIC_LAYOUT_ONLY_ROOTS);
        assertThat(printOnly)
                .as("print template fields absent from public (must be documented layout-only)")
                .containsExactlyInAnyOrderElementsOf(PRINT_LAYOUT_ONLY_ROOTS);
        Set<String> coreRoots = Set.of("vehicle", "inspection", "workshop", "technician",
                "coverage", "categories", "keyFindings", "notChecked", "reportNumber",
                "version", "verificationHash", "passedCount", "attentionCount",
                "defectCount", "passRate", "totalEvaluated", "tyreAssemblies",
                "damageZones", "vehicleShowcase");
        assertThat(publicRoots).containsAll(coreRoots);
        assertThat(printRoots).containsAll(coreRoots);
    }

    private Built assertProfile(Profile profile, int findings, int passed, int safetyCritical,
                                int score, String grade, boolean capApplied) throws Exception {
        Built built = build(profile);
        ReportSnapshot snapshot = built.snapshot();

        assertThat(snapshot.summary()).isNotNull();
        assertThat(snapshot.summary().findingsCount()).isEqualTo(findings);
        assertThat(snapshot.summary().safetyCriticalCount()).isEqualTo(safetyCritical);
        assertThat(snapshot.summary().passedCount()).isEqualTo(passed);
        assertThat(snapshot.summary().coveragePercent()).isEqualTo(100.0);
        assertThat(snapshot.score()).isEqualTo(score);
        assertThat(snapshot.gradeCode()).isEqualTo(grade);
        assertThat(snapshot.safetyCapApplied()).isEqualTo(capApplied);

        int expectedAttention = findings - safetyCritical;
        int expectedDefect = safetyCritical;
        assertThat(built.publicPage().get("passedCount")).isEqualTo(passed);
        assertThat(built.publicPage().get("attentionCount")).isEqualTo(expectedAttention);
        assertThat(built.publicPage().get("defectCount")).isEqualTo(expectedDefect);
        assertThat(built.printPage().get("passedCount")).isEqualTo(passed);

        assertThat(snapshot.customerName()).isEqualTo("E2E C***");
        assertThat(vehicle(built.publicPage()).get("clientName"))
                .as("public clientName for %s", profile).isEqualTo("E2E C***");
        assertThat(vehicle(built.printPage()).get("clientName"))
                .as("print clientName for %s", profile).isEqualTo("E2E C***");

        ReportTestAssertions.assertNoEmptyRenderedValues(built.publicPage());
        ReportTestAssertions.assertNoEmptyRenderedValues(built.printPage());
        return built;
    }

    private Built build(Profile profile) throws Exception {
        String finalSnapshotJson = objectMapper.writeValueAsString(finalSnapshot(profile));
        ReportSnapshot snapshot = snapshotBuilder.build(
                objectMapper.readTree(finalSnapshotJson), "hash-" + profile.name());
        String snapshotJson = objectMapper.writeValueAsString(snapshot);
        ReportVersion version = new ReportVersion(
                UUID.randomUUID(), UUID.randomUUID(), 1, snapshot.reportNumber(),
                new byte[32], snapshotJson, new byte[32],
                LocalDateTime.parse("2026-11-20T10:00:00"));
        Map<String, Object> publicPage = viewMapper.publicPage(
                version, List.of(), "en", false);
        Map<String, Object> printPage = viewMapper.printPage(version, List.of());
        return new Built(snapshot, version, publicPage, printPage);
    }

    private Map<String, Object> finalSnapshot(Profile profile) {
        Map<String, Object> root = new LinkedHashMap<>();
        root.put("reference", "JOB-PROFILE-" + profile.name());
        root.put("finalizedAt", "2026-11-20T10:00:00");
        root.put("publishedAt", "2026-11-20T10:00:00");
        root.put("customerName", "E2E Customer");
        root.put("customerPhone", "+971500000001");
        root.put("customerEmail", "e2e.customer@example.test");
        root.put("vehicleMake", "Toyota");
        root.put("vehicleModel", "Land Cruiser");
        root.put("vehicleYear", 2023);
        root.put("vehicleVin", "JTDBR32E720123456");
        root.put("vehiclePlate", "DXB-1001");
        root.put("odometerValue", 42850);
        root.put("odometerUnit", "KM");
        root.put("scope", "Comprehensive 30-Point GCC Standard");
        root.put("vehicleType", "SUV");
        root.put("transmission", "AUTOMATIC");
        root.put("fuelType", "PETROL");
        root.put("templateVersionNo", 1);
        root.put("workshopName", "Workshop A");
        root.put("workshopBranch", "Al Quoz");
        root.put("technicianName", "Technician A");
        root.put("score", score(profile));
        root.put("gradeCode", grade(profile));
        root.put("safetyCapApplied", profile == Profile.SAFETY_CRITICAL);
        root.put("safetyCapReason", profile == Profile.SAFETY_CRITICAL
                ? "Safety-critical item failed: BRK-PAD-01" : "");

        String brakeResult = switch (profile) {
            case PASS -> "NO_ISSUE_OBSERVED";
            case ATTENTION -> "ATTENTION_RECOMMENDED";
            case SAFETY_CRITICAL -> "DEFECT_FOUND";
        };
        String brakeSeverity = switch (profile) {
            case PASS -> null;
            case ATTENTION -> "MODERATE";
            case SAFETY_CRITICAL -> "SAFETY_CRITICAL";
        };
        String brakeNote = profile == Profile.PASS ? "" : "Brake pads below service limit";
        String brakeReason = profile == Profile.PASS ? "" : "Wear beyond the safe threshold";
        root.put("items", List.of(
                item("BRK-PAD-01", "Brakes & Safety", "Front Brake Pads",
                        true, brakeResult, brakeSeverity, brakeNote, brakeReason, List.of()),
                item("ENG-OIL-01", "Powertrain & Mechanical", "Engine Oil Condition",
                        false, "NO_ISSUE_OBSERVED", null, "", "", List.of()),
                item("TYRE-FL-01", "Tyres & Brakes", "Tyre Tread Depth",
                        false, "NO_ISSUE_OBSERVED", null, "", "", List.of(
                                measurement("treadDepth", "FL", "6.4", "MM", 100),
                                measurement("treadDepth", "FR", "6.2", "MM", 100),
                                measurement("treadDepth", "RL", "6.8", "MM", 100),
                                measurement("treadDepth", "RR", "6.6", "MM", 100)))));
        return root;
    }

    private Map<String, Object> item(String code, String category, String label,
                                     boolean safetyCritical, String result, String severity,
                                     String note, String reason,
                                     List<Map<String, Object>> measurements) {
        Map<String, Object> rules = new LinkedHashMap<>();
        rules.put("stableCode", code);
        rules.put("categoryLabelEn", category);
        rules.put("categoryLabelAr", category + " AR");
        rules.put("labelEn", label);
        rules.put("labelAr", label + " AR");
        rules.put("instructionEn", "Inspect " + label + " and record the condition with evidence.");
        rules.put("instructionAr", "Inspect " + label + " AR");
        rules.put("safetyCritical", safetyCritical);

        Map<String, Object> assessment = new LinkedHashMap<>();
        assessment.put("resultCode", result);
        assessment.put("severityCode", severity);
        assessment.put("note", note);
        assessment.put("noteLanguage", "en");
        assessment.put("reasonCode", reason.isBlank() ? "" : "WEAR");
        assessment.put("reasonText", reason);
        assessment.put("measurements", measurements);

        Map<String, Object> entry = new LinkedHashMap<>();
        entry.put("item", rules);
        entry.put("assessment", assessment);
        entry.put("evidence", List.of());
        return entry;
    }

    private Map<String, Object> measurement(String field, String index, String value,
                                             String unit, int score) {
        Map<String, Object> measurement = new LinkedHashMap<>();
        measurement.put("fieldCode", field);
        measurement.put("valueIndex", index);
        measurement.put("numericValue", new BigDecimal(value));
        measurement.put("unitCode", unit);
        measurement.put("resultCode", "NO_ISSUE_OBSERVED");
        measurement.put("score", score);
        return measurement;
    }

    private int score(Profile profile) {
        return switch (profile) {
            case PASS -> 92;
            case ATTENTION -> 78;
            case SAFETY_CRITICAL -> 68;
        };
    }

    private String grade(Profile profile) {
        return switch (profile) {
            case PASS -> "B";
            case ATTENTION -> "C";
            case SAFETY_CRITICAL -> "D";
        };
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> vehicle(Map<String, Object> page) {
        return (Map<String, Object>) page.get("vehicle");
    }

    private static Set<String> normalizedFields(Map<String, Object> page) {
        Set<String> paths = new TreeSet<>();
        collect("", page, paths);
        return paths.stream()
                .map(ReportProfileParityTest::normalize)
                .filter(path -> !LAYOUT_ONLY_PATHS.contains(path))
                .collect(Collectors.toCollection(TreeSet::new));
    }

    private static void collect(String prefix, Object value, Set<String> paths) {
        if (value instanceof Map<?, ?> map) {
            for (Map.Entry<?, ?> entry : map.entrySet()) {
                String key = String.valueOf(entry.getKey());
                String path = prefix.isEmpty() ? key : prefix + "." + key;
                paths.add(path);
                collect(path, entry.getValue(), paths);
            }
        } else if (value instanceof List<?> list) {
            for (int index = 0; index < list.size(); index++) {
                String path = prefix + "[" + index + "]";
                paths.add(path);
                collect(path, list.get(index), paths);
            }
        }
    }

    private static String normalize(String path) {
        if (path.startsWith("labels.")) {
            return "label." + path.substring("labels.".length());
        }
        if (path.startsWith("en.")) {
            return "label." + path.substring("en.".length());
        }
        if ("labels".equals(path) || "en".equals(path)) {
            return "label";
        }
        if ("disclaimerEn".equals(path)) {
            return "disclaimer";
        }
        if (path.startsWith("limitationsEn")) {
            return "limitations" + path.substring("limitationsEn".length());
        }
        return path;
    }

    private void assertTemplateFieldsServed(String template, Map<String, Object> viewModel,
                                            Set<String> extraKeys) throws Exception {
        Path path = Path.of("src/main/resources/templates/report", template);
        String html = Files.readString(path, StandardCharsets.UTF_8);
        Matcher matcher = TEMPLATE_ROOT.matcher(html);
        Set<String> missing = new TreeSet<>();
        while (matcher.find()) {
            String root = matcher.group(1);
            if (!viewModel.containsKey(root) && !extraKeys.contains(root)) {
                missing.add(root);
            }
        }
        assertThat(missing).as("%s references fields the view model does not serve", template)
                .isEmpty();
    }

    private static Set<String> templateRoots(String template) throws Exception {
        Path path = Path.of("src/main/resources/templates/report", template);
        String html = Files.readString(path, StandardCharsets.UTF_8);
        Matcher matcher = TEMPLATE_ROOT.matcher(html);
        Set<String> roots = new TreeSet<>();
        while (matcher.find()) {
            roots.add(matcher.group(1));
        }
        return roots;
    }

    private record Built(ReportSnapshot snapshot, ReportVersion version,
                         Map<String, Object> publicPage, Map<String, Object> printPage) {
    }
}
