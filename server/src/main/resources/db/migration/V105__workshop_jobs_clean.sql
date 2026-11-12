-- TrueReport rebuilt backend - workshop jobs clean schema.
-- These tables are owned by the Workshop Admin job domain and do not depend on the
-- legacy V1-V18 job/report tables. Legacy tables remain only for the reference
-- application. IDs are UUIDv7 strings for portability across H2 and MySQL 8.4.

CREATE TABLE platform_jobs (
    id VARCHAR(36) NOT NULL,
    workshop_id VARCHAR(36) NOT NULL,
    reference VARCHAR(40) NOT NULL,
    status VARCHAR(32) NOT NULL,
    review_status VARCHAR(32) NOT NULL,
    publication_status VARCHAR(20) NOT NULL,
    template_version_id VARCHAR(36) NOT NULL,
    assigned_technician_id VARCHAR(36) NULL,
    customer_name VARCHAR(512) NOT NULL,
    customer_phone VARCHAR(512) NOT NULL,
    customer_email VARCHAR(512) NULL,
    vehicle_vin VARCHAR(512) NOT NULL,
    vehicle_make VARCHAR(100) NOT NULL,
    vehicle_model VARCHAR(100) NOT NULL,
    vehicle_year INT NOT NULL,
    vehicle_plate VARCHAR(512) NOT NULL,
    odometer_value INT NOT NULL,
    odometer_unit VARCHAR(8) NOT NULL,
    transmission VARCHAR(40) NOT NULL,
    fuel_type VARCHAR(40) NOT NULL,
    preferred_language VARCHAR(8) NOT NULL DEFAULT 'en',
    scheduled_at DATETIME(6) NULL,
    started_at DATETIME(6) NULL,
    completed_at DATETIME(6) NULL,
    approved_at DATETIME(6) NULL,
    published_at DATETIME(6) NULL,
    cancelled_at DATETIME(6) NULL,
    approved_by VARCHAR(36) NULL,
    cancelled_by VARCHAR(36) NULL,
    cancel_reason VARCHAR(255) NULL,
    score INT NULL,
    grade_code VARCHAR(5) NULL,
    safety_cap_applied BOOLEAN NOT NULL DEFAULT FALSE,
    safety_cap_reason VARCHAR(255) NULL,
    consent_granted BOOLEAN NOT NULL DEFAULT FALSE,
    signature_present BOOLEAN NOT NULL DEFAULT FALSE,
    created_by VARCHAR(36) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_platform_jobs PRIMARY KEY (id),
    CONSTRAINT uq_platform_job_reference UNIQUE (workshop_id, reference),
    CONSTRAINT fk_platform_job_template_version FOREIGN KEY (template_version_id)
        REFERENCES platform_template_versions (id),
    CONSTRAINT ck_platform_job_status CHECK (status IN (
        'DRAFT', 'SCHEDULED', 'ASSIGNED', 'IN_PROGRESS', 'PENDING_REVIEW',
        'APPROVED', 'PUBLISHED', 'REJECTED', 'CANCELLED')),
    CONSTRAINT ck_platform_job_review_status CHECK (review_status IN (
        'NOT_SUBMITTED', 'PENDING_REVIEW', 'APPROVED', 'REJECTED')),
    CONSTRAINT ck_platform_job_publication_status CHECK (publication_status IN (
        'UNPUBLISHED', 'PUBLISHED', 'REVOKED'))
);

CREATE TABLE platform_job_assignments (
    id VARCHAR(36) NOT NULL,
    job_id VARCHAR(36) NOT NULL,
    technician_id VARCHAR(36) NOT NULL,
    assigned_by VARCHAR(36) NOT NULL,
    assigned_at DATETIME(6) NOT NULL,
    unassigned_at DATETIME(6) NULL,
    reason VARCHAR(255) NULL,
    CONSTRAINT pk_platform_job_assignments PRIMARY KEY (id),
    CONSTRAINT fk_platform_job_assignment_job FOREIGN KEY (job_id)
        REFERENCES platform_jobs (id)
);

CREATE TABLE platform_job_status_history (
    id VARCHAR(36) NOT NULL,
    job_id VARCHAR(36) NOT NULL,
    from_status VARCHAR(32) NULL,
    to_status VARCHAR(32) NOT NULL,
    actor_id VARCHAR(36) NULL,
    occurred_at DATETIME(6) NOT NULL,
    reason VARCHAR(255) NULL,
    CONSTRAINT pk_platform_job_status_history PRIMARY KEY (id),
    CONSTRAINT fk_platform_job_history_job FOREIGN KEY (job_id)
        REFERENCES platform_jobs (id)
);

CREATE TABLE platform_job_results (
    id VARCHAR(36) NOT NULL,
    job_id VARCHAR(36) NOT NULL,
    item_version_id VARCHAR(36) NOT NULL,
    result_code VARCHAR(40) NOT NULL,
    score INT NULL,
    evidence_photo_count INT NOT NULL DEFAULT 0,
    evidence_video_count INT NOT NULL DEFAULT 0,
    signature_present BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at DATETIME(6) NULL,
    issue_values_json TEXT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_platform_job_results PRIMARY KEY (id),
    CONSTRAINT uq_platform_job_result UNIQUE (job_id, item_version_id),
    CONSTRAINT fk_platform_job_result_job FOREIGN KEY (job_id)
        REFERENCES platform_jobs (id),
    CONSTRAINT fk_platform_job_result_item_version FOREIGN KEY (item_version_id)
        REFERENCES platform_item_versions (id),
    CONSTRAINT ck_platform_job_result_score CHECK (score IS NULL OR score BETWEEN 0 AND 100)
);

