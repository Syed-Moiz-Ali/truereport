-- Clean Platform Admin content tables (rebuilt backend).
-- Adds self-contained parent tables and a clean guide-image table. FKs and
-- legacy side-table removal are applied by V103 after the data migration.

CREATE TABLE platform_categories (
    id VARCHAR(36) NOT NULL,
    code VARCHAR(80) NOT NULL,
    name_en VARCHAR(200) NOT NULL,
    name_ar VARCHAR(200) NOT NULL,
    weight_percentage DECIMAL(5,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_content_categories PRIMARY KEY (id),
    CONSTRAINT uq_content_category_code UNIQUE (code),
    CONSTRAINT ck_content_category_weight CHECK (weight_percentage BETWEEN 0 AND 100),
    CONSTRAINT ck_content_category_status CHECK (status IN ('ACTIVE', 'RETIRED'))
);

CREATE TABLE platform_items (
    id VARCHAR(36) NOT NULL,
    stable_code VARCHAR(60) NOT NULL,
    category_id VARCHAR(36) NOT NULL,
    status VARCHAR(20) NOT NULL,
    current_published_version_id VARCHAR(36) NULL,
    sample_data BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_content_items PRIMARY KEY (id),
    CONSTRAINT uq_content_item_code UNIQUE (stable_code),
    CONSTRAINT ck_content_item_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'RETIRED'))
);

CREATE TABLE platform_item_versions (
    id VARCHAR(36) NOT NULL,
    item_id VARCHAR(36) NOT NULL,
    version_no INT NOT NULL,
    status VARCHAR(20) NOT NULL,
    label_en VARCHAR(200) NOT NULL,
    label_ar VARCHAR(200) NOT NULL,
    instruction_en TEXT NOT NULL,
    instruction_ar TEXT NOT NULL,
    measurement_unit VARCHAR(30) NULL,
    sensor_tool VARCHAR(150) NULL,
    standard_spec_en TEXT NULL,
    standard_spec_ar TEXT NULL,
    safety_critical BOOLEAN NOT NULL DEFAULT FALSE,
    multi_point BOOLEAN NOT NULL DEFAULT FALSE,
    max_tyre_age_years INT NULL,
    allow_free_text_note BOOLEAN NOT NULL DEFAULT FALSE,
    result_options_json TEXT NULL,
    severity_policy_json TEXT NULL,
    applicability_json TEXT NULL,
    reason_codes_json TEXT NULL,
    note_requirement VARCHAR(32) NOT NULL DEFAULT 'OPTIONAL',
    evidence_requirement VARCHAR(32) NOT NULL DEFAULT 'NONE',
    min_photos INT NOT NULL DEFAULT 0,
    equipment_ids_json TEXT NULL,
    guide_image_id VARCHAR(36) NULL,
    published_at DATETIME(6) NULL,
    published_by VARCHAR(36) NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_content_item_versions PRIMARY KEY (id),
    CONSTRAINT uq_content_item_version UNIQUE (item_id, version_no),
    CONSTRAINT ck_content_version_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'RETIRED'))
);

CREATE TABLE platform_guide_images (
    id VARCHAR(36) NOT NULL,
    storage_key VARCHAR(512) NOT NULL,
    content_hash VARBINARY(32) NOT NULL,
    mime VARCHAR(100) NOT NULL,
    bytes BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL,
    licence_note VARCHAR(255) NULL,
    alt_en VARCHAR(255) NULL,
    alt_ar VARCHAR(255) NULL,
    uploaded_by VARCHAR(36) NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_content_guide_images PRIMARY KEY (id),
    CONSTRAINT ck_content_guide_status CHECK (status IN ('ACTIVE', 'RETIRED'))
);

CREATE INDEX ix_content_categories_order ON platform_categories (status, sort_order);
CREATE INDEX ix_content_items_category ON platform_items (category_id, status, sort_order);
CREATE INDEX ix_content_versions_item ON platform_item_versions (item_id, status, version_no);
CREATE INDEX ix_content_versions_safety ON platform_item_versions (safety_critical);
CREATE INDEX ix_content_guide_images_status ON platform_guide_images (status, created_at);
