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
 * <p>All wording lives in the English bundle ({@code i18n/report_en.properties}).
 * No literal user-facing text may be added here; add a key to the bundle instead.
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
            "reportHash", "downloadPdf", "language", "english", "notCertified",
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
            "defectActionRequired", "diagnosticSystemsHub", "diagnosticSystemsHubSub",
            "inspectionCriteria", "inspectionCriteriaSubtitle", "cleanCondition",
            "noDamageNote", "tapPanelToInspect", "paintThickness", "zoneInspection",
            "inspectZoneProof", "allPanelsChecked", "inspectorSummary", "inspectorSummarySub",
            "gearbox", "fuelType", "drivetrain", "specs", "additionalSpecs", "engineSize",
            "horsepower", "cylinders", "exteriorColor", "interiorTrim", "wheels",
            "steeringSide", "keysCount", "emirate", "contactInspector", "contactInspectorSub",
            "callWorkshop", "whatsAppConsult", "obdDiagnostic", "faultCodesCount",
            "reportedFaults", "inspectionVideos", "imperfections", "underbodyChassis",
            "videoCaptionNote", "referenceNo", "inspectedOn", "clientName", "inspectionCenter",
            "shareReport", "electricalReport", "batteryReport", "beforeTestDriveReport",
            "afterTestDriveReport", "tireReport", "downloadAllDocuments",
            "customer", "vehicleDetails", "overallPassRate", "customerInspection",
            "categoryOverview", "checklistContinued", "tyresBrakesBody",
            "photoEvidence", "verificationDisclaimer", "reportNumber",
            "tamperHash", "tamperExplanation", "englishSummary", "certifiedPlatform",
            "year", "engine", "branch", "totalChecks", "noCriticalDefects", "brakePad",
            "checksEvaluated", "itemsRequireAttention", "checks", "signedVerifiedBy",
            "issued", "specsOrigin");

    private ReportMessages() {
    }

    public static Map<String, Object> labels(String language) {
        Map<String, Object> labels = new LinkedHashMap<>();
        for (String key : LABEL_KEYS) {
            labels.put(key, value(language, key));
        }
        return labels;
    }

    public static String label(String language, String key) {
        return value(language, key);
    }

    public static String result(String language, String code) {
        return valueOr(language, "result." + code, code);
    }

    public static String severity(String language, String code) {
        if (code == null) {
            return "";
        }
        return valueOr(language, "severity." + code, "");
    }

    public static List<String> limitations(String language) {
        return List.of(
                value(language, "limitation.1"),
                value(language, "limitation.2"),
                value(language, "limitation.3"),
                value(language, "limitation.4"));
    }

    public static String disclaimer(String language) {
        return value(language, "disclaimer");
    }

    public static String photoAlt(String language) {
        return value(language, "photo.alt");
    }

    static Locale locale(String language) {
        if (language == null || language.isBlank()) {
            return Locale.ENGLISH;
        }
        return Locale.forLanguageTag(language.trim().toLowerCase(Locale.ROOT));
    }

    static ResourceBundle bundle(String language) {
        return target(language);
    }

    /** Per-key fallback to English when the locale bundle is missing a key. */
    private static String value(String language, String key) {
        ResourceBundle target = target(language);
        if (target.containsKey(key)) {
            return target.getString(key);
        }
        return english().getString(key);
    }

    private static String valueOr(String language, String key, String fallback) {
        ResourceBundle target = target(language);
        if (target.containsKey(key)) {
            return target.getString(key);
        }
        ResourceBundle english = english();
        return english.containsKey(key) ? english.getString(key) : fallback;
    }

    private static ResourceBundle target(String language) {
        Locale locale = locale(language);
        if (Locale.ENGLISH.equals(locale)) {
            return english();
        }
        try {
            return ResourceBundle.getBundle(BASE_NAME, locale);
        } catch (MissingResourceException exception) {
            return english();
        }
    }

    private static ResourceBundle english() {
        return ResourceBundle.getBundle(BASE_NAME, Locale.ENGLISH);
    }
}
