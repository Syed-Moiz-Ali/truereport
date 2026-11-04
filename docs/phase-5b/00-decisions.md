# Phase 5B Decisions

**Project:** TrueReport  
**Date:** 4 November 2026  
**Status:** Accepted for Phase 5B unless marked Pending

---

## 1. Evidence rules

| ID | Decision | Status | Notes |
|---|---|---|---|
| P5B-E1 | Evidence is blocking at finalization | Accepted | Required, minimum-photo and required-count rules are evaluated against verified evidence. Missing evidence returns `EVIDENCE_REQUIRED`. |
| P5B-E2 | Evidence hard limit is 8 MB per file | Accepted | Server rejects larger payloads. Client compresses before hashing and upload. |
| P5B-E3 | JPEG and HEIC/HEIF are accepted input types | Accepted | JPEG normalization is verified. HEIC normalization is not verified because native `libheif` is absent. |
| P5B-E4 | Store a normalized JPEG derivative | Accepted | Original is retained privately; normalized output is EXIF-free and hash-recorded. |
| P5B-E5 | Upload tokens expire after 15 minutes | Accepted | Token is hashed at rest. Init is idempotent by evidence ID plus content hash. |
| P5B-E6 | Evidence is separate from guide images | Accepted | Guide images are instructional master content; evidence is inspection-owned. |
| P5B-E7 | Finalized evidence is immutable | Accepted | Service guards plus MySQL triggers reject update/delete after finalization. |
| P5B-E8 | Pre-finalization evidence can be soft-deleted | Accepted | Deletion does not physically remove the object immediately. |
| P5B-E9 | No video evidence in 5B | Accepted | Photo evidence only. |
| P5B-E10 | No evidence is fabricated or auto-generated | Accepted | Empty evidence is represented as missing, never as a placeholder photo. |

---

## 2. Offline and sync

| ID | Decision | Status | Notes |
|---|---|---|---|
| P5B-O1 | Drift is the local store | Accepted | Local SQLite via `drift_flutter`; web uses the Drift WASM assets. |
| P5B-O2 | Local save happens before server sync | Accepted | Assessment/customer/vehicle/consent/evidence are written locally first. |
| P5B-O3 | Queue states are explicit | Accepted | `PENDING`, `FAILED`, `SYNCING`, `CONFLICT`. |
| P5B-O4 | Local work is labeled "Saved on this phone" | Accepted | Checklist rows, review screen and sync queue expose local state. |
| P5B-O5 | Server receipt is labeled separately | Accepted | Successful sync updates cached item state to `RECEIVED`. |
| P5B-O6 | Version conflicts are visible | Accepted | HTTP `409`/version conflicts mark the operation `CONFLICT`; local assessment is not silently overwritten. |
| P5B-O7 | Sync triggers | Accepted | Best-effort after save/capture, automatic on reconnect, and manual "Sync now". No OS background worker in 5B. |
| P5B-O8 | Finalization requires an empty pending queue | Accepted | Client disables finalization while queued/conflicting work exists; server still validates evidence and job state. |
| P5B-O9 | Photo bytes are stored locally until verified | Accepted | Drift stores compressed bytes, MIME, SHA-256 and state. This is not a long-term media store. |
| P5B-O10 | Guide images are cached per job/item | Accepted | Offline render uses the cached bytes; online fetch refreshes the cache. |

---

## 3. Server and storage

| ID | Decision | Status | Notes |
|---|---|---|---|
| P5B-S1 | Evidence metadata lives in `evidence_assets` | Accepted | V9 adds normalized fields, hashes, token and soft-delete fields. |
| P5B-S2 | Local disk storage is development-only | Accepted | `LocalObjectStorage`; D6 production S3-compatible storage remains Pending. |
| P5B-S3 | Docker Compose uses a persistent server storage volume | Accepted | `server_storage:/app/.truereport-storage`; directory is owned by the app user. |
| P5B-S4 | MinIO remains an optional profile | Accepted | The pinned MinIO OSS image is unavailable/archived; default 5B stack does not require it. |
| P5B-S5 | Captured timestamps accept ISO-8601 with `Z`/offset | Accepted | Converted to UTC local date-time for storage. |
| P5B-S6 | MySQL V9 is the current migration head | Accepted | V1-V9 validated on MySQL 8.4.13. |

---

## 4. Unchanged or pending

- D6 production object storage: **Pending**.
- D7 forms package: **Pending**.
- D8 messaging providers: **Pending**.
- D11 production photo limits/retention: **Pending**; 8 MB is a Phase 5B implementation limit only.
- C2 legal consent/retention: **Pending**.
- Customer/vehicle data remains fake-only and unencrypted.
- No report, PDF, public link, delivery, correction, manager queue, customer portal or payment work in 5B.
