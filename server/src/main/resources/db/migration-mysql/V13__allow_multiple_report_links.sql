-- Phase 7: a report may have multiple active links, one per delivery request.
ALTER TABLE public_share_links DROP INDEX uq_public_share_report;
CREATE INDEX ix_public_share_report_created
    ON public_share_links (report_version_id, created_at);
