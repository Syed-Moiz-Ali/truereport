-- H2: remove the legacy FK that points workshop template pins at the old master table.
ALTER TABLE template_items DROP CONSTRAINT fk_template_item_master_version;
