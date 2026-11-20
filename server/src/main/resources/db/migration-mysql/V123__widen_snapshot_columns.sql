-- Pinned inspection snapshots and report snapshots carry the full checklist
-- schema (labels, instructions, rules, issue fields, measurements, evidence).
-- A 30-item GCC template is ~313 KB, which exceeds MySQL TEXT (65,535 bytes)
-- and caused GET /technician/jobs/{id}/checklist to fail with a data-integrity
-- error. H2 uses a CLOB, so the limit was never exercised by the H2 tests.
--
-- MEDIUMTEXT (16 MB) keeps the immutable audit record intact without trimming
-- rules or translations.

ALTER TABLE platform_job_checklists
    MODIFY COLUMN snapshot_json MEDIUMTEXT NOT NULL;

ALTER TABLE platform_report_versions
    MODIFY COLUMN snapshot_json MEDIUMTEXT NOT NULL;

ALTER TABLE inspection_final_snapshots
    MODIFY COLUMN snapshot_json MEDIUMTEXT NOT NULL;

ALTER TABLE report_versions
    MODIFY COLUMN snapshot_json MEDIUMTEXT NOT NULL;
