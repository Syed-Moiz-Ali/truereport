-- Phase 7: remember the last manual retry key so retry requests are idempotent.
ALTER TABLE delivery_requests ADD COLUMN retry_key_hash BINARY(32);
