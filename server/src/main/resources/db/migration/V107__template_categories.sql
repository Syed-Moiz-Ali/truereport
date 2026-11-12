-- Template structure is category-first.
-- Each template version owns ordered categories; each category owns ordered items.
-- Weight/scoring configuration is no longer part of Platform Admin. Legacy scoring
-- tables/columns are retained for the later Workshop/Public phases but are not read
-- or written by Platform Admin code.

CREATE TABLE platform_template_categories (
    id VARCHAR(36) NOT NULL,
    template_version_id VARCHAR(36) NOT NULL,
    category_id VARCHAR(36) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    included BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_platform_template_categories PRIMARY KEY (id),
    CONSTRAINT uq_platform_template_category UNIQUE (template_version_id, category_id)
);

ALTER TABLE platform_template_items ADD COLUMN category_id VARCHAR(36) NULL;

UPDATE platform_template_items
SET category_id = (
    SELECT i.category_id
    FROM platform_item_versions v
    JOIN platform_items i ON i.id = v.item_id
    WHERE v.id = platform_template_items.item_version_id
)
WHERE category_id IS NULL;

INSERT INTO platform_template_categories
    (id, template_version_id, category_id, sort_order, included)
SELECT
    CONCAT(SUBSTRING(ti.template_version_id, 1, 18), SUBSTRING(ti.category_id, 1, 18)),
    ti.template_version_id,
    ti.category_id,
    MIN(ti.sort_order),
    TRUE
FROM platform_template_items ti
WHERE ti.category_id IS NOT NULL AND ti.included = TRUE
GROUP BY ti.template_version_id, ti.category_id;

ALTER TABLE platform_template_items DROP COLUMN item_weight;

ALTER TABLE platform_template_items
    ADD CONSTRAINT fk_platform_template_items_category
    FOREIGN KEY (category_id) REFERENCES platform_categories (id);

ALTER TABLE platform_template_categories
    ADD CONSTRAINT fk_platform_template_categories_version
    FOREIGN KEY (template_version_id) REFERENCES platform_template_versions (id);

ALTER TABLE platform_template_categories
    ADD CONSTRAINT fk_platform_template_categories_category
    FOREIGN KEY (category_id) REFERENCES platform_categories (id);

CREATE INDEX ix_platform_template_categories_version
    ON platform_template_categories (template_version_id, sort_order);

CREATE INDEX ix_platform_template_items_category
    ON platform_template_items (category_id, sort_order);
