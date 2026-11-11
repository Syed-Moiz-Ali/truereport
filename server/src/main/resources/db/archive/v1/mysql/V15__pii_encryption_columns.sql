-- Phase 8: expand PII columns for application-level envelope encryption.
ALTER TABLE inspection_jobs MODIFY customer_name VARCHAR(512) NOT NULL;
ALTER TABLE inspection_jobs MODIFY customer_phone VARCHAR(512) NULL;
ALTER TABLE inspection_jobs MODIFY customer_email VARCHAR(512) NULL;
ALTER TABLE inspection_jobs MODIFY vehicle_vin VARCHAR(512) NULL;
ALTER TABLE inspection_jobs MODIFY vehicle_plate VARCHAR(512) NULL;
ALTER TABLE inspection_final_snapshots MODIFY snapshot_json LONGTEXT NOT NULL;
