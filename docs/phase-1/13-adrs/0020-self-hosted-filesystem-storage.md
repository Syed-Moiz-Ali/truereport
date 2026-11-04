# ADR-0020: Self-hosted filesystem storage supersedes cloud storage for D6

- **Status:** Accepted by owner, Phase 8.1
- **Date:** 4 November 2026
- **Supersedes:** the production-storage part of ADR-0006 / D6
- **Owner:** Product owner + Engineering/Ops

## Context

The owner decided that no cloud object storage (Amazon S3 or equivalent) will be used. Evidence photos, guide images, report PDFs and public derivatives live on the organisation's own server. The backend is deployed behind a domain and serves files through authorized backend endpoints.

The prior D6 shortlist assumed an S3-compatible provider. It is no longer the production direction.

## Decision

- Production storage is the self-hosted **filesystem** behind the existing `ObjectStorage` interface.
- The storage root is a configured persistent volume, outside the application image.
- `FileSystemObjectStorage` provides atomic temp-file+rename writes, SHA-256 checksum sidecars, path-traversal protection, restrictive permissions, quota/object-size checks, free-space reserve checks and checksum verification on read.
- Objects are **never** served by Nginx or Spring static-resource handlers. Private files are streamed only via role/tenant-authorized backend endpoints; public report photos/PDFs only via the token/revocation-checked `/r/{token}` endpoints.
- `LocalObjectStorage` remains development-only. Production startup rejects it.
- The S3 adapter is retained as an optional, disabled-by-default alternative. It is unused for this deployment and no cloud account is required.
- Backups include the database and storage bundle, are encrypted, and support a configurable off-site copy command.
- Disk encryption at rest is a host/volume control, not provided by the application. Use full-disk or volume encryption and document key custody.

## Consequences

- A single server/volume is a single point of failure unless replicated/backed up.
- Capacity, disk health, monitoring and restore drills become critical.
- Files are not directly addressable by URL; every read has a backend authorization path.
- Backup bundles contain PII and evidence and must be encrypted, access-controlled and stored off-site.
- The owner must choose the off-site destination and host/volume encryption method.

## Follow-ups

- Configure the persistent volume and minimum free-space reserve.
- Enable full-disk/volume encryption and off-site backup.
- Run periodic storage/database restore drills.
- Keep the S3 adapter untouched but unused; document any future reversal as a new ADR.

## What was not proven

- Production host/volume encryption and key custody.
- Off-site destination configuration.
- Disk-failure/failover behaviour.
- Real-customer data use.
