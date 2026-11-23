# Final QA Audit Report — TrueReport

**Audit type:** full-stack, end-to-end functional, integration, authorization and UX audit
**Build:** branch `rebuild/mobile-tablet-full-2026-11-23`, commit `9232faf`
**Environment:** local development stack — Spring Boot 8080, MySQL 8.0, Flutter web builds 5301/5302/5303
**Date:** 2026-11-23
**Method:** live browser automation (Playwright + real Chrome), direct API testing, read-only DB verification, disposable end-to-end records. Application source was not modified.

---

## 1. Executive summary

TrueReport's **core inspection lifecycle works end-to-end** on a fresh record: a workshop creates a job, a technician uploads the vehicle photo, attaches photo/video evidence, assesses every item, signs, and completes; the workshop admin reviews, approves, and publishes; the public report is generated with the correct job identity, the correct totals, and no customer PII. All 24 workflow steps passed, and the database reflects every transition.

The system is **not ready for release**. Three issues cross the release line:

1. **BUG-003 (Critical):** the seeded `admin.b@truereport.test` account is a **platform administrator** in the database, despite the seed code and README defining it as a Workshop Admin. It can list every workshop and read another tenant's workshop record (200, not 403). This is live privilege escalation.
2. **BUG-001 (Critical):** one published report (`JOB-98D5FD5D`) serves **another job's snapshot**. The database row and the public HTML both say `JOB-89211E61`. The current write path is correct (proven on a new job), so this is corrupted data plus a missing integrity invariant — but a customer link currently shows the wrong report.
3. **BUG-002 (High):** the Platform Admin web app has **no client-side role gate**. A Workshop Admin can sign in, see the full platform navigation, and land on a generic "Something went wrong / Retry".

A fourth issue blocks normal operation: **item evidence rejects PNG** (BUG-004), so web/screenshot captures cannot be attached even though the cover-photo path accepts them.

Beyond these, the quality is uneven: backend authorization is consistently correct (13/13 matrix cells, tenant-scoped job reads), validation and RFC 9457 errors are solid, and the visual design is genuinely strong — but the UI contains fabricated operational numbers (bays/capacity), a 0%-ready language marked LIVE, blank filter chips, mojibake, and misleading unauthorized copy.

**Release recommendation: NO-GO.** Fix BUG-001/003 (data + access), BUG-002/004 (role gate + evidence MIME), then re-run the 24-step workflow and the 13-cell permission matrix.

---

## 2. Application architecture (as observed)

```
Flutter web (3 builds)                  Spring Boot modular monolith (19 modules)
platform_admin_app  :5301  ─┐           identity (JWT access 15m + rotating refresh,
workshop_admin_app  :5302  ─┼─ HTTPS ─► tenancy (workshop membership, tenant guards),
technician_app      :5303  ─┘           masterdata, templates, jobs, technician,
                                        inspections, reports, delivery, governance,
                                        localization, uimessages, audit, media, dev
                                        │
                          MySQL 8.0 (126 tables, Flyway)  +  object storage (MinIO local)
                          public HTML reports  /r/{token}
```

Key facts:
- **225 API operations** across 31 controllers, OpenAPI at `/v3/api-docs`.
- Two generations of job/report tables coexist: legacy `inspection_jobs`/`reports` (1 row each) and active `platform_jobs`/`platform_report_versions` (109 / 7). A bridge (`CleanPublicReportReader`) connects clean links to the public reader.
- Roles: `PLATFORM_ADMIN`, `WORKSHOP_ADMIN`, `TECHNICIAN`; tenant scoping via workshop membership and `wid` claim.
- Public reports are server-rendered HTML with masked VIN and no customer name.

---

## 3. Coverage

| Dimension | Discovered | Tested | Coverage |
|---|---|---|---|
| Screens | 42 | 36 rendered in a browser; 29 with behaviour checks | 86% rendered / 69% behaviour |
| API operations | 225 | 95 GET contract-swept + 50 behaviour-tested | 42% contract / 22% behaviour |
| Roles | 4 + anonymous | all 5 contexts | 100% |
| Permission matrix | 13 cells + 4 tenant checks | 17 | 100% (13 pass, 4 fail — one root cause) |
| Cross-module workflows | 6 | 2 end-to-end, 4 partial | inspection lifecycle complete |
| Database invariants | 10 | 10 | 100% |
| Existing automated tests | 41 E2E + 468 Flutter | 41 E2E executed; 468 Flutter PASS | platform 15/15, workshop 8/8, technician 6/6, contracts 1/1, public 2 pass + 1 skip; analyze clean; Java pending |

