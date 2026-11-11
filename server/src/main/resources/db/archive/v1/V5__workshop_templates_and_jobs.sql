-- Phase 4: workshop templates, template versions and workshop jobs.
-- Published template versions pin master_item_version ids and snapshot effective rules.

CREATE TABLE workshop_templates (
    id BINARY(16) NOT NULL,
    workshop_id BINARY(16) NOT NULL,
    name VARCHAR(200) NOT NULL,
    description VARCHAR(1000) NULL,
    service_type VARCHAR(60) NOT NULL,
    vehicle_type VARCHAR(60) NULL,
    status VARCHAR(32) NOT NULL,
    current_published_version_id BINARY(16) NULL,
    created_by BINARY(16) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_workshop_templates PRIMARY KEY (id),
    CONSTRAINT uq_workshop_template_name UNIQUE (workshop_id, name),
    CONSTRAINT fk_workshop_template_workshop FOREIGN KEY (workshop_id) REFERENCES workshops (id),
    CONSTRAINT ck_workshop_template_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'RETIRED'))
);

CREATE TABLE template_versions (
    id BINARY(16) NOT NULL,
    template_id BINARY(16) NOT NULL,
    workshop_id BINARY(16) NOT NULL,
    version_no INT NOT NULL,
    status VARCHAR(32) NOT NULL,
    published_at DATETIME(6) NULL,
    published_by BINARY(16) NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_template_versions PRIMARY KEY (id),
    CONSTRAINT uq_template_version UNIQUE (template_id, version_no),
    CONSTRAINT fk_template_version_template FOREIGN KEY (template_id) REFERENCES workshop_templates (id),
    CONSTRAINT fk_template_version_workshop FOREIGN KEY (workshop_id) REFERENCES workshops (id),
    CONSTRAINT ck_template_version_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'RETIRED'))
);

CREATE TABLE template_items (
    id BINARY(16) NOT NULL,
    template_version_id BINARY(16) NOT NULL,
    workshop_id BINARY(16) NOT NULL,
    master_item_version_id BINARY(16) NOT NULL,
    sort_order INT NOT NULL,
    included BOOLEAN NOT NULL DEFAULT TRUE,
    overrides_json TEXT NULL,
    effective_rules_json TEXT NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_template_items PRIMARY KEY (id),
    CONSTRAINT uq_template_item_version UNIQUE (template_version_id, master_item_version_id),
    CONSTRAINT fk_template_item_version FOREIGN KEY (template_version_id) REFERENCES template_versions (id),
    CONSTRAINT fk_template_item_workshop FOREIGN KEY (workshop_id) REFERENCES workshops (id),
    CONSTRAINT fk_template_item_master_version FOREIGN KEY (master_item_version_id) REFERENCES master_item_versions (id)
);

CREATE TABLE inspection_jobs (
    id BINARY(16) NOT NULL,
    workshop_id BINARY(16) NOT NULL,
    reference VARCHAR(40) NOT NULL,
    status VARCHAR(32) NOT NULL,
    template_version_id BINARY(16) NOT NULL,
    assigned_technician_id BINARY(16) NULL,
    created_by BINARY(16) NOT NULL,
    scheduled_at DATETIME(6) NULL,
    cancelled_at DATETIME(6) NULL,
    cancel_reason VARCHAR(255) NULL,
    customer_name VARCHAR(200) NOT NULL,
    customer_phone VARCHAR(40) NULL,
    customer_email VARCHAR(320) NULL,
    vehicle_make VARCHAR(100) NOT NULL,
    vehicle_model VARCHAR(100) NOT NULL,
    vehicle_year INT NULL,
    vehicle_vin VARCHAR(40) NULL,
    vehicle_plate VARCHAR(40) NULL,
    scope VARCHAR(500) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    version INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_inspection_jobs PRIMARY KEY (id),
    CONSTRAINT uq_inspection_job_reference UNIQUE (workshop_id, reference),
    CONSTRAINT fk_inspection_job_workshop FOREIGN KEY (workshop_id) REFERENCES workshops (id),
    CONSTRAINT fk_inspection_job_template_version FOREIGN KEY (template_version_id) REFERENCES template_versions (id),
    CONSTRAINT fk_inspection_job_technician FOREIGN KEY (assigned_technician_id) REFERENCES users (id),
    CONSTRAINT ck_inspection_job_status CHECK (status IN (
        'DRAFT', 'SCHEDULED', 'ASSIGNED', 'IN_PROGRESS',
        'READY_TO_FINALIZE', 'FINALIZED', 'CANCELLED'))
);

CREATE TABLE job_assignments (
    id BINARY(16) NOT NULL,
    workshop_id BINARY(16) NOT NULL,
    job_id BINARY(16) NOT NULL,
    technician_id BINARY(16) NOT NULL,
    assigned_by BINARY(16) NOT NULL,
    assigned_at DATETIME(6) NOT NULL,
    unassigned_at DATETIME(6) NULL,
    reason VARCHAR(255) NULL,
    CONSTRAINT pk_job_assignments PRIMARY KEY (id),
    CONSTRAINT fk_job_assignment_workshop FOREIGN KEY (workshop_id) REFERENCES workshops (id),
    CONSTRAINT fk_job_assignment_job FOREIGN KEY (job_id) REFERENCES inspection_jobs (id),
    CONSTRAINT fk_job_assignment_technician FOREIGN KEY (technician_id) REFERENCES users (id)
);

CREATE INDEX ix_workshop_templates_status ON workshop_templates (workshop_id, status);
CREATE INDEX ix_template_versions_template ON template_versions (template_id, version_no);
CREATE INDEX ix_template_versions_workshop_status ON template_versions (workshop_id, status);
CREATE INDEX ix_template_items_version_order ON template_items (template_version_id, sort_order);
CREATE INDEX ix_inspection_jobs_workshop_status ON inspection_jobs (workshop_id, status, created_at);
CREATE INDEX ix_inspection_jobs_technician ON inspection_jobs (workshop_id, assigned_technician_id, status);
CREATE INDEX ix_inspection_jobs_template_version ON inspection_jobs (template_version_id);
CREATE INDEX ix_job_assignments_job ON job_assignments (job_id, assigned_at);
CREATE INDEX ix_job_assignments_technician ON job_assignments (technician_id, unassigned_at);
