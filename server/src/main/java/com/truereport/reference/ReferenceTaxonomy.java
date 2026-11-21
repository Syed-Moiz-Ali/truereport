package com.truereport.reference;

import com.truereport.reference.ReferenceEnums.ChecklistStatus;
import com.truereport.reference.ReferenceEnums.ConsentStatus;
import com.truereport.reference.ReferenceEnums.ContentType;
import com.truereport.reference.ReferenceEnums.DeliveryStatus;
import com.truereport.reference.ReferenceEnums.DocumentStatus;
import com.truereport.reference.ReferenceEnums.DocumentTypeStatus;
import com.truereport.reference.ReferenceEnums.EvidenceStatus;
import com.truereport.reference.ReferenceEnums.EvidenceType;
import com.truereport.reference.ReferenceEnums.Grade;
import com.truereport.reference.ReferenceEnums.HealthStatus;
import com.truereport.reference.ReferenceEnums.InputType;
import com.truereport.reference.ReferenceEnums.JobStatus;
import com.truereport.reference.ReferenceEnums.MeasurementDirection;
import com.truereport.reference.ReferenceEnums.MeasurementUnit;
import com.truereport.reference.ReferenceEnums.PlatformChipStatus;
import com.truereport.reference.ReferenceEnums.PublicationStatus;
import com.truereport.reference.ReferenceEnums.ResultCode;
import com.truereport.reference.ReferenceEnums.ReviewStatus;
import com.truereport.reference.ReferenceEnums.Role;
import com.truereport.reference.ReferenceEnums.Severity;
import com.truereport.reference.ReferenceEnums.SyncStatus;
import com.truereport.reference.ReferenceEnums.TemplateStatus;
import com.truereport.reference.ReferenceEnums.TranslationStatus;
import com.truereport.reference.ReferenceEnums.WorkshopStatus;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Static taxonomy seeded into the option-set store and {@code status_transition}.
 * Every {@code labelKey} must already exist in the English catalogs;
 * {@code ReferenceTaxonomyGuardTest} enforces both that and that every enum
 * constant has a seeded value.
 */
public final class ReferenceTaxonomy {

    public static final String JOB_STATUS = "job-status";
    public static final String REVIEW_STATUS = "review-status";
    public static final String PUBLICATION_STATUS = "publication-status";
    public static final String DOCUMENT_STATUS = "document-status";
    public static final String SYNC_STATUS = "sync-status";
    public static final String EVIDENCE_STATUS = "evidence-status";
    public static final String TEMPLATE_STATUS = "template-status";
    public static final String WORKSHOP_STATUS = "workshop-status";
    public static final String CHECKLIST_STATUS = "checklist-status";
    public static final String HEALTH_STATUS = "health-status";
    public static final String PLATFORM_CHIP_STATUS = "platform-chip-status";
    public static final String DELIVERY_STATUS = "delivery-status";
    public static final String CONSENT_STATUS = "consent-status";
    public static final String CONTENT_TYPE = "content-type";
    public static final String TRANSLATION_STATUS = "translation-status";
    public static final String INPUT_TYPE = "input-type";
    public static final String MEASUREMENT_DIRECTION = "measurement-direction";
    public static final String DOCUMENT_TYPE_STATUS = "document-type-status";

    public static final String ROLE = "role";
    public static final String SEVERITY = "severity";
    public static final String RESULT = "result";
    public static final String GRADE = "grade";
    public static final String MEASUREMENT_UNIT = "measurement-unit";
    public static final String EVIDENCE_TYPE = "evidence-type";

    public static final List<String> ALL = List.of(
            "platform_admin", "workshop_admin", "technician");
    public static final List<String> CLIENTS = List.of("workshop_admin", "technician");
    public static final List<String> PLATFORM = List.of("platform_admin");
    public static final List<String> WORKSHOP = List.of("workshop_admin");
    public static final List<String> PLATFORM_WORKSHOP = List.of("platform_admin", "workshop_admin");