CREATE TABLE platform_job_approvals (
    id VARCHAR(36) NOT NULL,
    job_id VARCHAR(36) NOT NULL,
    approved_by VARCHAR(36) NOT NULL,
    approved_at DATETIME(6) NOT NULL,
    decision VARCHAR(20) NOT NULL,
    reason VARCHAR(255) NULL,
    CONSTRAINT pk_platform_job_approvals PRIMARY KEY (id),
    CONSTRAINT fk_platform_job_approval_job FOREIGN KEY (job_id)
        REFERENCES platform_jobs (id),
    CONSTRAINT ck_platform_job_approval_decision CHECK (decision IN ('APPROVED', 'REJECTED'))
);

CREATE TABLE platform_report_versions (
    id VARCHAR(36) NOT NULL,
    job_id VARCHAR(36) NOT NULL,
    version_no INT NOT NULL,
    snapshot_json TEXT NOT NULL,
    snapshot_hash VARCHAR(64) NOT NULL,
    created_by VARCHAR(36) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_platform_report_versions PRIMARY KEY (id),
    CONSTRAINT uq_platform_report_version UNIQUE (job_id, version_no),
    CONSTRAINT fk_platform_report_version_job FOREIGN KEY (job_id)
        REFERENCES platform_jobs (id)
);

CREATE TABLE platform_public_links (
    id VARCHAR(36) NOT NULL,
    job_id VARCHAR(36) NOT NULL,
    report_version_id VARCHAR(36) NULL,
    token_hash VARCHAR(64) NOT NULL,
    token_encrypted VARCHAR(512) NULL,
    status VARCHAR(20) NOT NULL,
    pdf_download_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    activated_at DATETIME(6) NULL,
    revoked_at DATETIME(6) NULL,
    revocation_reason VARCHAR(255) NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_platform_public_links PRIMARY KEY (id),
    CONSTRAINT uq_platform_public_link_token UNIQUE (token_hash),
    CONSTRAINT fk_platform_public_link_job FOREIGN KEY (job_id)
        REFERENCES platform_jobs (id),
    CONSTRAINT fk_platform_public_link_version FOREIGN KEY (report_version_id)
        REFERENCES platform_report_versions (id),
    CONSTRAINT ck_platform_public_link_status CHECK (status IN (
        'PENDING', 'ACTIVE', 'REVOKED'))
);

CREATE TABLE platform_report_documents (
    id VARCHAR(36) NOT NULL,
    report_version_id VARCHAR(36) NOT NULL,
    document_type_code VARCHAR(60) NOT NULL,
    language VARCHAR(8) NOT NULL,
    storage_key VARCHAR(512) NULL,
    mime VARCHAR(100) NULL,
    bytes BIGINT NULL,
    status VARCHAR(20) NOT NULL,
    generated_at DATETIME(6) NULL,
    error VARCHAR(1000) NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_platform_report_documents PRIMARY KEY (id),
    CONSTRAINT uq_platform_report_document UNIQUE (report_version_id, document_type_code, language),
    CONSTRAINT fk_platform_report_document_version FOREIGN KEY (report_version_id)
        REFERENCES platform_report_versions (id),
    CONSTRAINT ck_platform_report_document_language CHECK (language IN ('en', 'ar')),
    CONSTRAINT ck_platform_report_document_status CHECK (status IN (
        'PENDING', 'GENERATING', 'READY', 'FAILED'))
);

CREATE TABLE platform_notifications (
    id VARCHAR(36) NOT NULL,
    workshop_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    type VARCHAR(60) NOT NULL,
    payload_json TEXT NULL,
    read_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_platform_notifications PRIMARY KEY (id)
);

CREATE INDEX ix_platform_jobs_workshop_status ON platform_jobs (workshop_id, status, created_at);
CREATE INDEX ix_platform_jobs_workshop_updated ON platform_jobs (workshop_id, updated_at);
CREATE INDEX ix_platform_jobs_technician ON platform_jobs (assigned_technician_id, status);
CREATE INDEX ix_platform_job_assignments_job ON platform_job_assignments (job_id, assigned_at);
CREATE INDEX ix_platform_job_history_job ON platform_job_status_history (job_id, occurred_at);
CREATE INDEX ix_platform_job_results_job ON platform_job_results (job_id);
CREATE INDEX ix_platform_job_approvals_job ON platform_job_approvals (job_id, approved_at);
CREATE INDEX ix_platform_report_versions_job ON platform_report_versions (job_id, version_no);
CREATE INDEX ix_platform_public_links_job ON platform_public_links (job_id, status);
CREATE INDEX ix_platform_report_documents_version ON platform_report_documents (report_version_id, status);
CREATE INDEX ix_platform_notifications_user ON platform_notifications (workshop_id, user_id, read_at);
