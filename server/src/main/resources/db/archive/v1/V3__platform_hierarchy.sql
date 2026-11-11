-- Platform Admin hierarchy: invitations and workshop branch detail.

ALTER TABLE workshops ADD COLUMN branch_name VARCHAR(200) NULL;

CREATE TABLE invitations (
    id BINARY(16) NOT NULL,
    workshop_id BINARY(16) NOT NULL,
    user_id BINARY(16) NOT NULL,
    email_normalized VARCHAR(320) NOT NULL,
    member_role VARCHAR(32) NOT NULL,
    token_hash BINARY(32) NOT NULL,
    status VARCHAR(32) NOT NULL,
    expires_at DATETIME(6) NOT NULL,
    accepted_at DATETIME(6) NULL,
    created_by BINARY(16) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_invitations PRIMARY KEY (id),
    CONSTRAINT uq_invitations_token UNIQUE (token_hash),
    CONSTRAINT fk_invitation_workshop FOREIGN KEY (workshop_id) REFERENCES workshops (id),
    CONSTRAINT fk_invitation_user FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT ck_invitation_role CHECK (member_role IN ('WORKSHOP_ADMIN', 'TECHNICIAN')),
    CONSTRAINT ck_invitation_status CHECK (status IN ('PENDING', 'ACCEPTED', 'EXPIRED', 'REVOKED'))
);

CREATE INDEX ix_invitations_workshop_status ON invitations (workshop_id, status);
CREATE INDEX ix_invitations_email_status ON invitations (email_normalized, status);
CREATE INDEX ix_invitations_expires ON invitations (status, expires_at);
