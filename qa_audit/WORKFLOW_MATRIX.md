# Workflow Matrix — TrueReport

## A. Inspection lifecycle (primary revenue flow) — executed end-to-end

Job `JOB-599E2DEB` / plate `QA-18728364` / 3-item "E2E Quick Check" / Workshop A / Technician A.
Raw log: `evidence/workflow-e2e.log`. **24/24 checks passed.**

| # | Step | Role | Endpoint / UI | Result |
|---|---|---|---|---|
| W1 | Published template available | admin | `GET /workshop/template-versions/available` | PASS (3-item template) |
| W2 | Technician fixture | admin | `GET /workshop/staff` | PASS |
| W3 | Create job | admin | `POST /workshop/jobs` (201, ASSIGNED) | PASS |
| W4 | Duplicate create, same Idempotency-Key | admin | same | PASS (same id, one row) |
| W5 | Job appears in technician queue | tech | `GET /technician/jobs` | PASS (total 108→109) |
| W6–W8 | Vehicle cover photo init/upload/complete | tech | `/vehicle-photo` | PASS (READY) |
| W9 | Pinned checklist | tech | `GET .../checklist` | PASS (3 items, v1) |
| W9b | Photo + video per item | tech | `/evidence/init → PUT → complete` | PASS (6 × VERIFIED) |
| W10 | Assess every item | tech | `PUT .../items/{code}` | PASS 3/3 |
| W11 | Signature blocker before signing | tech | `GET .../summary` | PASS |
| W12 | Signature | tech | `POST .../signature` | PASS (hash recorded) |
| W13 | No blockers, score computed | tech | `GET .../summary` | PASS (100, no blockers) |
| W14 | Complete | tech | `POST .../complete` | PASS (PENDING_REVIEW) |
| W15 | Publish before approval rejected | admin | `POST .../publish` | PASS (409 JOB_NOT_APPROVED) |
| W16 | Admin review sees 3/3 | admin | `GET .../review` | PASS |
| W17 | Approve | admin | `POST .../approve` | PASS (APPROVED, v5) |
| W18 | Approve twice | admin | `POST .../approve` | PASS (409) |
| W19 | Publish | admin | `POST .../publish` | PASS (ACTIVE link) |
| W20 | Report snapshot is job-specific | admin | `GET .../report` | PASS (`reportNumber` = own ref) |
| W21 | Public page identifies only this job | public | `GET /r/{token}` | PASS (1 ref, own) |
| W22 | No customer PII on public page | public | same | PASS |
| W23 | Published state reflected in list/counts | admin | `GET /workshop/jobs/counts` | PASS (published 6→7) |

**DB verification for `JOB-599E2DEB`:** `PUBLISHED / APPROVED / PUBLISHED`, score 100, grade A, `signature_present=1`, 3 assessments, 6 evidence assets, 1 report version, snapshot report number = `JOB-599E2DEB`, 1 ACTIVE public link.

**Conclusion:** the current write path is correct. BUG-001 is pre-existing corrupted data, not a reproducible code path.

## B. Public report integrity across all published jobs

| Job | Status | Snapshot report number | Matches job? |
|---|---|---|---|
| JOB-02F2ED6E | PUBLISHED | JOB-02F2ED6E | yes |
| JOB-1B05BA9A | PUBLISHED | JOB-1B05BA9A | yes |
| JOB-89211E61 | PUBLISHED | JOB-89211E61 | yes |
| JOB-EE3271A8 | PUBLISHED | JOB-EE3271A8 | yes |
| JOB-FF169B0D | PUBLISHED | JOB-FF169B0D | yes |
| **JOB-98D5FD5D** | PUBLISHED | **JOB-89211E61** | **NO — BUG-001** |
| JOB-599E2DEB (new) | PUBLISHED | JOB-599E2DEB | yes |

Additional state check: `JOB-98D5FD5D` has `/publish-checklist` `ready:false` (0/30 assessed, no signature, no score) yet is published with an ACTIVE link. Other published jobs are `ready:true` (3/3).

## C. Workshop/staff management — partially executed

| Flow | Steps | Result |
|---|---|---|
| List staff | `GET /workshop/staff` + Staff tab | PASS (3 members, masked emails, role filters 1/2) |
| Invite technician | `POST /workshop/technicians` | NOT TESTED (would send a real invitation email) |
| Disable / reactivate account | platform hierarchy endpoints | NOT TESTED (avoids mutating real users) |
| Transfer account | platform hierarchy | NOT TESTED |
| Workshop create/edit | `/workshops/new`, edit dialog | PARTIAL (form opens with real values; write not executed on real tenants) |
| Deactivate workshop | button opens destructive path | NOT TESTED |

