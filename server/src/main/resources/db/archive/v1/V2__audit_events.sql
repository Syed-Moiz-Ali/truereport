-- Append-only audit trail for account, auth and tenancy events.

CREATE TABLE audit_events (
    id BINARY(16) NOT NULL,
    workshop_id BINARY(16) NULL,
    actor_user_id BINARY(16) NULL,
    actor_role VARCHAR(32) NULL,
    action VARCHAR(80) NOT NULL,
    entity_type VARCHAR(80) NULL,
    entity_id BINARY(16) NULL,
    occurred_at DATETIME(6) NOT NULL,
    request_id VARCHAR(64) NULL,
    reason_code VARCHAR(64) NULL,
    metadata_json TEXT NULL,
    CONSTRAINT pk_audit_events PRIMARY KEY (id)
);

CREATE INDEX ix_audit_workshop_time ON audit_events (workshop_id, occurred_at);
CREATE INDEX ix_audit_actor_time ON audit_events (actor_user_id, occurred_at);
CREATE INDEX ix_audit_entity_time ON audit_events (entity_type, entity_id, occurred_at);
CREATE INDEX ix_audit_action_time ON audit_events (action, occurred_at);
