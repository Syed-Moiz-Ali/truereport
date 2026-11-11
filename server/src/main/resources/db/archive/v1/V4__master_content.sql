-- Platform Admin master content: categories, versioned items, translations,
-- reasons, equipment, dropdowns and guide images.
-- Placeholder sample content is marked with sample_data = TRUE.

CREATE TABLE master_categories (
    id BINARY(16) NOT NULL,
    slug VARCHAR(80) NOT NULL,
    status VARCHAR(32) NOT NULL,
    sort_order INT NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_master_categories PRIMARY KEY (id),
    CONSTRAINT uq_master_category_slug UNIQUE (slug),
    CONSTRAINT ck_master_category_status CHECK (status IN ('ACTIVE', 'RETIRED'))
);

CREATE TABLE master_inspection_items (
    id BINARY(16) NOT NULL,
    stable_code VARCHAR(60) NOT NULL,
    category_id BINARY(16) NOT NULL,
    status VARCHAR(32) NOT NULL,
    current_published_version_id BINARY(16) NULL,
    sample_data BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_master_inspection_items PRIMARY KEY (id),
    CONSTRAINT uq_master_item_code UNIQUE (stable_code),
    CONSTRAINT fk_master_item_category FOREIGN KEY (category_id) REFERENCES master_categories (id),
    CONSTRAINT ck_master_item_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'RETIRED'))
);

CREATE TABLE master_item_versions (
    id BINARY(16) NOT NULL,
    item_id BINARY(16) NOT NULL,
    version_no INT NOT NULL,
    status VARCHAR(32) NOT NULL,
    result_options_json TEXT NULL,
    severity_policy_json TEXT NULL,
    applicability_json TEXT NULL,
    reason_codes_json TEXT NULL,
    note_requirement VARCHAR(32) NOT NULL,
    evidence_requirement VARCHAR(32) NOT NULL,
    min_photos INT NOT NULL,
    equipment_ids_json TEXT NULL,
    guide_image_id BINARY(16) NULL,
    published_at DATETIME(6) NULL,
    published_by BINARY(16) NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_master_item_versions PRIMARY KEY (id),
    CONSTRAINT uq_master_item_version UNIQUE (item_id, version_no),
    CONSTRAINT fk_master_version_item FOREIGN KEY (item_id) REFERENCES master_inspection_items (id),
    CONSTRAINT ck_master_version_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'RETIRED')),
    CONSTRAINT ck_master_note_requirement CHECK (note_requirement IN ('NONE', 'OPTIONAL', 'REQUIRED')),
    CONSTRAINT ck_master_evidence_requirement CHECK (evidence_requirement IN ('NONE', 'OPTIONAL', 'REQUIRED', 'REQUIRED_MIN_N'))
);

CREATE TABLE localized_content (
    id BINARY(16) NOT NULL,
    entity_type VARCHAR(40) NOT NULL,
    entity_id BINARY(16) NOT NULL,
    locale VARCHAR(16) NOT NULL,
    field_key VARCHAR(60) NOT NULL,
    text_value TEXT NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_localized_content PRIMARY KEY (id),
    CONSTRAINT uq_localized_content UNIQUE (entity_type, entity_id, locale, field_key)
);

CREATE TABLE master_reasons (
    id BINARY(16) NOT NULL,
    code VARCHAR(60) NOT NULL,
    status VARCHAR(32) NOT NULL,
    sort_order INT NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_master_reasons PRIMARY KEY (id),
    CONSTRAINT uq_master_reason_code UNIQUE (code),
    CONSTRAINT ck_master_reason_status CHECK (status IN ('ACTIVE', 'RETIRED'))
);

CREATE TABLE equipment (
    id BINARY(16) NOT NULL,
    code VARCHAR(60) NOT NULL,
    status VARCHAR(32) NOT NULL,
    sort_order INT NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_equipment PRIMARY KEY (id),
    CONSTRAINT uq_equipment_code UNIQUE (code),
    CONSTRAINT ck_equipment_status CHECK (status IN ('ACTIVE', 'RETIRED'))
);

CREATE TABLE master_dropdowns (
    id BINARY(16) NOT NULL,
    code VARCHAR(60) NOT NULL,
    status VARCHAR(32) NOT NULL,
    sort_order INT NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_master_dropdowns PRIMARY KEY (id),
    CONSTRAINT uq_master_dropdown_code UNIQUE (code),
    CONSTRAINT ck_master_dropdown_status CHECK (status IN ('ACTIVE', 'RETIRED'))
);

CREATE TABLE master_dropdown_values (
    id BINARY(16) NOT NULL,
    dropdown_id BINARY(16) NOT NULL,
    code VARCHAR(60) NOT NULL,
    status VARCHAR(32) NOT NULL,
    sort_order INT NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_master_dropdown_values PRIMARY KEY (id),
    CONSTRAINT uq_master_dropdown_value UNIQUE (dropdown_id, code),
    CONSTRAINT fk_dropdown_value_dropdown FOREIGN KEY (dropdown_id) REFERENCES master_dropdowns (id),
    CONSTRAINT ck_dropdown_value_status CHECK (status IN ('ACTIVE', 'RETIRED'))
);

CREATE TABLE guide_images (
    id BINARY(16) NOT NULL,
    storage_key VARCHAR(512) NOT NULL,
    content_hash BINARY(32) NOT NULL,
    mime VARCHAR(100) NOT NULL,
    bytes BIGINT NOT NULL,
    width INT NULL,
    height INT NULL,
    status VARCHAR(32) NOT NULL,
    licence_note VARCHAR(255) NULL,
    uploaded_by BINARY(16) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_guide_images PRIMARY KEY (id),
    CONSTRAINT ck_guide_image_status CHECK (status IN ('ACTIVE', 'RETIRED'))
);

CREATE INDEX ix_master_items_category ON master_inspection_items (category_id, status);
CREATE INDEX ix_master_versions_item ON master_item_versions (item_id, status);
CREATE INDEX ix_localized_entity ON localized_content (entity_type, entity_id);
CREATE INDEX ix_localized_locale ON localized_content (locale, field_key);
CREATE INDEX ix_guide_images_status ON guide_images (status);
