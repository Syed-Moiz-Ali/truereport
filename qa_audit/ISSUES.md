# Issues — TrueReport QA Audit

Every entry below was reproduced against the running local stack. Severity is assigned by user/business impact, not by fix effort.

**Summary:** 22 findings — 2 Critical, 2 High, 12 Medium, 5 Low, 1 Informational. 20 are confirmed with direct evidence; 1 (BUG-001) is a confirmed data-state defect whose write path is not reproducible on a fresh record; 1 (BUG-019) is documentation drift.

---

## BUG-001 — Public report link serves another job's report snapshot
**Severity:** Critical (data integrity / customer-facing)
**Module:** Reports / Public report
**Screen/route:** `/r/{token}` for job `JOB-98D5FD5D`
**Affected roles:** Customers with the link; Workshop Admin (publisher)

**Steps to reproduce**
1. `GET /api/v1/workshop/jobs?search=JOB-98D5FD5D` as `admin.a@truereport.test`.
2. `GET /api/v1/workshop/jobs/{id}/report`.
3. `GET /api/v1/workshop/jobs/{id}/public-link` then open the returned URL.

**Expected:** The report and public page identify `JOB-98D5FD5D`.
**Actual:** The report response has `reportNumber = JOB-98D5FD5D` but `content.reportNumber = JOB-89211E61`; the public HTML contains only `JOB-89211E61`.

**Evidence**
- API: `reportId 0d8574a3…`, `content.finalizedAt 2026-11-21T18:41:57`, top-level `finalizedAt 2026-11-22T01:46:05`.
- DB: `platform_report_versions` row for job 98D5 has `snapshot_hash = 001ae484…` (identical to 89211E61) and `JSON_EXTRACT(snapshot_json,'$.reportNumber') = JOB-89211E61`.
- Public page: `https://…/r/5Xntu06_…` → 46,261 bytes, only `JOB-89211E61`.
- Scope: 1 of 6 published snapshots mismatched; the other 5 match their job.
- **Fresh-path control:** a newly created job (`JOB-599E2DEB`) went create→evidence→assess→sign→complete→approve→publish and produced its own snapshot and public page (24/24 workflow checks). The copy is therefore **not reproducible through the current write path** and is pre-existing corrupted data.

**Impact:** A customer-facing link can display a different report identity. In this dataset both jobs share the same vehicle, so no cross-customer PII was exposed; if the snapshot had belonged to another customer, this would be a PII disclosure.

**Likely root cause:** corrupted/legacy `platform_report_versions.snapshot_json` row (manual or older-tooling write). The publish and read paths have **no invariant** that `snapshot.reportNumber == job.reference`.

**Recommended fix**
1. Repair the row (rebuild the snapshot for 98D5 from its job, or unpublish/revoke the link).
2. Add a publish-time assertion: snapshot JSON `reportNumber` must equal the job reference, and the snapshot job id must equal the job id.
3. Add a read-time guard so a mismatch returns the neutral 404/500 rather than the wrong report.
4. DB test: no `platform_report_versions` row may reference a different job's report number.

**Retest:** open every active public link and assert the report number equals the job reference; then re-run the 24-step workflow.

---

## BUG-002 — Platform Admin web app has no role gate; Workshop Admin enters a broken shell
**Severity:** High (authorization surface / UX)
**Module:** Platform Admin client
**Screen/route:** `:5301/signin` → `/workshops`

**Steps**
1. Sign in at `http://127.0.0.1:5301/signin` with `admin.a@truereport.test` (WORKSHOP_ADMIN).
2. Observe URL, shell, network.

**Expected:** Redirect to `/unauthorized` (as the Workshop and Technician apps do) or an explicit access-denied screen.
**Actual:** Lands on `/workshops` with the full Platform Admin chrome (Dashboard, Workshops, Checklist, Reports, Audit Log, Settings) and the signed-in identity "Workshop Admin A / Workshop Admin". On first load the content area is a skeleton; after settle it shows a generic "Something went wrong" card with a Retry button. All `/api/v1/platform/*` calls return 403. There is no role redirect and no indication that the account lacks the platform role.

**Evidence:** screenshot `evidence/screens/platform-workshop-admin-shell.png`; 403s; `platform_router.dart` redirect checks only `session == null`.
**Impact:** A non-platform user can occupy the platform UI, sees navigation to privileged modules, and gets an indefinite loading state. Backend authorization holds (403), so this is not data exposure, but it is a broken and confusing privilege boundary.
**Likely root cause:** `client/apps/platform_admin_app/lib/src/platform_router.dart` has no role check in `redirect`.
**Recommended fix:** mirror `technicianRedirect`/workshop guard: if `session.role != PLATFORM_ADMIN` → `/unauthorized`; render an explicit error if a 403 occurs.
**Retest:** sign in with each role on 5301 and assert the route.

