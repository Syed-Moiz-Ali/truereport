-- Phase 8: TOTP recovery codes and admin lockout counters.
ALTER TABLE users ADD failed_login_count INT NOT NULL DEFAULT 0;
ALTER TABLE users ADD locked_until DATETIME(6) NULL;
ALTER TABLE users ADD totp_failed_count INT NOT NULL DEFAULT 0;

CREATE TABLE totp_recovery_codes (
    id BINARY(16) NOT NULL,
    user_id BINARY(16) NOT NULL,
    code_hash BINARY(32) NOT NULL,
    used_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL,
    CONSTRAINT pk_totp_recovery_codes PRIMARY KEY (id),
    CONSTRAINT uq_totp_recovery_code_hash UNIQUE (code_hash),
    CONSTRAINT fk_totp_recovery_user FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE INDEX ix_totp_recovery_user ON totp_recovery_codes (user_id, used_at);
