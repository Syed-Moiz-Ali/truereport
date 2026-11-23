# Evidence Index — TrueReport QA Audit

All evidence was produced by this audit against the running local stack on 2026-11-23. Nothing here contains passwords, access/refresh tokens, cookies, or real customer personal data. Seeded `@truereport.test` accounts are test identities; the one customer name on the public page is not printed in reports.

## Logs and machine output

| File | Produced by | Proves |
|---|---|---|
| `api-audit.log` | `qa_audit/api-audit.mjs` | 73 API checks, 67 pass / 6 findings, line-by-line expected vs actual |
| `api-audit-results.json` | same | machine-readable results, token-free session summary (users, memberships, JWT claims) |
| `auth-probe.json` | `qa_audit/probe-auth.mjs` | raw login payload shapes; `admin.b` `platformAdmin=true` + `PLATFORM_ADMIN` JWT; B→A cross-tenant 200; neutral 404 HTML; staff masking |
| `workflow-e2e.log` | `qa_audit/workflow-e2e.mjs` | 24/24 end-to-end steps on `JOB-599E2DEB`, including public report identity |
| `probe-evidence.log` | `qa_audit/probe-evidence.mjs` | PNG evidence rejected; JPEG accepted/VERIFIED; video duration rule; fake 4 KB MP4 verified |
| `openapi.json` | live `/v3/api-docs` | 189 paths / 225 operations (full contract) |
| `endpoint-list.txt` | derived | sorted method + path + controller (31 controllers) |
| `db-snapshot-integrity.txt` | MySQL | 6 of 7 snapshots match their job; `JOB-98D5FD5D` does not |
| `db-workflow-verification.txt` | MySQL | new job persisted: PUBLISHED/APPROVED, score 100, grade A, signature, 3 assessments, 6 evidence, 1 ACTIVE link |
| `db-rbac-and-schema.txt` | MySQL | `admin.b platform_admin=1`; `platform_jobs=109` vs legacy `inspection_jobs=1`; report versions 7 vs 1 |
| `playwright-suite.log` | repo Playwright config | first full run — 18 pass / 2 skip / 21 fail, 20 of them trace-ENOENT teardown |
| `playwright-suite-clean2.log` | QA config (trace off) | platform modules 15/15 PASS |
| `playwright-remaining.log` | QA config | workshop modules 8/8 PASS (run aborted later at technician start) |
| `playwright-technician.log` | QA config | technician 6/6 PASS |
| `playwright-contracts-public.log` | QA config | API sweep 95 GETs, 0 × 5xx; public neutral 404 PASS |
| `playwright-public-real.log` | QA config + fresh token | real published report PASS; Spanish variant SKIP (no es fixture) |
| `playwright-platform-sweep-wide.log` | QA config | attempted suite sweep — hung on this machine; superseded |
| `route-sweep.log`, `route-sweep.json` | `qa_audit/route-sweep.mjs` | 26/26 routes render with no fatal console/copy (23 platform, 3 technician) |
| `flutter-analyze.log` | `flutter analyze --fatal-infos` | No issues found |
| `flutter-tests.log` | `flutter test` ×3 | 468/468 tests pass (146 / 205 / 117) |
| `mvn-test.log` | `mvn -B test` (server) | BUILD SUCCESS, 350 tests, 0 failures/errors, 12 skipped; 80 surefire reports with 0 failures |
| `photo.jpg` | QA helper | JPEG fixture used for evidence upload (converted from the repo PNG) |

Prior-session files `platform-run.log`, `workshop-run.log`, `technician-run.log` were **not** produced by this audit and are retained only for context.

## Screenshots (`evidence/screens/`)

| File | Screen / state | Relevant issue |
|---|---|---|
| `platform-dashboard-1920.png` | Dashboard with 7 KPIs | UI-P1 |
| `platform-workshops-1920.png` | Workshops list + detail pane, 88% / 8 bays | BUG-005 |
| `platform-workshop-detail-1920.png`, `platform-detail.png` | Workshop A detail | UI-P5 |
| `platform-detail-staff.png` | Staff tab, "No data yet" | BUG-020 |
| `platform-detail-activity.png` | Activity tab with audit events | UI-P5 |
| `platform-workshop-edit.png` | Edit dialog with populated values | UI-P7, BUG-016 |
| `platform-items.png` | Checklist items | UI-P8 |
| `platform-categories.png` | Categories | UI-P8 |
| `platform-optionsets.png` | Option sets tabs | UI-P8 |
| `platform-health.png` | Configuration health | UI-P8 |
| `platform-workshop-admin-shell.png` | Workshop Admin inside Platform app: full chrome + "Something went wrong" | BUG-002 |
| `workshop-jobs-1920.png` | Jobs table; reference wrap, merged text, clipped dates | BUG-017 |
| `workshop-staff.png` | Staff list and role filters | UI-W8 |
| `workshop-templates.png` | Template cards with `Â·` mojibake | BUG-008 |
| `workshop-template-sequence.png` | Master-items category filters as blank pills; 0-item template | BUG-007, BUG-014 |
| `workshop-settings.png` | Settings (workshop/account/language/session) | UI-W13 |
| `technician-unauthorized.png` | Technician app `/unauthorized` for a workshop admin | BUG-015 |

Additional technician captures (queue, workspace, item assessment, profile) were reviewed live in the browser; text snapshots are quoted in `TEST_RESULTS.md`. They were not persisted as PNGs before the browser was closed to free memory.

## Network / console captures

- Platform dashboard: 65 requests; 1 console error (`401 /auth/me` at boot, then transparent refresh succeeds) — BUG-021.
- Platform app as Workshop Admin: 12 `/api/v1/platform/*` requests return 403 — BUG-002.
- Technician assessment: `PUT /items/ENG-OIL-01` → 422 with `NOTES_NOT_ALLOWED`, `EVIDENCE_RULE_NOT_MET`, `EVIDENCE_TYPE_REQUIRED`.
- Evidence init: PNG → 422 `MIME_NOT_ALLOWED`; JPEG → 201/200/200 VERIFIED; video 1 s → 422 `DURATION_INVALID`; fake 15 s MP4 → VERIFIED.

## Reproducibility

| Command | Purpose |
|---|---|
| `node qa_audit/api-audit.mjs` | re-run 73 API checks (read-only + negative writes that are rejected) |
| `node qa_audit/workflow-e2e.mjs` | create a new `QA-*` job and run the full lifecycle (safe, disposable) |
| `node qa_audit/probe-evidence.mjs` | evidence MIME/size probes against an existing QA job |
| `npx playwright test --config qa_audit/playwright.qa.config.ts` | clean E2E (trace/video disabled) |
| `node tests/e2e/static-server.js 5301 client/apps/platform_admin_app/build/web` | serve a build if the port is down |

`qa_audit/playwright.qa.config.ts` is a QA-only config: it imports the repo config and disables trace/video capture, whose writer fails teardown with ENOENT on this machine. It does not modify application source or the repository's test definitions.
