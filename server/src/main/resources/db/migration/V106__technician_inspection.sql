-- TrueReport rebuilt backend - technician inspection execution on platform_* tables.
-- Adds the dynamic checklist snapshot, assessments, structured issue values,
-- measurements, evidence, signatures and offline sync conflicts. Portable across
-- H2 (MySQL mode) and MySQL 8.4.

ALTER TABLE platform_jobs ADD COLUMN vehicle_type VARCHAR(40) NULL;
ALTER TABLE platform_jobs ADD COLUMN service_type VARCHAR(40) NULL;
ALTER TABLE platform_jobs ADD COLUMN scope VARCHAR(40) NULL;
ALTER TABLE platform_jobs ADD COLUMN assessment_state VARCHAR(20) NOT NULL DEFAULT 'NOT_STARTED';
ALTER TABLE platform_jobs ADD COLUMN last_client_revision BIGINT NULL;

ALTER TABLE platform_jobs ADD CONSTRAINT ck_technician_job_assessment_state CHECK (
    assessment_state IN ('NOT_STARTED', 'IN_PROGRESS', 'COMPLETED'));

CREATE TABLE platform_job_checklists (
    id VARCHAR(36) NOT NULL,
    job_id VARCHAR(36) NOT NULL,
    template_version_id VARCHAR(36) NOT NULL,
    snapshot_json TEXT NOT NULL,
    snapshot_hash VARCHAR(64) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_platform_job_checklists PRIMARY KEY (id),
    CONSTRAINT uq_platform_job_checklist UNIQUE (job_id),
    CONSTRAINT fk_platform_job_checklist_job FOREIGN KEY (job_id)
        REFERENCES platform_jobs (id),
    CONSTRAINT fk_platform_job_checklist_template FOREIGN KEY (template_version_id)
        REFERENCES platform_template_versions (id)
);

CREATE TABLE platform_assessments (
    id VARCHAR(36) NOT NULL,
    job_id VARCHAR(36) NOT NULL,
    item_version_id VARCHAR(36) NOT NULL,
    item_code VARCHAR(60) NOT NULL,
    result_code VARCHAR(40) NOT NULL,
    severity_code VARCHAR(40) NULL,
    suggested_result_code VARCHAR(40) NULL,
    suggested_score INT NULL,
    score INT NULL,
    notes_en TEXT NULL,
    notes_ar TEXT NULL,
    reason_code VARCHAR(60) NULL,
    state VARCHAR(20) NOT NULL,
    client_revision BIGINT NULL,
    server_revision BIGINT NOT NULL DEFAULT 1,
    conflict_state VARCHAR(20) NOT NULL DEFAULT 'NONE',
    assessed_by VARCHAR(36) NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_platform_assessments PRIMARY KEY (id),
    CONSTRAINT uq_platform_assessment_item UNIQUE (job_id, item_code),
    CONSTRAINT fk_platform_assessment_job FOREIGN KEY (job_id)
        REFERENCES platform_jobs (id),
    CONSTRAINT fk_platform_assessment_item_version FOREIGN KEY (item_version_id)
        REFERENCES platform_item_versions (id),
    CONSTRAINT ck_technician_assessment_state CHECK (
        state IN ('NOT_STARTED', 'IN_PROGRESS', 'COMPLETE')),
    CONSTRAINT ck_technician_assessment_conflict CHECK (
        conflict_state IN ('NONE', 'OPEN', 'RESOLVED')),
    CONSTRAINT ck_technician_assessment_score CHECK (
        score IS NULL OR score BETWEEN 0 AND 100)
);

CREATE TABLE platform_assessment_issue_values (
    id VARCHAR(36) NOT NULL,
    assessment_id VARCHAR(36) NOT NULL,
    field_code VARCHAR(60) NOT NULL,
    value_index VARCHAR(40) NULL,
    option_value_code VARCHAR(60) NULL,
    numeric_value DECIMAL(12,3) NULL,
    unit_code VARCHAR(30) NULL,
    text_value TEXT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_platform_assessment_issue_values PRIMARY KEY (id),
    CONSTRAINT uq_platform_assessment_issue_value UNIQUE (
        assessment_id, field_code, value_index, option_value_code),
    CONSTRAINT fk_platform_issue_value_assessment FOREIGN KEY (assessment_id)
        REFERENCES platform_assessments (id)
);

CREATE TABLE platform_assessment_measurements (
    id VARCHAR(36) NOT NULL,
    assessment_id VARCHAR(36) NOT NULL,
    field_code VARCHAR(60) NOT NULL,
    value_index VARCHAR(40) NULL,
    numeric_value DECIMAL(12,3) NOT NULL,
    unit_code VARCHAR(30) NULL,
    band_id VARCHAR(36) NULL,
    derived_result_code VARCHAR(40) NULL,
    derived_score INT NULL,
    CONSTRAINT pk_platform_assessment_measurements PRIMARY KEY (id),
    CONSTRAINT uq_platform_assessment_measurement UNIQUE (
        assessment_id, field_code, value_index),
    CONSTRAINT fk_platform_measurement_assessment FOREIGN KEY (assessment_id)
        REFERENCES platform_assessments (id)
);

