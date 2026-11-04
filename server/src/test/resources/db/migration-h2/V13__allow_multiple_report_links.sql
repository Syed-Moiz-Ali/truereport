-- H2 test equivalent of the MySQL link uniqueness change.
ALTER TABLE public_share_links DROP CONSTRAINT uq_public_share_report;
CREATE INDEX ix_public_share_report_created
    ON public_share_links (report_version_id, created_at);