---

## BUG-003 — Workshop Admin B account is a Platform Admin (cross-tenant access)
**Severity:** Critical (privilege escalation, data)
**Module:** Identity / dev data
**Affected account:** `admin.b@truereport.test`

**Steps**
1. `POST /api/v1/auth/login` as `admin.b@truereport.test`.
2. Decode the JWT; call `GET /api/v1/platform/workshops` and `GET /api/v1/workshops/{workshopAId}`.

**Expected:** `platformAdmin = false`, JWT `role = WORKSHOP_ADMIN`, platform endpoints 403, Workshop A read 404/403.
**Actual:** `user.platformAdmin = true`; JWT `role = PLATFORM_ADMIN` and no `wid` claim; `/platform/workshops` → 200 with 3 workshops; Workshop A record → 200.

**Evidence**
- `SELECT email, platform_admin FROM users` → `admin.b@truereport.test = 1`.
- `DevDataInitializer` creates adminB and a WORKSHOP_ADMIN membership and **never** sets `platformAdmin(true)` — so this is database drift, not seed code.
- Cross-tenant reads: B→A job 403 (job scoping still uses membership), but B→A workshop 200 and platform list 200.

**Impact:** A workshop-level account can administer every tenant, including hierarchy, master content and audit. Anyone with that credential has platform control.
**Recommended fix:** set `users.platform_admin = 0` for the account; ensure dev seed is idempotent and asserts role invariants; add an integration test "every seeded workshop-only account has platform_admin = 0".
**Retest:** login, decode JWT, re-run the 13-cell permission matrix and tenant isolation.

---

## BUG-004 — Item PHOTO evidence rejects PNG, while other photo paths accept it
**Severity:** High (functional blocker)
**Module:** Technician evidence
**Screen/route:** `POST /api/v1/technician/jobs/{id}/items/{itemCode}/evidence/init`

**Steps:** initialise PHOTO evidence with `mime: image/png` (7,948-byte PNG), then repeat with `image/jpeg`.

**Expected:** both accepted, or PNG rejected consistently everywhere.
**Actual:** PNG → `422 EVIDENCE_INVALID / MIME_NOT_ALLOWED`; JPEG → `201` then `VERIFIED`, `qualityStatus = PASS`. The vehicle cover photo accepts the same PNG (`201 → READY`).

**Evidence:** `evidence/probe-evidence.log`; `TechnicianInspectionService.PHOTO_MIMES = {jpeg, heic, heif, webp}` while `DOCUMENT_MIMES` and the vehicle-photo path include PNG.
**Impact:** Technicians cannot attach PNG captures (web/screenshot evidence); mobile HEIC/JPEG flows are unaffected. The contract is internally inconsistent.
**Recommended fix:** add `image/png` to `PHOTO_MIMES` (or reject it in the cover-photo/document paths too, and document why).
**Retest:** upload PNG photo evidence and assert VERIFIED.

---

## BUG-005 — Workshop cards show fabricated "8 Bays" and "88% capacity"
**Severity:** Medium (data integrity / trust)
**Module:** Platform Admin → Workshops

**Steps:** open `/workshops` and compare the card/detail figures with `GET /api/v1/platform/hierarchy`.

**Expected:** figures come from the API or are omitted.
**Actual:** every workshop shows `Bays 8` and `Assigned capacity 88%` (E2E WorkshopDeira, Workshop A, Workshop B), including a workshop with 0 staff and a workshop with 8 bays. `/platform/hierarchy` returns **no** bay or capacity fields.

**Evidence:** `client/apps/platform_admin_app/lib/src/platform_models.dart:39-40,79-80` defaults `bayCount = 8`, `assignedCapacityPercent = 88`; screenshot `platform-workshops-1920.png`.
**Impact:** Operators make staffing/capacity decisions on invented numbers; the same value for every tenant is a credibility red flag.
**Recommended fix:** remove the defaults, render "—" when absent, and add the fields to the API if the metric is real.
**Retest:** compare UI numbers to API payload for every workshop.

---

## BUG-006 — French is "LIVE" at 0% readiness and is not delivered to clients
**Severity:** Medium (data/business rule)
**Module:** Localization / Dashboard

**Steps:** `GET /platform/i18n/languages`, `GET /platform/i18n/languages/fr/readiness`, `GET /i18n/ui-messages/{app}/manifest`.

**Expected:** a language counted as live is deliverable.
**Actual:** `fr` has `status: LIVE, active: true` and `readinessPercent: 0` (0 UI messages, 0 approved content, blocker list). Workshop and Technician manifests contain only `en` and `es`. Dashboard shows "All languages live" and `languagesLive: 3`.

