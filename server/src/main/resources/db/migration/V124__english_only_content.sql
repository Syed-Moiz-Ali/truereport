-- English-only product decision: remove Arabic (and any other non-English)
-- language registry rows, preferences and translation overlays. English source
-- columns and the internal Arabic-capable model are kept, but no non-English
-- content remains addressable.

DELETE FROM platform_user_language_preferences WHERE language_code <> 'en';
DELETE FROM platform_translations WHERE lang <> 'en';
DELETE FROM platform_languages WHERE code <> 'en';

UPDATE platform_languages
SET native_name = 'English', direction = 'ltr', active = TRUE,
    is_default = TRUE, sort_order = 0, status = 'LIVE'
WHERE code = 'en';