CREATE TABLE platform_evidence_assets (
    id VARCHAR(36) NOT NULL,
    job_id VARCHAR(36) NOT NULL,
    item_version_id VARCHAR(36) NOT NULL,
    item_code VARCHAR(60) NOT NULL,
    assessment_id VARCHAR(36) NULL,
    type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL,
    storage_key VARCHAR(512) NULL,
    normalized_key VARCHAR(512) NULL,
    mime VARCHAR(100) NOT NULL,
    bytes BIGINT NOT NULL,
    sha256 VARCHAR(64) NOT NULL,
    captured_at DATETIME(6) NOT NULL,
    capture_source VARCHAR(20) NOT NULL,
    device_id VARCHAR(120) NULL,
    width INT NULL,
    height INT NULL,
    duration_ms BIGINT NULL,
    poster_key VARCHAR(512) NULL,
    caption_en VARCHAR(500) NULL,
    caption_ar VARCHAR(500) NULL,
    quality_status VARCHAR(20) NOT NULL,
    quality_json TEXT NULL,
    uploaded_by VARCHAR(36) NULL,
    deleted_at DATETIME(6) NULL,
    deleted_by VARCHAR(36) NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_platform_evidence_assets PRIMARY KEY (id),
    CONSTRAINT fk_platform_evidence_job FOREIGN KEY (job_id)
        REFERENCES platform_jobs (id),
    CONSTRAINT fk_platform_evidence_item_version FOREIGN KEY (item_version_id)
        REFERENCES platform_item_versions (id),
    CONSTRAINT ck_technician_evidence_type CHECK (type IN ('PHOTO', 'VIDEO', 'DOCUMENT')),
    CONSTRAINT ck_technician_evidence_status CHECK (
        status IN ('PENDING', 'UPLOADED', 'VERIFIED', 'DELETED')),
    CONSTRAINT ck_technician_evidence_source CHECK (
        capture_source IN ('CAMERA', 'FILE', 'SCANNER', 'IMPORT'))
);

CREATE TABLE platform_evidence_derivatives (
    id VARCHAR(36) NOT NULL,
    asset_id VARCHAR(36) NOT NULL,
    kind VARCHAR(20) NOT NULL,
    storage_key VARCHAR(512) NOT NULL,
    mime VARCHAR(100) NOT NULL,
    bytes BIGINT NOT NULL,
    sha256 VARCHAR(64) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_platform_evidence_derivatives PRIMARY KEY (id),
    CONSTRAINT fk_platform_derivative_asset FOREIGN KEY (asset_id)
        REFERENCES platform_evidence_assets (id),
    CONSTRAINT ck_technician_derivative_kind CHECK (kind IN ('POSTER', 'THUMBNAIL', 'NORMALIZED'))
);

CREATE TABLE platform_job_signatures (
    id VARCHAR(36) NOT NULL,
    job_id VARCHAR(36) NOT NULL,
    signer_user_id VARCHAR(36) NOT NULL,
    signer_name VARCHAR(200) NOT NULL,
    signed_at DATETIME(6) NOT NULL,
    device_id VARCHAR(120) NOT NULL,
    method VARCHAR(20) NOT NULL,
    storage_key VARCHAR(512) NOT NULL,
    signature_hash VARCHAR(64) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_platform_job_signatures PRIMARY KEY (id),
    CONSTRAINT uq_platform_job_signature UNIQUE (job_id),
    CONSTRAINT fk_platform_signature_job FOREIGN KEY (job_id)
        REFERENCES platform_jobs (id),
    CONSTRAINT ck_technician_signature_method CHECK (
        method IN ('DRAWN', 'TYPED', 'PIN', 'DEVICE'))
);

CREATE TABLE platform_sync_conflicts (
    id VARCHAR(36) NOT NULL,
    job_id VARCHAR(36) NOT NULL,
    item_code VARCHAR(60) NOT NULL,
    client_revision BIGINT NULL,
    server_revision BIGINT NULL,
    server_payload_json TEXT NULL,
    client_payload_json TEXT NULL,
    state VARCHAR(20) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    resolved_at DATETIME(6) NULL,
    CONSTRAINT pk_platform_sync_conflicts PRIMARY KEY (id),
    CONSTRAINT fk_platform_sync_conflict_job FOREIGN KEY (job_id)
        REFERENCES platform_jobs (id),
    CONSTRAINT ck_technician_sync_conflict_state CHECK (state IN ('OPEN', 'RESOLVED'))
);

ALTER TABLE platform_job_results ADD COLUMN item_code VARCHAR(60) NULL;
ALTER TABLE platform_job_results ADD COLUMN assessment_id VARCHAR(36) NULL;
ALTER TABLE platform_job_results ADD COLUMN score_suggested INT NULL;
ALTER TABLE platform_job_results ADD COLUMN evidence_document_count INT NOT NULL DEFAULT 0;
ALTER TABLE platform_job_results ADD COLUMN version INT NOT NULL DEFAULT 0;

CREATE INDEX ix_platform_assessments_job_item
    ON platform_assessments (job_id, item_code);
CREATE INDEX ix_platform_issue_values_assessment
    ON platform_assessment_issue_values (assessment_id, sort_order);
CREATE INDEX ix_platform_measurements_assessment
    ON platform_assessment_measurements (assessment_id);
CREATE INDEX ix_platform_evidence_job_item
    ON platform_evidence_assets (job_id, item_code);
CREATE INDEX ix_platform_evidence_sha
    ON platform_evidence_assets (sha256);
CREATE INDEX ix_platform_evidence_derivative_asset
    ON platform_evidence_derivatives (asset_id, kind);
CREATE INDEX ix_platform_signatures_job_signed
    ON platform_job_signatures (job_id, signed_at);
CREATE INDEX ix_platform_conflicts_job_state
    ON platform_sync_conflicts (job_id, state);

