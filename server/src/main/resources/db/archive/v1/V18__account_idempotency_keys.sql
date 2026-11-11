-- Phase C0 Workstream A: idempotency records for scoped account create/reset.
-- Additive only. Invitation tables are intentionally left untouched.

CREATE TABLE account_idempotency_keys (
    id BINARY(16) NOT NULL,
    key_hash BINARY(32) NOT NULL,
    actor_user_id BINARY(16) NOT NULL,
    endpoint VARCHAR(128) NOT NULL,
    request_hash BINARY(32) NOT NULL,
    user_id BINARY(16) NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_account_idempotency_keys PRIMARY KEY (id),
    CONSTRAINT uq_account_idempotency_key UNIQUE (key_hash, actor_user_id, endpoint),
    CONSTRAINT fk_account_idempotency_user FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE INDEX ix_account_idempotency_actor ON account_idempotency_keys (actor_user_id, endpoint);
