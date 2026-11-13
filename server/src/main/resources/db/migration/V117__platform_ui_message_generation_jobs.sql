CREATE TABLE platform_ui_message_generation_jobs (
    id VARCHAR(36) NOT NULL,
    language_code VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL,
    total_keys INT NOT NULL DEFAULT 0,
    translated_keys INT NOT NULL DEFAULT 0,
    failed_keys_json TEXT NULL,
    error_code VARCHAR(80) NULL,
    error_message TEXT NULL,
    requested_by VARCHAR(36) NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_platform_ui_message_generation_jobs PRIMARY KEY (id),
    CONSTRAINT ck_ui_message_generation_status CHECK (
        status IN ('QUEUED', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELLED')
    )
);

CREATE INDEX ix_ui_message_generation_language
    ON platform_ui_message_generation_jobs (language_code, created_at);
CREATE INDEX ix_ui_message_generation_status
    ON platform_ui_message_generation_jobs (status);
