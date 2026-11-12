-- Enforce clean Platform Admin content relationships and retire legacy side tables.

ALTER TABLE platform_items
    ADD CONSTRAINT fk_platform_items_category
    FOREIGN KEY (category_id) REFERENCES platform_categories (id);

ALTER TABLE platform_item_versions
    ADD CONSTRAINT fk_platform_versions_item
    FOREIGN KEY (item_id) REFERENCES platform_items (id);

ALTER TABLE platform_items
    ADD CONSTRAINT fk_platform_items_current_version
    FOREIGN KEY (current_published_version_id) REFERENCES platform_item_versions (id);

ALTER TABLE platform_item_versions
    ADD CONSTRAINT fk_platform_versions_guide_image
    FOREIGN KEY (guide_image_id) REFERENCES platform_guide_images (id);

ALTER TABLE platform_score_bands
    ADD CONSTRAINT fk_platform_score_bands_version
    FOREIGN KEY (item_version_id) REFERENCES platform_item_versions (id);

ALTER TABLE platform_evidence_rules
    ADD CONSTRAINT fk_platform_evidence_rules_version
    FOREIGN KEY (item_version_id) REFERENCES platform_item_versions (id);

ALTER TABLE platform_issue_fields
    ADD CONSTRAINT fk_platform_issue_fields_version
    FOREIGN KEY (item_version_id) REFERENCES platform_item_versions (id);

ALTER TABLE platform_issue_fields
    ADD CONSTRAINT fk_platform_issue_fields_option_set
    FOREIGN KEY (option_set_id) REFERENCES platform_option_sets (id);

ALTER TABLE platform_issue_fields
    ADD CONSTRAINT fk_platform_issue_fields_unit_set
    FOREIGN KEY (unit_set_id) REFERENCES platform_option_sets (id);

ALTER TABLE platform_issue_field_options
    ADD CONSTRAINT fk_platform_field_options_field
    FOREIGN KEY (issue_field_id) REFERENCES platform_issue_fields (id);

ALTER TABLE platform_issue_field_options
    ADD CONSTRAINT fk_platform_field_options_value
    FOREIGN KEY (option_value_id) REFERENCES platform_option_values (id);

ALTER TABLE platform_measurement_bands
    ADD CONSTRAINT fk_platform_measurement_bands_version
    FOREIGN KEY (item_version_id) REFERENCES platform_item_versions (id);

ALTER TABLE platform_template_versions
    ADD CONSTRAINT fk_platform_template_versions_template
    FOREIGN KEY (template_id) REFERENCES platform_templates (id);

ALTER TABLE platform_templates
    ADD CONSTRAINT fk_platform_templates_current_version
    FOREIGN KEY (current_published_version_id) REFERENCES platform_template_versions (id);

ALTER TABLE platform_template_items
    ADD CONSTRAINT fk_platform_template_items_version
    FOREIGN KEY (template_version_id) REFERENCES platform_template_versions (id);

ALTER TABLE platform_template_items
    ADD CONSTRAINT fk_platform_template_items_item_version
    FOREIGN KEY (item_version_id) REFERENCES platform_item_versions (id);

ALTER TABLE platform_grade_boundaries
    ADD CONSTRAINT fk_platform_grade_boundaries_rule
    FOREIGN KEY (scoring_rule_id) REFERENCES platform_scoring_rules (id);

-- Legacy workshop templates pin the same UUIDs, now living in platform_item_versions.
-- The legacy FK is dropped by the vendor-specific V104 migration.

DROP TABLE platform_category_config;
DROP TABLE platform_item_metadata;
