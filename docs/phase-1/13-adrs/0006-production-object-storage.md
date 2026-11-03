# ADR-0006: Production object storage shortlist

- **Status:** Proposed — D6 Pending
- **Date:** 3 November 2026
- **Owner:** Technical lead
- **Evidence:** `docs/phase-1/12-spike-results.md` §4

## Context

Phase 0 found MinIO OSS archived/no longer maintained and therefore unsuitable for production. The platform stores private evidence, guide images and PDFs. The UAE is the first market; data residency and encryption matter. The application should use the S3 API so the provider can change.

## Options

1. AWS S3 `me-central-1` (UAE).
2. OCI Object Storage UAE (`me-dubai-1`/`me-abudhabi-1`).
3. Cloudflare R2 (no UAE jurisdiction; EU/US/FedRAMP available).
4. Self-hosted Ceph RGW (LGPL, mature, heavy ops).
5. Self-hosted SeaweedFS (Apache-2.0, lighter).
6. Garage (AGPL-3.0, small-team).
7. MinIO OSS (local dev only).
8. Backblaze B2 (cost reference; no UAE region verified).

## Decision

**Pending:** shortlist **AWS S3 UAE** and **OCI Object Storage UAE** for production. Keep **MinIO local-development only**, pinned and labelled dev-only. Do not commit to a provider until a one-day proof and legal review of residency/terms.

## Consequences

- Managed providers reduce operational risk but add cost and contract dependencies.
- OCI’s S3 Compatibility API is a subset; feature parity must be tested.
- R2 is attractive on egress but cannot be the default for UAE data without counsel approval.
- Self-hosting requires real operational capability; Ceph is not a small-team default.
- The S3 boundary keeps migration feasible.

## Follow-ups

- Approve D6.
- Run the Phase 2 proof: private bucket, pre-signed PUT/GET, multipart, lifecycle, versioning, object lock, encryption/KMS, CORS, latency, cost, deletion, backup.
- Confirm data-processing terms and residency.
- Document the provider adapter and migration path.

## What was not proven

Actual pricing, contract terms, KMS configuration, residency guarantees, performance, OCI feature parity, or operational effort.
