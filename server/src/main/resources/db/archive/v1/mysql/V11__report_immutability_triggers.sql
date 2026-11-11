-- MySQL-only defence in depth for Phase 6 report immutability and link transitions.
-- Service guards remain the primary control. H2 tests cover the service paths.

DELIMITER $$

CREATE TRIGGER trg_reports_no_update
BEFORE UPDATE ON reports
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reports are immutable';
END$$

CREATE TRIGGER trg_reports_no_delete
BEFORE DELETE ON reports
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reports are immutable';
END$$

CREATE TRIGGER trg_report_versions_no_update
BEFORE UPDATE ON report_versions
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Report versions are immutable';
END$$

CREATE TRIGGER trg_report_versions_no_delete
BEFORE DELETE ON report_versions
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Report versions are immutable';
END$$

CREATE TRIGGER trg_public_share_link_no_token_change
BEFORE UPDATE ON public_share_links
FOR EACH ROW
BEGIN
    IF OLD.report_version_id <> NEW.report_version_id
        OR OLD.workshop_id <> NEW.workshop_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Public link ownership is immutable';
    END IF;
    IF NOT (OLD.token_hash <=> NEW.token_hash)
        AND NOT (OLD.token_hash IS NULL AND NEW.token_hash IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Public token can only be set once';
    END IF;
    IF OLD.status = 'REVOKED' AND NEW.status <> 'REVOKED' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Revoked public links cannot be reactivated';
    END IF;
    IF NEW.status = 'REVOKED'
        AND (NEW.revoked_at IS NULL OR NEW.revocation_reason_code IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Revocation requires time and reason';
    END IF;
END$$

DELIMITER ;
