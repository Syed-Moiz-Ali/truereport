# Flow-gap audit â€” final report

Date: 2026-11-20 Â· Scope: all modules, all three product apps, public report, backend in this repo.
Playwright execution was excluded by the user after the harness was generated; runtime evidence below is HTTP/API and
server tests, not a browser run. Product decision (2026-11-20): **English-only**. See `docs/english_only.md`.

## VERDICT

**BLOCKERS CLEARED Â· GAPS REMAINING.** All six blockers are closed and verified by API/HTTP or server tests. 2FA and the Platform delivery screen are removed from scope/accepted by owner decision; Workshop Admin now offers immediate or scheduled jobs; the public report's
used design sections (tyres, damage zones, photo showcase) are now data-driven. The remaining majors are the legacy
consent path, the unexecuted browser suite, and the red Workshop client test suite. A formal COMPLETE verdict still
requires the generated browser suite to pass.

## Product

`docs/project_brief.md` â€” TrueReport is a B2B partner-workshop vehicle-inspection platform. Roles: Platform Admin
(global configuration, workshops, staff, languages, audit), Workshop Admin (templates, jobs, review/approve/publish,
delivery), Technician (pinned checklist, evidence, signature, completion), anonymous public viewer (`/r/{token}`).
Core jobs: configure master data Â· onboard workshop/staff Â· build a template Â· create/assign a job Â· inspect Â·
review/approve/publish Â· view/deliver the report Â· audit.
Confidence: repo layout, routes, endpoints, lifecycles and tables are `confirmed`; `ui_gallery` is non-product and the
public viewer has no account (`inferred`). Documentation drift (README `admin_app`, "Phase 5A", "customer app") is
recorded, not used as proof.

## Discovery

`docs/flows/_discovery.md` â€” 4 workspace apps (`platform_admin_app`, `workshop_admin_app`, `technician_app`,
`ui_gallery`), shared packages (`api_client`, `auth`, `domain`, `design_system`, `l10n`, `offline_sync`), Spring Boot 4
backend with 33 controllers / 209 mappings, 26 portable + 6 MySQL-only migrations, 44 server test classes.
No customer app/portal; no Playwright suite existed.

## Matrix

`docs/flow_matrix.md` â€” 13 modules + gallery excluded. 62 EXISTS Â· 14 PARTIAL Â· 0 MISSING Â· 21 N/A. Every cell cites a
file/endpoint. Runtime column records API/HTTP results and explicitly marks the browser layer NOT RUN.

## Flows

One file per module in `docs/flows/`: auth, platform admin, workshop templates, workshop jobs, review/publish,
reports/delivery, technician inspection, public report, dashboards, cross-app. Each has numbered hops with
`file:line`, branches (error, permission, empty, other apps) and verification status.

## Gaps and fixes

`docs/flow_gaps.md` â€” **BLOCKER 6 (all fixed) Â· MAJOR 8 (3 closed, 5 open) Â· MINOR 8**.

Closed blockers:

1. **BLOCKER-01** 313 KB pinned checklist overflowed MySQL `TEXT` â†’ `MEDIUMTEXT` migration; 30-item checklist loads.
2. **BLOCKER-02** no consent write path for clean jobs â†’ `PUT /workshop/jobs/{id}/consent` + UI "Granted" action;
   API round-trip verified.
3. **BLOCKER-03** completion failed `SCORE_NOT_COMPUTABLE` with no scoring rule â†’ default A/B/C/D thresholds.
4. **BLOCKER-04** all issue fields required for a clean pass â†’ `requiredForStatuses` is conditional, seed flags fixed,
   default 100/70/40 score when no bands/measurement.
5. **BLOCKER-05** public report fabricated vehicle/tyre/damage/showcase/video facts â†’ hardcoded values removed,
   fabricated sections disabled, only snapshot-backed data rendered; print path treated the same.
6. **BLOCKER-06** clean report pipeline unreadable/unreachable â†’ normalized `ReportSnapshot` at approval +
   `CleanPublicReportReader` fallback in `PublicReportService`; `GET /r/{token}` = 200 with real data, PDF = 200 `%PDF`.

Also closed: MAJOR-01 (report version no longer stores customer contact/full VIN), MAJOR-05 (no fake item media),
MAJOR-07 (Start immediately / Schedule for later in the wizard).

Demo data: `DemoDataSeeder` (dev profile only) seeds the 30-item checklist and three realistic jobs
(assigned / scheduled / draft) when Workshop A has no jobs. It is idempotent and never runs in production.

Removed/accepted by owner: MAJOR-03 (2FA out of scope), MAJOR-04 (deliveries API/console-only; nav fixed at six items). MAJOR-07 is closed: the wizard offers Start immediately or Schedule for later.

Open: MAJOR-02 (legacy technician consent store still exists; Workshop path fixed), MAJOR-06 (browser suite generated
but not executed), MAJOR-09 (Workshop Flutter test suite red), plus MINOR-01â€¦08 (dead client endpoint declarations,
legacy API drift, page-local queue counts, client-only VIN validation, dev health 503, terminology drift, platform
template API without screen, English-only registry ambiguity).

Dynamic report sections: `tyreAssemblies` now comes from real multi-point tyre measurements, `damageZones` from real
non-pass body/tyre items, and `vehicleShowcase` from real public evidence URLs. At publish, verified clean photos are
resized/EXIF-stripped into `normalized_key`; the public HTML/PDF serve those real photos. Sections are empty when the
data is absent; no stock photos or invented readings are rendered.

