-- The workshop registration form collects a contact email; persist it instead
-- of only writing it to the audit trail.

ALTER TABLE workshops ADD COLUMN contact_email VARCHAR(320) NULL;
