# Phase 4 Risk Register Update

**Project:** TrueReport  
**Date:** 3 November 2026  
**Baseline:** `docs/phase-3/risk-register-update.md` and `docs/phase-1/14-risk-register-update.md`

---

## 1. New and updated risks

| ID | Risk | Impact | Likelihood | Score | Mitigation | Early warning |
|---|---|---|---|---|---|---|
| R61 | Published master/template versions could be changed by direct SQL | 4 | 3 | 12 High | Service/API guards plus MySQL-only triggers in `migration-mysql/V6`; triggers are **untested locally** because Docker is absent | A published row changes without a new version |
| R13 | Master edits/retirement change old jobs/templates | 4 | 2 | 8 Medium | Template items pin version IDs and snapshot labels/instructions/rules; tests cover v1 after v2/retirement | Old template preview changes after master publish |
| R72 | Workshop Admin cannot invite staff, while the Phase 4 brief says “list and invite” | 3 | 3 | 9 Medium | Followed approved RQ3: Platform Admin creates accounts; staff screen is read-only and explains this | Workshop expects an invite button |
| R73 | Technician walk-in creation is not enabled | 3 | 3 | 9 Medium | RQ12 requires a workshop policy; WA can create walk-in jobs, technician creation needs an approved policy | Workshop asks technicians to create walk-ins |
| R74 | MySQL immutability triggers are untested | 4 | 4 | 16 High | Run `MySqlMigrationIT` in Docker CI before production; keep service-level guards; document untested | Trigger creation fails in CI or a direct SQL update succeeds |
| R75 | Job customer/vehicle data is stored in plain columns in Phase 4 | 4 | 3 | 12 High | Treat Phase 4 data as fake/pilot only; encryption/retention must be resolved before real PII; C2 remains Pending | Real customer data entered in dev/pilot |
| R76 | 100+ item test uses placeholder `SAMPLE-...` content | 3 | 4 | 12 High | `sampleData=true`; no final checklist wording claimed; specialist review remains required | Placeholder wording treated as approved |
| R77 | Workshop Admin has no job/template oversight for Platform Admin | 2 | 4 | 8 Medium | Intentional Phase 4 scope; revisit if support needs read-only oversight | Support cannot inspect a workshop issue |
| R78 | Job status transitions are only partially implemented | 3 | 3 | 9 Medium | Phase 4 creates/assigns/cancels; Phase 5 owns inspection/finalization transitions | A user expects `IN_PROGRESS`/`READY_TO_FINALIZE` actions |
| R79 | Template category ordering is derived from item order, not a separate category-order editor | 2 | 3 | 6 Medium | Item order and category grouping are visible; add explicit category ordering only if pilot feedback requires it | Workshop cannot arrange categories as expected |
| R80 | Large template builder loads all published items for the workshop at once | 5 | 3 | 15 High | Search/category filter; 100+ publish is server-tested; add cursor pagination before large-scale production | Slow builder or memory pressure |

---

## 2. Updated existing risks

| Risk | Change |
|---|---|
| R02 cross-workshop leak | New job/template/master/staff endpoints are workshop-scoped; cross-workshop and role tests added. |
| R25 scope creep | No inspection, finalization, reports, delivery, correction, review queue or payments added. |
| R62 production storage | No change; D6 Pending. Phase 4 does not add new object storage. |
| R67 image picker | No change; no device test. |
| R71 MySQL/Docker | Still open; Docker is absent and `MySqlMigrationIT` skipped. |

---

## 3. Top Phase 4 risks

1. R74 MySQL triggers are written but untested.
2. R75 job PII is not encrypted yet.
3. R80 builder pagination at scale.
4. R61 direct SQL immutability not proven on MySQL.
5. R13 old-template pinning is tested at service level; DB durability still depends on triggers/grants.
6. R72/R73 approved-rule gaps versus the brief wording.
7. R76 placeholder content mistaken for final.

---

## 4. Decisions needed

- RQ12 workshop policy for technician walk-ins.
- Whether Platform Admin needs read-only job/template oversight.
- C2 legal retention/consent before real customer data.
- D6 production storage, D7 forms, D8 delivery, D11 photo limits.
- CI must run MySQL 8.4 migrations and trigger checks.