**Executed checks:** 221 live checks (73 API, 24 workflow, 9 CRUD, 41 E2E, 26 route sweep, 38 manual UI, 10 DB) plus 468 Flutter unit/widget tests.
**Confirmed defects:** 22 findings (2 Critical, 2 High, 12 Medium, 5 Low) + 1 informational.
**Blocked:** 1 workflow variant (30-item completion).

---

## 4. Module-by-module assessment

| Module | UI | CRUD | API | Permissions | Integration | Verdict |
|---|---|---|---|---|---|---|
| Auth / session | PASS | PASS | PASS | PASS | PASS | Strong; 1 medium session issue (logout) |
| Platform dashboard | PASS | R | PASS | PASS | PASS | KPIs truthful; language KPI misleading |
| Platform workshops | PARTIAL | R/PARTIAL | PASS | **FAIL** | PARTIAL | Fabricated bays/capacity; role drift |
| Workshop hierarchy/accounts | — | NOT TESTED | PASS | **FAIL** | — | admin.b privilege escalation |
| Master content (items/categories/option sets) | PASS | R | PASS | PASS | PASS | Good; test option pollution |
| Templates | PARTIAL | R | PASS | PASS | PARTIAL | Blank chips, mojibake, empty publishable template |
| Workshop jobs | **FAIL (layout)** | R/PARTIAL | PASS | PASS | PASS | Counts exact; table truncation |
| Job detail / publication | PASS | R | PASS | PASS | PASS | Clear status; 2 duplicate a11y nodes |
| Technician queue/workspace | PASS | R | PASS | PASS | PASS | Strong, but URL not addressable |
| Assessment + evidence | **FAIL** | PARTIAL | **FAIL** | PASS | BLOCKED | PNG rejected; every item needs photo+video; fake video accepted |
| Signature / complete | PARTIAL (API PASS) | W | PASS | PASS | PASS | Blockers work |
| Approve / publish | PASS | W | PASS | PASS | PASS | Gate works; snapshot invariant missing |
| Public report | PASS | R | PASS | PASS | **FAIL 1/7** | Neutral, no PII; one corrupted link |
| Localization | PASS | R/W | PASS | PASS | PARTIAL | fr LIVE at 0% |
| Audit log | PARTIAL | R | PASS | PASS | PASS | Events recorded |
| Delivery/PDF | NOT TESTED | — | contract only | — | — | Outside exercised scope |
| Reports/documents | PARTIAL | R | PASS | PASS | PARTIAL | Report endpoint verified; documents not opened |

---

## 5. Confirmed failures (summary — detail in `ISSUES.md`)

| ID | Sev | Finding | Evidence |
|---|---|---|---|
| BUG-001 | Critical | Public link for `JOB-98D5FD5D` renders `JOB-89211E61` snapshot | DB row + public HTML |
| BUG-002 | High | Platform app has no role gate; Workshop Admin sees platform shell + generic error | screenshot + 12×403 |
| BUG-003 | Critical | `admin.b` is `platform_admin=1`; reads all tenants | DB + JWT + 200 responses |
| BUG-004 | High | Item PHOTO evidence rejects `image/png` | 422 `MIME_NOT_ALLOWED`; JPEG passes |
| BUG-005 | Medium | Bays=8 / Capacity=88% fabricated for every workshop | model defaults; API has no fields |
| BUG-006 | Medium | French LIVE at 0% readiness; not in client manifests | readiness + manifests + dashboard |
| BUG-007 | Medium | Template category filters are blank pills | screenshot + unnamed buttons |
| BUG-008 | Medium | Mojibake `Â·` in template cards | screenshot |
| BUG-009 | Medium | "Live Set 1794471507926" option in assessment | screenshot |
| BUG-010 | Medium | Photo+video required for every item; UI/API disagree; README says warnings | checklist rules + 422 |
| BUG-011 | Medium | 4 KB fake MP4 passes VERIFIED/PASS | probe log |
| BUG-012 | Medium | Access token valid after logout | 200 `/auth/me` |
| BUG-013 | Medium | Technician URL fixed at `/jobs`; Back/refresh lose context | live navigation |
| BUG-014 | Medium | Published template with 0 items | UI + `itemCount: 0` |
| BUG-015 | Medium | Misleading unauthorized copy | screenshots |
| BUG-016 | Low | A11y naming gaps | semantics tree |
| BUG-017 | Low | Job table wrap/merge/clipping | screenshot |
| BUG-018 | Low | No CSP on public report | headers |
| BUG-019 | Low | Credential doc lists missing account | 401 |
| BUG-020 | Low | "No data yet" under every staff member | screenshot |
| BUG-021 | Info | 401 console error during transparent refresh | console |
| BUG-022 | Medium | Dual legacy/clean job-report schemas | DB counts + code |

---

## 6. What is demonstrably good

