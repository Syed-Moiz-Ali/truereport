-- Phase 1: platform-owned reference taxonomy (read API).
-- Additive only; existing columns/tables are untouched.

CREATE TABLE reference_domain (
    id BINARY(16) NOT NULL,
    domain_type VARCHAR(16) NOT NULL,
    domain_key VARCHAR(48) NOT NULL,
    code VARCHAR(64) NOT NULL,
    label_key VARCHAR(120) NOT NULL,
    tone VARCHAR(24) NULL,
    icon VARCHAR(48) NULL,
    sort_order INT NOT NULL DEFAULT 0,
    selectable BOOLEAN NOT NULL DEFAULT TRUE,
    visible_for_json TEXT NOT NULL,
    allowed_next_json TEXT NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'PUBLISHED',
    version INT NOT NULL DEFAULT 0,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_reference_domain PRIMARY KEY (id),
    CONSTRAINT uq_reference_domain UNIQUE (domain_key, code),
    CONSTRAINT ck_reference_domain_type CHECK (domain_type IN ('STATUS', 'ENUM')),
    CONSTRAINT ck_reference_domain_status CHECK (status IN ('PUBLISHED', 'DRAFT', 'RETIRED'))
);

CREATE INDEX ix_reference_domain_key ON reference_domain (domain_key, sort_order);

CREATE TABLE status_transition (
    id BINARY(16) NOT NULL,
    entity VARCHAR(32) NOT NULL,
    from_code VARCHAR(64) NOT NULL,
    to_code VARCHAR(64) NOT NULL,
    role VARCHAR(32) NOT NULL,
    guard_json TEXT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_status_transition PRIMARY KEY (id),
    CONSTRAINT uq_status_transition UNIQUE (entity, from_code, to_code, role)
);

CREATE INDEX ix_status_transition_entity ON status_transition (entity, from_code);
