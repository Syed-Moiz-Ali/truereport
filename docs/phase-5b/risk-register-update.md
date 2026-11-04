# Phase 5B Risk Register Update

**Project:** TrueReport  
**Date:** 4 November 2026  
**Baseline:** `docs/phase-5/risk-register-update.md`

---

## 1. Closed or reduced risks

| ID | Previous risk | Status | Evidence / remaining note |
|---|---|---|---|
| R71 | Docker was unavailable; MySQL path unverified | **Closed for this environment** | Docker Desktop 4.98.0 / engine 29.9.2 running; Compose stack and MySQL 8.4.13 verified. CLI is still not permanently on PATH. |
| R74 | MySQL V6/V8 triggers, including evidence, were untested | **Closed** | V1-V9 applied on MySQL 8.4; direct SQL rejected finalized assessment/snapshot/job/evidence updates and deletes. |
| R81 | Phase 5A evidence requirements were non-blocking warnings | **Closed** | `EVIDENCE_REQUIRED` now blocks review/ready/finalize until verified evidence meets the pinned rule. |
| R83 | MySQL inspection triggers written but unproven | **Closed** | `MySqlMigrationIT` and direct SQL trigger checks pass, including evidence triggers. |
| R85 | Concurrency tested only on H2 | **Closed** | Real MySQL concurrent same-key finalization returned the same finalized snapshot hash. |
| R88 | Guide images not shown in technician assessment | **Mitigated** | Guide-image endpoint wired; image is rendered and cached offline. Real-device visual check remains. |
| R84 | Offline mode and local persistence absent | **Substantially mitigated** | Drift cache, sync queue, offline assessments/edits/evidence and reconnect retry implemented. Physical-device offline matrix remains unrun. |

---

## 2. New or remaining risks

| ID | Risk | Impact | Likelihood | Score | Mitigation | Early warning |
|---|---|---|---|---|---|---|
| R90 | HEIC server normalization depends on unavailable native `libheif` | 3 | 4 | 12 High | Client normalizes camera output to JPEG before upload; document HEIC limitation; add native lib only if server-side HEIC is required | A HEIC upload reaches the server without client normalization and fails normalization |
| R91 | Offline photo bytes in Drift can grow the local database | 3 | 3 | 9 Medium | Compress to ~1-2 MB, delete/mark after server receipt, add storage budget/cleanup before pilot | Local DB growth or low-storage save failures |
| R92 | Real-device offline/camera/airplane/kill-app matrix not run | 4 | 4 | 16 High | Run on Android and iOS before pilot; include permission denial, 100+ items and low storage | Camera/file picker works in tests but fails on hardware |
| R93 | Local disk storage is development-only | 4 | 3 | 12 High | Keep D6 production object storage Pending; do not deploy local storage to production | Production deployment uses `LocalObjectStorage` |
| R94 | Sync is not an OS background worker | 3 | 3 | 9 Medium | Sync on save, reconnect and manual action; queue survives restart; add background scheduling if pilot requires it | User expects upload while app is closed |
| R95 | Offline conflict resolution is intentionally simple | 3 | 3 | 9 Medium | Show `CONFLICT`; user can re-edit/re-save; server remains authoritative | Conflict state has no clear recovery on device |
| R96 | Additive V9 migration increases schema surface | 2 | 2 | 4 Low | V9 is additive; tested on H2 and MySQL; no destructive change | Migration fails or old client cannot read new columns |
| R97 | MinIO pinned image remains unavailable | 2 | 4 | 8 Medium | MinIO is optional profile; local storage used for 5B; D6 remains open | Any environment requires MinIO for evidence |
| R98 | Evidence/photos are not encrypted at rest on the phone | 4 | 3 | 12 High | Fake-only data; local DB/app sandbox; encryption and retention remain C2/D11 work | Real customer data on an unencrypted device |
| R99 | No video evidence | 2 | 3 | 6 Medium | Explicitly out of 5B scope; photo evidence only | Requirement changes to video without a new phase |

---

## 3. Unchanged risks

- R82/R89: customer/vehicle PII remains fake-only and unencrypted; final snapshot contains customer/vehicle data.
- R86/R87: low-end device performance, RTL/keyboard/accessibility matrix still require manual device testing.
- D6 production storage, D7 forms package, D8 messaging, D11 final photo/retention policy and C2 legal retention remain Pending.
- No report, PDF, public link, delivery, correction, manager queue, customer portal or payments work in 5B.

---

## 4. Top Phase 5B risks

1. R92 real-device offline/camera matrix not run.
2. R98 local evidence/PII not encrypted at rest.
3. R90 HEIC server normalization unverified.
4. R93 local storage is not production storage.
5. R91 local evidence database growth.
6. R94 no OS background sync.
7. R95 simple conflict recovery.