**Impact:** The live-language KPI is misleading; activating French appears successful while users cannot select it.
**Recommended fix:** block LIVE activation below a readiness threshold, or report "3 registered / 2 delivered".
**Retest:** after activating a language, assert it appears in at least one client manifest.

---

## BUG-007 — Template "Master items" category filters render as unlabeled empty pills
**Severity:** Medium (UI regression)
**Module:** Workshop Admin → Templates → Template sequence
**Evidence:** screenshot `workshop-template-sequence.png`; accessibility tree exposes ~10 consecutive `button` nodes with no name, immediately after "All categories". The visual row is a set of empty white ovals.

**Impact:** Category filtering is unusable and unintelligible; also a serious screen-reader failure.
**Likely cause:** chips rendered without label text/child (l10n key unresolved).
**Retest:** snapshot must expose named category buttons and visible labels.

---

## BUG-008 — Mojibake in template subtitles (`Â·`)
**Severity:** Medium (visible quality)
**Module:** Workshop Admin → Templates
**Evidence:** both list rows show `FULL_INSPECTION Â· ALL Â· 3 items Â· v1` (screenshot `workshop-templates.png`); the same strings render correctly elsewhere (`·`).
**Likely cause:** UTF-8 text decoded as Latin-1 before display.
**Retest:** screenshot + assert the character is U+00B7, not U+00C2 U+00B7.

---

## BUG-009 — Test option "Live Set 1794471507926" is visible in the assessment UI
**Severity:** Medium (master-data quality)
**Module:** Technician → item assessment → Issue Type
**Evidence:** screenshot `technician-item.png`; option set includes a timestamped test value.
**Impact:** Technicians can select meaningless test data in a legal inspection; pollutes reports.
**Fix:** retire the option value; add a seeded-data hygiene check.

---

## BUG-010 — Every item requires photo **and** video even for "No issue observed"
**Severity:** Medium (product rule / operability)
**Module:** Master item rules + Technician completion

**Steps:** open the 30-item template checklist; inspect `evidenceRules`; select "No issue observed" on one item.

**Actual:** all 30 items share `NO_ISSUE_OBSERVED → minPhotos 1, minVideos 1`; the API rejects the assessment (`EVIDENCE_RULE_NOT_MET`, `EVIDENCE_TYPE_REQUIRED`), and `complete` reports blockers. The UI says only "Required evidence is missing: Photos." Values: a full 30-item inspection needs 60 captures. The 3-item E2E template works with 6 captures.

**Conflict:** `README.md` states Phase 5A evidence requirements are "warnings only"; the API treats them as hard blockers. UI and API disagree on whether video is required.
**Impact:** A normal "everything is fine" inspection is the most expensive to complete; technicians may attach junk evidence to proceed.
**Recommendation:** confirm the intended rule; if evidence is required only for defects, make `NO_ISSUE` rules zero; if video is required, surface it in the UI checklist; align README.

---

## BUG-011 — Evidence "verification" accepts arbitrary bytes as a valid 15-second video
**Severity:** Medium (evidence integrity / security)
**Module:** Technician evidence

**Steps:** upload a 4,120-byte buffer (`ftypmp42` header + 4 KB zeros) as `video/mp4` with `durationMs: 15000`.

**Actual:** `201 → UPLOADED → VERIFIED`, `qualityStatus: PASS`. No container/stream decode; the declared duration is trusted. The same applies to a JPEG with appended nonce bytes.
**Impact:** A fabricated "certified inspection video" satisfies the evidence gate. For a product whose value is trustworthy inspection evidence, this undermines the report's integrity claim.
**Fix:** server-side media probe (ffprobe/mp4 box parse), duration from the file, frame/poster extraction, and a real quality pipeline.
**Retest:** the same buffer must be rejected as malformed.

---

## BUG-012 — Access token stays valid after logout for up to 15 minutes
**Severity:** Medium (security)
**Module:** Auth/security

**Steps:** login → `POST /auth/logout` (204) → `GET /auth/me` with the same access token → `POST /auth/refresh` with the old refresh token.

**Actual:** `/auth/me` → 200; refresh → 401. The refresh token is revoked but the stateless access token is not.
**Impact:** A stolen/leaked access token survives logout/sign-out on another device; "sign out" does not immediately terminate the session.
**Fix:** check `sid` against the session table (or shorten access TTL / use a revocation list) for sensitive operations.
**Retest:** after logout, every authenticated endpoint returns 401.

---

## BUG-013 — Technician workspace does not update the URL; Back/refresh loses context
**Severity:** Medium (navigation/UX)
**Module:** Technician app

**Steps:** from `/jobs` open a job and an item; observe `location.pathname`; press browser Back; refresh.