## D. Master content → template → job

| Step | Result |
|---|---|
| Categories/items/option sets load from API | PASS (`/platform/master/*`, 30 items, 11 categories) |
| Template draft → publish → available | PASS (existing published versions visible; empty template also publishable — BUG-014) |
| Pinned checklist in job | PASS (`pinned: v1`, item count matches) |
| Item edit screen loads served data | PASS (E2E `item editor opens with the served reference data`) |
| Master item create/edit writes | NOT TESTED (no disposable master item created) |

## E. Localization distribution

| Step | Result |
|---|---|
| Register language (E2E adds `de`, then retires) | PASS |
| Manual translation edit + restore | PASS (E2E) |
| Machine Spanish queue visible | PASS (E2E) |
| Client manifest | Workshop/Technician: en + es; Platform: en only |
| Dashboard live-language KPI | 3 (en/es/fr) |
| French readiness | **0%** → BUG-006 |
| UI switch to Español persists after reload | PASS (E2E `selecting Español … survives a reload`) |

## F. Interrupted / negative workflows

| Scenario | Expected | Result |
|---|---|---|
| Duplicate create (same idempotency key) | one job | PASS (same id) |
| Publish before approval | 409 | PASS |
| Approve twice | 409 | PASS |
| Complete with missing evidence | 422 + blockers | PASS (blocks) |
| Complete with missing signature | 422 + `SIGNATURE_MISSING` | PASS |
| Duplicate evidence bytes in one job | rejected | 409 "already uploaded" |
| Evidence photo as PNG | accepted | **FAIL — BUG-004** |
| Video shorter than 15 s | rejected | PASS (`DURATION_INVALID`) |
| Fabricated video bytes | rejected | **FAIL — BUG-011 (accepted, VERIFIED)** |
| Invalid VIN | 422 `VIN_INVALID` | PASS |
| Malformed UUID path | 400/404 | 404 (accepted) |
| Wrong password | stay on sign-in + message | PASS |
| Empty sign-in submit | inline "This field is required." | PASS |
| Browser Back inside technician workspace | visible navigation | **FAIL — URL never changes (BUG-013)** |
| Refresh on technician item page | return to same screen | **FAIL — returns to queue (BUG-013)** |
| Session refresh at boot | transparent | PASS (one 401 then refresh) |
| 30-item template completion | possible | **BLOCKED by evidence rules (BUG-010)** — 60 captures required |
| Workshop Admin enters Platform app | denied/redirect | **FAIL — generic error shell (BUG-002)** |
| Technician enters Workshop app | `/unauthorized` | PASS (copy wrong — BUG-015) |
| Workshop Admin enters Technician app | `/unauthorized` | PASS (copy wrong — BUG-015) |

## H. Job UPDATE / DELETE (soft) — 9/9 checks

| # | Check | Expected | Actual |
|---|---|---|---|
| R1 | Read disposable job | 200 | 200, ASSIGNED v1 |
| U1 | Full update (PUT) with new phone | 200 | 200, phone changed, version 2 |
| U2 | Re-read shows the change | persisted | persisted |
| U3 | Stale `version` on update | 409 | 409 `VERSION_CONFLICT` |
| D1 | Cancel (soft delete) | 200 CANCELLED | 200 CANCELLED |
| D2 | Repeat cancel | 409 | 409 `JOB_ALREADY_CANCELLED` |
| D3 | Read cancelled job | 200 | 200, CANCELLED |
| D4 | Update after cancel | 409 | 409 `JOB_NOT_EDITABLE` |
| D5 | Counts include cancellation | cancelled +1 | 36 (from 35) |

Evidence: `evidence/crud-job.log`, `evidence/db-crud-verification.txt`.
Note: `PUT /workshop/jobs/{id}` is a **full replacement** — a partial body returns 422 `JOB_VALIDATION_FAILED`. This is a defensible contract but worth documenting for integrators (PATCH is not offered).

## I. Dependency map (observed)

```
master categories/items/option-sets
        └─ platform template versions (publish)
                └─ workshop template (pin version)
                        └─ job create (templateVersionId)
                                ├─ assignment (technician)
                                ├─ pinned checklist (3 or 30 items)
                                ├─ assessments + evidence (photo/video rules)
                                ├─ signature ──► complete (PENDING_REVIEW)
                                ├─ approve (creates report_version snapshot)
                                └─ publish (public_link + documents + PDF)
                                        └─ /r/{token} public report
```

Breaking points found: empty published template (BUG-014), evidence rules that block "all clear" inspections (BUG-010), and a corrupted snapshot breaking the last link (BUG-001).
