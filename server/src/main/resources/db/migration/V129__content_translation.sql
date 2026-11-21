-- Phase A: localized content store and translatable-field registry.
-- English remains the source column; every other language is one row here.

CREATE TABLE content_translation (
    id VARCHAR(36) NOT NULL,
    entity_type VARCHAR(40) NOT NULL,
    entity_id VARCHAR(36) NOT NULL,
    field_name VARCHAR(60) NOT NULL,
    lang VARCHAR(12) NOT NULL,
    body TEXT NOT NULL,
    origin VARCHAR(16) NOT NULL DEFAULT 'AUTHORED',
    status VARCHAR(16) NOT NULL DEFAULT 'REVIEWED',
    source_lang VARCHAR(12) NOT NULL DEFAULT 'en',
    source_hash VARCHAR(64) NULL,
    provider VARCHAR(32) NULL,
    reviewed_by VARCHAR(36) NULL,
    reviewed_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_content_translation PRIMARY KEY (id),
    CONSTRAINT uq_content_translation UNIQUE (entity_type, entity_id, field_name, lang),
    CONSTRAINT ck_content_translation_origin
        CHECK (origin IN ('AUTHORED', 'MACHINE', 'IMPORTED')),
    CONSTRAINT ck_content_translation_status
        CHECK (status IN ('DRAFT', 'PENDING_REVIEW', 'REVIEWED', 'STALE'))
);

CREATE INDEX ix_content_translation_lookup
    ON content_translation (entity_type, lang, field_name, entity_id);
CREATE INDEX ix_content_translation_entity
    ON content_translation (entity_type, entity_id);

CREATE TABLE translatable_field (
    entity_type VARCHAR(40) NOT NULL,
    field_name VARCHAR(60) NOT NULL,
    max_length INT NOT NULL,
    protect_patterns VARCHAR(500) NULL,
    safety_critical BOOLEAN NOT NULL DEFAULT FALSE,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_translatable_field PRIMARY KEY (entity_type, field_name)
);

INSERT INTO translatable_field
    (entity_type, field_name, max_length, protect_patterns, safety_critical, enabled)
VALUES
    ('CATEGORY', 'name', 200, NULL, FALSE, TRUE),
    ('CATEGORY', 'description', 1000, NULL, FALSE, TRUE),
    ('ITEM', 'label', 200, NULL, FALSE, TRUE),
    ('ITEM', 'instruction', 2000, NULL, TRUE, TRUE),
    ('ITEM', 'standardSpec', 1000, NULL, TRUE, TRUE),
    ('OPTION_SET', 'name', 200, NULL, FALSE, TRUE),
    ('OPTION_SET', 'label', 200, NULL, FALSE, TRUE),
    ('OPTION_VALUE', 'label', 200, NULL, FALSE, TRUE),
    ('TEMPLATE', 'name', 200, NULL, FALSE, TRUE),
    ('TEMPLATE', 'description', 2000, NULL, FALSE, TRUE),
    ('REASON', 'label', 200, NULL, FALSE, TRUE),
    ('EQUIPMENT', 'label', 200, NULL, FALSE, TRUE),
    ('DROPDOWN', 'label', 200, NULL, FALSE, TRUE),
    ('DROPDOWN_VALUE', 'label', 200, NULL, FALSE, TRUE),
    ('DOCUMENT_TYPE', 'name', 200, NULL, FALSE, TRUE),
    ('ISSUE_FIELD', 'label', 200, NULL, FALSE, TRUE);
