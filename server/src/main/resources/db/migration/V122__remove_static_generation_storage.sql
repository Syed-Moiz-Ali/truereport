-- Static UI text is JSON-backed only. Remove the legacy generation job
-- tables and the language columns that stored generated UI-message state.
DROP TABLE IF EXISTS platform_ui_message_generation_jobs;
DROP TABLE IF EXISTS platform_content_generation_jobs;

ALTER TABLE platform_languages DROP COLUMN ui_messages_path;
ALTER TABLE platform_languages DROP COLUMN ui_messages_hash;
ALTER TABLE platform_languages DROP COLUMN ui_messages_reviewed_at;
ALTER TABLE platform_languages DROP COLUMN ui_messages_reviewed_by;
