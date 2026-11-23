# QA Audit — Progress Ledger

**Application:** TrueReport (partner-workshop vehicle inspection platform)
**Audited build:** branch `rebuild/mobile-tablet-full-2026-11-23`, commit `9232faf`
**Environment:** local dev — Spring Boot on `:8080` (MySQL 8.0 `truereport`), Flutter web builds on `:5301` (Platform Admin), `:5302` (Workshop Admin), `:5303` (Technician)
**Audit window:** 2026-11-23, 11:25 → 14:00 (Asia/Dubai)
**Source changes:** none. Only `qa_audit/` artifacts were created.

## Current state

| Area | Status | Evidence |
|---|---|---|
| Environment / safety | COMPLETE | Local dev, seeded dev data, disposable `QA-*` records only |
| Application discovery | COMPLETE | 3 Flutter apps, 189 API paths / 225 operations, 126 tables |
| API behaviour audit | COMPLETE (73 checks) | `evidence/api-audit.log`, `evidence/api-audit-results.json` |
| End-to-end workflow | COMPLETE (24/24 on fresh job) | `evidence/workflow-e2e.log` |
| Browser UI (manual) | COMPLETE for 36 screens (29 behaviour-checked) | `evidence/screens/*.png`, `evidence/route-sweep.log` |
| Existing Playwright suite | Platform modules clean (15/15) | `evidence/playwright-suite-clean2.log` |
| Existing Playwright suite | Workshop / Technician / Contracts / Public | PASS — 8/8, 6/6, 1/1, 2 pass + 1 skip | `evidence/playwright-remaining.log`, `playwright-technician.log`, `playwright-contracts-public.log`, `playwright-public-real.log` |
| Controlled route sweep | 26/26 routes PASS | `evidence/route-sweep.log` |
| Flutter analyze + tests | analyze clean; 468/468 tests PASS | `evidence/flutter-analyze.log`, `evidence/flutter-tests.log` |
| Java test suite | BUILD SUCCESS — 350 tests, 0 failures, 0 errors, 12 skipped | `evidence/mvn-test.log` (80 surefire reports, 0 failures) |
| Database integrity | COMPLETE (read-only + new-record verification) | queries in this report |

## Resume instructions

1. Servers: `qa_audit/run-server.ps1` was removed by a prior session; the running server was started with the same env as `server/start-mysql-backend.ps1`. Static builds are served by `node tests/e2e/static-server.js <port> <build/web>`.
2. Re-run API audit: `node qa_audit/api-audit.mjs`.
3. Re-run workflow: `node qa_audit/workflow-e2e.mjs` (creates a new `QA-*` job; safe).
4. Re-run E2E cleanly: `npx playwright test --config qa_audit/playwright.qa.config.ts` (tracing disabled; the repo config's trace writer fails teardown on this machine).
5. Continue at: Java/Flutter test suites, and the remaining NOT TESTED screens listed in `TEST_INVENTORY.md`.

## Ledger

| # | Milestone | Result | Time |
|---|---|---|---|
| 1 | Repo + runtime discovery | done | 11:25 |
| 2 | First full E2E run (repo config) | 18 pass / 2 skip / 21 fail, 18 of 21 failures were trace-ENOENT teardown, 1 real assertion | 12:19 |
| 3 | API audit v1 | 57/67 pass, 6 findings | 12:22 |
| 4 | API audit v2 (harness corrections) | 67/73 pass, 6 findings | 12:35 |
| 5 | Manual browser sweep (platform) | 8 screens, no fatal errors | 12:40 |
| 6 | Manual browser sweep (workshop + technician) | 12 screens, 5 UI defects | 13:05 |
| 7 | Fresh end-to-end workflow | 24/24 pass | 13:20 |
| 8 | Clean E2E platform modules | 15/15 pass | 13:33 |
| 9 | DB integrity verification | complete | 13:25 |
| 10 | Remaining E2E projects | workshop 8/8, technician 6/6, contracts 1/1, public 2+1 skip; route sweep 26/26 | 13:40 |
| 11 | Flutter + Java suites | analyze clean; 468/468 Flutter; Java BUILD SUCCESS 350 tests | 13:25 |
| 12 | Final report pack | 9 deliverables written | 14:05 |
