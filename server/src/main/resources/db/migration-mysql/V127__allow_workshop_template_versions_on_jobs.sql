-- A clean job can be created from either a platform master template version
-- (platform_template_versions) or a workshop-owned published version
-- (template_versions). The application resolves and tenant-scopes both before
-- inserting the job, so the single-table FKs must be removed.
ALTER TABLE platform_jobs DROP FOREIGN KEY fk_platform_job_template_version;
ALTER TABLE platform_job_checklists DROP FOREIGN KEY fk_platform_job_checklist_template;
