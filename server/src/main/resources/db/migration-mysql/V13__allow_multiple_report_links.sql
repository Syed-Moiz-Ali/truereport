-- Phase 7: a report may have multiple active links, one per delivery request.
ALTER TABLE public_share_links DROP FOREIGN KEY fk_public_share_version;
ALTER TABLE public_share_links DROP INDEX uq_public_share_report;
CREATE INDEX ix_public_share_report_created
    ON public_share_links (report_version_id, created_at);
ALTER TABLE public_share_links ADD CONSTRAINT fk_public_share_version
    FOREIGN KEY (report_version_id) REFERENCES report_versions (id);