**Actual:** URL stays `/jobs` throughout the workspace and item pages; browser Back pops inside Flutter (URL never changes); refresh returns to the queue, losing the job context. Deep links (`/jobs/{id}`) do work when entered directly.
**Likely cause:** `Navigator.push` used instead of `context.go('/jobs/:id')`, so the router state and browser history diverge.
**Fix:** use GoRouter for job/item navigation so URL, refresh and Back match the visible screen.

---

## BUG-014 — A published template can contain zero items
**Severity:** Medium (business rule/data)
**Module:** Workshop templates
**Evidence:** "Comprehensive 120-Point Inspection" is `Published`, version history `v1 Published · No items`, and a `v2 Draft · No items`; the Publish step offers "Publish template" with no warning, and the Sequence step shows "No items selected" while the header still reads Published (`workshop-template-sequence.png`). API `available` reports `itemCount: 0`.
**Impact:** A job can be created against a template with no checklist; the technician sees an empty inspection and cannot produce a meaningful report.
**Fix:** require ≥1 item to publish; warn/disable publish otherwise.

---

## BUG-015 — Unauthorized screens use misleading copy
**Severity:** Medium (UX)
**Module:** Workshop Admin and Technician apps
**Evidence:** both show "Something went wrong / Use your workshop account." — in the **workshop** app a technician is told to use a workshop account; in the **technician** app a workshop admin is told the same. The header is just "Technician"/"TrueReport", and there is no "go to the right app" link.
**Fix:** role-specific copy ("This app is for technicians") + link to the correct app + keep sign-out.

---

## BUG-016 — Accessibility gaps in sign-in and job surfaces
**Severity:** Low
**Evidence**
- Platform sign-in show-password is exposed as an unnamed `button`; Technician's is named "Password" (not "Show password"); Workshop's is correct ("Show password").
- Workshop job detail exposes two `Report` and two `Documents` buttons with identical names (duplicate semantics nodes).
- Platform "Edit workshop" dialog: workshop-name textbox has no accessible name (only Branch/Contact email have labels).
**Fix:** accessible names, single semantics node per action.

---

## BUG-017 — Job table truncation/overlap
**Severity:** Low
**Evidence:** screenshot `workshop-jobs-1920.png`: references wrap mid-token (`JOB-36B7489` / `F`, `JOB-C2A2836E`), and the scheduled column renders `11/23/202610:43` with no gap for several rows.
**Fix:** widen/rebalance columns, `maxLines: 1` + ellipsis or copy-on-click for references.

---

## BUG-018 — No CSP on the server-rendered public report; no HSTS locally
**Severity:** Low (defence in depth)
**Evidence:** `GET /r/unavailable` and `/r/{token}` have `X-Content-Type-Options: nosniff`, `Cache-Control: no-store`, `Referrer-Policy: no-referrer`, `X-Robots-Tag` — but **no** `Content-Security-Policy` (`H3`). HSTS is absent (HTTP local; expected).
**Fix:** add a restrictive CSP (no inline script, `default-src 'self'`, img/media from the report origin).

---

## BUG-019 — Credential documentation lists a non-existent account
**Severity:** Low (environment/docs)
**Evidence:** `TEST_LOGIN_CREDENTIALS.txt` documents `tech.test@gmail.com / 12345678` ("manual DB insert"); login returns 401 and `users` has no such row. Also the file documents `admin.b` as workshop-only, which contradicts the DB (BUG-003).
**Fix:** regenerate the file from the seed, or delete the manual entry.

---

## BUG-020 — "No data yet" under every staff member
**Severity:** Low (UI)
**Evidence:** Platform workshop detail → Staff: each of the three accounts shows "No data yet" beneath the name.
**Fix:** show last-active/invited date or remove the placeholder.

---

## BUG-021 — Transparent refresh logs a 401 error at boot
**Severity:** Informational
**Evidence:** Platform dashboard load logs `Failed to load resource: 401 @ /api/v1/auth/me`, then refresh succeeds and the dashboard loads. This is the expected transparent-refresh flow, but it appears as a console error and will trip error monitors.
**Fix:** treat the first 401 as expected or refresh proactively before the call.

---

## BUG-022 — Two parallel job/report schemas are both live
**Severity:** Medium (architecture/maintainability, risk)
**Evidence:** MySQL has legacy `inspection_jobs` (1 row), `reports` (1), `report_versions` (1) alongside `platform_jobs` (109), `platform_report_versions` (7), `platform_public_links` (7). `CleanPublicReportReader` exists specifically to bridge clean links to the public path; `WorkshopJobController` exposes a `/workshop/legacy/jobs` API. The corrupted snapshot in BUG-001 shows how easily tooling can write the wrong table/row.
**Fix:** finish the migration, remove/redirect legacy reads, add a single repository boundary and migration tests.
