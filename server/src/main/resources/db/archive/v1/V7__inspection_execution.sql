-- Phase 5A: online inspection execution, finalization and evidence-ready tables.
-- No evidence rows or photo APIs are created in 5A; evidence tables are reserved for 5B.

ALTER TABLE inspection_jobs ADD COLUMN started_at DATETIME(6) NULL;
ALTER TABLE inspection_jobs ADD COLUMN ready_at DATETIME(6) NULL;
ALTER TABLE inspection_jobs ADD COLUMN finalized_at DATETIME(6) NULL;
ALTER TABLE inspection_jobs ADD COLUMN finalized_by BINARY(16) NULL;
ALTER TABLE inspection_jobs ADD COLUMN finalization_key_hash BINARY(32) NULL;
ALTER TABLE inspection_jobs ADD COLUMN vehicle_type VARCHAR(60) NULL;
ALTER TABLE inspection_jobs ADD COLUMN odometer_value INT NULL;
ALTER TABLE inspection_jobs ADD COLUMN odometer_unit VARCHAR(8) NULL;

CREATE TABLE inspection_item_snapshots (
    id BINARY(16) NOT NULL,
    workshop_id BINARY(16) NOT NULL,
    job_id BINARY(16) NOT NULL,
    master_item_version_id BINARY(16) NOT NULL,
    sort_order INT NOT NULL,
    item_json TEXT NOT NULL,
    snapshot_hash BINARY(32) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_inspection_item_snapshots PRIMARY KEY (id),
    CONSTRAINT uq_inspection_item_version UNIQUE (job_id, master_item_version_id),
    CONSTRAINT fk_inspection_snapshot_job FOREIGN KEY (job_id) REFERENCES inspection_jobs (id),
    CONSTRAINT fk_inspection_snapshot_workshop FOREIGN KEY (workshop_id) REFERENCES workshops (id)
);

CREATE TABLE assessments (
    id BINARY(16) NOT NULL,
    workshop_id BINARY(16) NOT NULL,
    job_id BINARY(16) NOT NULL,
    inspection_item_id BINARY(16) NOT NULL,
    technician_id BINARY(16) NOT NULL,
    result_code VARCHAR(40) NOT NULL,
    severity_code VARCHAR(40) NULL,
    note_text TEXT NULL,
    note_language VARCHAR(16) NULL,
    reason_code VARCHAR(60) NULL,
    reason_text TEXT NULL,
    client_revision BIGINT NOT NULL,
    server_revision BIGINT NOT NULL,
    base_version INT NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_assessments PRIMARY KEY (id),
    CONSTRAINT uq_assessment_item UNIQUE (job_id, inspection_item_id),
    CONSTRAINT fk_assessment_job FOREIGN KEY (job_id) REFERENCES inspection_jobs (id),
    CONSTRAINT fk_assessment_snapshot FOREIGN KEY (inspection_item_id) REFERENCES inspection_item_snapshots (id),
    CONSTRAINT fk_assessment_technician FOREIGN KEY (technician_id) REFERENCES users (id),
    CONSTRAINT ck_assessment_result CHECK (result_code IN (
        'NO_ISSUE_OBSERVED', 'ATTENTION_RECOMMENDED', 'DEFECT_FOUND',
        'NOT_CHECKED', 'NOT_APPLICABLE', 'COULD_NOT_VERIFY')),
    CONSTRAINT ck_assessment_severity CHECK (severity_code IS NULL OR severity_code IN (
        'MINOR', 'MODERATE', 'MAJOR', 'SAFETY_CRITICAL'))
);

CREATE TABLE findings (
    id BINARY(16) NOT NULL,
    workshop_id BINARY(16) NOT NULL,
    job_id BINARY(16) NOT NULL,
    assessment_id BINARY(16) NOT NULL,
    severity_code VARCHAR(40) NOT NULL,
    description TEXT NOT NULL,
    recommendation TEXT NULL,
    created_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_findings PRIMARY KEY (id),
    CONSTRAINT uq_finding_assessment UNIQUE (assessment_id),
    CONSTRAINT fk_finding_job FOREIGN KEY (job_id) REFERENCES inspection_jobs (id),
    CONSTRAINT fk_finding_assessment FOREIGN KEY (assessment_id) REFERENCES assessments (id)
);

CREATE TABLE inspection_final_snapshots (
    id BINARY(16) NOT NULL,
    workshop_id BINARY(16) NOT NULL,
    job_id BINARY(16) NOT NULL,
    snapshot_json TEXT NOT NULL,
    snapshot_hash BINARY(32) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_inspection_final_snapshots PRIMARY KEY (id),
    CONSTRAINT uq_final_snapshot_job UNIQUE (job_id),
    CONSTRAINT fk_final_snapshot_job FOREIGN KEY (job_id) REFERENCES inspection_jobs (id)
);

