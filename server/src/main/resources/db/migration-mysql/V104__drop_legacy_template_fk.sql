-- MySQL: remove the legacy FK that points workshop template pins at the old master table.
ALTER TABLE template_items DROP FOREIGN KEY fk_template_item_master_version;
