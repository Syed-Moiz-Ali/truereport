-- Phase 8: expand PII columns for application-level envelope encryption (H2 tests).
ALTER TABLE inspection_jobs ALTER COLUMN customer_name VARCHAR(512);
ALTER TABLE inspection_jobs ALTER COLUMN customer_phone VARCHAR(512);
ALTER TABLE inspection_jobs ALTER COLUMN customer_email VARCHAR(512);
ALTER TABLE inspection_jobs ALTER COLUMN vehicle_vin VARCHAR(512);
ALTER TABLE inspection_jobs ALTER COLUMN vehicle_plate VARCHAR(512);
