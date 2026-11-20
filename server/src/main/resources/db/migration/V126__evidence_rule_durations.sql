-- Phase 2a-3: optional video duration window on evidence rules.
-- Additive only; existing rows remain unconstrained (NULL).
ALTER TABLE platform_evidence_rules ADD COLUMN min_duration_seconds INT NULL;
ALTER TABLE platform_evidence_rules ADD COLUMN max_duration_seconds INT NULL;