- **Authorization is server-side.** Every role-scoped endpoint returned 401/403 correctly for the wrong role; job-level tenancy blocks Workshop B from Workshop A jobs. The UI gap (BUG-002) does not create backend access.
- **Validation is consistent** and uses a real problem+json contract with field errors and trace ids; no 5xx in 95 GETs or any negative probe.
- **Idempotency works** on job creation (same key → same job, one row).
- **Refresh rotation and reuse detection work**, including post-logout refresh rejection.
- **The full inspection workflow works** on a fresh job, including evidence, signature, completion, approval, publication, and a correct public report.
- **Data honesty in some places:** dashboard KPIs and workshop job counts match the API exactly; the overview even states that the status segments sum to the total.
- **Public surface is cautious:** neutral 404, no PII, masked VIN, `noindex`, `no-referrer`.
- **Visual quality is high** and consistent across the three apps, with RTL and Spanish supported.

---

## 7. Major risks

1. **Privilege escalation via data drift (BUG-003).** The seed is not idempotent/assertive, so role rows can diverge from code. Any workshop-only credential could become platform-level. Highest business risk.
2. **A wrong report can be published (BUG-001).** The system has no snapshot-ownership invariant, and a corrupted row reached a customer-facing link.
3. **Evidence can be fabricated (BUG-011).** Hash/MIME/duration checks only; a 4 KB buffer passes as a "verified" 15-second inspection video. This undermines the product's core trust claim.
4. **Operational numbers are invented (BUG-005) and language status is misleading (BUG-006).** Operators cannot trust the console.
5. **The primary workflow is heavy and inconsistent:** 60 evidence captures for a clean 30-item inspection, PNG rejected, and UI/API disagree on what is required (BUG-004, BUG-010).
6. **Dual schema (BUG-022)** makes wrong-table writes easy; it is the most plausible origin of BUG-001.

---

## 8. Release readiness

**NO-GO.**

**Must fix before any pilot**
1. BUG-003 — correct `admin.b` and enforce the role invariant in seed + tests.
2. BUG-001 — repair the corrupted snapshot, add publish/read invariants, re-check every active link.
3. BUG-002 — role-gate the Platform app; never show a generic error for 403.
4. BUG-004 — accept PNG (or make the policy consistent) in item evidence.

**Should fix before pilot**
5. BUG-010 / BUG-011 — agree evidence policy; validate real media; surface all missing requirements.
6. BUG-005 / BUG-006 — remove fabricated KPIs; make language readiness honest.
7. BUG-012 — revoke access tokens on logout for sensitive operations.
8. BUG-007 / BUG-008 / BUG-009 — visible quality defects in the workshop app.

**Can follow**
BUG-013–BUG-022 (navigation, copy, a11y, table layout, CSP, schema cleanup).

**Retest gate:** 24-step workflow on a new job + 13-cell permission matrix + every active public link + PNG evidence upload + Platform-app role gate for all three roles.

---

## 9. Limitations of this audit

- **Flutter:** `flutter analyze --fatal-infos` → **No issues found**; unit/widget tests **468/468 PASS** (technician 146, workshop 205, platform 117).
- **Java:** `mvn -B test` → **BUILD SUCCESS**, 350 tests, 0 failures, 0 errors, **12 skipped** (Docker/Testcontainers MySQL + S3 integration tests; Docker is not installed locally).
- **Not tested:** workshop technician invitation/disable/transfer (would send real email or mutate users), master-item create/edit writes, job update/cancel via UI, delivery/PDF documents, technician UI summary/signature/completed/sync/conflict screens (API paths were exercised), platform route sweeps at narrow width and the workshop/technician mobile sweeps (manual responsive checks used instead).
- **Environment:** local dev with seeded and E2E-generated data (109 jobs). Some data is test-generated ("E2E …", "Audit Customer …"), which reduced realism but enabled deterministic checks.
- **Corrupted record:** BUG-001 could not be reproduced through the current write path; it is reported as a data-state defect with the invariant gap, not as a proven code-path bug.
- **Trace teardown:** the repository's Playwright config fails on this machine while writing traces; clean runs used a QA-only config with tracing disabled. Behavioural tests are unchanged.

---

## 10. Deliverables

| File | Contents |
|---|---|
| `FINAL_QA_AUDIT_REPORT.md` | this report |
| `TEST_INVENTORY.md` | every screen, route, API, role, workflow |
| `TEST_RESULTS.md` | executed cases with expected/actual |
| `ISSUES.md` | 22 defects with reproduction and fixes |
| `UI_UX_IMPROVEMENTS.md` | prioritized, screen-by-screen |
| `API_AUDIT.md` | endpoint/authorization/error-contract findings |
| `WORKFLOW_MATRIX.md` | end-to-end and interrupted workflows |
| `PROGRESS.md` | execution ledger and resume state |
| `EVIDENCE_INDEX.md` | logs, screenshots, DB output, repro commands |
