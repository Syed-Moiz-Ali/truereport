-- TrueReport rebuilt backend — Phase 1 (Platform Admin) clean baseline.
-- These tables are owned by the rebuilt platform configuration modules and do
-- not depend on the legacy V1–V18 schema. Legacy tables remain in place only to
-- keep the reference application bootable while the rebuild is phased in.
-- IDs are UUIDv7 strings for portability across H2 (tests) and MySQL 8.4.

CREATE TABLE platform_languages (
    code VARCHAR(16) NOT NULL,
    name_en VARCHAR(80) NOT NULL,
    name_ar VARCHAR(80) NOT NULL,
    native_name VARCHAR(80) NOT NULL,
    direction VARCHAR(3) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_platform_languages PRIMARY KEY (code),
    CONSTRAINT ck_platform_language_direction CHECK (direction IN ('ltr', 'rtl'))
);

CREATE TABLE platform_user_language_preferences (
    user_id VARCHAR(36) NOT NULL,
    language_code VARCHAR(16) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_platform_user_language PRIMARY KEY (user_id)
);

CREATE TABLE platform_category_config (
    category_id VARCHAR(36) NOT NULL,
    weight_percentage DECIMAL(5,2) NOT NULL DEFAULT 0,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_platform_category_config PRIMARY KEY (category_id),
    CONSTRAINT ck_platform_category_weight CHECK (weight_percentage BETWEEN 0 AND 100)
);

CREATE TABLE platform_item_metadata (
    item_id VARCHAR(36) NOT NULL,
    measurement_unit VARCHAR(30) NULL,
    sensor_tool VARCHAR(150) NULL,
    standard_spec_en TEXT NULL,
    standard_spec_ar TEXT NULL,
    safety_critical BOOLEAN NOT NULL DEFAULT FALSE,
    multi_point BOOLEAN NOT NULL DEFAULT FALSE,
    max_tyre_age_years INT NULL,
    allow_free_text_note BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    guide_image_id VARCHAR(36) NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_platform_item_metadata PRIMARY KEY (item_id)
);

CREATE TABLE platform_score_bands (
    id VARCHAR(36) NOT NULL,
    item_version_id VARCHAR(36) NOT NULL,
    result_code VARCHAR(40) NOT NULL,
    min_score INT NOT NULL,
    max_score INT NOT NULL,
    default_score INT NOT NULL,
    criteria_en TEXT NULL,
    criteria_ar TEXT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_platform_score_bands PRIMARY KEY (id),
    CONSTRAINT uq_platform_score_band UNIQUE (item_version_id, result_code),
    CONSTRAINT ck_platform_score_band_range CHECK (0 <= min_score AND min_score <= max_score AND max_score <= 100),
    CONSTRAINT ck_platform_score_band_default CHECK (default_score BETWEEN min_score AND max_score)
);

CREATE TABLE platform_evidence_rules (
    id VARCHAR(36) NOT NULL,
    item_version_id VARCHAR(36) NOT NULL,
    result_code VARCHAR(40) NOT NULL,
    min_photos INT NOT NULL DEFAULT 0,
    min_videos INT NOT NULL DEFAULT 0,
    min_notes_chars INT NOT NULL DEFAULT 0,
    required_evidence_type VARCHAR(20) NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_platform_evidence_rules PRIMARY KEY (id),
    CONSTRAINT uq_platform_evidence_rule UNIQUE (item_version_id, result_code),
    CONSTRAINT ck_platform_evidence_type CHECK (required_evidence_type IS NULL OR required_evidence_type IN ('PHOTO', 'VIDEO', 'DOCUMENT'))
);

CREATE TABLE platform_option_sets (
    id VARCHAR(36) NOT NULL,
    code VARCHAR(60) NOT NULL,
    name_en VARCHAR(150) NOT NULL,
    name_ar VARCHAR(150) NOT NULL,
    status VARCHAR(20) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_platform_option_sets PRIMARY KEY (id),
    CONSTRAINT uq_platform_option_set_code UNIQUE (code),
    CONSTRAINT ck_platform_option_set_status CHECK (status IN ('ACTIVE', 'RETIRED'))
);

