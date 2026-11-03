# Phase 4 Decision Record

**Project:** TrueReport  
**Date:** 3 November 2026  
**Status:** Phase 4 implementation decisions. Phase 1 approved product decisions remain authoritative. D6, D7, D8, D11 and C2 remain Pending.

---

## 1. Workshop accounts and staff

| ID | Decision | Status | Notes |
|---|---|---|---|
| P4-W1 | Workshop Admin staff screen is read-only | Accepted for Phase 4 | RQ3 in `docs/phase-1/00-decisions.md` says Platform Admin creates all accounts. No Workshop Admin invitation endpoint was added. |
| P4-W2 | Workshop Admin can list only their own workshop staff | Accepted for Phase 4 | Existing `GET /api/v1/workshop/staff`; masked email only. |
| P4-W3 | Technician walk-in creation is not enabled | Accepted for Phase 4 | RQ12 requires a workshop policy for authorising technician walk-ins; no policy exists. Workshop Admin can create walk-in jobs. |
| P4-W4 | Technician job read endpoint shows assigned jobs plus jobs created by that technician | Accepted for Phase 4 | `GET /api/v1/technician/jobs`; no technician inspection or answer editing. |

---

## 2. Jobs

| ID | Decision | Status | Notes |
|---|---|---|---|
| P4-J1 | Workshop Admin job endpoints are WA-only and workshop-scoped | Accepted for Phase 4 | No Platform Admin job oversight endpoint in Phase 4. Cross-workshop access is a neutral 404. |
| P4-J2 | Job statuses are the master.md set | Accepted for Phase 4 | `DRAFT`, `SCHEDULED`, `ASSIGNED`, `IN_PROGRESS`, `READY_TO_FINALIZE`, `FINALIZED`, `CANCELLED`. Phase 4 creates `DRAFT`/`SCHEDULED`, assigns to `ASSIGNED` and cancels to `CANCELLED`; later states are Phase 5. |
| P4-J3 | Job creation pins `template_version_id` | Accepted for Phase 4 | The template version must be published and owned by the caller's workshop; retired templates cannot be selected for a new job. |
| P4-J4 | Assignment and reassignment are audited and before finalization | Accepted for Phase 4 | Reassignment closes the previous active assignment and records a new one. |
| P4-J5 | Job customer/vehicle fields are stored on the job | Accepted for Phase 4 with risk | Phase 4 has no full encrypted intake table. This is flagged in the risk register; Phase 5/6 must settle encryption and retention with C2. |

---

## 3. Templates

| ID | Decision | Status | Notes |
|---|---|---|---|
| P4-T1 | Template items reference `master_item_version_id` | Accepted for Phase 4 | Never a live “latest item” reference. |
| P4-T2 | Template items snapshot labels, instructions and effective rules | Accepted for Phase 4 | Stored in `template_items.effective_rules_json`; old template versions remain readable after master updates/retirement. |
| P4-T3 | No workshop overrides in Phase 4 | Accepted for Phase 4 | Master content has no exposed `overridable` allowlist, so the safe rule is “none”. The server rejects any override field or map with `422 TEMPLATE_WEAKENS_SAFETY_RULE`. |
| P4-T4 | Workshop can select only published master item versions | Accepted for Phase 4 | Retired items/versions are rejected for new drafts; old published template versions still render. |
| P4-T5 | Editing a published template requires a new draft | Accepted for Phase 4 | `POST /templates/{id}/draft` copies the current published version; publish creates a new immutable version. |
| P4-T6 | Existing jobs keep their pinned template version | Accepted for Phase 4 | Job stores `template_version_id`; publishing v2 does not migrate jobs. |
| P4-T7 | Template preview is EN/AR from the pinned snapshot | Accepted for Phase 4 | The UI toggles English/Arabic labels and instructions without editing master content. |

---

## 4. Immutability hardening

| ID | Decision | Status | Notes |
|---|---|---|---|
| P4-I1 | MySQL triggers protect published master item versions | Accepted for Phase 4; **untested** | `V6__immutability_triggers.sql` is in the MySQL-only Flyway location. Docker/MySQL is unavailable, so this is not locally verified. |
| P4-I2 | MySQL triggers protect published template versions/items | Accepted for Phase 4; **untested** | Same limitation. Service-level guards are tested. |
| P4-I3 | H2 tests use common migrations only | Accepted for Phase 4 | MySQL trigger syntax is not H2-compatible; `application-test.yml` keeps `classpath:db/migration`. |
| P4-I4 | Service-level rejection remains the primary control | Accepted for Phase 4 | Published versions have no update/delete service paths. |

---

## 5. UI

| ID | Decision | Status | Notes |
|---|---|---|---|
| P4-U1 | Use only the existing central design system | Accepted for Phase 4 | No new hardcoded colours, fonts, radii or paddings. |
| P4-U2 | Add all new paths to `ApiEndpoints` | Accepted for Phase 4 | No raw `/api/v1` strings outside the endpoints class. |
| P4-U3 | Responsive Workshop Admin shell | Accepted for Phase 4 | Tabs on phone/tablet; `NavigationRail` at >= 900 logical pixels. |
| P4-U4 | No master content hardcoded in Flutter | Accepted for Phase 4 | Builder content comes from `/api/v1/workshop/master/...`. |

---

## 6. Pending or unchanged

D6 production object storage, D7 forms package, D8 messaging providers, D11 photo limits and C2 legal consent/retention remain Pending. No correction UI/API, manager review, customer portal or payment feature was added.
