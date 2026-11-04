# Phase 5B - Offline Work and Photo Evidence

**Status:** Implemented and locally verified. Real-device offline/camera matrix is still not run.

## Scope delivered

- Drift-backed local cache for technician jobs, checklists, assessments, customer, vehicle, consent and guide images.
- Durable sync queue with `PENDING`, `FAILED`, `CONFLICT` and `SYNCING` states.
- Offline-first assessment save: local save first, then server sync; queued work is visibly marked as saved on the phone.
- Offline customer, vehicle and consent edits with queued sync.
- Camera/gallery evidence capture with client JPEG compression and SHA-256.
- Local evidence bytes stored in Drift until upload; offline photos survive app restart.
- Evidence init/upload/complete APIs, 15-minute upload token, source-hash verification and idempotent init.
- Server normalization to JPEG, EXIF-free output, 8 MB hard limit and 40 MP decode guard.
- Evidence count validation blocks finalization with `EVIDENCE_REQUIRED` until the pinned item rule is satisfied.
- Final snapshot includes evidence IDs, source/normalized hashes and `evidenceState`.
- Guide-image download and offline cache/render in the technician item screen.
- Sync queue screen, pending-count badge, automatic retry on reconnect and immediate best-effort sync after save/capture.
- Finalization blocked locally while the sync queue has pending or conflicting work; server remains authoritative.
- MySQL V9 migration and V8 evidence immutability triggers verified on MySQL 8.4.13.

## Explicitly not in Phase 5B

- Report/PDF/public link/delivery.
- Correction UI/API, manager/review queue, customer portal or payments.
- Video evidence.
- Production object storage. D6 remains Pending; local disk storage is development-only.
- OS-level background upload scheduling. Sync runs after save/capture, on reconnect and from the queue screen.

## Key decisions

- Evidence hard limit is **8 MB per file**.
- Client targets roughly 1-2 MB JPEGs; it compresses before hashing and upload.
- JPEG and HEIC/HEIF are accepted by the server contract. HEIC server normalization is **not proven** because native `libheif` is unavailable in this environment; the client normalizes camera output to JPEG.
- Required evidence is blocking, not a warning. `EVIDENCE_REQUIRED` replaces the Phase 5A `EVIDENCE_PENDING_5B` rule.
- Evidence is separate from instructional guide images.
- Finalized evidence is immutable; before finalization it can be soft-deleted.
- Offline queue operations are idempotent by operation ID/evidence ID. A server `409` becomes a visible `CONFLICT`, not silent data loss.
- No evidence is fabricated. A finalized inspection only claims evidence that exists and has been verified.
- D6, D7, D8, D11 and C2 remain Pending. D11's provisional 5B limit is 8 MB, not a production retention policy.

## Documents

- `00-decisions.md`
- `test-report.md`
- `risk-register-update.md`
- `BLOCKED.md` (historical gate, now resolved)
- `docker-install-log.md`
