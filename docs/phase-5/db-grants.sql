-- Phase 5A database grants (deployment template, not applied by Flyway).
-- Replace schema/user names and have the DBA review before execution.
-- The application must not be a MySQL superuser and must not have UPDATE/DELETE
-- on immutable inspection tables after Phase 5A.

-- Runtime application user: mutable job/intake tables
GRANT SELECT, INSERT, UPDATE ON truereport.inspection_jobs TO 'tr_app'@'%';
GRANT SELECT, INSERT, UPDATE ON truereport.assessments TO 'tr_app'@'%';
GRANT SELECT, INSERT, UPDATE ON truereport.consent_records TO 'tr_app'@'%';
GRANT SELECT, INSERT, UPDATE ON truereport.inspection_status_history TO 'tr_app'@'%';

-- Immutable / append-only tables: no UPDATE or DELETE
GRANT SELECT, INSERT ON truereport.inspection_item_snapshots TO 'tr_app'@'%';
GRANT SELECT, INSERT ON truereport.inspection_final_snapshots TO 'tr_app'@'%';
GRANT SELECT, INSERT ON truereport.findings TO 'tr_app'@'%';

-- Phase 5B evidence tables: reserved; grant only when the evidence API exists.
-- GRANT SELECT, INSERT, UPDATE ON truereport.evidence_assets TO 'tr_app'@'%';
-- GRANT SELECT, INSERT ON truereport.evidence_derivatives TO 'tr_app'@'%';

-- Audit is append-only for the application.
GRANT SELECT, INSERT ON truereport.audit_events TO 'tr_app'@'%';