    /** Status type segments used by {@code /reference/statuses/{type}}. */
    public static final Map<String, String> STATUS_TYPES = Map.ofEntries(
            Map.entry("job", JOB_STATUS),
            Map.entry("review", REVIEW_STATUS),
            Map.entry("publication", PUBLICATION_STATUS),
            Map.entry("document", DOCUMENT_STATUS),
            Map.entry("sync", SYNC_STATUS),
            Map.entry("evidence", EVIDENCE_STATUS),
            Map.entry("template", TEMPLATE_STATUS),
            Map.entry("workshop", WORKSHOP_STATUS),
            Map.entry("checklist", CHECKLIST_STATUS),
            Map.entry("health", HEALTH_STATUS),
            Map.entry("chip", PLATFORM_CHIP_STATUS),
            Map.entry("delivery", DELIVERY_STATUS),
            Map.entry("consent", CONSENT_STATUS),
            Map.entry("translation", TRANSLATION_STATUS),
            Map.entry("translation-status", TRANSLATION_STATUS),
            Map.entry("document-type", DOCUMENT_TYPE_STATUS),
            Map.entry("document-type-status", DOCUMENT_TYPE_STATUS));

    /** Enum segments used by {@code /reference/enums/{code}}. */
    public static final Map<String, String> ENUM_CODES = Map.of(
            "role", ROLE,
            "severity", SEVERITY,
            "result", RESULT,
            "grade", GRADE,
            "measurement-unit", MEASUREMENT_UNIT,
            "evidence-type", EVIDENCE_TYPE,
            "content-type", CONTENT_TYPE,
            "input-type", INPUT_TYPE,
            "measurement-direction", MEASUREMENT_DIRECTION);

    public static final Map<String, String> TRANSITION_ENTITIES = Map.of(
            "job", "job",
            "review", "review",
            "publication", "publication");

    public record DomainSeed(
            String domainType,
            String domainKey,
            String code,
            String labelKey,
            String tone,
            String icon,
            int order,
            boolean selectable,
            List<String> visibleFor) {
    }

    /**
     * Backend-defined option set. STATUS and ENUM sets are code-locked; the
     * legacy SEVERITY/UNIT/YES_NO catalogue sets are also locked but keep
     * {@code set_kind='CHECKLIST'} because issue fields reference them as
     * option/unit sets.
     */
    public record SetSeed(
            String code,
            String domainKey,
            String kind,
            boolean codeLocked,
            String name,
            int sortOrder) {
    }

    public record TransitionSeed(
            String entity,
            String fromCode,
            String toCode,
            String role) {
    }

    public static final List<DomainSeed> DOMAINS = buildDomains();
    public static final List<SetSeed> SETS = buildSets();
    public static final List<TransitionSeed> TRANSITIONS = buildTransitions();
    private static final Map<String, SetSeed> SETS_BY_DOMAIN = buildSetsByDomain();
    private static final Map<String, SetSeed> SETS_BY_CODE = buildSetsByCode();

    private ReferenceTaxonomy() {
    }

    public static List<String> jobStatusCodes() {
        return codes(JobStatus.values());
    }

    public static List<String> reviewStatusCodes() {
        return codes(ReviewStatus.values());
    }

    public static List<String> publicationStatusCodes() {
        return codes(PublicationStatus.values());
    }

    public static List<String> severityCodes() {
        return codes(Severity.values());
    }

    public static List<String> resultCodes() {
        return codes(ResultCode.values());
    }

    public static List<String> gradeCodes() {
        return codes(Grade.values());
    }

    public static List<String> unitCodes() {
        return codes(MeasurementUnit.values());
    }

    public static List<String> evidenceTypeCodes() {
        return codes(EvidenceType.values());
    }

    private static List<String> codes(Enum<?>[] values) {
        List<String> codes = new ArrayList<>(values.length);
        for (Enum<?> value : values) {
            codes.add(value.name());
        }
        return List.copyOf(codes);
    }

