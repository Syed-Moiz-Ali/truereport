-- Phase 5B evidence upload slot, normalization and soft-delete metadata.
-- Original evidence stays private; normalized JPEG is stored separately.

ALTER TABLE evidence_assets ADD COLUMN normalized_storage_key VARCHAR(512) NULL;
ALTER TABLE evidence_assets ADD COLUMN normalized_hash BINARY(32) NULL;
ALTER TABLE evidence_assets ADD COLUMN normalized_bytes BIGINT NULL;
ALTER TABLE evidence_assets ADD COLUMN normalized_mime VARCHAR(100) NULL;
ALTER TABLE evidence_assets ADD COLUMN upload_token_hash BINARY(32) NULL;
ALTER TABLE evidence_assets ADD COLUMN upload_token_expires_at DATETIME(6) NULL;
ALTER TABLE evidence_assets ADD COLUMN deleted_at DATETIME(6) NULL;
ALTER TABLE evidence_assets ADD COLUMN deleted_by BINARY(16) NULL;

CREATE INDEX ix_evidence_upload_token ON evidence_assets (upload_token_hash);
CREATE INDEX ix_evidence_active_job ON evidence_assets (job_id, upload_status, deleted_at);