## Runs

| Check | Command | Result |
|---|---|---|
| Server compile | `mvn -q -DskipTests compile` | PASS |
| Server full suite | `cd server; mvn test` | **166 run, 0 failures, 0 errors, 15 skipped, BUILD SUCCESS** (bilingual tests disabled by the English-only decision) |
| Targeted suites | `mvn -q "-Dtest=ReportIT,TechnicianInspectionIT,WorkshopJobAdminIT" test` | 3 + 7 + 6 tests PASS |
| Consent test | `WorkshopJobAdminIT` new case | PASS (grant/withdraw + 2 audit rows) |
| Workshop analyze | `cd client/apps/workshop_admin_app; flutter analyze` | No issues |
| Workshop widget tests | `flutter test` | **94 failures** (legacy Arabic/RTL + old UI characterization tests; the release gate) |
| Auth API | login platform/workshop/technician | PASS |
| Seed | `POST /platform/seed/default-checklist` | 146 created |
| Job create/assign | `POST /workshop/jobs` | PASS, status ASSIGNED |
| Checklist | `GET /technician/jobs/{id}/checklist` | PASS, 30 items, 313 KB snapshot |
| Assess/complete | 30 assessments + signature + evidence | PASS, score 100, grade A, PENDING_REVIEW |
| Approve | `POST /workshop/jobs/{id}/approve` | PASS, 6 categories / 25 KB report version |
| Publish | `POST /workshop/jobs/{id}/publish` | PASS, ACTIVE link |
| Public HTML | `GET /r/{token}` | **200**, real Toyota/Land Cruiser + real items, no demo strings |
| Public PDF | `GET /r/{token}/pdf` | **200**, `%PDF`, 551 KB |
| Browser suite | `npx playwright test --list` | 18 tests in 6 files; **not executed by request** (`docs/flows/harness.md`) |

## Questions

One question asked (`docs/flow_questions.md`): scope â†’ user chose **all modules, vertical slice executed**. No Step-0
correction question was needed; documentation drift was recorded as a gap.

## Files changed in the fix pass

Server:

- `server/src/main/resources/db/migration-mysql/V123__widen_snapshot_columns.sql` (new)
- `server/src/main/java/com/truereport/technician/TechnicianInspectionService.java`
- `server/src/main/java/com/truereport/seed/DefaultChecklistSeeder.java`
- `server/src/main/java/com/truereport/jobs/WorkshopJobAdminService.java`
- `server/src/main/java/com/truereport/jobs/WorkshopJobDtos.java`
- `server/src/main/java/com/truereport/jobs/WorkshopJobAdminController.java`
- `server/src/main/java/com/truereport/jobs/PlatformJobStore.java`
- `server/src/main/java/com/truereport/reports/ReportSnapshot.java`
- `server/src/main/java/com/truereport/reports/ReportSnapshotBuilder.java`
- `server/src/main/java/com/truereport/reports/ReportViewMapper.java`
- `server/src/main/java/com/truereport/reports/PublicReportService.java`
- `server/src/main/java/com/truereport/reports/PublicShareLink.java`
- `server/src/main/java/com/truereport/reports/CleanPublicReportReader.java` (new)
- `server/src/test/java/com/truereport/WorkshopJobAdminIT.java`
- `server/src/test/java/com/truereport/ReportPdfSampleTest.java`

Client:

- `client/packages/api_client/lib/src/api_endpoints.dart`
- `client/apps/workshop_admin_app/lib/src/admin_api.dart`
- `client/apps/workshop_admin_app/lib/src/features/jobs/dispatch/dispatch_detail.dart`

Harness/docs:

- `playwright.config.ts`, `package.json`, `tests/e2e/**` (generated; not executed)
- `docs/project_brief.md`, `docs/flow_matrix.md`, `docs/flow_gaps.md`, `docs/flow_questions.md`, `docs/flow_report.md`
- `docs/flows/*.md` (discovery, auth, platform, templates, jobs, review/publish, reports/delivery, technician, public,
  dashboards, cross-app, harness)

## Blocked / next

1. **Browser execution** â€” run `npx playwright test` with `E2E_PASSWORD` when the user wants a COMPLETE verdict.
3. **MAJOR-04 Platform deliveries screen** â€” expose `GET /platform/deliveries` or remove the endpoint.
5. **MAJOR-09 client suite** â€” triage 87 failing widget/characterization tests before using it as a release gate.
6. **MAJOR-02 legacy consent/report duplication** â€” one write path per concept; retire legacy technician consent or map
   it to `platform_jobs.consent_granted`.
7. **MINOR** â€” remove dead client endpoint declarations; align README/glossary (`admin_app`, gearbox/transmission);
   consider a "Platform Admin is English-only" note in the languages screen.

## Risks

- The public report design lost its static showcase/tyre/damage sections; this is intentional honesty, but product
  must decide which of those sections to rebuild from real evidence/measurements.
- PDF rendering depends on headless Chromium; verified locally but concurrency/memory remain unmeasured.
- The audit used a disposable MySQL 8.0 instance on port 3307 because the installed instance rejected repo credentials;
  the repository configuration itself is unchanged.
- The browser harness is untested end-to-end; its first run may need selector tuning for the Flutter semantics tree.