    private static List<DomainSeed> buildDomains() {
        List<DomainSeed> rows = new ArrayList<>();

        // ------------------------------------------------------------- statuses
        rows.add(status(JOB_STATUS, JobStatus.DRAFT, "status.draft", "neutral", ALL));
        rows.add(status(JOB_STATUS, JobStatus.SCHEDULED, "statusScheduled", "info", ALL));
        rows.add(status(JOB_STATUS, JobStatus.ASSIGNED, "statusAssigned", "info", ALL));
        rows.add(status(JOB_STATUS, JobStatus.IN_PROGRESS, "statusInProgress", "warning", ALL));
        rows.add(status(JOB_STATUS, JobStatus.PENDING_REVIEW, "jobsStatusPendingReview", "warning", ALL));
        rows.add(status(JOB_STATUS, JobStatus.APPROVED, "jobsStatusApproved", "success", ALL));
        rows.add(status(JOB_STATUS, JobStatus.PUBLISHED, "jobsStatusPublished", "success", ALL));
        rows.add(status(JOB_STATUS, JobStatus.REJECTED, "jobsStatusRejected", "danger", ALL));
        rows.add(status(JOB_STATUS, JobStatus.CANCELLED, "statusCancelled", "neutral", ALL));

        rows.add(status(REVIEW_STATUS, ReviewStatus.NOT_SUBMITTED, "statusNotSubmitted", "neutral", ALL));
        rows.add(status(REVIEW_STATUS, ReviewStatus.PENDING_REVIEW, "jobsStatusPendingReview", "warning", ALL));
        rows.add(status(REVIEW_STATUS, ReviewStatus.APPROVED, "jobsStatusApproved", "success", ALL));
        rows.add(status(REVIEW_STATUS, ReviewStatus.REJECTED, "jobsStatusRejected", "danger", ALL));

        rows.add(status(PUBLICATION_STATUS, PublicationStatus.UNPUBLISHED, "notPublished", "neutral", ALL));
        rows.add(status(PUBLICATION_STATUS, PublicationStatus.PUBLISHED, "published", "success", ALL));
        rows.add(status(PUBLICATION_STATUS, PublicationStatus.REVOKED, "linkRevoked", "danger", ALL));
        rows.add(status(PUBLICATION_STATUS, PublicationStatus.PENDING_CONSENT, "linkPendingConsent", "warning", ALL));
        rows.add(status(PUBLICATION_STATUS, PublicationStatus.ACTIVE, "active", "success", ALL));

        rows.add(status(DOCUMENT_STATUS, DocumentStatus.PENDING, "documentStatusPending", "warning", ALL));
        rows.add(status(DOCUMENT_STATUS, DocumentStatus.READY, "documentStatusReady", "success", ALL));
        rows.add(status(DOCUMENT_STATUS, DocumentStatus.FAILED, "documentStatusFailed", "danger", ALL));

        rows.add(status(SYNC_STATUS, SyncStatus.ONLINE, "technicianSyncOnline", "success", ALL));
        rows.add(status(SYNC_STATUS, SyncStatus.OFFLINE, "technicianSyncOffline", "neutral", ALL));
        rows.add(status(SYNC_STATUS, SyncStatus.PENDING, "technicianSyncPending", "warning", ALL));
        rows.add(status(SYNC_STATUS, SyncStatus.SYNCING, "technicianSyncStateSyncing", "info", ALL));
        rows.add(status(SYNC_STATUS, SyncStatus.CONFLICT, "technicianSyncStateConflict", "danger", ALL));
        rows.add(status(SYNC_STATUS, SyncStatus.FAILED, "technicianSyncStateFailed", "danger", ALL));

        rows.add(status(EVIDENCE_STATUS, EvidenceStatus.PENDING, "evidenceStatusPending", "warning", ALL));
        rows.add(status(EVIDENCE_STATUS, EvidenceStatus.UPLOADED, "evidenceStatusUploaded", "info", ALL));
        rows.add(status(EVIDENCE_STATUS, EvidenceStatus.VERIFIED, "evidenceStatusVerified", "success", ALL));
        rows.add(status(EVIDENCE_STATUS, EvidenceStatus.DELETED, "evidenceStatusDeleted", "neutral", ALL));

        rows.add(status(TEMPLATE_STATUS, TemplateStatus.DRAFT, "status.draft", "neutral", PLATFORM_WORKSHOP));
        rows.add(status(TEMPLATE_STATUS, TemplateStatus.PENDING_APPROVAL, "status.pendingApproval", "warning", PLATFORM_WORKSHOP));
        rows.add(status(TEMPLATE_STATUS, TemplateStatus.PUBLISHED, "published", "success", PLATFORM_WORKSHOP));
        rows.add(status(TEMPLATE_STATUS, TemplateStatus.RETIRED, "retired", "neutral", PLATFORM_WORKSHOP));

        // Platform Admin taxonomy status maps mirrored from the client widgets.
        rows.add(status(WORKSHOP_STATUS, WorkshopStatus.ACTIVE, "status.workshop.active", "success", PLATFORM));
        rows.add(status(WORKSHOP_STATUS, WorkshopStatus.INACTIVE, "status.workshop.inactive", "neutral", PLATFORM));
        rows.add(status(WORKSHOP_STATUS, WorkshopStatus.STANDBY, "status.workshop.standby", "warning", PLATFORM));
        rows.add(status(WORKSHOP_STATUS, WorkshopStatus.RETIRED, "status.workshop.retired", "danger", PLATFORM));
        rows.add(status(WORKSHOP_STATUS, WorkshopStatus.DEPOT_HUB, "status.workshop.depotHub", "info", PLATFORM));
        rows.add(status(WORKSHOP_STATUS, WorkshopStatus.DISABLED, "status.disabled", "danger", PLATFORM));
        rows.add(status(WORKSHOP_STATUS, WorkshopStatus.DRAFT, "status.draft", "warning", PLATFORM));
        rows.add(status(WORKSHOP_STATUS, WorkshopStatus.PUBLISHED, "status.published", "success", PLATFORM));

        rows.add(status(CHECKLIST_STATUS, ChecklistStatus.ACTIVE, "checklist.status.active", "success", PLATFORM));
        rows.add(status(CHECKLIST_STATUS, ChecklistStatus.DRAFT, "checklist.status.draft", "warning", PLATFORM));
        rows.add(status(CHECKLIST_STATUS, ChecklistStatus.PUBLISHED, "checklist.status.published", "success", PLATFORM));
        rows.add(status(CHECKLIST_STATUS, ChecklistStatus.RETIRED, "checklist.status.retired", "neutral", PLATFORM));
        rows.add(status(CHECKLIST_STATUS, ChecklistStatus.REVIEW, "checklist.status.review", "warning", PLATFORM));
        rows.add(status(CHECKLIST_STATUS, ChecklistStatus.IN_REVIEW, "checklist.status.review", "warning", PLATFORM));
        rows.add(status(CHECKLIST_STATUS, ChecklistStatus.PENDING, "checklist.status.review", "warning", PLATFORM));

        rows.add(status(HEALTH_STATUS, HealthStatus.HEALTHY, "checklist.health.severityBadgeHealthy", "success", PLATFORM));
        rows.add(status(HEALTH_STATUS, HealthStatus.WARNING, "checklist.health.severityBadgeWarning", "warning", PLATFORM));
        rows.add(status(HEALTH_STATUS, HealthStatus.ERROR, "checklist.health.severityBadgeError", "danger", PLATFORM));
        rows.add(status(HEALTH_STATUS, HealthStatus.OK, "checklist.health.severityBadgeHealthy", "success", PLATFORM));
        rows.add(status(HEALTH_STATUS, HealthStatus.UNHEALTHY, "checklist.health.severityBadgeError", "danger", PLATFORM));

        // PENDING and FAILED already exist in document-status; only DISABLED is new.
        rows.add(status(PLATFORM_CHIP_STATUS, PlatformChipStatus.DISABLED, "status.disabled", "danger", PLATFORM));

        // Delivery and consent states rendered by the report screen.
        rows.add(status(DELIVERY_STATUS, DeliveryStatus.QUEUED, "deliveryStatusQueued", "neutral", ALL));
        rows.add(status(DELIVERY_STATUS, DeliveryStatus.SENT, "deliveryStatusSent", "info", ALL));
        rows.add(status(DELIVERY_STATUS, DeliveryStatus.DELIVERED, "deliveryStatusDelivered", "success", ALL));
        rows.add(status(DELIVERY_STATUS, DeliveryStatus.FAILED, "deliveryStatusFailed", "danger", ALL));
        rows.add(status(DELIVERY_STATUS, DeliveryStatus.RETRY_PENDING, "deliveryStatusRetryPending", "warning", ALL));
        rows.add(status(DELIVERY_STATUS, DeliveryStatus.DEAD_LETTER, "deliveryStatusDeadLetter", "danger", ALL));

        rows.add(status(CONSENT_STATUS, ConsentStatus.GRANTED, "consentGranted", "success", ALL));
        rows.add(status(CONSENT_STATUS, ConsentStatus.NOT_GRANTED, "consentNotGranted", "warning", ALL));

        rows.add(status(TRANSLATION_STATUS, TranslationStatus.DRAFT, "status.language.draft", "neutral", PLATFORM));
        rows.add(status(TRANSLATION_STATUS, TranslationStatus.TRANSLATING, "status.language.translating", "info", PLATFORM));
        rows.add(status(TRANSLATION_STATUS, TranslationStatus.REVIEW, "status.language.review", "warning", PLATFORM));
        rows.add(status(TRANSLATION_STATUS, TranslationStatus.LIVE, "status.language.live", "success", PLATFORM));
        rows.add(status(TRANSLATION_STATUS, TranslationStatus.RETIRED, "status.language.retired", "neutral", PLATFORM));

        rows.add(status(DOCUMENT_TYPE_STATUS, DocumentTypeStatus.ACTIVE, "status.content.active", "success", PLATFORM));
        rows.add(status(DOCUMENT_TYPE_STATUS, DocumentTypeStatus.DRAFT, "status.content.draft", "warning", PLATFORM));
        rows.add(status(DOCUMENT_TYPE_STATUS, DocumentTypeStatus.RETIRED, "status.language.retired", "neutral", PLATFORM));

        // ---------------------------------------------------------------- enums
        rows.add(enumRow(ROLE, Role.PLATFORM_ADMIN, "role.platformAdmin", "info", PLATFORM));
        rows.add(enumRow(ROLE, Role.WORKSHOP_ADMIN, "role.workshopAdmin", "info", PLATFORM_WORKSHOP));
        rows.add(enumRow(ROLE, Role.TECHNICIAN, "role.technician", "neutral", ALL));

        rows.add(enumRow(SEVERITY, Severity.MINOR, "minor", "neutral", ALL));
        rows.add(enumRow(SEVERITY, Severity.MODERATE, "moderate", "warning", ALL));
        rows.add(enumRow(SEVERITY, Severity.MAJOR, "major", "danger", ALL));
        rows.add(enumRow(SEVERITY, Severity.SAFETY_CRITICAL, "safetyCritical", "danger", ALL));

        rows.add(enumRow(RESULT, ResultCode.NO_ISSUE_OBSERVED, "noIssueObserved", "success", ALL));
        rows.add(enumRow(RESULT, ResultCode.ATTENTION_RECOMMENDED, "attentionRecommended", "warning", ALL));
        rows.add(enumRow(RESULT, ResultCode.DEFECT_FOUND, "defectFound", "danger", ALL));
        // Derived/report states: visible in reports but not user assessment choices.
        rows.add(enumRow(RESULT, ResultCode.NOT_CHECKED, "notChecked", "neutral", ALL, false));
        rows.add(enumRow(RESULT, ResultCode.NOT_APPLICABLE, "notApplicable", "neutral", ALL, false));
        rows.add(enumRow(RESULT, ResultCode.COULD_NOT_VERIFY, "couldNotVerify", "warning", ALL, false));

        rows.add(enumRow(GRADE, Grade.A, "gradeA", "success", ALL));
        rows.add(enumRow(GRADE, Grade.B, "gradeB", "info", ALL));
        rows.add(enumRow(GRADE, Grade.C, "gradeC", "warning", ALL));
        rows.add(enumRow(GRADE, Grade.D, "gradeD", "danger", ALL));

        rows.add(enumRow(MEASUREMENT_UNIT, MeasurementUnit.MM, "unitMM", "neutral", ALL));
        rows.add(enumRow(MEASUREMENT_UNIT, MeasurementUnit.UM, "unitUM", "neutral", ALL));
        rows.add(enumRow(MEASUREMENT_UNIT, MeasurementUnit.V, "unitV", "neutral", ALL));
        rows.add(enumRow(MEASUREMENT_UNIT, MeasurementUnit.PSI, "unitPSI", "neutral", ALL));
        rows.add(enumRow(MEASUREMENT_UNIT, MeasurementUnit.DEG_C, "unitDegC", "neutral", ALL));
        rows.add(enumRow(MEASUREMENT_UNIT, MeasurementUnit.PERCENT, "unitPERCENT", "neutral", ALL));
        rows.add(enumRow(MEASUREMENT_UNIT, MeasurementUnit.A, "unitA", "neutral", ALL));
        rows.add(enumRow(MEASUREMENT_UNIT, MeasurementUnit.CCA, "unitCCA", "neutral", ALL));
        rows.add(enumRow(MEASUREMENT_UNIT, MeasurementUnit.RPM, "unitRPM", "neutral", ALL));
        rows.add(enumRow(MEASUREMENT_UNIT, MeasurementUnit.NM, "unitNM", "neutral", ALL));
        rows.add(enumRow(MEASUREMENT_UNIT, MeasurementUnit.BAR, "unitBAR", "neutral", ALL));
        rows.add(enumRow(MEASUREMENT_UNIT, MeasurementUnit.KM, "unitKM", "neutral", ALL));

        rows.add(enumRow(EVIDENCE_TYPE, EvidenceType.PHOTO, "attachments", "info", ALL));
        rows.add(enumRow(EVIDENCE_TYPE, EvidenceType.VIDEO, "technicianVideo", "info", ALL));
        rows.add(enumRow(EVIDENCE_TYPE, EvidenceType.DOCUMENT, "technicianDocument", "info", ALL));

        rows.add(enumRow(CONTENT_TYPE, ContentType.CATEGORY, "label.entityType.category", "neutral", PLATFORM));
        rows.add(enumRow(CONTENT_TYPE, ContentType.ITEM, "label.entityType.item", "neutral", PLATFORM));
        rows.add(enumRow(CONTENT_TYPE, ContentType.OPTION_SET, "activity.entity.optionSet", "neutral", PLATFORM));
        rows.add(enumRow(CONTENT_TYPE, ContentType.OPTION_VALUE, "activity.entity.optionValue", "neutral", PLATFORM));
        rows.add(enumRow(CONTENT_TYPE, ContentType.TEMPLATE, "label.entityType.template", "neutral", PLATFORM));
        rows.add(enumRow(CONTENT_TYPE, ContentType.DOCUMENT_TYPE, "activity.entity.documentType", "neutral", PLATFORM));
        rows.add(enumRow(CONTENT_TYPE, ContentType.ISSUE_FIELD, "section.item.issueFields", "neutral", PLATFORM));

        rows.add(enumRow(INPUT_TYPE, InputType.SELECT, "label.inputType.select", "neutral", PLATFORM));
        rows.add(enumRow(INPUT_TYPE, InputType.MULTI_SELECT, "label.inputType.multiSelect", "neutral", PLATFORM));
        rows.add(enumRow(INPUT_TYPE, InputType.NUMBER, "label.inputType.number", "neutral", PLATFORM));
        rows.add(enumRow(INPUT_TYPE, InputType.BOOLEAN, "label.inputType.boolean", "neutral", PLATFORM));
        rows.add(enumRow(INPUT_TYPE, InputType.TEXT, "label.inputType.text", "neutral", PLATFORM));

        rows.add(enumRow(MEASUREMENT_DIRECTION, MeasurementDirection.HIGHER_IS_BETTER,
                "label.measureDirection.higherIsBetter", "neutral", PLATFORM));
        rows.add(enumRow(MEASUREMENT_DIRECTION, MeasurementDirection.LOWER_IS_BETTER,
                "label.measureDirection.lowerIsBetter", "neutral", PLATFORM));

        return List.copyOf(rows);
    }