CREATE TABLE platform_option_values (
    id VARCHAR(36) NOT NULL,
    option_set_id VARCHAR(36) NOT NULL,
    code VARCHAR(60) NOT NULL,
    label_en VARCHAR(200) NOT NULL,
    label_ar VARCHAR(200) NOT NULL,
    status VARCHAR(20) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    metadata_json TEXT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_platform_option_values PRIMARY KEY (id),
    CONSTRAINT uq_platform_option_value UNIQUE (option_set_id, code),
    CONSTRAINT ck_platform_option_value_status CHECK (status IN ('ACTIVE', 'RETIRED'))
);

CREATE TABLE platform_issue_fields (
    id VARCHAR(36) NOT NULL,
    item_version_id VARCHAR(36) NOT NULL,
    field_code VARCHAR(60) NOT NULL,
    label_en VARCHAR(200) NOT NULL,
    label_ar VARCHAR(200) NOT NULL,
    input_type VARCHAR(20) NOT NULL,
    option_set_id VARCHAR(36) NULL,
    unit_set_id VARCHAR(36) NULL,
    is_required BOOLEAN NOT NULL DEFAULT FALSE,
    required_for_statuses_json TEXT NULL,
    min_value DECIMAL(12,3) NULL,
    max_value DECIMAL(12,3) NULL,
    decimal_places INT NOT NULL DEFAULT 0,
    depends_on_field_code VARCHAR(60) NULL,
    depends_on_value_code VARCHAR(60) NULL,
    allow_multiple BOOLEAN NOT NULL DEFAULT FALSE,
    allow_free_text BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_platform_issue_fields PRIMARY KEY (id),
    CONSTRAINT uq_platform_issue_field UNIQUE (item_version_id, field_code),
    CONSTRAINT ck_platform_issue_input_type CHECK (input_type IN ('SELECT', 'MULTI_SELECT', 'NUMBER', 'BOOLEAN', 'TEXT'))
);

CREATE TABLE platform_issue_field_options (
    id VARCHAR(36) NOT NULL,
    issue_field_id VARCHAR(36) NOT NULL,
    option_value_id VARCHAR(36) NOT NULL,
    CONSTRAINT pk_platform_issue_field_options PRIMARY KEY (id),
    CONSTRAINT uq_platform_issue_field_option UNIQUE (issue_field_id, option_value_id)
);

CREATE TABLE platform_measurement_bands (
    id VARCHAR(36) NOT NULL,
    item_version_id VARCHAR(36) NOT NULL,
    field_code VARCHAR(60) NOT NULL,
    unit_code VARCHAR(30) NOT NULL,
    direction VARCHAR(20) NOT NULL,
    min_value DECIMAL(12,3) NOT NULL,
    max_value DECIMAL(12,3) NOT NULL,
    result_code VARCHAR(40) NOT NULL,
    default_score INT NOT NULL,
    label_en VARCHAR(200) NULL,
    label_ar VARCHAR(200) NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_platform_measurement_bands PRIMARY KEY (id),
    CONSTRAINT ck_platform_measurement_range CHECK (min_value < max_value),
    CONSTRAINT ck_platform_measurement_direction CHECK (direction IN ('HIGHER_IS_BETTER', 'LOWER_IS_BETTER'))
);

CREATE TABLE platform_templates (
    id VARCHAR(36) NOT NULL,
    code VARCHAR(60) NOT NULL,
    name_en VARCHAR(200) NOT NULL,
    name_ar VARCHAR(200) NOT NULL,
    description_en TEXT NULL,
    description_ar TEXT NULL,
    status VARCHAR(20) NOT NULL,
    current_published_version_id VARCHAR(36) NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_platform_templates PRIMARY KEY (id),
    CONSTRAINT uq_platform_template_code UNIQUE (code),
    CONSTRAINT ck_platform_template_status CHECK (status IN ('ACTIVE', 'RETIRED'))
);

