-- Phase 6: immutable report versions, generation jobs, public derivatives, links.
-- Report content is copied from the final inspection snapshot; live catalogue tables are not used.

CREATE TABLE reports (
    id BINARY(16) NOT NULL,
    workshop_id BINARY(16) NOT NULL,
    job_id BINARY(16) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_reports PRIMARY KEY (id),
    CONSTRAINT uq_report_job UNIQUE (job_id),
    CONSTRAINT fk_report_job FOREIGN KEY (job_id) REFERENCES inspection_jobs (id),
    CONSTRAINT fk_report_workshop FOREIGN KEY (workshop_id) REFERENCES workshops (id)
);

CREATE TABLE report_versions (
    id BINARY(16) NOT NULL,
    report_id BINARY(16) NOT NULL,
    workshop_id BINARY(16) NOT NULL,
    version_no INT NOT NULL,
    report_number VARCHAR(60) NOT NULL,
    final_snapshot_hash BINARY(32) NOT NULL,
    snapshot_json TEXT NOT NULL,
    snapshot_hash BINARY(32) NOT NULL,
    finalized_at DATETIME(6) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_report_versions PRIMARY KEY (id),
    CONSTRAINT uq_report_version UNIQUE (report_id, version_no),
    CONSTRAINT fk_report_version_report FOREIGN KEY (report_id) REFERENCES reports (id),
    CONSTRAINT fk_report_version_workshop FOREIGN KEY (workshop_id) REFERENCES workshops (id)
);

CREATE TABLE report_generation_jobs (
    id BINARY(16) NOT NULL,
    report_version_id BINARY(16) NOT NULL,
    status VARCHAR(24) NOT NULL,
    attempts INT NOT NULL DEFAULT 0,
    last_error VARCHAR(1000) NULL,
    available_at DATETIME(6) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_report_generation_jobs PRIMARY KEY (id),
    CONSTRAINT uq_report_generation_version UNIQUE (report_version_id),
    CONSTRAINT fk_report_generation_version FOREIGN KEY (report_version_id) REFERENCES report_versions (id),
    CONSTRAINT ck_report_generation_status CHECK (status IN ('QUEUED', 'GENERATING', 'READY', 'FAILED'))
);

CREATE INDEX ix_report_generation_due ON report_generation_jobs (status, available_at);

CREATE TABLE report_artifacts (
    id BINARY(16) NOT NULL,
    report_version_id BINARY(16) NOT NULL,
    kind VARCHAR(20) NOT NULL,
    storage_key VARCHAR(512) NOT NULL,
    content_hash BINARY(32) NOT NULL,
    bytes BIGINT NOT NULL,
    mime VARCHAR(100) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_report_artifacts PRIMARY KEY (id),
    CONSTRAINT uq_report_artifact UNIQUE (report_version_id, kind),
    CONSTRAINT fk_report_artifact_version FOREIGN KEY (report_version_id) REFERENCES report_versions (id)
);

ALTER TABLE evidence_derivatives ADD COLUMN report_version_id BINARY(16) NOT NULL;
ALTER TABLE evidence_derivatives ADD COLUMN updated_at DATETIME(6) NOT NULL;
ALTER TABLE evidence_derivatives ADD COLUMN version INT NOT NULL DEFAULT 0;

CREATE UNIQUE INDEX uq_evidence_derivative_asset_purpose
    ON evidence_derivatives (evidence_asset_id, purpose);
CREATE INDEX ix_evidence_derivative_report ON evidence_derivatives (report_version_id);

ALTER TABLE evidence_derivatives ADD CONSTRAINT fk_evidence_derivative_version
    FOREIGN KEY (report_version_id) REFERENCES report_versions (id);

CREATE TABLE public_share_links (
    id BINARY(16) NOT NULL,
    workshop_id BINARY(16) NOT NULL,
    report_version_id BINARY(16) NOT NULL,
    token_hash BINARY(32) NULL,
    status VARCHAR(24) NOT NULL,
    pdf_download_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    activated_at DATETIME(6) NULL,
    revoked_at DATETIME(6) NULL,
    revoked_by BINARY(16) NULL,
    revocation_reason_code VARCHAR(60) NULL,
    revocation_note VARCHAR(500) NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_public_share_links PRIMARY KEY (id),
    CONSTRAINT uq_public_share_report UNIQUE (report_version_id),
    CONSTRAINT uq_public_share_token UNIQUE (token_hash),
    CONSTRAINT fk_public_share_version FOREIGN KEY (report_version_id) REFERENCES report_versions (id),
    CONSTRAINT fk_public_share_workshop FOREIGN KEY (workshop_id) REFERENCES workshops (id),
    CONSTRAINT ck_public_share_status CHECK (status IN ('PENDING_CONSENT', 'ACTIVE', 'REVOKED'))
);

CREATE INDEX ix_public_share_workshop ON public_share_links (workshop_id, status);