    private static List<SetSeed> buildSets() {
        return List.of(
                new SetSeed("JOB_STATUS", JOB_STATUS, "STATUS", true, "Job Status", 101),
                new SetSeed("REVIEW_STATUS", REVIEW_STATUS, "STATUS", true, "Review Status", 102),
                new SetSeed("PUBLICATION_STATUS", PUBLICATION_STATUS, "STATUS", true,
                        "Publication Status", 103),
                new SetSeed("DOCUMENT_STATUS", DOCUMENT_STATUS, "STATUS", true,
                        "Document Status", 104),
                new SetSeed("SYNC_STATUS", SYNC_STATUS, "STATUS", true, "Sync Status", 105),
                new SetSeed("EVIDENCE_STATUS", EVIDENCE_STATUS, "STATUS", true,
                        "Evidence Status", 106),
                new SetSeed("TEMPLATE_STATUS", TEMPLATE_STATUS, "STATUS", true,
                        "Template Status", 107),
                new SetSeed("WORKSHOP_STATUS", WORKSHOP_STATUS, "STATUS", true,
                        "Workshop Status", 108),
                new SetSeed("CHECKLIST_STATUS", CHECKLIST_STATUS, "STATUS", true,
                        "Checklist Status", 109),
                new SetSeed("HEALTH_STATUS", HEALTH_STATUS, "STATUS", true, "Health Status", 110),
                new SetSeed("PLATFORM_CHIP_STATUS", PLATFORM_CHIP_STATUS, "STATUS", true,
                        "Platform Chip Status", 111),
                new SetSeed("DELIVERY_STATUS", DELIVERY_STATUS, "STATUS", true,
                        "Delivery Status", 112),
                new SetSeed("CONSENT_STATUS", CONSENT_STATUS, "STATUS", true,
                        "Consent Status", 113),
                new SetSeed("TRANSLATION_STATUS", TRANSLATION_STATUS, "STATUS", true,
                        "Translation Status", 114),
                new SetSeed("DOCUMENT_TYPE_STATUS", DOCUMENT_TYPE_STATUS, "STATUS", true,
                        "Document Type Status", 115),
                new SetSeed("ROLE", ROLE, "ENUM", true, "Role", 201),
                new SetSeed("RESULT", RESULT, "ENUM", true, "Result", 202),
                new SetSeed("GRADE", GRADE, "ENUM", true, "Grade", 203),
                new SetSeed("INPUT_TYPE", INPUT_TYPE, "ENUM", true, "Input Type", 204),
                new SetSeed("EVIDENCE_TYPE", EVIDENCE_TYPE, "ENUM", true, "Evidence Type", 205),
                new SetSeed("CONTENT_TYPE", CONTENT_TYPE, "ENUM", true, "Content Type", 206),
                new SetSeed("MEASUREMENT_DIRECTION", MEASUREMENT_DIRECTION, "ENUM", true,
                        "Measurement Direction", 207),
                // Issue fields reference these as option/unit sets, so they stay
                // CHECKLIST kind while their codes remain backend-owned.
                new SetSeed("SEVERITY", SEVERITY, "CHECKLIST", true, "Severity", 5),
                new SetSeed("UNIT", MEASUREMENT_UNIT, "CHECKLIST", true, "Unit", 9),
                new SetSeed("YES_NO", "yes-no", "CHECKLIST", true, "Yes / No", 10));
    }

