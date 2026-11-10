package com.truereport.reports;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.MissingResourceException;
import java.util.ResourceBundle;

/**
 * User-facing report/PDF/public-page text.
 *
 * <p>All wording lives in per-language bundles ({@code i18n/report_en.properties},
 * {@code i18n/report_ar.properties}). No literal user-facing text may be added here;
 * add a key to both bundles instead.
 */
public final class ReportMessages {

    private static final String BASE_NAME = "i18n.report";

    /** Keys exposed to Thymeleaf templates via {@link #labels(String)}. */
    public static final List<String> LABEL_KEYS = List.of(
            "title", "neutralDescription", "summary", "coverage", "completed", "applicable",
            "checksCompleted", "coverageNotScore", "keyFindings", "noKeyFindings", "vehicle",
            "inspection", "workshop", "technician", "reportId", "version", "finalized", "published",
            "scope", "template", "odometer", "findings", "category", "result", "severity", "note",
            "reason", "notChecked", "couldNotVerify", "limitations", "photos", "noPhotos",
            "reportHash", "downloadPdf", "language", "english", "arabic", "notCertified",
            "evidenceCaption", "originalNote", "noTranslation", "reportDetails", "page",
            "unavailableTitle", "unavailableBody", "temporaryTitle", "temporaryBody",
            "revocationNotice", "vin", "check", "notApplicable", "notCompleted",
            "liveReport", "overallCondition", "passed", "attention", "defects",
            "overview", "exteriorDamageMap", "tyresAndBrakes", "subsystems",
            "evidenceGallery", "verification", "treadDepth", "pressure", "axle",
            "frontLeft", "frontRight", "rearLeft", "rearRight", "bodyCondition",
            "tamperProof", "verifiedBy", "viewFullSize", "viewPhoto", "close",
            "inspected", "passRateLabel", "officialInspection",
            "visualDiagnosis", "visualDiagnosisSubtitle", "allParts", "damageDetected",
            "noDamageObserved", "cosmeticAttention", "actionRequired", "tapToEnlarge",
            "technicianObservations", "componentsChecked", "damageLocation",
            "vehicleShowcase", "vehicleShowcaseSubtitle", "showcaseAll", "showcaseExterior",
            "showcaseInterior", "showcaseMechanical", "photosDocumented", "marketplaceReady",
            "verifiedCapture", "resaleAdviceTitle", "resaleAdviceBody", "viewFullPhoto",
            "originalCondition", "exteriorBadge", "interiorBadge", "mechanicalBadge",
            "systemsSummary", "systemsSummarySubtitle", "systemName", "checksCount",
            "status", "goodCondition", "exteriorSystem", "chassisSystem", "powertrainSystem",
            "suspensionSystem", "electricalSystem", "acSystem", "brakingSystem", "roadTestSystem",
            "finalDecision", "approved", "gradeLabel", "gallerySubtitle",
            "scheduledServices", "servicesGood", "servicesNeedService", "allChecks",
            "filterPassed", "filterAttention", "filterFailed", "itemScore",
            "videoProof", "playVideo", "partDetails", "measuredSpec",
            "serviceRemaining", "tapToToggleDetails", "viewPartDetails",
            "closeDetails", "systemHealthSummary", "diagnosticScore",
            "standardSpec", "diagnosticSensor", "technicianNotes",
            "defectActionRequired", "diagnosticSystemsHub", "diagnosticSystemsHubSub");

    private ReportMessages() {
    }

    public static Map<String, Object> labels(String language) {
        ResourceBundle bundle = bundle(language);
        Map<String, Object> labels = new LinkedHashMap<>();
        for (String key : LABEL_KEYS) {
            labels.put(key, bundle.getString(key));
        }
        return labels;
    }

    public static String label(String language, String key) {
        return bundle(language).getString(key);
    }

    public static String result(String language, String code) {
        try {
            return bundle(language).getString("result." + code);
        } catch (MissingResourceException exception) {
            return code;
        }
    }

    public static String severity(String language, String code) {
        if (code == null) {
            return "";
        }
        try {
            return bundle(language).getString("severity." + code);
        } catch (MissingResourceException exception) {
            return "";
        }
    }

    public static List<String> limitations(String language) {
        ResourceBundle bundle = bundle(language);
        return List.of(
                bundle.getString("limitation.1"),
                bundle.getString("limitation.2"),
                bundle.getString("limitation.3"),
                bundle.getString("limitation.4"));
    }

    public static String disclaimer(String language) {
        return bundle(language).getString("disclaimer");
    }

    public static String photoAlt(String language) {
        return bundle(language).getString("photo.alt");
    }

    static Locale locale(String language) {
        return "ar".equals(language) ? new Locale("ar") : Locale.ENGLISH;
    }

    static ResourceBundle bundle(String language) {
        return ResourceBundle.getBundle(BASE_NAME, locale(language));
    }
}
