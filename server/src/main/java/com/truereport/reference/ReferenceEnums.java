package com.truereport.reference;

/**
 * Codes owned by the platform taxonomy. These are the exact values already used
 * by the job, review, publication, document, technician and content services;
 * the enum names are the wire codes (no renames).
 */
public final class ReferenceEnums {

    private ReferenceEnums() {
    }

    public enum JobStatus {
        DRAFT, SCHEDULED, ASSIGNED, IN_PROGRESS, PENDING_REVIEW,
        APPROVED, PUBLISHED, REJECTED, CANCELLED
    }

    public enum ReviewStatus {
        NOT_SUBMITTED, PENDING_REVIEW, APPROVED, REJECTED
    }

    public enum PublicationStatus {
        UNPUBLISHED, PUBLISHED, REVOKED, PENDING_CONSENT, ACTIVE
    }

    public enum DocumentStatus {
        PENDING, READY, FAILED
    }

    public enum SyncStatus {
        ONLINE, OFFLINE, PENDING, SYNCING, CONFLICT, FAILED
    }

    public enum EvidenceStatus {
        PENDING, UPLOADED, VERIFIED, DELETED
    }

    public enum TemplateStatus {
        DRAFT, PENDING_APPROVAL, PUBLISHED, RETIRED
    }

    public enum WorkshopStatus {
        ACTIVE, INACTIVE, STANDBY, RETIRED, DEPOT_HUB,
        DISABLED, DRAFT, PUBLISHED
    }

    public enum ChecklistStatus {
        ACTIVE, DRAFT, PUBLISHED, RETIRED, REVIEW, IN_REVIEW, PENDING
    }

    public enum HealthStatus {
        HEALTHY, WARNING, ERROR, OK, UNHEALTHY
    }

    public enum PlatformChipStatus {
        PENDING, DISABLED, FAILED
    }

    public enum DeliveryStatus {
        QUEUED, SENT, DELIVERED, FAILED, RETRY_PENDING, DEAD_LETTER
    }

    public enum ConsentStatus {
        GRANTED, NOT_GRANTED
    }

    public enum ContentType {
        CATEGORY, ITEM, OPTION_SET, OPTION_VALUE, TEMPLATE, DOCUMENT_TYPE, ISSUE_FIELD
    }

    public enum TranslationStatus {
        DRAFT, TRANSLATING, REVIEW, LIVE, RETIRED
    }

    public enum InputType {
        SELECT, MULTI_SELECT, NUMBER, BOOLEAN, TEXT
    }

    public enum MeasurementDirection {
        HIGHER_IS_BETTER, LOWER_IS_BETTER
    }

    public enum DocumentTypeStatus {
        ACTIVE, DRAFT, RETIRED
    }

    public enum Role {
        PLATFORM_ADMIN, WORKSHOP_ADMIN, TECHNICIAN
    }

    public enum Severity {
        MINOR, MODERATE, MAJOR, SAFETY_CRITICAL
    }

    public enum ResultCode {
        NO_ISSUE_OBSERVED, ATTENTION_RECOMMENDED, DEFECT_FOUND,
        NOT_CHECKED, NOT_APPLICABLE, COULD_NOT_VERIFY
    }

    public enum Grade {
        A, B, C, D
    }

    public enum MeasurementUnit {
        MM, UM, V, PSI, DEG_C, PERCENT, A, CCA, RPM, NM, BAR, KM
    }

    public enum EvidenceType {
        PHOTO, VIDEO, DOCUMENT
    }
}