CREATE TABLE platform_template_versions (
    id VARCHAR(36) NOT NULL,
    template_id VARCHAR(36) NOT NULL,
    version_no INT NOT NULL,
    status VARCHAR(20) NOT NULL,
    published_at DATETIME(6) NULL,
    published_by VARCHAR(36) NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_platform_template_versions PRIMARY KEY (id),
    CONSTRAINT uq_platform_template_version UNIQUE (template_id, version_no),
    CONSTRAINT ck_platform_template_version_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'PUBLISHED', 'RETIRED'))
);

CREATE TABLE platform_template_items (
    id VARCHAR(36) NOT NULL,
    template_version_id VARCHAR(36) NOT NULL,
    item_version_id VARCHAR(36) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    included BOOLEAN NOT NULL DEFAULT TRUE,
    item_weight DECIMAL(6,3) NULL,
    CONSTRAINT pk_platform_template_items PRIMARY KEY (id),
    CONSTRAINT uq_platform_template_item UNIQUE (template_version_id, item_version_id)
);

CREATE TABLE platform_scoring_rules (
    id VARCHAR(36) NOT NULL,
    code VARCHAR(60) NOT NULL,
    name_en VARCHAR(200) NOT NULL,
    name_ar VARCHAR(200) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    category_weight_mode VARCHAR(20) NOT NULL,
    hard_fail_cap_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    hard_fail_cap_grade VARCHAR(5) NULL,
    pending_approval BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_platform_scoring_rules PRIMARY KEY (id),
    CONSTRAINT uq_platform_scoring_rule_code UNIQUE (code),
    CONSTRAINT ck_platform_scoring_weight_mode CHECK (category_weight_mode IN ('CONFIGURED', 'EQUAL'))
);

CREATE TABLE platform_grade_boundaries (
    id VARCHAR(36) NOT NULL,
    scoring_rule_id VARCHAR(36) NOT NULL,
    grade_code VARCHAR(5) NOT NULL,
    min_score INT NOT NULL,
    max_score INT NOT NULL,
    label_en VARCHAR(120) NOT NULL,
    label_ar VARCHAR(120) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    approved BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_platform_grade_boundaries PRIMARY KEY (id),
    CONSTRAINT uq_platform_grade_boundary UNIQUE (scoring_rule_id, grade_code),
    CONSTRAINT ck_platform_grade_range CHECK (0 <= min_score AND min_score <= max_score AND max_score <= 100)
);

CREATE TABLE platform_document_types (
    id VARCHAR(36) NOT NULL,
    code VARCHAR(60) NOT NULL,
    name_en VARCHAR(200) NOT NULL,
    name_ar VARCHAR(200) NOT NULL,
    status VARCHAR(20) NOT NULL,
    is_required BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_platform_document_types PRIMARY KEY (id),
    CONSTRAINT uq_platform_document_type_code UNIQUE (code),
    CONSTRAINT ck_platform_document_type_status CHECK (status IN ('ACTIVE', 'RETIRED'))
);

CREATE TABLE platform_releases (
    id VARCHAR(36) NOT NULL,
    entity_type VARCHAR(60) NOT NULL,
    entity_id VARCHAR(36) NOT NULL,
    version_id VARCHAR(36) NULL,
    status VARCHAR(20) NOT NULL,
    effective_from DATETIME(6) NULL,
    notes TEXT NULL,
    created_by VARCHAR(36) NULL,
    approved_by VARCHAR(36) NULL,
    approved_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_platform_releases PRIMARY KEY (id),
    CONSTRAINT ck_platform_release_status CHECK (status IN ('DRAFT', 'REVIEW', 'APPROVED', 'PUBLISHED', 'DEPRECATED'))
);

CREATE TABLE platform_change_requests (
    id VARCHAR(36) NOT NULL,
    entity_type VARCHAR(60) NOT NULL,
    entity_id VARCHAR(36) NULL,
    action_code VARCHAR(60) NOT NULL,
    payload_json TEXT NULL,
    status VARCHAR(20) NOT NULL,
    proposed_by VARCHAR(36) NOT NULL,
    proposed_at DATETIME(6) NOT NULL,
    decided_by VARCHAR(36) NULL,
    decided_at DATETIME(6) NULL,
    reason TEXT NULL,
    CONSTRAINT pk_platform_change_requests PRIMARY KEY (id),
    CONSTRAINT ck_platform_change_request_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED'))
);

