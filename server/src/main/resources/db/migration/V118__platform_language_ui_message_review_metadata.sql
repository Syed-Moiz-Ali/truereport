ALTER TABLE platform_languages ADD COLUMN ui_messages_hash VARCHAR(64) NULL;
ALTER TABLE platform_languages ADD COLUMN ui_messages_reviewed_at DATETIME(6) NULL;
ALTER TABLE platform_languages ADD COLUMN ui_messages_reviewed_by VARCHAR(36) NULL;
