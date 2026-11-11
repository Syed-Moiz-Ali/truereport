-- Phase 7: report delivery requests, attempts and provider webhook replay records.
-- Recipient values are not duplicated here; requests refer back to the job's recorded contact.
-- This remains fake-only data while C2 legal review and encryption are pending.

CREATE TABLE delivery_requests (
    id BINARY(16) NOT NULL,
    workshop_id BINARY(16) NOT NULL,
    job_id BINARY(16) NOT NULL,
    report_version_id BINARY(16) NOT NULL,
    channel VARCHAR(20) NOT NULL,
    recipient_masked VARCHAR(160) NOT NULL,
    recipient_hash BINARY(32) NOT NULL,
    language VARCHAR(8) NOT NULL,
    status VARCHAR(24) NOT NULL,
    request_hash BINARY(32) NOT NULL,
    idempotency_key_hash BINARY(32) NOT NULL,
    consent_type VARCHAR(40) NOT NULL,
    requested_by BINARY(16) NOT NULL,
    public_share_link_id BINARY(16) NULL,
    pdf_attached BOOLEAN NOT NULL DEFAULT FALSE,
    attempts INT NOT NULL DEFAULT 0,
    max_attempts INT NOT NULL,
    next_attempt_at DATETIME(6) NULL,
    last_error_code VARCHAR(80) NULL,
    last_error_message VARCHAR(500) NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_delivery_requests PRIMARY KEY (id),
    CONSTRAINT uq_delivery_idempotency UNIQUE (workshop_id, idempotency_key_hash),
    CONSTRAINT fk_delivery_job FOREIGN KEY (job_id) REFERENCES inspection_jobs (id),
    CONSTRAINT fk_delivery_report_version FOREIGN KEY (report_version_id) REFERENCES report_versions (id),
    CONSTRAINT fk_delivery_link FOREIGN KEY (public_share_link_id) REFERENCES public_share_links (id)
);

CREATE INDEX ix_delivery_job ON delivery_requests (workshop_id, job_id, created_at);
CREATE INDEX ix_delivery_due ON delivery_requests (status, next_attempt_at);
CREATE INDEX ix_delivery_recipient ON delivery_requests (workshop_id, recipient_hash, created_at);

CREATE TABLE delivery_attempts (
    id BINARY(16) NOT NULL,
    delivery_request_id BINARY(16) NOT NULL,
    attempt_no INT NOT NULL,
    provider VARCHAR(60) NOT NULL,
    status VARCHAR(24) NOT NULL,
    provider_message_id VARCHAR(255) NULL,
    error_code VARCHAR(80) NULL,
    error_message VARCHAR(500) NULL,
    sent_at DATETIME(6) NULL,
    delivered_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_delivery_attempts PRIMARY KEY (id),
    CONSTRAINT uq_delivery_attempt UNIQUE (delivery_request_id, attempt_no),
    CONSTRAINT fk_delivery_attempt_request FOREIGN KEY (delivery_request_id) REFERENCES delivery_requests (id),
    CONSTRAINT ck_delivery_attempt_status CHECK (status IN (
        'QUEUED', 'SENDING', 'SENT', 'DELIVERED', 'FAILED', 'RETRY_PENDING', 'DEAD_LETTER'))
);

CREATE INDEX ix_delivery_attempt_request ON delivery_attempts (delivery_request_id, attempt_no);

CREATE TABLE delivery_webhook_events (
    id BINARY(16) NOT NULL,
    provider VARCHAR(60) NOT NULL,
    event_id VARCHAR(160) NOT NULL,
    payload_hash BINARY(32) NOT NULL,
    delivery_request_id BINARY(16) NOT NULL,
    status VARCHAR(24) NOT NULL,
    received_at DATETIME(6) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_delivery_webhook_events PRIMARY KEY (id),
    CONSTRAINT uq_delivery_webhook_event UNIQUE (provider, event_id),
    CONSTRAINT fk_delivery_webhook_request FOREIGN KEY (delivery_request_id) REFERENCES delivery_requests (id)
);
