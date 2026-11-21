-- Phase G: glossary coverage for terms LibreTranslate leaves in English.
--
-- These are single-word domain terms, so they are locked: the protector swaps
-- them for tokens before the provider call and restores the Spanish term. That
-- keeps the translation correct even when the model echoes the English word.
-- Existing rows from V131 are promoted to locked instead of duplicated.

UPDATE translation_glossary SET locked = TRUE
WHERE source_lang = 'en' AND target_lang = 'es'
  AND term IN ('coolant', 'tyre', 'rim', 'brake pad', 'brake disc', 'worn');

INSERT INTO translation_glossary
    (id, source_lang, target_lang, term, translation, case_sensitive, locked, created_at)
SELECT '01a1cf00-0000-7000-8000-000000000001', 'en', 'es', 'urgency', 'urgencia', FALSE, TRUE,
       CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM translation_glossary
                  WHERE source_lang = 'en' AND target_lang = 'es' AND term = 'urgency');

INSERT INTO translation_glossary
    (id, source_lang, target_lang, term, translation, case_sensitive, locked, created_at)
SELECT '01a1cf00-0000-7000-8000-000000000002', 'en', 'es', 'severity', 'severidad', FALSE, TRUE,
       CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM translation_glossary
                  WHERE source_lang = 'en' AND target_lang = 'es' AND term = 'severity');

INSERT INTO translation_glossary
    (id, source_lang, target_lang, term, translation, case_sensitive, locked, created_at)
SELECT '01a1cf00-0000-7000-8000-000000000003', 'en', 'es', 'component', 'componente', FALSE, TRUE,
       CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM translation_glossary
                  WHERE source_lang = 'en' AND target_lang = 'es' AND term = 'component');

INSERT INTO translation_glossary
    (id, source_lang, target_lang, term, translation, case_sensitive, locked, created_at)
SELECT '01a1cf00-0000-7000-8000-000000000004', 'en', 'es', 'inspection', 'inspección', FALSE, TRUE,
       CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM translation_glossary
                  WHERE source_lang = 'en' AND target_lang = 'es' AND term = 'inspection');

INSERT INTO translation_glossary
    (id, source_lang, target_lang, term, translation, case_sensitive, locked, created_at)
SELECT '01a1cf00-0000-7000-8000-000000000005', 'en', 'es', 'chassis', 'chasis', FALSE, TRUE,
       CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM translation_glossary
                  WHERE source_lang = 'en' AND target_lang = 'es' AND term = 'chassis');

INSERT INTO translation_glossary
    (id, source_lang, target_lang, term, translation, case_sensitive, locked, created_at)
SELECT '01a1cf00-0000-7000-8000-000000000006', 'en', 'es', 'subframe', 'subchasis', FALSE, TRUE,
       CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM translation_glossary
                  WHERE source_lang = 'en' AND target_lang = 'es' AND term = 'subframe');

INSERT INTO translation_glossary
    (id, source_lang, target_lang, term, translation, case_sensitive, locked, created_at)
SELECT '01a1cf00-0000-7000-8000-000000000007', 'en', 'es', 'floor pan', 'piso', FALSE, TRUE,
       CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM translation_glossary
                  WHERE source_lang = 'en' AND target_lang = 'es' AND term = 'floor pan');

INSERT INTO translation_glossary
    (id, source_lang, target_lang, term, translation, case_sensitive, locked, created_at)
SELECT '01a1cf00-0000-7000-8000-000000000008', 'en', 'es', 'rail', 'riel', FALSE, TRUE,
       CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM translation_glossary
                  WHERE source_lang = 'en' AND target_lang = 'es' AND term = 'rail');

INSERT INTO translation_glossary
    (id, source_lang, target_lang, term, translation, case_sensitive, locked, created_at)
SELECT '01a1cf00-0000-7000-8000-000000000009', 'en', 'es', 'hose', 'manguera', FALSE, TRUE,
       CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM translation_glossary
                  WHERE source_lang = 'en' AND target_lang = 'es' AND term = 'hose');

INSERT INTO translation_glossary
    (id, source_lang, target_lang, term, translation, case_sensitive, locked, created_at)
SELECT '01a1cf00-0000-7000-8000-000000000010', 'en', 'es', 'worn out',
       'desgastado por completo', FALSE, TRUE, CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM translation_glossary
                  WHERE source_lang = 'en' AND target_lang = 'es' AND term = 'worn out');
