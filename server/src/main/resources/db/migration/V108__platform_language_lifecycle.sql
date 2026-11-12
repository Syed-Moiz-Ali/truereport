-- Platform Admin dynamic language lifecycle (translation overlay + backlog/coverage/publish).
-- Portable across H2 (MySQL mode, tests) and MySQL 8.4. Column names avoid reserved
-- words (FIELD/TEXT): the API still exposes them as `field`, `language`, `text`.
-- Existing migrations are untouched; en/ar are backfilled as LIVE.

ALTER TABLE platform_languages ADD COLUMN status VARCHAR(16) NOT NULL DEFAULT 'DRAFT';

UPDATE platform_languages SET status = 'LIVE' WHERE code IN ('en', 'ar');

CREATE TABLE platform_translations (
    id VARCHAR(36) NOT NULL,
    entity_type VARCHAR(48) NOT NULL,
    entity_id VARCHAR(36) NOT NULL,
    field_name VARCHAR(64) NOT NULL,
    lang VARCHAR(16) NOT NULL,
    body TEXT NOT NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'DRAFT',
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_platform_translations PRIMARY KEY (id),
    CONSTRAINT uq_platform_translation UNIQUE (entity_type, entity_id, field_name, lang)
);

CREATE INDEX ix_platform_translations_lang ON platform_translations (lang, status);
CREATE INDEX ix_platform_translations_entity ON platform_translations (entity_type, entity_id);
