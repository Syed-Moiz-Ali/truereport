-- MySQL-only defence in depth for Phase 5A finalized inspections.
-- Service/API guards remain the primary control. This migration is not
-- loaded by the H2 test profile and is not locally verified without Docker.

DELIMITER $$

CREATE TRIGGER trg_inspection_jobs_no_update_after_finalize
BEFORE UPDATE ON inspection_jobs
FOR EACH ROW
BEGIN
    IF OLD.status = 'FINALIZED' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Finalized inspections are immutable';
    END IF;
END$$

CREATE TRIGGER trg_inspection_jobs_no_delete_after_finalize
BEFORE DELETE ON inspection_jobs
FOR EACH ROW
BEGIN
    IF OLD.status = 'FINALIZED' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Finalized inspections are immutable';
    END IF;
END$$

CREATE TRIGGER trg_assessments_no_update_after_finalize
BEFORE UPDATE ON assessments
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM inspection_jobs j
        WHERE j.id = NEW.job_id AND j.status = 'FINALIZED'
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Finalized assessment is immutable';
    END IF;
END$$

CREATE TRIGGER trg_assessments_no_delete_after_finalize
BEFORE DELETE ON assessments
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM inspection_jobs j
        WHERE j.id = OLD.job_id AND j.status = 'FINALIZED'
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Finalized assessment is immutable';
    END IF;
END$$

CREATE TRIGGER trg_item_snapshots_no_update
BEFORE UPDATE ON inspection_item_snapshots
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Inspection item snapshots are immutable';
END$$

CREATE TRIGGER trg_item_snapshots_no_delete
BEFORE DELETE ON inspection_item_snapshots
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Inspection item snapshots are immutable';
END$$

CREATE TRIGGER trg_final_snapshots_no_update
BEFORE UPDATE ON inspection_final_snapshots
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Final inspection snapshots are immutable';
END$$

CREATE TRIGGER trg_final_snapshots_no_delete
BEFORE DELETE ON inspection_final_snapshots
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Final inspection snapshots are immutable';
END$$

CREATE TRIGGER trg_findings_no_update
BEFORE UPDATE ON findings
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Findings are immutable';
END$$

CREATE TRIGGER trg_findings_no_delete
BEFORE DELETE ON findings
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Findings are immutable';
END$$

CREATE TRIGGER trg_consent_no_update
BEFORE UPDATE ON consent_records
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Consent records are append-only';
END$$

CREATE TRIGGER trg_consent_no_delete
BEFORE DELETE ON consent_records
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Consent records are append-only';
END$$

CREATE TRIGGER trg_evidence_no_update_after_finalize
BEFORE UPDATE ON evidence_assets
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM inspection_jobs j
        WHERE j.id = NEW.job_id AND j.status = 'FINALIZED'
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Finalized evidence is immutable';
    END IF;
END$$

CREATE TRIGGER trg_evidence_no_delete_after_finalize
BEFORE DELETE ON evidence_assets
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM inspection_jobs j
        WHERE j.id = OLD.job_id AND j.status = 'FINALIZED'
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Finalized evidence is immutable';
    END IF;
END$$

DELIMITER ;
