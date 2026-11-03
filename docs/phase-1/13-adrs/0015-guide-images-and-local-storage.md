# ADR-0015: Guide images are separate from evidence; local dev storage

- **Status:** Accepted for Phase 3; production storage D6 remains Pending
- **Date:** 3 November 2026
- **Owner:** Backend lead

## Context

The master library needs guide images that teach a technician where/how to inspect. These must never be presented as evidence of an inspected vehicle. Production object storage (D6) is still pending; MinIO is local-only.

## Decision

- Guide images live in `guide_images` with their own ID, storage key, content hash, MIME, size, status, licence note and localized alt text.
- A guide image is referenced by a master item version; it is not an `evidence_asset` and has no inspection link.
- The admin UI labels the asset as a guide image and the public/evidence renderer must not treat it as evidence.
- Phase 3 uses `LocalObjectStorage`, a filesystem implementation behind the existing `ObjectStorage` interface, for development/tests only.
- Production must use an S3-compatible provider behind the same interface. MinIO remains local development only.

## Consequences

- Guide upload works locally without Docker/MinIO.
- The local filesystem is not a production storage solution and has no CDN, object lock, or multi-server durability.
- The S3-compatible boundary is preserved for D6.

## Follow-ups

- Implement an S3-compatible `ObjectStorage` adapter when D6 is decided.
- Add image dimension extraction/virus scanning/EXIF handling before production.
- Add a test that guide images cannot be serialized as evidence.

## What was not proven

No real MinIO/S3 upload was run because Docker is not installed. Image dimensions are not extracted in Phase 3. Production storage is not selected.