    /** The set that owns a reference domain key, or {@code null}. */
    public static SetSeed setForDomain(String domainKey) {
        return SETS_BY_DOMAIN.get(domainKey);
    }

    /** The set definition for an option-set code, or {@code null}. */
    public static SetSeed setForCode(String code) {
        return SETS_BY_CODE.get(code);
    }

    private static Map<String, SetSeed> buildSetsByDomain() {
        Map<String, SetSeed> result = new LinkedHashMap<>();
        for (SetSeed seed : SETS) {
            result.put(seed.domainKey(), seed);
        }
        return Map.copyOf(result);
    }

    private static Map<String, SetSeed> buildSetsByCode() {
        Map<String, SetSeed> result = new LinkedHashMap<>();
        for (SetSeed seed : SETS) {
            result.put(seed.code(), seed);
        }
        return Map.copyOf(result);
    }

    private static List<TransitionSeed> buildTransitions() {
        List<TransitionSeed> rows = new ArrayList<>();
        rows.add(new TransitionSeed("job", "DRAFT", "SCHEDULED", "WORKSHOP_ADMIN"));
        rows.add(new TransitionSeed("job", "DRAFT", "CANCELLED", "WORKSHOP_ADMIN"));
        rows.add(new TransitionSeed("job", "SCHEDULED", "ASSIGNED", "WORKSHOP_ADMIN"));
        rows.add(new TransitionSeed("job", "SCHEDULED", "CANCELLED", "WORKSHOP_ADMIN"));
        rows.add(new TransitionSeed("job", "ASSIGNED", "IN_PROGRESS", "TECHNICIAN"));
        rows.add(new TransitionSeed("job", "ASSIGNED", "CANCELLED", "WORKSHOP_ADMIN"));
        rows.add(new TransitionSeed("job", "IN_PROGRESS", "PENDING_REVIEW", "TECHNICIAN"));
        rows.add(new TransitionSeed("job", "IN_PROGRESS", "CANCELLED", "WORKSHOP_ADMIN"));
        rows.add(new TransitionSeed("job", "PENDING_REVIEW", "APPROVED", "WORKSHOP_ADMIN"));
        rows.add(new TransitionSeed("job", "PENDING_REVIEW", "REJECTED", "WORKSHOP_ADMIN"));
        rows.add(new TransitionSeed("job", "APPROVED", "PUBLISHED", "WORKSHOP_ADMIN"));
        rows.add(new TransitionSeed("job", "REJECTED", "IN_PROGRESS", "WORKSHOP_ADMIN"));

        rows.add(new TransitionSeed("review", "NOT_SUBMITTED", "PENDING_REVIEW", "TECHNICIAN"));
        rows.add(new TransitionSeed("review", "PENDING_REVIEW", "APPROVED", "WORKSHOP_ADMIN"));
        rows.add(new TransitionSeed("review", "PENDING_REVIEW", "REJECTED", "WORKSHOP_ADMIN"));
        rows.add(new TransitionSeed("review", "REJECTED", "PENDING_REVIEW", "WORKSHOP_ADMIN"));

        rows.add(new TransitionSeed("publication", "UNPUBLISHED", "PUBLISHED", "WORKSHOP_ADMIN"));
        rows.add(new TransitionSeed("publication", "PUBLISHED", "UNPUBLISHED", "WORKSHOP_ADMIN"));
        rows.add(new TransitionSeed("publication", "PUBLISHED", "REVOKED", "WORKSHOP_ADMIN"));
        return List.copyOf(rows);
    }

