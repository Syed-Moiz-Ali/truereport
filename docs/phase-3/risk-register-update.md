# Phase 3 Risk Register Update

**Project:** TrueReport  
**Date:** 3 November 2026  
**Baseline:** `docs/phase-1/14-risk-register-update.md`

---

## 1. New/updated risks

| ID | Risk | Impact | Likelihood | Score | Mitigation | Early warning |
|---|---|---|---|---|---|---|
| R61 | Published master item versions are immutable only through the service/API; a direct SQL operator could alter them | 4 | 3 | 12 High | Service rejects published edits; old-version tests; add DB trigger/grants in Phase 4/6; audit | A published version changes without a new version; audit gap |
| R62 | Guide images use local filesystem storage, not production S3 | 4 | 4 | 16 High | `ObjectStorage` boundary; D6 decision before production; local-only warning | Production deployment with local files |
| R63 | Invitation token is returned to Platform Admin because no email provider exists (D8 Pending) | 4 | 3 | 12 High | One-time display, `no-store`, short expiry, audit; deliver manually; replace with provider later | Token shared insecurely; invite abuse |
| R64 | Hierarchy endpoint loads all workshops/accounts without pagination | 3 | 3 | 9 Medium | Fine for pilot; add cursor/virtualization before large scale | Slow tree; memory pressure |
| R65 | Category/sort order changes are not versioned like items | 3 | 3 | 9 Medium | Item versions preserve wording; Phase 4 template snapshots must not rely on live category labels | Old report/template label drift |
| R66 | Sample master content could be mistaken for specialist-approved wording | 4 | 3 | 12 High | `sampleData=true`, UI warning, code prefix `SAMPLE-`, no final launch claim | Workshop treats sample as official |
| R67 | Admin app image-picker/file upload is untested on real devices/browsers | 3 | 3 | 9 Medium | Phase 8 device matrix; test PNG/JPEG/WebP, permission denial, large file | Upload failure in pilot |
| R68 | Last-admin guards can block legitimate workshop recovery | 3 | 2 | 6 Medium | Platform Admin transfer/replacement process; clear error; audit | Workshop cannot disable an admin |
| R69 | Manual invitation flow has no delivery/audit of actual handoff | 3 | 3 | 9 Medium | Record who invited and when; manual channel guidance; replace with D8 provider | Lost/expired invite |
| R70 | Direct object URL/content endpoint could expose guide images if authorization changes | 4 | 2 | 8 Medium | PA-only security; `no-store`; never public evidence; tests | Unauthorized image access |
| R71 | MySQL 8.4 Testcontainers/Compose remains unverified locally because Docker is absent | 4 | 4 | 16 High | Run CI/ops on Docker-enabled machine before Phase 3 gate; record results | Phase 3 gate closes without a real MySQL run |

---

## 2. Updated existing risks

| Risk | Change |
|---|---|
| R01 finalized findings edited | Still Phase 5/6; no findings feature exists yet. |
| R02 cross-workshop leak | New Platform Admin endpoints are PA-only; role tests added. Workshop endpoints unchanged. |
| R03 public PII leak | No public report content in Phase 3; `/r/*` remains neutral. |
| R06 Arabic PDF | Still Phase 6; no PDF work. |
| R13 master update silently changes old inspections/reports | Partially mitigated by immutable item versions; Phase 4 templates must reference versions, Phase 6 snapshots must copy wording. |
| R15 MinIO EOL | Local-only; new local `ObjectStorage` implementation is not production. D6 remains open. |
| R25 scope creep | Phase 3 did not add templates/inspection/PDF/delivery/corrections/payments. |
| R36 consent | No real customer data; C2 still Pending. |

---

## 3. Top Phase 3 risks

1. R62 local guide-image storage is not production-ready.
2. R63 manual invitation-token handling.
3. R66 sample content mistaken for final.
4. R61 published master version immutability relies on service/API, not DB triggers.
5. R13 templates/reports drifting from master content in Phase 4/6.
6. R02 cross-workshop/role leakage as new endpoints grow.
7. R67 image-picker/upload not device-tested.
8. R65 category label/version drift.
9. R69 invitation delivery.
10. R64 hierarchy scale.

---

## 4. Decisions needed

- D6 production object storage before any production guide/evidence upload.
- D8 provider before replacing manual invitations with email/WhatsApp/SMS.
- D7 forms package before complex template/checklist forms.
- D11 photo limits before evidence capture.
- C2 legal consent/retention before real customer data.
- Phase 4 must confirm that templates reference `master_item_version_id`, not live items.

---

## 5. Review

Re-score after Phase 4 implements template versioning. Close R61/R13 only when DB/API controls and cross-version tests exist. Close R62 only when D6 is implemented and tested. Close R63/R69 when D8 delivery is approved and integrated.
