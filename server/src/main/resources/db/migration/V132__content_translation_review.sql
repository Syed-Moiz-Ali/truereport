-- Phase D: review notes and review-queue index.

ALTER TABLE content_translation ADD COLUMN review_note VARCHAR(500) NULL;

CREATE INDEX ix_content_translation_review
    ON content_translation (lang, status, entity_type);
