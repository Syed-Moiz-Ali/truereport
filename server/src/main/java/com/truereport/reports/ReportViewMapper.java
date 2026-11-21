package com.truereport.reports;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.truereport.shared.text.CustomerNames;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Component
public class ReportViewMapper {

    private final ObjectMapper objectMapper;

    public ReportViewMapper(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    public Map<String, Object> publicPage(ReportVersion version, List<EvidenceDerivative> derivatives,
                                          String language, boolean pdfDownloadEnabled) throws Exception {
        return publicPage(version, derivatives, language, pdfDownloadEnabled, null);
    }

    public Map<String, Object> publicPage(ReportVersion version, List<EvidenceDerivative> derivatives,
                                          String language, boolean pdfDownloadEnabled,
                                          String token) throws Exception {
        return publicPage(version, derivatives, language, pdfDownloadEnabled, token, null);
    }

    public Map<String, Object> publicPage(ReportVersion version, List<EvidenceDerivative> derivatives,
                                          String language, boolean pdfDownloadEnabled,
                                          String token, String customerName) throws Exception {
        return publicPage(version, derivatives, language, pdfDownloadEnabled, token,
                customerName, null);
    }

    /**
     * @param heroPhotoUrl public URL of the pre-inspection vehicle photo, or
     *                     {@code null} to fall back to item evidence in the
     *                     template.
     */
    public Map<String, Object> publicPage(ReportVersion version, List<EvidenceDerivative> derivatives,
                                          String language, boolean pdfDownloadEnabled,
                                          String token, String customerName,
                                          String heroPhotoUrl) throws Exception {
        ReportSnapshot snapshot = objectMapper.readValue(version.getSnapshotJson(), ReportSnapshot.class);
        String snapshotLanguage = snapshot.language();
        if (snapshotLanguage != null && !snapshotLanguage.isBlank()) {
            language = snapshotLanguage;
        }
        Map<UUID, EvidenceDerivative> byEvidence = derivatives.stream()
                .filter(d -> d.getPurpose().equals("PUBLIC_FULL"))
                .collect(Collectors.toMap(EvidenceDerivative::getEvidenceAssetId, Function.identity(),
                        (left, right) -> left, LinkedHashMap::new));
        Map<String, Object> root = new LinkedHashMap<>();
        root.put("lang", language);
        root.put("dir", "ltr");
        root.put("isRtl", false);
        root.put("labels", ReportMessages.labels(language));
        root.put("pdfDownloadEnabled", pdfDownloadEnabled);
        root.put("heroPhotoUrl", heroPhotoUrl);
        root.put("reportNumber", snapshot.reportNumber());
        root.put("displayToken", snapshot.reportNumber());
        root.put("version", snapshot.reportVersion());
        root.put("finalizedAt", formatDate(snapshot.finalizedAt(), language));
        root.put("publishedAt", formatDate(snapshot.publishedAt(), language));
        root.put("verificationHash", snapshot.verificationHash());
        root.put("score", snapshot.score());
        root.put("gradeCode", snapshot.gradeCode());
        root.put("safetyCapApplied", snapshot.safetyCapApplied());
        root.put("safetyCapReason", snapshot.safetyCapReason());
        root.put("vehicle", vehicle(snapshot.vehicle(),
                firstNonBlank(customerName, snapshot.customerName())));
        root.put("inspection", inspection(snapshot.inspection(), language));
        root.put("workshop", workshop(snapshot.workshop()));
        root.put("technician", technician(snapshot.technician()));
        int passedCount = 0;
        int attentionCount = 0;
        int defectCount = 0;
        for (ReportSnapshot.Category cat : snapshot.categories()) {
            for (ReportSnapshot.ItemSnapshot it : cat.items()) {
                if ("NO_ISSUE_OBSERVED".equals(it.resultCode())) passedCount++;
                else if ("ATTENTION_RECOMMENDED".equals(it.resultCode())) attentionCount++;
                else if ("DEFECT_FOUND".equals(it.resultCode())) defectCount++;
            }
        }
        int evaluated = passedCount + attentionCount + defectCount;
        int passRate = evaluated > 0 ? Math.round((float) passedCount * 100f / (float) evaluated) : 100;
        root.put("passedCount", passedCount);
        root.put("attentionCount", attentionCount);
        root.put("defectCount", defectCount);
        root.put("passRate", passRate);
        root.put("totalEvaluated", evaluated);
        root.put("coverage", coverage(snapshot.coverage(), language));
        // The previous demo sections were hardcoded stock photos, tyre/brake
        // values and paint readings unrelated to this job. They stay disabled
        // until they are derived from real assessments/evidence.
        root.put("visualInspections", List.of());
        root.put("inspectionSystems", List.of());
        List<Map<String, Object>> catList = categories(snapshot.categories(), byEvidence, language,
                false, token);
        root.put("categories", catList);
        int goodCats = 0;
        int attentionCats = 0;
        for (Map<String, Object> c : catList) {
            int d = (int) c.get("defectCount");
            int a = (int) c.get("attentionCount");
            if (d > 0 || a > 0) {
                attentionCats++;
                c.put("categoryStatus", "ATTENTION");
                c.put("categoryStatusLabel", ReportMessages.label(language, "categoryStatus.attention"));
            } else {
                goodCats++;
                c.put("categoryStatus", "GOOD");
                c.put("categoryStatusLabel", ReportMessages.label(language, "categoryStatus.good"));
            }
        }
        String bullet = ReportMessages.label(language, "categorySummary.separator");
        String systemsGood = counted(language, goodCats,
                "categorySummary.systemsGood", "categorySummary.systemsGood");
        String systemsAttention = counted(language, attentionCats,
                "categorySummary.systemsAttention", "categorySummary.systemsAttention");
        Map<String, Object> catSummary = new LinkedHashMap<>();
        catSummary.put("total", catList.size());
        catSummary.put("goodCount", goodCats);
        catSummary.put("attentionCount", attentionCats);
        catSummary.put("text", systemsGood + " " + bullet + " " + systemsAttention);
        String passCat = counted(language, goodCats,
                "categorySummary.passedOne", "categorySummary.passedMany");
        String attnCat = counted(language, attentionCats,
                "categorySummary.attentionOne", "categorySummary.attentionMany");
        catSummary.put("checklistSummaryText", passCat + " " + bullet + " " + attnCat);
        catSummary.put("servicesText", passCat + " " + bullet + " " + attnCat);
        root.put("categoriesSummary", catSummary);
        root.put("tyreAssemblies", tyreAssemblies(snapshot, byEvidence, token));
        root.put("damageZones", damageZones(snapshot, byEvidence, token));
        root.put("inspectorSummary", List.of());
        root.put("inspectionVideos", videos(snapshot, byEvidence, token));
        List<Map<String, Object>> showcase = vehicleShowcase(snapshot, byEvidence, language, token);
        root.put("vehicleShowcase", showcase);
        root.put("showcaseExterior", showcase.stream().filter(i -> "exterior".equals(i.get("category"))).toList());
        root.put("showcaseInterior", showcase.stream().filter(i -> "interior".equals(i.get("category"))).toList());
        root.put("showcaseMechanical", showcase.stream().filter(i -> "mechanical".equals(i.get("category"))).toList());
        root.put("showcaseImperfections", showcase.stream().filter(i -> "imperfections".equals(i.get("category"))).toList());
        root.put("showcaseUnderbody", showcase.stream().filter(i -> "underbody".equals(i.get("category"))).toList());
        root.put("keyFindings", items(snapshot.keyFindings(), byEvidence, language, false, token));
        root.put("notChecked", notChecked(snapshot.notChecked(), language));
        root.put("limitations", limitations());
        root.put("disclaimer", disclaimer());
        return root;
    }

    public Map<String, Object> printPage(ReportVersion version, List<EvidenceDerivative> derivatives)
            throws Exception {
        return printPage(version, derivatives, null);
    }

    public Map<String, Object> printPage(ReportVersion version, List<EvidenceDerivative> derivatives,
                                         String customerName) throws Exception {
        return printPage(version, derivatives, customerName, null, null);
    }

    /**
     * @param heroPhotoBytes raw vehicle photo bytes embedded into the cover as
     *                       a data URI, or {@code null} for the unchanged cover.
     */
    public Map<String, Object> printPage(ReportVersion version, List<EvidenceDerivative> derivatives,
                                         String customerName, byte[] heroPhotoBytes,
                                         String heroMime) throws Exception {
        ReportSnapshot snapshot = objectMapper.readValue(version.getSnapshotJson(), ReportSnapshot.class);
        String language = snapshotLanguage(snapshot);
        Map<UUID, EvidenceDerivative> byEvidence = derivatives.stream()
                .filter(d -> d.getPurpose().equals("PUBLIC_FULL"))
                .collect(Collectors.toMap(EvidenceDerivative::getEvidenceAssetId, Function.identity(),
                        (left, right) -> left, LinkedHashMap::new));
        Map<String, Object> root = new LinkedHashMap<>();
        root.put("en", ReportMessages.labels(language));
        root.put("labels", ReportMessages.labels(language));
        root.put("lang", language);
        root.put("dir", "ltr");
        root.put("heroPhotoDataUri", heroPhotoBytes == null || heroPhotoBytes.length == 0
                ? null
                : "data:" + (heroMime == null || heroMime.isBlank() ? "image/jpeg" : heroMime)
                        + ";base64," + Base64.getEncoder().encodeToString(heroPhotoBytes));
        root.put("reportNumber", snapshot.reportNumber());
        root.put("displayToken", snapshot.reportNumber());
        root.put("version", snapshot.reportVersion());
        root.put("finalizedAt", formatDate(snapshot.finalizedAt(), language));
        root.put("publishedAt", formatDate(snapshot.publishedAt(), language));
        root.put("verificationHash", snapshot.verificationHash());
        root.put("score", snapshot.score());
        root.put("gradeCode", snapshot.gradeCode());
        root.put("safetyCapApplied", snapshot.safetyCapApplied());
        root.put("safetyCapReason", snapshot.safetyCapReason());
        root.put("vehicle", vehicle(snapshot.vehicle(),
                firstNonBlank(customerName, snapshot.customerName())));
        root.put("inspection", inspection(snapshot.inspection(), language));
        root.put("workshop", workshop(snapshot.workshop()));
        root.put("technician", technician(snapshot.technician()));
        int passedCount = 0;
        int attentionCount = 0;
        int defectCount = 0;
        for (ReportSnapshot.Category cat : snapshot.categories()) {
            for (ReportSnapshot.ItemSnapshot it : cat.items()) {
                if ("NO_ISSUE_OBSERVED".equals(it.resultCode())) passedCount++;
                else if ("ATTENTION_RECOMMENDED".equals(it.resultCode())) attentionCount++;
                else if ("DEFECT_FOUND".equals(it.resultCode())) defectCount++;
            }
        }
        int evaluated = passedCount + attentionCount + defectCount;
        int passRate = evaluated > 0 ? Math.round((float) passedCount * 100f / (float) evaluated) : 100;
        root.put("passedCount", passedCount);
        root.put("attentionCount", attentionCount);
        root.put("defectCount", defectCount);
        root.put("passRate", passRate);
        root.put("totalEvaluated", evaluated);
        root.put("coverage", coverage(snapshot.coverage(), language));
        // Same honesty rule as the public page: no stock/fabricated sections in print.
        root.put("visualInspections", List.of());
        root.put("inspectionSystems", List.of());
        List<Map<String, Object>> catListEn = categories(snapshot.categories(), byEvidence, language, true, null);
        root.put("categories", catListEn);
        int goodCatsEn = 0;
        int attentionCatsEn = 0;
        for (Map<String, Object> c : catListEn) {
            int d = (int) c.get("defectCount");
            int a = (int) c.get("attentionCount");
            if (d > 0 || a > 0) {
                attentionCatsEn++;
                c.put("categoryStatus", "ATTENTION");
                c.put("categoryStatusLabel", ReportMessages.label(language, "servicesNeedService"));
            } else {
                goodCatsEn++;
                c.put("categoryStatus", "GOOD");
                c.put("categoryStatusLabel", ReportMessages.label(language, "goodCondition"));
            }
        }
        Map<String, Object> catSummaryEn = new LinkedHashMap<>();
        catSummaryEn.put("total", catListEn.size());
        catSummaryEn.put("goodCount", goodCatsEn);
        catSummaryEn.put("attentionCount", attentionCatsEn);
        String goodText = ReportMessages.label(language, "servicesGood");
        String needText = ReportMessages.label(language, "servicesNeedService");
        catSummaryEn.put("text", goodCatsEn + " " + goodText + " · " + attentionCatsEn + " " + needText);
        String summaryText = goodCatsEn + " " + goodText + " · " + attentionCatsEn + " " + needText;
        catSummaryEn.put("checklistSummaryText", summaryText);
        catSummaryEn.put("servicesText", summaryText);
        root.put("categoriesSummary", catSummaryEn);
        List<Map<String, Object>> printShowcase = vehicleShowcase(snapshot, byEvidence, language, null);
        root.put("tyreAssemblies", tyreAssemblies(snapshot, byEvidence, null));
        root.put("damageZones", damageZones(snapshot, byEvidence, null));
        root.put("inspectorSummary", List.of());
        root.put("inspectionVideos", List.of());
        root.put("vehicleShowcase", printShowcase);
        root.put("showcaseExterior", printShowcase.stream()
                .filter(i -> "exterior".equals(i.get("category"))).toList());
        root.put("showcaseInterior", printShowcase.stream()
                .filter(i -> "interior".equals(i.get("category"))).toList());
        root.put("showcaseMechanical", printShowcase.stream()
                .filter(i -> "mechanical".equals(i.get("category"))).toList());
        root.put("showcaseImperfections", printShowcase.stream()
                .filter(i -> "imperfections".equals(i.get("category"))).toList());
        root.put("showcaseUnderbody", printShowcase.stream()
                .filter(i -> "underbody".equals(i.get("category"))).toList());
        root.put("keyFindings", items(snapshot.keyFindings(), byEvidence, language, true));
        root.put("notChecked", notChecked(snapshot.notChecked(), language, true));
        root.put("limitationsEn", snapshot.limitations());
        root.put("disclaimerEn", snapshot.disclaimer());
        return root;
    }

    public Map<String, Object> adminPage(ReportVersion version, List<EvidenceDerivative> derivatives)
            throws Exception {
        return publicPage(version, derivatives, "en", false);
    }

    private Map<String, Object> vehicle(ReportSnapshot.Vehicle vehicle, String customerName) {
        Map<String, Object> map = new LinkedHashMap<>();
        putIfText(map, "make", vehicle.make());
        putIfText(map, "model", vehicle.model());
        if (vehicle.year() != null) {
            map.put("year", vehicle.year());
        }
        putIfText(map, "vinMasked", vehicle.vinMasked());
        if (vehicle.odometerValue() != null) {
            map.put("odometer", String.format(Locale.ROOT, "%,d %s", vehicle.odometerValue(),
                    vehicle.odometerUnit() == null ? "" : vehicle.odometerUnit()).trim());
        }
        putIfText(map, "vehicleType", vehicle.vehicleType());
        // Only values captured on the job are rendered. Optional specs that have
        // no data are omitted so the templates hide the whole labelled cell.
        putIfText(map, "gearbox", vehicle.transmission());
        putIfText(map, "fuelType", vehicle.fuelType());
        String masked = CustomerNames.mask(customerName);
        if (masked != null) {
            map.put("clientName", masked);
        }
        return map;
    }

    /**
     * Masks a customer name for the public page:
     * {@code "E2E Customer"} becomes {@code "E2E C***"}.
     */
    public static String maskCustomerName(String name) {
        return CustomerNames.mask(name);
    }

    private static String firstNonBlank(String preferred, String fallback) {
        if (preferred != null && !preferred.isBlank()) {
            return preferred;
        }
        return fallback == null || fallback.isBlank() ? null : fallback;
    }

    private static void putIfText(Map<String, Object> map, String key, String value) {
        if (value != null && !value.isBlank()) {
            map.put(key, value);
        }
    }

    private Map<String, Object> inspection(ReportSnapshot.Inspection inspection, String language) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("scope", inspection.scope());
        map.put("templateVersion", inspection.templateVersionNo() == null ? "" : "v" + inspection.templateVersionNo());
        map.put("dateTime", formatDate(inspection.dateTime(), language));
        return map;
    }

