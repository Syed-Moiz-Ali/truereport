-- Phase C: translation glossary (quality lever, post-edit and locked terms).

CREATE TABLE translation_glossary (
    id VARCHAR(36) NOT NULL,
    source_lang VARCHAR(12) NOT NULL,
    target_lang VARCHAR(12) NOT NULL,
    term VARCHAR(200) NOT NULL,
    translation VARCHAR(200) NOT NULL,
    case_sensitive BOOLEAN NOT NULL DEFAULT FALSE,
    locked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_translation_glossary PRIMARY KEY (id),
    CONSTRAINT uq_translation_glossary UNIQUE (source_lang, target_lang, term)
);

INSERT INTO translation_glossary
    (id, source_lang, target_lang, term, translation, case_sensitive, locked, created_at)
VALUES
    ('01a1ce00-0000-7000-8000-000000000001', 'en', 'es', 'brake pad', 'pastilla de freno',
     FALSE, FALSE, CURRENT_TIMESTAMP),
    ('01a1ce00-0000-7000-8000-000000000002', 'en', 'es', 'worn', 'desgastado',
     FALSE, FALSE, CURRENT_TIMESTAMP),
    ('01a1ce00-0000-7000-8000-000000000003', 'en', 'es', 'tyre', 'neumático',
     FALSE, FALSE, CURRENT_TIMESTAMP),
    ('01a1ce00-0000-7000-8000-000000000004', 'en', 'es', 'rim', 'llanta',
     FALSE, FALSE, CURRENT_TIMESTAMP),
    ('01a1ce00-0000-7000-8000-000000000005', 'en', 'es', 'coolant', 'refrigerante',
     FALSE, FALSE, CURRENT_TIMESTAMP),
    ('01a1ce00-0000-7000-8000-000000000006', 'en', 'es', 'brake disc', 'disco de freno',
     FALSE, FALSE, CURRENT_TIMESTAMP),
    ('01a1ce00-0000-7000-8000-000000000007', 'en', 'es', 'oil filter', 'filtro de aceite',
     FALSE, FALSE, CURRENT_TIMESTAMP);
