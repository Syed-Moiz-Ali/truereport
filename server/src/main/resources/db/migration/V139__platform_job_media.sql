-- Vehicle hero photo captured before the inspection. One VEHICLE_HERO row per
-- job; a retake replaces the row and storage key. This table is intentionally
-- separate from platform_evidence_assets and the evidence rules.
CREATE TABLE platform_job_media (
    id VARCHAR(36) NOT NULL,
    job_id VARCHAR(36) NOT NULL,
    kind VARCHAR(24) NOT NULL,
    storage_key VARCHAR(512) NULL,
    mime VARCHAR(100) NULL,
    bytes BIGINT NULL,
    sha256 VARCHAR(64) NULL,
    width INT NULL,
    height INT NULL,
    captured_at DATETIME(6) NULL,
    capture_source VARCHAR(20) NULL,
    uploaded_by VARCHAR(36) NULL,
    status VARCHAR(20) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_platform_job_media PRIMARY KEY (id),
    CONSTRAINT uq_platform_job_media_job_kind UNIQUE (job_id, kind),
    CONSTRAINT fk_platform_job_media_job FOREIGN KEY (job_id)
        REFERENCES platform_jobs (id)
);