CREATE TABLE consent_records (
    id BINARY(16) NOT NULL,
    workshop_id BINARY(16) NOT NULL,
    job_id BINARY(16) NOT NULL,
    consent_type VARCHAR(40) NOT NULL,
    status VARCHAR(24) NOT NULL,
    wording_version VARCHAR(40) NOT NULL,
    wording_hash BINARY(32) NOT NULL,
    captured_by BINARY(16) NOT NULL,
    captured_at DATETIME(6) NOT NULL,
    channel VARCHAR(40) NOT NULL,
    evidence_ref VARCHAR(255) NULL,
    created_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_consent_records PRIMARY KEY (id),
    CONSTRAINT fk_consent_job FOREIGN KEY (job_id) REFERENCES inspection_jobs (id),
    CONSTRAINT ck_consent_type CHECK (consent_type IN (
        'PROCESSING', 'PUBLIC_LINK', 'WHATSAPP', 'SMS', 'EMAIL', 'PDF_DOWNLOAD')),
    CONSTRAINT ck_consent_status CHECK (status IN ('GRANTED', 'REFUSED', 'WITHDRAWN'))
);

CREATE TABLE inspection_status_history (
    id BINARY(16) NOT NULL,
    workshop_id BINARY(16) NOT NULL,
    job_id BINARY(16) NOT NULL,
    from_status VARCHAR(32) NOT NULL,
    to_status VARCHAR(32) NOT NULL,
    actor_id BINARY(16) NOT NULL,
    occurred_at DATETIME(6) NOT NULL,
    reason VARCHAR(255) NULL,
    CONSTRAINT pk_inspection_status_history PRIMARY KEY (id),
    CONSTRAINT fk_status_history_job FOREIGN KEY (job_id) REFERENCES inspection_jobs (id)
);

-- Reserved for Phase 5B. No API writes in 5A.
CREATE TABLE evidence_assets (
    id BINARY(16) NOT NULL,
    workshop_id BINARY(16) NOT NULL,
    job_id BINARY(16) NOT NULL,
    inspection_item_id BINARY(16) NULL,
    assessment_id BINARY(16) NULL,
    storage_key VARCHAR(512) NOT NULL,
    content_hash BINARY(32) NOT NULL,
    mime VARCHAR(100) NOT NULL,
    bytes BIGINT NOT NULL,
    width INT NULL,
    height INT NULL,
    captured_at DATETIME(6) NULL,
    uploaded_by BINARY(16) NOT NULL,
    upload_status VARCHAR(24) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_evidence_assets PRIMARY KEY (id),
    CONSTRAINT fk_evidence_job FOREIGN KEY (job_id) REFERENCES inspection_jobs (id),
    CONSTRAINT ck_evidence_status CHECK (upload_status IN ('PENDING', 'RECEIVED', 'VERIFIED', 'REJECTED'))
);

CREATE TABLE evidence_derivatives (
    id BINARY(16) NOT NULL,
    workshop_id BINARY(16) NOT NULL,
    evidence_asset_id BINARY(16) NOT NULL,
    purpose VARCHAR(24) NOT NULL,
    storage_key VARCHAR(512) NOT NULL,
    content_hash BINARY(32) NOT NULL,
    mime VARCHAR(100) NOT NULL,
    bytes BIGINT NOT NULL,
    width INT NULL,
    height INT NULL,
    exif_stripped BOOLEAN NOT NULL,
    created_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_evidence_derivatives PRIMARY KEY (id),
    CONSTRAINT fk_derivative_asset FOREIGN KEY (evidence_asset_id) REFERENCES evidence_assets (id),
    CONSTRAINT ck_derivative_purpose CHECK (purpose IN ('PUBLIC_THUMB', 'PUBLIC_FULL'))
);

CREATE INDEX ix_item_snapshots_job_order ON inspection_item_snapshots (job_id, sort_order);
CREATE INDEX ix_assessments_job ON assessments (workshop_id, job_id);
CREATE INDEX ix_consent_job_type ON consent_records (job_id, consent_type, captured_at);
CREATE INDEX ix_status_history_job ON inspection_status_history (job_id, occurred_at);
CREATE INDEX ix_evidence_job ON evidence_assets (workshop_id, job_id);
CREATE INDEX ix_evidence_hash ON evidence_assets (content_hash);
