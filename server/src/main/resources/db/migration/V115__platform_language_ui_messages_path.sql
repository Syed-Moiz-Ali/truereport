ALTER TABLE platform_languages ADD COLUMN ui_messages_path VARCHAR(512) NULL;

UPDATE platform_languages SET ui_messages_path = 'platform_admin/en.json' WHERE code = 'en';
UPDATE platform_languages SET ui_messages_path = 'platform_admin/ar.json' WHERE code = 'ar';