    private Map<String, Object> workshop(ReportSnapshot.Workshop workshop) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("name", workshop.name());
        map.put("branch", workshop.branch());
        return map;
    }

    private Map<String, Object> technician(ReportSnapshot.Technician technician) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("displayName", technician.displayName());
        return map;
    }

    private Map<String, Object> coverage(ReportSnapshot.Coverage coverage, String language) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("total", coverage.total());
        map.put("applicable", coverage.applicable());
        map.put("completed", coverage.completed());
        map.put("notApplicable", coverage.notApplicable());
        map.put("notChecked", coverage.notChecked());
        map.put("couldNotVerify", coverage.couldNotVerify());
        map.put("text", coverage.completed() + " / " + coverage.applicable());
        return map;
    }

    private List<Map<String, Object>> categories(List<ReportSnapshot.Category> categories,
                                                 Map<UUID, EvidenceDerivative> derivatives,
                                                 String language) {
        return categories(categories, derivatives, language, false, null);
    }

    private List<Map<String, Object>> categories(List<ReportSnapshot.Category> categories,
                                                 Map<UUID, EvidenceDerivative> derivatives,
                                                 boolean bilingual) {
        return categories(categories, derivatives, "en", bilingual, null);
    }

    private List<Map<String, Object>> categories(List<ReportSnapshot.Category> categories,
                                                 Map<UUID, EvidenceDerivative> derivatives,
                                                 String language, boolean bilingual) {
        return categories(categories, derivatives, language, bilingual, null);
    }

    private List<Map<String, Object>> categories(List<ReportSnapshot.Category> categories,
                                                 Map<UUID, EvidenceDerivative> derivatives,
                                                 String language, boolean bilingual,
                                                 String token) {
        List<Map<String, Object>> result = new ArrayList<>();
        for (ReportSnapshot.Category category : categories) {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("label", display(category.label(), category.labelEn()));
            map.put("labelEn", category.labelEn());
            List<Map<String, Object>> itemList = items(category.items(), derivatives, language,
                    bilingual, token);
            map.put("items", itemList);
            int catPassed = 0;
            int catAttention = 0;
            int catDefect = 0;
            int totalScore = 0;
            for (Map<String, Object> it : itemList) {
                String rc = (String) it.get("resultCode");
                if ("NO_ISSUE_OBSERVED".equals(rc)) catPassed++;
                else if ("ATTENTION_RECOMMENDED".equals(rc)) catAttention++;
                else if ("DEFECT_FOUND".equals(rc)) catDefect++;
                Integer sc = (Integer) it.get("score");
                if (sc != null) totalScore += sc;
            }
            int avgScore = itemList.isEmpty() ? 100 : Math.round((float) totalScore / itemList.size());
            map.put("score", avgScore);
            map.put("scoreText", avgScore + "%");
            map.put("scoreGrade", avgScore >= 90 ? "A" : (avgScore >= 75 ? "B" : "C"));
            map.put("passedCount", catPassed);
            map.put("attentionCount", catAttention);
            map.put("defectCount", catDefect);
            String catStatus = catDefect > 0 ? "DEFECT" : (catAttention > 0 ? "ATTENTION" : "GOOD");
            String catStatusLabel = catDefect > 0
                    ? ReportMessages.label(language, "categoryStatus.badgeDefect")
                    : (catAttention > 0
                            ? ReportMessages.label(language, "categoryStatus.badgeAttention")
                            : ReportMessages.label(language, "categoryStatus.badgePass"));
            map.put("categoryStatus", catStatus);
            map.put("categoryStatusLabel", catStatusLabel);
            map.put("statusBadge", catStatusLabel);
            result.add(map);
        }
        return result;
    }

    private List<Map<String, Object>> items(List<ReportSnapshot.ItemSnapshot> items,
                                            Map<UUID, EvidenceDerivative> derivatives,
                                            String language) {
        return items(items, derivatives, language, false, null);
    }

    private List<Map<String, Object>> items(List<ReportSnapshot.ItemSnapshot> items,
                                            Map<UUID, EvidenceDerivative> derivatives,
                                            String language, boolean bilingual) {
        return items(items, derivatives, language, bilingual, null);
    }

    private List<Map<String, Object>> items(List<ReportSnapshot.ItemSnapshot> items,
                                            Map<UUID, EvidenceDerivative> derivatives,
                                            String language, boolean bilingual,
                                            String token) {
        List<Map<String, Object>> result = new ArrayList<>();
        for (ReportSnapshot.ItemSnapshot item : items) {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("stableCode", item.stableCode());
            map.put("label", display(item.label(), item.labelEn()));
            map.put("labelEn", item.labelEn());
            map.put("instruction", display(item.instruction(), item.instructionEn()));
            map.put("instructionEn", item.instructionEn());
            map.put("standardSpec", display(item.standardSpec(), ""));
            map.put("resultCode", item.resultCode());
            map.put("result", ReportMessages.result(language, item.resultCode()));
            map.put("resultEn", ReportMessages.result("en", item.resultCode()));
            String passFail = "DEFECT_FOUND".equals(item.resultCode()) ? "FAIL" :
                              ("ATTENTION_RECOMMENDED".equals(item.resultCode()) ? "ATTENTION" : "PASS");
            map.put("passFailStatus", passFail);
            map.put("severityCode", item.severityCode());
            map.put("severity", ReportMessages.severity(language, item.severityCode()));
            map.put("severityEn", ReportMessages.severity("en", item.severityCode()));
            map.put("note", item.note());
            map.put("noteLanguage", item.noteLanguage());
            map.put("noteDir", "ltr");
            map.put("reason", !item.reasonText().isBlank() ? item.reasonText() : item.reasonCode());
            map.put("reasonCode", item.reasonCode());

            // Score per item
            int score = "NO_ISSUE_OBSERVED".equals(item.resultCode()) ? 100 :
                        ("ATTENTION_RECOMMENDED".equals(item.resultCode()) ? 70 : 40);
            map.put("score", score);
            map.put("scoreText", score + "/100");
            map.put("scoreGrade", score >= 90 ? "A" : (score >= 70 ? "B" : "D"));

            String measuredSpec = measurementSummary(item);
            map.put("diagnosticMetric", measuredSpec);
            map.put("measuredSpec", measuredSpec);
            map.put("hasVideo", false);
            map.put("videoUrl", null);
            map.put("videoDuration", null);
            map.put("videoCaption", "");

            List<Map<String, Object>> itemPhotos =
                    photos(item.evidenceIds(), derivatives, language, bilingual);
            map.put("photos", itemPhotos);
            map.put("partPhoto", itemPhotos.isEmpty() ? null
                    : photoUrl(token, itemPhotos.get(0).get("id")));
            map.put("measurements", item.measurements().stream().map(measurement -> {
                Map<String, Object> value = new LinkedHashMap<>();
                value.put("fieldCode", measurement.fieldCode());
                value.put("valueIndex", measurement.valueIndex());
                value.put("numericValue", measurement.numericValue());
                value.put("unitCode", measurement.unitCode());
                value.put("resultCode", measurement.resultCode());
                value.put("score", measurement.score());
                return value;
            }).toList());
            map.put("bilingual", bilingual);
            result.add(map);
        }
        return result;
    }

    private List<Map<String, Object>> videos(ReportSnapshot snapshot,
                                             Map<UUID, EvidenceDerivative> byEvidence,
                                             String token) {
        List<Map<String, Object>> result = new ArrayList<>();
        for (ReportSnapshot.Category category : snapshot.categories()) {
            for (ReportSnapshot.ItemSnapshot item : category.items()) {
                for (String raw : item.evidenceIds()) {
                    UUID evidenceId;
                    try {
                        evidenceId = UUID.fromString(raw);
                    } catch (RuntimeException ignored) {
                        continue;
                    }
                    EvidenceDerivative derivative = byEvidence.get(evidenceId);
                    if (derivative == null || derivative.getMime() == null
                            || !derivative.getMime().startsWith("video/")) {
                        continue;
                    }
                    Map<String, Object> video = new LinkedHashMap<>();
                    video.put("id", derivative.getId());
                    video.put("title", display(item.label(), item.labelEn()));
                    video.put("category", display(category.label(), category.labelEn()));
                    video.put("videoUrl", videoUrl(token, derivative.getId()));
                    video.put("thumbnailUrl", firstPhotoUrl(item, byEvidence, token));
                    video.put("duration", "");
                    video.put("caption", item.note() == null || item.note().isBlank()
                            ? item.reasonText() : item.note());
                    result.add(video);
                }
            }
        }
        return result;
    }

    private String videoUrl(String token, Object derivativeId) {
        if (token == null || derivativeId == null) {
            return null;
        }
        return "/r/" + token + "/video/" + derivativeId;
    }

    private List<Map<String, Object>> photos(List<String> evidenceIds,
                                             Map<UUID, EvidenceDerivative> derivatives,
                                             String language, boolean bilingual) {
        List<Map<String, Object>> result = new ArrayList<>();
        for (String rawId : evidenceIds) {
            UUID evidenceId;
            try {
                evidenceId = UUID.fromString(rawId);
            } catch (RuntimeException ignored) {
                continue;
            }
            EvidenceDerivative derivative = derivatives.get(evidenceId);
            if (derivative == null || derivative.getMime() == null
                    || !derivative.getMime().startsWith("image/")) {
                continue;
            }
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("id", derivative.getId());
            map.put("alt", ReportMessages.photoAlt(language));
            map.put("altEn", ReportMessages.photoAlt("en"));
            map.put("caption", ReportMessages.label(language, "evidenceCaption"));
            map.put("captionEn", ReportMessages.label("en", "evidenceCaption"));
            result.add(map);
        }
        return result;
    }

    private List<Map<String, Object>> notChecked(List<ReportSnapshot.NotChecked> values,
                                                 String language) {
        return notChecked(values, language, false);
    }

    private List<Map<String, Object>> notChecked(List<ReportSnapshot.NotChecked> values,
                                                 String language, boolean bilingual) {
        List<Map<String, Object>> result = new ArrayList<>();
        for (ReportSnapshot.NotChecked value : values) {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("label", value.labelEn());
            map.put("labelEn", value.labelEn());
            map.put("result", ReportMessages.result(language, value.resultCode()));
            map.put("resultEn", ReportMessages.result("en", value.resultCode()));
            map.put("reason", value.reason());
            result.add(map);
        }
        return result;
    }

    private List<String> limitations() {
        return ReportMessages.limitations("en");
    }

    private String disclaimer() {
        return ReportMessages.disclaimer("en");
    }

    private String blankIfNull(String value) {
        return value == null ? "" : value;
    }

    private String photoUrl(String token, Object derivativeId) {
        if (token == null || derivativeId == null) {
            return null;
        }
        return "/r/" + token + "/photo/" + derivativeId;
    }

    private Map<UUID, EvidenceDerivative> byEvidence(List<EvidenceDerivative> derivatives) {
        Map<UUID, EvidenceDerivative> map = new LinkedHashMap<>();
        for (EvidenceDerivative derivative : derivatives) {
            if ("PUBLIC_FULL".equals(derivative.getPurpose())) {
                map.putIfAbsent(derivative.getEvidenceAssetId(), derivative);
            }
        }
        return map;
    }

    private String firstPhotoUrl(ReportSnapshot.ItemSnapshot item,
                                 Map<UUID, EvidenceDerivative> byEvidence, String token) {
        for (String raw : item.evidenceIds()) {
            try {
                EvidenceDerivative derivative = byEvidence.get(UUID.fromString(raw));
                if (derivative != null && derivative.getMime() != null
                        && derivative.getMime().startsWith("image/")) {
                    return photoUrl(token, derivative.getId());
                }
            } catch (RuntimeException ignored) {
                // Skip malformed evidence ids.
            }
        }
        return null;
    }

    private String measurementSummary(ReportSnapshot.ItemSnapshot item) {
        if (item.measurements().isEmpty()) {
            return "";
        }
        return item.measurements().stream()
                .map(value -> {
                    String label = value.valueIndex() == null || value.valueIndex().isBlank()
                            ? value.fieldCode() : value.valueIndex();
                    return label + ": " + value.numericValue()
                            + (value.unitCode() == null ? "" : " " + value.unitCode());
                })
                .collect(Collectors.joining(" â·¢ "));
    }

    private List<Map<String, Object>> vehicleShowcase(ReportSnapshot snapshot,
                                                      Map<UUID, EvidenceDerivative> byEvidence,
                                                      String language, String token) {
        List<Map<String, Object>> result = new ArrayList<>();
        for (ReportSnapshot.Category category : snapshot.categories()) {
            for (ReportSnapshot.ItemSnapshot item : category.items()) {
                for (String raw : item.evidenceIds()) {
                    UUID evidenceId;
                    try {
                        evidenceId = UUID.fromString(raw);
                    } catch (RuntimeException ignored) {
                        continue;
                    }
                    EvidenceDerivative derivative = byEvidence.get(evidenceId);
                    if (derivative == null || derivative.getMime() == null
                            || !derivative.getMime().startsWith("image/")) {
                        continue;
                    }
                    Map<String, Object> photo = new LinkedHashMap<>();
                    photo.put("id", "photo-" + derivative.getId());
                    photo.put("category", showcaseCategory(category.labelEn()));
                    photo.put("categoryLabel", display(category.label(), category.labelEn()));
                    photo.put("title", display(item.label(), item.labelEn()));
                    photo.put("details", measurementSummary(item));
                    photo.put("condition", ReportMessages.result(language, item.resultCode()));
                    photo.put("imageUrl", photoUrl(token, derivative.getId()));
                    photo.put("inspectNote", item.note());
                    result.add(photo);
                }
            }
        }
        return result;
    }

    private String showcaseCategory(String category) {
        String value = category == null ? "" : category.toLowerCase(Locale.ROOT);
        if (value.contains("interior") || value.contains("cabin")) return "interior";
        if (value.contains("underbody") || value.contains("chassis")) return "underbody";
        if (value.contains("body") || value.contains("paint") || value.contains("exterior")) {
            return "exterior";
        }
        return "mechanical";
    }

    private List<Map<String, Object>> tyreAssemblies(ReportSnapshot snapshot,
                                                     Map<UUID, EvidenceDerivative> byEvidence,
                                                     String token) {
        String[] positions = {"FL", "FR", "RL", "RR"};
        String[] labels = {"Front Left", "Front Right", "Rear Left", "Rear Right"};
        List<Map<String, Object>> result = new ArrayList<>();
        for (ReportSnapshot.Category category : snapshot.categories()) {
            for (ReportSnapshot.ItemSnapshot item : category.items()) {
                if (!item.stableCode().toUpperCase(Locale.ROOT).contains("TYRE")) {
                    continue;
                }
                for (int i = 0; i < positions.length; i++) {
                    String positionCode = positions[i];
                    ReportSnapshot.Measurement measurement = item.measurements().stream()
                            .filter(value -> positionCode.equalsIgnoreCase(value.valueIndex()))
                            .findFirst().orElse(null);
                    if (measurement == null) {
                        continue;
                    }
                    int score = measurement.score() == null
                            ? ("NO_ISSUE_OBSERVED".equals(item.resultCode()) ? 100
                            : ("ATTENTION_RECOMMENDED".equals(item.resultCode()) ? 70 : 40))
                            : measurement.score();
                    Map<String, Object> tyre = new LinkedHashMap<>();
                    tyre.put("id", "tyre-" + positions[i].toLowerCase(Locale.ROOT));
                    tyre.put("posCode", positions[i]);
                    tyre.put("position", labels[i]);
                    tyre.put("title", display(item.label(), item.labelEn()) + " " + labels[i]);
                    tyre.put("category", display(category.label(), category.labelEn()));
                    tyre.put("status", tyreStatus(item.resultCode()));
                    tyre.put("statusLabel", ReportMessages.result(snapshotLanguage(snapshot),
                            item.resultCode()));
                    tyre.put("statusClass", "NO_ISSUE_OBSERVED".equals(item.resultCode())
                            ? "badge-pass" : "badge-attention");
                    tyre.put("score", score);
                    tyre.put("scoreText", score + "/100");
                    String value = measurement.numericValue() == null ? ""
                            : measurement.numericValue().stripTrailingZeros().toPlainString();
                    tyre.put("treadDepth", value + (measurement.unitCode() == null
                            ? "" : " " + measurement.unitCode()));
                    tyre.put("pressure", "");
                    tyre.put("brakePad", "");
                    tyre.put("measuredSpec", measurementSummary(item));
                    tyre.put("standardSpec", "");
                    tyre.put("diagnosticSensor", "");
                    tyre.put("technicianNote", item.note());
                    tyre.put("imageUrl", firstPhotoUrl(item, byEvidence, token));
                    tyre.put("videoUrl", null);
                    tyre.put("videoCaption", "");
                    result.add(tyre);
                }
            }
        }
        return result;
    }

    private String tyreStatus(String resultCode) {
        if ("ATTENTION_RECOMMENDED".equals(resultCode)) return "ATTENTION";
        if ("DEFECT_FOUND".equals(resultCode)) return "DEFECT_FOUND";
        return "PASSED";
    }

    private List<Map<String, Object>> damageZones(ReportSnapshot snapshot,
                                                  Map<UUID, EvidenceDerivative> byEvidence,
                                                  String token) {
        List<Map<String, Object>> result = new ArrayList<>();
        for (ReportSnapshot.Category category : snapshot.categories()) {
            String label = category.labelEn() == null ? "" : category.labelEn().toLowerCase(Locale.ROOT);
            boolean body = label.contains("body") || label.contains("paint")
                    || label.contains("exterior") || label.contains("tyre")
                    || label.contains("brake");
            if (!body) {
                continue;
            }
            for (ReportSnapshot.ItemSnapshot item : category.items()) {
                if ("NO_ISSUE_OBSERVED".equals(item.resultCode())) {
                    continue;
                }
                Map<String, Object> zone = new LinkedHashMap<>();
                zone.put("id", item.stableCode());
                zone.put("code", item.stableCode());
                zone.put("title", display(item.label(), item.labelEn()));
                zone.put("isDamaged", true);
                zone.put("status", item.resultCode());
                zone.put("statusLabel", ReportMessages.result(snapshotLanguage(snapshot),
                        item.resultCode()));
                zone.put("statusClass", "DEFECT_FOUND".equals(item.resultCode())
                        ? "badge-defect" : "badge-attention");
                zone.put("paintThickness", item.measurements().isEmpty() ? ""
                        : item.measurements().get(0).numericValue()
                        + (item.measurements().get(0).unitCode() == null ? ""
                        : " " + item.measurements().get(0).unitCode()));
                zone.put("note", item.note().isBlank() ? item.reasonText() : item.note());
                zone.put("score", "DEFECT_FOUND".equals(item.resultCode()) ? 40
                        : ("ATTENTION_RECOMMENDED".equals(item.resultCode()) ? 70 : 100));
                zone.put("imageUrl", firstPhotoUrl(item, byEvidence, token));
                zone.put("videoUrl", null);
                zone.put("videoCaption", "");
                result.add(zone);
            }
        }
        return result;
    }

    private String formatDate(String value, String language) {
        if (value == null || value.isBlank()) {
            return "";
        }
        try {
            LocalDateTime date = LocalDateTime.parse(value);
            Locale locale = ReportMessages.locale(language);
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd MMM yyyy, HH:mm", locale);
            return date.atOffset(ZoneOffset.ofHours(4)).format(formatter) + " GST";
        } catch (DateTimeParseException exception) {
            return value;
        }
    }

    private static String display(String localized, String english) {
        return localized == null || localized.isBlank()
                ? (english == null ? "" : english) : localized;
    }

    private static String counted(String language, int count, String oneKey, String manyKey) {
        String template = ReportMessages.label(language, count == 1 ? oneKey : manyKey);
        return template.replace("{0}", Integer.toString(count));
    }

    private static String snapshotLanguage(ReportSnapshot snapshot) {
        return snapshot.language() == null || snapshot.language().isBlank()
                ? "en" : snapshot.language();
    }

}
