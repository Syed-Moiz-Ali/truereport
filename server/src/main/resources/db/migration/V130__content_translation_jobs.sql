-- Phase B: durable translation jobs (provider interface only; no network here).

CREATE TABLE content_translation_job (
    id VARCHAR(36) NOT NULL,
    entity_type VARCHAR(40) NOT NULL,
    entity_id VARCHAR(36) NOT NULL,
    field_name VARCHAR(60) NOT NULL,
    lang VARCHAR(12) NOT NULL,
    direction VARCHAR(16) NOT NULL,
    state VARCHAR(16) NOT NULL DEFAULT 'PENDING',
    attempts INT NOT NULL DEFAULT 0,
    error VARCHAR(500) NULL,
    next_attempt_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_content_translation_job PRIMARY KEY (id),
    CONSTRAINT uq_content_translation_job
        UNIQUE (entity_type, entity_id, field_name, lang, direction),
    CONSTRAINT ck_content_translation_job_direction
        CHECK (direction IN ('TO_CANONICAL', 'FROM_CANONICAL')),
    CONSTRAINT ck_content_translation_job_state
        CHECK (state IN ('PENDING', 'RUNNING', 'DONE', 'FAILED'))
);

CREATE INDEX ix_content_translation_job_claim
    ON content_translation_job (state, next_attempt_at, created_at);
CREATE INDEX ix_content_translation_job_entity
    ON content_translation_job (entity_type, entity_id);
