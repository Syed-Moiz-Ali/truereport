-- TrueReport Phase 2 foundation: tenancy, identity, refresh tokens.
-- MySQL 8.4 LTS in production; H2 MySQL mode in local tests.

CREATE TABLE workshops (
    id BINARY(16) NOT NULL,
    name VARCHAR(200) NOT NULL,
    status VARCHAR(32) NOT NULL,
    timezone VARCHAR(64) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_workshops PRIMARY KEY (id),
    CONSTRAINT ck_workshops_status CHECK (status IN ('ACTIVE', 'DISABLED'))
);

CREATE TABLE users (
    id BINARY(16) NOT NULL,
    email VARCHAR(320) NOT NULL,
    email_normalized VARCHAR(320) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    display_name VARCHAR(200) NOT NULL,
    status VARCHAR(32) NOT NULL,
    platform_admin BOOLEAN NOT NULL DEFAULT FALSE,
    totp_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    totp_secret_enc VARBINARY(512) NULL,
    totp_last_step BIGINT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_users PRIMARY KEY (id),
    CONSTRAINT uq_users_email_normalized UNIQUE (email_normalized),
    CONSTRAINT ck_users_status CHECK (status IN ('PENDING_INVITATION', 'ACTIVE', 'DISABLED'))
);

CREATE TABLE workshop_memberships (
    id BINARY(16) NOT NULL,
    workshop_id BINARY(16) NOT NULL,
    user_id BINARY(16) NOT NULL,
    member_role VARCHAR(32) NOT NULL,
    status VARCHAR(32) NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_workshop_memberships PRIMARY KEY (id),
    CONSTRAINT fk_membership_workshop FOREIGN KEY (workshop_id) REFERENCES workshops (id),
    CONSTRAINT fk_membership_user FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT uq_membership_workshop_user UNIQUE (workshop_id, user_id),
    CONSTRAINT ck_membership_role CHECK (member_role IN ('WORKSHOP_ADMIN', 'TECHNICIAN')),
    CONSTRAINT ck_membership_status CHECK (status IN ('ACTIVE', 'DISABLED'))
);

CREATE TABLE refresh_tokens (
    id BINARY(16) NOT NULL,
    user_id BINARY(16) NOT NULL,
    family_id BINARY(16) NOT NULL,
    token_hash BINARY(32) NOT NULL,
    issued_at DATETIME(6) NOT NULL,
    expires_at DATETIME(6) NOT NULL,
    revoked_at DATETIME(6) NULL,
    replaced_by BINARY(16) NULL,
    ip_hash BINARY(32) NULL,
    user_agent_hash BINARY(32) NULL,
    CONSTRAINT pk_refresh_tokens PRIMARY KEY (id),
    CONSTRAINT fk_refresh_user FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT uq_refresh_token_hash UNIQUE (token_hash)
);

CREATE INDEX ix_memberships_workshop_role ON workshop_memberships (workshop_id, member_role, status);
CREATE INDEX ix_memberships_user_status ON workshop_memberships (user_id, status);
CREATE INDEX ix_refresh_user_active ON refresh_tokens (user_id, revoked_at);
CREATE INDEX ix_refresh_family ON refresh_tokens (family_id);
CREATE INDEX ix_workshops_status ON workshops (status);