CREATE TABLE platform_outbox_events (
    id VARCHAR(36) NOT NULL,
    aggregate_type VARCHAR(60) NOT NULL,
    aggregate_id VARCHAR(36) NOT NULL,
    event_type VARCHAR(80) NOT NULL,
    payload_json TEXT NOT NULL,
    status VARCHAR(20) NOT NULL,
    attempts INT NOT NULL DEFAULT 0,
    available_at DATETIME(6) NOT NULL,
    locked_by VARCHAR(80) NULL,
    locked_at DATETIME(6) NULL,
    last_error TEXT NULL,
    created_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_platform_outbox_events PRIMARY KEY (id),
    CONSTRAINT ck_platform_outbox_status CHECK (status IN ('PENDING', 'PROCESSING', 'DONE', 'FAILED', 'DEAD_LETTER'))
);

CREATE TABLE platform_idempotency_keys (
    id VARCHAR(36) NOT NULL,
    actor_id VARCHAR(36) NOT NULL,
    endpoint VARCHAR(200) NOT NULL,
    key_hash VARCHAR(64) NOT NULL,
    response_status INT NOT NULL,
    response_json TEXT NULL,
    created_at DATETIME(6) NOT NULL,
    expires_at DATETIME(6) NULL,
    CONSTRAINT pk_platform_idempotency_keys PRIMARY KEY (id),
    CONSTRAINT uq_platform_idempotency UNIQUE (actor_id, endpoint, key_hash)
);

CREATE TABLE platform_audit_events (
    id VARCHAR(36) NOT NULL,
    actor_user_id VARCHAR(36) NULL,
    actor_role VARCHAR(32) NULL,
    action_code VARCHAR(80) NOT NULL,
    entity_type VARCHAR(60) NOT NULL,
    entity_id VARCHAR(36) NULL,
    reason VARCHAR(255) NULL,
    before_json TEXT NULL,
    after_json TEXT NULL,
    trace_id VARCHAR(64) NULL,
    ip_address VARCHAR(64) NULL,
    occurred_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_platform_audit_events PRIMARY KEY (id)
);

CREATE INDEX ix_platform_category_weight ON platform_category_config (weight_percentage);
CREATE INDEX ix_platform_score_bands_version ON platform_score_bands (item_version_id);
CREATE INDEX ix_platform_evidence_rules_version ON platform_evidence_rules (item_version_id);
CREATE INDEX ix_platform_issue_fields_version ON platform_issue_fields (item_version_id);
CREATE INDEX ix_platform_measurement_bands_version ON platform_measurement_bands (item_version_id);
CREATE INDEX ix_platform_option_value_set ON platform_option_values (option_set_id, status, sort_order);
CREATE INDEX ix_platform_template_items_version ON platform_template_items (template_version_id, sort_order);
CREATE INDEX ix_platform_grade_rule ON platform_grade_boundaries (scoring_rule_id, sort_order);
CREATE INDEX ix_platform_releases_entity ON platform_releases (entity_type, entity_id);
CREATE INDEX ix_platform_outbox_status ON platform_outbox_events (status, available_at);
CREATE INDEX ix_platform_audit_entity ON platform_audit_events (entity_type, entity_id, occurred_at);

INSERT INTO platform_languages (code, name_en, name_ar, native_name, direction, active, is_default, sort_order, created_at, updated_at, version)
VALUES ('en', 'English', 'الإنجليزية', 'English', 'ltr', TRUE, TRUE, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0);

INSERT INTO platform_languages (code, name_en, name_ar, native_name, direction, active, is_default, sort_order, created_at, updated_at, version)
VALUES ('ar', 'Arabic', 'العربية', 'العربية', 'rtl', TRUE, FALSE, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0);
