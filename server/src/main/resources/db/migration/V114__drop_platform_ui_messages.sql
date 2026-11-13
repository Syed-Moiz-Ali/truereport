DELETE FROM platform_translations WHERE entity_type = 'UI_MESSAGE';

DROP TABLE IF EXISTS platform_ui_message_language_versions;
DROP TABLE IF EXISTS platform_ui_message_versions;
DROP TABLE IF EXISTS platform_ui_messages;