    private static DomainSeed status(String domainKey, Enum<?> code, String labelKey,
                                     String tone, List<String> visibleFor) {
        return domain("STATUS", domainKey, code, labelKey, tone, visibleFor);
    }

    private static DomainSeed enumRow(String domainKey, Enum<?> code, String labelKey,
                                      String tone, List<String> visibleFor) {
        return domain("ENUM", domainKey, code, labelKey, tone, visibleFor, true);
    }

    private static DomainSeed enumRow(String domainKey, Enum<?> code, String labelKey,
                                      String tone, List<String> visibleFor, boolean selectable) {
        return domain("ENUM", domainKey, code, labelKey, tone, visibleFor, selectable);
    }

    private static DomainSeed domain(String type, String domainKey, Enum<?> code,
                                     String labelKey, String tone, List<String> visibleFor) {
        return domain(type, domainKey, code, labelKey, tone, visibleFor, true);
    }

    private static DomainSeed domain(String type, String domainKey, Enum<?> code,
                                     String labelKey, String tone, List<String> visibleFor,
                                     boolean selectable) {
        int order = Integer.parseInt(String.valueOf(code.ordinal())) + 1;
        return new DomainSeed(type, domainKey, code.name(), labelKey, tone,
                "circle", order, selectable, visibleFor);
    }

    /** Allowed-next codes for a status row, derived from the transition graph. */
    public static List<String> allowedNext(String domainKey, String code) {
        String entity = switch (domainKey) {
            case JOB_STATUS -> "job";
            case REVIEW_STATUS -> "review";
            case PUBLICATION_STATUS -> "publication";
            default -> null;
        };
        if (entity == null) {
            return List.of();
        }
        List<String> next = new ArrayList<>();
        for (TransitionSeed transition : TRANSITIONS) {
            if (transition.entity().equals(entity) && transition.fromCode().equals(code)
                    && !next.contains(transition.toCode())) {
                next.add(transition.toCode());
            }
        }
        return List.copyOf(next);
    }

    /** Seed rows keyed by domain key, used by tests. */
    public static Map<String, List<DomainSeed>> byDomainKey() {
        Map<String, List<DomainSeed>> grouped = new LinkedHashMap<>();
        for (DomainSeed row : DOMAINS) {
            grouped.computeIfAbsent(row.domainKey(), ignored -> new ArrayList<>()).add(row);
        }
        return grouped;
    }
}
