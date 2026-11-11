-- MySQL-only defence in depth for published master and template versions.
-- The application service remains the primary guard; these triggers protect
-- against accidental direct SQL writes after publication.
--
-- This migration is loaded only by the MySQL Flyway location. It is not
-- executed by the H2 test profile because H2 does not support MySQL trigger
-- syntax.

DELIMITER $$

CREATE TRIGGER trg_master_item_versions_no_update
BEFORE UPDATE ON master_item_versions
FOR EACH ROW
BEGIN
    IF OLD.status IN ('PUBLISHED', 'RETIRED') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Published master item versions are immutable';
    END IF;
END$$

CREATE TRIGGER trg_master_item_versions_no_delete
BEFORE DELETE ON master_item_versions
FOR EACH ROW
BEGIN
    IF OLD.status IN ('PUBLISHED', 'RETIRED') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Published master item versions are immutable';
    END IF;
END$$

CREATE TRIGGER trg_template_versions_no_update
BEFORE UPDATE ON template_versions
FOR EACH ROW
BEGIN
    IF OLD.status IN ('PUBLISHED', 'RETIRED') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Published template versions are immutable';
    END IF;
END$$

CREATE TRIGGER trg_template_versions_no_delete
BEFORE DELETE ON template_versions
FOR EACH ROW
BEGIN
    IF OLD.status IN ('PUBLISHED', 'RETIRED') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Published template versions are immutable';
    END IF;
END$$

CREATE TRIGGER trg_template_items_no_insert
BEFORE INSERT ON template_items
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM template_versions v
        WHERE v.id = NEW.template_version_id
          AND v.status IN ('PUBLISHED', 'RETIRED')
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Published template items are immutable';
    END IF;
END$$

CREATE TRIGGER trg_template_items_no_update
BEFORE UPDATE ON template_items
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM template_versions v
        WHERE v.id IN (OLD.template_version_id, NEW.template_version_id)
          AND v.status IN ('PUBLISHED', 'RETIRED')
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Published template items are immutable';
    END IF;
END$$

CREATE TRIGGER trg_template_items_no_delete
BEFORE DELETE ON template_items
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM template_versions v
        WHERE v.id = OLD.template_version_id
          AND v.status IN ('PUBLISHED', 'RETIRED')
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Published template items are immutable';
    END IF;
END$$

DELIMITER ;
