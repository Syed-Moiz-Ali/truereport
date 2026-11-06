package com.truereport.reports;

import com.fasterxml.jackson.databind.ObjectMapper;
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
        ReportSnapshot snapshot = objectMapper.readValue(version.getSnapshotJson(), ReportSnapshot.class);
        Map<UUID, EvidenceDerivative> byEvidence = derivatives.stream()
                .filter(d -> d.getPurpose().equals("PUBLIC_FULL"))
                .collect(Collectors.toMap(EvidenceDerivative::getEvidenceAssetId, Function.identity(),
                        (left, right) -> left, LinkedHashMap::new));
        boolean ar = "ar".equals(language);
        Map<String, Object> root = new LinkedHashMap<>();
        root.put("lang", language);
        root.put("dir", ar ? "rtl" : "ltr");
        root.put("isRtl", ar);
        root.put("labels", ReportMessages.labels(language));
        root.put("pdfDownloadEnabled", pdfDownloadEnabled);
        root.put("reportNumber", snapshot.reportNumber());
        root.put("version", snapshot.reportVersion());
        root.put("finalizedAt", formatDate(snapshot.finalizedAt(), language));
        root.put("publishedAt", formatDate(snapshot.publishedAt(), language));
        root.put("verificationHash", snapshot.verificationHash());
        root.put("vehicle", vehicle(snapshot.vehicle(), language));
        root.put("inspection", inspection(snapshot.inspection(), language));
        root.put("workshop", workshop(snapshot.workshop()));
        root.put("technician", technician(snapshot.technician()));
        root.put("coverage", coverage(snapshot.coverage(), language));
        root.put("keyFindings", items(snapshot.keyFindings(), byEvidence, language));
        root.put("categories", categories(snapshot.categories(), byEvidence, language));
        root.put("notChecked", notChecked(snapshot.notChecked(), language));
        root.put("limitations", limitations(ar));
        root.put("disclaimer", disclaimer(ar));
        return root;
    }

    public Map<String, Object> printPage(ReportVersion version, List<EvidenceDerivative> derivatives)
            throws Exception {
        ReportSnapshot snapshot = objectMapper.readValue(version.getSnapshotJson(), ReportSnapshot.class);
        Map<UUID, EvidenceDerivative> byEvidence = derivatives.stream()
                .filter(d -> d.getPurpose().equals("PUBLIC_FULL"))
                .collect(Collectors.toMap(EvidenceDerivative::getEvidenceAssetId, Function.identity(),
                        (left, right) -> left, LinkedHashMap::new));
        Map<String, Object> root = new LinkedHashMap<>();
        root.put("en", ReportMessages.labels("en"));
        root.put("ar", ReportMessages.labels("ar"));
        root.put("reportNumber", snapshot.reportNumber());
        root.put("version", snapshot.reportVersion());
        root.put("finalizedAt", formatDate(snapshot.finalizedAt(), "en"));
        root.put("publishedAt", formatDate(snapshot.publishedAt(), "en"));
        root.put("verificationHash", snapshot.verificationHash());
        root.put("vehicle", vehicle(snapshot.vehicle(), "en"));
        root.put("inspection", inspection(snapshot.inspection(), "en"));
        root.put("workshop", workshop(snapshot.workshop()));
        root.put("technician", technician(snapshot.technician()));
        root.put("coverage", coverage(snapshot.coverage(), "en"));
        root.put("keyFindings", items(snapshot.keyFindings(), byEvidence, "en", true));
        root.put("categories", categories(snapshot.categories(), byEvidence, true));
        root.put("notChecked", notChecked(snapshot.notChecked(), "en", true));
        root.put("limitationsEn", limitations(false));
        root.put("limitationsAr", limitations(true));
        root.put("disclaimerEn", disclaimer(false));
        root.put("disclaimerAr", disclaimer(true));
        return root;
    }

    public Map<String, Object> adminPage(ReportVersion version, List<EvidenceDerivative> derivatives)
            throws Exception {
        return publicPage(version, derivatives, "en", false);
    }

    private Map<String, Object> vehicle(ReportSnapshot.Vehicle vehicle, String language) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("make", vehicle.make());
        map.put("model", vehicle.model());
        map.put("year", vehicle.year());
        map.put("vinMasked", vehicle.vinMasked());
        map.put("odometer", vehicle.odometerValue() == null ? "" :
                String.format(Locale.ROOT, "%,d %s", vehicle.odometerValue(),
                        vehicle.odometerUnit() == null ? "" : vehicle.odometerUnit()));
        map.put("vehicleType", vehicle.vehicleType());
        return map;
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
        return categories(categories, derivatives, language, false);
    }

    private List<Map<String, Object>> categories(List<ReportSnapshot.Category> categories,
                                                 Map<UUID, EvidenceDerivative> derivatives,
                                                 boolean bilingual) {
        return categories(categories, derivatives, "en", bilingual);
    }

    private List<Map<String, Object>> categories(List<ReportSnapshot.Category> categories,
                                                 Map<UUID, EvidenceDerivative> derivatives,
                                                 String language, boolean bilingual) {
        List<Map<String, Object>> result = new ArrayList<>();
        for (ReportSnapshot.Category category : categories) {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("label", "ar".equals(language) ? category.labelAr() : category.labelEn());
            map.put("labelEn", category.labelEn());
            map.put("labelAr", category.labelAr());
            map.put("items", items(category.items(), derivatives, language, bilingual));
            result.add(map);
        }
        return result;
    }

    private List<Map<String, Object>> items(List<ReportSnapshot.ItemSnapshot> items,
                                            Map<UUID, EvidenceDerivative> derivatives,
                                            String language) {
        return items(items, derivatives, language, false);
    }

    private List<Map<String, Object>> items(List<ReportSnapshot.ItemSnapshot> items,
                                            Map<UUID, EvidenceDerivative> derivatives,
                                            String language, boolean bilingual) {
        List<Map<String, Object>> result = new ArrayList<>();
        for (ReportSnapshot.ItemSnapshot item : items) {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("stableCode", item.stableCode());
            map.put("label", "ar".equals(language) ? item.labelAr() : item.labelEn());
            map.put("labelEn", item.labelEn());
            map.put("labelAr", item.labelAr());
            map.put("instruction", "ar".equals(language) ? item.instructionAr() : item.instructionEn());
            map.put("instructionEn", item.instructionEn());
            map.put("instructionAr", item.instructionAr());
            map.put("resultCode", item.resultCode());
            map.put("result", ReportMessages.result(language, item.resultCode()));
            map.put("resultEn", ReportMessages.result("en", item.resultCode()));
            map.put("resultAr", ReportMessages.result("ar", item.resultCode()));
            map.put("severityCode", item.severityCode());
            map.put("severity", ReportMessages.severity(language, item.severityCode()));
            map.put("severityEn", ReportMessages.severity("en", item.severityCode()));
            map.put("severityAr", ReportMessages.severity("ar", item.severityCode()));
            map.put("note", item.note());
            map.put("noteLanguage", item.noteLanguage());
            map.put("noteDir", "ar".equals(item.noteLanguage()) ? "rtl" : "ltr");
            map.put("reason", !item.reasonText().isBlank() ? item.reasonText() : item.reasonCode());
            map.put("reasonCode", item.reasonCode());
            map.put("photos", photos(item.evidenceIds(), derivatives, language, bilingual));
            map.put("bilingual", bilingual);
            result.add(map);
        }
        return result;
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
            if (derivative == null) {
                continue;
            }
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("id", derivative.getId());
            map.put("alt", ReportMessages.photoAlt(language));
            map.put("altEn", ReportMessages.photoAlt("en"));
            map.put("altAr", ReportMessages.photoAlt("ar"));
            map.put("caption", ReportMessages.label(language, "evidenceCaption"));
            map.put("captionEn", ReportMessages.label("en", "evidenceCaption"));
            map.put("captionAr", ReportMessages.label("ar", "evidenceCaption"));
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
            map.put("label", "ar".equals(language) ? value.labelAr() : value.labelEn());
            map.put("labelEn", value.labelEn());
            map.put("labelAr", value.labelAr());
            map.put("result", ReportMessages.result(language, value.resultCode()));
            map.put("resultEn", ReportMessages.result("en", value.resultCode()));
            map.put("resultAr", ReportMessages.result("ar", value.resultCode()));
            map.put("reason", value.reason());
            result.add(map);
        }
        return result;
    }

    private List<String> limitations(boolean ar) {
        return ReportMessages.limitations(ar ? "ar" : "en");
    }

    private String disclaimer(boolean ar) {
        return ReportMessages.disclaimer(ar ? "ar" : "en");
    }

    private String formatDate(String value, String language) {
        if (value == null || value.isBlank()) {
            return "";
        }
        try {
            LocalDateTime date = LocalDateTime.parse(value);
            Locale locale = "ar".equals(language) ? Locale.forLanguageTag("ar") : Locale.ENGLISH;
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd MMM yyyy, HH:mm", locale);
            return date.atOffset(ZoneOffset.ofHours(4)).format(formatter) + " GST";
        } catch (DateTimeParseException exception) {
            return value;
        }
    }
}
